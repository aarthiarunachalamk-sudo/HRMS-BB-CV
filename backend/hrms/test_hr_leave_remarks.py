from datetime import timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import AppNotification, EmployeeLeaveRequest


class HrLeaveRemarksTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        today = timezone.localdate()
        self.leave = EmployeeLeaveRequest.objects.create(
            employee_id='EMP-REMARKS-01',
            leave_type='Casual Leave',
            from_date=today + timedelta(days=2),
            to_date=today + timedelta(days=2),
            reason='Family appointment',
            tl_status='approved',
            tl_approved_by='TL-01',
        )

    def test_hr_remarks_are_required(self):
        response = self.client.post(
            f'/api/hr/leave-requests/{self.leave.id}/',
            {
                'status': 'approved',
                'user_id': 'HR-01',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn('remarks', response.data['message'].lower())
        self.leave.refresh_from_db()
        self.assertEqual(self.leave.hr_status, 'pending')

    def test_hr_remarks_are_saved_returned_and_notified(self):
        remarks = 'Approved after checking the leave balance and project plan.'
        response = self.client.post(
            f'/api/hr/leave-requests/{self.leave.id}/',
            {
                'status': 'approved',
                'user_id': 'HR-01',
                'approver_comments': remarks,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.leave.refresh_from_db()
        self.assertEqual(self.leave.approver_comments, remarks)
        self.assertEqual(response.data['leave']['approver_comments'], remarks)
        notification = AppNotification.objects.get(
            recipient_user_id=self.leave.employee_id,
            module='leave',
            reference_id=str(self.leave.id),
        )
        self.assertIn(remarks, notification.message)
