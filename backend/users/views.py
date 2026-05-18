from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth.models import User
from django.shortcuts import render, redirect
from django.utils import timezone
from datetime import timedelta
from .forms import SignupForm
from .models import DriverProfile


def home(request):
    return render(request, 'users/home.html')


def signup_view(request):
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            user = User.objects.create_user(
                username=form.cleaned_data['username'],
                email=form.cleaned_data['email'],
                password=form.cleaned_data['password']
            )
            DriverProfile.objects.create(
                user=user,
                phone_number=form.cleaned_data['phone_number'],
                vehicle_type=form.cleaned_data['vehicle_type'],
                license_number=form.cleaned_data['license_number'],
                role=form.cleaned_data['role']
            )
            login(request, user)
            return redirect('dashboard')
    else:
        form = SignupForm()
    return render(request, 'users/signup.html', {'form': form})


@login_required
def dashboard_view(request):
    from trips.models import Trip
    from alerts.models import EmergencyContact, EmergencyAlert

    profile, _ = DriverProfile.objects.get_or_create(user=request.user)
    trips = Trip.objects.filter(user=request.user)
    total_trips = trips.count()
    overspeed_alerts = trips.filter(alert_triggered=True).count()
    red_light_violations = trips.filter(red_light_crossed=True).count()
    helmet_violations = trips.filter(helmet_worn=False).count()
    emergency_alerts_sent = EmergencyAlert.objects.filter(user=request.user, alert_sent=True).count()

    penalty = (overspeed_alerts * 10) + (red_light_violations * 15) + (helmet_violations * 10)
    safety_score = max(0, 100 - penalty)

    avg_risk = 0
    if total_trips:
        avg_risk = round(sum(t.risk_score for t in trips) / total_trips, 1)

    since = timezone.now() - timedelta(days=7)
    weekly_trips = trips.filter(created_at__gte=since)
    weekly_total = weekly_trips.count()
    weekly_overspeed = weekly_trips.filter(alert_triggered=True).count()
    weekly_red_light = weekly_trips.filter(red_light_crossed=True).count()
    weekly_helmet = weekly_trips.filter(helmet_worn=False).count()
    weekly_avg_risk = round(sum(t.risk_score for t in weekly_trips) / weekly_total, 1) if weekly_total else 0

    tag_counter = {}
    for trip in weekly_trips:
        for tag in [tag for tag in trip.tags.split(',') if tag]:
            tag_counter[tag] = tag_counter.get(tag, 0) + 1
    weekly_top_tags = sorted(tag_counter.items(), key=lambda item: item[1], reverse=True)[:5]

    zone_visits = weekly_trips.exclude(road_type='normal').count()
    latest_zone_trip = weekly_trips.exclude(road_type='normal').order_by('-created_at').first()

    contact = EmergencyContact.objects.filter(user=request.user).first()
    latest_alert = EmergencyAlert.objects.filter(user=request.user).order_by('-created_at').first()
    latest_trips = trips.order_by('-created_at')[:5]

    return render(request, 'users/dashboard.html', {
        'profile': profile,
        'total_trips': total_trips,
        'overspeed_alerts': overspeed_alerts,
        'red_light_violations': red_light_violations,
        'helmet_violations': helmet_violations,
        'emergency_alerts_sent': emergency_alerts_sent,
        'safety_score': safety_score,
        'avg_risk': avg_risk,
        'contact': contact,
        'latest_alert': latest_alert,
        'latest_trips': latest_trips,
        'weekly_total': weekly_total,
        'weekly_overspeed': weekly_overspeed,
        'weekly_red_light': weekly_red_light,
        'weekly_helmet': weekly_helmet,
        'weekly_avg_risk': weekly_avg_risk,
        'weekly_top_tags': weekly_top_tags,
        'zone_visits': zone_visits,
        'latest_zone_trip': latest_zone_trip,
    })


def login_view(request):
    if request.method == 'POST':
        form = AuthenticationForm(data=request.POST)
        if form.is_valid():
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password')
            user = authenticate(username=username, password=password)
            if user is not None:
                login(request, user)
                return redirect('dashboard')
    else:
        form = AuthenticationForm()
    return render(request, 'users/login.html', {'form': form})


def logout_view(request):
    logout(request)
    return redirect('login')
