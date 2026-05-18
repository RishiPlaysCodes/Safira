from django.contrib import admin
from .models import DriverProfile

@admin.register(DriverProfile)
class DriverProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'role', 'vehicle_type', 'phone_number']
    list_filter = ['role', 'vehicle_type']
    search_fields = ['user__username', 'phone_number']
