from django.db import models
from django.utils import timezone

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


# ─────────────────────────────────────────────────────────────────────────────
# Booking — a matched, confirmed job between a client and a tasker.
# A Booking is created when a tasker's interest is accepted for a Task.
# The check-in / check-out lifecycle lives here.
# ─────────────────────────────────────────────────────────────────────────────

class Booking(models.Model):
    # Status constants — ordered by lifecycle stage
    STATUS_PENDING = "pending"
    STATUS_ACCEPTED = "accepted"
    STATUS_WORKER_ARRIVED = "worker_arrived"
    STATUS_WAITING_CHECKIN_CONFIRM = "waiting_client_checkin_confirm"
    STATUS_IN_PROGRESS = "in_progress"
    STATUS_WAITING_CHECKOUT_CONFIRM = "waiting_client_checkout_confirm"
    STATUS_COMPLETED = "completed"
    STATUS_ARRIVAL_DISPUTED = "arrival_disputed"
    STATUS_COMPLETION_DISPUTED = "completion_disputed"
    STATUS_CANCELLED = "cancelled"

    STATUS_CHOICES = [
        (STATUS_PENDING, "Pending"),
        (STATUS_ACCEPTED, "Accepted"),
        (STATUS_WORKER_ARRIVED, "Worker Arrived"),
        (STATUS_WAITING_CHECKIN_CONFIRM, "Waiting Client Check-In Confirm"),
        (STATUS_IN_PROGRESS, "In Progress"),
        (STATUS_WAITING_CHECKOUT_CONFIRM, "Waiting Client Checkout Confirm"),
        (STATUS_COMPLETED, "Completed"),
        (STATUS_ARRIVAL_DISPUTED, "Arrival Disputed"),
        (STATUS_COMPLETION_DISPUTED, "Completion Disputed"),
        (STATUS_CANCELLED, "Cancelled"),
    ]

    # Valid status transitions for each action
    VALID_CHECKIN_FROM = {STATUS_ACCEPTED}
    VALID_CLIENT_CONFIRM_CHECKIN_FROM = {STATUS_WORKER_ARRIVED, STATUS_WAITING_CHECKIN_CONFIRM}
    VALID_CLIENT_REJECT_CHECKIN_FROM = {STATUS_WORKER_ARRIVED, STATUS_WAITING_CHECKIN_CONFIRM}
    VALID_CHECKOUT_FROM = {STATUS_IN_PROGRESS}
    VALID_CLIENT_CONFIRM_CHECKOUT_FROM = {STATUS_WAITING_CHECKOUT_CONFIRM}
    VALID_CLIENT_REPORT_ISSUE_FROM = {STATUS_WAITING_CHECKOUT_CONFIRM}

    task = models.ForeignKey(
        Task,
        on_delete=models.CASCADE,
        related_name="bookings",
        null=True,
        blank=True,
    )
    worker = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="worker_bookings",
    )
    client = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="client_bookings",
    )

    status = models.CharField(
        max_length=40,
        choices=STATUS_CHOICES,
        default=STATUS_ACCEPTED,
    )

    # Lifecycle timestamps
    worker_checkin_at = models.DateTimeField(null=True, blank=True)
    client_checkin_confirmed_at = models.DateTimeField(null=True, blank=True)
    worker_checkout_at = models.DateTimeField(null=True, blank=True)
    client_checkout_confirmed_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Booking #{self.pk} — {self.status}"

    # ── Lifecycle actions ────────────────────────────────────────────────────

    def worker_checkin(self):
        self.status = self.STATUS_WAITING_CHECKIN_CONFIRM
        self.worker_checkin_at = timezone.now()
        self.save(update_fields=["status", "worker_checkin_at", "updated_at"])

    def client_confirm_checkin(self):
        self.status = self.STATUS_IN_PROGRESS
        self.client_checkin_confirmed_at = timezone.now()
        self.save(update_fields=["status", "client_checkin_confirmed_at", "updated_at"])

    def client_reject_checkin(self):
        self.status = self.STATUS_ARRIVAL_DISPUTED
        self.save(update_fields=["status", "updated_at"])

    def worker_checkout(self):
        self.status = self.STATUS_WAITING_CHECKOUT_CONFIRM
        self.worker_checkout_at = timezone.now()
        self.save(update_fields=["status", "worker_checkout_at", "updated_at"])

    def client_confirm_checkout(self):
        self.status = self.STATUS_COMPLETED
        self.client_checkout_confirmed_at = timezone.now()
        self.save(update_fields=["status", "client_checkout_confirmed_at", "updated_at"])

    def client_report_issue(self):
        self.status = self.STATUS_COMPLETION_DISPUTED
        self.save(update_fields=["status", "updated_at"])
