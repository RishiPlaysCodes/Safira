"""Notification providers for SafeRide Guardian.
Supports: Free (simulated), Twilio (production SMS/Call)."""
import logging
from dataclasses import dataclass
from django.conf import settings

logger = logging.getLogger(__name__)


@dataclass
class DeliveryResult:
    provider: str
    status: str
    detail: str = ''


class BaseNotificationProvider:
    name = 'base'

    def send_sms(self, phone: str, message: str) -> DeliveryResult:
        raise NotImplementedError

    def place_call(self, phone: str, message: str) -> DeliveryResult:
        raise NotImplementedError


class FreeNotificationProvider(BaseNotificationProvider):
    """Free simulated provider - logs notifications without sending."""
    name = 'free_simulated'

    def send_sms(self, phone: str, message: str) -> DeliveryResult:
        logger.info(f'[SMS SIMULATED] To: {phone} | Message: {message[:100]}...')
        return DeliveryResult(self.name, 'simulated', f'SMS queued for {phone}')

    def place_call(self, phone: str, message: str) -> DeliveryResult:
        logger.info(f'[CALL SIMULATED] To: {phone}')
        return DeliveryResult(self.name, 'simulated', f'Call queued for {phone}')


class TwilioNotificationProvider(BaseNotificationProvider):
    """Production Twilio provider for real SMS and voice calls."""
    name = 'twilio'

    def send_sms(self, phone: str, message: str) -> DeliveryResult:
        try:
            from twilio.rest import Client
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            msg = client.messages.create(
                body=message,
                from_=settings.TWILIO_FROM_NUMBER,
                to=phone
            )
            logger.info(f'[SMS SENT] To: {phone} | SID: {msg.sid}')
            return DeliveryResult(self.name, 'sent', f'SMS sent to {phone} (SID: {msg.sid})')
        except ImportError:
            logger.error('[SMS FAILED] twilio package not installed')
            return DeliveryResult(self.name, 'failed', 'Twilio package not installed. pip install twilio')
        except Exception as exc:
            logger.error(f'[SMS FAILED] To: {phone} | Error: {exc}')
            return DeliveryResult(self.name, 'failed', str(exc))

    def place_call(self, phone: str, message: str) -> DeliveryResult:
        try:
            from twilio.rest import Client
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            # Use TwiML to speak the emergency message
            twiml = (
                f'<Response><Say voice="alice">'
                f'SafeRide Guardian Emergency Alert. '
                f'A possible accident has been detected. '
                f'Please check on the rider immediately.'
                f'</Say><Pause length="2"/><Say voice="alice">'
                f'Repeating: This is an emergency alert from SafeRide Guardian.'
                f'</Say></Response>'
            )
            call = client.calls.create(
                twiml=twiml,
                from_=settings.TWILIO_FROM_NUMBER,
                to=phone
            )
            logger.info(f'[CALL INITIATED] To: {phone} | SID: {call.sid}')
            return DeliveryResult(self.name, 'sent', f'Call initiated to {phone} (SID: {call.sid})')
        except ImportError:
            return DeliveryResult(self.name, 'failed', 'Twilio package not installed')
        except Exception as exc:
            logger.error(f'[CALL FAILED] To: {phone} | Error: {exc}')
            return DeliveryResult(self.name, 'failed', str(exc))


def get_notification_provider() -> BaseNotificationProvider:
    """Get the configured notification provider."""
    provider = getattr(settings, 'NOTIFICATION_PROVIDER', 'free')
    if provider == 'twilio' and getattr(settings, 'TWILIO_ACCOUNT_SID', ''):
        return TwilioNotificationProvider()
    return FreeNotificationProvider()
