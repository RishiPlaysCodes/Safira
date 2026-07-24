"""Health check endpoints for load balancers and monitoring.

Provides:
  - /api/health/         : Simple liveness probe (always returns 200 if app is up)
  - /api/health/ready/   : Readiness probe (checks DB + cache connectivity)
  - /api/health/detail/  : Detailed health (authenticated, shows versions & stats)
"""

import logging
import time

import django
from django.conf import settings
from django.db import connections
from django.db.utils import OperationalError
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.response import Response

logger = logging.getLogger('saferide')


@api_view(['GET'])
@permission_classes([AllowAny])
def health_liveness(request):
    """
    Liveness probe - confirms the application is running.

    GET /api/health/
    Returns 200 if the Django process is alive.
    Used by Docker HEALTHCHECK and load balancers.
    """
    return Response({'status': 'ok'}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def health_readiness(request):
    """
    Readiness probe - confirms the application can serve traffic.

    GET /api/health/ready/
    Checks database connectivity and cache availability.
    Returns 200 if all dependencies are healthy, 503 otherwise.
    """
    checks = {}
    all_healthy = True

    # Check database
    try:
        start = time.time()
        connection = connections['default']
        connection.cursor().execute('SELECT 1')
        db_time_ms = (time.time() - start) * 1000
        checks['database'] = {'status': 'healthy', 'response_ms': round(db_time_ms, 1)}
    except OperationalError as e:
        checks['database'] = {'status': 'unhealthy', 'error': str(e)[:100]}
        all_healthy = False
        logger.error('Health check: database unhealthy - %s', str(e)[:100])

    # Check cache
    try:
        from django.core.cache import cache
        start = time.time()
        cache.set('_health_check', 'ok', timeout=10)
        value = cache.get('_health_check')
        cache_time_ms = (time.time() - start) * 1000
        if value == 'ok':
            checks['cache'] = {'status': 'healthy', 'response_ms': round(cache_time_ms, 1)}
        else:
            checks['cache'] = {'status': 'degraded', 'detail': 'Cache set/get mismatch'}
    except Exception as e:
        checks['cache'] = {'status': 'unhealthy', 'error': str(e)[:100]}
        all_healthy = False

    response_status = status.HTTP_200_OK if all_healthy else status.HTTP_503_SERVICE_UNAVAILABLE
    return Response({
        'status': 'healthy' if all_healthy else 'unhealthy',
        'checks': checks,
    }, status=response_status)


@api_view(['GET'])
@permission_classes([IsAdminUser])
def health_detail(request):
    """
    Detailed health information (admin only).

    GET /api/health/detail/
    Headers: Authorization: Token <admin-token>
    Returns system info, dependency versions, and statistics.
    """
    from alerts.models import EmergencyAlert
    from trips.models import Trip

    checks = {}

    # Database
    try:
        start = time.time()
        connection = connections['default']
        cursor = connection.cursor()
        cursor.execute('SELECT 1')
        db_time_ms = (time.time() - start) * 1000
        checks['database'] = {
            'status': 'healthy',
            'response_ms': round(db_time_ms, 1),
            'engine': settings.DATABASES['default']['ENGINE'],
        }
    except OperationalError as e:
        checks['database'] = {'status': 'unhealthy', 'error': str(e)[:100]}

    # Cache
    try:
        from django.core.cache import cache
        start = time.time()
        cache.set('_health_detail', 'ok', timeout=10)
        cache.get('_health_detail')
        cache_time_ms = (time.time() - start) * 1000
        checks['cache'] = {
            'status': 'healthy',
            'response_ms': round(cache_time_ms, 1),
            'backend': settings.CACHES['default']['BACKEND'].split('.')[-1],
        }
    except Exception as e:
        checks['cache'] = {'status': 'unhealthy', 'error': str(e)[:100]}

    # Application stats
    stats = {
        'total_trips': Trip.objects.count(),
        'total_alerts': EmergencyAlert.objects.count(),
        'confirmed_alerts': EmergencyAlert.objects.filter(severity='confirmed').count(),
    }

    return Response({
        'status': 'healthy',
        'version': '1.0.0',
        'django_version': django.get_version(),
        'debug': settings.DEBUG,
        'checks': checks,
        'stats': stats,
    }, status=status.HTTP_200_OK)
