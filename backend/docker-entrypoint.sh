#!/bin/bash
set -e

echo "=== SafeRide Guardian - Starting ==="

# Wait for database to be ready
echo "Waiting for database..."
for i in $(seq 1 30); do
    python -c "
import os, sys
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'saferide.settings')
import django
django.setup()
from django.db import connections
try:
    connections['default'].cursor()
    sys.exit(0)
except Exception:
    sys.exit(1)
" 2>/dev/null && break
    echo "  Attempt $i/30 - database not ready, waiting..."
    sleep 2
done

# Run migrations
echo "Running database migrations..."
python manage.py migrate --noinput

# Collect static files (if not already done in build)
echo "Collecting static files..."
python manage.py collectstatic --noinput 2>/dev/null || true

echo "=== SafeRide Guardian - Ready ==="

# Execute the CMD
exec "$@"
