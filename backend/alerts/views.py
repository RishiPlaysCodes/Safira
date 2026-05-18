from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect, get_object_or_404
from .forms import EmergencyContactForm
from .models import DeviceRegistration, EmergencyContact, EmergencyAlert, EscalationEvent, NotificationLog
from .serializers import DeviceRegistrationSerializer, EmergencyAlertSerializer
from django.contrib.auth.models import User
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .detection_engine import calculate_accident_risk, to_bool
from .notification_service import notify_guardian


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
        message='Possible accident detected. User did not respond within safety countdown.'
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


def _api_user_from_request(request):
    if request.user and request.user.is_authenticated:
        return request.user
    username = request.data.get('username')
    return User.objects.filter(username=username).first() if username else None


@api_view(['POST'])
def receive_accident_signal(request):
    api_user = _api_user_from_request(request)
    if api_user is None:
        return Response({'error': 'Login first or send a valid username field for demo API testing.'}, status=status.HTTP_401_UNAUTHORIZED)

    status_value = request.data.get('status', '')
    speed_after = request.data.get('speed_after', request.data.get('speed', 0))
    speed_before = request.data.get('speed_before', request.data.get('speed', 0))
    impact_level = request.data.get('impact_level', request.data.get('impact_g', 0))
    user_confirmed = request.data.get('user_confirmed', status_value in {'confirmed_no_response', 'manual_sos'})
    decision = calculate_accident_risk(
        impact_level=impact_level,
        speed_before=speed_before,
        speed_after=speed_after,
        no_movement_seconds=request.data.get('no_movement_seconds', 0),
        phone_angle_changed=request.data.get('phone_angle_changed', False),
        user_confirmed=user_confirmed,
    )
    location = request.data.get('location', 'Mobile GPS location not provided')
    is_confirmed = decision['severity'] == 'confirmed'
    alert = EmergencyAlert.objects.create(
        user=api_user,
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
            f"no_movement_seconds={request.data.get('no_movement_seconds', 0)}, "
            f"phone_angle_changed={request.data.get('phone_angle_changed', False)}, "
            f"user_confirmed={request.data.get('user_confirmed', False)}"
        )
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
    return Response({
        'message': 'Accident signal processed by notification-ready engine.',
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
def register_device(request):
    api_user = _api_user_from_request(request)
    if api_user is None:
        return Response({'error': 'Login first or send a valid username.'}, status=status.HTTP_401_UNAUTHORIZED)
    token = request.data.get('token')
    if not token:
        return Response({'error': 'token is required.'}, status=status.HTTP_400_BAD_REQUEST)
    device, _ = DeviceRegistration.objects.update_or_create(token=token, defaults={'user': api_user, 'platform': request.data.get('platform', 'android'), 'is_active': True})
    return Response(DeviceRegistrationSerializer(device).data, status=status.HTTP_201_CREATED)


@api_view(['POST'])
def test_notification_api(request):
    api_user = _api_user_from_request(request)
    if api_user is None:
        return Response({'error': 'Login first or send a valid username.'}, status=status.HTTP_401_UNAUTHORIZED)
    alert = EmergencyAlert.objects.create(
        user=api_user,
        location=request.data.get('location', 'Phase 4 notification test'),
        severity='medium',
        source='demo',
        message=request.data.get('message', 'SafeRide Guardian test notification.'),
        alert_sent=True,
        parent_call_requested=to_bool(request.data.get('request_call')),
    )
    logs = notify_guardian(alert, request_call=alert.parent_call_requested)
    return Response({'message': 'Simulated notification logs created.', 'logs_created': len(logs), 'recipients': [log.recipient for log in logs]}, status=status.HTTP_201_CREATED)


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
            notes=f"Phase 4 web detector risk_score={decision['score']}; reasons={' | '.join(decision['reasons'])}"
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
