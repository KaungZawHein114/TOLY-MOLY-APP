from rest_framework.permissions import BasePermission


class IsClient(BasePermission):
    """Only CLIENT-role accounts post tasks."""

    message = "Only client accounts can post tasks."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == "CLIENT")


class IsTasker(BasePermission):
    """Only TASKER-role accounts perform worker-side booking actions."""

    message = "Only tasker accounts can perform this action."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == "TASKER")
