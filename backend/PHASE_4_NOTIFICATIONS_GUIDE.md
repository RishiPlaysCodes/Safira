# SafeRide Guardian — Phase 4 Notification Layer

Phase 4 adds a notification-ready emergency layer. It does **not** send real SMS/calls yet; it safely simulates them and stores every notification attempt in the database.

## Added

- `NotificationLog` model
- `alerts/notification_service.py`
- simulated SMS, push notification, and phone-call request logs
- `/alerts/notifications/` page
- `/alerts/api/test-notification/` demo API
- accident API now creates notification logs when a serious/confirmed alert is generated

## Why simulation first?

Real notifications require paid/verified services such as:

- Firebase Cloud Messaging for push notifications
- Twilio for SMS and phone calls
- WhatsApp Business API for WhatsApp alerts

For a safe MVP, the app records exactly what would be sent, to whom, when, and through which channel.

## Test manually

1. Add emergency contact.
2. Trigger Manual SOS.
3. Open Notification History.
4. You should see SMS, push, and call logs.

## Test API

POST to:

```text
/alerts/api/test-notification/
```

Example JSON:

```json
{
  "username": "demo",
  "message": "SafeRide test emergency notification",
  "location": "Delhi",
  "request_call": true
}
```

## Real production upgrade

Replace `notify_guardian()` in `alerts/notification_service.py` with:

- Firebase push send function
- Twilio SMS function
- Twilio voice-call function

Keep `NotificationLog` even in production so every alert attempt is auditable.
