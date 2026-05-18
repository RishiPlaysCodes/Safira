from rest_framework import serializers
from .models import DeviceRegistration, EmergencyAlert, EmergencyContact, EscalationEvent


class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = ['contact_name', 'contact_phone', 'relationship']


class EscalationEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = EscalationEvent
        fields = ['stage', 'status', 'message', 'created_at']


class EmergencyAlertSerializer(serializers.ModelSerializer):
    escalation_events = EscalationEventSerializer(many=True, read_only=True)

    class Meta:
        model = EmergencyAlert
        fields = [
            'id', 'location', 'message', 'severity', 'source', 'is_cancelled',
            'alert_sent', 'parent_call_requested', 'ambulance_requested', 'notes',
            'created_at', 'escalation_events',
        ]
        read_only_fields = ['id', 'alert_sent', 'parent_call_requested', 'ambulance_requested', 'created_at']


class DeviceRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceRegistration
        fields = ['token', 'platform', 'is_active', 'updated_at']
        read_only_fields = ['updated_at']
