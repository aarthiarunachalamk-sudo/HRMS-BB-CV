from django.test import TestCase
from rest_framework.test import APIClient
from django.utils import timezone
from hrms.models import User, EmployeeRegistration, EmployeeAccount, AppNotification


class TeamAllocationFlowTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # CEO
        self.ceo = User.objects.create_user(
            email='ceo_test@bitbytetech.org',
            password='TestPassword@2026',
            role='ceo',
        )
        self.ceo.first_name = 'CEO'
        self.ceo.last_name = 'Leader'
        self.ceo.user_id = 'BBCEO0001'
        self.ceo.save()

        # PM
        self.pm = User.objects.create_user(
            email='pm_test@bitbytetech.org',
            password='TestPassword@2026',
            role='manager',
        )
        self.pm.first_name = 'PM'
        self.pm.last_name = 'Manager'
        self.pm.user_id = 'BBMGR0001'
        self.pm.save()

        # HR
        self.hr = User.objects.create_user(
            email='hr_test@bitbytetech.org',
            password='TestPassword@2026',
            role='hr',
        )
        self.hr.first_name = 'HR'
        self.hr.last_name = 'Admin'
        self.hr.user_id = 'BBHR0001'
        self.hr.save()

        # Team Lead (TL)
        self.tl = User.objects.create_user(
            email='tl_test@bitbytetech.org',
            password='TestPassword@2026',
            role='tl',
        )
        self.tl.first_name = 'Lead'
        self.tl.last_name = 'Tester'
        self.tl.user_id = 'BBTL0001'
        self.tl.save()

        # Ensure TL has an active EmployeeAccount with designation='tl'
        self.tl_account = EmployeeAccount.objects.filter(employee_email=self.tl.email).first()
        if not self.tl_account:
            self.tl_reg = EmployeeRegistration.objects.create(
                first_name='Lead',
                last_name='Tester',
                gender='male',
                dob='1990-01-01',
                mobile='9876543210',
                personal_email='tl_test_personal@bitbytetech.org',
                marital_status='single',
                blood_group='O+',
                nationality='Indian',
                current_city='Chennai',
                current_state='Tamil Nadu',
                permanent_city='Chennai',
                permanent_state='Tamil Nadu',
                emergency_name='Contact',
                emergency_relationship='Father',
                emergency_contact='9876543211',
                aadhar='123456789012',
                pan='ABCDE1234F',
                qualification='B.Tech',
                college='Engineering',
                status='approved',
            )
            self.tl_account = EmployeeAccount.objects.create(
                registration=self.tl_reg,
                employee_id='BBTL0001',
                employee_email='tl_test@bitbytetech.org',
                department='webapp',
                designation='tl',
                date_of_joining=timezone.localdate(),
                employment_type='full_time',
                work_location='onsite',
            )
        else:
            self.tl_account.designation = 'tl'
            self.tl_account.employee_id = 'BBTL0001'
            self.tl_account.department = 'webapp'
            self.tl_account.save()

        # Candidate who just registered
        self.candidate = EmployeeRegistration.objects.create(
            first_name='Newbie',
            last_name='Coder',
            gender='female',
            dob='2000-05-15',
            mobile='9123456780',
            personal_email='newbie.coder@example.com',
            marital_status='single',
            blood_group='A+',
            nationality='Indian',
            current_city='Bengaluru',
            current_state='Karnataka',
            permanent_city='Bengaluru',
            permanent_state='Karnataka',
            emergency_name='Parent',
            emergency_relationship='Mother',
            emergency_contact='9123456781',
            aadhar='987654321098',
            pan='XYZAB5678C',
            qualification='B.E. CSE',
            college='Tech College',
            status='pending',
        )

    def test_hr_approves_candidate_ready_to_join_without_tl(self):
        # HR approves person ready to join
        response = self.client.post(
            f'/api/add-employee/{self.candidate.id}/',
            data={
                'employee_email': 'newbie.coder@bitbyte.com',
                'department': 'webapp',
                'designation': 'associate',
                'date_of_joining': str(timezone.localdate()),
                'employment_type': 'full_time',
                'work_location': 'onsite',
                'reporting_tl': 'TRYING_TO_ASSIGN_TL', # Should be removed/ignored for HR!
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data.get('success'))
        self.assertEqual(response.data.get('status'), 'hr_approved')

        # Check candidate status in database
        self.candidate.refresh_from_db()
        self.assertEqual(self.candidate.status, 'hr_approved')

        # Check account was created without TL
        account = EmployeeAccount.objects.get(registration=self.candidate)
        self.assertEqual(account.reporting_tl, '')

        # Check notifications sent to CEO and PM
        ceo_notifs = AppNotification.objects.filter(recipient_role='ceo', module='team_allocation')
        self.assertTrue(ceo_notifs.exists())
        pm_notifs = AppNotification.objects.filter(recipient_role='pm', module='team_allocation')
        self.assertTrue(pm_notifs.exists())

    def test_hr_cannot_allocate_tl_directly(self):
        # HR attempts to call allocate_team_member
        response = self.client.post(
            f'/api/team/allocate-member/{self.candidate.id}/',
            data={
                'role': 'hr',
                'reporting_tl': 'BBTL0001',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 403)
        self.assertFalse(response.data.get('success'))
        self.assertIn('assigned by PM or CEO', response.data.get('message'))

    def test_pm_allocates_team_member_and_tl(self):
        # 1. HR first approves candidate
        self.client.post(
            f'/api/add-employee/{self.candidate.id}/',
            data={
                'employee_email': 'newbie.coder@bitbyte.com',
                'department': 'webapp',
                'designation': 'associate',
                'date_of_joining': str(timezone.localdate()),
                'employment_type': 'full_time',
                'work_location': 'onsite',
            },
            format='json',
        )

        # 2. PM allocates team member and assigns TL
        response = self.client.post(
            f'/api/team/allocate-member/{self.candidate.id}/',
            data={
                'role': 'manager', # PM role
                'user_id': self.pm.user_id,
                'reporting_tl': 'BBTL0001',
                'department': 'webapp',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data.get('success'))

        # Check candidate status
        self.candidate.refresh_from_db()
        self.assertEqual(self.candidate.status, 'approved')

        # Check TL is assigned
        account = EmployeeAccount.objects.get(registration=self.candidate)
        self.assertEqual(account.reporting_tl, 'BBTL0001')

        # Check TL was notified
        tl_notifs = AppNotification.objects.filter(recipient_user_id='BBTL0001', module='team_allocation')
        self.assertTrue(tl_notifs.exists())

    def test_ceo_allocates_team_member_and_tl(self):
        # 1. HR approves
        self.candidate.status = 'hr_approved'
        self.candidate.save()

        # 2. CEO allocates
        response = self.client.post(
            f'/api/team/allocate-member/{self.candidate.id}/',
            data={
                'role': 'ceo',
                'user_id': self.ceo.user_id,
                'reporting_tl': 'BBTL0001',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data.get('success'))

        self.candidate.refresh_from_db()
        self.assertEqual(self.candidate.status, 'approved')
        account = EmployeeAccount.objects.get(registration=self.candidate)
        self.assertEqual(account.reporting_tl, 'BBTL0001')
