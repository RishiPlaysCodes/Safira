# SafeRide Guardian — Code Study Guide

Study this project in this order.

## 1. Project structure
Understand:
- `saferide/` = main project settings and main URLs
- `users/` = authentication and profile
- `trips/` = trip records, speed logic, safety reports
- `alerts/` = emergency contacts and accident alerts

## 2. Models
Read:
- `users/models.py`
- `trips/models.py`
- `alerts/models.py`

Focus on:
- `OneToOneField` for one user → one profile/contact
- `ForeignKey` for one user → many trips/alerts
- Boolean fields for alert states
- timestamps with `auto_now_add=True`

## 3. Forms
Read:
- `users/forms.py`
- `trips/forms.py`
- `alerts/forms.py`

Understand:
- forms validate user input
- ModelForm creates form fields from models
- forms do not replace HTML templates; they help validation and data handling

## 4. Views
Read:
- `users/views.py`
- `trips/views.py`
- `alerts/views.py`

Understand:
- views are the brain/controller
- views connect forms, models, templates, and redirects
- `request.user` means current logged-in user
- `login_required` protects private pages

## 5. URLs
Read:
- `saferide/urls.py`
- `users/urls.py`
- `trips/urls.py`
- `alerts/urls.py`

Flow:
```text
Browser URL → main urls.py → app urls.py → view function → template/database
```

## 6. Templates
Read templates inside:
- `users/templates/users/`
- `trips/templates/trips/`
- `alerts/templates/alerts/`

Understand:
- `{{ variable }}` displays dynamic data
- `{% if %}`, `{% for %}` are template logic tags
- `{% csrf_token %}` protects POST forms

## 7. Migrations
Commands:
```bash
python manage.py makemigrations
python manage.py migrate
```

Meaning:
- `makemigrations` creates database-change files
- `migrate` applies them to SQLite database

## 8. After studying
Try modifying:
- safety score formula
- badge names
- default speed limit
- emergency countdown seconds
- dashboard card text
