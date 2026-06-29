# Onboarding Backend — Phase 1 (Auth API) — Design Spec

> Source: user-provided "TOLY MOLY — User Onboarding Technical Design"
> (Django REST Framework + PostgreSQL + JWT). That doc covers Authentication
> *and* full KYC/Verification *and* Tasker Skills in one document — this spec
> covers only the first slice of it, per an explicit "phase by phase"
> decomposition agreed with the user. Later slices (Flutter integration,
> profile/picture upload, verification, tasker skills) get their own specs.

## 1. Scope

**In scope:**
- New Django project at `backend/` (repo root, monorepo alongside `lib/`).
- Apps: `authentication`, `users`, `profiles` (fully built); `verification`,
  `taskers` (scaffolded as empty Django apps only — no models/views yet, so
  later phases don't need to re-run `startapp` and re-wire `INSTALLED_APPS`).
- PostgreSQL connection to the user's existing local `tolymoly` database.
- Endpoints: `register`, `send-otp`, `verify-otp`, `login`, `refresh`,
  `logout`, `me`.
- `User`, `PhoneOTP`, `ClientProfile`, `TaskerProfile` models — profile
  models hold only `name`/`gender`/`age` for now.
- Automated tests (DRF `APITestCase`) covering every endpoint's happy path
  and documented error cases.

**Explicitly out of scope (separate future specs):**
- Flutter integration — no `dio`, `flutter_secure_storage`, or repository
  layer touched this phase. The existing offline onboarding screens
  (`lib/features/onboarding/**`) are untouched.
- File uploads (profile picture, NRC, face, promotion video).
- Verification workflow logic, tasker skills, trust score, tier.
- Real SMS gateway integration, OCR, AI face matching, device recognition,
  admin approval workflows — all explicitly future per the source doc's own
  §18/§19.

## 2. Resolved decisions (from brainstorming)

| Question | Decision |
|---|---|
| OTP delivery | Dev-mode mock — `send-otp` returns the code directly in the response body (`dev_otp_code`) instead of sending a real SMS. Swapped for a real gateway later behind the same endpoint contract. |
| Logout semantics | Real server-side invalidation via `djangorestframework-simplejwt`'s token-blacklist app. |
| User row creation timing | Created immediately at `register` (`is_active=False`), not deferred until OTP succeeds. OTP gates login, not row existence. |
| Profile creation mechanism | Explicit, inside the `register` view's DB transaction — not a `post_save` signal — since it needs request data (`name`/`gender`/`age`) the signal wouldn't have. |
| Python tooling | Plain `venv` + `requirements.txt` (no poetry/pipenv). |
| JWT library | `djangorestframework-simplejwt`. |
| Settings/secrets | `django-environ` reading a local `.env` (gitignored) for `DATABASE_URL`, `SECRET_KEY`, JWT lifetimes. |
| User identity field | Custom `User` model, `phone_number` as `USERNAME_FIELD` — no `username`/`email` fields at all, matching the source doc exactly. |

## 3. Data model

```python
# apps/users/models.py
class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = [("CLIENT", "Client"), ("TASKER", "Tasker")]
    STATUS_CHOICES = [
        ("UNVERIFIED", "Unverified"),
        ("PENDING_VERIFICATION", "Pending Verification"),
        ("VERIFIED", "Verified"),
        ("SUSPENDED", "Suspended"),
    ]

    phone_number = models.CharField(max_length=20, unique=True, db_index=True)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)   # set once, never edited after creation
    status = models.CharField(max_length=24, choices=STATUS_CHOICES, default="UNVERIFIED")
    is_phone_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=False)   # False until OTP verified — gates login
    is_staff = models.BooleanField(default=False)     # required by PermissionsMixin/Django admin
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS = []
```

```python
# apps/authentication/models.py
class PhoneOTP(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="otps")
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()       # 5 minutes from creation
    is_used = models.BooleanField(default=False)
    attempts = models.PositiveSmallIntegerField(default=0)   # locks at 5 wrong tries
```

```python
# apps/profiles/models.py
class ClientProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="client_profile")
    name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10)
    age = models.PositiveSmallIntegerField()

class TaskerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="tasker_profile")
    name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10)
    age = models.PositiveSmallIntegerField()
```

`status` (marketplace lifecycle: UNVERIFIED→VERIFIED etc.) and `is_active`
(Django/simplejwt's login gate, tied only to phone verification) are
deliberately separate concerns — conflating them would make the KYC
verification phase harder to build correctly later.

## 4. API contracts

**POST `/api/auth/register`**
Request: `{ name, phone_number, password, gender, age, role }` (`role`: `"CLIENT"` | `"TASKER"`)
- Creates `User` (`is_active=False`, `status="UNVERIFIED"`) + matching
  `ClientProfile`/`TaskerProfile`, in one transaction. Auto-generates and
  "sends" (dev-mode) the first OTP.
- `201` → `{ user_id, phone_number, role }`.
- `400` → duplicate phone, weak password, or other field validation failure.

**POST `/api/auth/send-otp`**
Request: `{ phone_number }`
- Invalidates any prior unused OTP for that user, creates a new one
  (5-minute expiry).
- `200` → `{ otp_sent: true, dev_otp_code: "123456" }` (dev-mode only — this
  key is removed entirely once a real SMS gateway is wired in).
- `404` → phone not registered. `429` → requested again within a 30s cooldown.

**POST `/api/auth/verify-otp`**
Request: `{ phone_number, code }`
- Match → marks OTP used, sets `is_phone_verified=True`, `is_active=True`,
  issues tokens.
- `200` → `{ access_token, refresh_token, user: { id, phone_number, role, status } }`.
- `400` → wrong code (increments `attempts`). `410` → expired/already-used.
  `423` → locked after 5 wrong attempts (caller must call send-otp again).

**POST `/api/auth/login`**
Request: `{ phone_number, password }`
- `200` → same token+user shape as verify-otp.
- `401` → bad credentials. `403` → `is_active=False` (phone never verified —
  distinct from bad-password so Flutter can route back to OTP instead of
  showing "wrong password").

**POST `/api/auth/refresh`**
Request: `{ refresh_token }` → `200` `{ access_token }`. `401` → invalid/blacklisted/expired.

**POST `/api/auth/logout`** *(auth required)*
Request: `{ refresh_token }` → blacklists it. `200`/`205` empty body. `401` → not authenticated.

**GET `/api/auth/me`** *(auth required)*
→ `200` `{ id, phone_number, role, status, is_phone_verified, profile: { name, gender, age } }`
(`profile` sourced from whichever of `ClientProfile`/`TaskerProfile` matches `role`).

## 5. Validation, errors, testing

- `phone_number`: regex-validated (`^09\d{7,9}$` — Myanmar mobile format,
  adjustable later), unique.
- `password`: Django's `validate_password` (length/common-password checks).
- `age`: positive integer, bounded 16–100.
- `gender`: plain validated non-empty string for now — not locked to an enum,
  since the real allowed values belong to a Flutter `gender_selector.dart`
  widget that doesn't exist yet (next phase's concern).
- Error shape: DRF's default per-field format for validation errors
  (`{"phone_number": ["..."]}`); a consistent `{"detail": "...", "code": "..."}`
  for business-logic errors. `code` values: `phone_already_registered`,
  `otp_expired`, `otp_locked`, `account_not_verified`, `otp_cooldown`.
- Permissions: `AllowAny` on register/send-otp/verify-otp/login/refresh;
  `IsAuthenticated` on `/me` and `/logout`.
- Testing: DRF `APITestCase`, one module per endpoint, happy path + every
  error case listed in §4.
- CORS: `django-cors-headers`, all origins allowed only while `DEBUG=True`.

## 6. Project structure

```
backend/
├── manage.py
├── requirements.txt
├── .env.example          # DATABASE_URL, SECRET_KEY, JWT lifetimes — no real secrets committed
├── config/                # Django project: settings, root urls
└── apps/
    ├── authentication/    # PhoneOTP model; register/send-otp/verify-otp/login/refresh/logout/me views
    ├── users/             # User model + custom manager
    ├── profiles/          # ClientProfile/TaskerProfile models
    ├── verification/      # scaffolded only — no models/views yet
    └── taskers/           # scaffolded only — no models/views yet
```

## 7. Future slices (not built now, listed for continuity)

- Flutter integration: `dio` client, `flutter_secure_storage` token storage,
  `features/auth/` repository layer per the source doc's §15, rewiring the
  existing onboarding screens to call this API.
- Profile picture upload (`POST /api/profile/upload-picture`).
- Verification app: NRC/face/video upload endpoints, `Verification` model,
  approval workflow.
- Taskers app: skills CRUD, tier, trust score.
- Real SMS gateway, OCR, AI face matching, device recognition, MFA — per the
  source doc's own §18 "Future Enhancements" and §19 Phase 3.
