from rest_framework import serializers
from .models import EmployeeRegistration
from .models import EmployeeAccount

TEAM_MEMBER_DEPARTMENT_CHOICES = [
    ('web_application_development', 'Web Application Development'),
    ('mobile_application_development', 'Mobile Application Development'),
    ('ui_ux_design', 'UI/UX Design'),
    ('quality_assurance_testing', 'Quality Assurance (QA) and Testing'),
    ('devops_cloud_engineering', 'DevOps and Cloud Engineering'),
    ('artificial_intelligence_machine_learning', 'Artificial Intelligence and Machine Learning'),
    ('data_science_analytics', 'Data Science and Analytics'),
    ('cybersecurity', 'Cybersecurity'),
    ('it_infrastructure_network_support', 'IT Infrastructure and Network Support'),
    ('technical_support', 'Technical Support'),
    ('project_management', 'Project Management'),
    ('product_management', 'Product Management'),
    ('digital_marketing', 'Digital Marketing'),
    ('sales_business_development', 'Sales and Business Development'),
    ('human_resources', 'Human Resources (HR)'),
    ('finance_accounts', 'Finance and Accounts'),
    ('administration_operations', 'Administration and Operations'),
    ('management', 'Management'),
    ('research_development', 'Research and Development (R&D)'),
    ('internship_trainee', 'Internship / Trainee'),
]

HR_DEPARTMENT_CHOICES = [
    ('talent_acquisition_recruitment', 'Talent Acquisition / Recruitment'),
    ('hr_operations', 'HR Operations'),
    ('employee_onboarding_offboarding', 'Employee Onboarding and Offboarding'),
    ('attendance_leave_management', 'Attendance and Leave Management'),
    ('payroll_compensation', 'Payroll and Compensation'),
    ('benefits_administration', 'Benefits Administration'),
    ('learning_development', 'Learning and Development (L&D)'),
    ('performance_management', 'Performance Management'),
    ('employee_relations', 'Employee Relations'),
    ('employee_engagement', 'Employee Engagement'),
    ('hr_compliance_policies', 'HR Compliance and Policies'),
    ('workforce_planning', 'Workforce Planning'),
    ('hr_analytics_reporting', 'HR Analytics and Reporting'),
    ('health_safety_well_being', 'Health, Safety and Well-being'),
    ('internship_campus_recruitment', 'Internship and Campus Recruitment'),
]

STATE_CITY_CHOICES = {
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Tirupati'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru', 'Hubballi'],
    'Kerala': ['Kochi', 'Thiruvananthapuram', 'Kozhikode', 'Thrissur'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
    'Tamil Nadu': [
        'Chennai', 'Coimbatore', 'Erode', 'Madurai', 'Salem',
        'Tiruchirappalli', 'Tirunelveli', 'Vellore',
    ],
    'Telangana': ['Hyderabad', 'Warangal', 'Karimnagar', 'Nizamabad'],
    'Uttar Pradesh': ['Lucknow', 'Noida', 'Kanpur', 'Varanasi', 'Agra'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Siliguri'],
}

INDIA_STATES_AND_UTS = {
    'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh',
    'Assam', 'Bihar', 'Chandigarh', 'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Goa', 'Gujarat',
    'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir', 'Jharkhand',
    'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh',
    'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha',
    'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
}

class LoginSerializer(serializers.Serializer):
    email = serializers.CharField()
    password = serializers.CharField()
    # Optional dashboard context. Existing clients continue to receive the
    # account's actual role when this field is omitted.
    selected_role = serializers.CharField(required=False, allow_blank=True)
    login_as = serializers.CharField(required=False, allow_blank=True)

class CreateUserSerializer(serializers.Serializer):
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    email = serializers.EmailField()
    country_code = serializers.CharField()
    phone = serializers.CharField()
    gender = serializers.CharField()
    dob = serializers.DateField()
    password = serializers.CharField()
    confirm_password = serializers.CharField()
    door_no = serializers.CharField()
    street = serializers.CharField()
    pincode = serializers.CharField()
    city = serializers.CharField()
    state = serializers.CharField()
    department = serializers.CharField(required=False, allow_blank=True)
    occupation = serializers.CharField(required=False, allow_blank=True)
    designation = serializers.CharField(required=False, allow_blank=True)
    created_by = serializers.CharField(required=False, allow_blank=True)
    work_mode = serializers.ChoiceField(
        choices=['work_from_home', 'hybrid', 'onsite'],
        required=False,
        default='onsite',
    )
    pan = serializers.CharField()
    aadhar = serializers.CharField()
    role = serializers.ChoiceField(choices=['ceo', 'md', 'director', 'hr', 'finance', 'marketing', 'it', 'admin', 'manager', 'tl', 'employee'])

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError('Passwords do not match')
        phone = data.get('phone', '').strip()
        if not phone.isdigit() or len(phone) != 10:
            raise serializers.ValidationError({'phone': 'Phone number must be 10 digits'})
        state = (data.get('state') or '').strip()
        city = (data.get('city') or '').strip()
        if state not in INDIA_STATES_AND_UTS:
            raise serializers.ValidationError({'state': 'Select a valid state'})
        if not city:
            raise serializers.ValidationError({'city': 'Select a city'})
        data['state'] = state
        data['city'] = city
        work_mode = (data.get('work_mode') or 'onsite').strip().lower()
        if work_mode not in {'work_from_home', 'hybrid', 'onsite'}:
            raise serializers.ValidationError({'work_mode': 'Select a valid work mode'})
        data['work_mode'] = work_mode
        role = data.get('role', '')
        designation = (data.get('designation') or data.get('occupation') or role).strip().lower()
        data['designation'] = 'tl' if role == 'tl' else designation
        data['occupation'] = data['designation']
        data['department'] = (data.get('department') or '').strip()
        if role in {'hr', 'it', 'tl'}:
            if not data['department']:
                role_label = {
                    'hr': 'HR',
                    'it': 'IT Team',
                    'tl': 'Team Lead',
                }[role]
                raise serializers.ValidationError({
                    'department': f'Department is required for {role_label}',
                })
            choices = (
                HR_DEPARTMENT_CHOICES
                if role == 'hr'
                else TEAM_MEMBER_DEPARTMENT_CHOICES
            )
            valid_departments = {value for value, _label in choices}
            if data['department'] not in valid_departments:
                raise serializers.ValidationError({'department': 'Select a valid department'})
        else:
            # Other members always belong to the department represented by
            # their role (HR -> hr, CEO -> ceo, Finance -> finance, and so on).
            data['department'] = 'management' if role == 'admin' else role
        return data



class EmployeeAccountSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployeeAccount
        fields = '__all__'

import cloudinary

class EmployeeRegistrationSerializer(serializers.ModelSerializer):
    # Registration is currently India-specific (Aadhaar/PAN). Accept requests
    # from older app builds that omitted nationality and store a useful value.
    nationality = serializers.CharField(
        required=False,
        allow_blank=True,
        default='Indian',
    )
    doc_passport_photo = serializers.SerializerMethodField()
    doc_aadhar = serializers.SerializerMethodField()
    doc_pan = serializers.SerializerMethodField()
    doc_bank_passbook = serializers.SerializerMethodField()
    doc_10th = serializers.SerializerMethodField()
    doc_12th = serializers.SerializerMethodField()
    doc_degree = serializers.SerializerMethodField()
    doc_consolidated = serializers.SerializerMethodField()
    doc_college_noc = serializers.SerializerMethodField()
    doc_resume = serializers.SerializerMethodField()
    doc_experience_cert = serializers.SerializerMethodField()
    doc_relieving = serializers.SerializerMethodField()
    doc_salary_slips = serializers.SerializerMethodField()
    doc_passport_copy = serializers.SerializerMethodField()
    doc_driving = serializers.SerializerMethodField()
    doc_vaccination = serializers.SerializerMethodField()

    def _get_url(self, obj, field_name):
        field = getattr(obj, field_name)
        if field:
            return cloudinary.CloudinaryImage(str(field)).build_url()
        return ''

    def get_doc_passport_photo(self, obj): return self._get_url(obj, 'doc_passport_photo')
    def get_doc_aadhar(self, obj): return self._get_url(obj, 'doc_aadhar')
    def get_doc_pan(self, obj): return self._get_url(obj, 'doc_pan')
    def get_doc_bank_passbook(self, obj): return self._get_url(obj, 'doc_bank_passbook')
    def get_doc_10th(self, obj): return self._get_url(obj, 'doc_10th')
    def get_doc_12th(self, obj): return self._get_url(obj, 'doc_12th')
    def get_doc_degree(self, obj): return self._get_url(obj, 'doc_degree')
    def get_doc_consolidated(self, obj): return self._get_url(obj, 'doc_consolidated')
    def get_doc_college_noc(self, obj): return self._get_url(obj, 'doc_college_noc')
    def get_doc_resume(self, obj): return self._get_url(obj, 'doc_resume')
    def get_doc_experience_cert(self, obj): return self._get_url(obj, 'doc_experience_cert')
    def get_doc_relieving(self, obj): return self._get_url(obj, 'doc_relieving')
    def get_doc_salary_slips(self, obj): return self._get_url(obj, 'doc_salary_slips')
    def get_doc_passport_copy(self, obj): return self._get_url(obj, 'doc_passport_copy')
    def get_doc_driving(self, obj): return self._get_url(obj, 'doc_driving')
    def get_doc_vaccination(self, obj): return self._get_url(obj, 'doc_vaccination')

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['mobile'] = mask_phone_number(data.get('mobile'))
        return data

    def validate_nationality(self, value):
        return str(value or '').strip() or 'Indian'

    class Meta:
        model = EmployeeRegistration
        fields = '__all__'
        read_only_fields = ['status', 'submitted_at']
def mask_phone_number(value):
    raw = str(value or '').strip()
    if not raw:
        return ''
    if any(marker in raw for marker in ('X', '*', '•')):
        return raw
    digits = ''.join(character for character in raw if character.isdigit())
    if not digits:
        return ''
    local = digits[-10:] if len(digits) > 10 else digits
    country = digits[:-10] if len(digits) > 10 else ''
    if len(local) <= 3:
        masked = local[:1] + ('X' * max(len(local) - 1, 0))
    else:
        masked = local[:2] + ('X' * (len(local) - 3)) + local[-1:]
    return f'+{country} {masked}' if country else masked
