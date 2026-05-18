# Advanced AI Architecture Roadmap

## Goal
Turn the current SafeRide system into an intelligent road-safety platform without making the beginner-readable codebase messy.

The present app already has a strong practical base:
- live GPS tracking
- speed monitoring
- accident suspicion + countdown
- parent alerts
- Firebase push notifications
- destination support
- safety zones
- trip tags and risk score
- weekly reports

The next stage should add intelligence in layers instead of mixing everything into one large feature.

---

## 1. Recommended High-Level Architecture

### A. Mobile App Layer
Responsible for:
- live GPS and motion sensors
- camera capture when user allows it
- local accident countdown UI
- route destination input
- showing warnings, score, and notifications

Keep mobile modules separate:
- `location_service`
- `sensor_service`
- `camera_service`
- `vision_result_service`
- `accident_detector`
- `notification_service`

### B. Backend API Layer
Responsible for:
- storing trips
- storing zone visits
- storing AI results
- calculating weekly reports
- sending parent notifications
- triggering escalation workflow

Recommended future backend apps/modules:
- `vision`
- `risk_engine`
- `reports`
- `dispatch`

### C. Intelligence Layer
This should stay separate from normal CRUD logic.

It should include:
1. **Helmet detector**
2. **Red-light violation detector**
3. **Vehicle-density estimator**
4. **Risk scoring engine**
5. **Accident confidence engine**

---

## 2. Feature-by-Feature Design

## Helmet Detection
### Best practical design
- Use phone camera or helmet-mounted camera only when user enables ride mode.
- Run lightweight image inference on sampled frames, not full video all the time.
- Store only detection results, not personal video, unless user explicitly allows recording.

### Backend fields to add later
- `helmet_status`: worn / not_worn / unknown
- `helmet_confidence`
- `helmet_checked_at`

### Parent alert rule
- If `helmet_status = not_worn` for multiple checks in a row, create a guardian alert.
- Do **not** alert on one uncertain frame.

---

## Red-Light Violation Detection
### Best practical design
This cannot be trusted from GPS alone.
It needs one of these:
1. camera vision that recognizes traffic lights + crossing line, or
2. city traffic-light data integration where available.

### Safer rollout
- Version 1: manual/admin-tagged traffic-light zones + user speed crossing logic
- Version 2: camera-based signal recognition
- Version 3: city-data integration where available

### Parent alert rule
- Use it for score/reporting first.
- Send immediate parent alert only after high-confidence repeated violations, not a single weak estimate.

---

## Nearby Vehicle Count / Traffic Density
### Best practical design
Do not try to estimate exact vehicle count from GPS.
Use one of:
- camera-based object detection
- map/traffic provider API
- crowd-sourced traffic signals later

### Use in app
- show `low / medium / high traffic density`
- increase trip risk score in dense traffic zones
- include in weekly report

---

## Destination + Navigation Substitute
### Current state
- destination input already exists
- free map is already available through OpenStreetMap

### Next improvements
- route preview
- ETA estimate
- route safety score
- warning tags on route: school-zone, hospital-zone, danger-zone
- later: turn-by-turn navigation if a routing engine/API is added

---

## Weekly Parent Report
### Should include
- total rides
- total distance
- average risk score
- overspeed count
- harsh braking count
- school/danger zone visits
- red-light events
- helmet-missing events
- accident/suspicion events
- best ride and riskiest ride

### Message example
> This week: 12 rides, safety score 82/100, 3 overspeed events, 1 school-zone overspeed, helmet missing twice.

---

## Accident Escalation Workflow
### Recommended real-world flow
1. Strong signal detected: impact + speed drop + motion abnormality
2. App shows countdown on rider phone
3. Guardian gets low-priority warning immediately
4. If rider taps **I am safe**, escalation stops
5. If rider taps **Need help** or timer expires:
   - guardian gets confirmed alert
   - auto-call guardian
   - SMS/push with live location
6. Ambulance dispatch should happen only after:
   - rider confirms, or
   - guardian confirms, or
   - very high-confidence multi-signal event with no response

### Why this is important
Automatic ambulance calls on weak signals create dangerous false positives.

---

## 3. Data Model Additions for the Next Phase

### Suggested new models
#### `VisionObservation`
- user
- trip
- type: helmet / signal / vehicle_density
- label
- confidence
- latitude
- longitude
- created_at

#### `RoutePlan`
- user
- origin
- destination
- estimated_distance
- estimated_duration
- route_safety_score

#### `WeeklySafetyReport`
- user
- week_start
- week_end
- total_trips
- overspeed_events
- red_light_events
- helmet_missing_events
- zone_events
- average_score
- summary_text

#### `EscalationEvent`
- alert
- stage: suspicion / guardian_notified / rider_confirmed / ambulance_requested
- status
- created_at

---

## 4. What Can Be Built Without Extra Hardware or Paid Services

Can be built now:
- destination routes UI
- better weekly reports
- richer safety score
- zone-aware parent warnings
- incident escalation stages
- admin dashboard for AI observations
- manual helmet / red-light reporting hooks

Needs extra AI/data/hardware later:
- real helmet recognition
- reliable red-light recognition
- accurate vehicle counting
- true ambulance dispatch integration
- production traffic intelligence

---

## 5. Recommended Build Order

### Phase A — Product polish now
- richer dashboard
- better weekly reports
- route safety score
- zone history
- escalation timeline

### Phase B — AI-ready backend
- add `VisionObservation`
- add APIs for helmet/red-light/traffic observations
- include those signals in scoring and reports

### Phase C — Real AI prototypes
- helmet detection model
- red-light detection model
- vehicle density model

### Phase D — Production integrations
- ambulance partner workflow
- traffic data provider
- stronger privacy controls
- model monitoring and retraining

---

## 6. Final Recommendation
Do **not** jump directly into heavy AI first.

The strongest next move is:
1. finish the rich dashboard + weekly reporting experience
2. add AI-ready backend tables/APIs
3. then plug in camera models one by one

That gives you a real app now, while keeping the door open for a much more advanced system later.
