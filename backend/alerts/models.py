from django.db import models
from django.contrib.auth.models import User


class EmergencyContact(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    contact_name = models.CharField(max_length=100)
    contact_phone = models.CharField(max_length=15)
    relationship = models.CharField(max_length=50, blank=True)

    def __str__(self):
        return f'{self.user.username} - {self.contact_name}'


class EmergencyAlert(models.Model):
    SEVERITY_CHOICES = [
        ('low', 'Low Suspicion'),
        ('medium', 'Medium Suspicion'),
        ('high', 'High Suspicion'),
        ('confirmed', 'User Confirmed Accident'),
    ]

    SOURCE_CHOICES = [
        ('demo', 'Demo/Simulation'),
        ('speed_drop', 'Speed Drop'),
        ('impact', 'Impact/Jerk'),
        ('manual', 'Manual SOS'),
        ('zone', 'Safety Zone'),
        ('vision', 'Vision Observation'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    location = models.CharField(max_length=220, blank=True)
    message = models.TextField(default='Accident-like event detected. Please check immediately.')
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='medium')
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES, default='demo')
    is_cancelled = models.BooleanField(default=False)
    alert_sent = models.BooleanField(default=False)
    parent_call_requested = models.BooleanField(default=False)
    ambulance_requested = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Alert for {self.user.username} - {self.severity} - {self.created_at}'


class NotificationLog(models.Model):
    CHANNEL_CHOICES = [
        ('sms', 'SMS'),
        ('call', 'Phone Call'),
        ('push', 'Push Notification'),
        ('email', 'Email'),
        ('ambulance', 'Ambulance Dispatch'),
    ]

    STATUS_CHOICES = [
        ('simulated', 'Simulated'),
        ('queued', 'Queued'),
        ('sent', 'Sent'),
        ('failed', 'Failed'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    alert = models.ForeignKey(EmergencyAlert, on_delete=models.CASCADE, related_name='notification_logs')
    channel = models.CharField(max_length=20, choices=CHANNEL_CHOICES)
    recipient = models.CharField(max_length=100)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='simulated')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.channel.upper()} to {self.recipient} - {self.status}'


class DeviceRegistration(models.Model):
    PLATFORM_CHOICES = [
        ('android', 'Android'),
        ('ios', 'iOS'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='devices')
    token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=20, choices=PLATFORM_CHOICES, default='android')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'{self.user.username} - {self.platform}'


class EscalationEvent(models.Model):
    STAGE_CHOICES = [
        ('suspicion', 'Suspicion'),
        ('guardian_notified', 'Guardian Notified'),
        ('rider_safe', 'Rider Marked Safe'),
        ('rider_confirmed', 'Rider Confirmed Accident'),
        ('ambulance_requested', 'Ambulance Requested'),
    ]

    alert = models.ForeignKey(EmergencyAlert, on_delete=models.CASCADE, related_name='escalation_events')
    stage = models.CharField(max_length=30, choices=STAGE_CHOICES)
    status = models.CharField(max_length=30, default='created')
    message = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.alert_id} - {self.stage}'
