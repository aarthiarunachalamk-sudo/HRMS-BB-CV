from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from rest_framework.test import APITestCase

from hrms.models import AppNotification, User
from .models import ClientVisit, VisitAttachment


@override_settings(CLIENT_VISIT_CLOUDINARY_STORAGE={
    'cloud_name': 'client-visits-test-cloud',
    'api_key': 'client-visits-test-key',
    'api_secret': 'client-visits-test-secret',
    'folder': 'hrms-client-visits',
})
class ClientVisitApiTests(APITestCase):
    def setUp(self):
        self.employee = User.objects.create_user('employee@example.com', role='employee')
        self.manager = User.objects.create_user('tl@example.com', role='tl')

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
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=self.manager.user_id,
            module='client_visit',
            reference_id=str(visit_id),
        ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='ceo',
            title='New Client Visit Request',
            reference_id=str(visit_id),
        ).exists())

        approved = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': self.manager.user_id, 'action': 'approve', 'comment': 'Proceed.',
        }, format='json')
        self.assertEqual(approved.status_code, 200)
        self.assertEqual(approved.data['visit']['status'], 'approved')
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=self.employee.user_id,
            title='Client Visit Approved',
            reference_id=str(visit_id),
        ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='ceo',
            title='Client Visit Approved',
            reference_id=str(visit_id),
        ).exists())

        travelling = self.client.post(f'/api/client-visits/{visit_id}/start-travel/', {
            'user_id': self.employee.user_id, 'latitude': 13.0827, 'longitude': 80.2707,
            'odometer': 12540,
        }, format='json')
        self.assertEqual(travelling.status_code, 200)
        self.assertEqual(travelling.data['visit']['status'], 'travelling')

        reached = self.client.post(f'/api/client-visits/{visit_id}/reached-client/', {
            'user_id': self.employee.user_id, 'latitude': 13.0844, 'longitude': 80.2710,
        }, format='json')
        self.assertEqual(reached.status_code, 200)

        checked_in = self.client.post(f'/api/client-visits/{visit_id}/check-in/', {
            'user_id': self.employee.user_id, 'latitude': 13.0844, 'longitude': 80.2710,
        }, format='json')
        self.assertEqual(checked_in.status_code, 200)
        self.assertEqual(checked_in.data['visit']['status'], 'in_progress')

        progress = self.client.post(f'/api/client-visits/{visit_id}/progress/', {
            'user_id': self.employee.user_id,
            'attendees': ['Rohit Sharma'],
            'checklist': [{'label': 'Discuss requirements', 'done': True}],
            'notes': 'Requirements captured.',
        }, format='json')
        self.assertEqual(progress.status_code, 200)
        self.assertEqual(progress.data['visit']['attendees'], ['Rohit Sharma'])

        completed = self.client.post(f'/api/client-visits/{visit_id}/complete/', {
            'user_id': self.employee.user_id, 'latitude': 13.0828, 'longitude': 80.2708,
            'outcome': 'Client approved the proposal.', 'follow_up': 'Send quotation.',
        }, format='json')
        self.assertEqual(completed.status_code, 200)
        self.assertEqual(completed.data['visit']['status'], 'completed')

        verified = self.client.post(f'/api/client-visits/{visit_id}/verify/', {
            'user_id': self.manager.user_id,
        }, format='json')
        self.assertEqual(verified.status_code, 200)
        self.assertEqual(verified.data['visit']['manager_verified_by'], self.manager.user_id)

    @patch('client_visits.storage.cloudinary.uploader.upload')
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
            f'hrms-client-visits/{visit.visit_id}/check_in',
            f'hrms-client-visits/{visit.visit_id}/proof',
        ])
        self.assertEqual(VisitAttachment.objects.filter(visit=visit).count(), 2)
        self.assertFalse(VisitAttachment.objects.filter(
            visit=visit,
        ).exclude(
            cloudinary_cloud_name='client-visits-test-cloud',
            storage_provider='cloudinary_client_visits',
        ).exists())
        for call in upload.call_args_list:
            self.assertEqual(call.kwargs['cloud_name'], 'client-visits-test-cloud')
            self.assertEqual(call.kwargs['api_key'], 'client-visits-test-key')
            self.assertEqual(call.kwargs['api_secret'], 'client-visits-test-secret')

    def test_unassigned_manager_cannot_review_visit(self):
        visit_id = self._create().data['visit']['id']
        other = User.objects.create_user('other-manager@example.com', role='manager')
        response = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': other.user_id, 'action': 'approve',
        }, format='json')
        self.assertEqual(response.status_code, 403)

    @override_settings(CLIENT_VISIT_CLOUDINARY_STORAGE={})
    @patch('client_visits.storage.cloudinary.uploader.upload')
    def test_attachment_upload_never_falls_back_to_existing_storage(self, upload):
        visit_id = self._create().data['visit']['id']
        response = self.client.post(f'/api/client-visits/{visit_id}/attachments/', {
            'user_id': self.employee.user_id,
            'category': 'proof',
            'files': SimpleUploadedFile('proof.jpg', b'image-bytes', content_type='image/jpeg'),
        }, format='multipart')
        self.assertEqual(response.status_code, 503)
        self.assertIn('Dedicated Client Visit Cloudinary', response.data['message'])
        upload.assert_not_called()
        self.assertFalse(VisitAttachment.objects.filter(visit_id=visit_id).exists())

    def test_visit_module_is_visible_to_every_supported_role(self):
        visit_id = self._create().data['visit']['id']
        viewers = [self.employee, self.manager]
        for role in ('admin', 'hr', 'ceo', 'md', 'director'):
            viewers.append(User.objects.create_user(f'{role}@example.com', role=role))

        for viewer in viewers:
            listing = self.client.get('/api/client-visits/', {'user_id': viewer.user_id})
            self.assertEqual(listing.status_code, 200, viewer.role)
            self.assertTrue(
                any(item['id'] == visit_id for item in listing.data['visits']),
                f'{viewer.role} cannot see the visit',
            )
            detail = self.client.get(f'/api/client-visits/{visit_id}/', {'user_id': viewer.user_id})
            self.assertEqual(detail.status_code, 200, viewer.role)
