from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    ordering = ("phone_number",)

    list_display = (
        "phone_number",
        "role",
        "status",
        "is_phone_verified",
        "is_staff",
        "is_superuser",
        "is_active",
    )

    search_fields = (
        "phone_number",
    )

    fieldsets = (
        (
            "Authentication",
            {
                "fields": (
                    "phone_number",
                    "password",
                )
            },
        ),
        (
            "Profile",
            {
                "fields": (
                    "role",
                    "status",
                    "is_phone_verified",
                )
            },
        ),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        (
            "Important Dates",
            {
                "fields": (
                    "created_at",
                    "updated_at",
                )
            },
        ),
    )

    readonly_fields = (
        "created_at",
        "updated_at",
    )

    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "phone_number",
                    "password1",
                    "password2",
                    "role",
                ),
            },
        ),
    )