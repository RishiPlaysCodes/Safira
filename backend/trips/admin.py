from django.contrib import admin
from .models import SafetyZone, Trip, VisionObservation

@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ('user', 'speed', 'speed_limit', 'risk_score', 'alert_triggered', 'red_light_crossed', 'helmet_worn', 'created_at')
    list_filter = ('alert_triggered', 'red_light_crossed', 'helmet_worn', 'road_type', 'created_at')
    search_fields = ('user__username', 'location')


@admin.register(SafetyZone)
class SafetyZoneAdmin(admin.ModelAdmin):
    list_display = ('name', 'zone_type', 'latitude', 'longitude', 'radius_meters', 'active')
    list_filter = ('zone_type', 'active')
    search_fields = ('name',)


@admin.register(VisionObservation)
class VisionObservationAdmin(admin.ModelAdmin):
    list_display = ('user', 'observation_type', 'label', 'confidence', 'created_at')
    list_filter = ('observation_type', 'label', 'created_at')
    search_fields = ('user__username', 'label')
