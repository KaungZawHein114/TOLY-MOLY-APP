from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from apps.authentication.models import PhoneOTP
from apps.authentication.serializers import (
    LoginSerializer,
    RegisterSerializer,
    SendOtpSerializer,
    VerifyOtpSerializer,
)
from apps.authentication.services import (
    MAX_OTP_ATTEMPTS,
    generate_otp_for_phone,
    has_verified_otp,
)
from apps.users.models import User

OTP_RESEND_COOLDOWN_SECONDS = 30


def _user_payload(user):
    return {"id": user.id, "phone_number": user.phone_number, "role": user.role, "status": user.status}


class RegisterView(APIView):
    """The final onboarding step (after rules agreement) — this is the only
    moment a User row gets created, and only once phone ownership was
    already proven via verify-otp. No more half-finished accounts left
    behind by someone who drops off mid-flow."""

    permission_classes = [AllowAny]

    def post(self, request):
        phone_number = request.data.get("phone_number")
        if phone_number and User.objects.filter(phone_number=phone_number).exists():
            return Response(
                {"detail": "This phone number is already registered.", "code": "phone_already_registered"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if phone_number and not has_verified_otp(phone_number):
            return Response(
                {"detail": "Please verify your phone number first.", "code": "otp_not_verified"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        return Response(
            {"access_token": str(refresh.access_token), "refresh_token": str(refresh), "user": _user_payload(user)},
            status=status.HTTP_201_CREATED,
        )


class SendOtpView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SendOtpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]

        if User.objects.filter(phone_number=phone_number).exists():
            return Response(
                {"detail": "This phone number is already registered.", "code": "phone_already_registered"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        last_otp = PhoneOTP.objects.filter(phone_number=phone_number).order_by("-created_at").first()
        if last_otp:
            elapsed = (timezone.now() - last_otp.created_at).total_seconds()
            if elapsed < OTP_RESEND_COOLDOWN_SECONDS:
                return Response(
                    {"detail": "Please wait before requesting another code.", "code": "otp_cooldown"},
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

        otp = generate_otp_for_phone(phone_number)
        return Response({"otp_sent": True, "dev_otp_code": otp.code}, status=status.HTTP_200_OK)


class VerifyOtpView(APIView):
    """Proves phone ownership before any account exists — does not create a
    User or issue tokens. RegisterView is what actually creates the account,
    once this has succeeded recently enough (see has_verified_otp)."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOtpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        code = serializer.validated_data["code"]

        otp = PhoneOTP.objects.filter(phone_number=phone_number, is_used=False).order_by("-created_at").first()
        if not otp:
            return Response(
                {"detail": "No active code for this phone number.", "code": "otp_expired"},
                status=status.HTTP_410_GONE,
            )

        if otp.attempts >= MAX_OTP_ATTEMPTS:
            return Response(
                {"detail": "Too many attempts. Request a new code.", "code": "otp_locked"},
                status=status.HTTP_423_LOCKED,
            )

        if timezone.now() > otp.expires_at:
            return Response(
                {"detail": "This code has expired.", "code": "otp_expired"},
                status=status.HTTP_410_GONE,
            )

        if otp.code != code:
            otp.attempts += 1
            otp.save(update_fields=["attempts"])
            return Response(
                {"detail": "Incorrect code.", "code": "otp_incorrect"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp.is_used = True
        otp.save(update_fields=["is_used"])
        return Response({"phone_verified": True}, status=status.HTTP_200_OK)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        password = serializer.validated_data["password"]

        user = User.objects.filter(phone_number=phone_number).first()
        if not user or not user.check_password(password):
            return Response(
                {"detail": "Invalid phone number or password.", "code": "invalid_credentials"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if not user.is_active:
            return Response(
                {"detail": "Phone number not verified yet.", "code": "account_not_verified"},
                status=status.HTTP_403_FORBIDDEN,
            )

        refresh = RefreshToken.for_user(user)
        return Response(
            {"access_token": str(refresh.access_token), "refresh_token": str(refresh), "user": _user_payload(user)},
            status=status.HTTP_200_OK,
        )


class RefreshView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        refresh_token = request.data.get("refresh_token")
        if not refresh_token:
            return Response(
                {"detail": "refresh_token is required.", "code": "refresh_token_required"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            refresh = RefreshToken(refresh_token)
        except TokenError:
            return Response(
                {"detail": "Invalid or expired refresh token.", "code": "invalid_refresh_token"},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        return Response({"access_token": str(refresh.access_token)}, status=status.HTTP_200_OK)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh_token")
        if not refresh_token:
            return Response(
                {"detail": "refresh_token is required.", "code": "refresh_token_required"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError:
            return Response(
                {"detail": "Invalid or already invalidated refresh token.", "code": "invalid_refresh_token"},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        return Response(status=status.HTTP_200_OK)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        profile = user.client_profile if user.role == "CLIENT" else user.tasker_profile
        data = _user_payload(user)
        data["is_phone_verified"] = user.is_phone_verified
        data["profile"] = {"name": profile.name, "gender": profile.gender, "age": profile.age}
        return Response(data, status=status.HTTP_200_OK)
