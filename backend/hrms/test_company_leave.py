from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (
    Announcement,
    AppNotification,
    AuditLog,
    CompanyLeave,
    EmployeeLeaveRequest,
    User,
)


class CompanyLeaveTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.ceo = User.objects.create_user(
            'ceo-company-leave@example.com', 'secret', role='ceo'
        )
        self.employee = User.objects.create_user(
            'employee-company-leave@example.com', 'secret', role='employee'
        )
        self.inactive_employee = User.objects.create_user(
            'inactive-company-leave@example.com',
            'secret',
            role='employee',
        )
        self.inactive_employee.is_active = False
        self.inactive_employee.save(update_fields=['is_active'])

    def test_ceo_company_leave_is_not_personal_leave_and_notifies_dashboards(self):
        today = timezone.localdate()
        response = self.client.post(
            '/api/ceo/company-leaves/',
            {
                'user_id': self.ceo.user_id,
                'title': 'Emergency Company Closure',
                'message': 'Office will remain closed.',
                'from_date': today.isoformat(),
                'to_date': today.isoformat(),
            },
            format='json',
        )
        self.assertEqual(response.status_code, 201)
        self.assertGreaterEqual(response.data['notified_to'], 1)
        self.assertEqual(CompanyLeave.objects.count(), 1)
        self.assertEqual(Announcement.objects.filter(status='published').count(), 1)
        self.assertEqual(EmployeeLeaveRequest.objects.count(), 0)
        for role in ('admin', 'tl', 'hr', 'md', 'director'):
            self.assertTrue(AppNotification.objects.filter(
                recipient_role=role,
                module='company_leave',
            ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=self.employee.user_id,
            module='company_leave',
        ).exists())
        self.assertFalse(AppNotification.objects.filter(
            recipient_user_id=self.inactive_employee.user_id,
            module='company_leave',
        ).exists())
        self.assertTrue(AuditLog.objects.filter(
            actor_user_id=self.ceo.user_id,
            action='company_leave_published',
            module='company_leave',
        ).exists())

        dashboard = self.client.get(
            '/api/employee/dashboard/',
            {'user_id': self.employee.user_id},
        )
        self.assertEqual(dashboard.status_code, 200)
        self.assertEqual(
            dashboard.data['data']['attendance']['status'],
            'Company Leave',
        )
        self.assertEqual(
            dashboard.data['data']['leave_balances']['used_this_year'],
            0,
        )
        leave_history = self.client.get(
            '/api/employee/leave-history/',
            {
                'user_id': self.employee.user_id,
                'from_date': today.isoformat(),
                'to_date': today.isoformat(),
            },
        )
        self.assertEqual(leave_history.status_code, 200)
        self.assertEqual(leave_history.data['records'][0]['leave_type'], 'Company Leave')
        self.assertFalse(leave_history.data['records'][0]['personal_leave'])
        self.assertEqual(leave_history.data['leave_balances']['used_this_year'], 0)

    def test_company_leave_requires_message_and_non_overlapping_dates(self):
        today = timezone.localdate()
        missing_message = self.client.post(
            '/api/ceo/company-leaves/',
            {
                'user_id': self.ceo.user_id,
                'title': 'Incomplete update',
                'from_date': today.isoformat(),
                'to_date': today.isoformat(),
            },
            format='json',
        )
        self.assertEqual(missing_message.status_code, 400)

        CompanyLeave.objects.create(
            title='Existing company leave',
            message='Already published.',
            from_date=today,
            to_date=today,
            announced_by=self.ceo.user_id,
        )
        overlap = self.client.post(
            '/api/ceo/company-leaves/',
            {
                'user_id': self.ceo.user_id,
                'title': 'Overlapping update',
                'message': 'This should be rejected.',
                'from_date': today.isoformat(),
                'to_date': today.isoformat(),
            },
            format='json',
        )
        self.assertEqual(overlap.status_code, 409)
