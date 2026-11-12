# AstraQuest Django backend — Render Free + Neon PostgreSQL

This guide applies to the `backend/` directory. The React/Vite frontend is
deployed separately. The build script runs database migrations and the
idempotent store seed command, so **configure the Neon database before deploying**.

## 1. Create a Neon database

1. Sign in to https://console.neon.tech and create a project (e.g. `astraquest-db`).
2. Choose a region geographically close to your Render service (e.g. US West).
3. Use **Connect** to copy a **direct** (non-pooled) PostgreSQL URL for initial deployment.
4. The URL must include TLS, usually via `?sslmode=require`.
5. Keep credentials private. Never put the URL or its password in Git.

## 2. Create a Render Web Service

- Repository: `promedchandradas4/astraquest-v2.0`
- Branch: `main` **after merging the deployment PR**
- Name: `astraquest-api` (or another available name)
- Runtime: **Python 3**
- Region: same geography as Neon if possible
- Root Directory: `backend`
- Instance type: **Free**
- Build Command: `bash build.sh`
- Start Command:
  `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers 1 --threads 2 --timeout 120 --access-logfile -`

## 3. Render environment variables

Enter these using **Environment → Add Environment Variable**:

| Key | Example value / instruction |
| --- | --- |
| `DJANGO_SECRET_KEY` | Generate a **new random secret** in Render |
| `DJANGO_DEBUG` | `False` |
| `DATABASE_URL` | Paste your Neon **direct** URL; keep secret |
| `DJANGO_ALLOWED_HOSTS` | Your assigned hostname only, e.g. `astraquest-api.onrender.com` |
| `CORS_ALLOWED_ORIGINS` | Exact frontend origins, e.g. `http://localhost:5173` for local testing |
| `CSRF_TRUSTED_ORIGINS` | HTTPS backend origin, e.g. `https://astraquest-api.onrender.com` |
| `PYTHON_VERSION` | `3.12.11` |

Render also sets `RENDER_EXTERNAL_HOSTNAME` automatically; the Django settings
include that hostname in `ALLOWED_HOSTS` and its HTTPS origin in
`CSRF_TRUSTED_ORIGINS`. Explicit values are useful for custom domains.

**Never** set `DJANGO_DEBUG=True` on a public service. Do not paste any
credentials in public issues, screenshots or chat messages.

## 4. Deployment and checks

Before deploying, check the code has merged to `main`.
The build script installs dependencies, collects static files, migrates Neon
and runs `seed_store`. Then Gunicorn serves the Django WSGI app.

Once Render shows **Live**, test these URLs (substitute your real hostname):

- `https://YOUR-HOST.onrender.com/api/store/items/` — should return HTTP 200
  and a JSON catalog after the six initial store records have been seeded.
- `https://YOUR-HOST.onrender.com/api/auth/me/` — should reject an anonymous
  request (usually HTTP 401). This is expected.
- `https://YOUR-HOST.onrender.com/admin/` — should show Django admin login,
  with WhiteNoise providing CSS/JS.

The root URL `/` is not defined and can return HTTP 404; this is not proof
of a failed deployment.

To verify Neon tables, use its SQL editor:

```sql
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

## 5. Frontend integration

The Vite dev-server proxy in `frontend/vite.config.js` works only during
local development. A production frontend needs an API base URL or a supported
host-level proxy/rewrite configuration, and its **exact HTTPS origin** must be
added to `CORS_ALLOWED_ORIGINS` on Render.

## 6. Troubleshooting

- **Build script not found:** Root Directory must be `backend`, and
  `backend/build.sh` must be merged to the deployed branch.
- **Node runtime shown:** choose **Python 3**, not Node.
- **Missing secret:** configure `DJANGO_SECRET_KEY` before the build.
- **Database connection refused:** confirm Neon connection URL, credentials,
  SSL setting, and project status. Avoid copying a placeholder.
- **Static admin files missing:** check `collectstatic` and WhiteNoise logs.
- **DisallowedHost:** update `DJANGO_ALLOWED_HOSTS` with the assigned Render
  hostname, without `https://`.
- **CORS errors:** configure exact frontend origin, including scheme.
- **First request delayed:** Render Free services can sleep after inactivity.

Render Free does not provide a shell, so creating a Django superuser is a
separate administrative step. One option is to run
`python manage.py createsuperuser` locally with a secure connection to the
same Neon database; never commit the local `.env`.

Official references:
- https://render.com/docs/deploy-django
- https://render.com/docs/free
- https://neon.com/docs/get-started/connect-neon
- https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/
