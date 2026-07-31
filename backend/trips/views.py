"""Trip views - web (session auth) and API (token auth) endpoints."""

import logging
from datetime import timedelta
from math import asin, cos, radians, sin, sqrt

from django.contrib.auth.decorators import login_required
from django.shortcuts import redirect, render
from django.utils import timezone
from rest_framework import serializers as drf_serializers
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from alerts.models import EmergencyAlert, EscalationEvent
from alerts.notification_service import notify_guardian
from integrations.vision import get_vision_provider

from .forms import TripForm
from .models import SafetyZone, Trip, VisionObservation
from .serializers import SafetyZoneSerializer, TripSerializer, VisionObservationSerializer

logger = logging.getLogger('trips')


# ===========================================================================
# INPUT VALIDATION SERIALIZERS
# ===========================================================================

class TripDataInputSerializer(drf_serializers.Serializer):
    """Validates incoming trip data from mobile app."""
    speed = drf_serializers.IntegerField(min_value=0, max_value=400)
    speed_limit = drf_serializers.IntegerField(min_value=0, max_value=300, default=40)
    location = drf_serializers.CharField(max_length=120, required=False, allow_blank=True, default='')
    destination = drf_serializers.CharField(max_length=160, required=False, allow_blank=True, default='')
    road_type = drf_serializers.ChoiceField(
        choices=['normal', 'school', 'hospital', 'market', 'highway'],
        default='normal',
    )
    helmet_worn = drf_serializers.BooleanField(default=True)
    red_light_crossed = drf_serializers.BooleanField(default=False)
    harsh_braking = drf_serializers.BooleanField(default=False)
    sudden_acceleration = drf_serializers.BooleanField(default=False)
    latitude = drf_serializers.FloatField(
        min_value=-90.0, max_value=90.0, required=False, allow_null=True, default=None
    )
    longitude = drf_serializers.FloatField(
        min_value=-180.0, max_value=180.0, required=False, allow_null=True, default=None
    )
    notes = drf_serializers.CharField(max_length=500, required=False, allow_blank=True, default='')


class VisionObservationInputSerializer(drf_serializers.Serializer):
    """Validates vision observation input from mobile app."""
    observation_type = drf_serializers.ChoiceField(choices=['helmet', 'red_light', 'traffic_density'])
    trip = drf_serializers.IntegerField(required=False, allow_null=True, default=None)
    label = drf_serializers.CharField(max_length=80, required=False, allow_blank=True, default='unknown')
    confidence = drf_serializers.FloatField(min_value=0.0, max_value=1.0, required=False, default=0.0)
    latitude = drf_serializers.FloatField(
        min_value=-90.0, max_value=90.0, required=False, allow_null=True, default=None
    )
    longitude = drf_serializers.FloatField(
        min_value=-180.0, max_value=180.0, required=False, allow_null=True, default=None
    )


# ===========================================================================
# WEB VIEWS (session-based auth)
# ===========================================================================

@login_required
def create_trip(request):
    if request.method == 'POST':
        form = TripForm(request.POST)
        if form.is_valid():
            trip = form.save(commit=False)
            trip.user = request.user
            trip.save()
            return redirect('trip_history')
    else:
        form = TripForm()
    return render(request, 'trips/create_trip.html', {'form': form})


@login_required
def trip_history(request):
    trips = Trip.objects.filter(user=request.user).order_by('-created_at')
    return render(request, 'trips/trip_history.html', {'trips': trips})


@login_required
def gps_tracker(request):
    return render(request, 'trips/gps_tracker.html')


@login_required
def safety_report(request):
    trips = Trip.objects.filter(user=request.user).order_by('-created_at')
    total_trips = trips.count()
    overspeed = trips.filter(alert_triggered=True).count()
    red_light = trips.filter(red_light_crossed=True).count()
    helmet_violations = trips.filter(helmet_worn=False).count()
    harsh_events = trips.filter(harsh_braking=True).count() + trips.filter(sudden_acceleration=True).count()
    avg_risk = round(sum(t.risk_score for t in trips) / total_trips, 1) if total_trips else 0
    return render(request, 'trips/safety_report.html', {
        'trips': trips[:10],
        'total_trips': total_trips,
        'overspeed': overspeed,
        'red_light': red_light,
        'helmet_violations': helmet_violations,
        'harsh_events': harsh_events,
        'avg_risk': avg_risk,
    })


@login_required
def weekly_report_view(request):
    summary = _build_weekly_summary(request.user)
    return render(request, 'trips/weekly_report.html', {'summary': summary})


@login_required
def send_weekly_report(request):
    summary = _build_weekly_summary(request.user)
    message = (
        f"Weekly safety report: {summary['total_trips']} trips, "
        f"{summary['overspeed_events']} overspeed events, "
        f"{summary['red_light_events']} red-light events, "
        f"{summary['helmet_issues']} helmet issues, "
        f"{summary['zone_visits']} zone visits, "
        f"average risk {summary['average_risk']}/100."
    )
    alert = EmergencyAlert.objects.create(
        user=request.user, location='Weekly report', severity='low',
        source='demo', message=message, alert_sent=True,
    )
    EscalationEvent.objects.create(alert=alert, stage='guardian_notified', message='Weekly report sent to guardian.')
    notify_guardian(alert, request_call=False)
    return redirect('weekly_report')


# ===========================================================================
# API VIEWS (token-based auth - requires Authorization: Token <key>)
# ===========================================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def receive_trip_data(request):
    """
    Receive real-time trip data from the mobile app.

    POST /trips/api/receive/
    Headers: Authorization: Token <token>
    Body: {speed, speed_limit, location, latitude, longitude, ...}
    """
    input_serializer = TripDataInputSerializer(data=request.data)
    if not input_serializer.is_valid():
        return Response(
            {'error': {'code': 'validation_error', 'details': input_serializer.errors}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    validated = input_serializer.validated_data
    latitude = validated.get('latitude')
    longitude = validated.get('longitude')

    # Check safety zone proximity
    nearby_zone = None
    if latitude is not None and longitude is not None:
        for zone in SafetyZone.objects.filter(active=True):
            if _distance_meters(latitude, longitude, zone.latitude, zone.longitude) <= zone.radius_meters:
                nearby_zone = zone
                break
        if nearby_zone:
            validated['road_type'] = nearby_zone.zone_type if nearby_zone.zone_type != 'danger' else 'market'
            validated['notes'] = f'Entered zone: {nearby_zone.name}'

    # Build trip payload (exclude lat/lon which aren't Trip model fields)
    trip_data = {k: v for k, v in validated.items() if k not in ('latitude', 'longitude')}
    serializer = TripSerializer(data=trip_data)
    if serializer.is_valid():
        trip = serializer.save(user=request.user)
        zone_alert = _maybe_send_zone_alert(request.user, nearby_zone) if nearby_zone else None

        logger.info('Trip recorded for user=%s speed=%d risk=%d', request.user.username, trip.speed, trip.risk_score)
        return Response({
            'message': 'Trip data received successfully.',
            'trip': TripSerializer(trip).data,
            'overspeed': trip.alert_triggered,
            'risk_score': trip.risk_score,
            'tags': trip.tags.split(',') if trip.tags else [],
            'zone_alert_sent': bool(zone_alert),
        }, status=status.HTTP_201_CREATED)

    return Response(
        {'error': {'code': 'validation_error', 'details': serializer.errors}},
        status=status.HTTP_400_BAD_REQUEST,
    )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_vision_observation(request):
    """
    Submit a vision AI observation (helmet detection, red light, etc).

    POST /trips/api/vision-observation/
    Headers: Authorization: Token <token>
    Body: {observation_type, label, confidence, latitude, longitude, trip}
    """
    input_serializer = VisionObservationInputSerializer(data=request.data)
    if not input_serializer.is_valid():
        return Response(
            {'error': {'code': 'validation_error', 'details': input_serializer.errors}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    validated = input_serializer.validated_data

    # Run through vision provider (may override label/confidence)
    provider_result = get_vision_provider().analyze(validated)
    validated['label'] = provider_result.label
    validated['confidence'] = provider_result.confidence

    serializer = VisionObservationSerializer(data=validated)
    if serializer.is_valid():
        observation = serializer.save(user=request.user)

        # Check for immediate guardian alerts
        immediate_alert = _check_vision_alert(request.user, observation)

        logger.info(
            'Vision observation stored user=%s type=%s label=%s confidence=%.2f alert=%s',
            request.user.username, observation.observation_type,
            observation.label, observation.confidence, bool(immediate_alert),
        )
        return Response({
            'message': 'Vision observation stored.',
            'observation': VisionObservationSerializer(observation).data,
            'guardian_alert_sent': bool(immediate_alert),
        }, status=status.HTTP_201_CREATED)

    return Response(
        {'error': {'code': 'validation_error', 'details': serializer.errors}},
        status=status.HTTP_400_BAD_REQUEST,
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_trip_history(request):
    """
    Get authenticated user's trip history.

    GET /trips/api/history/
    Headers: Authorization: Token <token>
    """
    trips = Trip.objects.filter(user=request.user).order_by('-created_at')[:20]
    return Response({
        'username': request.user.username,
        'trips': TripSerializer(trips, many=True).data,
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def api_safety_zones(request):
    """
    Get all active safety zones (public endpoint).

    GET /trips/api/zones/
    """
    zones = SafetyZone.objects.filter(active=True)
    return Response({'zones': SafetyZoneSerializer(zones, many=True).data})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_weekly_summary(request):
    """
    Get weekly ride safety summary for the authenticated user.

    GET /trips/api/weekly-summary/
    Headers: Authorization: Token <token>
    """
    return Response({
        'username': request.user.username,
        'period_days': 7,
        **_build_weekly_summary(request.user),
    })


# ===========================================================================
# PRIVATE HELPERS
# ===========================================================================

def _distance_meters(lat1, lon1, lat2, lon2):
    """Haversine distance between two GPS coordinates in meters."""
    earth_radius = 6371000
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    a = sin(d_lat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lon / 2) ** 2
    return 2 * earth_radius * asin(sqrt(a))


def _maybe_send_zone_alert(user, zone):
    """Send a guardian alert when user enters a safety zone (debounced 15min)."""
    fifteen_minutes_ago = timezone.now() - timedelta(minutes=15)
    duplicate = EmergencyAlert.objects.filter(
        user=user,
        source='zone',
        location=zone.name,
        created_at__gte=fifteen_minutes_ago,
    ).exists()
    if duplicate:
        return None

    message = f'Entered {zone.name} ({zone.zone_type} zone). Ride carefully.'
    alert = EmergencyAlert.objects.create(
        user=user,
        location=zone.name,
        severity='low',
        source='zone',
        message=message,
        alert_sent=True,
        notes='Automatic zone-entry guardian alert.',
    )
    EscalationEvent.objects.create(alert=alert, stage='guardian_notified', message='Zone-entry alert sent to guardian.')
    notify_guardian(alert, request_call=False)
    return alert


def _check_vision_alert(user, observation):
    """Create an emergency alert if a high-confidence vision violation is detected."""
    immediate_alert = None

    if observation.observation_type == 'helmet' and observation.label == 'not_worn' and observation.confidence >= 0.8:
        immediate_alert = EmergencyAlert.objects.create(
            user=user,
            location='Vision observation',
            severity='medium',
            source='vision',
            message='Helmet not detected during ride.',
            alert_sent=True,
            notes=f'helmet confidence={observation.confidence}',
        )
    elif observation.observation_type == 'red_light' and observation.label == 'violation' and observation.confidence >= 0.85:
        immediate_alert = EmergencyAlert.objects.create(
            user=user,
            location='Vision observation',
            severity='medium',
            source='vision',
            message='Possible red-light violation detected.',
            alert_sent=True,
            notes=f'red-light confidence={observation.confidence}',
        )

    if immediate_alert:
        EscalationEvent.objects.create(
            alert=immediate_alert, stage='guardian_notified',
            message='Vision-based guardian alert sent.',
        )
        notify_guardian(immediate_alert, request_call=False)

    return immediate_alert


def _build_weekly_summary(user):
    """Build a 7-day safety summary for a user."""
    since = timezone.now() - timedelta(days=7)
    trips = Trip.objects.filter(user=user, created_at__gte=since)
    total = trips.count()
    overspeed = trips.filter(alert_triggered=True).count()
    red_light = trips.filter(red_light_crossed=True).count()
    helmet_issues = trips.filter(helmet_worn=False).count()
    zone_visits = trips.exclude(road_type='normal').count()
    avg_risk = round(sum(t.risk_score for t in trips) / total, 1) if total else 0

    tags = []
    for trip in trips:
        tags.extend([tag for tag in trip.tags.split(',') if tag])

    observations = VisionObservation.objects.filter(user=user, created_at__gte=since)
    return {
        'total_trips': total,
        'overspeed_events': overspeed,
        'red_light_events': red_light,
        'helmet_issues': helmet_issues,
        'zone_visits': zone_visits,
        'average_risk': avg_risk,
        'tags': sorted(set(tags)),
        'helmet_observations': observations.filter(observation_type='helmet').count(),
        'red_light_observations': observations.filter(observation_type='red_light').count(),
        'traffic_density_observations': observations.filter(observation_type='traffic_density').count(),
    }
