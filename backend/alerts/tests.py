from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient

from .models import DeviceRegistration, EmergencyAlert


class MobileIntegrationTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='demo', password='pass12345')
        self.client = APIClient()

    def test_register_device(self):
        response = self.client.post(
            '/alerts/api/register-device/',
            {'username': 'demo', 'token': 'abc123', 'platform': 'android'},
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertTrue(DeviceRegistration.objects.filter(user=self.user, token='abc123').exists())

    def test_mobile_confirmed_alert_payload_is_accepted(self):
        response = self.client.post(
            '/alerts/api/accident-signal/',
            {
                'username': 'demo',
                'status': 'confirmed_no_response',
                'speed': 2,
                'impact_g': 3.5,
                'latitude': 28.61,
                'longitude': 77.20,
                'location': 'https://maps.google.com/?q=28.61,77.20',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        alert = EmergencyAlert.objects.latest('created_at')
        self.assertEqual(alert.severity, 'confirmed')
        self.assertTrue(alert.alert_sent)
