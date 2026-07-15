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
        ('director', 'Director'),
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

    email = models.EmailField(unique=True)
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

    USERNAME_FIELD = 'email'
    objects = UserManager()

    def save(self, *args, **kwargs):
        if not self.user_id:
            prefix = ROLE_ID_PREFIXES.get(self.role, f'BB{self.role.upper()}')
            width = ROLE_ID_WIDTHS.get(self.role, 4)
            self.user_id = next_prefixed_id(User, 'user_id', prefix, width)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.email


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
    doc_aadhar = CloudinaryField('image', blank=True, null=True)
    doc_pan = CloudinaryField('image', blank=True, null=True)
    doc_bank_passbook = CloudinaryField('image', blank=True, null=True)
    doc_10th = CloudinaryField('image', blank=True, null=True)
    doc_12th = CloudinaryField('image', blank=True, null=True)
    doc_degree = CloudinaryField('image', blank=True, null=True)
    doc_consolidated = CloudinaryField('image', blank=True, null=True)
    doc_college_noc = CloudinaryField('image', blank=True, null=True)
    doc_resume = CloudinaryField('image', blank=True, null=True)
    doc_experience_cert = CloudinaryField('image', blank=True, null=True)
    doc_relieving = CloudinaryField('image', blank=True, null=True)
    doc_salary_slips = CloudinaryField('image', blank=True, null=True)
    doc_passport_copy = CloudinaryField('image', blank=True, null=True)
    doc_driving = CloudinaryField('image', blank=True, null=True)
    doc_vaccination = CloudinaryField('image', blank=True, null=True)

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    document_statuses = models.JSONField(default=dict, blank=True)
    document_review_history = models.JSONField(default=list, blank=True)
    submitted_at = models.DateTimeField(auto_now_add=True)

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
        ('director', 'Director'),
        ('manager', 'Manager'),
    ]
    EMPLOYMENT_TYPE_CHOICES = [
        ('full_time', 'Full Time'),
        ('part_time', 'Part Time'),
    ]

    registration = models.OneToOneField(EmployeeRegistration, on_delete=models.CASCADE, related_name='account')
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


class EmployeeAttendanceRecord(models.Model):
    employee_id = models.CharField(max_length=20, db_index=True)
    attendance_date = models.DateField(db_index=True)
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
    from_date = models.DateField(db_index=True)
    to_date = models.DateField(db_index=True)
    total_days = models.PositiveIntegerField(default=1)
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
    paid_days = models.PositiveIntegerField(default=0)
    lop_days = models.PositiveIntegerField(default=0)
    overtime_minutes = models.PositiveIntegerField(default=0)
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
