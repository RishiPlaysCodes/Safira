# SafeRide Guardian — Testing Checklist

Run from the folder containing `manage.py`:

```bash
python manage.py migrate
python manage.py runserver
```

Open: http://127.0.0.1:8000/

## 1. Authentication
- Open `/signup/`
- Create a new user
- Confirm dashboard opens
- Logout
- Login again
- Confirm dashboard is protected

## 2. Dashboard
Check dashboard shows:
- profile
- trips count
- overspeed alerts
- safety score
- badge
- emergency contact
- latest alert status

## 3. Trips
- Create trip with speed below 40
- Create trip with speed above 40
- Open trip history
- Confirm overspeed alert true for high-speed trip
- Open safety report

## 4. Emergency contact
- Add contact
- Confirm dashboard shows contact
- Edit contact

## 5. Accident simulation
- Simulate accident
- Click “I am safe” before timer ends
- Confirm cancelled alert
- Simulate again
- Let timer finish
- Confirm alert sent
- Check alert history

## 6. Admin panel
Create superuser:

```bash
python manage.py createsuperuser
```

Open `/admin/` and verify:
- Users
- Driver Profiles
- Trips
- Emergency Contacts
- Emergency Alerts
