from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from cloudinary.models import CloudinaryField
import random
import string


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
        ('hr', 'HR'),
        ('finance', 'Finance'),
        ('marketing', 'Marketing Team'),
        ('it', 'IT Team'),
        ('admin', 'Admin'),
        ('manager', 'Manager'),
        ('tl', 'TL'),
    ]

    GENDER_CHOICES = [('male', 'Male'), ('female', 'Female'), ('other', 'Other')]

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

    occupation = models.CharField(max_length=50, blank=True)
    pan = models.CharField(max_length=10, blank=True)
    aadhar = models.CharField(max_length=12, blank=True)

    USERNAME_FIELD = 'email'
    objects = UserManager()

    def save(self, *args, **kwargs):
        if not self.user_id:
            count = User.objects.filter(role=self.role).count() + 1
            self.user_id = f'BB{self.role.upper()}{count:04d}'
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
    STATUS_CHOICES = [('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected')]

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
    percentage = models.CharField(max_length=10)

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
    doc_resume = CloudinaryField('image', blank=True, null=True)
    doc_experience_cert = CloudinaryField('image', blank=True, null=True)
    doc_relieving = CloudinaryField('image', blank=True, null=True)
    doc_salary_slips = CloudinaryField('image', blank=True, null=True)
    doc_passport_copy = CloudinaryField('image', blank=True, null=True)
    doc_driving = CloudinaryField('image', blank=True, null=True)
    doc_vaccination = CloudinaryField('image', blank=True, null=True)

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.first_name} {self.last_name}'


class EmployeeAccount(models.Model):
    DEPARTMENT_CHOICES = [
        ('hr', 'HR'),
        ('marketing', 'Marketing'),
        ('digital_marketing', 'Digital Marketing'),
        ('webapp', 'WebApp'),
        ('mobile_app', 'Mobile App'),
        ('sales', 'Sales'),
    ]
    DESIGNATION_CHOICES = [
        ('associate', 'Associate'),
        ('intern', 'Intern'),
        ('tl', 'TL'),
        ('ceo', 'CEO'),
        ('md', 'MD'),
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
            count = EmployeeAccount.objects.count() + 1
            self.employee_id = f'BBEMP{count:05d}'
        if not self.otc:
            self.otc = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        super().save(*args, **kwargs)

    def __str__(self):
        return self.employee_id