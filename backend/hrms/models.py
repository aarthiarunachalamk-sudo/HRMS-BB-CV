from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from cloudinary.models import CloudinaryField
import random
import re
import string


ROLE_ID_PREFIXES = {
    'superadmin': 'BBSA',
    'ceo': 'BBCEO',
    'md': 'BBMD',
    'director': 'BBDIR',
    'hr': 'BBHR',
    'finance': 'BBFIN',
    'marketing': 'BBMKT',
    'it': 'BBIT',
    'admin': 'BBADM',
    'manager': 'BBMGR',
    'tl': 'BBTL',
    'employee': 'BBEMP',
}

ROLE_ID_WIDTHS = {
    'employee': 5,
}

EMPLOYEE_DEPARTMENT_ID_PREFIXES = {
    'web_application_development': 'BBEWEB',
    'mobile_application_development': 'BBEMOB',
    'marketing': 'BBEMKT',
    'digital_marketing': 'BBEDM',
    'technical_support': 'BBETS',
    'management': 'BBEMGT',
    'internship_trainee': 'BBEINT',
    # Legacy department values kept so old records/forms continue to work.
    'hr': 'BBEHR',
    'webapp': 'BBEWEB',
    'mobile_app': 'BBEMOB',
    'sales': 'BBESAL',
}


def next_prefixed_id(model, field_name, prefix, width=4):
    existing_ids = model.objects.filter(
        **{f'{field_name}__startswith': prefix},
    ).values_list(field_name, flat=True)
    highest = 0
    pattern = re.compile(rf'^{re.escape(prefix)}(\d+)$')
    for value in existing_ids:
        match = pattern.match(value or '')
        if match:
            highest = max(highest, int(match.group(1)))

    candidate = highest + 1
    while model.objects.filter(
        **{field_name: f'{prefix}{candidate:0{width}d}'},
    ).exists():
        candidate += 1
    return f'{prefix}{candidate:0{width}d}'


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, role='employee'):
        user = self.model(email=email, role=role)
        user.set_password(password)
        user.save(using=self._db)
        return user


class User(AbstractBaseUser):
    ROLE_CHOICES = [
        ('superadmin', 'Super Admin'),
        ('ceo', 'CEO'),
        ('md', 'MD'),
        ('director', 'Executive Director'),
        ('hr', 'HR'),
        ('finance', 'Finance'),
        ('marketing', 'Marketing Team'),
        ('it', 'IT Team'),
        ('admin', 'Admin'),
        ('manager', 'Manager'),
        ('tl', 'TL'),
        ('employee', 'Employee'),
    ]

    GENDER_CHOICES = [('male', 'Male'), ('female', 'Female'), ('other', 'Other')]
    WORK_MODE_CHOICES = [
        ('work_from_home', 'Work From Home'),
        ('hybrid', 'Hybrid'),
        ('onsite', 'OnSite'),
    ]

    email = models.EmailField(db_index=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='employee')
    is_active = models.BooleanField(default=True)
    user_id = models.CharField(max_length=20, unique=True, blank=True)

    first_name = models.CharField(max_length=50, blank=True)
    last_name = models.CharField(max_length=50, blank=True)
    country_code = models.CharField(max_length=5, default='+91')
    phone = models.CharField(max_length=15, blank=True)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True)
    dob = models.DateField(null=True, blank=True)

    door_no = models.CharField(max_length=20, blank=True)
    street = models.CharField(max_length=100, blank=True)
    pincode = models.CharField(max_length=10, blank=True)
    city = models.CharField(max_length=50, blank=True)
    state = models.CharField(max_length=50, blank=True)
    department = models.CharField(max_length=50, blank=True)
    work_mode = models.CharField(max_length=20, choices=WORK_MODE_CHOICES, default='onsite')

    occupation = models.CharField(max_length=50, blank=True)
    created_by = models.CharField(max_length=40, blank=True, db_index=True)
    pan = models.CharField(max_length=10, blank=True)
    aadhar = models.CharField(max_length=12, blank=True)

    USERNAME_FIELD = 'user_id'
    objects = UserManager()

    def save(self, *args, **kwargs):
        if not self.user_id:
            prefix = ROLE_ID_PREFIXES.get(self.role, f'BB{self.role.upper()}')
            width = ROLE_ID_WIDTHS.get(self.role, 4)
            self.user_id = next_prefixed_id(User, 'user_id', prefix, width)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.email


class RecruitmentJobOpening(models.Model):
    STATUS_CHOICES = [('open', 'Open'), ('paused', 'Paused'), ('closed', 'Closed')]
    title = models.CharField(max_length=140)
    department = models.CharField(max_length=100)
    location = models.CharField(max_length=120, blank=True)
    openings = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class EmployeeRegistration(models.Model):
    GENDER_CHOICES = [('male', 'Male'), ('female', 'Female'), ('other', 'Other')]
    MARITAL_CHOICES = [('single', 'Single'), ('married', 'Married'), ('other', 'Other')]
    BLOOD_CHOICES = [
        ('A+', 'A+'), ('A-', 'A-'), ('B+', 'B+'), ('B-', 'B-'),
        ('O+', 'O+'), ('O-', 'O-'), ('AB+', 'AB+'), ('AB-', 'AB-'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('flagged', 'Flagged'),
    ]

    # Personal
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES)
    dob = models.CharField(max_length=20)
    mobile = models.CharField(max_length=10)
    personal_email = models.EmailField()
    marital_status = models.CharField(max_length=20, choices=MARITAL_CHOICES)
    marital_other = models.CharField(max_length=50, blank=True)
    blood_group = models.CharField(max_length=5, choices=BLOOD_CHOICES)
    nationality = models.CharField(max_length=50)

    # Address
    current_door = models.CharField(max_length=20, blank=True)
    current_street = models.CharField(max_length=100, blank=True)
    current_address2 = models.CharField(max_length=100, blank=True)
    current_city = models.CharField(max_length=50)
    current_state = models.CharField(max_length=50)
    permanent_door = models.CharField(max_length=20, blank=True)
    permanent_street = models.CharField(max_length=100, blank=True)
    permanent_address2 = models.CharField(max_length=100, blank=True)
    permanent_city = models.CharField(max_length=50)
    permanent_state = models.CharField(max_length=50)

    # Emergency
    emergency_name = models.CharField(max_length=50)
    emergency_relationship = models.CharField(max_length=50)
    emergency_contact = models.CharField(max_length=10)

    # Identity
    aadhar = models.CharField(max_length=12)
    pan = models.CharField(max_length=10)
    passport = models.CharField(max_length=20, blank=True)
    driving_license = models.CharField(max_length=20, blank=True)

    # Education
    qualification = models.CharField(max_length=100)
    college = models.CharField(max_length=100)
    year_of_passing = models.CharField(max_length=4)
    percentage = models.CharField(max_length=30)

    # Bank
    account_holder = models.CharField(max_length=100)
    bank_name = models.CharField(max_length=100)
    account_number = models.CharField(max_length=20)
    ifsc_code = models.CharField(max_length=11)
    branch_name = models.CharField(max_length=100)

    # Employment Type
    is_experienced = models.BooleanField(default=False)

    # Previous Employment
    prev_company = models.CharField(max_length=100, blank=True)
    prev_designation = models.CharField(max_length=100, blank=True)
    prev_experience = models.CharField(max_length=10, blank=True)
    prev_last_working_day = models.CharField(max_length=20, blank=True)

    # Documents
    doc_passport_photo = CloudinaryField('image', blank=True, null=True)
    doc_aadhar = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_pan = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_bank_passbook = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_10th = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_12th = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_degree = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_consolidated = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_college_noc = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_resume = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_experience_cert = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_relieving = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_salary_slips = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_passport_copy = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_driving = CloudinaryField('file', resource_type='auto', blank=True, null=True)
    doc_vaccination = CloudinaryField('file', resource_type='auto', blank=True, null=True)

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    document_statuses = models.JSONField(default=dict, blank=True)
    document_review_history = models.JSONField(default=list, blank=True)
    submitted_at = models.DateTimeField(auto_now_add=True)
    applied_job = models.ForeignKey(
        RecruitmentJobOpening,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='candidates',
    )
    recruitment_stage = models.CharField(max_length=30, default='applied', db_index=True)
    interview_data = models.JSONField(default=dict, blank=True)
    offer_data = models.JSONField(default=dict, blank=True)
    onboarding_checklist = models.JSONField(default=dict, blank=True)

    def __str__(self):
        return f'{self.first_name} {self.last_name}'


class EmployeeAccount(models.Model):
    DEPARTMENT_CHOICES = [
        ('web_application_development', 'Web Application Development'),
        ('mobile_application_development', 'Mobile Application Development'),
        ('marketing', 'Marketing'),
        ('digital_marketing', 'Digital Marketing'),
        ('technical_support', 'Technical Support'),
        ('management', 'Management'),
        ('internship_trainee', 'Internship / Trainee'),
        ('hr', 'HR'),
        ('webapp', 'WebApp'),
        ('mobile_app', 'Mobile App'),
        ('sales', 'Sales'),
    ]
    DESIGNATION_CHOICES = [
        ('associate', 'Associate'),
        ('intern', 'Intern'),
        ('tl', 'TL'),
        ('admin', 'Admin'),
        ('hr', 'HR'),
        ('ceo', 'CEO'),
        ('md', 'MD'),
        ('director', 'Executive Director'),
        ('manager', 'Manager'),
    ]
    EMPLOYMENT_TYPE_CHOICES = [
        ('full_time', 'Full Time'),
        ('part_time', 'Part Time'),
    ]

    registration = models.OneToOneField(EmployeeRegistration, on_delete=models.CASCADE, related_name='account')
    # Optional direct link for role-based users who also participate as employees.
    # Existing employee accounts continue to resolve through email/user_id.
    user = models.OneToOneField(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='employee_account',
    )
    employee_id = models.CharField(max_length=20, unique=True, blank=True)
    employee_email = models.EmailField(unique=True)
    department = models.CharField(max_length=50, choices=DEPARTMENT_CHOICES)
    designation = models.CharField(max_length=50, choices=DESIGNATION_CHOICES)
    date_of_joining = models.DateField()
    employment_type = models.CharField(max_length=20, choices=EMPLOYMENT_TYPE_CHOICES)
    reporting_tl = models.CharField(max_length=100, blank=True)
    work_location = models.CharField(max_length=100, blank=True)
    otc = models.CharField(max_length=10, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.employee_id:
            prefix = EMPLOYEE_DEPARTMENT_ID_PREFIXES.get(self.department, 'BBEMP')
            self.employee_id = next_prefixed_id(EmployeeAccount, 'employee_id', prefix, 5)
        if not self.otc:
            self.otc = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        super().save(*args, **kwargs)

    def __str__(self):
        return self.employee_id


class MdMeeting(models.Model):
    STATUS_CHOICES = [
        ('upcoming', 'Upcoming'),
        ('past', 'Past'),
        ('cancelled', 'Cancelled'),
    ]

    title = models.CharField(max_length=120)
    meeting_type = models.CharField(max_length=80, blank=True)
    location = models.CharField(max_length=120, blank=True)
    description = models.TextField(blank=True)
    date_label = models.CharField(max_length=40, blank=True)
    time_label = models.CharField(max_length=60, blank=True)
    duration = models.CharField(max_length=40, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='upcoming')
    participants = models.JSONField(default=list, blank=True)
    agenda = models.JSONField(default=list, blank=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class TeamTask(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
    ]
    PRIORITY_CHOICES = [
        ('Low', 'Low'),
        ('Medium', 'Medium'),
        ('High', 'High'),
        ('Urgent', 'Urgent'),
    ]

    title = models.CharField(max_length=160)
    project = models.CharField(max_length=120, blank=True)
    assignee_id = models.CharField(max_length=20, blank=True, db_index=True)
    assignee_name = models.CharField(max_length=120, blank=True)
    assignee_email = models.EmailField(blank=True)
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='Medium')
    due_date = models.CharField(max_length=40, blank=True)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_by = models.CharField(max_length=80, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class Project(models.Model):
    STATUS_CHOICES = [
        ('not_started', 'Not Started'), ('in_progress', 'In Progress'),
        ('on_hold', 'On Hold'), ('at_risk', 'At Risk'), ('completed', 'Completed'),
    ]
    name = models.CharField(max_length=160)
    code = models.CharField(max_length=40, unique=True)
    department = models.CharField(max_length=120, blank=True)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='not_started')
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    budget = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    spent = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    progress = models.PositiveIntegerField(default=0)
    manager_id = models.CharField(max_length=40, blank=True)
    manager_name = models.CharField(max_length=120, blank=True)
    manager_email = models.EmailField(blank=True)
    team = models.JSONField(default=list, blank=True)
    milestones = models.JSONField(default=list, blank=True)
    progress_history = models.JSONField(default=list, blank=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return self.name


class EmployeePerformance(models.Model):
    employee_id = models.CharField(max_length=20, db_index=True)
    period = models.CharField(max_length=40, db_index=True)
    goals = models.JSONField(default=list, blank=True)
    kpis = models.JSONField(default=dict, blank=True)
    potential_score = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    performance_score = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    competency_scores = models.JSONField(default=dict, blank=True)
    reviewer_comments = models.TextField(blank=True)
    status = models.CharField(max_length=20, default='draft')
    reviewed_by = models.CharField(max_length=40, blank=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('employee_id', 'period')
        ordering = ['-updated_at']


class ReportSchedule(models.Model):
    owner_user_id = models.CharField(max_length=40, db_index=True)
    report_type = models.CharField(max_length=80)
    filters = models.JSONField(default=dict, blank=True)
    format = models.CharField(max_length=10, default='pdf')
    frequency = models.CharField(max_length=30, default='once')
    recipients = models.JSONField(default=list, blank=True)
    is_active = models.BooleanField(default=True)
    last_generated_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class EmployeeAttendanceRecord(models.Model):
    WORK_MODE_CHOICES = [
        ('office', 'Office'),
        ('work_from_home', 'Work From Home'),
        ('hybrid', 'Hybrid'),
    ]

    employee_id = models.CharField(max_length=20, db_index=True)
    attendance_date = models.DateField(db_index=True)
    work_mode = models.CharField(
        max_length=20,
        choices=WORK_MODE_CHOICES,
        default='office',
    )
    status = models.CharField(max_length=20, default='Present')
    check_in = models.DateTimeField(null=True, blank=True)
    check_out = models.DateTimeField(null=True, blank=True)
    check_in_timezone_offset_minutes = models.IntegerField(null=True, blank=True)
    check_out_timezone_offset_minutes = models.IntegerField(null=True, blank=True)
    working_hours = models.CharField(max_length=20, blank=True)
    check_in_latitude = models.CharField(max_length=40, blank=True)
    check_in_longitude = models.CharField(max_length=40, blank=True)
    check_in_accuracy = models.CharField(max_length=40, blank=True)
    check_out_latitude = models.CharField(max_length=40, blank=True)
    check_out_longitude = models.CharField(max_length=40, blank=True)
    check_out_accuracy = models.CharField(max_length=40, blank=True)
    check_in_selfie = models.FileField(upload_to='attendance/check_in/', blank=True, null=True)
    check_out_selfie = models.FileField(upload_to='attendance/check_out/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('employee_id', 'attendance_date')
        ordering = ['-attendance_date']

    def __str__(self):
        return f'{self.employee_id} - {self.attendance_date}'


class EmployeeLeaveRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    employee_id = models.CharField(max_length=20, db_index=True)
    leave_type = models.CharField(max_length=50)
    session = models.CharField(max_length=20, default='Full Day')
    from_date = models.DateField(db_index=True)
    to_date = models.DateField(db_index=True)
    total_days = models.DecimalField(max_digits=5, decimal_places=2, default=1)
    reason = models.TextField(blank=True)
    medical_certificate = models.FileField(upload_to='leave_certificates/', blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    tl_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    hr_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    approved_by = models.CharField(max_length=100, blank=True)
    tl_approved_by = models.CharField(max_length=100, blank=True)
    hr_approved_by = models.CharField(max_length=100, blank=True)
    tl_reviewed_at = models.DateTimeField(null=True, blank=True)
    hr_reviewed_at = models.DateTimeField(null=True, blank=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-from_date']

    def __str__(self):
        return f'{self.employee_id} - {self.leave_type} ({self.status})'


class SalaryStructure(models.Model):
    employee_id = models.CharField(max_length=20, unique=True, db_index=True)
    basic_salary = models.DecimalField(max_digits=10, decimal_places=2, default=40000)
    hra = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    conveyance_allowance = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    medical_allowance = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    special_allowance = models.DecimalField(max_digits=10, decimal_places=2, default=8000)
    other_allowance = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    pf_employee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    esi_employee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    professional_tax = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    tds = models.DecimalField(max_digits=10, decimal_places=2, default=2000)
    other_deduction = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    overtime_rate_per_hour = models.DecimalField(max_digits=10, decimal_places=2, default=150)
    performance_incentive_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=10,
    )
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.employee_id


class Payslip(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('approved', 'Approved'),
        ('paid', 'Paid'),
    ]

    employee_id = models.CharField(max_length=20, db_index=True)
    year = models.PositiveIntegerField()
    month = models.PositiveIntegerField()
    working_days = models.PositiveIntegerField(default=0)
    paid_days = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    lop_days = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    overtime_minutes = models.PositiveIntegerField(default=0)
    performance_score = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    performance_incentive = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    gross_salary = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_earnings = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_deductions = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    net_salary = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    earnings = models.JSONField(default=dict, blank=True)
    deductions = models.JSONField(default=dict, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='approved')
    generated_by = models.CharField(max_length=80, blank=True)
    paid_date = models.DateField(null=True, blank=True)
    pdf_file = models.FileField(upload_to='payslips/', blank=True, null=True)
    generated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('employee_id', 'year', 'month')
        ordering = ['-year', '-month']

    def __str__(self):
        return f'{self.employee_id} - {self.year}-{self.month:02d}'


class PayrollProcess(models.Model):
    STATUS_CHOICES = [
        ('inputs', 'Inputs'),
        ('validation', 'Validation'),
        ('calculation', 'Calculation'),
        ('approval', 'Approval'),
        ('published', 'Published'),
    ]

    year = models.PositiveIntegerField()
    month = models.PositiveIntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='inputs')
    resolved_issues = models.JSONField(default=list, blank=True)
    publishing_options = models.JSONField(default=dict, blank=True)
    prepared_by = models.CharField(max_length=80, blank=True)
    validated_at = models.DateTimeField(null=True, blank=True)
    calculated_at = models.DateTimeField(null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    published_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('year', 'month')
        ordering = ['-year', '-month']

    def __str__(self):
        return f'Payroll {self.year}-{self.month:02d} ({self.status})'


class AppNotification(models.Model):
    TYPE_CHOICES = [
        ('info', 'Info'),
        ('success', 'Success'),
        ('warning', 'Warning'),
        ('error', 'Error'),
    ]

    recipient_user_id = models.CharField(max_length=40, blank=True, db_index=True)
    recipient_role = models.CharField(max_length=30, blank=True, db_index=True)
    title = models.CharField(max_length=120)
    message = models.TextField(blank=True)
    notification_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='info')
    module = models.CharField(max_length=40, blank=True)
    reference_id = models.CharField(max_length=40, blank=True)
    is_read = models.BooleanField(default=False)
    push_sent = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        target = self.recipient_user_id or self.recipient_role or 'all'
        return f'{target} - {self.title}'


class MobileDeviceToken(models.Model):
    user_id = models.CharField(max_length=40, db_index=True)
    role = models.CharField(max_length=30, blank=True)
    token = models.TextField(unique=True)
    platform = models.CharField(max_length=20, blank=True)
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return f'{self.user_id} - {self.platform}'


class OrganizationProfile(models.Model):
    owner_user_id = models.CharField(max_length=40, unique=True, db_index=True)
    name = models.CharField(max_length=160)
    company_type = models.CharField(max_length=80, blank=True)
    industry = models.CharField(max_length=120, blank=True)
    registration_number = models.CharField(max_length=100, blank=True)
    founded_on = models.CharField(max_length=40, blank=True)
    website = models.URLField(blank=True)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    pan = models.CharField(max_length=20, blank=True)
    gstin = models.CharField(max_length=30, blank=True)
    esi_number = models.CharField(max_length=40, blank=True)
    pf_code = models.CharField(max_length=40, blank=True)
    documents = models.JSONField(default=list, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class OrganizationBranch(models.Model):
    owner_user_id = models.CharField(max_length=40, db_index=True)
    name = models.CharField(max_length=140)
    city = models.CharField(max_length=80)
    state = models.CharField(max_length=80, blank=True)
    country = models.CharField(max_length=80, blank=True)
    address = models.TextField(blank=True)
    is_head_office = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('owner_user_id', 'name')
        ordering = ['-is_head_office', 'name']

    def __str__(self):
        return self.name


class OrganizationRole(models.Model):
    owner_user_id = models.CharField(max_length=40, db_index=True)
    name = models.CharField(max_length=120)
    business_unit = models.CharField(max_length=120, blank=True)
    department = models.CharField(max_length=120, blank=True)
    reports_to = models.CharField(max_length=120, blank=True)
    filled_positions = models.PositiveIntegerField(default=0)
    vacant_positions = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('owner_user_id', 'name', 'department')
        ordering = ['name']

    def __str__(self):
        return self.name


class OrganizationDepartment(models.Model):
    owner_user_id = models.CharField(max_length=40, db_index=True)
    department_key = models.CharField(max_length=100)
    name = models.CharField(max_length=140)
    code = models.CharField(max_length=20)
    description = models.TextField(blank=True)
    head_user_id = models.CharField(max_length=40, blank=True)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    location = models.CharField(max_length=160, blank=True)
    established_date = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = (
            ('owner_user_id', 'department_key'),
            ('owner_user_id', 'code'),
        )
        ordering = ['name']

    def __str__(self):
        return self.name


# ---------------------------------------------------------------------------
# HRMS module extension tables
# Existing models above are intentionally left unchanged. The models below add
# storage for the remaining mobile app module flows so every screen can read
# from the live database instead of static/frontend fallback data.
# ---------------------------------------------------------------------------


class UserProfileSetting(models.Model):
    THEME_CHOICES = [
        ('system', 'System'),
        ('light', 'Light'),
        ('dark', 'Dark'),
    ]

    user_id = models.CharField(max_length=40, unique=True, db_index=True)
    display_name = models.CharField(max_length=140, blank=True)
    avatar = CloudinaryField('image', blank=True, null=True)
    designation = models.CharField(max_length=120, blank=True)
    department = models.CharField(max_length=120, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    alternate_email = models.EmailField(blank=True)
    theme_mode = models.CharField(max_length=20, choices=THEME_CHOICES, default='system')
    language = models.CharField(max_length=20, default='en')
    timezone = models.CharField(max_length=60, default='Asia/Kolkata')
    notification_preferences = models.JSONField(default=dict, blank=True)
    privacy_preferences = models.JSONField(default=dict, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.display_name or self.user_id


class DashboardWidgetSnapshot(models.Model):
    owner_user_id = models.CharField(max_length=40, db_index=True)
    owner_role = models.CharField(max_length=30, db_index=True)
    module = models.CharField(max_length=80, db_index=True)
    widget_key = models.CharField(max_length=100)
    title = models.CharField(max_length=160)
    value = models.CharField(max_length=80, blank=True)
    subtitle = models.CharField(max_length=200, blank=True)
    icon = models.CharField(max_length=80, blank=True)
    color = models.CharField(max_length=40, blank=True)
    filters = models.JSONField(default=dict, blank=True)
    payload = models.JSONField(default=dict, blank=True)
    captured_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('owner_user_id', 'owner_role', 'module', 'widget_key')
        ordering = ['module', 'widget_key']

    def __str__(self):
        return f'{self.owner_role} - {self.title}'


class SavedFilterView(models.Model):
    owner_user_id = models.CharField(max_length=40, db_index=True)
    module = models.CharField(max_length=80, db_index=True)
    name = models.CharField(max_length=120)
    filters = models.JSONField(default=dict, blank=True)
    sort_by = models.CharField(max_length=80, blank=True)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('owner_user_id', 'module', 'name')
        ordering = ['module', 'name']

    def __str__(self):
        return f'{self.module} - {self.name}'


class WorkflowApprovalRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('cancelled', 'Cancelled'),
    ]

    module = models.CharField(max_length=80, db_index=True)
    reference_id = models.CharField(max_length=60, db_index=True)
    title = models.CharField(max_length=160)
    requester_user_id = models.CharField(max_length=40, db_index=True)
    requester_name = models.CharField(max_length=140, blank=True)
    approver_user_id = models.CharField(max_length=40, blank=True, db_index=True)
    approver_role = models.CharField(max_length=30, blank=True, db_index=True)
    current_step = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', db_index=True)
    priority = models.CharField(max_length=20, default='Medium')
    amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    payload = models.JSONField(default=dict, blank=True)
    remarks = models.TextField(blank=True)
    acted_by = models.CharField(max_length=40, blank=True)
    acted_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.title} ({self.status})'


class BudgetPlan(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('active', 'Active'),
        ('closed', 'Closed'),
    ]

    owner_user_id = models.CharField(max_length=40, db_index=True)
    financial_year = models.CharField(max_length=20, db_index=True)
    department = models.CharField(max_length=120, blank=True, db_index=True)
    branch = models.CharField(max_length=120, blank=True, db_index=True)
    category = models.CharField(max_length=120, blank=True)
    allocated_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    spent_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    committed_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    currency = models.CharField(max_length=10, default='INR')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    notes = models.TextField(blank=True)
    payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['financial_year', 'department', 'category']

    def __str__(self):
        return f'{self.financial_year} - {self.department or self.branch or self.category}'


class BudgetTransaction(models.Model):
    TRANSACTION_CHOICES = [
        ('allocation', 'Allocation'),
        ('expense', 'Expense'),
        ('adjustment', 'Adjustment'),
        ('refund', 'Refund'),
    ]

    budget = models.ForeignKey(BudgetPlan, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=30, choices=TRANSACTION_CHOICES)
    title = models.CharField(max_length=160)
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    transaction_date = models.DateField(db_index=True)
    reference_number = models.CharField(max_length=80, blank=True)
    vendor = models.CharField(max_length=140, blank=True)
    attachment = models.FileField(upload_to='budget/attachments/', blank=True, null=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-transaction_date', '-created_at']

    def __str__(self):
        return f'{self.title} - {self.amount}'


class BranchPerformanceSnapshot(models.Model):
    branch_name = models.CharField(max_length=140, db_index=True)
    period = models.CharField(max_length=40, db_index=True)
    total_employees = models.PositiveIntegerField(default=0)
    active_employees = models.PositiveIntegerField(default=0)
    revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    expense = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    attendance_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    productivity_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    change_percent = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    payload = models.JSONField(default=dict, blank=True)
    captured_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('branch_name', 'period')
        ordering = ['branch_name', '-period']

    def __str__(self):
        return f'{self.branch_name} - {self.period}'


class DepartmentPerformanceSnapshot(models.Model):
    department = models.CharField(max_length=140, db_index=True)
    period = models.CharField(max_length=40, db_index=True)
    total_employees = models.PositiveIntegerField(default=0)
    present_count = models.PositiveIntegerField(default=0)
    absent_count = models.PositiveIntegerField(default=0)
    late_count = models.PositiveIntegerField(default=0)
    leave_count = models.PositiveIntegerField(default=0)
    task_completion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    performance_score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    payload = models.JSONField(default=dict, blank=True)
    captured_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('department', 'period')
        ordering = ['department', '-period']

    def __str__(self):
        return f'{self.department} - {self.period}'


class MeetingParticipantStatus(models.Model):
    STATUS_CHOICES = [
        ('invited', 'Invited'),
        ('accepted', 'Accepted'),
        ('declined', 'Declined'),
        ('attended', 'Attended'),
        ('missed', 'Missed'),
    ]

    meeting = models.ForeignKey(MdMeeting, on_delete=models.CASCADE, related_name='participant_statuses')
    participant_user_id = models.CharField(max_length=40, db_index=True)
    participant_name = models.CharField(max_length=140, blank=True)
    participant_email = models.EmailField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='invited')
    response_note = models.TextField(blank=True)
    responded_at = models.DateTimeField(null=True, blank=True)
    notification_sent = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('meeting', 'participant_user_id')
        ordering = ['meeting', 'participant_name']

    def __str__(self):
        return f'{self.participant_user_id} - {self.meeting.title}'


class MeetingMinute(models.Model):
    meeting = models.ForeignKey(MdMeeting, on_delete=models.CASCADE, related_name='minutes')
    title = models.CharField(max_length=160)
    notes = models.TextField(blank=True)
    action_items = models.JSONField(default=list, blank=True)
    recorded_by = models.CharField(max_length=40, blank=True)
    recorded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-recorded_at']

    def __str__(self):
        return self.title


class TaskComment(models.Model):
    task = models.ForeignKey(TeamTask, on_delete=models.CASCADE, related_name='comments')
    author_user_id = models.CharField(max_length=40, db_index=True)
    author_name = models.CharField(max_length=140, blank=True)
    comment = models.TextField()
    attachments = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'{self.task_id} - {self.author_user_id}'


class TaskChecklistItem(models.Model):
    task = models.ForeignKey(TeamTask, on_delete=models.CASCADE, related_name='checklist_items')
    title = models.CharField(max_length=160)
    is_completed = models.BooleanField(default=False)
    completed_by = models.CharField(max_length=40, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['sort_order', 'id']

    def __str__(self):
        return self.title


class ProjectIssue(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='issues')
    title = models.CharField(max_length=180)
    description = models.TextField(blank=True)
    owner_user_id = models.CharField(max_length=40, blank=True)
    priority = models.CharField(max_length=20, default='Medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    due_date = models.DateField(null=True, blank=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return self.title


class ProjectExpense(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='expenses')
    title = models.CharField(max_length=160)
    category = models.CharField(max_length=100, blank=True)
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    expense_date = models.DateField(db_index=True)
    vendor = models.CharField(max_length=140, blank=True)
    receipt = models.FileField(upload_to='project_expenses/', blank=True, null=True)
    approved_by = models.CharField(max_length=40, blank=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-expense_date']

    def __str__(self):
        return f'{self.project.name} - {self.title}'


class AttendanceRegularizationRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    employee_id = models.CharField(max_length=20, db_index=True)
    attendance_date = models.DateField(db_index=True)
    request_type = models.CharField(max_length=50, default='correction')
    requested_check_in = models.DateTimeField(null=True, blank=True)
    requested_check_out = models.DateTimeField(null=True, blank=True)
    reason = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    reviewed_by = models.CharField(max_length=40, blank=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    review_note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-attendance_date', '-created_at']

    def __str__(self):
        return f'{self.employee_id} - {self.attendance_date}'


class LeaveBalanceLedger(models.Model):
    employee_id = models.CharField(max_length=20, db_index=True)
    leave_type = models.CharField(max_length=60, db_index=True)
    fiscal_year = models.CharField(max_length=20, db_index=True)
    opening_balance = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    accrued = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    used = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    pending = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    carry_forward = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    available = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    updated_by = models.CharField(max_length=40, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('employee_id', 'leave_type', 'fiscal_year')
        ordering = ['employee_id', 'leave_type']

    def __str__(self):
        return f'{self.employee_id} - {self.leave_type} ({self.available})'


class OvertimeRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('paid', 'Paid'),
    ]

    employee_id = models.CharField(max_length=20, db_index=True)
    overtime_date = models.DateField(db_index=True)
    start_time = models.DateTimeField(null=True, blank=True)
    end_time = models.DateTimeField(null=True, blank=True)
    total_minutes = models.PositiveIntegerField(default=0)
    reason = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    approved_by = models.CharField(max_length=40, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    payroll_month = models.PositiveIntegerField(null=True, blank=True)
    payroll_year = models.PositiveIntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-overtime_date', '-created_at']

    def __str__(self):
        return f'{self.employee_id} - {self.overtime_date}'


class ShiftSchedule(models.Model):
    employee_id = models.CharField(max_length=20, db_index=True)
    shift_date = models.DateField(db_index=True)
    shift_name = models.CharField(max_length=80)
    start_time = models.TimeField()
    end_time = models.TimeField()
    work_mode = models.CharField(max_length=30, blank=True)
    location = models.CharField(max_length=140, blank=True)
    assigned_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('employee_id', 'shift_date')
        ordering = ['shift_date', 'employee_id']

    def __str__(self):
        return f'{self.employee_id} - {self.shift_date}'


class RecruitmentCandidatePipeline(models.Model):
    STATUS_CHOICES = [
        ('applied', 'Applied'),
        ('screening', 'Screening'),
        ('interview', 'Interview'),
        ('offered', 'Offered'),
        ('hired', 'Hired'),
        ('rejected', 'Rejected'),
    ]

    job = models.ForeignKey(RecruitmentJobOpening, on_delete=models.CASCADE, related_name='pipeline_candidates')
    candidate_name = models.CharField(max_length=140)
    candidate_email = models.EmailField()
    candidate_phone = models.CharField(max_length=20, blank=True)
    resume = models.FileField(upload_to='recruitment/resumes/', blank=True, null=True)
    source = models.CharField(max_length=80, blank=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='applied', db_index=True)
    score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    current_stage = models.CharField(max_length=80, blank=True)
    notes = models.TextField(blank=True)
    assigned_to = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return self.candidate_name


class InterviewSchedule(models.Model):
    candidate = models.ForeignKey(RecruitmentCandidatePipeline, on_delete=models.CASCADE, related_name='interviews')
    interviewer_user_id = models.CharField(max_length=40, db_index=True)
    interviewer_name = models.CharField(max_length=140, blank=True)
    scheduled_at = models.DateTimeField(db_index=True)
    duration_minutes = models.PositiveIntegerField(default=30)
    mode = models.CharField(max_length=40, default='online')
    location_or_link = models.CharField(max_length=250, blank=True)
    status = models.CharField(max_length=30, default='scheduled')
    feedback = models.JSONField(default=dict, blank=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['scheduled_at']

    def __str__(self):
        return f'{self.candidate.candidate_name} - {self.scheduled_at}'


class OnboardingTask(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('blocked', 'Blocked'),
    ]

    employee_id = models.CharField(max_length=20, db_index=True)
    title = models.CharField(max_length=160)
    category = models.CharField(max_length=80, blank=True)
    owner_user_id = models.CharField(max_length=40, blank=True)
    due_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    checklist = models.JSONField(default=list, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['status', 'due_date']

    def __str__(self):
        return self.title


class DocumentRecord(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('verified', 'Verified'),
        ('rejected', 'Rejected'),
        ('expired', 'Expired'),
    ]

    owner_user_id = models.CharField(max_length=40, db_index=True)
    owner_role = models.CharField(max_length=30, blank=True)
    document_type = models.CharField(max_length=100, db_index=True)
    document_number = models.CharField(max_length=100, blank=True)
    file = models.FileField(upload_to='documents/', blank=True, null=True)
    expiry_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    verified_by = models.CharField(max_length=40, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    remarks = models.TextField(blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['owner_user_id', 'document_type']

    def __str__(self):
        return f'{self.owner_user_id} - {self.document_type}'


class AssetInventory(models.Model):
    STATUS_CHOICES = [
        ('available', 'Available'),
        ('assigned', 'Assigned'),
        ('maintenance', 'Maintenance'),
        ('retired', 'Retired'),
    ]

    asset_code = models.CharField(max_length=60, unique=True)
    asset_name = models.CharField(max_length=160)
    category = models.CharField(max_length=100, blank=True)
    serial_number = models.CharField(max_length=120, blank=True)
    purchase_date = models.DateField(null=True, blank=True)
    purchase_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    assigned_to = models.CharField(max_length=40, blank=True, db_index=True)
    assigned_at = models.DateField(null=True, blank=True)
    location = models.CharField(max_length=140, blank=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='available')
    notes = models.TextField(blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['asset_code']

    def __str__(self):
        return self.asset_code


class HelpdeskTicket(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]

    ticket_no = models.CharField(max_length=60, unique=True)
    requester_user_id = models.CharField(max_length=40, db_index=True)
    assigned_to = models.CharField(max_length=40, blank=True, db_index=True)
    category = models.CharField(max_length=80, blank=True)
    subject = models.CharField(max_length=180)
    description = models.TextField(blank=True)
    priority = models.CharField(max_length=20, default='Medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    attachments = models.JSONField(default=list, blank=True)
    resolution_note = models.TextField(blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return self.ticket_no


class TrainingProgram(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('scheduled', 'Scheduled'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    title = models.CharField(max_length=160)
    description = models.TextField(blank=True)
    trainer = models.CharField(max_length=140, blank=True)
    department = models.CharField(max_length=120, blank=True)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    location_or_link = models.CharField(max_length=250, blank=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='draft')
    materials = models.JSONField(default=list, blank=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-start_date', 'title']

    def __str__(self):
        return self.title


class TrainingEnrollment(models.Model):
    program = models.ForeignKey(TrainingProgram, on_delete=models.CASCADE, related_name='enrollments')
    employee_id = models.CharField(max_length=20, db_index=True)
    status = models.CharField(max_length=30, default='enrolled')
    progress_percent = models.PositiveIntegerField(default=0)
    score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    feedback = models.TextField(blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    enrolled_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('program', 'employee_id')
        ordering = ['program', 'employee_id']

    def __str__(self):
        return f'{self.employee_id} - {self.program.title}'


class PerformanceReviewCycle(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('archived', 'Archived'),
    ]

    name = models.CharField(max_length=140)
    period = models.CharField(max_length=40, unique=True)
    start_date = models.DateField()
    end_date = models.DateField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    review_template = models.JSONField(default=dict, blank=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-start_date']

    def __str__(self):
        return self.name


class EmployeeGoal(models.Model):
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('deferred', 'Deferred'),
    ]

    employee_id = models.CharField(max_length=20, db_index=True)
    cycle = models.ForeignKey(PerformanceReviewCycle, on_delete=models.SET_NULL, null=True, blank=True, related_name='goals')
    title = models.CharField(max_length=180)
    description = models.TextField(blank=True)
    weightage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    target_value = models.CharField(max_length=80, blank=True)
    achieved_value = models.CharField(max_length=80, blank=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='not_started')
    manager_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    employee_comment = models.TextField(blank=True)
    manager_comment = models.TextField(blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['employee_id', 'title']

    def __str__(self):
        return self.title


class SalaryRevisionRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('implemented', 'Implemented'),
    ]

    employee_id = models.CharField(max_length=20, db_index=True)
    current_ctc = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    proposed_ctc = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    effective_from = models.DateField(null=True, blank=True)
    reason = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    requested_by = models.CharField(max_length=40, blank=True)
    approved_by = models.CharField(max_length=40, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.employee_id} - {self.status}'


class ReportExportHistory(models.Model):
    STATUS_CHOICES = [
        ('queued', 'Queued'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    ]

    requested_by = models.CharField(max_length=40, db_index=True)
    report_type = models.CharField(max_length=100, db_index=True)
    filters = models.JSONField(default=dict, blank=True)
    file_format = models.CharField(max_length=20, default='pdf')
    file = models.FileField(upload_to='reports/exports/', blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='queued')
    error_message = models.TextField(blank=True)
    generated_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.report_type} - {self.status}'


class Announcement(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
        ('archived', 'Archived'),
    ]

    title = models.CharField(max_length=180)
    message = models.TextField()
    target_roles = models.JSONField(default=list, blank=True)
    target_user_ids = models.JSONField(default=list, blank=True)
    attachment = models.FileField(upload_to='announcements/', blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    publish_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    created_by = models.CharField(max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-publish_at', '-created_at']

    def __str__(self):
        return self.title


class CompanyLeave(models.Model):
    title = models.CharField(max_length=180)
    message = models.TextField(blank=True)
    from_date = models.DateField(db_index=True)
    to_date = models.DateField(db_index=True)
    announced_by = models.CharField(max_length=40, blank=True)
    announcement = models.OneToOneField(
        Announcement,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='company_leave',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-from_date', '-created_at']

    def __str__(self):
        return f'{self.title}: {self.from_date} - {self.to_date}'


class AuditLog(models.Model):
    actor_user_id = models.CharField(max_length=40, blank=True, db_index=True)
    actor_role = models.CharField(max_length=30, blank=True)
    action = models.CharField(max_length=120, db_index=True)
    module = models.CharField(max_length=80, db_index=True)
    reference_id = models.CharField(max_length=80, blank=True, db_index=True)
    before = models.JSONField(default=dict, blank=True)
    after = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.module} - {self.action}'


class EmployeeApprovalRequest(models.Model):
    STATUS_CHOICES = [
        ('requested', 'Requested'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('cancelled', 'Cancelled'),
    ]

    employee_id = models.CharField(max_length=40, db_index=True)
    sender_role = models.CharField(max_length=20, default='employee')
    department = models.CharField(max_length=80, blank=True)
    assigned_tl_user_id = models.CharField(max_length=40, blank=True, db_index=True)
    request_type = models.CharField(max_length=50, default='daily_report')
    title = models.CharField(max_length=180)
    request_date = models.DateField()
    session = models.CharField(max_length=20)
    task_details = models.TextField()
    expected_result = models.TextField()
    actual_result = models.TextField()
    platforms = models.JSONField(default=list, blank=True)
    posted_by = models.CharField(max_length=180, blank=True)
    scheduled_post = models.CharField(max_length=10, blank=True)
    leave_type = models.CharField(max_length=40, blank=True)
    leave_end_date = models.DateField(blank=True, null=True)
    attachment = models.FileField(upload_to='approval_attachments/', blank=True, null=True)
    approvers = models.JSONField(default=list)
    decisions = models.JSONField(default=list)
    current_stage = models.PositiveSmallIntegerField(default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='requested')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.employee_id} - {self.title}'
