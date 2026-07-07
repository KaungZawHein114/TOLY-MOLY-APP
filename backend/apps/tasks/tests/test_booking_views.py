"""
Tests for the Booking check-in / check-out lifecycle endpoints.

Every test follows the same pattern:
  1. Arrange — create users, a booking in a given status.
  2. Act    — hit the endpoint with the correct / wrong actor.
  3. Assert — response code, returned status, DB state, timestamps.
"""

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.tasks.models import Booking
from apps.users.models import User


class BookingTestBase(APITestCase):
    def setUp(self):
        self.client_user = User.objects.create_user(
            phone_number="09111000001", password="x", role="CLIENT", is_active=True
        )
        self.worker_user = User.objects.create_user(
            phone_number="09222000001", password="x", role="TASKER", is_active=True
        )
        self.other_client = User.objects.create_user(
            phone_number="09111000002", password="x", role="CLIENT", is_active=True
        )
        self.other_worker = User.objects.create_user(
            phone_number="09222000002", password="x", role="TASKER", is_active=True
        )

        self.client_token = str(RefreshToken.for_user(self.client_user).access_token)
        self.worker_token = str(RefreshToken.for_user(self.worker_user).access_token)
        self.other_client_token = str(RefreshToken.for_user(self.other_client).access_token)
        self.other_worker_token = str(RefreshToken.for_user(self.other_worker).access_token)

    def _as_client(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.client_token}")

    def _as_worker(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.worker_token}")

    def _as_other_client(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.other_client_token}")

    def _as_other_worker(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.other_worker_token}")

    def _make_booking(self, booking_status=Booking.STATUS_ACCEPTED):
        return Booking.objects.create(
            worker=self.worker_user,
            client=self.client_user,
            status=booking_status,
        )


# ─────────────────────────────────────────────────────────────────────────────
# Worker check-in  →  waiting_client_checkin_confirm
# ─────────────────────────────────────────────────────────────────────────────

class WorkerCheckinTests(BookingTestBase):
    def _url(self, pk):
        return reverse("booking-worker-checkin", args=[pk])

    def test_requires_auth(self):
        b = self._make_booking()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_client_cannot_checkin(self):
        b = self._make_booking()
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_wrong_worker_rejected(self):
        b = self._make_booking()
        self._as_other_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(resp.data["code"], "wrong_worker")

    def test_happy_path_sets_status_and_timestamp(self):
        b = self._make_booking(Booking.STATUS_ACCEPTED)
        self._as_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data["status"], Booking.STATUS_WAITING_CHECKIN_CONFIRM)
        b.refresh_from_db()
        self.assertIsNotNone(b.worker_checkin_at)
        self.assertEqual(b.status, Booking.STATUS_WAITING_CHECKIN_CONFIRM)

    def test_invalid_transition_from_pending(self):
        b = self._make_booking(Booking.STATUS_PENDING)
        self._as_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(resp.data["code"], "invalid_transition")

    def test_invalid_transition_from_in_progress(self):
        b = self._make_booking(Booking.STATUS_IN_PROGRESS)
        self._as_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)

    def test_404_for_unknown_booking(self):
        self._as_worker()
        resp = self.client.post(self._url(99999))
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)


# ─────────────────────────────────────────────────────────────────────────────
# Client confirm check-in  →  in_progress
# ─────────────────────────────────────────────────────────────────────────────

class ClientConfirmCheckinTests(BookingTestBase):
    def _url(self, pk):
        return reverse("booking-client-confirm-checkin", args=[pk])

    def test_worker_cannot_confirm(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKIN_CONFIRM)
        self._as_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_wrong_client_rejected(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKIN_CONFIRM)
        self._as_other_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(resp.data["code"], "wrong_client")

    def test_happy_path(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKIN_CONFIRM)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data["status"], Booking.STATUS_IN_PROGRESS)
        b.refresh_from_db()
        self.assertIsNotNone(b.client_checkin_confirmed_at)

    def test_invalid_transition_from_accepted(self):
        b = self._make_booking(Booking.STATUS_ACCEPTED)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)


# ─────────────────────────────────────────────────────────────────────────────
# Client reject check-in  →  arrival_disputed
# ─────────────────────────────────────────────────────────────────────────────

class ClientRejectCheckinTests(BookingTestBase):
    def _url(self, pk):
        return reverse("booking-client-reject-checkin", args=[pk])

    def test_wrong_client_rejected(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKIN_CONFIRM)
        self._as_other_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_happy_path(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKIN_CONFIRM)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data["status"], Booking.STATUS_ARRIVAL_DISPUTED)
        b.refresh_from_db()
        self.assertEqual(b.status, Booking.STATUS_ARRIVAL_DISPUTED)

    def test_invalid_transition_from_in_progress(self):
        b = self._make_booking(Booking.STATUS_IN_PROGRESS)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)


# ─────────────────────────────────────────────────────────────────────────────
# Worker checkout  →  waiting_client_checkout_confirm
# ─────────────────────────────────────────────────────────────────────────────

class WorkerCheckoutTests(BookingTestBase):
    def _url(self, pk):
        return reverse("booking-worker-checkout", args=[pk])

    def test_client_cannot_checkout(self):
        b = self._make_booking(Booking.STATUS_IN_PROGRESS)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_wrong_worker_rejected(self):
        b = self._make_booking(Booking.STATUS_IN_PROGRESS)
        self._as_other_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_checkout_before_checkin_confirmed(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKIN_CONFIRM)
        self._as_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)

    def test_happy_path(self):
        b = self._make_booking(Booking.STATUS_IN_PROGRESS)
        self._as_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data["status"], Booking.STATUS_WAITING_CHECKOUT_CONFIRM)
        b.refresh_from_db()
        self.assertIsNotNone(b.worker_checkout_at)


# ─────────────────────────────────────────────────────────────────────────────
# Client confirm checkout  →  completed
# ─────────────────────────────────────────────────────────────────────────────

class ClientConfirmCheckoutTests(BookingTestBase):
    def _url(self, pk):
        return reverse("booking-client-confirm-checkout", args=[pk])

    def test_worker_cannot_confirm_checkout(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKOUT_CONFIRM)
        self._as_worker()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_wrong_client_rejected(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKOUT_CONFIRM)
        self._as_other_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_complete_before_checkout(self):
        b = self._make_booking(Booking.STATUS_IN_PROGRESS)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)

    def test_happy_path(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKOUT_CONFIRM)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data["status"], Booking.STATUS_COMPLETED)
        b.refresh_from_db()
        self.assertIsNotNone(b.client_checkout_confirmed_at)
        self.assertEqual(b.status, Booking.STATUS_COMPLETED)


# ─────────────────────────────────────────────────────────────────────────────
# Client report issue  →  completion_disputed
# ─────────────────────────────────────────────────────────────────────────────

class ClientReportCheckoutIssueTests(BookingTestBase):
    def _url(self, pk):
        return reverse("booking-client-report-checkout-issue", args=[pk])

    def test_wrong_client_rejected(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKOUT_CONFIRM)
        self._as_other_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_report_issue_before_checkout(self):
        b = self._make_booking(Booking.STATUS_IN_PROGRESS)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)

    def test_happy_path(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKOUT_CONFIRM)
        self._as_client()
        resp = self.client.post(self._url(b.pk))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data["status"], Booking.STATUS_COMPLETION_DISPUTED)
        b.refresh_from_db()
        self.assertEqual(b.status, Booking.STATUS_COMPLETION_DISPUTED)


# ─────────────────────────────────────────────────────────────────────────────
# Full happy-path end-to-end lifecycle
# ─────────────────────────────────────────────────────────────────────────────

class BookingFullLifecycleTest(BookingTestBase):
    def test_full_checkin_checkout_lifecycle(self):
        b = self._make_booking(Booking.STATUS_ACCEPTED)

        # 1. Worker checks in
        self._as_worker()
        resp = self.client.post(reverse("booking-worker-checkin", args=[b.pk]))
        self.assertEqual(resp.data["status"], Booking.STATUS_WAITING_CHECKIN_CONFIRM)

        # 2. Client confirms check-in
        self._as_client()
        resp = self.client.post(reverse("booking-client-confirm-checkin", args=[b.pk]))
        self.assertEqual(resp.data["status"], Booking.STATUS_IN_PROGRESS)

        # 3. Worker checks out
        self._as_worker()
        resp = self.client.post(reverse("booking-worker-checkout", args=[b.pk]))
        self.assertEqual(resp.data["status"], Booking.STATUS_WAITING_CHECKOUT_CONFIRM)

        # 4. Client confirms checkout → completed
        self._as_client()
        resp = self.client.post(reverse("booking-client-confirm-checkout", args=[b.pk]))
        self.assertEqual(resp.data["status"], Booking.STATUS_COMPLETED)

        b.refresh_from_db()
        self.assertIsNotNone(b.worker_checkin_at)
        self.assertIsNotNone(b.client_checkin_confirmed_at)
        self.assertIsNotNone(b.worker_checkout_at)
        self.assertIsNotNone(b.client_checkout_confirmed_at)

    def test_dispute_arrival_then_resolve(self):
        b = self._make_booking(Booking.STATUS_ACCEPTED)

        # Worker checks in
        self._as_worker()
        self.client.post(reverse("booking-worker-checkin", args=[b.pk]))

        # Client rejects → disputed
        self._as_client()
        resp = self.client.post(reverse("booking-client-reject-checkin", args=[b.pk]))
        self.assertEqual(resp.data["status"], Booking.STATUS_ARRIVAL_DISPUTED)

    def test_dispute_completion(self):
        b = self._make_booking(Booking.STATUS_WAITING_CHECKOUT_CONFIRM)
        self._as_client()
        resp = self.client.post(reverse("booking-client-report-checkout-issue", args=[b.pk]))
        self.assertEqual(resp.data["status"], Booking.STATUS_COMPLETION_DISPUTED)
