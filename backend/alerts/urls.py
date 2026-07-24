from django.urls import path
from . import views

urlpatterns = [
    # Web views (session-based auth)
    path('contact/', views.emergency_contact_view, name='emergency_contact'),
    path('simulate-accident/', views.accident_simulation, name='accident_simulation'),
    path('manual-sos/', views.manual_sos, name='manual_sos'),
    path('cancel/<int:alert_id>/', views.cancel_alert, name='cancel_alert'),
    path('confirm/<int:alert_id>/', views.confirm_accident, name='confirm_accident'),
    path('send/<int:alert_id>/', views.send_emergency_alert, name='send_emergency_alert'),
    path('history/', views.alert_history, name='alert_history'),
    path('notifications/', views.notification_history, name='notification_history'),
    path('detector-demo/', views.accident_detector_demo, name='accident_detector_demo'),

    # API endpoints (token-based auth)
    path('api/accident-signal/', views.receive_accident_signal, name='receive_accident_signal'),
    path('api/register-device/', views.register_device, name='register_device'),
    path('api/test-notification/', views.test_notification_api, name='test_notification_api'),
    path('api/history/', views.api_alert_history, name='api_alert_history'),
]
