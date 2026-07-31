"""API views for authentication - token-based login, signup, and token management."""

import logging

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from rest_framework import serializers, status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle

from .models import DriverProfile

logger = logging.getLogger('saferide')


# ---------------------------------------------------------------------------
# Throttle Classes
# ---------------------------------------------------------------------------

class AuthRateThrottle(AnonRateThrottle):
    """Stricter throttle for auth endpoints to prevent brute force.

    Uses its own 'auth' scope (rate configured in settings) so it does not
    share a counter with the global anonymous throttle.
    """
    scope = 'auth'


# ---------------------------------------------------------------------------
# Serializers
# ---------------------------------------------------------------------------

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150, required=True)
    password = serializers.CharField(max_length=128, required=True, write_only=True)


class SignupSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150, required=True)
    email = serializers.EmailField(required=True)
    password = serializers.CharField(max_length=128, required=True, write_only=True)
    phone_number = serializers.CharField(max_length=15, required=True)
    vehicle_type = serializers.ChoiceField(choices=DriverProfile.VEHICLE_CHOICES, default='bike')
    license_number = serializers.CharField(max_length=30, required=False, allow_blank=True, default='')
    role = serializers.ChoiceField(choices=DriverProfile.ROLE_CHOICES, default='driver')

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('A user with this username already exists.')
        return value

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('A user with this email already exists.')
        return value

    def validate_password(self, value):
        try:
            validate_password(value)
        except ValidationError as e:
            raise serializers.ValidationError(list(e.messages))
        return value


class UserProfileSerializer(serializers.Serializer):
    id = serializers.IntegerField(read_only=True)
    username = serializers.CharField(read_only=True)
    email = serializers.EmailField(read_only=True)
    phone_number = serializers.CharField(read_only=True)
    vehicle_type = serializers.CharField(read_only=True)
    license_number = serializers.CharField(read_only=True)
    role = serializers.CharField(read_only=True)


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True)

    def validate_new_password(self, value):
        try:
            validate_password(value)
        except ValidationError as e:
            raise serializers.ValidationError(list(e.messages))
        return value


# ---------------------------------------------------------------------------
# API Views
# ---------------------------------------------------------------------------

@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthRateThrottle])
def api_login(request):
    """
    Authenticate user and return auth token.

    POST /api/auth/login/
    Body: {"username": "...", "password": "..."}
    Response: {"token": "...", "user": {...}}
    """
    serializer = LoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    user = authenticate(
        username=serializer.validated_data['username'],
        password=serializer.validated_data['password'],
    )

    if user is None:
        logger.warning(
            'Failed login attempt for username=%s from IP=%s',
            serializer.validated_data['username'],
            _get_client_ip(request),
        )
        return Response(
            {'error': {'code': 'authentication_failed', 'message': 'Invalid username or password.'}},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if not user.is_active:
        return Response(
            {'error': {'code': 'account_disabled', 'message': 'This account has been disabled.'}},
            status=status.HTTP_403_FORBIDDEN,
        )

    token, _ = Token.objects.get_or_create(user=user)
    logger.info('User %s logged in from IP=%s', user.username, _get_client_ip(request))

    profile = DriverProfile.objects.filter(user=user).first()
    return Response({
        'token': token.key,
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'phone_number': profile.phone_number if profile else '',
            'vehicle_type': profile.vehicle_type if profile else 'bike',
            'role': profile.role if profile else 'driver',
        },
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthRateThrottle])
def api_signup(request):
    """
    Register a new user and return auth token.

    POST /api/auth/signup/
    Body: {"username": "...", "email": "...", "password": "...", "phone_number": "...", ...}
    Response: {"token": "...", "user": {...}}
    """
    serializer = SignupSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    data = serializer.validated_data
    user = User.objects.create_user(
        username=data['username'],
        email=data['email'],
        password=data['password'],
    )

    DriverProfile.objects.create(
        user=user,
        phone_number=data['phone_number'],
        vehicle_type=data['vehicle_type'],
        license_number=data.get('license_number', ''),
        role=data['role'],
    )

    token = Token.objects.create(user=user)
    logger.info('New user registered: %s from IP=%s', user.username, _get_client_ip(request))

    return Response({
        'token': token.key,
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'phone_number': data['phone_number'],
            'vehicle_type': data['vehicle_type'],
            'role': data['role'],
        },
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_logout(request):
    """
    Invalidate the user's auth token.

    POST /api/auth/logout/
    Headers: Authorization: Token <token>
    """
    request.user.auth_token.delete()
    logger.info('User %s logged out', request.user.username)
    return Response({'message': 'Successfully logged out.'}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_profile(request):
    """
    Get the authenticated user's profile.

    GET /api/auth/profile/
    Headers: Authorization: Token <token>
    """
    user = request.user
    profile = DriverProfile.objects.filter(user=user).first()
    return Response({
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'phone_number': profile.phone_number if profile else '',
            'vehicle_type': profile.vehicle_type if profile else 'bike',
            'license_number': profile.license_number if profile else '',
            'role': profile.role if profile else 'driver',
        },
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_change_password(request):
    """
    Change authenticated user's password.

    POST /api/auth/change-password/
    Body: {"current_password": "...", "new_password": "..."}
    """
    serializer = ChangePasswordSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    user = request.user
    if not user.check_password(serializer.validated_data['current_password']):
        return Response(
            {'error': {'code': 'invalid_password', 'message': 'Current password is incorrect.'}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user.set_password(serializer.validated_data['new_password'])
    user.save()

    # Invalidate old token and issue new one
    Token.objects.filter(user=user).delete()
    new_token = Token.objects.create(user=user)

    logger.info('User %s changed password', user.username)
    return Response({
        'message': 'Password changed successfully.',
        'token': new_token.key,
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_refresh_token(request):
    """
    Rotate the auth token (invalidate old, issue new).

    POST /api/auth/refresh-token/
    Headers: Authorization: Token <token>
    """
    Token.objects.filter(user=request.user).delete()
    new_token = Token.objects.create(user=request.user)
    return Response({'token': new_token.key}, status=status.HTTP_200_OK)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_client_ip(request):
    """Extract client IP from request, respecting proxy headers."""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR', 'unknown')
