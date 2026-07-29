from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (
    AppNotification,
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
        self.assertEqual(CompanyLeave.objects.count(), 1)
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
