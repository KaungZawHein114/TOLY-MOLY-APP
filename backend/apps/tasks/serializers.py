from rest_framework import serializers

from apps.tasks.models import Booking, Task


class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = [
            "id",
            "category",
            "title",
            "description",
            "date",
            "time",
            "latitude",
            "longitude",
            "address",
            "urgency",
            "budget_tier",
            "worker_tier_min",
            "worker_tier_max",
            "budget_mmk",
            "status",
            "created_at",
        ]
        read_only_fields = ["id", "status", "created_at"]


PUBLISH_REQUIRED_FIELDS = ["category", "title", "date", "time", "budget_tier", "budget_mmk"]


class AnalyzeTaskSerializer(serializers.Serializer):
    message = serializers.CharField()
    history = serializers.ListField(child=serializers.DictField(), required=False, default=list)
    known_fields = serializers.DictField(required=False, default=dict)


class ExtractTaskSerializer(serializers.Serializer):
    """One-shot voice/text extraction — the whole spoken description in a
    single field. No history or known_fields: this flow makes one pass and
    goes straight to review (see services.extract_task)."""

    transcript = serializers.CharField()


class BudgetOptionsSerializer(serializers.Serializer):
    category = serializers.CharField()
    urgency = serializers.ChoiceField(choices=Task.URGENCY_CHOICES, default=Task.URGENCY_NORMAL)


class BookingSerializer(serializers.ModelSerializer):
    """Read-only view of a booking returned after every lifecycle action."""

    class Meta:
        model = Booking
        fields = [
            "id",
            "task",
            "worker",
            "client",
            "status",
            "worker_checkin_at",
            "client_checkin_confirmed_at",
            "worker_checkout_at",
            "client_checkout_confirmed_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class PublishTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = [
            "category",
            "title",
            "description",
            "date",
            "time",
            "latitude",
            "longitude",
            "address",
            "urgency",
            "budget_tier",
            "worker_tier_min",
            "worker_tier_max",
            "budget_mmk",
        ]
        # The "every required field present" check (PUBLISH_REQUIRED_FIELDS)
        # lives in TaskListCreateView.post, not here — raising a dict from
        # a serializer's validate() gets each value wrapped in a list by
        # DRF, which breaks the flat {"detail": ..., "code": ...} shape
        # the rest of this API uses for business-logic errors (same reason
        # apps.authentication.serializers.RegisterSerializer does the same).
