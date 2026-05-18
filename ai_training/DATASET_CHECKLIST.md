# Dataset Checklist

## Helmet model
Minimum useful classes:
- helmet
- no_helmet

Collect images across:
- different helmet colors
- day/night
- front/side views
- different camera distances
- riders with caps/scarves to reduce false positives

## Red-light model
Minimum useful classes:
- red_signal
- green_signal
- yellow_signal
- stop_line

This is harder than helmet detection because violation logic depends on:
- signal state
- rider position
- crossing timing

## Vehicle model
Useful classes:
- car
- bike
- bus
- truck
- auto_rickshaw

Use vehicle detections to estimate density bands:
- low
- medium
- high

## Important
Do not train on only perfect internet images. Include real phone-camera frames from the same angle the app will use during rides.
