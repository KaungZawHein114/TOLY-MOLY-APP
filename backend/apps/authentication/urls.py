from django.urls import path

from apps.authentication.views import (
    LoginView,
    LogoutView,
    MeView,
    RefreshView,
    RegisterView,
    SendOtpView,
    VerifyOtpView,
)

urlpatterns = [
    path("register", RegisterView.as_view(), name="auth-register"),
    path("send-otp", SendOtpView.as_view(), name="auth-send-otp"),
    path("verify-otp", VerifyOtpView.as_view(), name="auth-verify-otp"),
    path("login", LoginView.as_view(), name="auth-login"),
    path("refresh", RefreshView.as_view(), name="auth-refresh"),
    path("logout", LogoutView.as_view(), name="auth-logout"),
    path("me", MeView.as_view(), name="auth-me"),
]
