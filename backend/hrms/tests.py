from datetime import date

from django.test import SimpleTestCase
from django.core.cache import cache
from rest_framework import serializers
from rest_framework.test import APIRequestFactory
from unittest.mock import Mock, patch

from .serializers import (
    CreateUserSerializer,
    HR_DEPARTMENT_CHOICES,
    TEAM_MEMBER_DEPARTMENT_CHOICES,
    mask_phone_number,
)
from .views import _attendance_credit, _working_dates
from . import views
from .models import User


class PhonePrivacyTests(SimpleTestCase):
    def test_local_mobile_reveals_only_first_two_and_last_digit(self):
        self.assertEqual(mask_phone_number('9524318966'), '95XXXXXXX6')

    def test_country_code_is_preserved_without_exposing_mobile(self):
        self.assertEqual(mask_phone_number('+91 9524318966'), '+91 95XXXXXXX6')

    def test_already_masked_mobile_is_not_changed(self):
        self.assertEqual(mask_phone_number('95XXXXXXX6'), '95XXXXXXX6')


class AttendanceHealthCalculationTests(SimpleTestCase):
    def test_attendance_statuses_receive_expected_credit(self):
        self.assertEqual(_attendance_credit('Present'), 1.0)
        self.assertEqual(_attendance_credit('Late Entry'), 1.0)
        self.assertEqual(_attendance_credit('WFH'), 1.0)
        self.assertEqual(_attendance_credit('Hybrid'), 1.0)
        self.assertEqual(_attendance_credit('Half Day'), 0.5)
        self.assertEqual(_attendance_credit('Absent'), 0.0)
        self.assertEqual(_attendance_credit(''), 0.0)

    def test_working_dates_exclude_weekends(self):
        dates = _working_dates(date(2026, 7, 10), date(2026, 7, 13))

        self.assertEqual(dates, [date(2026, 7, 10), date(2026, 7, 13)])


class CreateUserDepartmentValidationTests(SimpleTestCase):
    def _data(self, role, department=''):
        return {
            'password': 'Password1!',
            'confirm_password': 'Password1!',
            'phone': '9876543210',
            'state': 'Tamil Nadu',
            'city': 'Chennai',
            'role': role,
            'designation': role,
            'occupation': role,
            'department': department,
            'work_mode': 'hybrid',
        }

    def test_valid_state_and_city_are_accepted(self):
        data = CreateUserSerializer().validate(
            self._data('ceo'),
        )

        self.assertEqual(data['state'], 'Tamil Nadu')
        self.assertEqual(data['city'], 'Chennai')

    def test_city_must_belong_to_selected_state(self):
        invalid = self._data('ceo')
        invalid['city'] = 'Mumbai'

        with self.assertRaises(serializers.ValidationError) as context:
            CreateUserSerializer().validate(invalid)

        self.assertIn('city', context.exception.detail)

    def test_unknown_state_is_rejected(self):
        invalid = self._data('ceo')
        invalid['state'] = 'Unknown State'

        with self.assertRaises(serializers.ValidationError) as context:
            CreateUserSerializer().validate(invalid)

        self.assertIn('state', context.exception.detail)

    def test_valid_work_mode_is_accepted(self):
        data = CreateUserSerializer().validate(self._data('ceo'))

        self.assertEqual(data['work_mode'], 'hybrid')

    def test_unknown_work_mode_is_rejected(self):
        invalid = self._data('ceo')
        invalid['work_mode'] = 'field'

        with self.assertRaises(serializers.ValidationError) as context:
            CreateUserSerializer().validate(invalid)

        self.assertIn('work_mode', context.exception.detail)

    def test_department_is_required_for_team_lead(self):
        with self.assertRaises(serializers.ValidationError) as context:
            CreateUserSerializer().validate(self._data('tl'))

        self.assertIn('department', context.exception.detail)

    def test_valid_department_is_accepted_for_team_lead(self):
        data = CreateUserSerializer().validate(
            self._data('tl', 'web_application_development'),
        )

        self.assertEqual(data['department'], 'web_application_development')

    def test_department_is_required_for_it_team(self):
        with self.assertRaises(serializers.ValidationError) as context:
            CreateUserSerializer().validate(self._data('it'))

        self.assertIn('department', context.exception.detail)

    def test_listed_department_is_accepted_for_it_team(self):
        data = CreateUserSerializer().validate(
            self._data('it', 'artificial_intelligence_machine_learning'),
        )

        self.assertEqual(
            data['department'],
            'artificial_intelligence_machine_learning',
        )

    def test_department_is_required_for_hr(self):
        with self.assertRaises(serializers.ValidationError) as context:
            CreateUserSerializer().validate(self._data('hr'))

        self.assertIn('department', context.exception.detail)

    def test_listed_department_is_accepted_for_hr(self):
        data = CreateUserSerializer().validate(
            self._data('hr', 'talent_acquisition_recruitment'),
        )

        self.assertEqual(data['department'], 'talent_acquisition_recruitment')

    def test_it_department_is_not_accepted_for_hr(self):
        with self.assertRaises(serializers.ValidationError) as context:
            CreateUserSerializer().validate(
                self._data('hr', 'web_application_development'),
            )

        self.assertIn('department', context.exception.detail)

    def test_only_the_configured_department_list_is_accepted(self):
        with self.assertRaises(serializers.ValidationError) as context:
            CreateUserSerializer().validate(
                self._data('it', 'unsupported_department'),
            )

        self.assertIn('department', context.exception.detail)

    def test_configured_department_labels_match_member_creation_list(self):
        self.assertEqual(
            [label for _value, label in TEAM_MEMBER_DEPARTMENT_CHOICES],
            [
                'Web Application Development',
                'Mobile Application Development',
                'UI/UX Design',
                'Quality Assurance (QA) and Testing',
                'DevOps and Cloud Engineering',
                'Artificial Intelligence and Machine Learning',
                'Data Science and Analytics',
                'Cybersecurity',
                'IT Infrastructure and Network Support',
                'Technical Support',
                'Project Management',
                'Product Management',
                'Digital Marketing',
                'Sales and Business Development',
                'Human Resources (HR)',
                'Finance and Accounts',
                'Administration and Operations',
                'Management',
                'Research and Development (R&D)',
                'Internship / Trainee',
            ],
        )

    def test_configured_hr_department_labels_match_member_creation_list(self):
        self.assertEqual(
            [label for _value, label in HR_DEPARTMENT_CHOICES],
            [
                'Talent Acquisition / Recruitment',
                'HR Operations',
                'Employee Onboarding and Offboarding',
                'Attendance and Leave Management',
                'Payroll and Compensation',
                'Benefits Administration',
                'Learning and Development (L&D)',
                'Performance Management',
                'Employee Relations',
                'Employee Engagement',
                'HR Compliance and Policies',
                'Workforce Planning',
                'HR Analytics and Reporting',
                'Health, Safety and Well-being',
                'Internship and Campus Recruitment',
            ],
        )

    def test_department_is_derived_from_other_roles(self):
        roles = [
            'ceo', 'md', 'director', 'finance', 'marketing',
            'admin', 'manager', 'employee',
        ]
        for role in roles:
            with self.subTest(role=role):
                data = CreateUserSerializer().validate(self._data(role))
                self.assertEqual(data['department'], role)

    def test_supplied_department_is_replaced_for_non_team_lead(self):
        data = CreateUserSerializer().validate(
            self._data('ceo', 'web_application_development'),
        )

        self.assertEqual(data['department'], 'ceo')


class MeetingScheduleValidationTests(SimpleTestCase):
    def test_tl_cannot_schedule_a_meeting_in_the_past(self):
        request = APIRequestFactory().post(
            '/api/tl/meetings/',
            {
                'title': 'Past meeting',
                'date_label': '01-01-2020',
                'time_label': '09:00 AM',
            },
            format='json',
        )

        with patch.object(views, '_create_meeting_from_payload') as create:
            response = views.tl_meetings_view(request)

        self.assertEqual(response.status_code, 400)
        self.assertIn('future', response.data['message'].lower())
        create.assert_not_called()


class PasswordRecoveryTests(SimpleTestCase):
    def setUp(self):
        cache.clear()
        self.factory = APIRequestFactory()
        self.user = User(
            user_id='BBEMPTEST01',
            email='employee.test@bitbyte.test',
            role='employee',
        )
        self.user.set_password('Current@123')
        self.user.save = Mock()

    def tearDown(self):
        cache.clear()

    def test_cached_recovery_credential_changes_password_once(self):
        cache.set('password_reset:BBEMPTEST01', 'RESET123', timeout=900)
        request = self.factory.post(
            '/api/change-password/',
            {
                'employee_id': 'BBEMPTEST01',
                'otc': 'RESET123',
                'new_password': 'Changed@123',
            },
            format='json',
        )

        with patch.object(views.User.objects, 'get', return_value=self.user), patch.object(
            views.EmployeeAccount.objects,
            'filter',
        ) as accounts:
            accounts.return_value.update.return_value = 1
            response = views.change_password_view(request)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertTrue(self.user.check_password('Changed@123'))
        self.assertIsNone(cache.get('password_reset:BBEMPTEST01'))
        accounts.return_value.update.assert_called_once_with(otc='')

    def test_recovery_credential_cannot_be_reused(self):
        request = self.factory.post(
            '/api/change-password/',
            {
                'employee_id': 'BBEMPTEST01',
                'otc': 'EXPIRED1',
                'new_password': 'Changed@123',
            },
            format='json',
        )

        with patch.object(views.User.objects, 'get', return_value=self.user):
            response = views.change_password_view(request)

        self.assertEqual(response.status_code, 400)
        self.assertFalse(response.data['success'])
