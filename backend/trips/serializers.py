from rest_framework import serializers
from .models import SafetyZone, Trip, VisionObservation


class TripSerializer(serializers.ModelSerializer):
    class Meta:
        model = Trip
        fields = [
            'id', 'speed', 'speed_limit', 'location', 'destination', 'road_type',
            'helmet_worn', 'red_light_crossed', 'harsh_braking', 'sudden_acceleration',
            'alert_triggered', 'overspeed_count', 'risk_score', 'notes', 'tags', 'created_at',
        ]
        read_only_fields = ['id', 'alert_triggered', 'overspeed_count', 'risk_score', 'tags', 'created_at']


class SafetyZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = SafetyZone
        fields = ['id', 'name', 'zone_type', 'latitude', 'longitude', 'radius_meters']


class VisionObservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = VisionObservation
        fields = ['id', 'trip', 'observation_type', 'label', 'confidence', 'latitude', 'longitude', 'created_at']
        read_only_fields = ['id', 'created_at']
