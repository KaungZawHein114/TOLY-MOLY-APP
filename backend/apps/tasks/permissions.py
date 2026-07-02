from rest_framework.permissions import BasePermission


class IsClient(BasePermission):
    """Only CLIENT-role accounts post tasks — posting a task is a client
    action, mirroring apps.taskers.permissions.IsTasker for the inverse."""

    message = "Only client accounts can post tasks."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == "CLIENT")
