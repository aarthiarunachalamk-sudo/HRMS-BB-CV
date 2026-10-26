from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from decimal import Decimal

from hrms.models import (
    User, EmployeeRegistration, EmployeeAccount,
    EmployeeLeaveRequest, AttendanceRegularizationRequest, AppNotification
)


class TLApprovalNotificationsTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create CEO
        self.ceo = User.objects.create_user(
            email='ceo_test@bitbytetech.org',
            password='Password@123',
            role='ceo',
        )
        self.ceo.first_name = 'CEO'
        self.ceo.save()

        # Create PM
        self.pm = User.objects.create_user(
            email='jairamachandran@bitbytetech.org',
            password='JAIPM@2026',
            role='manager',
        )
        self.pm.first_name = 'Jai'
        self.pm.last_name = 'Ramachandran'
        self.pm.department = 'Project Management'
        self.pm.occupation = 'Project Manager'
        self.pm.save()

        # Create TL
        self.tl = User.objects.create_user(
            email='tl_test@bitbytetech.org',
            password='Password@123',
            role='tl',
        )
        self.tl.first_name = 'Team'
        self.tl.last_name = 'Lead'
        self.tl.save()

        # Create Employee
        self.emp = User.objects.create_user(
            email='emp_test@bitbytetech.org',
            password='Password@123',
            role='employee',
        )
        self.emp.first_name = 'Emp'
        self.emp.last_name = 'Test'
        self.emp.save()

        reg = EmployeeRegistration.objects.create(
            first_name='Emp',
            last_name='Test',
            personal_email=self.emp.email,
            status='approved',
        )
        self.account = EmployeeAccount.objects.create(
            user=self.emp,
            registration=reg,
            employee_email=self.emp.email,
            department='web_application_development',
            reporting_tl=self.tl.user_id,
            date_of_joining=timezone.localdate(),
        )

    def test_tl_leave_approval_notifies_ceo_and_pm(self):
        # Create pending leave request
        leave = EmployeeLeaveRequest.objects.create(
            employee_id=self.account.employee_id,
            leave_type='Casual Leave',
            from_date=timezone.localdate(),
            to_date=timezone.localdate(),
            total_days=Decimal('1.00'),
            reason='Need leave',
            status='pending',
            tl_status='pending',
            hr_status='pending',
        )

        # TL approves leave
        response = self.client.post(
            f'/api/tl/leave-requests/{leave.id}/',
            {'status': 'approved', 'reviewed_by': self.tl.user_id},
            format='json',
        )
        self.assertEqual(response.status_code, 200)

        # Check notifications generated for CEO and PM/Manager
        ceo_notifications = AppNotification.objects.filter(
            recipient_role='ceo',
            module='leave',
            reference_id=str(leave.id),
        )
        self.assertTrue(ceo_notifications.exists())
        self.assertIn('Leave Approved by TL', ceo_notifications.first().title)

        pm_notifications = AppNotification.objects.filter(
            recipient_role='pm',
            module='leave',
            reference_id=str(leave.id),
        )
        self.assertTrue(pm_notifications.exists())

        mgr_notifications = AppNotification.objects.filter(
            recipient_role='manager',
            module='leave',
            reference_id=str(leave.id),
        )
        self.assertTrue(mgr_notifications.exists())

    def test_tl_checkout_permission_approval_notifies_ceo_and_pm(self):
        permission = AttendanceRegularizationRequest.objects.create(
            employee_id=self.account.employee_id,
            request_type='early_checkout',
            attendance_date=timezone.localdate(),
            reason='Doctor visit',
            status='pending',
        )

        response = self.client.post(
            f'/api/tl/checkout-permissions/{permission.id}/',
            {'status': 'approved', 'reviewed_by': self.tl.user_id},
            format='json',
        )
        self.assertEqual(response.status_code, 200)

        ceo_notifications = AppNotification.objects.filter(
            recipient_role='ceo',
            module='attendance_permission',
            reference_id=str(permission.id),
        )
        self.assertTrue(ceo_notifications.exists())

        mgr_notifications = AppNotification.objects.filter(
            recipient_role='manager',
            module='attendance_permission',
            reference_id=str(permission.id),
        )
        self.assertTrue(mgr_notifications.exists())

    def test_pm_login_and_credentials(self):
        # Test PM login with loginid-jairamachandran@bitbytetech.org and pswrd-JAIPM@2026
        response = self.client.post(
            '/api/login/',
            {
                'email': 'jairamachandran@bitbytetech.org',
                'password': 'JAIPM@2026',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data.get('success'))
        self.assertEqual(response.data.get('role'), 'manager')
        self.assertEqual(response.data.get('email'), 'jairamachandran@bitbytetech.org')
