"""Alert views - web (session auth) and API (token auth) endpoints."""

import logging

from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404, redirect, render
from rest_framework import serializers as drf_serializers
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from .detection_engine import calculate_accident_risk, to_bool
from .forms import EmergencyContactForm
from .models import (
    DeviceRegistration,
    EmergencyAlert,
    EmergencyContact,
    EscalationEvent,
    NotificationLog,
)
from .notification_service import notify_guardian
from .serializers import DeviceRegistrationSerializer, EmergencyAlertSerializer

logger = logging.getLogger('alerts')


# ===========================================================================
# INPUT VALIDATION SERIALIZERS
# ===========================================================================

class AccidentSignalInputSerializer(drf_serializers.Serializer):
    """Validates accident signal data from mobile app."""
    status = drf_serializers.CharField(max_length=50, required=False, allow_blank=True, default='')
    speed = drf_serializers.FloatField(min_value=0, max_value=500, required=False, default=0)
    speed_before = drf_serializers.FloatField(min_value=0, max_value=500, required=False, default=None)
    speed_after = drf_serializers.FloatField(min_value=0, max_value=500, required=False, default=None)
    impact_level = drf_serializers.FloatField(min_value=0, max_value=100, required=False, default=0)
    impact_g = drf_serializers.FloatField(min_value=0, max_value=100, required=False, default=0)
    no_movement_seconds = drf_serializers.IntegerField(min_value=0, max_value=3600, required=False, default=0)
    phone_angle_changed = drf_serializers.BooleanField(required=False, default=False)
    user_confirmed = drf_serializers.BooleanField(required=False, default=False)
    location = drf_serializers.CharField(max_length=220, required=False, allow_blank=True, default='')
    latitude = drf_serializers.FloatField(min_value=-90.0, max_value=90.0, required=False, allow_null=True, default=None)
    longitude = drf_serializers.FloatField(min_value=-180.0, max_value=180.0, required=False, allow_null=True, default=None)


class DeviceRegistrationInputSerializer(drf_serializers.Serializer):
    """Validates device registration input."""
    token = drf_serializers.CharField(max_length=255, required=True)
    platform = drf_serializers.ChoiceField(choices=['android', 'ios'], default='android')


class TestNotificationInputSerializer(drf_serializers.Serializer):
    """Validates test notification input."""
    location = drf_serializers.CharField(max_length=220, required=False, default='Notification test')
    message = drf_serializers.CharField(max_length=500, required=False, default='SafeRide Guardian test notification.')
    request_call = drf_serializers.BooleanField(required=False, default=False)


# ===========================================================================
# CUSTOM THROTTLE
# ===========================================================================

class AccidentSignalThrottle(ScopedRateThrottle):
    """Throttle accident signals to prevent abuse (10/min per user)."""
    scope = 'accident_signal'


# ===========================================================================
# WEB VIEWS (session-based auth)
# ===========================================================================

@login_required
def emergency_contact_view(request):
    contact, _ = EmergencyContact.objects.get_or_create(user=request.user)
    if request.method == 'POST':
        form = EmergencyContactForm(request.POST, instance=contact)
        if form.is_valid():
            emergency_contact = form.save(commit=False)
            emergency_contact.user = request.user
            emergency_contact.save()
            return redirect('dashboard')
    else:
        form = EmergencyContactForm(instance=contact)
    return render(request, 'alerts/emergency_contact.html', {'form': form})


@login_required
def accident_simulation(request):
    alert = EmergencyAlert.objects.create(
        user=request.user,
        location='Demo Location - live GPS will be attached by mobile app',
        severity='high',
        source='demo',
        message='Possible accident detected. User did not respond within safety countdown.',
    )
    EscalationEvent.objects.create(alert=alert, stage='suspicion', message='Accident suspicion created.')
    return render(request, 'alerts/accident_countdown.html', {'alert': alert})


@login_required
def manual_sos(request):
    alert = EmergencyAlert.objects.create(
        user=request.user,
        location='Manual SOS - current GPS will be attached by mobile app',
        severity='confirmed',
        source='manual',
        message='User manually confirmed an emergency. Immediate guardian help required.',
        alert_sent=True,
        parent_call_requested=True,
        ambulance_requested=True,
    )
    EscalationEvent.objects.create(alert=alert, stage='rider_confirmed', message='Manual SOS confirmed by rider.')
    EscalationEvent.objects.create(alert=alert, stage='ambulance_requested', message='Ambulance workflow requested after confirmed emergency.')
    contact = EmergencyContact.objects.filter(user=request.user).first()
    notification_logs = notify_guardian(alert, request_call=True, request_ambulance=True)
    return render(request, 'alerts/alert_sent.html', {'alert': alert, 'contact': contact, 'notification_logs': notification_logs})


@login_required
def cancel_alert(request, alert_id):
    alert = get_object_or_404(EmergencyAlert, id=alert_id, user=request.user)
    alert.is_cancelled = True
    alert.alert_sent = False
    alert.parent_call_requested = False
    alert.ambulance_requested = False
    alert.notes = 'User cancelled during countdown and marked safe.'
    alert.save()
    EscalationEvent.objects.create(alert=alert, stage='rider_safe', message='Rider marked safe during countdown.')
    return render(request, 'alerts/alert_cancelled.html', {'alert': alert})


@login_required
def confirm_accident(request, alert_id):
    alert = get_object_or_404(EmergencyAlert, id=alert_id, user=request.user)
    alert.severity = 'confirmed'
    alert.alert_sent = True
    alert.parent_call_requested = True
    alert.ambulance_requested = True
    alert.message = 'User confirmed accident/emergency. Call guardian immediately and request ambulance workflow.'
    alert.save()
    EscalationEvent.objects.create(alert=alert, stage='rider_confirmed', message='Rider confirmed accident.')
    EscalationEvent.objects.create(alert=alert, stage='ambulance_requested', message='Ambulance workflow requested after rider confirmation.')
    contact = EmergencyContact.objects.filter(user=request.user).first()
    notification_logs = notify_guardian(alert, request_call=True, request_ambulance=True)
    return render(request, 'alerts/alert_sent.html', {'alert': alert, 'contact': contact, 'notification_logs': notification_logs})


@login_required
def send_emergency_alert(request, alert_id):
    alert = get_object_or_404(EmergencyAlert, id=alert_id, user=request.user)
    contact = EmergencyContact.objects.filter(user=request.user).first()
    notification_logs = []
    if not alert.is_cancelled:
        alert.alert_sent = True
        alert.parent_call_requested = True
        alert.ambulance_requested = True
        alert.save()
        EscalationEvent.objects.create(alert=alert, stage='guardian_notified', message='Guardian notified from web flow.')
        EscalationEvent.objects.create(alert=alert, stage='ambulance_requested', message='Ambulance workflow requested from web flow.')
        notification_logs = notify_guardian(alert, request_call=True, request_ambulance=True)
    return render(request, 'alerts/alert_sent.html', {'alert': alert, 'contact': contact, 'notification_logs': notification_logs})


@login_required
def alert_history(request):
    alerts = EmergencyAlert.objects.filter(user=request.user).order_by('-created_at')
    return render(request, 'alerts/alert_history.html', {'alerts': alerts})


@login_required
def notification_history(request):
    notifications = NotificationLog.objects.filter(user=request.user).order_by('-created_at')
    return render(request, 'alerts/notification_history.html', {'notifications': notifications})


@login_required
def accident_detector_demo(request):
    result = None
    alert = None
    if request.method == 'POST':
        decision = calculate_accident_risk(
            impact_level=request.POST.get('impact_level', 0),
            speed_before=request.POST.get('speed_before', 0),
            speed_after=request.POST.get('speed_after', 0),
            no_movement_seconds=request.POST.get('no_movement_seconds', 0),
            phone_angle_changed=to_bool(request.POST.get('phone_angle_changed')),
            user_confirmed=to_bool(request.POST.get('user_confirmed')),
        )
        is_confirmed = decision['severity'] == 'confirmed'
        alert = EmergencyAlert.objects.create(
            user=request.user,
            location=request.POST.get('location', 'Demo detector location'),
            severity=decision['severity'],
            source='impact',
            message=decision['message'],
            alert_sent=decision['guardian_alert_sent'],
            parent_call_requested=decision['parent_call_requested'],
            ambulance_requested=is_confirmed,
            notes=f"Web detector risk_score={decision['score']}; reasons={' | '.join(decision['reasons'])}",
        )
        EscalationEvent.objects.create(alert=alert, stage='suspicion', message='Web detector event created.')
        if alert.alert_sent:
            EscalationEvent.objects.create(alert=alert, stage='guardian_notified', message='Guardian notified from web detector.')
        if is_confirmed:
            EscalationEvent.objects.create(alert=alert, stage='ambulance_requested', message='Ambulance workflow requested from web detector.')
        if alert.alert_sent or alert.parent_call_requested or alert.ambulance_requested:
            notify_guardian(alert, request_call=alert.parent_call_requested, request_ambulance=alert.ambulance_requested)
        result = decision
    return render(request, 'alerts/accident_detector_demo.html', {'result': result, 'alert': alert})


# ===========================================================================
# API VIEWS (token-based auth - requires Authorization: Token <key>)
# ===========================================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@throttle_classes([AccidentSignalThrottle])
def receive_accident_signal(request):
    """
    Process an accident/impact signal from the mobile app.

    POST /alerts/api/accident-signal/
    Headers: Authorization: Token <token>
    Body: {impact_level, speed_before, speed_after, no_movement_seconds, phone_angle_changed, user_confirmed, location}
    """
    input_serializer = AccidentSignalInputSerializer(data=request.data)
    if not input_serializer.is_valid():
        return Response(
            {'error': {'code': 'validation_error', 'details': input_serializer.errors}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    data = input_serializer.validated_data
    user = request.user

    # Resolve speed values (support both naming conventions)
    status_value = data.get('status', '')
    speed_before = data.get('speed_before') if data.get('speed_before') is not None else data.get('speed', 0)
    speed_after = data.get('speed_after') if data.get('speed_after') is not None else data.get('speed', 0)
    impact_level = data.get('impact_level') or data.get('impact_g', 0)
    user_confirmed = data.get('user_confirmed') or status_value in {'confirmed_no_response', 'manual_sos'}

    decision = calculate_accident_risk(
        impact_level=impact_level,
        speed_before=speed_before,
        speed_after=speed_after,
        no_movement_seconds=data.get('no_movement_seconds', 0),
        phone_angle_changed=data.get('phone_angle_changed', False),
        user_confirmed=user_confirmed,
    )

    # Build location string
    location = data.get('location', '')
    if not location and data.get('latitude') is not None and data.get('longitude') is not None:
        location = f"{data['latitude']},{data['longitude']}"
    if not location:
        location = 'Mobile GPS location not provided'

    is_confirmed = decision['severity'] == 'confirmed'
    alert = EmergencyAlert.objects.create(
        user=user,
        location=location,
        severity=decision['severity'],
        source='impact',
        message=decision['message'],
        alert_sent=decision['guardian_alert_sent'],
        parent_call_requested=decision['parent_call_requested'],
        ambulance_requested=is_confirmed,
        notes=(
            f"risk_score={decision['score']}; speed_drop={decision['speed_drop']}; "
            f"reasons={' | '.join(decision['reasons'])}; impact_level={impact_level}, "
            f"speed_before={speed_before}, speed_after={speed_after}, "
            f"no_movement_seconds={data.get('no_movement_seconds', 0)}, "
            f"phone_angle_changed={data.get('phone_angle_changed', False)}"
        ),
    )

    EscalationEvent.objects.create(alert=alert, stage='suspicion', message='Accident signal received from mobile app.')
    if alert.alert_sent:
        EscalationEvent.objects.create(alert=alert, stage='guardian_notified', message='Guardian notified after accident signal.')
    if is_confirmed:
        EscalationEvent.objects.create(alert=alert, stage='rider_confirmed', message='Confirmed accident from mobile workflow.')
        EscalationEvent.objects.create(alert=alert, stage='ambulance_requested', message='Ambulance workflow requested after confirmed mobile event.')

    notification_logs = []
    if alert.alert_sent or alert.parent_call_requested or alert.ambulance_requested:
        notification_logs = notify_guardian(alert, request_call=alert.parent_call_requested, request_ambulance=alert.ambulance_requested)

    logger.warning(
        'Accident signal user=%s severity=%s score=%d location=%s',
        user.username, decision['severity'], decision['score'], location,
    )

    return Response({
        'message': 'Accident signal processed.',
        'risk_score': decision['score'],
        'severity': decision['severity'],
        'reasons': decision['reasons'],
        'guardian_alert_sent': alert.alert_sent,
        'parent_call_requested': alert.parent_call_requested,
        'ambulance_requested': alert.ambulance_requested,
        'notification_logs_created': len(notification_logs),
        'alert': EmergencyAlertSerializer(alert).data,
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_device(request):
    """
    Register a device for push notifications.

    POST /alerts/api/register-device/
    Headers: Authorization: Token <token>
    Body: {token, platform}
    """
    input_serializer = DeviceRegistrationInputSerializer(data=request.data)
    if not input_serializer.is_valid():
        return Response(
            {'error': {'code': 'validation_error', 'details': input_serializer.errors}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    data = input_serializer.validated_data
    device, created = DeviceRegistration.objects.update_or_create(
        token=data['token'],
        defaults={
            'user': request.user,
            'platform': data['platform'],
            'is_active': True,
        },
    )

    logger.info('Device registered user=%s platform=%s new=%s', request.user.username, data['platform'], created)
    return Response(DeviceRegistrationSerializer(device).data, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def test_notification_api(request):
    """
    Send a test notification (development/QA only).

    POST /alerts/api/test-notification/
    Headers: Authorization: Token <token>
    Body: {location, message, request_call}
    """
    input_serializer = TestNotificationInputSerializer(data=request.data)
    if not input_serializer.is_valid():
        return Response(
            {'error': {'code': 'validation_error', 'details': input_serializer.errors}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    data = input_serializer.validated_data
    alert = EmergencyAlert.objects.create(
        user=request.user,
        location=data['location'],
        severity='medium',
        source='demo',
        message=data['message'],
        alert_sent=True,
        parent_call_requested=data['request_call'],
    )
    logs = notify_guardian(alert, request_call=data['request_call'])

    logger.info('Test notification sent user=%s logs=%d', request.user.username, len(logs))
    return Response({
        'message': 'Test notification sent.',
        'logs_created': len(logs),
        'recipients': [log.recipient for log in logs],
    }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_alert_history(request):
    """
    Get the authenticated user's alert history.

    GET /alerts/api/history/
    Headers: Authorization: Token <token>
    """
    alerts = EmergencyAlert.objects.filter(user=request.user).order_by('-created_at')[:20]
    return Response({
        'username': request.user.username,
        'alerts': EmergencyAlertSerializer(alerts, many=True).data,
    })
