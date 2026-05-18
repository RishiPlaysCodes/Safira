# External Provider Setup

The project now supports two modes:

## 1. Free mode (default)
No paid account required.

```env
NOTIFICATION_PROVIDER=free
AMBULANCE_PROVIDER=free
VISION_PROVIDER=free_manual
TRAFFIC_PROVIDER=free_manual
```

What free mode does:
- Firebase push still works when configured
- SMS/call/ambulance actions are logged as simulated workflows
- helmet/red-light/traffic observations can come from the mobile app or a future on-device model

## 2. Real provider mode
Use this only when you decide to connect outside services.

```env
NOTIFICATION_PROVIDER=twilio
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM_NUMBER=

AMBULANCE_PROVIDER=webhook
AMBULANCE_WEBHOOK_URL=

VISION_PROVIDER=on_device
TRAFFIC_PROVIDER=external_api
```

## Why this matters
The app does not need to be rewritten later. Free mode and paid mode use the same product logic; only the provider adapter changes.

## Current adapters included
- `free_simulated` notifications
- `twilio` notification adapter scaffold
- `free_simulated` ambulance adapter
- `webhook` ambulance adapter
- `free_manual` vision adapter
- `on_device` vision adapter
- `free_manual` traffic adapter
- `external_api` traffic adapter scaffold
