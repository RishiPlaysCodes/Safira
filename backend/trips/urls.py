from django.urls import path
from . import views

urlpatterns = [
    path('create/', views.create_trip, name='create_trip'),
    path('history/', views.trip_history, name='trip_history'),
    path('gps/', views.gps_tracker, name='gps_tracker'),
    path('report/', views.safety_report, name='safety_report'),
    path('weekly-report/', views.weekly_report_view, name='weekly_report'),
    path('weekly-report/send/', views.send_weekly_report, name='send_weekly_report'),
    path('api/receive/', views.receive_trip_data, name='receive_trip_data'),
    path('api/history/', views.api_trip_history, name='api_trip_history'),
    path('api/zones/', views.api_safety_zones, name='api_safety_zones'),
    path('api/weekly-summary/', views.api_weekly_summary, name='api_weekly_summary'),
    path('api/vision-observation/', views.api_vision_observation, name='api_vision_observation'),
]
