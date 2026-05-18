from django.contrib import admin
from .models import DeviceRegistration, EmergencyContact, EmergencyAlert, EscalationEvent, NotificationLog

@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ('user', 'contact_name', 'contact_phone', 'relationship')
    search_fields = ('user__username', 'contact_name', 'contact_phone')

@admin.register(EmergencyAlert)
class EmergencyAlertAdmin(admin.ModelAdmin):
    list_display = ('user', 'severity', 'source', 'alert_sent', 'is_cancelled', 'parent_call_requested', 'ambulance_requested', 'created_at')
    list_filter = ('severity', 'source', 'alert_sent', 'is_cancelled', 'parent_call_requested', 'ambulance_requested', 'created_at')
    search_fields = ('user__username', 'location', 'message')

@admin.register(EscalationEvent)
class EscalationEventAdmin(admin.ModelAdmin):
    list_display = ('alert', 'stage', 'status', 'created_at')
    list_filter = ('stage', 'status', 'created_at')

admin.site.register(NotificationLog)
admin.site.register(DeviceRegistration)
