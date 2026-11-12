#!/usr/bin/env bash
set -o errexit

# Render build command: bash build.sh (with Root Directory set to backend).
# Configure DATABASE_URL, DJANGO_SECRET_KEY and other environment variables
# before deploying; migrations and seeding need an accessible Neon database.

python -m pip install -r requirements.txt
python manage.py collectstatic --noinput
python manage.py migrate --noinput
python manage.py seed_store
