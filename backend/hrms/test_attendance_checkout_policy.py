from datetime import datetime, timedelta, timezone as datetime_timezone

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from .management.commands.auto_checkout_attendance import IST, run_auto_checkout
from .models import (
    AttendanceRegularizationRequest,
    EmployeeAttendanceRecord,
    EmployeeLeaveRequest,
)


class AttendanceCheckoutPolicyTests(TestCase):
    employee_id = 'EMP-POLICY-01'

    def setUp(self):
        self.client = APIClient()

    def _open_attendance(self, local_check_in):
        return EmployeeAttendanceRecord.objects.create(
            employee_id=self.employee_id,
            attendance_date=local_check_in.date(),
            check_in=local_check_in.astimezone(datetime_timezone.utc),
            check_in_timezone_offset_minutes=330,
            status='Present',
        )

    def test_checkout_before_530_creates_permission_without_closing_attendance(self):
        local_now = datetime(2026, 7, 27, 17, 0, tzinfo=IST)
        record = self._open_attendance(local_now.replace(hour=9))
        response = self.client.post(
            '/api/employee/check-out/',
            {
                'user_id': self.employee_id,
                'mobile_timestamp': local_now.isoformat(),
                'timezone_offset_minutes': 330,
                'selfie': SimpleUploadedFile('selfie.jpg', b'photo', content_type='image/jpeg'),
            },
            format='multipart',
        )
        self.assertEqual(response.status_code, 202)
        self.assertTrue(response.data['permission_required'])
        record.refresh_from_db()
        self.assertIsNone(record.check_out)
        self.assertTrue(AttendanceRegularizationRequest.objects.filter(
            employee_id=self.employee_id,
            request_type='early_checkout',
            status='pending',
        ).exists())

    def test_approval_does_not_checkout_until_employee_completes_checkout(self):
        local_now = datetime(2026, 7, 27, 17, 0, tzinfo=IST)
        record = self._open_attendance(local_now.replace(hour=9))
        permission = AttendanceRegularizationRequest.objects.create(
            employee_id=self.employee_id,
            attendance_date=local_now.date(),
            request_type='early_checkout',
            requested_check_out=local_now,
            status='pending',
        )
        approval = self.client.post(
            f'/api/hr/checkout-permissions/{permission.id}/',
            {'status': 'approved', 'user_id': 'HR-01'},
            format='json',
        )
        self.assertEqual(approval.status_code, 200)
        record.refresh_from_db()
        self.assertIsNone(record.check_out)

        checkout = self.client.post(
            '/api/employee/check-out/',
            {
                'user_id': self.employee_id,
                'mobile_timestamp': local_now.isoformat(),
                'timezone_offset_minutes': 330,
                'selfie': SimpleUploadedFile(
                    'checkout.jpg',
                    b'photo',
                    content_type='image/jpeg',
                ),
            },
            format='multipart',
        )
        self.assertEqual(checkout.status_code, 200)
        self.assertFalse(checkout.data.get('permission_required', False))
        record.refresh_from_db()
        self.assertIsNotNone(record.check_out)

    def test_normal_attendance_auto_checks_out_at_630_pm(self):
        local_now = datetime(2026, 7, 27, 18, 30, tzinfo=IST)
        record = self._open_attendance(local_now.replace(hour=9, minute=0))
        self.assertEqual(run_auto_checkout(local_now), 1)
        record.refresh_from_db()
        self.assertEqual(record.check_out.astimezone(IST).strftime('%H:%M'), '18:30')

    def test_only_hr_approved_second_half_leave_auto_checks_out_at_1_pm(self):
        local_now = datetime(2026, 7, 27, 13, 0, tzinfo=IST)
        record = self._open_attendance(local_now.replace(hour=9))
        EmployeeLeaveRequest.objects.create(
            employee_id=self.employee_id,
            leave_type='Casual Leave',
            session='Second Half',
            from_date=local_now.date(),
            to_date=local_now.date(),
            status='approved',
            tl_status='approved',
            hr_status='approved',
        )
        self.assertEqual(run_auto_checkout(local_now), 1)
        record.refresh_from_db()
        self.assertEqual(record.check_out.astimezone(IST).strftime('%H:%M'), '13:00')
        self.assertEqual(record.status, 'Half Day')

    def test_pending_half_day_leave_does_not_auto_checkout_at_1_pm(self):
        local_now = datetime(2026, 7, 27, 13, 0, tzinfo=IST)
        record = self._open_attendance(local_now.replace(hour=9))
        EmployeeLeaveRequest.objects.create(
            employee_id=self.employee_id,
            leave_type='Casual Leave',
            session='Second Half',
            from_date=local_now.date(),
            to_date=local_now.date(),
            status='pending',
            tl_status='approved',
            hr_status='pending',
        )
        self.assertEqual(run_auto_checkout(local_now), 0)
        record.refresh_from_db()
        self.assertIsNone(record.check_out)
