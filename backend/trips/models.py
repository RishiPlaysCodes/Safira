from django.db import models
from django.contrib.auth.models import User


class Trip(models.Model):
    ROAD_TYPE_CHOICES = [
        ('normal', 'Normal Road'),
        ('school', 'School Zone'),
        ('hospital', 'Hospital Zone'),
        ('market', 'Market/Crowded Area'),
        ('highway', 'Highway'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    speed = models.IntegerField(help_text='Speed in km/h')
    speed_limit = models.IntegerField(default=40)
    location = models.CharField(max_length=120, blank=True)
    destination = models.CharField(max_length=160, blank=True)
    road_type = models.CharField(max_length=20, choices=ROAD_TYPE_CHOICES, default='normal')
    helmet_worn = models.BooleanField(default=True)
    red_light_crossed = models.BooleanField(default=False)
    harsh_braking = models.BooleanField(default=False)
    sudden_acceleration = models.BooleanField(default=False)
    alert_triggered = models.BooleanField(default=False)
    overspeed_count = models.IntegerField(default=0)
    risk_score = models.IntegerField(default=0)
    notes = models.TextField(blank=True)
    tags = models.CharField(max_length=220, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def calculate_risk(self):
        score = 0
        if self.speed > self.speed_limit:
            score += 30
        if self.red_light_crossed:
            score += 30
        if not self.helmet_worn:
            score += 20
        if self.harsh_braking:
            score += 10
        if self.sudden_acceleration:
            score += 10
        if self.road_type in {'school', 'hospital', 'market'}:
            score += 5
        return min(score, 100)

    def calculate_tags(self):
        tags = []
        if self.speed > self.speed_limit:
            tags.append('overspeed')
        if self.red_light_crossed:
            tags.append('red-light')
        if not self.helmet_worn:
            tags.append('helmet-missing')
        if self.harsh_braking:
            tags.append('harsh-braking')
        if self.sudden_acceleration:
            tags.append('sudden-acceleration')
        if self.road_type != 'normal':
            tags.append(f'{self.road_type}-zone')
        return ','.join(tags)

    def save(self, *args, **kwargs):
        self.alert_triggered = self.speed > self.speed_limit
        self.overspeed_count = 1 if self.alert_triggered else 0
        self.risk_score = self.calculate_risk()
        self.tags = self.calculate_tags()
        super().save(*args, **kwargs)

    def __str__(self):
        return f'{self.user.username} - {self.speed} km/h - Risk {self.risk_score}'


class SafetyZone(models.Model):
    ZONE_TYPE_CHOICES = [
        ('school', 'School Zone'),
        ('hospital', 'Hospital Zone'),
        ('market', 'Market/Crowded Area'),
        ('danger', 'Danger Zone'),
    ]

    name = models.CharField(max_length=120)
    zone_type = models.CharField(max_length=20, choices=ZONE_TYPE_CHOICES)
    latitude = models.FloatField()
    longitude = models.FloatField()
    radius_meters = models.IntegerField(default=250)
    active = models.BooleanField(default=True)

    def __str__(self):
        return f'{self.name} ({self.zone_type})'


class VisionObservation(models.Model):
    OBSERVATION_TYPES = [
        ('helmet', 'Helmet'),
        ('red_light', 'Red Light'),
        ('traffic_density', 'Traffic Density'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    trip = models.ForeignKey(Trip, on_delete=models.SET_NULL, null=True, blank=True, related_name='vision_observations')
    observation_type = models.CharField(max_length=30, choices=OBSERVATION_TYPES)
    label = models.CharField(max_length=80)
    confidence = models.FloatField(default=0)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.user.username} - {self.observation_type} - {self.label}'
