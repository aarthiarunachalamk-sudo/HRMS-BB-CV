from datetime import date
from io import BytesIO
from tempfile import TemporaryDirectory
from unittest.mock import patch

from PIL import Image
from cloudinary import CloudinaryResource
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.test.utils import override_settings
from rest_framework.test import APIClient

from .models import EmployeeAccount, EmployeeRegistration, User


class ProfilePhotoFlowTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.media_directory = TemporaryDirectory()
        self.media_override = override_settings(MEDIA_ROOT=self.media_directory.name)
        self.media_override.enable()
        self.addCleanup(self.media_override.disable)
        self.addCleanup(self.media_directory.cleanup)
        self.user = User.objects.create_user(
            'profile.employee@test.local',
            'Password1!',
            role='employee',
        )
        self.user.user_id = 'AUTH-PROFILE-01'
        self.user.save(update_fields=['user_id'])
        registration = EmployeeRegistration.objects.create(
            first_name='Profile',
            last_name='Employee',
            gender='other',
            dob='1995-01-01',
            mobile='9000000099',
            personal_email=self.user.email,
            marital_status='single',
            blood_group='O+',
            nationality='Indian',
            current_city='Salem',
            current_state='Tamil Nadu',
            permanent_city='Salem',
            permanent_state='Tamil Nadu',
            emergency_name='Contact',
            emergency_relationship='Friend',
            emergency_contact='8000000099',
            aadhar='123456789099',
            pan='ABCDE0099F',
            qualification='B.E.',
            college='Test College',
            year_of_passing='2020',
            percentage='80',
            account_holder='Profile Employee',
            bank_name='Test Bank',
            account_number='123456789099',
            ifsc_code='TEST0001234',
            branch_name='Salem',
            status='approved',
        )
        EmployeeAccount.objects.create(
            registration=registration,
            user=self.user,
            employee_id='BBEMP00999',
            employee_email=self.user.email,
            department='mobile_application_development',
            designation='associate',
            date_of_joining=date(2026, 1, 1),
            employment_type='full_time',
        )

    def test_profile_load_accepts_employee_id_for_linked_login_user(self):
        response = self.client.get(
            '/api/profile/',
            {'user_id': 'BBEMP00999'},
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertEqual(response.data['profile']['user_id'], self.user.user_id)
        self.assertEqual(response.data['profile']['email'], self.user.email)

    @patch('cloudinary.uploader.upload_resource')
    def test_profile_photo_upload_accepts_employee_id_and_refreshes_url(
        self,
        upload_resource,
    ):
        upload_resource.return_value = CloudinaryResource(
            public_id='profiles/auth-profile-01',
            format='jpg',
            version=1,
            resource_type='image',
            type='upload',
        )
        image_bytes = BytesIO()
        Image.new('RGB', (120, 120), color=(24, 112, 220)).save(
            image_bytes,
            format='JPEG',
        )
        upload = SimpleUploadedFile(
            'profile.jpg',
            image_bytes.getvalue(),
            content_type='image/jpeg',
        )
        response = self.client.post(
            '/api/profile/photo/',
            {'user_id': 'BBEMP00999', 'profile_photo': upload},
            format='multipart',
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertTrue(response.data['profile_photo_url'])

        self.user.refresh_from_db()
        self.assertTrue(self.user.profile_photo)
        refreshed = self.client.get(
            '/api/profile/',
            {'user_id': 'BBEMP00999'},
        )
        self.assertEqual(refreshed.status_code, 200)
        self.assertEqual(
            refreshed.data['profile']['profile_photo_url'],
            response.data['profile_photo_url'],
        )

    @patch('cloudinary.uploader.upload_resource')
    def test_profile_photo_returns_clean_error_when_storage_is_unavailable(
        self,
        upload_resource,
    ):
        upload_resource.side_effect = RuntimeError('storage offline')
        image_bytes = BytesIO()
        Image.new('RGB', (40, 40), color=(10, 20, 30)).save(
            image_bytes,
            format='JPEG',
        )
        response = self.client.post(
            '/api/profile/photo/',
            {
                'user_id': 'BBEMP00999',
                'profile_photo': SimpleUploadedFile(
                    'profile.jpg',
                    image_bytes.getvalue(),
                    content_type='image/jpeg',
                ),
            },
            format='multipart',
        )
        self.assertEqual(response.status_code, 503)
        self.assertFalse(response.data['success'])
        self.assertIn('storage is temporarily unavailable', response.data['message'])
