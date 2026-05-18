"""Notification service for guardian alerts and escalation logs.
Includes live location sharing in all emergency messages."""
import os
from django.conf import settings
from .models import DeviceRegistration, EmergencyContact, LiveLocationSession, NotificationLog
from integrations.notifications import get_notification_provider
from integrations.ambulance import get_ambulance_provider

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
except ImportError:
    firebase_admin = None
    credentials = None
    messaging = None


def build_emergency_message(alert, contact=None):
    location = alert.location or 'Location not available'
    severity = alert.severity.title() if alert.severity else 'Unknown'

    # Try to get live tracking link
    live_link = ''
    try:
        session = LiveLocationSession.objects.filter(
            user=alert.user, status='active'
        ).first()
        if session:
            live_link = f'\nLive Tracking: /alerts/live-track/{session.session_id}/'
    except Exception:
        pass

    # Generate Google Maps link from location if it contains coordinates
    maps_link = ''
    if ',' in location:
        try:
            parts = location.split(',')
            lat, lng = parts[0].strip(), parts[1].strip()
            float(lat)
            float(lng)
            maps_link = f'\nGoogle Maps: https://maps.google.com/?q={lat},{lng}'
        except (ValueError, IndexError):
            pass

    return (
        f'SafeRide Guardian EMERGENCY ALERT!\n'
        f'Message: {alert.message}\n'
        f'Severity: {severity}\n'
        f'Location: {location}{maps_link}{live_link}\n'
        f"Time: {alert.created_at.strftime('%d %b %Y, %H:%M') if alert.created_at else 'Just now'}\n"
        f'Please respond immediately!'
    )


def log_notification(user, alert, channel, recipient, message, status='simulated'):
    return NotificationLog.objects.create(
        user=user, alert=alert, channel=channel,
        recipient=recipient or 'No recipient configured',
        message=message, status=status
    )


def _firebase_enabled():
    return bool(
        firebase_admin and
        getattr(settings, 'FIREBASE_CREDENTIALS_PATH', '') and
        os.path.exists(settings.FIREBASE_CREDENTIALS_PATH)
    )


def _firebase_app():
    if not _firebase_enabled():
        return None
    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
    return firebase_admin.get_app()


def notify_guardian(alert, request_call=False, request_ambulance=False):
    """Send notifications to guardian through all available channels.
    Includes live location link in all messages."""
    user = alert.user
    contact = EmergencyContact.objects.filter(user=user).first()
    recipient = contact.contact_phone if contact else 'No emergency contact'
    message = build_emergency_message(alert, contact)

    notification_provider = get_notification_provider()
    ambulance_provider = get_ambulance_provider()

    # SMS notification with live location
    sms_result = notification_provider.send_sms(recipient, message)
    logs = [log_notification(user, alert, 'sms', recipient, message, status=sms_result.status)]

    # Push notification
    active_tokens = list(
        DeviceRegistration.objects.filter(user=user, is_active=True)
        .values_list('token', flat=True)
    )

    if active_tokens and _firebase_app():
        firebase_message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title='SafeRide Guardian Emergency!',
                body=alert.message,
            ),
            data={
                'alert_id': str(alert.id),
                'severity': alert.severity,
                'location': alert.location or '',
                'type': 'emergency',
            },
            tokens=active_tokens,
        )
        response = messaging.send_each_for_multicast(firebase_message)
        push_status = 'sent' if response.success_count else 'failed'
        logs.append(log_notification(
            user, alert, 'push',
            f'{len(active_tokens)} device(s)', message, status=push_status
        ))
    else:
        logs.append(log_notification(user, alert, 'push', recipient, message))

    # Phone call to guardian
    if request_call or alert.parent_call_requested or alert.severity == 'confirmed':
        call_result = notification_provider.place_call(recipient, message)
        logs.append(log_notification(
            user, alert, 'call', recipient,
            'Emergency auto-call initiated by SafeRide Guardian.',
            status=call_result.status
        ))

    # Ambulance dispatch
    if request_ambulance or alert.ambulance_requested:
        dispatch_result = ambulance_provider.request_dispatch(
            location=alert.location, message=message
        )
        logs.append(log_notification(
            user, alert, 'ambulance',
            'Emergency services',
            dispatch_result.detail, status=dispatch_result.status
        ))

    return logs
