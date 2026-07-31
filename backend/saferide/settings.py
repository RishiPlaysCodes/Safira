"""
Django settings for saferide project.

Production-ready configuration with environment variable support.
All sensitive values are loaded from environment variables.
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# ---------------------------------------------------------------------------
# SECURITY SETTINGS
# ---------------------------------------------------------------------------

SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', '')
if not SECRET_KEY:
    raise ValueError(
        "DJANGO_SECRET_KEY environment variable is required. "
        "Generate one with: python -c \"from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())\""
    )

DEBUG = os.environ.get('DJANGO_DEBUG', 'False').lower() in ('true', '1', 'yes')

ALLOWED_HOSTS = [
    host.strip()
    for host in os.environ.get('DJANGO_ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')
    if host.strip()
]


# ---------------------------------------------------------------------------
# APPLICATION DEFINITION
# ---------------------------------------------------------------------------

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third-party
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    # Local apps
    'users',
    'trips',
    'alerts',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'saferide.middleware.RequestLoggingMiddleware',
]

ROOT_URLCONF = 'saferide.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'saferide.wsgi.application'


# ---------------------------------------------------------------------------
# DATABASE
# ---------------------------------------------------------------------------

DATABASES = {
    'default': {
        'ENGINE': os.environ.get('DB_ENGINE', 'django.db.backends.postgresql'),
        'NAME': os.environ.get('DB_NAME', 'saferide'),
        'USER': os.environ.get('DB_USER', 'saferide'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
        'CONN_MAX_AGE': int(os.environ.get('DB_CONN_MAX_AGE', '600')),
        'OPTIONS': {
            'connect_timeout': 5,
        },
    }
}

# Allow SQLite for local development if explicitly set
if os.environ.get('DB_ENGINE') == 'django.db.backends.sqlite3':
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / os.environ.get('DB_NAME', 'db.sqlite3'),
    }

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# ---------------------------------------------------------------------------
# PASSWORD VALIDATION
# ---------------------------------------------------------------------------

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', 'OPTIONS': {'min_length': 10}},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]


# ---------------------------------------------------------------------------
# INTERNATIONALIZATION
# ---------------------------------------------------------------------------

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True


# ---------------------------------------------------------------------------
# STATIC FILES
# ---------------------------------------------------------------------------

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STORAGES = {
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage',
    },
}


# ---------------------------------------------------------------------------
# AUTHENTICATION & SESSIONS
# ---------------------------------------------------------------------------

LOGIN_URL = '/login/'
LOGIN_REDIRECT_URL = '/dashboard/'
LOGOUT_REDIRECT_URL = '/login/'

SESSION_COOKIE_AGE = 60 * 60 * 8  # 8 hours
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'

# Production-only cookie settings (HTTPS)
if not DEBUG:
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_SSL_REDIRECT = True
    SECURE_HSTS_SECONDS = 31536000  # 1 year
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_BROWSER_XSS_FILTER = True
    X_FRAME_OPTIONS = 'DENY'


# ---------------------------------------------------------------------------
# CORS CONFIGURATION
# ---------------------------------------------------------------------------

CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get('CORS_ALLOWED_ORIGINS', 'http://localhost:3000').split(',')
    if origin.strip()
]
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]


# ---------------------------------------------------------------------------
# REST FRAMEWORK
# ---------------------------------------------------------------------------

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': os.environ.get('THROTTLE_ANON', '20/minute'),
        'user': os.environ.get('THROTTLE_USER', '120/minute'),
        'accident_signal': os.environ.get('THROTTLE_ACCIDENT', '10/minute'),
        'auth': os.environ.get('THROTTLE_AUTH', '5/minute'),
    },
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'EXCEPTION_HANDLER': 'saferide.exception_handler.custom_exception_handler',
}

# Add BrowsableAPIRenderer only in DEBUG mode
if DEBUG:
    REST_FRAMEWORK['DEFAULT_RENDERER_CLASSES'].append(
        'rest_framework.renderers.BrowsableAPIRenderer'
    )


# ---------------------------------------------------------------------------
# FIREBASE / PUSH NOTIFICATIONS
# ---------------------------------------------------------------------------

FIREBASE_CREDENTIALS_PATH = os.environ.get('FIREBASE_CREDENTIALS_PATH', '')


# ---------------------------------------------------------------------------
# EXTERNAL PROVIDER CONFIGURATION
# ---------------------------------------------------------------------------

NOTIFICATION_PROVIDER = os.environ.get('NOTIFICATION_PROVIDER', 'free')
TWILIO_ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID', '')
TWILIO_AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN', '')
TWILIO_FROM_NUMBER = os.environ.get('TWILIO_FROM_NUMBER', '')

AMBULANCE_PROVIDER = os.environ.get('AMBULANCE_PROVIDER', 'free')
AMBULANCE_WEBHOOK_URL = os.environ.get('AMBULANCE_WEBHOOK_URL', '')

VISION_PROVIDER = os.environ.get('VISION_PROVIDER', 'free_manual')
TRAFFIC_PROVIDER = os.environ.get('TRAFFIC_PROVIDER', 'free_manual')


# ---------------------------------------------------------------------------
# LOGGING CONFIGURATION
# ---------------------------------------------------------------------------

LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')

# On serverless platforms (Cloud Run, App Engine, Heroku) logs should go to
# stdout/stderr and be collected by the platform. File logging is opt-in via
# LOG_TO_FILE=true and is intended for VM/bare-metal or local development.
LOG_TO_FILE = os.environ.get('LOG_TO_FILE', 'False').lower() in ('true', '1', 'yes')

_app_handlers = ['console']
_security_handlers = ['console']

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{asctime} [{levelname}] {name} {module}.{funcName}:{lineno} - {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': _app_handlers,
            'level': LOG_LEVEL,
            'propagate': False,
        },
        'django.security': {
            'handlers': _security_handlers,
            'level': 'WARNING',
            'propagate': False,
        },
        'saferide': {
            'handlers': _app_handlers,
            'level': LOG_LEVEL,
            'propagate': False,
        },
        'alerts': {
            'handlers': _app_handlers,
            'level': LOG_LEVEL,
            'propagate': False,
        },
        'trips': {
            'handlers': _app_handlers,
            'level': LOG_LEVEL,
            'propagate': False,
        },
    },
}

if LOG_TO_FILE:
    log_dir = BASE_DIR / 'logs'
    log_dir.mkdir(exist_ok=True)
    LOGGING['handlers']['file'] = {
        'class': 'logging.handlers.RotatingFileHandler',
        'filename': log_dir / 'saferide.log',
        'maxBytes': 10 * 1024 * 1024,  # 10 MB
        'backupCount': 5,
        'formatter': 'verbose',
    }
    LOGGING['handlers']['security'] = {
        'class': 'logging.handlers.RotatingFileHandler',
        'filename': log_dir / 'security.log',
        'maxBytes': 10 * 1024 * 1024,
        'backupCount': 10,
        'formatter': 'verbose',
    }
    for _logger in ('django', 'saferide', 'alerts', 'trips'):
        LOGGING['loggers'][_logger]['handlers'].append('file')
    LOGGING['loggers']['django.security']['handlers'].append('security')


# ---------------------------------------------------------------------------
# CACHES
# ---------------------------------------------------------------------------

CACHES = {
    'default': {
        'BACKEND': os.environ.get(
            'CACHE_BACKEND',
            'django.core.cache.backends.locmem.LocMemCache'
        ),
        'LOCATION': os.environ.get('CACHE_LOCATION', 'saferide-cache'),
        'TIMEOUT': int(os.environ.get('CACHE_TIMEOUT', '300')),
    }
}
