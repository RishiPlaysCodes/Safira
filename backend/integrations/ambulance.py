from dataclasses import dataclass
from django.conf import settings


@dataclass
class DispatchResult:
    provider: str
    status: str
    detail: str = ''


class BaseAmbulanceProvider:
    name = 'base'

    def request_dispatch(self, *, location: str, message: str) -> DispatchResult:
        raise NotImplementedError


class FreeAmbulanceProvider(BaseAmbulanceProvider):
    name = 'free_simulated'

    def request_dispatch(self, *, location: str, message: str) -> DispatchResult:
        return DispatchResult(self.name, 'simulated', f'Ambulance workflow logged for {location}')


class WebhookAmbulanceProvider(BaseAmbulanceProvider):
    name = 'webhook'

    def request_dispatch(self, *, location: str, message: str) -> DispatchResult:
        try:
            import requests
            response = requests.post(settings.AMBULANCE_WEBHOOK_URL, json={'location': location, 'message': message}, timeout=5)
            response.raise_for_status()
            return DispatchResult(self.name, 'sent', 'Webhook dispatch request sent')
        except Exception as exc:
            return DispatchResult(self.name, 'failed', str(exc))


def get_ambulance_provider() -> BaseAmbulanceProvider:
    if settings.AMBULANCE_PROVIDER == 'webhook' and settings.AMBULANCE_WEBHOOK_URL:
        return WebhookAmbulanceProvider()
    return FreeAmbulanceProvider()
