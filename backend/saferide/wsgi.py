"""
WSGI config for saferide project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.1/howto/deployment/wsgi/
"""

import os
from pathlib import Path

from django.core.wsgi import get_wsgi_application

# Load .env file if present (for non-Docker deployments)
env_file = Path(__file__).resolve().parent.parent / '.env'
if env_file.exists():
    try:
        from dotenv import load_dotenv
        load_dotenv(env_file)
    except ImportError:
        pass

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'saferide.settings')

application = get_wsgi_application()
