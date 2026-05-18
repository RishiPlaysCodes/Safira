from dataclasses import dataclass
from django.conf import settings


@dataclass
class TrafficAssessment:
    provider: str
    level: str
    confidence: float


class BaseTrafficProvider:
    name = 'base'

    def assess(self, *, latitude: float, longitude: float) -> TrafficAssessment:
        raise NotImplementedError


class FreeTrafficProvider(BaseTrafficProvider):
    name = 'free_manual'

    def assess(self, *, latitude: float, longitude: float) -> TrafficAssessment:
        return TrafficAssessment(self.name, 'unknown', 0.0)


class ExternalTrafficProvider(BaseTrafficProvider):
    name = 'external_api'

    def assess(self, *, latitude: float, longitude: float) -> TrafficAssessment:
        return TrafficAssessment(self.name, 'unknown', 0.0)


def get_traffic_provider() -> BaseTrafficProvider:
    if settings.TRAFFIC_PROVIDER == 'external_api':
        return ExternalTrafficProvider()
    return FreeTrafficProvider()
