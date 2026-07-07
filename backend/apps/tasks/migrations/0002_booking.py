import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("tasks", "0001_initial"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="Booking",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("pending", "Pending"),
                            ("accepted", "Accepted"),
                            ("worker_arrived", "Worker Arrived"),
                            ("waiting_client_checkin_confirm", "Waiting Client Check-In Confirm"),
                            ("in_progress", "In Progress"),
                            ("waiting_client_checkout_confirm", "Waiting Client Checkout Confirm"),
                            ("completed", "Completed"),
                            ("arrival_disputed", "Arrival Disputed"),
                            ("completion_disputed", "Completion Disputed"),
                            ("cancelled", "Cancelled"),
                        ],
                        default="accepted",
                        max_length=40,
                    ),
                ),
                ("worker_checkin_at", models.DateTimeField(blank=True, null=True)),
                ("client_checkin_confirmed_at", models.DateTimeField(blank=True, null=True)),
                ("worker_checkout_at", models.DateTimeField(blank=True, null=True)),
                ("client_checkout_confirmed_at", models.DateTimeField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "client",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="client_bookings",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "task",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="bookings",
                        to="tasks.task",
                    ),
                ),
                (
                    "worker",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="worker_bookings",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "ordering": ["-created_at"],
            },
        ),
    ]
