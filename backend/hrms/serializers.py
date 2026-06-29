from rest_framework import serializers
from .models import MdMeeting

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
    role = serializers.ChoiceField(choices=['employee', 'ceo', 'md', 'hr', 'finance', 'marketing', 'it', 'admin', 'manager', 'tl'])

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError('Passwords do not match')
        return data


class MdMeetingSerializer(serializers.ModelSerializer):
    class Meta:
        model = MdMeeting
        fields = [
            'id',
            'title',
            'meeting_type',
            'location',
            'description',
            'date_label',
            'time_label',
            'duration',
            'status',
            'participants',
            'agenda',
            'created_by',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']
