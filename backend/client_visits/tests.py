from io import BytesIO
from datetime import timedelta
from urllib.parse import urlparse
from unittest.mock import patch

from cloudinary.exceptions import Error as CloudinaryError
from django.core.exceptions import ImproperlyConfigured
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase
from PIL import Image

from hrms.models import AppNotification, User
from .models import ClientVisit, ClientVisitTrackingLink, VisitAttachment
from .storage import client_visit_storage_config


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

    def test_employee_visit_requires_tl_then_hr_approval(self):
        hr = User.objects.create_user(
            'employee-visit-final-hr@example.com',
            role='hr',
        )
        created = self._create()
        visit_id = created.data['visit']['id']

        tl_approval = self.client.post(
            f'/api/client-visits/{visit_id}/approval/',
            {
                'user_id': self.manager.user_id,
                'action': 'approve',
                'comment': 'TL approved this visit.',
            },
            format='json',
        )

        self.assertEqual(tl_approval.status_code, 200)
        self.assertEqual(tl_approval.data['visit']['status'], 'pending')
        self.assertEqual(
            tl_approval.data['visit']['tl_approved_by'],
            self.manager.user_id,
        )
        self.assertEqual(
            tl_approval.data['visit']['tl_approval_comment'],
            'TL approved this visit.',
        )
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='hr',
            title='Client Visit HR Approval Required',
            reference_id=str(visit_id),
        ).exists())

        hr_approval = self.client.post(
            f'/api/client-visits/{visit_id}/approval/',
            {
                'user_id': hr.user_id,
                'action': 'approve',
                'comment': 'Final HR approval.',
            },
            format='json',
        )

        self.assertEqual(hr_approval.status_code, 200)
        self.assertEqual(hr_approval.data['visit']['status'], 'approved')
        self.assertEqual(hr_approval.data['visit']['approved_by'], hr.user_id)
        self.assertEqual(
            hr_approval.data['visit']['tl_approved_by'],
            self.manager.user_id,
        )

    @patch('client_visits.storage.cloudinary.config')
    def test_client_visit_cloudinary_must_differ_from_primary_account(self, config):
        config.return_value.cloud_name = 'client-visits-test-cloud'

        with self.assertRaisesMessage(
            ImproperlyConfigured,
            'must use a different cloud name',
        ):
            client_visit_storage_config()

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
        hr_dashboard = self.client.get('/api/hr/dashboard/', {
            'user_id': hr.user_id,
        })
        self.assertEqual(hr_dashboard.status_code, 200)
        self.assertTrue(any(
            item['module'] == 'client_visit'
            and item['reference_id'] == str(response.data['visit']['id'])
            for item in hr_dashboard.data['notifications']
        ))
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
        self.assertEqual(hr_approval.data['visit']['approved_by_role'], 'hr')
        self.assertEqual(
            hr_approval.data['visit']['approved_by_name'],
            hr.email,
        )
        tl_notification = AppNotification.objects.filter(
            recipient_user_id=requester.user_id,
            module='client_visit',
            reference_id=str(visit_id),
            title='HR Approved Client Visit',
            is_read=False,
        ).first()
        self.assertIsNotNone(tl_notification)
        tl_dashboard = self.client.get('/api/tl/dashboard/', {
            'user_id': requester.user_id,
        })
        self.assertEqual(tl_dashboard.status_code, 200)
        self.assertIn(
            tl_notification.id,
            {item['id'] for item in tl_dashboard.data['notifications']},
        )
        shared_notifications = self.client.get('/api/notifications/', {
            'user_id': requester.user_id,
            'role': 'tl',
        })
        self.assertEqual(shared_notifications.status_code, 200)
        self.assertIn(
            tl_notification.id,
            {item['id'] for item in shared_notifications.data['notifications']},
        )
        listing = self.client.get('/api/client-visits/', {
            'user_id': requester.user_id,
        })
        self.assertEqual(listing.status_code, 200)
        self.assertIn(
            response.data['visit']['id'],
            {item['id'] for item in listing.data['visits']},
        )
        listed_visit = next(
            item for item in listing.data['visits']
            if item['id'] == response.data['visit']['id']
        )
        self.assertEqual(listed_visit['approved_by_role'], 'hr')
        self.assertEqual(listed_visit['approved_by_name'], hr.email)

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

    @patch(
        'client_visits.views.send_mobile_push',
        side_effect=RuntimeError('Push provider unavailable'),
    )
    def test_hr_approval_notification_survives_push_failure(self, _push):
        requester = User.objects.create_user(
            'client-visit-push-failure-tl@example.com',
            role='tl',
        )
        hr = User.objects.create_user(
            'client-visit-push-failure-hr@example.com',
            role='hr',
        )
        created = self.client.post('/api/client-visits/', {
            'user_id': requester.user_id,
            'manager_user_id': hr.user_id,
            'client_name': 'Push Safe Client',
            'contact_person': 'Nandhini',
            'contact_phone': '9876543210',
            'address': 'Chennai',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '16:00',
            'purpose': 'Project discussion',
            'submit': True,
        }, format='json')
        self.assertEqual(created.status_code, 201)
        visit_id = created.data['visit']['id']

        approved = self.client.post(
            f'/api/client-visits/{visit_id}/approval/',
            {
                'user_id': hr.user_id,
                'action': 'approve',
                'comment': 'Approved by HR.',
            },
            format='json',
        )
        self.assertEqual(approved.status_code, 200)
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=requester.user_id,
            module='client_visit',
            reference_id=str(visit_id),
            title='HR Approved Client Visit',
            push_sent=False,
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
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=ceo.user_id,
            module='client_visit',
            reference_id=str(visit_id),
            title='Client Visit Approval Required',
        ).exists())
        self.assertFalse(AppNotification.objects.filter(
            recipient_role='ceo',
            module='client_visit',
            reference_id=str(visit_id),
        ).exists())
        ceo_notifications = self.client.get('/api/ceo/notifications/', {
            'user_id': ceo.user_id,
        })
        self.assertEqual(ceo_notifications.status_code, 200)
        self.assertTrue(any(
            item['module'] == 'client_visit'
            and item['reference_id'] == str(visit_id)
            for item in ceo_notifications.data['notifications']
        ))

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

    def test_visit_stores_and_returns_selected_service(self):
        response = self.client.post('/api/client-visits/', {
            'user_id': self.employee.user_id,
            'manager_user_id': self.manager.user_id,
            'client_name': 'ABC Solutions',
            'contact_person': 'Rohit Sharma',
            'contact_phone': '9876543210',
            'address': 'Tech Park, Chennai',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '10:30',
            'service_type': 'business_analytics',
            'purpose': 'Review the client reporting requirements',
            'submit': True,
        }, format='json')

        self.assertEqual(response.status_code, 201)
        self.assertEqual(
            response.data['visit']['service_type'],
            'business_analytics',
        )
        self.assertEqual(
            response.data['visit']['service_name'],
            'Business Analytics',
        )

    def test_visit_rejects_unknown_service(self):
        response = self.client.post('/api/client-visits/', {
            'user_id': self.employee.user_id,
            'manager_user_id': self.manager.user_id,
            'client_name': 'ABC Solutions',
            'contact_person': 'Rohit Sharma',
            'contact_phone': '9876543210',
            'address': 'Tech Park, Chennai',
            'scheduled_date': '2026-08-10',
            'scheduled_time': '10:30',
            'service_type': 'unknown_service',
            'purpose': 'Project discussion',
            'submit': True,
        }, format='json')

        self.assertEqual(response.status_code, 400)
        self.assertIn('valid client service', response.data['message'])

    def test_visit_follows_approval_check_in_and_completion_workflow(self):
        md = User.objects.create_user('visit-monitor-md@example.com', role='md')
        director = User.objects.create_user(
            'visit-monitor-director@example.com', role='director'
        )
        admin = User.objects.create_user('visit-monitor-admin@example.com', role='admin')
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
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=self.employee.user_id,
            title='Client Visit Request Submitted',
            reference_id=str(visit_id),
        ).exists())
        for role, user in (('md', md), ('director', director), ('admin', admin)):
            self.assertTrue(AppNotification.objects.filter(
                recipient_role=role,
                title='New Client Visit Request',
                reference_id=str(visit_id),
            ).exists())
            notifications = self.client.get('/api/notifications/', {
                'user_id': user.user_id,
                'role': role,
            })
            self.assertEqual(notifications.status_code, 200)
            self.assertTrue(any(
                item['module'] == 'client_visit'
                and item['reference_id'] == str(visit_id)
                for item in notifications.data['notifications']
            ))

        approved = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': self.manager.user_id, 'action': 'approve', 'comment': 'Proceed.',
        }, format='json')
        self.assertEqual(approved.status_code, 200)
        self.assertEqual(approved.data['visit']['status'], 'approved')
        self.assertTrue(AppNotification.objects.filter(
            recipient_user_id=self.employee.user_id,
            title='TL Approved Client Visit',
            reference_id=str(visit_id),
        ).exists())
        self.assertTrue(AppNotification.objects.filter(
            recipient_role='ceo',
            title='TL Approved Client Visit',
            reference_id=str(visit_id),
        ).exists())

        travelling = self.client.post(f'/api/client-visits/{visit_id}/start-travel/', {
            'user_id': self.employee.user_id, 'latitude': 13.0827, 'longitude': 80.2707,
            'odometer': 12540,
        }, format='json')
        self.assertEqual(travelling.status_code, 200)
        self.assertEqual(travelling.data['visit']['status'], 'travelling')
        self.assertEqual(len(travelling.data['visit']['travel_route']), 1)

        tracked = self.client.post(f'/api/client-visits/{visit_id}/location/', {
            'user_id': self.employee.user_id,
            'latitude': 13.0831,
            'longitude': 80.2709,
            'accuracy': 8.5,
            'speed': 4.2,
        }, format='json')
        self.assertEqual(tracked.status_code, 200)
        self.assertEqual(tracked.data['route_points'], 2)

        reached = self.client.post(f'/api/client-visits/{visit_id}/reached-client/', {
            'user_id': self.employee.user_id, 'latitude': 13.0844, 'longitude': 80.2710,
        }, format='json')
        self.assertEqual(reached.status_code, 200)
        self.assertEqual(reached.data['visit']['reached_client_latitude'], 13.0844)
        self.assertEqual(reached.data['visit']['reached_client_longitude'], 80.271)

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
            {'secure_url': 'https://res.cloudinary.com/test/office.jpg', 'public_id': 'office', 'resource_type': 'image'},
        ]
        for category in ('check_in', 'proof', 'office_checkout'):
            response = self.client.post(f'/api/client-visits/{visit_id}/attachments/', {
                'user_id': self.employee.user_id, 'category': category,
                'files': SimpleUploadedFile(f'{category}.jpg', b'image-bytes', content_type='image/jpeg'),
            }, format='multipart')
            self.assertEqual(response.status_code, 201)

        folders = [call.kwargs['folder'] for call in upload.call_args_list]
        self.assertEqual(folders, [
            f'hrms-client-visits/{visit.visit_id}/check_in',
            f'hrms-client-visits/{visit.visit_id}/proof',
            f'hrms-client-visits/{visit.visit_id}/office_checkout',
        ])
        self.assertEqual(VisitAttachment.objects.filter(visit=visit).count(), 3)
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

    @patch('client_visits.storage.cloudinary.uploader.upload')
    def test_android_camera_image_with_octet_stream_mime_is_accepted(self, upload):
        image = BytesIO()
        Image.new('RGB', (2, 2), color='white').save(image, format='JPEG')
        upload.return_value = {
            'secure_url': 'https://res.cloudinary.com/test/selfie.jpg',
            'public_id': 'office-selfie',
            'resource_type': 'image',
        }
        visit_id = self._create().data['visit']['id']

        response = self.client.post(f'/api/client-visits/{visit_id}/attachments/', {
            'user_id': self.employee.user_id,
            'category': 'office_checkout',
            'files': SimpleUploadedFile(
                'image_picker_cache', image.getvalue(),
                content_type='application/octet-stream',
            ),
        }, format='multipart')

        self.assertEqual(response.status_code, 201)
        upload.assert_called_once()

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

    @patch('client_visits.storage.cloudinary.uploader.upload')
    def test_attachment_reports_rejected_cloudinary_credentials(self, upload):
        upload.side_effect = CloudinaryError('Invalid API key or signature')
        visit_id = self._create().data['visit']['id']
        response = self.client.post(f'/api/client-visits/{visit_id}/attachments/', {
            'user_id': self.employee.user_id,
            'category': 'office_checkout',
            'files': SimpleUploadedFile(
                'selfie.jpg', b'image-bytes', content_type='image/jpeg',
            ),
        }, format='multipart')
        self.assertEqual(response.status_code, 503)
        self.assertIn('credentials were rejected', response.data['message'])
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

    def test_active_visit_can_create_a_public_live_tracking_link(self):
        visit_id = self._create().data['visit']['id']
        visit = ClientVisit.objects.get(pk=visit_id)
        visit.status = 'travelling'
        visit.travel_route = [{
            'latitude': 13.0831,
            'longitude': 80.2709,
            'recorded_at': timezone.now().isoformat(),
        }]
        visit.save(update_fields=['status', 'travel_route'])

        created = self.client.post(
            f'/api/client-visits/{visit_id}/tracking-link/',
            {
                'user_id': self.employee.user_id,
                'destination_latitude': 13.0844,
                'destination_longitude': 80.2710,
            },
            format='json',
        )
        self.assertEqual(created.status_code, 201)
        tracking_url = created.data['tracking_url']
        self.assertIn('/track/client-visit/', tracking_url)
        token = urlparse(tracking_url).path.rstrip('/').split('/')[-1]

        page = self.client.get(f'/track/client-visit/{token}/')
        self.assertEqual(page.status_code, 200)
        self.assertContains(page, 'LIVE TRACKING')

        public_data = self.client.get(
            f'/api/client-visits/public-track/{token}/',
        )
        self.assertEqual(public_data.status_code, 200)
        self.assertEqual(public_data.data['status_label'], 'On the way')
        self.assertEqual(
            public_data.data['current_location']['latitude'],
            13.0831,
        )
        self.assertEqual(public_data.data['destination']['latitude'], 13.0844)
        self.assertNotIn('contact_phone', public_data.data)
        self.assertNotIn('address', public_data.data)
        self.assertNotIn('travel_route', public_data.data)

    def test_expired_tracking_link_stops_returning_location(self):
        visit_id = self._create().data['visit']['id']
        visit = ClientVisit.objects.get(pk=visit_id)
        visit.status = 'travelling'
        visit.save(update_fields=['status'])
        created = self.client.post(
            f'/api/client-visits/{visit_id}/tracking-link/',
            {'user_id': self.employee.user_id},
            format='json',
        )
        token = urlparse(created.data['tracking_url']).path.rstrip('/').split('/')[-1]
        ClientVisitTrackingLink.objects.update(
            expires_at=timezone.now() - timedelta(seconds=1),
        )

        response = self.client.get(
            f'/api/client-visits/public-track/{token}/',
        )
        self.assertEqual(response.status_code, 410)

    def test_hr_cannot_skip_tl_approval_for_employee_visit(self):
        visit_id = self._create().data['visit']['id']
        hr = User.objects.create_user(
            'client-visit-approver-hr@example.com',
            role='hr',
        )

        response = self.client.post(f'/api/client-visits/{visit_id}/approval/', {
            'user_id': hr.user_id,
            'action': 'approve',
            'comment': 'Attempted final HR approval.',
        }, format='json')

        self.assertEqual(response.status_code, 409)
        visit = ClientVisit.objects.get(pk=visit_id)
        self.assertEqual(visit.status, 'pending')
        self.assertEqual(visit.tl_approved_by, '')

    def test_active_route_is_tl_only_then_available_to_history_roles(self):
        hr = User.objects.create_user('route-history-hr@example.com', role='hr')
        ceo = User.objects.create_user('route-history-ceo@example.com', role='ceo')
        visit_id = self._create().data['visit']['id']
        visit = ClientVisit.objects.get(pk=visit_id)
        visit.status = 'travelling'
        visit.travel_route = [{
            'latitude': 13.0831,
            'longitude': 80.2709,
            'recorded_at': timezone.now().isoformat(),
        }]
        visit.save(update_fields=['status', 'travel_route'])

        tl_detail = self.client.get(
            f'/api/client-visits/{visit_id}/',
            {'user_id': self.manager.user_id},
        )
        self.assertEqual(len(tl_detail.data['visit']['travel_route']), 1)

        for viewer in (hr, ceo):
            active_detail = self.client.get(
                f'/api/client-visits/{visit_id}/',
                {'user_id': viewer.user_id},
            )
            self.assertEqual(active_detail.status_code, 200)
            self.assertEqual(active_detail.data['visit']['travel_route'], [])

        visit.status = 'completed'
        visit.save(update_fields=['status'])
        completed_detail = self.client.get(
            f'/api/client-visits/{visit_id}/',
            {'user_id': hr.user_id},
        )
        self.assertEqual(len(completed_detail.data['visit']['travel_route']), 1)

    def test_tl_completion_notifies_hr_and_executive_history_roles(self):
        requester = User.objects.create_user(
            'completed-visit-tl@example.com',
            role='tl',
        )
        hr = User.objects.create_user('completed-visit-hr@example.com', role='hr')
        visit = ClientVisit.objects.create(
            employee_user_id=requester.user_id,
            employee_name='TL Visitor',
            manager_user_id=hr.user_id,
            client_name='History Client',
            contact_person='Client Manager',
            contact_phone='9876543210',
            address='Chennai',
            scheduled_date=timezone.localdate(),
            scheduled_time=timezone.localtime().time(),
            purpose='Completion audit test',
            status='in_progress',
        )

        response = self.client.post(
            f'/api/client-visits/{visit.id}/complete/',
            {
                'user_id': requester.user_id,
                'outcome': 'Visit objectives completed.',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)

        for role in ('hr', 'ceo', 'md', 'superadmin'):
            self.assertTrue(AppNotification.objects.filter(
                recipient_role=role,
                title='Client Visit Completed - History Ready',
                reference_id=str(visit.id),
            ).exists(), role)

        notifications = self.client.get('/api/notifications/', {
            'user_id': hr.user_id,
            'role': 'hr',
        })
        self.assertEqual(notifications.status_code, 200)
        self.assertTrue(any(
            item['reference_id'] == str(visit.id)
            and item['title'] == 'Client Visit Completed - History Ready'
            for item in notifications.data['notifications']
        ))
