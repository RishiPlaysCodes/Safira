"""
URL configuration for saferide project.

API Endpoints Summary:
  - /api/auth/          : Authentication (login, signup, logout, profile)
  - /api/health/        : Health checks (liveness, readiness, detail)
  - /trips/api/         : Trip data, history, zones, vision
  - /alerts/api/        : Accident signals, device registration, notifications
  - /admin/             : Django admin interface
"""

from django.contrib import admin
from django.urls import include, path

from .health import health_detail, health_liveness, health_readiness

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),

    # Health checks (must be accessible without auth)
    path('api/health/', health_liveness, name='health_liveness'),
    path('api/health/ready/', health_readiness, name='health_readiness'),
    path('api/health/detail/', health_detail, name='health_detail'),

    # App URLs
    path('', include('users.urls')),
    path('trips/', include('trips.urls')),
    path('alerts/', include('alerts.urls')),
]
