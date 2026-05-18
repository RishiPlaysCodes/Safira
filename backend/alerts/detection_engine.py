"""Accident decision engine for SafeRide Guardian Phase 3.

This module keeps the crash/false-alarm logic separate from views so it can be
reused by the web demo, API endpoint, and future mobile app.
"""


def to_bool(value):
    """Convert common API/form values to boolean safely."""
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    return str(value).strip().lower() in {"true", "1", "yes", "y", "on"}


def calculate_accident_risk(
    impact_level=0,
    speed_before=0,
    speed_after=0,
    no_movement_seconds=0,
    phone_angle_changed=False,
    user_confirmed=False,
):
    """Return a structured accident-risk decision.

    The rule is intentionally conservative to reduce false positives:
    - A small bump/pothole alone should NOT alert parents.
    - Normal stopping alone should NOT alert parents.
    - High confidence requires multiple signals together.
    """
    impact_level = int(float(impact_level or 0))
    speed_before = float(speed_before or 0)
    speed_after = float(speed_after or 0)
    no_movement_seconds = int(float(no_movement_seconds or 0))
    phone_angle_changed = to_bool(phone_angle_changed)
    user_confirmed = to_bool(user_confirmed)

    speed_drop = max(speed_before - speed_after, 0)
    score = 0
    reasons = []

    if user_confirmed:
        return {
            "score": 100,
            "severity": "confirmed",
            "guardian_alert_sent": True,
            "parent_call_requested": True,
            "message": "User confirmed accident/emergency. Call guardian immediately.",
            "reasons": ["User manually confirmed accident/emergency."],
            "speed_drop": speed_drop,
        }

    if impact_level >= 8:
        score += 35
        reasons.append("Strong impact/jerk detected.")
    elif impact_level >= 5:
        score += 18
        reasons.append("Medium impact/jerk detected.")
    elif impact_level >= 3:
        score += 6
        reasons.append("Small bump detected; not enough alone.")

    if speed_before >= 25 and speed_drop >= 25 and speed_after <= 8:
        score += 35
        reasons.append("High speed followed by sudden near-stop.")
    elif speed_drop >= 15:
        score += 15
        reasons.append("Moderate speed drop detected.")

    if no_movement_seconds >= 45:
        score += 20
        reasons.append("No movement after event for 45+ seconds.")
    elif no_movement_seconds >= 20:
        score += 10
        reasons.append("No movement after event for 20+ seconds.")

    if phone_angle_changed:
        score += 10
        reasons.append("Phone orientation changed suddenly.")

    if not reasons:
        reasons.append("No serious accident pattern found.")

    if score >= 75:
        severity = "high"
        guardian_alert_sent = True
        parent_call_requested = True
        message = "High accident suspicion detected. Guardian should be notified/called."
    elif score >= 45:
        severity = "medium"
        guardian_alert_sent = False
        parent_call_requested = False
        message = "Medium accident suspicion. Show countdown and ask user to confirm safety."
    else:
        severity = "low"
        guardian_alert_sent = False
        parent_call_requested = False
        message = "Low confidence signal recorded. No guardian alert sent."

    return {
        "score": score,
        "severity": severity,
        "guardian_alert_sent": guardian_alert_sent,
        "parent_call_requested": parent_call_requested,
        "message": message,
        "reasons": reasons,
        "speed_drop": speed_drop,
    }
