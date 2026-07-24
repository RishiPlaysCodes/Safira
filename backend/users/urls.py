from django.urls import path
from . import views
from . import api_views

urlpatterns = [
    # Web views (session-based auth)
    path('signup/', views.signup_view, name='signup'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('', views.home, name='home'),

    # API authentication endpoints (token-based)
    path('api/auth/login/', api_views.api_login, name='api_login'),
    path('api/auth/signup/', api_views.api_signup, name='api_signup'),
    path('api/auth/logout/', api_views.api_logout, name='api_logout'),
    path('api/auth/profile/', api_views.api_profile, name='api_profile'),
    path('api/auth/change-password/', api_views.api_change_password, name='api_change_password'),
    path('api/auth/refresh-token/', api_views.api_refresh_token, name='api_refresh_token'),
]
