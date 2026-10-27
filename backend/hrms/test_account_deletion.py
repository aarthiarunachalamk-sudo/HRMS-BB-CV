from datetime import date
from django.test import TestCase
from rest_framework.test import APIClient
from hrms.models import User, EmployeeRegistration, EmployeeAccount, AccountDeletionRequest, AuditLog


class AccountDeletionTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.password = 'Secret@123'
        self.employee = User.objects.create_user(
            email='testemp@bitbytetech.org',
            password=self.password,
            role='employee',
        )
        self.employee.first_name = 'Test'
        self.employee.last_name = 'Employee'
        self.employee.phone = '9876543210'
        self.employee.save()

        self.reg = EmployeeRegistration.objects.create(
            first_name='Test',
            last_name='Employee',
            gender='male',
            dob='2000-01-01',
            mobile='9876543210',
            personal_email='testemp@bitbytetech.org',
            marital_status='single',
            blood_group='O+',
            nationality='Indian',
            current_city='Chennai',
            permanent_city='Chennai',
        )

        self.employee_acc = EmployeeAccount.objects.create(
            registration=self.reg,
            user=self.employee,
            employee_email=self.employee.email,
            department='web_application_development',
            designation='associate',
            date_of_joining=date(2026, 1, 1),
            employment_type='full_time',
            is_active=True,
        )

        self.admin_user = User.objects.create_user(
            email='admin@bitbytetech.org',
            password=self.password,
            role='admin',
        )
        self.admin_user.first_name = 'Admin'
        self.admin_user.save()

    def test_get_status_when_empty(self):
        self.client.force_authenticate(user=self.employee)
        response = self.client.get('/api/account/delete-request/')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertFalse(response.data['has_active_request'])
        self.assertIsNone(response.data['request'])

    def test_post_wrong_password_fails(self):
        self.client.force_authenticate(user=self.employee)
        response = self.client.post('/api/account/delete-request/', {
            'password': 'WrongPassword!',
            'reason': 'Privacy concerns',
        }, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertFalse(response.data['success'])
        self.assertIn('Incorrect password', response.data['message'])

    def test_post_valid_request_creates_record(self):
        self.client.force_authenticate(user=self.employee)
        response = self.client.post('/api/account/delete-request/', {
            'password': self.password,
            'reason': 'I left the organization',
            'details': 'Relocated abroad',
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data['success'])
        req_data = response.data['request']
        self.assertTrue(req_data['request_id'].startswith('DEL-'))
        self.assertEqual(req_data['status'], 'PENDING')
        self.assertEqual(req_data['reason'], 'I left the organization')

        # Check DB record
        db_req = AccountDeletionRequest.objects.get(user=self.employee)
        self.assertEqual(db_req.status, 'PENDING')

    def test_prevent_duplicate_pending_request(self):
        self.client.force_authenticate(user=self.employee)
        # First submission
        self.client.post('/api/account/delete-request/', {
            'password': self.password,
            'reason': 'Duplicate account',
        }, format='json')

        # Second submission
        response = self.client.post('/api/account/delete-request/', {
            'password': self.password,
            'reason': 'Duplicate account',
        }, format='json')
        self.assertEqual(response.status_code, 409)
        self.assertFalse(response.data['success'])

    def test_cancel_request(self):
        self.client.force_authenticate(user=self.employee)
        self.client.post('/api/account/delete-request/', {
            'password': self.password,
            'reason': 'Other',
        }, format='json')

        response = self.client.post('/api/account/delete-request/cancel/')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertEqual(response.data['request']['status'], 'CANCELLED')

    def test_admin_list_and_action_flow(self):
        # Create a deletion request from employee
        self.client.force_authenticate(user=self.employee)
        res = self.client.post('/api/account/delete-request/', {
            'password': self.password,
            'reason': 'Privacy concerns',
        }, format='json')
        req_id = res.data['request']['id']

        # Admin lists requests
        self.client.force_authenticate(user=self.admin_user)
        list_res = self.client.get('/api/account/delete-requests/')
        self.assertEqual(list_res.status_code, 200)
        self.assertEqual(list_res.data['counts']['pending'], 1)
        self.assertEqual(len(list_res.data['requests']), 1)

        # Admin marks Under Review
        act_res = self.client.post(f'/api/account/delete-requests/{req_id}/action/', {
            'action': 'under_review',
            'remarks': 'Reviewing employee handover status',
        }, format='json')
        self.assertEqual(act_res.status_code, 200)
        self.assertEqual(act_res.data['request']['status'], 'UNDER_REVIEW')

        # Admin completes deletion
        complete_res = self.client.post(f'/api/account/delete-requests/{req_id}/action/', {
            'action': 'complete',
            'remarks': 'Handover complete. Account deactivated.',
        }, format='json')
        self.assertEqual(complete_res.status_code, 200)
        self.assertEqual(complete_res.data['request']['status'], 'COMPLETED')

        # Verify user is deactivated
        self.employee.refresh_from_db()
        self.assertFalse(self.employee.is_active)
        self.employee_acc.refresh_from_db()
        self.assertFalse(self.employee_acc.is_active)

    def test_public_web_page_get(self):
        # Public webpage must be accessible without login
        response = self.client.get('/account-deletion/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('Bit Byte – HRMS Account Deletion'.encode('utf-8'), response.content)
        self.assertIn(b'Data that may be deleted', response.content)
        self.assertIn(b'Data that may be retained', response.content)
        self.assertIn(b'Profile &rarr; Settings &rarr; Account &rarr; Delete Account', response.content)
        self.assertIn(b'Certain records may be retained where required', response.content)

    def test_public_web_page_post_creates_request(self):
        response = self.client.post('/account-deletion/', {
            'employee_id': self.employee.user_id,
            'email': self.employee.email,
            'mobile_number': '9876543210',
            'reason': 'Privacy concerns',
            'confirm': 'yes',
        })
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Your account deletion request has been submitted successfully', response.content)

        db_req = AccountDeletionRequest.objects.filter(user=self.employee).first()
        self.assertIsNotNone(db_req)
        self.assertEqual(db_req.status, 'PENDING')
        self.assertEqual(db_req.reason, 'Privacy concerns')

