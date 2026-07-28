from datetime import date

from django.test import SimpleTestCase, TestCase
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.cache import cache
from rest_framework import serializers
from rest_framework.test import APIClient, APIRequestFactory
from unittest.mock import Mock, patch

from .serializers import (
    CreateUserSerializer,
    HR_DEPARTMENT_CHOICES,
    TEAM_MEMBER_DEPARTMENT_CHOICES,
    mask_phone_number,
)
from .views import _attendance_credit, _working_dates
from . import views
from .models import AppNotification, User, EmployeeApprovalRequest


class DailyApprovalFlowTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.employee = User.objects.create_user('employee@flow.test', 'Password1!', role='employee')
        self.employee.department = 'web_application_development'
        self.employee.save()
        self.tl = User.objects.create_user('tl@flow.test', 'Password1!', role='tl')
        self.tl.department = 'web_application_development'
        self.tl.save()
        self.ceo = User.objects.create_user('ceo@flow.test', 'Password1!', role='ceo')
        self.md = User.objects.create_user('md@flow.test', 'Password1!', role='md')

    def _submit(self, sender):
        return self.client.post('/api/employee/approvals/', {
            'user_id': sender.user_id,
            'title': 'Morning Report',
            'date': '2026-07-28',
            'session': 'Forenoon',
            'task_details': 'Completed module testing.',
            'expected_result': 'All flows pass.',
            'actual_result': 'All flows pass.',
        }, format='json')

    def test_employee_requires_tl_then_ceo_final_approval(self):
        submitted = self._submit(self.employee)
        self.assertEqual(submitted.status_code, 201)
        approval_id = submitted.data['approval']['id']
        request = EmployeeApprovalRequest.objects.get(pk=approval_id)
        self.assertEqual(request.assigned_tl_user_id, self.tl.user_id)
        self.assertEqual(request.current_stage, 0)

        premature_ceo = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.ceo.user_id, 'action': 'approve',
        }, format='json')
        self.assertEqual(premature_ceo.status_code, 409)

        tl_result = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.tl.user_id, 'action': 'approve', 'comment': 'Reviewed and approved.',
        }, format='json')
        self.assertEqual(tl_result.status_code, 200)
        request.refresh_from_db()
        self.assertEqual(request.current_stage, 1)
        self.assertEqual(request.status, 'requested')

        ceo_result = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.ceo.user_id, 'action': 'approve', 'comment': 'Final approval granted.',
        }, format='json')
        self.assertEqual(ceo_result.status_code, 200)
        request.refresh_from_db()
        self.assertEqual(request.status, 'approved')
        self.assertEqual(request.current_stage, 2)

    def test_tl_sender_cannot_be_assigned_to_self(self):
        second_tl = User.objects.create_user('tl2@flow.test', 'Password1!', role='tl')
        second_tl.department = self.tl.department
        second_tl.save()
        submitted = self._submit(self.tl)
        self.assertEqual(submitted.status_code, 201)
        assigned = submitted.data['approval']['assigned_tl_user_id']
        self.assertNotEqual(assigned, self.tl.user_id)

    def test_tl_must_reply_before_approving_or_rejecting(self):
        submitted = self._submit(self.employee)
        approval_id = submitted.data['approval']['id']
        result = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.tl.user_id, 'action': 'approve',
        }, format='json')
        self.assertEqual(result.status_code, 400)
        self.assertIn('reply is required', result.data['message'])

    def test_any_notified_tl_can_view_reply_and_take_first_action(self):
        other_tl = User.objects.create_user('other-tl@flow.test', 'Password1!', role='tl')
        submitted = self._submit(self.employee)
        approval_id = submitted.data['approval']['id']

        details = self.client.get(
            f'/api/employee/approvals/{approval_id}/action/',
            {'user_id': other_tl.user_id},
        )
        self.assertEqual(details.status_code, 200)
        self.assertEqual(details.data['approval']['id'], approval_id)
        self.assertEqual(details.data['approval']['assigned_tl_user_id'], self.tl.user_id)

        action = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': other_tl.user_id,
            'action': 'approve',
            'comment': 'Reviewed and approved by Selva.',
        }, format='json')
        self.assertEqual(action.status_code, 200)
        approval = EmployeeApprovalRequest.objects.get(pk=approval_id)
        self.assertEqual(approval.current_stage, 1)
        self.assertEqual(approval.decisions[0]['approver'], other_tl.user_id)

        second_action = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.tl.user_id,
            'action': 'reject',
            'comment': 'A second TL decision must not be accepted.',
        }, format='json')
        self.assertEqual(second_action.status_code, 409)

    @patch('hrms.push_notifications.send_mobile_push', return_value=True)
    def test_submission_notifies_tl_md_and_ceo_in_app_and_by_push(self, push):
        submitted = self._submit(self.employee)
        self.assertEqual(submitted.status_code, 201)
        approval_id = str(submitted.data['approval']['id'])
        notifications = AppNotification.objects.filter(
            module='approval', reference_id=approval_id,
        )
        self.assertTrue(notifications.filter(recipient_role='tl').exists())
        self.assertTrue(notifications.filter(recipient_role='md').exists())
        self.assertTrue(notifications.filter(recipient_role='ceo').exists())
        self.assertEqual(notifications.filter(push_sent=True).count(), 3)
        self.assertEqual(push.call_count, 3)

        tl_dashboard = self.client.get('/api/tl/dashboard/', {'user_id': self.tl.user_id})
        self.assertEqual(tl_dashboard.status_code, 200)
        self.assertTrue(any(
            item.get('module') == 'approval'
            for item in tl_dashboard.data['notifications']
        ))
        self.assertTrue(any(
            item.get('id') == int(approval_id)
            for item in tl_dashboard.data['approvals']
        ))
        self.assertGreaterEqual(tl_dashboard.data['pending_approvals'], 1)

        ceo_dashboard = self.client.get('/api/ceo/home/', {'user_id': self.ceo.user_id})
        self.assertTrue(any(
            item.get('module') == 'approval'
            for item in ceo_dashboard.data['notifications']
        ))

        md_dashboard = self.client.get('/api/md/dashboard/', {'user_id': self.md.user_id})
        self.assertTrue(any(
            item.get('module') == 'approval'
            for item in md_dashboard.data['notifications']
        ))
        md_alerts = self.client.get('/api/md/modules/critical-alerts/', {
            'user_id': self.md.user_id,
        })
        self.assertTrue(any(
            item.get('module') == 'approval'
            for item in md_alerts.data['items']
        ))

    @patch('hrms.push_notifications.send_mobile_push', return_value=True)
    def test_tl_approval_notifies_ceo_for_action_and_md_of_progress(self, push):
        submitted = self._submit(self.employee)
        approval_id = submitted.data['approval']['id']
        AppNotification.objects.all().delete()
        push.reset_mock()

        result = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.tl.user_id, 'action': 'approve', 'comment': 'Good progress.',
        }, format='json')

        self.assertEqual(result.status_code, 200)
        notifications = AppNotification.objects.filter(reference_id=str(approval_id))
        self.assertTrue(notifications.filter(
            recipient_role='ceo', title='Daily Report Final Approval', push_sent=True,
        ).exists())
        self.assertTrue(notifications.filter(
            recipient_role='md', title='Daily Report Passed Team Lead Review', push_sent=True,
        ).exists())
        self.assertTrue(notifications.filter(
            recipient_user_id=self.employee.user_id,
            title='Daily Report Approved by Team Lead',
            push_sent=True,
        ).exists())
        self.assertEqual(push.call_count, 3)

    @patch('hrms.push_notifications.send_mobile_push', return_value=True)
    def test_ceo_final_action_notifies_employee_and_tl(self, push):
        submitted = self._submit(self.employee)
        approval_id = submitted.data['approval']['id']
        self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.tl.user_id, 'action': 'approve', 'comment': 'Approved for CEO review.',
        }, format='json')
        AppNotification.objects.all().delete()
        push.reset_mock()

        result = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.ceo.user_id, 'action': 'approve', 'comment': 'Approved by CEO.',
        }, format='json')

        self.assertEqual(result.status_code, 200)
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=self.employee.user_id,
            title='Approval Request Approved by CEO',
            push_sent=True,
        ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='ceo', title='Daily Report Approved', push_sent=True,
        ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='md', title='Daily Report Approved', push_sent=True,
        ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='tl', title='Daily Report Approved', push_sent=True,
        ).exists())
        self.assertEqual(push.call_count, 4)

    @patch('hrms.push_notifications.send_mobile_push', return_value=True)
    def test_ceo_final_rejection_notifies_employee_and_tl(self, push):
        submitted = self._submit(self.employee)
        approval_id = submitted.data['approval']['id']
        self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.tl.user_id,
            'action': 'approve',
            'comment': 'Approved for CEO review.',
        }, format='json')
        AppNotification.objects.all().delete()
        push.reset_mock()

        result = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.ceo.user_id,
            'action': 'reject',
            'comment': 'Please revise and resubmit.',
        }, format='json')

        self.assertEqual(result.status_code, 200)
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=self.employee.user_id,
            title='Approval Request Rejected by CEO',
            push_sent=True,
        ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='tl', title='Daily Report Rejected', push_sent=True,
        ).exists())
        self.assertEqual(push.call_count, 4)

    def test_ceo_must_reply_before_final_decision(self):
        submitted = self._submit(self.employee)
        approval_id = submitted.data['approval']['id']
        self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.tl.user_id,
            'action': 'approve',
            'comment': 'TL review completed.',
        }, format='json')

        result = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.ceo.user_id,
            'action': 'approve',
        }, format='json')
        self.assertEqual(result.status_code, 400)
        self.assertIn('CEO reply is required', result.data['message'])

    @patch('hrms.push_notifications.send_mobile_push', return_value=True)
    def test_tl_rejection_notifies_ceo_and_md(self, push):
        submitted = self._submit(self.employee)
        approval_id = submitted.data['approval']['id']
        AppNotification.objects.all().delete()
        push.reset_mock()

        result = self.client.post(f'/api/employee/approvals/{approval_id}/action/', {
            'user_id': self.tl.user_id, 'action': 'reject', 'comment': 'Needs revision',
        }, format='json')

        self.assertEqual(result.status_code, 200)
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='ceo', title='Daily Report Rejected', push_sent=True,
        ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='md', title='Daily Report Rejected', push_sent=True,
        ).exists())

    def test_shared_notification_api_includes_and_reads_role_notifications(self):
        notification = AppNotification.objects.create(
            recipient_role='ceo', title='Final approval required',
            message='A report is ready.', module='approval', reference_id='123',
        )

        listed = self.client.get('/api/notifications/', {'user_id': self.ceo.user_id})
        self.assertEqual(listed.status_code, 200)
        self.assertIn(notification.id, [item['id'] for item in listed.data['notifications']])

        marked = self.client.post(f'/api/notifications/{notification.id}/read/', {
            'user_id': self.ceo.user_id,
        }, format='json')
        self.assertEqual(marked.status_code, 200)
        notification.refresh_from_db()
        self.assertTrue(notification.is_read)

    @patch('hrms.push_notifications.send_mobile_push', return_value=True)
    def test_employee_can_submit_social_media_post_for_tl_ceo_flow(self, push):
        submitted = self.client.post('/api/employee/approvals/', {
            'user_id': self.employee.user_id,
            'request_type': 'social_media_post',
            'title': 'Product launch post',
            'date': '2026-07-30',
            'platforms': '["Instagram", "LinkedIn"]',
            'posted_by': 'Employee Name',
            'scheduled_post': 'Yes',
            'attachment': SimpleUploadedFile('post.jpg', b'fake-image', content_type='image/jpeg'),
        }, format='multipart')

        self.assertEqual(submitted.status_code, 201)
        approval = EmployeeApprovalRequest.objects.get(pk=submitted.data['approval']['id'])
        self.assertEqual(approval.request_type, 'social_media_post')
        self.assertEqual(approval.platforms, ['Instagram', 'LinkedIn'])
        self.assertEqual(approval.posted_by, 'Employee Name')
        self.assertEqual(approval.scheduled_post, 'Yes')
        self.assertTrue(bool(approval.attachment))
        self.assertEqual(approval.current_stage, 0)
        recipients = set(AppNotification.objects.filter(
            reference_id=str(approval.id), module='approval',
        ).values_list('recipient_role', flat=True))
        self.assertTrue({'tl', 'ceo', 'md'}.issubset(recipients))
        self.assertEqual(push.call_count, 3)

    @patch('hrms.push_notifications.send_mobile_push', return_value=True)
    def test_employee_can_submit_leave_request_for_tl_ceo_flow(self, push):
        submitted = self.client.post('/api/employee/approvals/', {
            'user_id': self.employee.user_id,
            'request_type': 'leave_request',
            'title': 'Family event leave',
            'leave_type': 'Casual Leave',
            'task_details': 'Attending a family event.',
            'date': '2026-08-03',
            'leave_end_date': '2026-08-05',
            'attachment': SimpleUploadedFile('proof.jpg', b'fake-image', content_type='image/jpeg'),
        }, format='multipart')

        self.assertEqual(submitted.status_code, 201)
        approval = EmployeeApprovalRequest.objects.get(pk=submitted.data['approval']['id'])
        self.assertEqual(approval.request_type, 'leave_request')
        self.assertEqual(approval.leave_type, 'Casual Leave')
        self.assertEqual(str(approval.request_date), '2026-08-03')
        self.assertEqual(str(approval.leave_end_date), '2026-08-05')
        self.assertTrue(bool(approval.attachment))
        self.assertEqual(approval.current_stage, 0)
        recipients = set(AppNotification.objects.filter(
            reference_id=str(approval.id), module='approval',
        ).values_list('recipient_role', flat=True))
        self.assertTrue({'tl', 'ceo', 'md'}.issubset(recipients))
        self.assertEqual(push.call_count, 3)

    def test_leave_request_rejects_end_date_before_start_date(self):
        submitted = self.client.post('/api/employee/approvals/', {
            'user_id': self.employee.user_id,
            'request_type': 'leave_request',
            'title': 'Invalid leave dates',
            'leave_type': 'Casual Leave',
            'task_details': 'Invalid range.',
            'date': '2026-08-05',
            'leave_end_date': '2026-08-03',
            'attachment': SimpleUploadedFile('proof.jpg', b'fake-image', content_type='image/jpeg'),
        }, format='multipart')

        self.assertEqual(submitted.status_code, 400)
        self.assertIn('cannot be before', submitted.data['message'])


class PhonePrivacyTests(SimpleTestCase):
    def test_local_mobile_reveals_only_first_two_and_last_digit(self):
        self.assertEqual(mask_phone_number('9524318966'), '95XXXXXXX6')

    def test_country_code_is_preserved_without_exposing_mobile(self):
        self.assertEqual(mask_phone_number('+91 9524318966'), '+91 95XXXXXXX6')

    def test_already_masked_mobile_is_not_changed(self):
        self.assertEqual(mask_phone_number('95XXXXXXX6'), '95XXXXXXX6')


class SharedAdminEmailLoginTests(SimpleTestCase):
    def setUp(self):
        self.factory = APIRequestFactory()

    def _user(self, user_id, password_matches):
        user = Mock(
            user_id=user_id,
            email='office@bitbyte.test',
            role='admin',
            first_name=user_id,
        )
        user.check_password.return_value = password_matches
        return user

    def test_password_selects_one_admin_from_shared_email(self):
        request = self.factory.post(
            '/api/login/',
            {'email': 'office@bitbyte.test', 'password': 'AdminTwo@123'},
            format='json',
        )
        users = [self._user('BBADM0001', False), self._user('BBADM0002', True)]

        with patch.object(views.User.objects, 'filter', return_value=users), patch.object(
            views.EmployeeAccount.objects,
            'get',
            side_effect=views.EmployeeAccount.DoesNotExist,
        ), patch.object(views, 'ensure_leadership_employee_account', return_value=None):
            response = views.login_view(request)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['user_id'], 'BBADM0002')

    def test_same_email_and_password_requires_user_id(self):
        request = self.factory.post(
            '/api/login/',
            {'email': 'office@bitbyte.test', 'password': 'Shared@123'},
            format='json',
        )
        users = [self._user('BBADM0001', True), self._user('BBADM0002', True)]

        with patch.object(views.User.objects, 'filter', return_value=users):
            response = views.login_view(request)

        self.assertEqual(response.status_code, 409)
        self.assertIn('user ID', response.data['message'])


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
                self.assertEqual(
                    data['department'],
                    'management' if role == 'admin' else role,
                )

    def test_supplied_department_is_replaced_for_non_team_lead(self):
        data = CreateUserSerializer().validate(
            self._data('ceo', 'web_application_development'),
        )

        self.assertEqual(data['department'], 'ceo')

    def test_admin_is_assigned_to_management_department(self):
        data = CreateUserSerializer().validate(self._data('admin'))

        self.assertEqual(data['department'], 'management')


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


class ExecutiveDirectorAccessTests(SimpleTestCase):
    def setUp(self):
        self.factory = APIRequestFactory()

    def test_inactive_director_cannot_open_dashboard(self):
        request = self.factory.get(
            '/api/director/dashboard/',
            {'user_id': 'BBDIR0001'},
        )

        with patch.object(views.User.objects, 'filter') as users:
            users.return_value.exists.return_value = False
            response = views.md_dashboard_view(request)

        self.assertEqual(response.status_code, 403)
        self.assertIn('Executive Director', response.data['message'])

    def test_inactive_director_cannot_schedule_meeting(self):
        request = self.factory.post(
            '/api/director/meetings/',
            {'created_by': 'BBDIR0001'},
            format='json',
        )

        with patch.object(views.User.objects, 'filter') as users:
            users.return_value.exists.return_value = False
            response = views.md_meetings_view(request)

        self.assertEqual(response.status_code, 403)
        self.assertIn('Executive Director', response.data['message'])


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
