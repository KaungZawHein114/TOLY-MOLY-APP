from django.contrib import admin

from apps.profiles.models import ClientProfile, TaskerProfile


@admin.register(ClientProfile)
class ClientProfileAdmin(admin.ModelAdmin):
    list_display = ["name", "user", "gender", "age"]
    search_fields = ["name", "user__phone_number"]


@admin.register(TaskerProfile)
class TaskerProfileAdmin(admin.ModelAdmin):
    list_display = ["name", "user", "gender", "age", "tier", "trust_score"]
    search_fields = ["name", "user__phone_number"]
