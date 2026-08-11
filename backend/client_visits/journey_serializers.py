from rest_framework import serializers

from hrms.models import User
from .models import ClientVisit, ClientVisitJourney, JourneyLocationPoint, JourneyStop


class JourneyCreateSerializer(serializers.ModelSerializer):
    source_visit_id = serializers.PrimaryKeyRelatedField(
        source= 'source_visit', queryset=ClientVisit.objects.all(), required=False,
        allow_null=True,
    )
    assigned_team_lead_id = serializers.SlugRelatedField(
        source='assigned_team_lead', slug_field='user_id',
        queryset=User.objects.filter(is_active=True),
    )

    class Meta:
        model = ClientVisitJourney
        fields = (
            'source_visit_id', 'assigned_team_lead_id', 'client_name',
            'client_contact', 'meeting_purpose', 'destination_address',
            'destination_latitude', 'destination_longitude', 'scheduled_at',
        )

    def validate_assigned_team_lead_id(self, user):
        if user.role not in {'tl', 'manager'}:
            raise serializers.ValidationError('Assigned user is not an eligible Team Lead.')
        return user

    def validate(self, attrs):
        request = self.context['request']
        source_visit = attrs.get('source_visit')
        if source_visit and source_visit.employee_user_id not in {
            request.user.user_id,
            getattr(getattr(request.user, 'employee_account', None), 'employee_id', ''),
        }:
            raise serializers.ValidationError('The source visit does not belong to this employee.')
        return attrs

    def create(self, validated_data):
        return ClientVisitJourney.objects.create(
            employee=self.context['request'].user,
            **validated_data,
        )


class JourneyPointSerializer(serializers.ModelSerializer):
    class Meta:
        model = JourneyLocationPoint
        exclude = ('journey', 'employee', 'created_at')


class JourneyStopSerializer(serializers.ModelSerializer):
    class Meta:
        model = JourneyStop
        exclude = ('journey', 'created_at')


class JourneySerializer(serializers.ModelSerializer):
    employee_id = serializers.CharField(source='employee.user_id', read_only=True)
    employee_name = serializers.SerializerMethodField()
    assigned_team_lead_id = serializers.CharField(source='assigned_team_lead.user_id', read_only=True)
    assigned_team_lead_name = serializers.SerializerMethodField()
    point_count = serializers.IntegerField(read_only=True, default=0)
    low_accuracy_point_count = serializers.IntegerField(read_only=True, default=0)
    stop_count = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = ClientVisitJourney
        fields = '__all__'

    @staticmethod
    def _name(user):
        return f'{user.first_name} {user.last_name}'.strip() or user.email

    def get_employee_name(self, obj):
        return self._name(obj.employee)

    def get_assigned_team_lead_name(self, obj):
        return self._name(obj.assigned_team_lead)
