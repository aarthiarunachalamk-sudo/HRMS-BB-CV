import json
from unittest.mock import MagicMock, patch

from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from .models import EmployeeRegistration


class IfscVerificationTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

    def test_rejects_format_without_calling_registry(self):
        with patch('hrms.views.urlopen') as lookup:
            response = self.client.get('/api/verify-ifsc/', {'ifsc': 'INVALID'})
        self.assertEqual(response.status_code, 400)
        self.assertFalse(response.data['verified'])
        lookup.assert_not_called()

    def test_health_endpoint_is_available_for_upload_warmup(self):
        response = self.client.get('/api/health/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {'success': True, 'status': 'ready'})

    def test_registration_retry_is_idempotent(self):
        registration = EmployeeRegistration.objects.create(
            submission_key='mobile-retry-1', first_name='Retry', last_name='User',
            gender='other', dob='1995-01-01', mobile='9999999999',
            personal_email='retry@example.com', marital_status='single',
            blood_group='O+', nationality='Indian', current_city='Chennai',
            current_state='Tamil Nadu', permanent_city='Chennai',
            permanent_state='Tamil Nadu', emergency_name='Contact',
            emergency_relationship='Friend', emergency_contact='8888888888',
            aadhar='123456789012', pan='ABCDE1234F', qualification='B.E.',
            college='College', year_of_passing='2020', percentage='80',
            account_holder='Retry User', bank_name='State Bank of India',
            account_number='1234567890', ifsc_code='SBIN0000877',
            branch_name='Chennai',
        )
        response = self.client.post(
            '/api/register-employee/',
            {'submission_key': 'mobile-retry-1'},
            format='multipart',
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertTrue(response.data['duplicate'])
        self.assertEqual(response.data['id'], registration.id)
        self.assertEqual(EmployeeRegistration.objects.count(), 1)

    @patch('hrms.views.urlopen')
    def test_returns_live_registry_bank_and_branch(self, lookup):
        registry_response = MagicMock()
        registry_response.__enter__.return_value = registry_response
        registry_response.read.return_value = json.dumps({
            'IFSC': 'SBIN0000877',
            'BANK': 'State Bank of India',
            'BRANCH': 'Anna Nagar',
            'ADDRESS': 'Chennai',
            'CITY': 'Chennai',
            'STATE': 'Tamil Nadu',
        }).encode()
        lookup.return_value = registry_response

        response = self.client.get('/api/verify-ifsc/', {'ifsc': 'sbin0000877'})

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['verified'])
        self.assertEqual(response.data['ifsc'], 'SBIN0000877')
        self.assertEqual(response.data['branch'], 'Anna Nagar')
        self.assertEqual(response.data['source'], 'Razorpay IFSC Registry')
