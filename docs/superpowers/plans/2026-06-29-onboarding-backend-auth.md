# Onboarding Backend Phase 1 (Auth API) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a Django REST Framework + PostgreSQL + JWT backend at `backend/` that implements registration, OTP verification, login, token refresh, logout, and `/me`, exactly per `docs/superpowers/specs/2026-06-29-onboarding-backend-auth-design.md`.

**Architecture:** Django project (`config/`) with five apps under `apps/` (`users`, `authentication`, `profiles`, `verification`, `taskers` — the last two scaffolded empty). Custom `User` model (`phone_number` as login identifier, no email/username). `djangorestframework-simplejwt` issues/blacklists tokens. Each endpoint is a DRF `APIView` with its own serializer; OTP generation is a shared service function used by both `register` and `send-otp`.

**Tech Stack:** Python 3.11+, Django 5.x, djangorestframework, djangorestframework-simplejwt, psycopg2-binary, django-environ, django-cors-headers, PostgreSQL (existing local `tolymoly` database).

## Global Constraints

- No email/username field anywhere — `phone_number` is the sole identifier (spec §2, §3).
- `role` is set once at registration and never editable afterward (spec source doc §5).
- `is_active=False` until OTP verified; `status` (UNVERIFIED/PENDING_VERIFICATION/VERIFIED/SUSPENDED) is a separate concern from `is_active` (spec §3).
- `send-otp` returns `dev_otp_code` directly in the response body — dev-mode only, no real SMS gateway this phase (spec §2, §4).
- Profile rows (`ClientProfile`/`TaskerProfile`) are created explicitly inside the `register` view's transaction, never via a `post_save` signal (spec §2).
- Error shape: DRF default per-field errors for validation; `{"detail": "...", "code": "..."}` for business-logic errors, using exactly these `code` values where applicable: `phone_already_registered`, `otp_expired`, `otp_locked`, `account_not_verified`, `otp_cooldown` (spec §5).
- `phone_number` regex: `^09\d{7,9}$`. `age`: integer 16–100. `password`: Django's `validate_password`.
- `verification` and `taskers` apps exist in `INSTALLED_APPS` this phase but contain no models/views beyond the default `apps.py` (spec §1, §6).
- Every endpoint gets a DRF `APITestCase` covering its happy path and every documented error case (spec §5).
- No Flutter files are touched in this plan.

---

## Task 1: Django project scaffold

**Files:**
- Create: `backend/manage.py`
- Create: `backend/requirements.txt`
- Create: `backend/.env.example`
- Create: `backend/.gitignore`
- Create: `backend/config/__init__.py`
- Create: `backend/config/settings.py`
- Create: `backend/config/urls.py`
- Create: `backend/config/wsgi.py`
- Create: `backend/apps/__init__.py`
- Create: `backend/apps/users/__init__.py`
- Create: `backend/apps/users/apps.py`
- Create: `backend/apps/authentication/__init__.py`
- Create: `backend/apps/authentication/apps.py`
- Create: `backend/apps/profiles/__init__.py`
- Create: `backend/apps/profiles/apps.py`
- Create: `backend/apps/verification/__init__.py`
- Create: `backend/apps/verification/apps.py`
- Create: `backend/apps/taskers/__init__.py`
- Create: `backend/apps/taskers/apps.py`

**Interfaces:**
- Produces: a working Django project answering `python manage.py check` with zero errors; `config.settings` module other tasks import `AUTH_USER_MODEL`, `INSTALLED_APPS`, env-driven `DATABASES`/`SECRET_KEY` from.

- [ ] **Step 1: Create the directory skeleton and empty `__init__.py` files**

```bash
mkdir -p backend/config backend/apps/users backend/apps/authentication backend/apps/profiles backend/apps/verification backend/apps/taskers
touch backend/config/__init__.py backend/apps/__init__.py
touch backend/apps/users/__init__.py backend/apps/authentication/__init__.py backend/apps/profiles/__init__.py backend/apps/verification/__init__.py backend/apps/taskers/__init__.py
```

- [ ] **Step 2: Write `backend/requirements.txt`**

```text
Django==5.1.4
djangorestframework==3.15.2
djangorestframework-simplejwt==5.3.1
psycopg2-binary==2.9.10
django-environ==0.11.2
django-cors-headers==4.6.0
```

- [ ] **Step 3: Write `backend/.env.example`**

```text
SECRET_KEY=change-me-to-a-random-50-char-string
DEBUG=True
DATABASE_URL=postgres://postgres:YOUR_PASSWORD@localhost:5432/tolymoly
JWT_ACCESS_TOKEN_LIFETIME_MINUTES=30
JWT_REFRESH_TOKEN_LIFETIME_DAYS=14
```

- [ ] **Step 4: Write `backend/.gitignore`**

```text
.env
__pycache__/
*.pyc
db.sqlite3
venv/
.venv/
```

- [ ] **Step 5: Write each app's `apps.py`**

`backend/apps/users/apps.py`:
```python
from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.users"
    label = "users"
```

`backend/apps/authentication/apps.py`:
```python
from django.apps import AppConfig


class AuthenticationConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.authentication"
    label = "authentication"
```

`backend/apps/profiles/apps.py`:
```python
from django.apps import AppConfig


class ProfilesConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.profiles"
    label = "profiles"
```

`backend/apps/verification/apps.py`:
```python
from django.apps import AppConfig


class VerificationConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.verification"
    label = "verification"
```

`backend/apps/taskers/apps.py`:
```python
from django.apps import AppConfig


class TaskersConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.taskers"
    label = "taskers"
```

- [ ] **Step 6: Write `backend/config/settings.py`**

```python
from pathlib import Path
import environ

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env()
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("SECRET_KEY")
DEBUG = env.bool("DEBUG", default=False)
ALLOWED_HOSTS = ["*"] if DEBUG else []

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt.token_blacklist",
    "corsheaders",
    "apps.users",
    "apps.authentication",
    "apps.profiles",
    "apps.verification",
    "apps.taskers",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {"default": env.db("DATABASE_URL")}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

AUTH_USER_MODEL = "users.User"

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Yangon"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

CORS_ALLOW_ALL_ORIGINS = DEBUG

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
}

from datetime import timedelta  # noqa: E402

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=env.int("JWT_ACCESS_TOKEN_LIFETIME_MINUTES", default=30)),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=env.int("JWT_REFRESH_TOKEN_LIFETIME_DAYS", default=14)),
    "ROTATE_REFRESH_TOKENS": False,
    "BLACKLIST_AFTER_ROTATION": False,
}
```

- [ ] **Step 7: Write `backend/config/urls.py`**

```python
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("apps.authentication.urls")),
]
```

(`apps.authentication.urls` doesn't exist yet — created in Task 5. Leave
this import as-is; Django won't load `urls.py` until a request comes in,
and `manage.py check` in Step 9 only checks app configs, not URL resolution,
so this is safe to write now.)

- [ ] **Step 8: Write `backend/config/wsgi.py`**

```python
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
application = get_wsgi_application()
```

- [ ] **Step 9: Write `backend/manage.py`**

```python
#!/usr/bin/env python
import os
import sys


def main():
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
```

- [ ] **Step 10: Create venv, install deps, copy `.env`**

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Edit `backend/.env` and replace `YOUR_PASSWORD` with the real local
PostgreSQL password for the `postgres` user (or whichever user owns the
`tolymoly` database), and replace `SECRET_KEY` with a random string (any
50+ character string works for local dev).

- [ ] **Step 11: Verify the project boots**

Run (from `backend/`, venv active): `python manage.py check`
Expected: `System check identified no issues (0 silenced).`

If this fails with a database connection error instead, that's expected —
Step 11 only fails on *config* errors (missing settings, bad app configs,
URL import errors). A DB connection error here means `.env`'s
`DATABASE_URL` is wrong; fix it before continuing, since Task 2 needs a
working DB connection to run migrations.

- [ ] **Step 12: Commit**

```bash
git add backend/
git commit -m "feat(backend): scaffold Django project for onboarding auth API"
```

---

## Task 2: User model

**Files:**
- Create: `backend/apps/users/models.py`
- Create: `backend/apps/users/managers.py`
- Create: `backend/apps/users/migrations/__init__.py`
- Create: `backend/apps/users/tests.py`

**Interfaces:**
- Consumes: `AUTH_USER_MODEL = "users.User"` from Task 1's settings.
- Produces: `apps.users.models.User` with fields `phone_number`, `role`
  (`"CLIENT"`/`"TASKER"`), `status` (`"UNVERIFIED"`/`"PENDING_VERIFICATION"`/`"VERIFIED"`/`"SUSPENDED"`),
  `is_phone_verified` (bool), `is_active` (bool, default `False`),
  `is_staff` (bool, default `False`), `created_at`, `updated_at`.
  `UserManager.create_user(phone_number, password, role, **extra_fields)`
  and `create_superuser(phone_number, password, **extra_fields)` —
  later tasks call these, never `User.objects.create()` directly.

- [ ] **Step 1: Write the failing test**

`backend/apps/users/tests.py`:
```python
from django.test import TestCase

from apps.users.models import User


class UserModelTests(TestCase):
    def test_create_user_sets_expected_defaults(self):
        user = User.objects.create_user(
            phone_number="09123456789", password="StrongPass123", role="CLIENT"
        )
        self.assertEqual(user.phone_number, "09123456789")
        self.assertEqual(user.role, "CLIENT")
        self.assertEqual(user.status, "UNVERIFIED")
        self.assertFalse(user.is_phone_verified)
        self.assertFalse(user.is_active)
        self.assertTrue(user.check_password("StrongPass123"))

    def test_create_user_requires_phone_number(self):
        with self.assertRaises(ValueError):
            User.objects.create_user(phone_number="", password="x", role="CLIENT")

    def test_phone_number_is_unique(self):
        User.objects.create_user(phone_number="09123456789", password="x", role="CLIENT")
        with self.assertRaises(Exception):
            User.objects.create_user(phone_number="09123456789", password="y", role="TASKER")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python manage.py test apps.users -v 2`
Expected: FAIL — `ModuleNotFoundError: No module named 'apps.users.models'` (or `ImportError`)

- [ ] **Step 3: Write `backend/apps/users/managers.py`**

```python
from django.contrib.auth.base_user import BaseUserManager


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, phone_number, password=None, role=None, **extra_fields):
        if not phone_number:
            raise ValueError("phone_number is required")
        if not role:
            raise ValueError("role is required")
        user = self.model(phone_number=phone_number, role=role, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault("role", "CLIENT")
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_active", True)
        extra_fields.setdefault("status", "VERIFIED")
        return self.create_user(phone_number, password, **extra_fields)
```

- [ ] **Step 4: Write `backend/apps/users/models.py`**

```python
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models

from apps.users.managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = [("CLIENT", "Client"), ("TASKER", "Tasker")]
    STATUS_CHOICES = [
        ("UNVERIFIED", "Unverified"),
        ("PENDING_VERIFICATION", "Pending Verification"),
        ("VERIFIED", "Verified"),
        ("SUSPENDED", "Suspended"),
    ]

    phone_number = models.CharField(max_length=20, unique=True, db_index=True)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    status = models.CharField(max_length=24, choices=STATUS_CHOICES, default="UNVERIFIED")
    is_phone_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.phone_number
```

- [ ] **Step 5: Generate and run migrations**

```bash
python manage.py makemigrations users
python manage.py migrate
```
Expected: a `0001_initial.py` migration file is created under
`backend/apps/users/migrations/`, and `migrate` reports
`Applying users.0001_initial... OK` plus all the built-in Django migrations.

- [ ] **Step 6: Run test to verify it passes**

Run: `python manage.py test apps.users -v 2`
Expected: `Ran 3 tests in ...s` / `OK`

- [ ] **Step 7: Commit**

```bash
git add backend/apps/users/
git commit -m "feat(backend): add custom User model with phone_number identity"
```

---

## Task 3: Profile models

**Files:**
- Create: `backend/apps/profiles/models.py`
- Create: `backend/apps/profiles/migrations/__init__.py`
- Create: `backend/apps/profiles/tests.py`

**Interfaces:**
- Consumes: `apps.users.models.User` (Task 2).
- Produces: `apps.profiles.models.ClientProfile` and
  `apps.profiles.models.TaskerProfile`, both with fields `user` (OneToOne to
  `User`), `name` (str), `gender` (str), `age` (int), accessible via
  `user.client_profile` / `user.tasker_profile`.

- [ ] **Step 1: Write the failing test**

`backend/apps/profiles/tests.py`:
```python
from django.test import TestCase

from apps.profiles.models import ClientProfile, TaskerProfile
from apps.users.models import User


class ProfileModelTests(TestCase):
    def test_client_profile_links_to_user(self):
        user = User.objects.create_user(phone_number="09111111111", password="x", role="CLIENT")
        profile = ClientProfile.objects.create(user=user, name="Mya", gender="Female", age=28)
        self.assertEqual(user.client_profile, profile)

    def test_tasker_profile_links_to_user(self):
        user = User.objects.create_user(phone_number="09222222222", password="x", role="TASKER")
        profile = TaskerProfile.objects.create(user=user, name="Aung", gender="Male", age=34)
        self.assertEqual(user.tasker_profile, profile)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python manage.py test apps.profiles -v 2`
Expected: FAIL — `ModuleNotFoundError: No module named 'apps.profiles.models'`

- [ ] **Step 3: Write `backend/apps/profiles/models.py`**

```python
from django.db import models

from apps.users.models import User


class ClientProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="client_profile")
    name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10)
    age = models.PositiveSmallIntegerField()

    def __str__(self):
        return self.name


class TaskerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="tasker_profile")
    name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10)
    age = models.PositiveSmallIntegerField()

    def __str__(self):
        return self.name
```

- [ ] **Step 4: Generate and run migrations**

```bash
python manage.py makemigrations profiles
python manage.py migrate
```
Expected: `Applying profiles.0001_initial... OK`

- [ ] **Step 5: Run test to verify it passes**

Run: `python manage.py test apps.profiles -v 2`
Expected: `Ran 2 tests in ...s` / `OK`

- [ ] **Step 6: Commit**

```bash
git add backend/apps/profiles/
git commit -m "feat(backend): add ClientProfile and TaskerProfile models"
```

---

## Task 4: PhoneOTP model + OTP service

**Files:**
- Create: `backend/apps/authentication/models.py`
- Create: `backend/apps/authentication/services.py`
- Create: `backend/apps/authentication/migrations/__init__.py`
- Create: `backend/apps/authentication/tests/__init__.py`
- Create: `backend/apps/authentication/tests/test_models.py`
- Create: `backend/apps/authentication/tests/test_services.py`

**Interfaces:**
- Consumes: `apps.users.models.User` (Task 2).
- Produces: `apps.authentication.models.PhoneOTP` (fields: `user`, `code`,
  `created_at`, `expires_at`, `is_used`, `attempts`).
  `apps.authentication.services.generate_otp_for_user(user) -> PhoneOTP` —
  invalidates (deletes) any prior unused OTP for that user, creates a new
  6-digit code with a 5-minute expiry. Later tasks (register, send-otp)
  call this function; they don't construct `PhoneOTP` directly.

- [ ] **Step 1: Write the failing tests**

`backend/apps/authentication/tests/__init__.py`: (empty file)

`backend/apps/authentication/tests/test_models.py`:
```python
from django.test import TestCase
from django.utils import timezone

from apps.authentication.models import PhoneOTP
from apps.users.models import User


class PhoneOTPModelTests(TestCase):
    def test_otp_links_to_user(self):
        user = User.objects.create_user(phone_number="09333333333", password="x", role="CLIENT")
        otp = PhoneOTP.objects.create(
            user=user, code="123456", expires_at=timezone.now() + timezone.timedelta(minutes=5)
        )
        self.assertEqual(otp.user, user)
        self.assertFalse(otp.is_used)
        self.assertEqual(otp.attempts, 0)
```

`backend/apps/authentication/tests/test_services.py`:
```python
from django.test import TestCase
from django.utils import timezone

from apps.authentication.models import PhoneOTP
from apps.authentication.services import generate_otp_for_user
from apps.users.models import User


class GenerateOtpForUserTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(phone_number="09444444444", password="x", role="CLIENT")

    def test_creates_six_digit_code(self):
        otp = generate_otp_for_user(self.user)
        self.assertEqual(len(otp.code), 6)
        self.assertTrue(otp.code.isdigit())

    def test_sets_five_minute_expiry(self):
        before = timezone.now()
        otp = generate_otp_for_user(self.user)
        self.assertGreater(otp.expires_at, before + timezone.timedelta(minutes=4))
        self.assertLess(otp.expires_at, before + timezone.timedelta(minutes=6))

    def test_invalidates_prior_unused_otp(self):
        first = generate_otp_for_user(self.user)
        generate_otp_for_user(self.user)
        self.assertFalse(PhoneOTP.objects.filter(pk=first.pk).exists())
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python manage.py test apps.authentication -v 2`
Expected: FAIL — `ModuleNotFoundError: No module named 'apps.authentication.models'`

- [ ] **Step 3: Write `backend/apps/authentication/models.py`**

```python
from django.db import models

from apps.users.models import User


class PhoneOTP(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="otps")
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    attempts = models.PositiveSmallIntegerField(default=0)

    def __str__(self):
        return f"OTP for {self.user.phone_number}"
```

- [ ] **Step 4: Write `backend/apps/authentication/services.py`**

```python
import random

from django.utils import timezone

from apps.authentication.models import PhoneOTP

OTP_LIFETIME_MINUTES = 5
MAX_OTP_ATTEMPTS = 5


def generate_otp_for_user(user):
    PhoneOTP.objects.filter(user=user, is_used=False).delete()
    code = f"{random.randint(0, 999999):06d}"
    return PhoneOTP.objects.create(
        user=user,
        code=code,
        expires_at=timezone.now() + timezone.timedelta(minutes=OTP_LIFETIME_MINUTES),
    )
```

- [ ] **Step 5: Generate and run migrations**

```bash
python manage.py makemigrations authentication
python manage.py migrate
```
Expected: `Applying authentication.0001_initial... OK`

- [ ] **Step 6: Run tests to verify they pass**

Run: `python manage.py test apps.authentication -v 2`
Expected: `Ran 4 tests in ...s` / `OK`

- [ ] **Step 7: Commit**

```bash
git add backend/apps/authentication/
git commit -m "feat(backend): add PhoneOTP model and OTP generation service"
```

---

## Task 5: Register endpoint

**Files:**
- Create: `backend/apps/authentication/serializers.py`
- Create: `backend/apps/authentication/views.py`
- Create: `backend/apps/authentication/urls.py`
- Create: `backend/apps/authentication/tests/test_register.py`
- Modify: `backend/config/urls.py` (already references `apps.authentication.urls` from Task 1 — no change needed, just confirming it now resolves)

**Interfaces:**
- Consumes: `User.objects.create_user` (Task 2), `ClientProfile`/`TaskerProfile`
  (Task 3), `generate_otp_for_user` (Task 4).
- Produces: `POST /api/auth/register` — request
  `{name, phone_number, password, gender, age, role}`, response `201`
  `{user_id, phone_number, role}` or `400` with field errors or
  `{"detail": "...", "code": "phone_already_registered"}`.

- [ ] **Step 1: Write the failing test**

`backend/apps/authentication/tests/test_register.py`:
```python
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.profiles.models import ClientProfile, TaskerProfile
from apps.users.models import User


class RegisterEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-register")
        self.valid_payload = {
            "name": "Mya Mya",
            "phone_number": "09123456789",
            "password": "StrongPass123",
            "gender": "Female",
            "age": 28,
            "role": "CLIENT",
        }

    def test_register_creates_inactive_user_and_profile(self):
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["phone_number"], "09123456789")
        self.assertEqual(response.data["role"], "CLIENT")

        user = User.objects.get(phone_number="09123456789")
        self.assertFalse(user.is_active)
        self.assertEqual(user.status, "UNVERIFIED")
        self.assertTrue(ClientProfile.objects.filter(user=user, name="Mya Mya").exists())

    def test_register_creates_tasker_profile_for_tasker_role(self):
        payload = {**self.valid_payload, "phone_number": "09199999999", "role": "TASKER"}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(phone_number="09199999999")
        self.assertTrue(TaskerProfile.objects.filter(user=user).exists())
        self.assertFalse(ClientProfile.objects.filter(user=user).exists())

    def test_register_generates_an_otp(self):
        self.client.post(self.url, self.valid_payload, format="json")
        user = User.objects.get(phone_number="09123456789")
        self.assertTrue(user.otps.exists())

    def test_duplicate_phone_number_rejected(self):
        self.client.post(self.url, self.valid_payload, format="json")
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("code"), "phone_already_registered")

    def test_weak_password_rejected(self):
        payload = {**self.valid_payload, "phone_number": "09188888888", "password": "123"}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("password", response.data)

    def test_invalid_phone_format_rejected(self):
        payload = {**self.valid_payload, "phone_number": "12345"}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("phone_number", response.data)

    def test_age_out_of_bounds_rejected(self):
        payload = {**self.valid_payload, "phone_number": "09177777777", "age": 10}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("age", response.data)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python manage.py test apps.authentication.tests.test_register -v 2`
Expected: FAIL — `django.urls.exceptions.NoReverseMatch: 'auth-register' is not a registered namespace`

- [ ] **Step 3: Write `backend/apps/authentication/serializers.py`**

```python
import re

from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from rest_framework import serializers

from apps.authentication.services import generate_otp_for_user
from apps.profiles.models import ClientProfile, TaskerProfile
from apps.users.models import User

PHONE_REGEX = re.compile(r"^09\d{7,9}$")


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150)
    phone_number = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True)
    gender = serializers.CharField(max_length=10)
    age = serializers.IntegerField(min_value=16, max_value=100)
    role = serializers.ChoiceField(choices=User.ROLE_CHOICES)

    def validate_phone_number(self, value):
        if not PHONE_REGEX.match(value):
            raise serializers.ValidationError("Enter a valid phone number (e.g. 09123456789).")
        return value

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate(self, attrs):
        # Duplicate-phone check lives here, not in validate_phone_number,
        # because raising a dict from a field-level validator nests it
        # under that field's key in the response — the test asserts
        # response.data["code"] at the top level, so this needs to be a
        # non-field error instead.
        if User.objects.filter(phone_number=attrs["phone_number"]).exists():
            raise serializers.ValidationError(
                {"detail": "This phone number is already registered.", "code": "phone_already_registered"}
            )
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        user = User.objects.create_user(
            phone_number=validated_data["phone_number"],
            password=validated_data["password"],
            role=validated_data["role"],
        )
        profile_model = ClientProfile if validated_data["role"] == "CLIENT" else TaskerProfile
        profile_model.objects.create(
            user=user,
            name=validated_data["name"],
            gender=validated_data["gender"],
            age=validated_data["age"],
        )
        generate_otp_for_user(user)
        return user
```

- [ ] **Step 4: Write `backend/apps/authentication/views.py`**

```python
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.authentication.serializers import RegisterSerializer


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            {"user_id": user.id, "phone_number": user.phone_number, "role": user.role},
            status=status.HTTP_201_CREATED,
        )
```

- [ ] **Step 5: Write `backend/apps/authentication/urls.py`**

```python
from django.urls import path

from apps.authentication.views import RegisterView

urlpatterns = [
    path("register", RegisterView.as_view(), name="auth-register"),
]
```

- [ ] **Step 6: Run test to verify it passes**

Run: `python manage.py test apps.authentication.tests.test_register -v 2`
Expected: `Ran 7 tests in ...s` / `OK`

- [ ] **Step 7: Commit**

```bash
git add backend/apps/authentication/
git commit -m "feat(backend): add register endpoint"
```

---

## Task 6: Send-OTP endpoint

**Files:**
- Modify: `backend/apps/authentication/serializers.py` (add `SendOtpSerializer`)
- Modify: `backend/apps/authentication/views.py` (add `SendOtpView`)
- Modify: `backend/apps/authentication/urls.py` (add route)
- Create: `backend/apps/authentication/tests/test_send_otp.py`

**Interfaces:**
- Consumes: `generate_otp_for_user` (Task 4), `User` (Task 2).
- Produces: `POST /api/auth/send-otp` — request `{phone_number}`, response
  `200` `{otp_sent: true, dev_otp_code: "123456"}`, `404` if phone not
  registered, `429` `{"detail": "...", "code": "otp_cooldown"}` if called
  again within 30 seconds of the last OTP for that user.

- [ ] **Step 1: Write the failing test**

`backend/apps/authentication/tests/test_send_otp.py`:
```python
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.authentication.models import PhoneOTP
from apps.users.models import User


class SendOtpEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-send-otp")
        self.user = User.objects.create_user(phone_number="09123456789", password="x", role="CLIENT")

    def test_send_otp_returns_dev_code(self):
        response = self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["otp_sent"])
        otp = PhoneOTP.objects.get(user=self.user, is_used=False)
        self.assertEqual(response.data["dev_otp_code"], otp.code)

    def test_unregistered_phone_returns_404(self):
        response = self.client.post(self.url, {"phone_number": "09100000000"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_cooldown_blocks_immediate_resend(self):
        self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        response = self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertEqual(response.data.get("code"), "otp_cooldown")

    def test_resend_allowed_after_cooldown(self):
        self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        otp = PhoneOTP.objects.get(user=self.user, is_used=False)
        otp.created_at = timezone.now() - timezone.timedelta(seconds=31)
        otp.save(update_fields=["created_at"])
        response = self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python manage.py test apps.authentication.tests.test_send_otp -v 2`
Expected: FAIL — `NoReverseMatch: 'auth-send-otp' is not a registered namespace`

- [ ] **Step 3: Add `SendOtpSerializer` to `backend/apps/authentication/serializers.py`**

```python
from rest_framework.exceptions import NotFound


class SendOtpSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)

    def validate_phone_number(self, value):
        if not User.objects.filter(phone_number=value).exists():
            raise NotFound("No account found for this phone number.")
        return value
```

- [ ] **Step 4: Add `SendOtpView` to `backend/apps/authentication/views.py`**

```python
from django.utils import timezone

from apps.authentication.models import PhoneOTP
from apps.authentication.serializers import SendOtpSerializer
from apps.authentication.services import generate_otp_for_user
from apps.users.models import User

OTP_RESEND_COOLDOWN_SECONDS = 30


class SendOtpView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SendOtpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = User.objects.get(phone_number=serializer.validated_data["phone_number"])

        last_otp = PhoneOTP.objects.filter(user=user).order_by("-created_at").first()
        if last_otp:
            elapsed = (timezone.now() - last_otp.created_at).total_seconds()
            if elapsed < OTP_RESEND_COOLDOWN_SECONDS:
                return Response(
                    {"detail": "Please wait before requesting another code.", "code": "otp_cooldown"},
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

        otp = generate_otp_for_user(user)
        return Response({"otp_sent": True, "dev_otp_code": otp.code}, status=status.HTTP_200_OK)
```

(A `Response(...)` with an explicit status code is used for the cooldown
case rather than raising `rest_framework.exceptions.Throttled` — DRF's
built-in `Throttled` exception nests its detail under its own format and
doesn't expose a flat `{"detail": ..., "code": ...}` shape, which is what
the test and the spec's error-shape convention both expect.)

- [ ] **Step 5: Add the route to `backend/apps/authentication/urls.py`**

```python
from apps.authentication.views import RegisterView, SendOtpView

urlpatterns = [
    path("register", RegisterView.as_view(), name="auth-register"),
    path("send-otp", SendOtpView.as_view(), name="auth-send-otp"),
]
```

- [ ] **Step 6: Run test to verify it passes**

Run: `python manage.py test apps.authentication.tests.test_send_otp -v 2`
Expected: `Ran 4 tests in ...s` / `OK`

- [ ] **Step 7: Commit**

```bash
git add backend/apps/authentication/
git commit -m "feat(backend): add send-otp endpoint with resend cooldown"
```

---

## Task 7: Verify-OTP endpoint

**Files:**
- Modify: `backend/apps/authentication/serializers.py` (add `VerifyOtpSerializer`)
- Modify: `backend/apps/authentication/views.py` (add `VerifyOtpView`)
- Modify: `backend/apps/authentication/urls.py` (add route)
- Create: `backend/apps/authentication/tests/test_verify_otp.py`

**Interfaces:**
- Consumes: `PhoneOTP` (Task 4), `User` (Task 2),
  `rest_framework_simplejwt.tokens.RefreshToken`.
- Produces: `POST /api/auth/verify-otp` — request `{phone_number, code}`,
  response `200` `{access_token, refresh_token, user: {id, phone_number, role, status}}`,
  `400` wrong code, `410` expired/used, `423` locked after 5 attempts.

- [ ] **Step 1: Write the failing test**

`backend/apps/authentication/tests/test_verify_otp.py`:
```python
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.authentication.models import PhoneOTP
from apps.users.models import User


class VerifyOtpEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-verify-otp")
        self.user = User.objects.create_user(phone_number="09123456789", password="x", role="CLIENT")
        self.otp = PhoneOTP.objects.create(
            user=self.user, code="111111", expires_at=timezone.now() + timezone.timedelta(minutes=5)
        )

    def test_correct_code_activates_user_and_returns_tokens(self):
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access_token", response.data)
        self.assertIn("refresh_token", response.data)
        self.assertEqual(response.data["user"]["phone_number"], "09123456789")

        self.user.refresh_from_db()
        self.assertTrue(self.user.is_active)
        self.assertTrue(self.user.is_phone_verified)
        self.otp.refresh_from_db()
        self.assertTrue(self.otp.is_used)

    def test_wrong_code_returns_400_and_increments_attempts(self):
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "999999"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.otp.refresh_from_db()
        self.assertEqual(self.otp.attempts, 1)

    def test_expired_code_returns_410(self):
        self.otp.expires_at = timezone.now() - timezone.timedelta(minutes=1)
        self.otp.save(update_fields=["expires_at"])
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_410_GONE)

    def test_already_used_code_returns_410(self):
        self.otp.is_used = True
        self.otp.save(update_fields=["is_used"])
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_410_GONE)

    def test_locks_after_five_wrong_attempts(self):
        for _ in range(5):
            self.client.post(
                self.url, {"phone_number": "09123456789", "code": "000000"}, format="json"
            )
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_423_LOCKED)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python manage.py test apps.authentication.tests.test_verify_otp -v 2`
Expected: FAIL — `NoReverseMatch: 'auth-verify-otp' is not a registered namespace`

- [ ] **Step 3: Add `VerifyOtpSerializer` to `backend/apps/authentication/serializers.py`**

```python
class VerifyOtpSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)
    code = serializers.CharField(max_length=6)
```

(No custom validation here — the lookup/expiry/attempts/lock logic belongs
in the view, since it needs to mutate the `PhoneOTP` row, which a
serializer's `validate()` shouldn't do as a side effect of validation.)

- [ ] **Step 4: Add `VerifyOtpView` to `backend/apps/authentication/views.py`**

```python
from rest_framework_simplejwt.tokens import RefreshToken

from apps.authentication.serializers import VerifyOtpSerializer
from apps.authentication.services import MAX_OTP_ATTEMPTS


def _user_payload(user):
    return {"id": user.id, "phone_number": user.phone_number, "role": user.role, "status": user.status}


class VerifyOtpView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOtpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        code = serializer.validated_data["code"]

        user = User.objects.filter(phone_number=phone_number).first()
        if not user:
            return Response({"detail": "No account found for this phone number.", "code": "phone_not_found"}, status=status.HTTP_404_NOT_FOUND)

        otp = PhoneOTP.objects.filter(user=user, is_used=False).order_by("-created_at").first()
        if not otp:
            return Response({"detail": "No active code for this phone number.", "code": "otp_expired"}, status=status.HTTP_410_GONE)

        if otp.attempts >= MAX_OTP_ATTEMPTS:
            return Response({"detail": "Too many attempts. Request a new code.", "code": "otp_locked"}, status=status.HTTP_423_LOCKED)

        if timezone.now() > otp.expires_at:
            return Response({"detail": "This code has expired.", "code": "otp_expired"}, status=status.HTTP_410_GONE)

        if otp.code != code:
            otp.attempts += 1
            otp.save(update_fields=["attempts"])
            return Response({"detail": "Incorrect code.", "code": "otp_incorrect"}, status=status.HTTP_400_BAD_REQUEST)

        otp.is_used = True
        otp.save(update_fields=["is_used"])
        user.is_phone_verified = True
        user.is_active = True
        user.save(update_fields=["is_phone_verified", "is_active"])

        refresh = RefreshToken.for_user(user)
        return Response(
            {"access_token": str(refresh.access_token), "refresh_token": str(refresh), "user": _user_payload(user)},
            status=status.HTTP_200_OK,
        )
```

- [ ] **Step 5: Add the route to `backend/apps/authentication/urls.py`**

```python
from apps.authentication.views import RegisterView, SendOtpView, VerifyOtpView

urlpatterns = [
    path("register", RegisterView.as_view(), name="auth-register"),
    path("send-otp", SendOtpView.as_view(), name="auth-send-otp"),
    path("verify-otp", VerifyOtpView.as_view(), name="auth-verify-otp"),
]
```

- [ ] **Step 6: Run test to verify it passes**

Run: `python manage.py test apps.authentication.tests.test_verify_otp -v 2`
Expected: `Ran 5 tests in ...s` / `OK`

- [ ] **Step 7: Commit**

```bash
git add backend/apps/authentication/
git commit -m "feat(backend): add verify-otp endpoint with lockout"
```

---

## Task 8: Login endpoint

**Files:**
- Modify: `backend/apps/authentication/serializers.py` (add `LoginSerializer`)
- Modify: `backend/apps/authentication/views.py` (add `LoginView`)
- Modify: `backend/apps/authentication/urls.py` (add route)
- Create: `backend/apps/authentication/tests/test_login.py`

**Interfaces:**
- Consumes: `User` (Task 2), `_user_payload` (Task 7).
- Produces: `POST /api/auth/login` — request `{phone_number, password}`,
  response `200` same shape as verify-otp, `401` bad credentials, `403`
  `{"detail": "...", "code": "account_not_verified"}` if `is_active=False`.

- [ ] **Step 1: Write the failing test**

`backend/apps/authentication/tests/test_login.py`:
```python
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User


class LoginEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-login")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="StrongPass123", role="CLIENT"
        )

    def test_login_rejects_unverified_account(self):
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "password": "StrongPass123"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(response.data.get("code"), "account_not_verified")

    def test_login_succeeds_for_active_user(self):
        self.user.is_active = True
        self.user.save(update_fields=["is_active"])
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "password": "StrongPass123"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access_token", response.data)
        self.assertIn("refresh_token", response.data)

    def test_login_rejects_wrong_password(self):
        self.user.is_active = True
        self.user.save(update_fields=["is_active"])
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "password": "wrong"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_login_rejects_unknown_phone(self):
        response = self.client.post(
            self.url, {"phone_number": "09199999999", "password": "whatever"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python manage.py test apps.authentication.tests.test_login -v 2`
Expected: FAIL — `NoReverseMatch: 'auth-login' is not a registered namespace`

- [ ] **Step 3: Add `LoginSerializer` to `backend/apps/authentication/serializers.py`**

```python
class LoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True)
```

- [ ] **Step 4: Add `LoginView` to `backend/apps/authentication/views.py`**

```python
from apps.authentication.serializers import LoginSerializer


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        password = serializer.validated_data["password"]

        user = User.objects.filter(phone_number=phone_number).first()
        if not user or not user.check_password(password):
            return Response({"detail": "Invalid phone number or password.", "code": "invalid_credentials"}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_active:
            return Response({"detail": "Phone number not verified yet.", "code": "account_not_verified"}, status=status.HTTP_403_FORBIDDEN)

        refresh = RefreshToken.for_user(user)
        return Response(
            {"access_token": str(refresh.access_token), "refresh_token": str(refresh), "user": _user_payload(user)},
            status=status.HTTP_200_OK,
        )
```

- [ ] **Step 5: Add the route to `backend/apps/authentication/urls.py`**

```python
from apps.authentication.views import LoginView, RegisterView, SendOtpView, VerifyOtpView

urlpatterns = [
    path("register", RegisterView.as_view(), name="auth-register"),
    path("send-otp", SendOtpView.as_view(), name="auth-send-otp"),
    path("verify-otp", VerifyOtpView.as_view(), name="auth-verify-otp"),
    path("login", LoginView.as_view(), name="auth-login"),
]
```

- [ ] **Step 6: Run test to verify it passes**

Run: `python manage.py test apps.authentication.tests.test_login -v 2`
Expected: `Ran 4 tests in ...s` / `OK`

- [ ] **Step 7: Commit**

```bash
git add backend/apps/authentication/
git commit -m "feat(backend): add login endpoint"
```

---

## Task 9: Refresh endpoint

**Files:**
- Modify: `backend/apps/authentication/urls.py` (add route, wire simplejwt's built-in view)
- Create: `backend/apps/authentication/tests/test_refresh.py`

**Interfaces:**
- Consumes: `rest_framework_simplejwt.views.TokenRefreshView` (third-party,
  already installed in Task 1).
- Produces: `POST /api/auth/refresh` — request `{refresh_token}` (simplejwt
  expects the key named `refresh`, not `refresh_token` — see Step 3),
  response `200` `{access_token}`. Wait — simplejwt's default response key
  is `access`, not `access_token`. To match the spec's `{access_token}`
  exactly without forking simplejwt's view, wrap it in a thin custom view
  instead of using `TokenRefreshView` directly.

- [ ] **Step 1: Write the failing test**

`backend/apps/authentication/tests/test_refresh.py`:
```python
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User


class RefreshEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-refresh")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="CLIENT", is_active=True
        )
        self.refresh = RefreshToken.for_user(self.user)

    def test_valid_refresh_returns_new_access_token(self):
        response = self.client.post(self.url, {"refresh_token": str(self.refresh)}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access_token", response.data)

    def test_invalid_refresh_token_returns_401(self):
        response = self.client.post(self.url, {"refresh_token": "not-a-real-token"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python manage.py test apps.authentication.tests.test_refresh -v 2`
Expected: FAIL — `NoReverseMatch: 'auth-refresh' is not a registered namespace`

- [ ] **Step 3: Add `RefreshView` to `backend/apps/authentication/views.py`**

`RefreshToken` is already imported at the top of this file since Task 7
(`from rest_framework_simplejwt.tokens import RefreshToken`). Add one new
import for `TokenError`, then add the view:

```python
from rest_framework_simplejwt.exceptions import TokenError


class RefreshView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        refresh_token = request.data.get("refresh_token")
        if not refresh_token:
            return Response({"detail": "refresh_token is required.", "code": "refresh_token_required"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            refresh = RefreshToken(refresh_token)
        except TokenError:
            return Response({"detail": "Invalid or expired refresh token.", "code": "invalid_refresh_token"}, status=status.HTTP_401_UNAUTHORIZED)
        return Response({"access_token": str(refresh.access_token)}, status=status.HTTP_200_OK)
```

- [ ] **Step 4: Add the route to `backend/apps/authentication/urls.py`**

```python
from apps.authentication.views import LoginView, RefreshView, RegisterView, SendOtpView, VerifyOtpView

urlpatterns = [
    path("register", RegisterView.as_view(), name="auth-register"),
    path("send-otp", SendOtpView.as_view(), name="auth-send-otp"),
    path("verify-otp", VerifyOtpView.as_view(), name="auth-verify-otp"),
    path("login", LoginView.as_view(), name="auth-login"),
    path("refresh", RefreshView.as_view(), name="auth-refresh"),
]
```

- [ ] **Step 5: Run test to verify it passes**

Run: `python manage.py test apps.authentication.tests.test_refresh -v 2`
Expected: `Ran 2 tests in ...s` / `OK`

- [ ] **Step 6: Commit**

```bash
git add backend/apps/authentication/
git commit -m "feat(backend): add refresh endpoint"
```

---

## Task 10: Logout endpoint (token blacklist)

**Files:**
- Modify: `backend/apps/authentication/views.py` (add `LogoutView`)
- Modify: `backend/apps/authentication/urls.py` (add route)
- Create: `backend/apps/authentication/tests/test_logout.py`

**Interfaces:**
- Consumes: `rest_framework_simplejwt.token_blacklist` app (already in
  `INSTALLED_APPS` since Task 1 — its migrations need running once here).
- Produces: `POST /api/auth/logout` *(auth required)* — request
  `{refresh_token}`, response `200` empty body; the blacklisted refresh
  token then fails on subsequent `/refresh` calls.

- [ ] **Step 1: Run the blacklist app's migrations (one-time, not test-driven — it's third-party)**

```bash
python manage.py migrate token_blacklist
```
Expected: `Applying token_blacklist.0001_initial... OK` (and any other
`token_blacklist.000N` migrations bundled with the package).

- [ ] **Step 2: Write the failing test**

`backend/apps/authentication/tests/test_logout.py`:
```python
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User


class LogoutEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-logout")
        self.refresh_url = reverse("auth-refresh")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="CLIENT", is_active=True
        )
        self.refresh = RefreshToken.for_user(self.user)
        self.access = str(self.refresh.access_token)

    def test_logout_requires_authentication(self):
        response = self.client.post(self.url, {"refresh_token": str(self.refresh)}, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_logout_blacklists_refresh_token(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")
        response = self.client.post(self.url, {"refresh_token": str(self.refresh)}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        refresh_response = self.client.post(self.refresh_url, {"refresh_token": str(self.refresh)}, format="json")
        self.assertEqual(refresh_response.status_code, status.HTTP_401_UNAUTHORIZED)
```

- [ ] **Step 3: Run test to verify it fails**

Run: `python manage.py test apps.authentication.tests.test_logout -v 2`
Expected: FAIL — `NoReverseMatch: 'auth-logout' is not a registered namespace`

- [ ] **Step 4: Add `LogoutView` to `backend/apps/authentication/views.py`**

```python
from rest_framework.permissions import IsAuthenticated


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh_token")
        if not refresh_token:
            return Response({"detail": "refresh_token is required.", "code": "refresh_token_required"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError:
            return Response({"detail": "Invalid or already invalidated refresh token.", "code": "invalid_refresh_token"}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(status=status.HTTP_200_OK)
```

- [ ] **Step 5: Add the route to `backend/apps/authentication/urls.py`**

```python
from apps.authentication.views import LoginView, LogoutView, RefreshView, RegisterView, SendOtpView, VerifyOtpView

urlpatterns = [
    path("register", RegisterView.as_view(), name="auth-register"),
    path("send-otp", SendOtpView.as_view(), name="auth-send-otp"),
    path("verify-otp", VerifyOtpView.as_view(), name="auth-verify-otp"),
    path("login", LoginView.as_view(), name="auth-login"),
    path("refresh", RefreshView.as_view(), name="auth-refresh"),
    path("logout", LogoutView.as_view(), name="auth-logout"),
]
```

- [ ] **Step 6: Run test to verify it passes**

Run: `python manage.py test apps.authentication.tests.test_logout -v 2`
Expected: `Ran 2 tests in ...s` / `OK`

- [ ] **Step 7: Commit**

```bash
git add backend/apps/authentication/
git commit -m "feat(backend): add logout endpoint with refresh token blacklisting"
```

---

## Task 11: Me endpoint

**Files:**
- Modify: `backend/apps/authentication/views.py` (add `MeView`)
- Modify: `backend/apps/authentication/urls.py` (add route)
- Create: `backend/apps/authentication/tests/test_me.py`

**Interfaces:**
- Consumes: `ClientProfile`/`TaskerProfile` (Task 3), `_user_payload` (Task 7).
- Produces: `GET /api/auth/me` *(auth required)* → `200`
  `{id, phone_number, role, status, is_phone_verified, profile: {name, gender, age}}`,
  `401` if unauthenticated.

- [ ] **Step 1: Write the failing test**

`backend/apps/authentication/tests/test_me.py`:
```python
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.profiles.models import ClientProfile
from apps.users.models import User


class MeEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-me")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="CLIENT", is_active=True, is_phone_verified=True
        )
        ClientProfile.objects.create(user=self.user, name="Mya Mya", gender="Female", age=28)
        self.access = str(RefreshToken.for_user(self.user).access_token)

    def test_me_requires_authentication(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_returns_user_and_profile(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["phone_number"], "09123456789")
        self.assertEqual(response.data["profile"]["name"], "Mya Mya")
        self.assertEqual(response.data["profile"]["age"], 28)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python manage.py test apps.authentication.tests.test_me -v 2`
Expected: FAIL — `NoReverseMatch: 'auth-me' is not a registered namespace`

- [ ] **Step 3: Add `MeView` to `backend/apps/authentication/views.py`**

```python
class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        profile = user.client_profile if user.role == "CLIENT" else user.tasker_profile
        data = _user_payload(user)
        data["is_phone_verified"] = user.is_phone_verified
        data["profile"] = {"name": profile.name, "gender": profile.gender, "age": profile.age}
        return Response(data, status=status.HTTP_200_OK)
```

- [ ] **Step 4: Add the route to `backend/apps/authentication/urls.py`**

```python
from apps.authentication.views import LoginView, LogoutView, MeView, RefreshView, RegisterView, SendOtpView, VerifyOtpView

urlpatterns = [
    path("register", RegisterView.as_view(), name="auth-register"),
    path("send-otp", SendOtpView.as_view(), name="auth-send-otp"),
    path("verify-otp", VerifyOtpView.as_view(), name="auth-verify-otp"),
    path("login", LoginView.as_view(), name="auth-login"),
    path("refresh", RefreshView.as_view(), name="auth-refresh"),
    path("logout", LogoutView.as_view(), name="auth-logout"),
    path("me", MeView.as_view(), name="auth-me"),
]
```

- [ ] **Step 5: Run test to verify it passes**

Run: `python manage.py test apps.authentication.tests.test_me -v 2`
Expected: `Ran 2 tests in ...s` / `OK`

- [ ] **Step 6: Commit**

```bash
git add backend/apps/authentication/
git commit -m "feat(backend): add me endpoint"
```

---

## Task 12: Full suite verification

**Files:** none created/modified — verification only.

**Interfaces:** none.

- [ ] **Step 1: Run the entire backend test suite**

Run: `python manage.py test`
Expected: all tests across `apps.users`, `apps.profiles`, and
`apps.authentication` pass — `Ran 35 tests in ...s` / `OK` (3 + 2 + 4 + 7 + 4 + 5 + 4 + 2 + 2 + 2, one count per task above). The exact number matters less than zero failures — if it's off by one or two because of how a later task's edits touched an earlier test, that's fine as long as everything is green.

- [ ] **Step 2: Manually smoke-test the running server**

```bash
python manage.py runserver
```

In a separate terminal, run through the full lifecycle with `curl`:
```bash
curl -X POST http://127.0.0.1:8000/api/auth/register -H "Content-Type: application/json" -d "{\"name\":\"Test User\",\"phone_number\":\"09123456780\",\"password\":\"StrongPass123\",\"gender\":\"Female\",\"age\":25,\"role\":\"CLIENT\"}"
```
Expected: `201` with `{"user_id": ..., "phone_number": "09123456780", "role": "CLIENT"}`.

```bash
curl -X POST http://127.0.0.1:8000/api/auth/send-otp -H "Content-Type: application/json" -d "{\"phone_number\":\"09123456780\"}"
```
Expected: `200` with `{"otp_sent": true, "dev_otp_code": "..."}` — copy that code.

```bash
curl -X POST http://127.0.0.1:8000/api/auth/verify-otp -H "Content-Type: application/json" -d "{\"phone_number\":\"09123456780\",\"code\":\"<paste code>\"}"
```
Expected: `200` with `access_token`/`refresh_token`/`user`.

```bash
curl http://127.0.0.1:8000/api/auth/me -H "Authorization: Bearer <paste access_token>"
```
Expected: `200` with the user's profile data.

Stop the server (`Ctrl+C`) once this confirms cleanly.

- [ ] **Step 3: Update root `CLAUDE.md`'s Phase 1 description**

`CLAUDE.md` currently states the project is "Phase 1: a fully offline MVP —
... no backend/database/network." This is no longer fully accurate now
that `backend/` exists. Modify the Project section's opening paragraph
(find the line starting with "TOLY MOLY — an on-demand service
marketplace") to add one sentence after it:

```
A Django REST Framework + PostgreSQL backend now exists under `backend/`
for user onboarding (registration, OTP, JWT auth) — see
`docs/superpowers/specs/2026-06-29-onboarding-backend-auth-design.md`. The
Flutter app itself is not yet wired to it; that's a separate follow-up
phase, and every other feature remains fully offline as described below.
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: note new backend/ in CLAUDE.md project description"
```
