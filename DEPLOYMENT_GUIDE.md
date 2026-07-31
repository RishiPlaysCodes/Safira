# Safira - Google Cloud Deployment Guide (FREE Tier)

Complete step-by-step guide to deploy Safira backend on **Google Cloud for FREE** using Cloud Run + Cloud SQL.

---

## What You Get for FREE

Google Cloud offers:
- **$300 free credit** for 90 days (new accounts)
- **Always Free tier** (even after credits expire):
  - Cloud Run: 2 million requests/month, 360,000 GB-seconds of memory, 180,000 vCPU-seconds
  - Cloud SQL: Not always-free, but covered by $300 credit
  - Artifact Registry: 500 MB storage
  - Cloud Build: 120 build-minutes/day

For a personal project like Safira, the **free tier is MORE than enough** for months of use.

---

## Prerequisites

### 1. Check Your Google Developer Student Account

Tu Google Developer Student Club me enroll kiya tha, check kar:

1. Go to: https://developers.google.com/profile
2. Login with your Google account
3. Check if you have any active credits

**OR** if you don't have student credits:

1. Go to: https://cloud.google.com/free
2. Click "Get started for free"
3. Sign in with your Google account
4. You'll get **$300 free credit for 90 days**
5. Add a debit/credit card (required for verification, **won't be charged**)

> **Important:** Google will NOT charge you after free trial ends. They'll simply pause your services. You have to manually upgrade to get charged.

### 2. Install Google Cloud CLI (gcloud)

**Windows (VS Code Terminal / PowerShell):**
```powershell
# Download and run the installer
# Go to: https://cloud.google.com/sdk/docs/install
# Download the Windows installer (.exe)
# Run it, follow the prompts

# OR use winget:
winget install Google.CloudSDK
```

**Mac:**
```bash
brew install google-cloud-sdk
```

**Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### 3. Login to Google Cloud

```bash
# Login (opens browser)
gcloud auth login

# Check your account
gcloud auth list
```

---

## Step-by-Step Deployment

### Step 1: Create a Google Cloud Project

```bash
# Create a new project (use any unique name)
gcloud projects create safira-app --name="Safira"

# Set it as active project
gcloud config set project safira-app

# Enable billing (links your free trial)
# This will open browser - select your billing account (Free Trial)
gcloud billing accounts list
gcloud billing projects link safira-app --billing-account=YOUR_BILLING_ACCOUNT_ID
```

> **Note:** Replace `YOUR_BILLING_ACCOUNT_ID` with the ID shown by `gcloud billing accounts list`

### Step 2: Enable Required APIs

```bash
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com
```

### Step 3: Create Cloud SQL Database (PostgreSQL)

```bash
# Create a PostgreSQL instance (smallest possible = cheapest)
gcloud sql instances create safira-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=asia-south1 \
  --storage-size=10 \
  --storage-type=HDD

# This takes 3-5 minutes. Wait for it to finish.

# Create the database
gcloud sql databases create saferide --instance=safira-db

# Set a password for the default postgres user
gcloud sql users set-password postgres \
  --instance=safira-db \
  --password=YOUR_STRONG_DB_PASSWORD
```

> **Replace** `YOUR_STRONG_DB_PASSWORD` with a strong password. Note it down!
>
> **Region:** Use `asia-south1` (Mumbai) for India. Other options: `us-central1`, `europe-west1`

### Step 4: Store Secrets in Secret Manager

```bash
# Generate a Django secret key
python -c "import secrets; print(secrets.token_urlsafe(50))"
# Copy the output

# Store Django secret key
echo -n "YOUR_GENERATED_SECRET_KEY" | \
  gcloud secrets create django-secret-key --data-file=-

# Store database password
echo -n "YOUR_STRONG_DB_PASSWORD" | \
  gcloud secrets create db-password --data-file=-
```

### Step 5: Create Artifact Registry (Docker image storage)

```bash
gcloud artifacts repositories create safira-repo \
  --repository-format=docker \
  --location=asia-south1
```

### Step 6: Build and Push Docker Image

```bash
# Navigate to your project
cd Safira/backend

# Build and push using Cloud Build (FREE 120 min/day)
gcloud builds submit --tag asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest
```

> This builds your Dockerfile in the cloud and pushes it to Artifact Registry. Takes 3-5 minutes first time.

### Step 7: Deploy to Cloud Run

```bash
# Get your Cloud SQL connection name
gcloud sql instances describe safira-db --format="value(connectionName)"
# Output will be like: safira-app:asia-south1:safira-db

# Deploy!
gcloud run deploy safira-backend \
  --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest \
  --platform=managed \
  --region=asia-south1 \
  --allow-unauthenticated \
  --port=8000 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=2 \
  --set-env-vars="DJANGO_DEBUG=False" \
  --set-env-vars="DJANGO_ALLOWED_HOSTS=*" \
  --set-env-vars="DB_ENGINE=django.db.backends.postgresql" \
  --set-env-vars="DB_NAME=saferide" \
  --set-env-vars="DB_USER=postgres" \
  --set-env-vars="DB_HOST=/cloudsql/safira-app:asia-south1:safira-db" \
  --set-env-vars="DB_PORT=5432" \
  --set-env-vars="NOTIFICATION_PROVIDER=free" \
  --set-env-vars="VISION_PROVIDER=free_manual" \
  --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest" \
  --set-secrets="DB_PASSWORD=db-password:latest" \
  --add-cloudsql-instances=safira-app:asia-south1:safira-db
```

> After deployment, you'll get a URL like: `https://safira-backend-xxxxx-el.a.run.app`

### Step 8: Run Migrations

```bash
# Run migrations on Cloud Run (one-time job)
gcloud run jobs create migrate \
  --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest \
  --region=asia-south1 \
  --set-env-vars="DJANGO_DEBUG=False,DB_ENGINE=django.db.backends.postgresql,DB_NAME=saferide,DB_USER=postgres,DB_HOST=/cloudsql/safira-app:asia-south1:safira-db,DB_PORT=5432,NOTIFICATION_PROVIDER=free" \
  --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest,DB_PASSWORD=db-password:latest" \
  --add-cloudsql-instances=safira-app:asia-south1:safira-db \
  --command="python" \
  --args="manage.py,migrate,--noinput"

# Execute the migration job
gcloud run jobs execute migrate --region=asia-south1 --wait
```

### Step 9: Create Admin User

```bash
# Create a superuser job
gcloud run jobs create create-admin \
  --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest \
  --region=asia-south1 \
  --set-env-vars="DJANGO_DEBUG=False,DB_ENGINE=django.db.backends.postgresql,DB_NAME=saferide,DB_USER=postgres,DB_HOST=/cloudsql/safira-app:asia-south1:safira-db,DB_PORT=5432,DJANGO_SUPERUSER_USERNAME=admin,DJANGO_SUPERUSER_EMAIL=rishigurdatta.002@gmail.com,DJANGO_SUPERUSER_PASSWORD=YourAdminPass123!,NOTIFICATION_PROVIDER=free" \
  --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest,DB_PASSWORD=db-password:latest" \
  --add-cloudsql-instances=safira-app:asia-south1:safira-db \
  --command="python" \
  --args="manage.py,createsuperuser,--noinput"

gcloud run jobs execute create-admin --region=asia-south1 --wait
```

### Step 10: Test Your Deployment!

```bash
# Get your service URL
gcloud run services describe safira-backend --region=asia-south1 --format="value(status.url)"

# Test health endpoint
curl https://safira-backend-xxxxx-el.a.run.app/api/health/
# Should return: {"status": "ok"}

# Test signup
curl -X POST https://safira-backend-xxxxx-el.a.run.app/api/auth/signup/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "rishi",
    "email": "rishigurdatta.002@gmail.com",
    "password": "MySecurePass123!",
    "phone_number": "+911234567890",
    "vehicle_type": "bike",
    "role": "driver"
  }'
```

---

## Connect Mobile App to Cloud Run

In your Flutter app settings, set the backend URL to your Cloud Run URL:

```
https://safira-backend-xxxxx-el.a.run.app
```

The `AuthService` will automatically:
1. Login and get a token
2. Send the token with every API request
3. HTTPS is already enforced

---

## Update/Redeploy After Code Changes

Whenever you make changes to the backend code:

```bash
cd Safira/backend

# Build new image
gcloud builds submit --tag asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest

# Deploy updated image
gcloud run deploy safira-backend \
  --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest \
  --region=asia-south1

# Run migrations if models changed
gcloud run jobs execute migrate --region=asia-south1 --wait
```

---

## Cost Breakdown (What's FREE)

| Service | Free Tier Limit | Safira Usage (estimated) |
|---------|----------------|--------------------------|
| Cloud Run | 2M requests/month | ~5,000 requests/month |
| Cloud Run CPU | 180,000 vCPU-seconds | ~2,000 vCPU-seconds |
| Cloud Run Memory | 360,000 GB-seconds | ~5,000 GB-seconds |
| Cloud SQL | $300 credit covers ~4 months for db-f1-micro | ~$8/month |
| Artifact Registry | 500 MB free | ~200 MB |
| Cloud Build | 120 minutes/day | ~5 minutes per deploy |
| Networking | 1 GB egress free (North America) | Minimal |

**Total cost: $0 for first 90 days ($300 credit). After that: ~$8-10/month for Cloud SQL only.**

### Want to Keep it 100% FREE Forever?

Replace Cloud SQL with **Supabase** (free PostgreSQL):
1. Go to https://supabase.com (free tier: 500 MB database, unlimited API requests)
2. Create a project, get the connection string
3. Update Cloud Run env vars with Supabase DB credentials

---

## Custom Domain (Optional, FREE)

```bash
# Map your domain (if you have one)
gcloud run domain-mappings create \
  --service=safira-backend \
  --domain=api.yourdomain.com \
  --region=asia-south1

# Google provides free SSL certificate automatically!
```

---

## Monitoring (FREE)

Google Cloud automatically provides:
- **Cloud Logging** — All your app logs visible in console
- **Cloud Monitoring** — CPU, memory, request count dashboards
- **Error Reporting** — Automatic error grouping

View at: https://console.cloud.google.com/run

---

## Troubleshooting

### "Permission denied" errors
```bash
# Grant Cloud Run access to Secret Manager
gcloud projects add-iam-policy-binding safira-app \
  --member="serviceAccount:$(gcloud projects describe safira-app --format='value(projectNumber)')-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Grant Cloud Run access to Cloud SQL
gcloud projects add-iam-policy-binding safira-app \
  --member="serviceAccount:$(gcloud projects describe safira-app --format='value(projectNumber)')-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

### "Database connection refused"
```bash
# Make sure Cloud SQL instance is running
gcloud sql instances describe safira-db --format="value(state)"

# Make sure --add-cloudsql-instances flag was used in deploy
```

### "Container failed to start"
```bash
# Check logs
gcloud run services logs read safira-backend --region=asia-south1 --limit=50
```

### Want to stop everything (save credits)
```bash
# Delete Cloud Run service (stops billing immediately)
gcloud run services delete safira-backend --region=asia-south1

# Stop Cloud SQL (stops billing, keeps data)
gcloud sql instances patch safira-db --activation-policy=NEVER
```

---

## Google Developer Student Club Credits

Agar tune **Google Developer Student Club** me enroll kiya tha:

1. Go to: https://developers.google.com/profile
2. Check "My benefits" section
3. If you see Cloud credits, redeem them
4. They typically give **$50-$100** extra credits

**Also check:**
- Google Cloud Skills Boost: https://www.cloudskillsboost.google/
- Google for Students: https://cloud.google.com/edu/students

Even without student credits, the **$300 free trial** is enough to run Safira for 3+ months.

---

## Summary - Quick Commands Cheat Sheet

```bash
# === ONE-TIME SETUP ===
gcloud auth login
gcloud projects create safira-app --name="Safira"
gcloud config set project safira-app
gcloud services enable run.googleapis.com sqladmin.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com

# === DATABASE ===
gcloud sql instances create safira-db --database-version=POSTGRES_15 --tier=db-f1-micro --region=asia-south1 --storage-size=10 --storage-type=HDD
gcloud sql databases create saferide --instance=safira-db
gcloud sql users set-password postgres --instance=safira-db --password=YOUR_DB_PASSWORD

# === SECRETS ===
echo -n "your-secret-key" | gcloud secrets create django-secret-key --data-file=-
echo -n "YOUR_DB_PASSWORD" | gcloud secrets create db-password --data-file=-

# === BUILD & DEPLOY ===
gcloud artifacts repositories create safira-repo --repository-format=docker --location=asia-south1
cd Safira/backend
gcloud builds submit --tag asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest
gcloud run deploy safira-backend --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest --platform=managed --region=asia-south1 --allow-unauthenticated --port=8000 --memory=512Mi --cpu=1 --min-instances=0 --max-instances=2 --set-env-vars="DJANGO_DEBUG=False,DJANGO_ALLOWED_HOSTS=*,DB_ENGINE=django.db.backends.postgresql,DB_NAME=saferide,DB_USER=postgres,DB_HOST=/cloudsql/safira-app:asia-south1:safira-db,DB_PORT=5432,NOTIFICATION_PROVIDER=free,VISION_PROVIDER=free_manual" --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest,DB_PASSWORD=db-password:latest" --add-cloudsql-instances=safira-app:asia-south1:safira-db

# === POST-DEPLOY ===
gcloud run jobs execute migrate --region=asia-south1 --wait
```
