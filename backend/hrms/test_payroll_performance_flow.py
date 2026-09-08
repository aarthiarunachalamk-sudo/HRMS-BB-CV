from datetime import date
from decimal import Decimal
import tempfile

from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from .models import (
    CompanyLeave,
    AppNotification,
    EmployeeAccount,
    EmployeeAttendanceRecord,
    EmployeeLeaveRequest,
    EmployeePerformance,
    EmployeeRegistration,
    PayrollProcess,
    SalaryStructure,
    User,
)
from .payroll import calculate_employee_payslip
from .employee_views import _notifications_for_employee


class PerformanceLinkedPayrollTests(TestCase):
    def setUp(self):
        self.media = tempfile.TemporaryDirectory()
        self.media_override = override_settings(MEDIA_ROOT=self.media.name)
        self.media_override.enable()
        self.addCleanup(self.media_override.disable)
        self.addCleanup(self.media.cleanup)
        self.client = APIClient()
        registration = EmployeeRegistration.objects.create(
            first_name='Payroll',
            last_name='Employee',
            gender='other',
            dob='1995-01-01',
            mobile='9999999999',
            personal_email='payroll.employee@example.com',
            marital_status='single',
            blood_group='O+',
            nationality='Indian',
            current_city='Chennai',
            current_state='Tamil Nadu',
            permanent_city='Chennai',
            permanent_state='Tamil Nadu',
            emergency_name='Contact',
            emergency_relationship='Friend',
            emergency_contact='8888888888',
            aadhar='123456789012',
            pan='ABCDE1234F',
            qualification='B.E.',
            college='Test College',
            year_of_passing='2017',
            percentage='80',
            account_holder='Payroll Employee',
            bank_name='Test Bank',
            account_number='1234567890',
            ifsc_code='TEST0001234',
            branch_name='Chennai',
            status='approved',
        )
        self.account = EmployeeAccount.objects.create(
            registration=registration,
            employee_id='BBPAY00001',
            employee_email='payroll.employee@bitbyte.com',
            department='mobile_application_development',
            designation='associate',
            date_of_joining=date(2025, 1, 1),
            employment_type='full_time',
        )
        SalaryStructure.objects.create(
            employee_id=self.account.employee_id,
            basic_salary=Decimal('10000'),
            performance_incentive_percent=Decimal('10'),
            tds=0,
            special_allowance=0,
            overtime_rate_per_hour=0,
        )
        EmployeePerformance.objects.create(
            employee_id=self.account.employee_id,
            period='2026-02',
            performance_score=Decimal('4.00'),
            potential_score=Decimal('4.00'),
            status='submitted',
        )

    def _record_all_workdays(self, skip=None, half_day=None):
        current = date(2026, 2, 1)
        while current <= date(2026, 2, 28):
            if current.weekday() < 5 and current != skip:
                EmployeeAttendanceRecord.objects.create(
                    employee_id=self.account.employee_id,
                    attendance_date=current,
                    status='Half Day' if current == half_day else 'Present',
                )
            current = current.fromordinal(current.toordinal() + 1)

    def test_performance_incentive_is_prorated_by_attendance(self):
        half_day = date(2026, 2, 10)
        self._record_all_workdays(half_day=half_day)
        payslip = calculate_employee_payslip(self.account, 2026, 2, 'HR')

        self.assertEqual(payslip.working_days, 20)
        self.assertEqual(payslip.paid_days, Decimal('19.50'))
        self.assertEqual(payslip.lop_days, Decimal('0.50'))
        self.assertEqual(payslip.performance_score, Decimal('4.00'))
        self.assertEqual(payslip.performance_incentive, Decimal('780.00'))
        self.assertEqual(payslip.earnings['Performance Incentive'], '780.00')
        self.assertEqual(payslip.status, 'draft')
        self.assertIsNone(payslip.paid_date)

    def test_lop_is_not_deducted_twice(self):
        missing_day = date(2026, 2, 11)
        self._record_all_workdays(skip=missing_day)
        EmployeeLeaveRequest.objects.create(
            employee_id=self.account.employee_id,
            leave_type='LOP',
            from_date=missing_day,
            to_date=missing_day,
            status='approved',
        )
        payslip = calculate_employee_payslip(self.account, 2026, 2, 'HR')
        self.assertEqual(payslip.lop_days, Decimal('1.00'))

    def test_company_leave_is_excluded_from_working_days(self):
        holiday = date(2026, 2, 16)
        CompanyLeave.objects.create(
            title='Company Holiday',
            from_date=holiday,
            to_date=holiday,
            announced_by='CEO',
        )
        self._record_all_workdays(skip=holiday)
        payslip = calculate_employee_payslip(self.account, 2026, 2, 'HR')
        self.assertEqual(payslip.working_days, 19)
        self.assertEqual(payslip.paid_days, Decimal('19.00'))
        self.assertEqual(payslip.lop_days, Decimal('0.00'))

    def test_hr_process_enforces_validation_then_calculation_then_publish(self):
        self._record_all_workdays()
        start = self.client.post('/api/hr/payroll/process/', {
            'user_id': 'HR001', 'year': 2026, 'month': 2, 'action': 'start',
        }, format='json')
        self.assertEqual(start.status_code, 200)

        validated = self.client.post('/api/hr/payroll/process/', {
            'user_id': 'HR001', 'year': 2026, 'month': 2, 'action': 'validate',
        }, format='json')
        self.assertEqual(validated.status_code, 200)

        calculated = self.client.post('/api/hr/payroll/process/', {
            'user_id': 'HR001', 'year': 2026, 'month': 2, 'action': 'calculate',
        }, format='json')
        self.assertEqual(calculated.status_code, 200)
        self.assertEqual(calculated.data['process']['status'], 'approval')
        self.assertEqual(calculated.data['payslips'][0]['status'], 'Draft')

        published = self.client.post('/api/hr/payroll/process/', {
            'user_id': 'HR001',
            'year': 2026,
            'month': 2,
            'action': 'publish',
            'options': {'email_employees': False},
        }, format='json')
        self.assertEqual(published.status_code, 200)
        self.assertEqual(published.data['process']['status'], 'published')
        self.assertTrue(PayrollProcess.objects.filter(
            year=2026, month=2, status='published',
        ).exists())

    def test_employee_notifications_include_login_and_employee_id_aliases(self):
        login_user = User.objects.create_user(
            'payroll.employee@bitbyte.com',
            'Password1!',
            role='employee',
        )
        notification = AppNotification.objects.create(
            recipient_user_id=login_user.user_id,
            title='Approval Request Approved by CEO',
            message='Your report was approved by CEO.',
            module='approval',
        )

        notifications = _notifications_for_employee(
            self.account.employee_id,
            self.account.employee_email,
        )

        self.assertIn(
            'Approval Request Approved by CEO',
            [item['title'] for item in notifications],
        )
        marked = self.client.post(
            f'/api/notifications/{notification.id}/read/',
            {'user_id': self.account.employee_id, 'role': 'employee'},
            format='json',
        )
        self.assertEqual(marked.status_code, 200)
        notification.refresh_from_db()
        self.assertTrue(notification.is_read)
