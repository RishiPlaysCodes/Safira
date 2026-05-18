"""Notification service for guardian alerts and escalation logs."""
import os
from django.conf import settings
from .models import DeviceRegistration, EmergencyContact, NotificationLog
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
    return (
        f'SafeRide Guardian Alert: {alert.message}\n'
        f'Severity: {severity}\n'
        f'Location: {location}\n'
        f"Time: {alert.created_at.strftime('%d %b %Y, %H:%M') if alert.created_at else 'Just now'}"
    )


def log_notification(user, alert, channel, recipient, message, status='simulated'):
    return NotificationLog.objects.create(user=user, alert=alert, channel=channel, recipient=recipient or 'No recipient configured', message=message, status=status)


def _firebase_enabled():
    return bool(firebase_admin and getattr(settings, 'FIREBASE_CREDENTIALS_PATH', '') and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH))


def _firebase_app():
    if not _firebase_enabled():
        return None
    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
    return firebase_admin.get_app()


def notify_guardian(alert, request_call=False, request_ambulance=False):
    user = alert.user
    contact = EmergencyContact.objects.filter(user=user).first()
    recipient = contact.contact_phone if contact else 'No emergency contact'
    message = build_emergency_message(alert, contact)

    notification_provider = get_notification_provider()
    ambulance_provider = get_ambulance_provider()
    sms_result = notification_provider.send_sms(recipient, message)
    logs = [log_notification(user, alert, 'sms', recipient, message, status=sms_result.status)]
    active_tokens = list(DeviceRegistration.objects.filter(user=user, is_active=True).values_list('token', flat=True))

    if active_tokens and _firebase_app():
        firebase_message = messaging.MulticastMessage(
            notification=messaging.Notification(title='SafeRide Guardian Alert', body=alert.message),
            data={'alert_id': str(alert.id), 'severity': alert.severity, 'location': alert.location},
            tokens=active_tokens,
        )
        response = messaging.send_each_for_multicast(firebase_message)
        push_status = 'sent' if response.success_count else 'failed'
        logs.append(log_notification(user, alert, 'push', f'{len(active_tokens)} device(s)', message, status=push_status))
    else:
        logs.append(log_notification(user, alert, 'push', recipient, message))

    if request_call or alert.parent_call_requested or alert.severity == 'confirmed':
        call_result = notification_provider.place_call(recipient, message)
        logs.append(log_notification(user, alert, 'call', recipient, 'Parent call workflow created by SafeRide Guardian.', status=call_result.status))

    if request_ambulance or alert.ambulance_requested:
        dispatch_result = ambulance_provider.request_dispatch(location=alert.location, message=message)
        logs.append(log_notification(user, alert, 'ambulance', 'Emergency services integration', dispatch_result.detail, status=dispatch_result.status))

    return logs

