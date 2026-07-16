from datetime import date, datetime, time, timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from hrms.models import (
    Announcement,
    AppNotification,
    AssetInventory,
    AttendanceRegularizationRequest,
    AuditLog,
    BranchPerformanceSnapshot,
    BudgetPlan,
    BudgetTransaction,
    DashboardWidgetSnapshot,
    DepartmentPerformanceSnapshot,
    DocumentRecord,
    EmployeeAccount,
    EmployeeAttendanceRecord,
    EmployeeGoal,
    EmployeeLeaveRequest,
    EmployeePerformance,
    EmployeeRegistration,
    HelpdeskTicket,
    InterviewSchedule,
    LeaveBalanceLedger,
    MdMeeting,
    MeetingMinute,
    MeetingParticipantStatus,
    MobileDeviceToken,
    OnboardingTask,
    OrganizationBranch,
    OrganizationDepartment,
    OrganizationProfile,
    OrganizationRole,
    OvertimeRequest,
    PayrollProcess,
    Payslip,
    PerformanceReviewCycle,
    Project,
    ProjectExpense,
    ProjectIssue,
    RecruitmentCandidatePipeline,
    RecruitmentJobOpening,
    ReportExportHistory,
    ReportSchedule,
    SalaryRevisionRequest,
    SalaryStructure,
    SavedFilterView,
    ShiftSchedule,
    TaskChecklistItem,
    TaskComment,
    TeamTask,
    TrainingEnrollment,
    TrainingProgram,
    User,
    UserProfileSetting,
    WorkflowApprovalRequest,
)


class Command(BaseCommand):
    help = 'Seed dummy HRMS data for every module/model for load and flow testing.'

    ROLE_USERS = [
        ('superadmin', 'superadmin@bitbyte.test', 'Super', 'Admin', 'Management', 'Super Administrator'),
        ('ceo', 'ceo@bitbyte.test', 'Rajesh', 'Kumar', 'Management', 'Chief Executive Officer'),
        ('md', 'md@bitbyte.test', 'Meena', 'Raman', 'Management', 'Managing Director'),
        ('director', 'director@bitbyte.test', 'Arun', 'Prakash', 'Management', 'Director'),
        ('hr', 'hr@bitbyte.test', 'Padma', 'Sheela', 'HR', 'HR Manager'),
        ('admin', 'admin@bitbyte.test', 'Aarthi', 'Karthik', 'Administration', 'Admin'),
        ('tl', 'tl@bitbyte.test', 'Jai', 'Ramachandran', 'Web Application Development', 'Team Lead'),
        ('employee', 'employee@bitbyte.test', 'Mano', 'CA', 'Mobile Application Development', 'Employee'),
        ('finance', 'finance@bitbyte.test', 'Kavin', 'Raj', 'Finance', 'Finance Manager'),
        ('marketing', 'marketing@bitbyte.test', 'Divya', 'Sri', 'Digital Marketing', 'Marketing Lead'),
        ('it', 'it@bitbyte.test', 'Naveen', 'Kumar', 'Technical Support', 'IT Support'),
    ]

    EMPLOYEE_DEPARTMENTS = [
        ('web_application_development', 'TL'),
        ('mobile_application_development', 'Associate'),
        ('digital_marketing', 'Associate'),
        ('technical_support', 'Associate'),
        ('hr', 'HR'),
        ('management', 'Manager'),
    ]

    def add_arguments(self, parser):
        parser.add_argument(
            '--employees',
            type=int,
            default=18,
            help='Number of dummy employee registrations/accounts to ensure.',
        )

    @transaction.atomic
    def handle(self, *args, **options):
        employee_count = max(options['employees'], 6)
        today = timezone.localdate()
        now = timezone.now()

        users = self._seed_users()
        registrations, accounts = self._seed_employee_master(employee_count, today)
        role_accounts = self._seed_role_employee_accounts(users, today)
        accounts = role_accounts + accounts
        jobs = self._seed_recruitment(users, registrations, now)
        meetings = self._seed_meetings(users, accounts, now)
        projects = self._seed_projects(users, accounts, today)
        tasks = self._seed_tasks(users, accounts, projects, today)
        self._seed_attendance_and_leave(accounts, today, now)
        self._seed_payroll(accounts, today)
        self._seed_notifications(users, meetings, tasks)
        self._seed_organization(users, accounts, today)
        self._seed_extension_modules(users, accounts, jobs, meetings, projects, tasks, today, now)

        self.stdout.write(self.style.SUCCESS('Dummy HRMS data seeded for every module/model.'))
        self.stdout.write(self.style.SUCCESS(f'Users: {len(users)} | Employees: {len(accounts)} | Projects: {len(projects)} | Tasks: {len(tasks)}'))

    def _seed_users(self):
        users = {}
        for role, email, first_name, last_name, department, occupation in self.ROLE_USERS:
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'role': role,
                    'first_name': first_name,
                    'last_name': last_name,
                    'department': department,
                    'occupation': occupation,
                    'phone': f'900000{len(users):04d}',
                    'city': 'Salem',
                    'state': 'Tamil Nadu',
                    'work_mode': 'onsite',
                    'is_active': True,
                },
            )
            user.role = role
            user.first_name = first_name
            user.last_name = last_name
            user.department = department
            user.occupation = occupation
            user.is_active = True
            user.set_password('Test@1234')
            user.save()
            users[role] = user
        return users

    def _registration_defaults(self, index, department_key):
        first = f'Dummy{index:02d}'
        last = 'Employee'
        return {
            'first_name': first,
            'last_name': last,
            'gender': 'male' if index % 2 else 'female',
            'dob': f'199{index % 10}-0{(index % 9) + 1}-15',
            'mobile': f'8{index:09d}'[-10:],
            'personal_email': f'dummy.employee{index:02d}@bitbyte.test',
            'marital_status': 'single',
            'blood_group': ['A+', 'B+', 'O+', 'AB+'][index % 4],
            'nationality': 'Indian',
            'current_door': str(10 + index),
            'current_street': 'Test Street',
            'current_address2': 'Near HRMS Demo Office',
            'current_city': 'Salem',
            'current_state': 'Tamil Nadu',
            'permanent_door': str(20 + index),
            'permanent_street': 'Permanent Street',
            'permanent_address2': 'Demo Nagar',
            'permanent_city': 'Salem',
            'permanent_state': 'Tamil Nadu',
            'emergency_name': f'Emergency Contact {index}',
            'emergency_relationship': 'Parent',
            'emergency_contact': f'7{index:09d}'[-10:],
            'aadhar': f'{index:012d}'[-12:],
            'pan': f'ABCDE{index:04d}F'[-10:],
            'qualification': 'B.Tech',
            'college': 'BitByte Institute',
            'year_of_passing': str(2018 + (index % 6)),
            'percentage': str(70 + (index % 20)),
            'account_holder': f'{first} {last}',
            'bank_name': 'Demo Bank',
            'account_number': f'1234500000{index:04d}',
            'ifsc_code': 'DEMO0001234',
            'branch_name': 'Salem',
            'is_experienced': index % 3 == 0,
            'prev_company': 'Previous Demo Company' if index % 3 == 0 else '',
            'prev_designation': 'Developer' if index % 3 == 0 else '',
            'prev_experience': '2' if index % 3 == 0 else '',
            'prev_last_working_day': '2024-12-31' if index % 3 == 0 else '',
            'status': 'approved',
            'recruitment_stage': 'hired',
            'document_statuses': {'aadhar': 'verified', 'pan': 'verified', 'degree': 'verified'},
            'document_review_history': [{'status': 'verified', 'by': 'HR', 'note': 'Dummy verified documents'}],
            'interview_data': {'round': 'HR', 'score': 8},
            'offer_data': {'ctc': 420000 + index * 10000},
            'onboarding_checklist': {'email_created': True, 'laptop_assigned': index % 2 == 0},
        }

    def _seed_employee_master(self, employee_count, today):
        registrations = []
        accounts = []
        for index in range(1, employee_count + 1):
            department_key, designation_label = self.EMPLOYEE_DEPARTMENTS[(index - 1) % len(self.EMPLOYEE_DEPARTMENTS)]
            email = f'dummy.employee{index:02d}@bitbyte.test'
            registration, _ = EmployeeRegistration.objects.update_or_create(
                personal_email=email,
                defaults=self._registration_defaults(index, department_key),
            )
            account, _ = EmployeeAccount.objects.update_or_create(
                employee_email=email,
                defaults={
                    'registration': registration,
                    'department': department_key,
                    'designation': self._designation_value(designation_label),
                    'date_of_joining': today - timedelta(days=30 + index),
                    'employment_type': 'full_time',
                    'reporting_tl': 'BBTL0001',
                    'work_location': ['Salem', 'Onsite', 'Remote'][index % 3],
                    'is_active': True,
                },
            )
            registrations.append(registration)
            accounts.append(account)
        return registrations, accounts

    def _seed_role_employee_accounts(self, users, today):
        role_specs = [
            ('ceo', 'management', 'ceo'),
            ('md', 'management', 'md'),
            ('hr', 'hr', 'hr'),
            ('tl', 'web_application_development', 'tl'),
            ('employee', 'mobile_application_development', 'associate'),
        ]
        accounts = []
        for index, (role, department, designation) in enumerate(role_specs, start=101):
            user = users[role]
            registration_defaults = self._registration_defaults(index, department)
            registration_defaults.update({
                'first_name': user.first_name,
                'last_name': user.last_name,
                'personal_email': user.email,
                'mobile': f'9{index:09d}'[-10:],
                'status': 'approved',
            })
            registration, _ = EmployeeRegistration.objects.update_or_create(
                personal_email=user.email,
                defaults=registration_defaults,
            )
            account, _ = EmployeeAccount.objects.update_or_create(
                employee_email=user.email,
                defaults={
                    'registration': registration,
                    'department': department,
                    'designation': designation,
                    'date_of_joining': today - timedelta(days=180 + index),
                    'employment_type': 'full_time',
                    'reporting_tl': users['tl'].user_id if role == 'employee' else users['ceo'].user_id,
                    'work_location': 'Salem HQ',
                    'is_active': True,
                },
            )
            accounts.append(account)
        return accounts

    def _designation_value(self, label):
        mapping = {
            'TL': 'tl',
            'Associate': 'associate',
            'HR': 'hr',
            'Manager': 'manager',
        }
        return mapping.get(label, 'associate')

    def _seed_recruitment(self, users, registrations, now):
        jobs = []
        for index, title in enumerate(['Flutter Developer', 'Django Backend Developer', 'HR Executive', 'Digital Marketing Executive'], start=1):
            job, _ = RecruitmentJobOpening.objects.update_or_create(
                title=title,
                defaults={
                    'department': ['Mobile App', 'WebApp', 'HR', 'Digital Marketing'][index - 1],
                    'location': 'Salem',
                    'openings': index + 1,
                    'status': 'open',
                    'created_by': users['hr'].user_id,
                },
            )
            jobs.append(job)
        return jobs

    def _seed_meetings(self, users, accounts, now):
        meetings = []
        participants = [
            {'id': account.employee_id, 'name': account.registration.first_name, 'email': account.employee_email}
            for account in accounts[:6]
        ]
        meeting_owners = [users['ceo'].user_id, users['md'].user_id, users['tl'].user_id, users['hr'].user_id]
        for index, title in enumerate(['Sprint Planning', 'MD Business Review', 'TL Team Sync', 'HR Policy Discussion', 'Budget Planning'], start=1):
            scheduled = now + timedelta(days=index, hours=index)
            meeting, _ = MdMeeting.objects.update_or_create(
                title=title,
                created_by=meeting_owners[(index - 1) % len(meeting_owners)],
                defaults={
                    'meeting_type': 'Online' if index % 2 else 'Office',
                    'location': f'https://meet.bitbyte.in/dummy-{index}',
                    'description': f'Dummy {title.lower()} for flow testing.',
                    'date_label': scheduled.strftime('%d-%m-%Y'),
                    'time_label': scheduled.strftime('%I:%M %p'),
                    'duration': '45 Minutes',
                    'status': 'upcoming',
                    'participants': participants,
                    'agenda': ['Review progress', 'Discuss blockers', 'Assign action items'],
                },
            )
            meetings.append(meeting)
        return meetings

    def _seed_projects(self, users, accounts, today):
        projects = []
        for index, name in enumerate(['HRMS Mobile App', 'Payroll Automation', 'Attendance Intelligence', 'Recruitment Portal'], start=1):
            team = [
                {'id': account.employee_id, 'name': f'{account.registration.first_name} {account.registration.last_name}', 'role': account.designation}
                for account in accounts[(index - 1):index + 4]
            ]
            project, _ = Project.objects.update_or_create(
                code=f'PRJ-DUMMY-{index:03d}',
                defaults={
                    'name': name,
                    'department': ['Mobile App', 'Finance', 'HR', 'WebApp'][index - 1],
                    'description': f'Dummy project for {name} module testing.',
                    'status': ['in_progress', 'not_started', 'at_risk', 'completed'][index - 1],
                    'start_date': today - timedelta(days=20 * index),
                    'end_date': today + timedelta(days=45 * index),
                    'budget': Decimal(250000 * index),
                    'spent': Decimal(85000 * index),
                    'progress': min(25 * index, 100),
                    'manager_id': users['tl'].user_id,
                    'manager_name': 'Jai Ramachandran',
                    'manager_email': users['tl'].email,
                    'team': team,
                    'milestones': [{'title': 'Phase 1', 'status': 'completed'}, {'title': 'Phase 2', 'status': 'in_progress'}],
                    'progress_history': [{'date': str(today - timedelta(days=7)), 'progress': 35}, {'date': str(today), 'progress': min(25 * index, 100)}],
                    'created_by': users['ceo'].user_id,
                },
            )
            projects.append(project)
        return projects

    def _seed_tasks(self, users, accounts, projects, today):
        tasks = []
        for index, account in enumerate(accounts[:18], start=1):
            project = projects[(index - 1) % len(projects)]
            task, _ = TeamTask.objects.update_or_create(
                title=f'Dummy Task {index:02d} - {project.name}',
                assignee_id=account.employee_id,
                defaults={
                    'project': project.name,
                    'assignee_name': f'{account.registration.first_name} {account.registration.last_name}',
                    'assignee_email': account.employee_email,
                    'priority': ['Low', 'Medium', 'High', 'Urgent'][index % 4],
                    'due_date': str(today + timedelta(days=index)),
                    'description': 'Dummy task for TL/employee task flow testing.',
                    'status': ['pending', 'in_progress', 'completed'][index % 3],
                    'created_by': users['tl'].user_id,
                },
            )
            tasks.append(task)
        role_task_specs = [
            ('CEO Review Hiring Plan', users['ceo'].user_id, accounts[0]),
            ('MD Review Branch Budget', users['md'].user_id, accounts[1]),
            ('HR Verify Employee Documents', users['hr'].user_id, accounts[2]),
            ('TL Assign Sprint Work', users['tl'].user_id, accounts[3]),
            ('Employee Submit Daily Update', users['tl'].user_id, accounts[4]),
        ]
        for index, (title, creator_id, account) in enumerate(role_task_specs, start=101):
            project = projects[index % len(projects)]
            task, _ = TeamTask.objects.update_or_create(
                title=title,
                assignee_id=account.employee_id,
                defaults={
                    'project': project.name,
                    'assignee_name': f'{account.registration.first_name} {account.registration.last_name}',
                    'assignee_email': account.employee_email,
                    'priority': ['High', 'Medium', 'Urgent', 'Low', 'Medium'][index % 5],
                    'due_date': str(today + timedelta(days=index % 14 + 1)),
                    'description': 'Role-specific dummy task for backend flow testing.',
                    'status': ['pending', 'in_progress', 'completed'][index % 3],
                    'created_by': creator_id,
                },
            )
            tasks.append(task)
        return tasks

    def _seed_attendance_and_leave(self, accounts, today, now):
        for index, account in enumerate(accounts, start=1):
            for offset in range(0, 10):
                attendance_date = today - timedelta(days=offset)
                status = ['Present', 'Late Entry', 'Absent', 'Half Day'][((index + offset) % 4)]
                EmployeeAttendanceRecord.objects.update_or_create(
                    employee_id=account.employee_id,
                    attendance_date=attendance_date,
                    defaults={
                        'status': status,
                        'check_in': timezone.make_aware(datetime.combine(attendance_date, time(9, 15))) if status != 'Absent' else None,
                        'check_out': timezone.make_aware(datetime.combine(attendance_date, time(18, 10))) if status != 'Absent' else None,
                        'working_hours': '08h 30m' if status != 'Absent' else '',
                        'check_in_latitude': '11.6643',
                        'check_in_longitude': '78.1460',
                        'check_in_accuracy': '20',
                        'check_out_latitude': '11.6643',
                        'check_out_longitude': '78.1460',
                        'check_out_accuracy': '20',
                    },
                )
            EmployeeLeaveRequest.objects.update_or_create(
                employee_id=account.employee_id,
                from_date=today + timedelta(days=index),
                to_date=today + timedelta(days=index + 1),
                defaults={
                    'leave_type': ['Sick Leave', 'Casual Leave', 'Annual Leave'][index % 3],
                    'total_days': 2,
                    'reason': 'Dummy leave request for flow testing.',
                    'status': ['pending', 'approved', 'rejected'][index % 3],
                    'tl_status': ['pending', 'approved', 'rejected'][index % 3],
                    'hr_status': ['pending', 'approved', 'rejected'][index % 3],
                    'approved_by': 'Dummy Approver',
                },
            )
            LeaveBalanceLedger.objects.update_or_create(
                employee_id=account.employee_id,
                leave_type='Annual Leave',
                fiscal_year=f'{today.year}-{today.year + 1}',
                defaults={
                    'opening_balance': Decimal('12.00'),
                    'accrued': Decimal('6.00'),
                    'used': Decimal(index % 5),
                    'pending': Decimal(index % 2),
                    'carry_forward': Decimal('1.00'),
                    'available': Decimal('8.00'),
                    'updated_by': 'seed',
                },
            )

    def _seed_payroll(self, accounts, today):
        process, _ = PayrollProcess.objects.update_or_create(
            year=today.year,
            month=today.month,
            defaults={
                'status': 'published',
                'resolved_issues': [{'employee': 'dummy', 'issue': 'Verified'}],
                'publishing_options': {'email': True, 'mobile': True},
                'prepared_by': 'seed',
                'validated_at': timezone.now(),
                'calculated_at': timezone.now(),
                'approved_at': timezone.now(),
                'published_at': timezone.now(),
            },
        )
        for index, account in enumerate(accounts, start=1):
            SalaryStructure.objects.update_or_create(
                employee_id=account.employee_id,
                defaults={
                    'basic_salary': Decimal(35000 + index * 1000),
                    'hra': Decimal(8000),
                    'conveyance_allowance': Decimal(2000),
                    'medical_allowance': Decimal(1500),
                    'special_allowance': Decimal(6000),
                    'pf_employee': Decimal(1800),
                    'professional_tax': Decimal(200),
                    'tds': Decimal(1000),
                    'overtime_rate_per_hour': Decimal(180),
                },
            )
            Payslip.objects.update_or_create(
                employee_id=account.employee_id,
                year=today.year,
                month=today.month,
                defaults={
                    'working_days': 26,
                    'paid_days': 24 + (index % 3),
                    'lop_days': index % 2,
                    'overtime_minutes': 60 * (index % 5),
                    'gross_salary': Decimal(52000 + index * 1000),
                    'total_earnings': Decimal(52000 + index * 1000),
                    'total_deductions': Decimal(3000 + index * 100),
                    'net_salary': Decimal(49000 + index * 900),
                    'earnings': {'basic': 35000, 'hra': 8000, 'special': 6000},
                    'deductions': {'pf': 1800, 'tax': 1000, 'pt': 200},
                    'status': 'paid',
                    'generated_by': 'seed',
                    'paid_date': today,
                },
            )
        return process

    def _seed_notifications(self, users, meetings, tasks):
        for role, user in users.items():
            AppNotification.objects.update_or_create(
                recipient_user_id=user.user_id,
                title=f'Dummy {role.upper()} Notification',
                defaults={
                    'recipient_role': role,
                    'message': f'This is dummy notification data for {role} flow testing.',
                    'notification_type': 'info',
                    'module': 'seed',
                    'reference_id': user.user_id,
                    'is_read': role in ['superadmin', 'ceo'],
                    'push_sent': True,
                },
            )
            MobileDeviceToken.objects.update_or_create(
                token=f'dummy-token-{role}',
                defaults={
                    'user_id': user.user_id,
                    'role': role,
                    'platform': 'android',
                    'is_active': True,
                },
            )

    def _seed_organization(self, users, accounts, today):
        profile, _ = OrganizationProfile.objects.update_or_create(
            owner_user_id=users['superadmin'].user_id,
            defaults={
                'name': 'BitByte Technologies Dummy Pvt Ltd',
                'company_type': 'Private Limited',
                'industry': 'Information Technology',
                'registration_number': 'DUMMY-CIN-2026',
                'founded_on': '2020-01-01',
                'website': 'https://bitbyte.test',
                'email': 'info@bitbyte.test',
                'phone': '+919999999999',
                'address': 'Dummy Tech Park, Salem, Tamil Nadu',
                'pan': 'ABCDE1234F',
                'gstin': '33ABCDE1234F1Z5',
                'documents': [{'type': 'incorporation', 'status': 'verified'}],
            },
        )
        for index, branch in enumerate(['Salem HQ', 'Chennai Branch', 'Bangalore Branch'], start=1):
            OrganizationBranch.objects.update_or_create(
                owner_user_id=profile.owner_user_id,
                name=branch,
                defaults={
                    'city': branch.split()[0],
                    'state': 'Tamil Nadu' if index < 3 else 'Karnataka',
                    'country': 'India',
                    'address': f'{branch} dummy address',
                    'is_head_office': index == 1,
                    'is_active': True,
                },
            )
        for dept_key, dept_name in [
            ('hr', 'HR'),
            ('webapp', 'Web Application Development'),
            ('mobile_app', 'Mobile Application Development'),
            ('digital_marketing', 'Digital Marketing'),
            ('technical_support', 'Technical Support'),
        ]:
            OrganizationDepartment.objects.update_or_create(
                owner_user_id=profile.owner_user_id,
                department_key=dept_key,
                defaults={
                    'name': dept_name,
                    'code': dept_key.upper()[:10],
                    'description': f'Dummy {dept_name} department.',
                    'head_user_id': users['hr'].user_id if dept_key == 'hr' else users['tl'].user_id,
                    'email': f'{dept_key}@bitbyte.test',
                    'phone': '+919000000000',
                    'location': 'Salem',
                    'established_date': today - timedelta(days=365),
                    'is_active': True,
                },
            )
            OrganizationRole.objects.update_or_create(
                owner_user_id=profile.owner_user_id,
                name=f'{dept_name} Lead',
                department=dept_name,
                defaults={
                    'business_unit': 'Technology',
                    'reports_to': 'CEO',
                    'filled_positions': max(1, accounts.filter(department=dept_key).count()) if hasattr(accounts, 'filter') else 1,
                    'vacant_positions': 2,
                    'is_active': True,
                },
            )

    def _seed_extension_modules(self, users, accounts, jobs, meetings, projects, tasks, today, now):
        self._seed_profiles_dashboards_filters(users, accounts)
        self._seed_approvals_budgets(users, today)
        self._seed_performance_snapshots(accounts, today)
        self._seed_meeting_extensions(meetings, accounts)
        self._seed_task_project_extensions(tasks, projects, users, accounts, today)
        self._seed_attendance_extensions(accounts, today)
        self._seed_recruitment_extensions(jobs, users, now)
        self._seed_documents_assets_helpdesk(accounts, users, today)
        self._seed_training_performance_salary_reports(users, accounts, today, now)
        self._seed_announcements_audit(users, now)

    def _seed_profiles_dashboards_filters(self, users, accounts):
        for role, user in users.items():
            UserProfileSetting.objects.update_or_create(
                user_id=user.user_id,
                defaults={
                    'display_name': f'{user.first_name} {user.last_name}'.strip(),
                    'designation': user.occupation,
                    'department': user.department,
                    'phone': user.phone,
                    'alternate_email': user.email,
                    'theme_mode': 'dark' if role in ['ceo', 'tl'] else 'light',
                    'notification_preferences': {'push': True, 'email': True},
                    'privacy_preferences': {'profile_visible': True},
                },
            )
            for widget_key in ['summary', 'attendance', 'tasks', 'approvals']:
                DashboardWidgetSnapshot.objects.update_or_create(
                    owner_user_id=user.user_id,
                    owner_role=role,
                    module='dashboard',
                    widget_key=widget_key,
                    defaults={
                        'title': f'{widget_key.title()} Widget',
                        'value': '12',
                        'subtitle': 'Dummy backend metric',
                        'icon': 'dashboard',
                        'color': 'cyan',
                        'payload': {'count': 12, 'source': 'dummy'},
                    },
                )
            SavedFilterView.objects.update_or_create(
                owner_user_id=user.user_id,
                module='people',
                name='All Active',
                defaults={'filters': {'status': 'active'}, 'sort_by': 'name', 'is_default': True},
            )

    def _seed_approvals_budgets(self, users, today):
        for index, module in enumerate(['leave', 'salary_revision', 'budget', 'recruitment'], start=1):
            WorkflowApprovalRequest.objects.update_or_create(
                module=module,
                reference_id=f'DUMMY-APP-{index:03d}',
                defaults={
                    'title': f'Dummy {module.replace("_", " ").title()} Approval',
                    'requester_user_id': users['hr'].user_id,
                    'requester_name': 'Padma Sheela',
                    'approver_user_id': users['ceo'].user_id,
                    'approver_role': 'ceo',
                    'current_step': index,
                    'status': ['pending', 'approved', 'rejected', 'pending'][index - 1],
                    'priority': ['Low', 'Medium', 'High', 'Urgent'][index - 1],
                    'amount': Decimal(10000 * index),
                    'payload': {'module': module, 'dummy': True},
                },
            )
        for index, dept in enumerate(['HR', 'WebApp', 'Mobile App', 'Digital Marketing'], start=1):
            budget, _ = BudgetPlan.objects.update_or_create(
                owner_user_id=users['ceo'].user_id,
                financial_year=f'{today.year}-{today.year + 1}',
                department=dept,
                category='Operations',
                defaults={
                    'branch': 'Salem HQ',
                    'allocated_amount': Decimal(500000 * index),
                    'spent_amount': Decimal(125000 * index),
                    'committed_amount': Decimal(50000 * index),
                    'status': 'active',
                    'notes': 'Dummy budget plan for load testing.',
                    'payload': {'month': today.month},
                },
            )
            BudgetTransaction.objects.update_or_create(
                budget=budget,
                title=f'{dept} Dummy Expense',
                transaction_date=today - timedelta(days=index),
                defaults={
                    'transaction_type': 'expense',
                    'amount': Decimal(25000 * index),
                    'reference_number': f'BUD-TXN-{index:03d}',
                    'vendor': 'Dummy Vendor',
                    'created_by': users['finance'].user_id,
                },
            )

    def _seed_performance_snapshots(self, accounts, today):
        period = today.strftime('%Y-%m')
        for branch in ['Salem HQ', 'Chennai Branch', 'Bangalore Branch']:
            BranchPerformanceSnapshot.objects.update_or_create(
                branch_name=branch,
                period=period,
                defaults={
                    'total_employees': len(accounts),
                    'active_employees': len(accounts) - 1,
                    'revenue': Decimal('1250000.00'),
                    'expense': Decimal('650000.00'),
                    'attendance_rate': Decimal('86.50'),
                    'productivity_rate': Decimal('82.00'),
                    'change_percent': Decimal('4.25'),
                    'payload': {'source': 'dummy'},
                },
            )
        for dept in ['HR', 'WebApp', 'Mobile App', 'Digital Marketing']:
            DepartmentPerformanceSnapshot.objects.update_or_create(
                department=dept,
                period=period,
                defaults={
                    'total_employees': 5,
                    'present_count': 4,
                    'absent_count': 1,
                    'late_count': 1,
                    'leave_count': 1,
                    'task_completion_rate': Decimal('78.00'),
                    'performance_score': Decimal('84.00'),
                    'payload': {'trend': [70, 75, 82, 84]},
                },
            )

    def _seed_meeting_extensions(self, meetings, accounts):
        for meeting in meetings:
            for account in accounts[:5]:
                MeetingParticipantStatus.objects.update_or_create(
                    meeting=meeting,
                    participant_user_id=account.employee_id,
                    defaults={
                        'participant_name': f'{account.registration.first_name} {account.registration.last_name}',
                        'participant_email': account.employee_email,
                        'status': 'accepted',
                        'response_note': 'Dummy accepted response.',
                        'responded_at': timezone.now(),
                        'notification_sent': True,
                    },
                )
            MeetingMinute.objects.update_or_create(
                meeting=meeting,
                title=f'{meeting.title} Minutes',
                defaults={
                    'notes': 'Dummy meeting minutes and decisions.',
                    'action_items': [{'title': 'Follow up task', 'owner': 'TL', 'status': 'open'}],
                    'recorded_by': 'seed',
                },
            )

    def _seed_task_project_extensions(self, tasks, projects, users, accounts, today):
        for task in tasks[:10]:
            TaskComment.objects.update_or_create(
                task=task,
                author_user_id=users['tl'].user_id,
                comment='Dummy task progress comment.',
                defaults={
                    'author_name': 'Jai Ramachandran',
                    'attachments': [{'name': 'dummy-note.txt'}],
                },
            )
            TaskChecklistItem.objects.update_or_create(
                task=task,
                title='Dummy checklist item',
                defaults={
                    'is_completed': task.status == 'completed',
                    'completed_by': task.assignee_id if task.status == 'completed' else '',
                    'completed_at': timezone.now() if task.status == 'completed' else None,
                    'sort_order': 1,
                },
            )
        for project in projects:
            ProjectIssue.objects.update_or_create(
                project=project,
                title=f'{project.name} Dummy Issue',
                defaults={
                    'description': 'Dummy issue for project issue flow.',
                    'owner_user_id': users['tl'].user_id,
                    'priority': 'High',
                    'status': 'open',
                    'due_date': today + timedelta(days=7),
                    'created_by': users['ceo'].user_id,
                },
            )
            ProjectExpense.objects.update_or_create(
                project=project,
                title=f'{project.name} Dummy Expense',
                expense_date=today - timedelta(days=2),
                defaults={
                    'category': 'Software',
                    'amount': Decimal('35000.00'),
                    'vendor': 'Dummy Software Vendor',
                    'approved_by': users['ceo'].user_id,
                    'created_by': users['tl'].user_id,
                },
            )

    def _seed_attendance_extensions(self, accounts, today):
        for index, account in enumerate(accounts[:8], start=1):
            AttendanceRegularizationRequest.objects.update_or_create(
                employee_id=account.employee_id,
                attendance_date=today - timedelta(days=index),
                defaults={
                    'request_type': 'missed_checkout',
                    'requested_check_in': timezone.make_aware(datetime.combine(today - timedelta(days=index), time(9, 10))),
                    'requested_check_out': timezone.make_aware(datetime.combine(today - timedelta(days=index), time(18, 20))),
                    'reason': 'Dummy regularization request.',
                    'status': ['pending', 'approved', 'rejected'][index % 3],
                    'reviewed_by': 'HR',
                    'reviewed_at': timezone.now(),
                    'review_note': 'Dummy review note.',
                },
            )
            OvertimeRequest.objects.update_or_create(
                employee_id=account.employee_id,
                overtime_date=today - timedelta(days=index),
                defaults={
                    'start_time': timezone.make_aware(datetime.combine(today - timedelta(days=index), time(18, 30))),
                    'end_time': timezone.make_aware(datetime.combine(today - timedelta(days=index), time(20, 30))),
                    'total_minutes': 120,
                    'reason': 'Dummy release support.',
                    'status': ['pending', 'approved', 'paid'][index % 3],
                    'approved_by': 'TL',
                    'approved_at': timezone.now(),
                    'payroll_month': today.month,
                    'payroll_year': today.year,
                },
            )
            ShiftSchedule.objects.update_or_create(
                employee_id=account.employee_id,
                shift_date=today + timedelta(days=index),
                defaults={
                    'shift_name': 'General Shift',
                    'start_time': time(9, 0),
                    'end_time': time(18, 0),
                    'work_mode': ['onsite', 'hybrid', 'work_from_home'][index % 3],
                    'location': 'Salem',
                    'assigned_by': 'seed',
                },
            )

    def _seed_recruitment_extensions(self, jobs, users, now):
        for index, job in enumerate(jobs, start=1):
            candidate, _ = RecruitmentCandidatePipeline.objects.update_or_create(
                job=job,
                candidate_email=f'candidate{index:02d}@bitbyte.test',
                defaults={
                    'candidate_name': f'Dummy Candidate {index:02d}',
                    'candidate_phone': f'6{index:09d}'[-10:],
                    'source': 'LinkedIn',
                    'status': ['applied', 'screening', 'interview', 'offered'][index % 4],
                    'score': Decimal(70 + index),
                    'current_stage': 'Technical Round',
                    'notes': 'Dummy recruitment candidate.',
                    'assigned_to': users['hr'].user_id,
                },
            )
            InterviewSchedule.objects.update_or_create(
                candidate=candidate,
                interviewer_user_id=users['tl'].user_id,
                scheduled_at=now + timedelta(days=index),
                defaults={
                    'interviewer_name': 'Jai Ramachandran',
                    'duration_minutes': 45,
                    'mode': 'online',
                    'location_or_link': f'https://meet.bitbyte.in/interview-{index}',
                    'status': 'scheduled',
                    'feedback': {'technical': 'pending'},
                    'created_by': users['hr'].user_id,
                },
            )

    def _seed_documents_assets_helpdesk(self, accounts, users, today):
        for index, account in enumerate(accounts[:10], start=1):
            OnboardingTask.objects.update_or_create(
                employee_id=account.employee_id,
                title='Dummy Onboarding Checklist',
                defaults={
                    'category': 'Joining',
                    'owner_user_id': users['hr'].user_id,
                    'due_date': today + timedelta(days=index),
                    'status': ['pending', 'in_progress', 'completed'][index % 3],
                    'checklist': [{'title': 'Create email', 'done': True}, {'title': 'Assign laptop', 'done': index % 2 == 0}],
                    'completed_at': timezone.now() if index % 3 == 2 else None,
                },
            )
            DocumentRecord.objects.update_or_create(
                owner_user_id=account.employee_id,
                document_type='Aadhar',
                defaults={
                    'owner_role': 'employee',
                    'document_number': f'{index:012d}'[-12:],
                    'expiry_date': None,
                    'status': 'verified',
                    'verified_by': users['hr'].user_id,
                    'verified_at': timezone.now(),
                    'remarks': 'Dummy verified document.',
                    'metadata': {'source': 'seed'},
                },
            )
            AssetInventory.objects.update_or_create(
                asset_code=f'BB-LAP-{index:04d}',
                defaults={
                    'asset_name': f'Dummy Laptop {index:02d}',
                    'category': 'Laptop',
                    'serial_number': f'DUMMY-SN-{index:04d}',
                    'purchase_date': today - timedelta(days=120),
                    'purchase_cost': Decimal('55000.00'),
                    'assigned_to': account.employee_id,
                    'assigned_at': today - timedelta(days=30),
                    'location': 'Salem',
                    'status': 'assigned',
                    'notes': 'Dummy asset for asset module.',
                },
            )
            HelpdeskTicket.objects.update_or_create(
                ticket_no=f'BB-TCK-{index:04d}',
                defaults={
                    'requester_user_id': account.employee_id,
                    'assigned_to': users['it'].user_id,
                    'category': 'IT',
                    'subject': f'Dummy Laptop Support {index:02d}',
                    'description': 'Dummy helpdesk ticket for flow testing.',
                    'priority': ['Low', 'Medium', 'High'][index % 3],
                    'status': ['open', 'in_progress', 'resolved'][index % 3],
                    'attachments': [],
                    'resolution_note': 'Dummy resolution note.',
                    'resolved_at': timezone.now() if index % 3 == 2 else None,
                },
            )

    def _seed_training_performance_salary_reports(self, users, accounts, today, now):
        program, _ = TrainingProgram.objects.update_or_create(
            title='Dummy Flutter + Django Training',
            defaults={
                'description': 'Dummy training program for employee learning flow.',
                'trainer': 'Internal Trainer',
                'department': 'Technology',
                'start_date': today + timedelta(days=3),
                'end_date': today + timedelta(days=8),
                'location_or_link': 'https://learn.bitbyte.test/dummy',
                'status': 'scheduled',
                'materials': [{'title': 'Dummy PDF'}],
                'created_by': users['hr'].user_id,
            },
        )
        cycle, _ = PerformanceReviewCycle.objects.update_or_create(
            period=f'{today.year}-H1',
            defaults={
                'name': f'{today.year} Half Yearly Review',
                'start_date': date(today.year, 1, 1),
                'end_date': date(today.year, 6, 30),
                'status': 'active',
                'review_template': {'rating_scale': 5},
                'created_by': users['hr'].user_id,
            },
        )
        for index, account in enumerate(accounts, start=1):
            TrainingEnrollment.objects.update_or_create(
                program=program,
                employee_id=account.employee_id,
                defaults={
                    'status': ['enrolled', 'in_progress', 'completed'][index % 3],
                    'progress_percent': min(100, index * 7),
                    'score': Decimal(60 + index),
                    'feedback': 'Dummy training feedback.',
                    'completed_at': now if index % 3 == 2 else None,
                },
            )
            EmployeePerformance.objects.update_or_create(
                employee_id=account.employee_id,
                period=today.strftime('%Y-%m'),
                defaults={
                    'goals': [{'title': 'Complete assigned tasks', 'status': 'in_progress'}],
                    'kpis': {'task_completion': 80 + (index % 10), 'attendance': 85},
                    'potential_score': Decimal('4.00'),
                    'performance_score': Decimal('4.20'),
                    'competency_scores': {'communication': 4, 'delivery': 4},
                    'reviewer_comments': 'Dummy performance review.',
                    'status': 'reviewed',
                    'reviewed_by': users['tl'].user_id,
                    'reviewed_at': now,
                },
            )
            EmployeeGoal.objects.update_or_create(
                employee_id=account.employee_id,
                cycle=cycle,
                title='Dummy Delivery Goal',
                defaults={
                    'description': 'Complete module work with quality.',
                    'weightage': Decimal('40.00'),
                    'target_value': '100%',
                    'achieved_value': '82%',
                    'status': 'in_progress',
                    'manager_rating': Decimal('4.00'),
                    'employee_comment': 'Dummy employee self comment.',
                    'manager_comment': 'Dummy manager comment.',
                },
            )
            SalaryRevisionRequest.objects.update_or_create(
                employee_id=account.employee_id,
                effective_from=today + timedelta(days=30),
                defaults={
                    'current_ctc': Decimal(420000 + index * 10000),
                    'proposed_ctc': Decimal(480000 + index * 12000),
                    'reason': 'Dummy appraisal salary revision.',
                    'status': ['pending', 'approved', 'rejected'][index % 3],
                    'requested_by': users['hr'].user_id,
                    'approved_by': users['ceo'].user_id,
                    'approved_at': now if index % 3 == 1 else None,
                },
            )
        ReportSchedule.objects.update_or_create(
            owner_user_id=users['ceo'].user_id,
            report_type='attendance_summary',
            defaults={
                'filters': {'period': today.strftime('%Y-%m')},
                'format': 'pdf',
                'frequency': 'weekly',
                'recipients': [users['ceo'].email, users['hr'].email],
                'is_active': True,
                'last_generated_at': now,
            },
        )
        ReportExportHistory.objects.update_or_create(
            requested_by=users['ceo'].user_id,
            report_type='attendance_summary',
            file_format='pdf',
            defaults={
                'filters': {'period': today.strftime('%Y-%m')},
                'status': 'completed',
                'generated_at': now,
            },
        )

    def _seed_announcements_audit(self, users, now):
        Announcement.objects.update_or_create(
            title='Dummy Company Announcement',
            defaults={
                'message': 'This is a dummy announcement for notification and announcement flow testing.',
                'target_roles': ['employee', 'tl', 'hr'],
                'target_user_ids': [],
                'status': 'published',
                'publish_at': now,
                'expires_at': now + timedelta(days=30),
                'created_by': users['hr'].user_id,
            },
        )
        AuditLog.objects.update_or_create(
            actor_user_id=users['superadmin'].user_id,
            module='seed',
            action='seed_dummy_data',
            reference_id='DUMMY-SEED',
            defaults={
                'actor_role': 'superadmin',
                'before': {},
                'after': {'status': 'seeded'},
                'ip_address': '127.0.0.1',
                'user_agent': 'Django management command',
            },
        )
