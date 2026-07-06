from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.authentication.services import has_verified_otp
from apps.profiles.serializers import (
    ClientProfileSerializer,
    PhoneChangeSerializer,
    ProfilePictureUploadSerializer,
    TaskerProfileSerializer,
)
from apps.users.models import User


def _profile_and_serializer_class(user):
    if user.role == "CLIENT":
        return user.client_profile, ClientProfileSerializer
    return user.tasker_profile, TaskerProfileSerializer


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, serializer_class = _profile_and_serializer_class(request.user)
        data = serializer_class(profile).data
        # phone_number/status live on the User row, not the profile — merge
        # them in here so the app can render the whole profile from one call.
        data["phone_number"] = request.user.phone_number
        data["status"] = request.user.status
        return Response(data, status=status.HTTP_200_OK)

    def put(self, request):
        profile, serializer_class = _profile_and_serializer_class(request.user)
        serializer = serializer_class(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


class ProfilePictureUploadView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = ProfilePictureUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        profile, _ = _profile_and_serializer_class(request.user)
        profile.profile_picture = serializer.validated_data["profile_picture"]
        profile.save(update_fields=["profile_picture"])
        return Response({"profile_picture": profile.profile_picture.url}, status=status.HTTP_200_OK)


class PhoneChangeView(APIView):
    """Only callable after the new number has passed verify-otp (see
    apps.authentication.services.has_verified_otp) — the OTP flow itself is
    handled by /api/auth/send-otp and /api/auth/verify-otp, this endpoint
    just requires proof it already succeeded before committing the change."""

    permission_classes = [IsAuthenticated]

    def put(self, request):
        serializer = PhoneChangeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]

        if User.objects.exclude(pk=request.user.pk).filter(phone_number=phone_number).exists():
            return Response(
                {"detail": "This phone number is already registered.", "code": "phone_already_registered"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not has_verified_otp(phone_number):
            return Response(
                {"detail": "Please verify this phone number first.", "code": "otp_not_verified"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        request.user.phone_number = phone_number
        request.user.save(update_fields=["phone_number"])
        return Response({"phone_number": phone_number}, status=status.HTTP_200_OK)
