"""Custom DRF exception handler for consistent error responses."""

import logging

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import status
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import exception_handler

logger = logging.getLogger('saferide')


def custom_exception_handler(exc, context):
    """
    Provides consistent JSON error responses for all API errors.

    Response format:
    {
        "error": {
            "code": "error_code",
            "message": "Human-readable description",
            "details": {...}  // optional
        }
    }
    """
    # Let DRF handle known exceptions first
    response = exception_handler(exc, context)

    if response is not None:
        error_data = {
            'error': {
                'code': _get_error_code(exc),
                'message': _get_error_message(exc, response),
            }
        }
        if hasattr(response, 'data') and isinstance(response.data, dict):
            # Include field-level validation errors
            details = {k: v for k, v in response.data.items() if k != 'detail'}
            if details:
                error_data['error']['details'] = details

        response.data = error_data
        return response

    # Handle Django ValidationError
    if isinstance(exc, DjangoValidationError):
        logger.warning('Django ValidationError: %s', exc.message_dict if hasattr(exc, 'message_dict') else str(exc))
        return Response(
            {
                'error': {
                    'code': 'validation_error',
                    'message': 'Invalid input data.',
                    'details': exc.message_dict if hasattr(exc, 'message_dict') else {'non_field_errors': exc.messages},
                }
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Unexpected errors - log but don't expose internals
    logger.exception('Unhandled API exception: %s', str(exc))
    return Response(
        {
            'error': {
                'code': 'internal_error',
                'message': 'An unexpected error occurred. Please try again later.',
            }
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


def _get_error_code(exc):
    if hasattr(exc, 'default_code'):
        return exc.default_code
    return type(exc).__name__.lower()


def _get_error_message(exc, response):
    if hasattr(exc, 'detail'):
        detail = exc.detail
        if isinstance(detail, str):
            return detail
        if isinstance(detail, list):
            return detail[0] if detail else 'Unknown error'
    return 'Request could not be processed.'
