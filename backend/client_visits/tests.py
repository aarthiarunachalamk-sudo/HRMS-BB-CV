from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APITestCase

from hrms.models import User
from .models import ClientVisit, VisitAttachment


class ClientVisitApiTests(APITestCase):
    def setUp(self):
        self.employee = User.objects.create_user('employee@example.com', role='employee')
        self.manager = User.objects.create_user('manager@example.com', role='manager')

    def _create(self):
        return self.client.post('/api/client-visits/', {
            'user_id': self.employee.user_id,
            'manager_user_id': self.manager.user_id,
            'client_name': 'ABC Solutions',
            'contact_person': 'Rohit Sharma',
            'contact_phone': '9876543210',
            'address': 'Tech Park, Chennai',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '10:30',
            'purpose': 'Project discussion',
            'submit': True,
        }, format='json')

    def test_visit_follows_approval_check_in_and_completion_workflow(self):
        created = self._create()
        self.assertEqual(created.status_code, 201)
        visit_id = created.data['visit']['id']
        self.assertEqual(created.data['visit']['status'], 'pending')

        approved = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': self.manager.user_id, 'action': 'approve', 'comment': 'Proceed.',
        }, format='json')
        self.assertEqual(approved.status_code, 200)
        self.assertEqual(approved.data['visit']['status'], 'approved')

        checked_in = self.client.post(f'/api/client-visits/{visit_id}/check-in/', {
            'user_id': self.employee.user_id, 'latitude': 13.0827, 'longitude': 80.2707,
        }, format='json')
        self.assertEqual(checked_in.status_code, 200)
        self.assertEqual(checked_in.data['visit']['status'], 'in_progress')

        completed = self.client.post(f'/api/client-visits/{visit_id}/complete/', {
            'user_id': self.employee.user_id, 'latitude': 13.0828, 'longitude': 80.2708,
            'outcome': 'Client approved the proposal.', 'follow_up': 'Send quotation.',
        }, format='json')
        self.assertEqual(completed.status_code, 200)
        self.assertEqual(completed.data['visit']['status'], 'completed')

    @patch('client_visits.views.cloudinary.uploader.upload')
    def test_each_attachment_category_uses_a_separate_cloudinary_folder(self, upload):
        visit_id = self._create().data['visit']['id']
        visit = ClientVisit.objects.get(pk=visit_id)
        upload.side_effect = [
            {'secure_url': 'https://res.cloudinary.com/test/check-in.jpg', 'public_id': 'check-in', 'resource_type': 'image'},
            {'secure_url': 'https://res.cloudinary.com/test/proof.jpg', 'public_id': 'proof', 'resource_type': 'image'},
        ]
        for category in ('check_in', 'proof'):
            response = self.client.post(f'/api/client-visits/{visit_id}/attachments/', {
                'user_id': self.employee.user_id, 'category': category,
                'files': SimpleUploadedFile(f'{category}.jpg', b'image-bytes', content_type='image/jpeg'),
            }, format='multipart')
            self.assertEqual(response.status_code, 201)

        folders = [call.kwargs['folder'] for call in upload.call_args_list]
        self.assertEqual(folders, [
            f'hrms/client_visits/{visit.visit_id}/check_in',
            f'hrms/client_visits/{visit.visit_id}/proof',
        ])
        self.assertEqual(VisitAttachment.objects.filter(visit=visit).count(), 2)

    def test_unassigned_manager_cannot_review_visit(self):
        visit_id = self._create().data['visit']['id']
        other = User.objects.create_user('other-manager@example.com', role='manager')
        response = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': other.user_id, 'action': 'approve',
        }, format='json')
        self.assertEqual(response.status_code, 403)
