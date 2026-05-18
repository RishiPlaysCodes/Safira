from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect
from .forms import TripForm
from datetime import timedelta
from math import asin, cos, radians, sin, sqrt

from django.utils import timezone

from .models import SafetyZone, Trip, VisionObservation
from .serializers import SafetyZoneSerializer, TripSerializer, VisionObservationSerializer
from django.contrib.auth.models import User
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from alerts.models import EmergencyAlert, EscalationEvent
from alerts.notification_service import notify_guardian
from integrations.vision import get_vision_provider


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


def _distance_meters(lat1, lon1, lat2, lon2):
    earth_radius = 6371000
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    a = sin(d_lat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lon / 2) ** 2
    return 2 * earth_radius * asin(sqrt(a))


def _api_user_from_request(request):
    if request.user and request.user.is_authenticated:
        return request.user
    username = request.data.get('username')
    if username:
        return User.objects.filter(username=username).first()
    return None


def _maybe_send_zone_alert(user, zone):
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


@api_view(['POST'])
def receive_trip_data(request):
    api_user = _api_user_from_request(request)
    if api_user is None:
        return Response({'error': 'Login first or send a valid username field for demo API testing.'}, status=status.HTTP_401_UNAUTHORIZED)

    payload = request.data.copy()
    latitude = payload.get('latitude')
    longitude = payload.get('longitude')
    nearby_zone = None
    if latitude is not None and longitude is not None:
        for zone in SafetyZone.objects.filter(active=True):
            if _distance_meters(float(latitude), float(longitude), zone.latitude, zone.longitude) <= zone.radius_meters:
                nearby_zone = zone
                break
        if nearby_zone:
            payload['road_type'] = nearby_zone.zone_type if nearby_zone.zone_type != 'danger' else 'market'
            payload['notes'] = f'Entered zone: {nearby_zone.name}'

    serializer = TripSerializer(data=payload)
    if serializer.is_valid():
        trip = serializer.save(user=api_user)
        zone_alert = _maybe_send_zone_alert(api_user, nearby_zone) if nearby_zone else None
        return Response({
            'message': 'Trip data received successfully.',
            'trip': TripSerializer(trip).data,
            'overspeed': trip.alert_triggered,
            'risk_score': trip.risk_score,
            'tags': trip.tags.split(',') if trip.tags else [],
            'zone_alert_sent': bool(zone_alert),
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def api_vision_observation(request):
    api_user = _api_user_from_request(request)
    if api_user is None:
        return Response({'error': 'Login first or send a valid username.'}, status=status.HTTP_401_UNAUTHORIZED)

    provider_result = get_vision_provider().analyze(request.data)
    payload = request.data.copy()
    payload['label'] = provider_result.label
    payload['confidence'] = provider_result.confidence
    serializer = VisionObservationSerializer(data=payload)
    if serializer.is_valid():
        observation = serializer.save(user=api_user)
        immediate_alert = None
        if observation.observation_type == 'helmet' and observation.label == 'not_worn' and observation.confidence >= 0.8:
            immediate_alert = EmergencyAlert.objects.create(
                user=api_user,
                location='Vision observation',
                severity='medium',
                source='vision',
                message='Helmet not detected during ride.',
                alert_sent=True,
                notes=f'helmet confidence={observation.confidence}',
            )
        elif observation.observation_type == 'red_light' and observation.label == 'violation' and observation.confidence >= 0.85:
            immediate_alert = EmergencyAlert.objects.create(
                user=api_user,
                location='Vision observation',
                severity='medium',
                source='vision',
                message='Possible red-light violation detected.',
                alert_sent=True,
                notes=f'red-light confidence={observation.confidence}',
            )
        if immediate_alert:
            EscalationEvent.objects.create(alert=immediate_alert, stage='guardian_notified', message='Vision-based guardian alert sent.')
            notify_guardian(immediate_alert, request_call=False)
        return Response({
            'message': 'Vision observation stored.',
            'observation': VisionObservationSerializer(observation).data,
            'guardian_alert_sent': bool(immediate_alert),
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def api_trip_history(request):
    api_user = request.user if request.user and request.user.is_authenticated else None
    username = request.GET.get('username')
    if api_user is None and username:
        api_user = User.objects.filter(username=username).first()
    if api_user is None:
        return Response({'error': 'Login first or pass ?username=your_username for demo API testing.'}, status=status.HTTP_401_UNAUTHORIZED)
    trips = Trip.objects.filter(user=api_user).order_by('-created_at')[:20]
    return Response({'username': api_user.username, 'trips': TripSerializer(trips, many=True).data})


@api_view(['GET'])
def api_safety_zones(request):
    zones = SafetyZone.objects.filter(active=True)
    return Response({'zones': SafetyZoneSerializer(zones, many=True).data})


def _build_weekly_summary(api_user):
    since = timezone.now() - timedelta(days=7)
    trips = Trip.objects.filter(user=api_user, created_at__gte=since)
    total = trips.count()
    overspeed = trips.filter(alert_triggered=True).count()
    red_light = trips.filter(red_light_crossed=True).count()
    helmet_issues = trips.filter(helmet_worn=False).count()
    zone_visits = trips.exclude(road_type='normal').count()
    avg_risk = round(sum(t.risk_score for t in trips) / total, 1) if total else 0
    tags = []
    for trip in trips:
        tags.extend([tag for tag in trip.tags.split(',') if tag])
    observations = VisionObservation.objects.filter(user=api_user, created_at__gte=since)
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


@api_view(['GET'])
def api_weekly_summary(request):
    api_user = request.user if request.user and request.user.is_authenticated else None
    username = request.GET.get('username')
    if api_user is None and username:
        api_user = User.objects.filter(username=username).first()
    if api_user is None:
        return Response({'error': 'Login first or pass ?username=your_username.'}, status=status.HTTP_401_UNAUTHORIZED)
    return Response({'username': api_user.username, 'period_days': 7, **_build_weekly_summary(api_user)})


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
    alert = EmergencyAlert.objects.create(user=request.user, location='Weekly report', severity='low', source='demo', message=message, alert_sent=True)
    EscalationEvent.objects.create(alert=alert, stage='guardian_notified', message='Weekly report sent to guardian.')
    notify_guardian(alert, request_call=False)
    return redirect('weekly_report')

