from django.urls import path

from apps.profiles.views import ProfilePictureUploadView, ProfileView

urlpatterns = [
    path("", ProfileView.as_view(), name="profile"),
    path("upload-picture", ProfilePictureUploadView.as_view(), name="profile-upload-picture"),
]
