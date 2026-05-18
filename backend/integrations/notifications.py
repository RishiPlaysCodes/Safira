from dataclasses import dataclass
from django.conf import settings


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
    name = 'free_simulated'

    def send_sms(self, phone: str, message: str) -> DeliveryResult:
        return DeliveryResult(self.name, 'simulated', f'SMS queued for {phone}')

    def place_call(self, phone: str, message: str) -> DeliveryResult:
        return DeliveryResult(self.name, 'simulated', f'Call queued for {phone}')


class TwilioNotificationProvider(BaseNotificationProvider):
    name = 'twilio'

    def send_sms(self, phone: str, message: str) -> DeliveryResult:
        try:
            from twilio.rest import Client
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            client.messages.create(body=message, from_=settings.TWILIO_FROM_NUMBER, to=phone)
            return DeliveryResult(self.name, 'sent', f'SMS sent to {phone}')
        except Exception as exc:
            return DeliveryResult(self.name, 'failed', str(exc))

    def place_call(self, phone: str, message: str) -> DeliveryResult:
        return DeliveryResult(self.name, 'queued', 'Twilio voice adapter ready; attach TwiML URL before production calling.')


def get_notification_provider() -> BaseNotificationProvider:
    if settings.NOTIFICATION_PROVIDER == 'twilio':
        return TwilioNotificationProvider()
    return FreeNotificationProvider()
