from django.db import models
from django.contrib.auth.models import User

class DriverProfile(models.Model):

    VEHICLE_CHOICES = [
        ('bike', 'Bike'),
        ('car', 'Car'),
        ('scooter', 'Scooter'),
    ]

    ROLE_CHOICES = [
        ('driver', 'Driver'),
        ('parent', 'Parent'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone_number = models.CharField(max_length=15, blank=True)
    vehicle_type = models.CharField(max_length=20, choices=VEHICLE_CHOICES, default='bike')
    license_number = models.CharField(max_length=30, blank=True)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='driver')

    def __str__(self):
        return f"{self.user.username} - {self.role}"
# Create your models here.
