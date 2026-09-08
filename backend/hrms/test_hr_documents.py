import tempfile

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from .models import AuditLog, DocumentRecord, User


class HrDocumentApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.hr = User.objects.create_user(
            'hr.documents@test.local',
            'Password1!',
            role='hr',
        )
        self.employee = User.objects.create_user(
            'employee.documents@test.local',
            'Password1!',
            role='employee',
        )
        self.media = tempfile.TemporaryDirectory()
        self.media_override = override_settings(MEDIA_ROOT=self.media.name)
        self.media_override.enable()

    def tearDown(self):
        self.media_override.disable()
        self.media.cleanup()

    def _upload(self, **overrides):
        payload = {
            'user_id': self.hr.user_id,
            'document_type': 'Employment Contract',
            'owner_user_id': self.employee.user_id,
            'owner_role': 'employee',
            'document_number': 'CONTRACT-001',
            'remarks': 'Signed employment agreement.',
            'file': SimpleUploadedFile(
                'contract.pdf',
                b'%PDF-1.4 test document',
                content_type='application/pdf',
            ),
            **overrides,
        }
        return self.client.post('/api/hr/documents/', payload, format='multipart')

    def test_hr_can_upload_list_review_and_delete_document(self):
        uploaded = self._upload()
        self.assertEqual(uploaded.status_code, 201)
        document_id = uploaded.data['document']['id']
        self.assertEqual(uploaded.data['document']['status'], 'pending')
        self.assertEqual(DocumentRecord.objects.count(), 1)
        self.assertTrue(
            AuditLog.objects.filter(
                module='documents',
                action='document_uploaded',
                reference_id=str(document_id),
            ).exists()
        )

        listed = self.client.get(
            '/api/hr/documents/',
            {'user_id': self.hr.user_id, 'query': 'Contract'},
        )
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.data['counts']['total'], 1)
        self.assertEqual(len(listed.data['documents']), 1)

        reviewed = self.client.patch(
            f'/api/hr/documents/{document_id}/',
            {
                'user_id': self.hr.user_id,
                'status': 'verified',
                'remarks': 'Reviewed by HR.',
            },
            format='json',
        )
        self.assertEqual(reviewed.status_code, 200)
        self.assertEqual(reviewed.data['document']['status'], 'verified')
        record = DocumentRecord.objects.get(pk=document_id)
        self.assertEqual(record.verified_by, self.hr.user_id)
        self.assertIsNotNone(record.verified_at)

        deleted = self.client.delete(
            f'/api/hr/documents/{document_id}/',
            {'user_id': self.hr.user_id},
            format='json',
        )
        self.assertEqual(deleted.status_code, 200)
        self.assertFalse(DocumentRecord.objects.filter(pk=document_id).exists())

    def test_non_hr_user_cannot_manage_documents(self):
        response = self.client.get(
            '/api/hr/documents/',
            {'user_id': self.employee.user_id},
        )
        self.assertEqual(response.status_code, 403)

    def test_upload_rejects_unsupported_files(self):
        response = self._upload(
            file=SimpleUploadedFile(
                'script.exe',
                b'not allowed',
                content_type='application/octet-stream',
            ),
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn('Unsupported file', response.data['message'])
        self.assertEqual(DocumentRecord.objects.count(), 0)
