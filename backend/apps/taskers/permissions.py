from rest_framework.permissions import BasePermission


class IsTasker(BasePermission):
    """Only TASKER-role accounts manage skills — skills are tasker-only data."""

    message = "Only tasker accounts can manage skills."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == "TASKER")
