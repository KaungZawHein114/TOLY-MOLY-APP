from django.contrib import admin

from apps.tasks.models import Task


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ["title", "category", "client", "status", "urgency", "budget_tier", "budget_mmk", "created_at"]
    list_filter = ["status", "category", "urgency", "budget_tier"]
    search_fields = ["title", "category", "client__phone_number"]
