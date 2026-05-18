from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient

from .models import SafetyZone


class TripIntelligenceTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='demo', password='pass12345')
        self.client = APIClient()

    def test_zone_is_applied_to_trip_payload(self):
        SafetyZone.objects.create(
            name='Demo School',
            zone_type='school',
            latitude=28.6139,
            longitude=77.2090,
            radius_meters=500,
        )
        response = self.client.post(
            '/trips/api/receive/',
            {
                'username': 'demo',
                'speed': 45,
                'location': '28.6139,77.2090',
                'latitude': 28.6139,
                'longitude': 77.2090,
                'destination': 'Library',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 201)
        self.assertIn('school-zone', response.data['tags'])

    def test_weekly_summary_returns_trip_stats(self):
        self.client.post(
            '/trips/api/receive/',
            {
                'username': 'demo',
                'speed': 55,
                'speed_limit': 40,
                'location': 'Delhi',
                'helmet_worn': False,
                'red_light_crossed': True,
            },
            format='json',
        )
        response = self.client.get('/trips/api/weekly-summary/?username=demo')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['total_trips'], 1)
        self.assertEqual(response.data['overspeed_events'], 1)
        self.assertEqual(response.data['helmet_issues'], 1)
