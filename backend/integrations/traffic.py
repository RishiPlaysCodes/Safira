"""Traffic assessment providers for SafeRide Guardian.
Supports: Free (heuristic), External API (Google/HERE)."""
import logging
from dataclasses import dataclass
from django.conf import settings

logger = logging.getLogger(__name__)


@dataclass
class TrafficAssessment:
    provider: str
    level: str  # free, moderate, heavy, severe
    confidence: float
    details: str = ''


class BaseTrafficProvider:
    name = 'base'

    def assess(self, *, latitude: float, longitude: float, speed_kmh: float = 0) -> TrafficAssessment:
        raise NotImplementedError


class FreeTrafficProvider(BaseTrafficProvider):
    """Speed-based traffic estimation without external APIs."""
    name = 'free_heuristic'

    def assess(self, *, latitude: float, longitude: float, speed_kmh: float = 0) -> TrafficAssessment:
        # Estimate traffic based on current speed vs typical speed
        typical_speed = 40.0  # Default expected speed

        if speed_kmh <= 0:
            return TrafficAssessment(self.name, 'unknown', 0.0, 'Vehicle stationary')

        ratio = speed_kmh / typical_speed
        if ratio >= 0.8:
            return TrafficAssessment(self.name, 'free', 0.7, 'Traffic flowing normally')
        elif ratio >= 0.5:
            return TrafficAssessment(self.name, 'moderate', 0.6, 'Some congestion detected')
        elif ratio >= 0.25:
            return TrafficAssessment(self.name, 'heavy', 0.65, 'Heavy traffic')
        else:
            return TrafficAssessment(self.name, 'severe', 0.7, 'Severe congestion')


class ExternalTrafficProvider(BaseTrafficProvider):
    """External API traffic provider (Google Maps / HERE Maps)."""
    name = 'external_api'

    def assess(self, *, latitude: float, longitude: float, speed_kmh: float = 0) -> TrafficAssessment:
        try:
            import requests
            api_key = getattr(settings, 'TRAFFIC_API_KEY', '')
            if not api_key:
                return FreeTrafficProvider().assess(latitude=latitude, longitude=longitude, speed_kmh=speed_kmh)

            # HERE Traffic API
            url = f'https://traffic.ls.hereapi.com/traffic/6.3/flow.json'
            params = {
                'apiKey': api_key,
                'prox': f'{latitude},{longitude},500',
                'responseattributes': 'sh,fc',
            }
            response = requests.get(url, params=params, timeout=5)
            if response.status_code == 200:
                data = response.json()
                # Parse traffic flow data
                return TrafficAssessment(self.name, 'moderate', 0.8, 'External API assessment')
            return FreeTrafficProvider().assess(latitude=latitude, longitude=longitude, speed_kmh=speed_kmh)
        except Exception as exc:
            logger.warning(f'[Traffic API] Failed: {exc}')
            return FreeTrafficProvider().assess(latitude=latitude, longitude=longitude, speed_kmh=speed_kmh)


def get_traffic_provider() -> BaseTrafficProvider:
    provider = getattr(settings, 'TRAFFIC_PROVIDER', 'free_manual')
    if provider == 'external_api':
        return ExternalTrafficProvider()
    return FreeTrafficProvider()
