from django.db import models

from apps.users.models import User

# Worker tier bands a budget option maps to — matches the 7-Tier Trust
# System (Tier 1-2 Basic / 3-5 Trusted / 6-7 Expert) loosely, but task
# posting groups them into the three client-facing options the spec calls
# for instead of exposing raw tier numbers.
BUDGET_TIER_BANDS = {
    "ECONOMY": (1, 3),
    "STANDARD": (4, 5),
    "PROFESSIONAL": (6, 7),
}


class Task(models.Model):
    STATUS_PENDING = "PENDING"
    STATUS_ONGOING = "ONGOING"
    STATUS_COMPLETED = "COMPLETED"
    STATUS_CANCELLED = "CANCELLED"
    STATUS_CHOICES = [
        (STATUS_PENDING, "Pending"),
        (STATUS_ONGOING, "Ongoing"),
        (STATUS_COMPLETED, "Completed"),
        (STATUS_CANCELLED, "Cancelled"),
    ]

    URGENCY_NORMAL = "NORMAL"
    URGENCY_URGENT = "URGENT"
    URGENCY_CHOICES = [(URGENCY_NORMAL, "Normal"), (URGENCY_URGENT, "Urgent")]

    BUDGET_TIER_CHOICES = [
        ("ECONOMY", "Economy"),
        ("STANDARD", "Standard"),
        ("PROFESSIONAL", "Professional"),
    ]

    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name="posted_tasks")

    category = models.CharField(max_length=50)
    title = models.CharField(max_length=150)
    description = models.TextField(blank=True)

    date = models.DateField(null=True, blank=True)
    time = models.TimeField(null=True, blank=True)

    # Device GPS, sent directly by the client app — the AI only ever
    # *confirms* this (spec Step 6), it never determines coordinates from
    # text. address is a human-readable label for display (e.g. reverse
    # geocoded township), not authoritative.
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    address = models.CharField(max_length=255, blank=True)

    urgency = models.CharField(max_length=10, choices=URGENCY_CHOICES, default=URGENCY_NORMAL)

    budget_tier = models.CharField(max_length=20, choices=BUDGET_TIER_CHOICES, null=True, blank=True)
    worker_tier_min = models.PositiveSmallIntegerField(null=True, blank=True)
    worker_tier_max = models.PositiveSmallIntegerField(null=True, blank=True)
    budget_mmk = models.PositiveIntegerField(null=True, blank=True)

    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_PENDING)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} ({self.category}) — {self.status}"
