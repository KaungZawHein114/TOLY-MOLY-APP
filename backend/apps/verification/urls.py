from django.urls import path

from apps.verification.views import (
    UploadFaceView,
    UploadNrcView,
    UploadVideoView,
    VerificationStatusView,
)

urlpatterns = [
    path("upload-nrc", UploadNrcView.as_view(), name="verification-upload-nrc"),
    path("upload-face", UploadFaceView.as_view(), name="verification-upload-face"),
    path("upload-video", UploadVideoView.as_view(), name="verification-upload-video"),
    path("status", VerificationStatusView.as_view(), name="verification-status"),
]
