from rest_framework import serializers
from .models import EmployeeRegistration
from .models import EmployeeAccount

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()

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
    occupation = serializers.CharField()
    pan = serializers.CharField()
    aadhar = serializers.CharField()
    role = serializers.ChoiceField(choices=['ceo', 'md', 'hr', 'finance', 'marketing', 'it', 'admin', 'manager', 'tl'])

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError('Passwords do not match')
        return data



class EmployeeAccountSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployeeAccount
        fields = '__all__'

import cloudinary

class EmployeeRegistrationSerializer(serializers.ModelSerializer):
    doc_passport_photo = serializers.SerializerMethodField()
    doc_aadhar = serializers.SerializerMethodField()
    doc_pan = serializers.SerializerMethodField()
    doc_bank_passbook = serializers.SerializerMethodField()
    doc_10th = serializers.SerializerMethodField()
    doc_12th = serializers.SerializerMethodField()
    doc_degree = serializers.SerializerMethodField()
    doc_consolidated = serializers.SerializerMethodField()
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
    def get_doc_resume(self, obj): return self._get_url(obj, 'doc_resume')
    def get_doc_experience_cert(self, obj): return self._get_url(obj, 'doc_experience_cert')
    def get_doc_relieving(self, obj): return self._get_url(obj, 'doc_relieving')
    def get_doc_salary_slips(self, obj): return self._get_url(obj, 'doc_salary_slips')
    def get_doc_passport_copy(self, obj): return self._get_url(obj, 'doc_passport_copy')
    def get_doc_driving(self, obj): return self._get_url(obj, 'doc_driving')
    def get_doc_vaccination(self, obj): return self._get_url(obj, 'doc_vaccination')

    class Meta:
        model = EmployeeRegistration
        fields = '__all__'
        read_only_fields = ['status', 'submitted_at']