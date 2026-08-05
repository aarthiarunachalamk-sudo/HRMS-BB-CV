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
        self.manager.first_name = 'Rajesh'
        self.manager.save(update_fields=['first_name'])

    def _create(self, manager_user_id=None):
        return self.client.post('/api/client-visits/', {
            'user_id': self.employee.user_id,
            'manager_user_id': manager_user_id or self.manager.user_id,
            'client_name': 'ABC Solutions',
            'contact_person': 'Rohit Sharma',
            'contact_phone': '9876543210',
            'address': 'Tech Park, Chennai',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '10:30',
            'purpose': 'Project discussion',
            'submit': True,
        }, format='json')

    def test_reporting_tl_name_is_resolved_to_the_system_user_id(self):
        response = self._create(manager_user_id='Rajesh')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(
            response.data['visit']['manager_user_id'],
            self.manager.user_id,
        )

    def test_unknown_reporting_tl_returns_a_json_validation_error(self):
        response = self._create(manager_user_id='Not A Real Team Lead')
        self.assertEqual(response.status_code, 400)
        self.assertIn('TL/HR approver was not found', response.data['message'])

    def test_client_visit_approver_list_contains_tl_and_hr(self):
        hr = User.objects.create_user('visit-approver-list-hr@example.com', role='hr')
        hr.first_name = 'Aarthi'
        hr.save(update_fields=['first_name'])
        response = self.client.get('/api/client-visits/approvers/', {
            'user_id': self.employee.user_id,
        })
        self.assertEqual(response.status_code, 200)
        by_id = {item['employee_id']: item for item in response.data['approvers']}
        self.assertEqual(by_id[self.manager.user_id]['role'], 'tl')
        self.assertEqual(by_id[hr.user_id]['role'], 'hr')

        created = self._create(manager_user_id=hr.user_id)
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.data['visit']['manager_user_id'], hr.user_id)

    def test_team_lead_can_submit_a_new_visit_to_hr(self):
        requester = User.objects.create_user(
            'client-visit-requester-tl@example.com',
            role='tl',
        )
        hr = User.objects.create_user(
            'client-visit-submit-hr@example.com',
            role='hr',
        )
        response = self.client.post('/api/client-visits/', {
            'user_id': requester.user_id,
            'manager_user_id': hr.user_id,
            'client_name': 'Silks Client',
            'contact_person': 'Nandhini',
            'contact_phone': '9876543210',
            'address': 'Chennai',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '16:00',
            'duration_minutes': 60,
            'travel_mode': 'car',
            'purpose': 'Photo taking',
            'notes': 'Capture saree images.',
            'submit': True,
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['visit']['employee_user_id'], requester.user_id)
        self.assertEqual(response.data['visit']['manager_user_id'], hr.user_id)
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=hr.user_id,
            module='client_visit',
            reference_id=str(response.data['visit']['id']),
        ).exists())
        visit_id = response.data['visit']['id']
        tl_approval = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': self.manager.user_id,
            'action': 'approve',
            'comment': 'A TL must not approve another TL request.',
        }, format='json')
        self.assertEqual(tl_approval.status_code, 403)

        hr_approval = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': hr.user_id,
            'action': 'approve',
            'comment': 'Approved by HR.',
        }, format='json')
        self.assertEqual(hr_approval.status_code, 200)
        self.assertEqual(hr_approval.data['visit']['status'], 'approved')
        self.assertEqual(hr_approval.data['visit']['approved_by'], hr.user_id)
        listing = self.client.get('/api/client-visits/', {
            'user_id': requester.user_id,
        })
        self.assertEqual(listing.status_code, 200)
        self.assertIn(
            response.data['visit']['id'],
            {item['id'] for item in listing.data['visits']},
        )

    def test_team_lead_sees_only_hr_approvers_and_cannot_assign_a_tl(self):
        requester = User.objects.create_user(
            'client-visit-requester-tl-filter@example.com',
            role='tl',
        )
        hr = User.objects.create_user(
            'client-visit-hr-filter@example.com',
            role='hr',
        )
        approvers = self.client.get('/api/client-visits/approvers/', {
            'user_id': requester.user_id,
        })
        self.assertEqual(approvers.status_code, 200)
        self.assertEqual(
            {item['employee_id'] for item in approvers.data['approvers']},
            {hr.user_id},
        )

        response = self.client.post('/api/client-visits/', {
            'user_id': requester.user_id,
            'manager_user_id': self.manager.user_id,
            'client_name': 'Kumarapa Silks',
            'contact_person': 'Bhanu',
            'contact_phone': '9572646433',
            'address': 'Omalur',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '13:00',
            'purpose': 'Client project discussion',
            'submit': True,
        }, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('HR approver was not found', response.data['message'])
        self.assertFalse(ClientVisit.objects.filter(
            employee_user_id=requester.user_id,
            client_name='Kumarapa Silks',
        ).exists())

    def test_hr_sees_only_ceo_approvers_and_only_ceo_can_approve(self):
        requester = User.objects.create_user(
            'client-visit-requester-hr@example.com',
            role='hr',
        )
        ceo = User.objects.create_user(
            'client-visit-approver-ceo@example.com',
            role='ceo',
        )
        other_hr = User.objects.create_user(
            'client-visit-non-approver-hr@example.com',
            role='hr',
        )
        approvers = self.client.get('/api/client-visits/approvers/', {
            'user_id': requester.user_id,
        })
        self.assertEqual(approvers.status_code, 200)
        self.assertEqual(
            {item['employee_id'] for item in approvers.data['approvers']},
            {ceo.user_id},
        )

        created = self.client.post('/api/client-visits/', {
            'user_id': requester.user_id,
            'manager_user_id': ceo.user_id,
            'client_name': 'HR Client Visit',
            'contact_person': 'Bhanu',
            'contact_phone': '9572646433',
            'address': 'Omalur',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '13:00',
            'purpose': 'Client project discussion',
            'submit': True,
        }, format='json')
        self.assertEqual(created.status_code, 201)
        visit_id = created.data['visit']['id']

        hr_approval = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': other_hr.user_id,
            'action': 'approve',
        }, format='json')
        self.assertEqual(hr_approval.status_code, 403)
        self.assertIn('CEO approval is required', hr_approval.data['message'])

        ceo_approval = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': ceo.user_id,
            'action': 'approve',
            'comment': 'Approved by CEO.',
        }, format='json')
        self.assertEqual(ceo_approval.status_code, 200)
        self.assertEqual(ceo_approval.data['visit']['status'], 'approved')
        self.assertEqual(ceo_approval.data['visit']['approved_by'], ceo.user_id)

    def test_contact_mobile_number_is_validated_and_normalized(self):
        invalid = self.client.post('/api/client-visits/', {
            'user_id': self.employee.user_id,
            'manager_user_id': self.manager.user_id,
            'client_name': 'ABC Solutions',
            'contact_person': 'Rohit Sharma',
            'contact_phone': '12345',
            'address': 'Tech Park, Chennai',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '10:30',
            'purpose': 'Project discussion',
            'submit': True,
        }, format='json')
        self.assertEqual(invalid.status_code, 400)
        self.assertIn('valid 10-digit mobile number', invalid.data['message'])

        normalized = self.client.post('/api/client-visits/', {
            'user_id': self.employee.user_id,
            'manager_user_id': self.manager.user_id,
            'client_name': 'ABC Solutions',
            'contact_person': 'Rohit Sharma',
            'contact_phone': '+91 98765 43210',
            'address': 'Tech Park, Chennai',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '10:30',
            'purpose': 'Project discussion',
            'submit': True,
        }, format='json')
        self.assertEqual(normalized.status_code, 201)
        self.assertEqual(normalized.data['visit']['contact_phone'], '9876543210')

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

    def test_ceo_md_and_director_have_no_client_visit_approval_permission(self):
        visit_id = self._create().data['visit']['id']
        for role in ('ceo', 'md', 'director'):
            viewer = User.objects.create_user(f'no-approval-{role}@example.com', role=role)
            response = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
                'user_id': viewer.user_id,
                'action': 'approve',
                'comment': 'This must not be accepted.',
            }, format='json')
            self.assertEqual(response.status_code, 403, role)
            self.assertEqual(ClientVisit.objects.get(pk=visit_id).status, 'pending')

    def test_tl_and_hr_can_approve_client_visits(self):
        for role in ('tl', 'hr'):
            visit_id = self._create().data['visit']['id']
            approver = self.manager if role == 'tl' else User.objects.create_user(
                'client-visit-approver-hr@example.com',
                role='hr',
            )
            response = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
                'user_id': approver.user_id,
                'action': 'approve',
                'comment': f'Approved by {role.upper()}.',
            }, format='json')
            self.assertEqual(response.status_code, 200, role)
            visit = ClientVisit.objects.get(pk=visit_id)
            self.assertEqual(visit.status, 'approved', role)
            self.assertEqual(visit.approved_by, approver.user_id, role)
