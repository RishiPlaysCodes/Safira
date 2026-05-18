from dataclasses import dataclass
from django.conf import settings


@dataclass
class VisionResult:
    provider: str
    label: str
    confidence: float


class BaseVisionProvider:
    name = 'base'

    def analyze(self, payload: dict) -> VisionResult:
        raise NotImplementedError


class FreeManualVisionProvider(BaseVisionProvider):
    name = 'free_manual'

    def analyze(self, payload: dict) -> VisionResult:
        return VisionResult(self.name, payload.get('label', 'unknown'), float(payload.get('confidence', 0)))


class OnDeviceVisionProvider(BaseVisionProvider):
    name = 'on_device'

    def analyze(self, payload: dict) -> VisionResult:
        return VisionResult(self.name, payload.get('label', 'unknown'), float(payload.get('confidence', 0)))


def get_vision_provider() -> BaseVisionProvider:
    if settings.VISION_PROVIDER == 'on_device':
        return OnDeviceVisionProvider()
    return FreeManualVisionProvider()
