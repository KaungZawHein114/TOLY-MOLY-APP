# TOLY MOLY Backend

Django REST Framework + PostgreSQL + JWT backend for user onboarding
(registration, OTP, login). See
`docs/superpowers/specs/2026-06-29-onboarding-backend-auth-design.md` (repo
root) for the full design.

The Flutter app is fully offline otherwise — this backend is only needed for
the signup/login flow.

## First-time setup (new machine / fresh clone)

### 1. Install PostgreSQL

If you don't already have it, install PostgreSQL (16+ recommended) and note
the password you set for the `postgres` user during install.

### 2. Create the database

Using pgAdmin4, psql, or any Postgres client, create a database named
`tolymoly`:

```sql
CREATE DATABASE tolymoly;
```

### 3. Create a Python virtual environment and install dependencies

From the `backend/` folder:

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS/Linux
pip install -r requirements.txt
```

> Requires Python 3.12+ (this project currently runs on 3.14; if
> `psycopg2-binary`/`Pillow` fail to build from source on your machine, try
> `pip install --upgrade psycopg2-binary Pillow` to pull a newer version with
> a prebuilt wheel for your Python version, then update `requirements.txt`
> to match).

### 4. Configure your local environment

```bash
copy .env.example .env         # Windows
# cp .env.example .env         # macOS/Linux
```

Edit `backend/.env` (this file is gitignored — never commit it) and:
- Replace `YOUR_PASSWORD` in `DATABASE_URL` with your actual local
  PostgreSQL password.
- Replace `SECRET_KEY` with any random 50+ character string.

### 5. Run migrations

```bash
python manage.py migrate
```

This creates all the tables (`tolymoly` must already exist as an empty
database — migrate creates the schema inside it, not the database itself).

### 6. (Optional) Create a Django admin account

To view/edit/delete users at `/admin`:

```bash
python manage.py shell -c "from apps.users.models import User; User.objects.create_superuser(phone_number='09000000001', password='YourChoicePassword')"
```

(`createsuperuser` also works, but it's an interactive prompt.)

### 7. Run the server

```bash
python manage.py runserver 0.0.0.0:8000
```

Binding to `0.0.0.0` (not just `127.0.0.1`) is important — it's what lets an
Android emulator reach the server (see the Flutter section below). Leave
this running in its own terminal; it does not start automatically with the
Flutter app.

### 8. Verify

```bash
curl http://127.0.0.1:8000/admin/login/
```

Should return a `200` with an HTML login page. Or just open
`http://127.0.0.1:8000/admin` in a browser.

## Running the test suite

```bash
python manage.py test
```

Should report all tests passing (57 at time of writing) with no errors.

## Running the Flutter app

From the repo root (not `backend/`):

```bash
flutter pub get
flutter devices       # see what's connected/available
flutter run -d <device-id>
```

The backend (above) must already be running in its own terminal — the app
doesn't start it for you.

### Connecting to your backend (`apiBaseUrl`)

The app **auto-detects the correct URL** based on what it's running on — you
do not need to change anything for the emulator, iOS simulator, web, or
desktop:

| Running on... | URL used (automatic) |
|---|---|
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://127.0.0.1:8000` |
| Web browser | `http://127.0.0.1:8000` |
| Windows / macOS desktop | `http://127.0.0.1:8000` |
| **Physical Android phone** | `physicalDeviceUrl` from `local_config.dart` ← only this needs editing |

**First-time setup (only needed for physical device testing):**

1. Copy the template (once, after cloning):

   ```bash
   # Windows
   copy lib\core\config\local_config.dart.example lib\core\config\local_config.dart
   # macOS/Linux
   cp lib/core/config/local_config.dart.example lib/core/config/local_config.dart
   ```

2. Open `lib/core/config/local_config.dart` and change `physicalDeviceUrl`
   to your PC's current LAN IP:

   ```dart
   const String physicalDeviceUrl = "http://192.168.x.x:8000";
   ```

   Find your IP with `ipconfig` (Windows) or `ifconfig` (macOS/Linux) — look
   for the IPv4 address under your Wi-Fi adapter.

3. **Hot-restart** the app after editing (not hot-reload — it's read at
   startup).

> **Never commit `local_config.dart`** — it's in `.gitignore`. The
> `.example` file is the committed template.

### Physical phone over Wi-Fi: two extra one-time steps

If "physical phone" above is your case (most common — e.g. testing on an
Android phone via USB/Wi-Fi debugging), you also need:

1. **Phone and PC on the same Wi-Fi network.**
2. **A Windows Firewall rule allowing inbound traffic on port 8000** — by
   default Windows blocks it, so the phone's requests never arrive even
   though `runserver 0.0.0.0:8000` is listening correctly. One-time fix, run
   in an **elevated** (Run as Administrator) PowerShell/Command Prompt:

   ```bash
   netsh advfirewall firewall add rule name="Django Dev Server 8000" dir=in action=allow protocol=TCP localport=8000
   ```

If you still see "can't reach server" after both of those, re-check
`apiBaseUrl` against the PC's *current* IP — it changes whenever the PC
reconnects to Wi-Fi or reboots, so this is the most common thing to go
stale.

### AI Task Posting (OpenAI key)

The AI Task Posting feature (Whisper-backed endpoints under
`/api/tasks/ai/*` — though voice input in the app itself now uses on-device
`speech_to_text`, not Whisper, so this is only needed if you're exercising
those endpoints directly) needs an `OPENAI_API_KEY` in `backend/.env`:

```
OPENAI_API_KEY=sk-proj-...
```

Leave it blank to disable those specific endpoints — everything else in the
backend works fine without it; they just return a clean 503 instead of
crashing.

### Burmese voice input

Voice input in AI Task Posting uses the phone's on-device speech recognizer
forced to Burmese. If a teammate's phone has no Burmese language pack
installed (Settings → System → Languages), the app shows an in-app message
telling them to add one — this is a device setting, not something fixable
in code.

## Day-to-day (after first-time setup)

Every time you want to run the backend:

```bash
cd backend
venv\Scripts\activate
python manage.py runserver 0.0.0.0:8000
```

If you pulled new commits that touch `requirements.txt` or add migrations:

```bash
pip install -r requirements.txt
python manage.py migrate
```

## Resetting your local data

To wipe all users/profiles/OTPs and start clean:

```bash
python manage.py shell -c "from apps.users.models import User; from apps.authentication.models import PhoneOTP; User.objects.all().delete(); PhoneOTP.objects.all().delete()"
```

###lin khant kyaw
