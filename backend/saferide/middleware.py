"""Custom middleware for SafeRide production deployment."""

import logging
import time
import uuid

from django.http import JsonResponse

logger = logging.getLogger('saferide')


class RequestLoggingMiddleware:
    """Log every request with timing, status, and a correlation ID."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request_id = str(uuid.uuid4())[:8]
        request.META['X_REQUEST_ID'] = request_id
        start = time.time()

        response = self.get_response(request)

        duration_ms = (time.time() - start) * 1000
        user = getattr(request, 'user', None)
        username = user.username if user and user.is_authenticated else 'anonymous'

        logger.info(
            '[%s] %s %s %s -> %d (%.1fms) user=%s',
            request_id,
            request.method,
            request.path,
            request.META.get('QUERY_STRING', ''),
            response.status_code,
            duration_ms,
            username,
        )

        response['X-Request-ID'] = request_id
        return response

    def process_exception(self, request, exception):
        request_id = request.META.get('X_REQUEST_ID', 'unknown')
        logger.exception(
            '[%s] Unhandled exception in %s %s: %s',
            request_id,
            request.method,
            request.path,
            str(exception),
        )
        return None
