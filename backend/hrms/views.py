from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from .serializers import LoginSerializer, CreateUserSerializer, MdMeetingSerializer
from .models import User, MdMeeting

@api_view(['POST'])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']
        try:
            user = User.objects.get(email=email)
            if user.check_password(password):
                return Response({
                    'success': True,
                    'role': user.role,
                    'email': user.email,
                    'first_name': user.first_name,
                    'user_id': user.user_id,
                })
            else:
                return Response({'success': False, 'message': 'Wrong password'}, status=400)
        except User.DoesNotExist:
            return Response({'success': False, 'message': 'User not found'}, status=404)
    return Response(serializer.errors, status=400)

@api_view(['POST'])
def create_user_view(request):
    serializer = CreateUserSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        if User.objects.filter(email=data['email']).exists():
            return Response({'success': False, 'message': 'Email already exists'}, status=400)
        user = User(
            email=data['email'],
            role=data['role'],
            first_name=data['first_name'],
            last_name=data['last_name'],
            country_code=data['country_code'],
            phone=data['phone'],
            gender=data['gender'],
            dob=data['dob'],
            door_no=data['door_no'],
            street=data['street'],
            pincode=data['pincode'],
            city=data['city'],
            state=data['state'],
            occupation=data['occupation'],
            pan=data['pan'],
            aadhar=data['aadhar'],
        )
        user.set_password(data['password'])
        user.save()
        return Response({'success': True, 'user_id': user.user_id, 'message': f'{data["role"].upper()} created!'})
    return Response({'success': False, 'errors': serializer.errors}, status=400)


def _dashboard_counts():
    active_users = User.objects.filter(is_active=True)
    total_users = User.objects.count()
    total_active = active_users.count()
    department_count = active_users.exclude(role__in=['superadmin', 'ceo', 'md']).values('role').distinct().count()
    branch_count = active_users.exclude(city='').values('city').distinct().count()
    today = timezone.localdate()
    return {
        'total_users': total_users,
        'total_active': total_active,
        'departments': department_count,
        'branches': branch_count,
        'pending_approvals': 0,
        'pending_leaves': 0,
        'open_tasks': 0,
        'attendance': total_active,
        'absent': max(total_users - total_active, 0),
        'late': 0,
        'meetings_today': MdMeeting.objects.filter(created_at__date=today).count(),
    }


def _users_payload():
    payload = []
    for user in User.objects.all().order_by('first_name', 'email'):
        display_name = f'{user.first_name} {user.last_name}'.strip() or user.email
        detail = user.city or user.state or user.occupation or user.get_role_display()
        payload.append({
            'name': display_name,
            'subtitle': f'{user.user_id} - {user.get_role_display()}'.strip(),
            'detail': detail,
            'trailing': 'Active' if user.is_active else 'Inactive',
            'email': user.email,
            'id': user.user_id,
            'role': user.get_role_display(),
        })
    return payload


@api_view(['GET'])
def ceo_dashboard_view(request):
    counts = _dashboard_counts()
    return Response({
        'total_employees': f'{counts["total_users"]:,}',
        'active_employees': f'{counts["total_active"]:,}',
        'departments': f'{counts["departments"]:,}',
        'branches': f'{counts["branches"]:,}',
        'revenue': '0',
        'revenue_trend': '',
        'attendance': f'{counts["attendance"]:,}',
        'pending_approvals': counts['pending_approvals'],
        'payroll_cost': '0',
    })


@api_view(['GET'])
def superadmin_dashboard_view(request):
    counts = _dashboard_counts()
    return Response({
        'total_employees': f'{counts["total_users"]:,}',
        'total_departments': f'{counts["departments"]:,}',
        'active_users': f'{counts["total_active"]:,}',
        'attendance': f'{counts["attendance"]:,}',
        'pending_leaves': counts['pending_leaves'],
        'open_tasks': counts['open_tasks'],
        'present': f'{counts["attendance"]:,}',
        'absent': f'{counts["absent"]:,}',
        'late': f'{counts["late"]:,}',
        'users': _users_payload(),
    })


@api_view(['GET'])
def hr_dashboard_view(request):
    counts = _dashboard_counts()
    employees = _users_payload()
    active_employees = [employee for employee in employees if employee['trailing'] == 'Active']
    tl_creator_ids = list(User.objects.filter(role='tl').exclude(user_id='').values_list('user_id', flat=True))
    tl_meetings = MdMeeting.objects.filter(created_by__in=tl_creator_ids)[:10]
    hr_notifications = []
    for meeting in tl_meetings:
        participants = meeting.participants if isinstance(meeting.participants, list) else []
        participant_names = ', '.join(
            str(participant.get('title') or participant.get('name') or participant.get('email') or '').strip()
            for participant in participants
            if isinstance(participant, dict)
        )
        hr_notifications.append({
            'title': meeting.title,
            'subtitle': participant_names or meeting.location or meeting.meeting_type,
            'time': meeting.time_label,
            'date': meeting.date_label,
            'created_by': meeting.created_by,
            'trailing': 'TL Meeting',
        })
    return Response({
        'total_employees': f'{counts["total_users"]:,}',
        'present_today': f'{counts["total_active"]:,}',
        'absent_today': f'{counts["absent"]:,}',
        'on_leave': 0,
        'late_entry': 0,
        'wfh': 0,
        'open_positions_count': 0,
        'candidates_count': 0,
        'interviews_count': 0,
        'offers_count': 0,
        'pending_reviews': 0,
        'completed_reviews': 0,
        'high_performers': 0,
        'low_performers': 0,
        'payroll_month': timezone.localdate().strftime('%B %Y'),
        'payroll_processed': 0,
        'payroll_pending': counts['total_users'],
        'training_upcoming': 0,
        'training_completed': 0,
        'training_progress': 0,
        'calendar_month': timezone.localdate().strftime('%B %Y'),
        'calendar_day': timezone.localdate().day,
        'interview_date': '',
        'interview_time': '',
        'interview_mode': '',
        'interview_link': '',
        'employees': employees,
        'attendance_records': [
            {
                'name': employee['name'],
                'subtitle': 'Checked in' if employee['trailing'] == 'Active' else 'Not active',
                'time': 'Active' if employee['trailing'] == 'Active' else 'Inactive',
            }
            for employee in employees[:10]
        ],
        'leave_requests': [],
        'open_positions': [],
        'pipeline': [
            {'title': 'Applied', 'subtitle': '0 Candidates'},
            {'title': 'Screening', 'subtitle': '0 Candidates'},
            {'title': 'Interview', 'subtitle': '0 Candidates'},
            {'title': 'Offered', 'subtitle': '0 Candidates'},
            {'title': 'Hired', 'subtitle': '0 Candidates'},
        ],
        'candidates': active_employees[:5],
        'onboarding': [
            {'title': 'Create Employee', 'subtitle': 'Add new employee details'},
            {'title': 'Upload Documents', 'subtitle': 'Upload employee documents'},
            {'title': 'Assign Department', 'subtitle': 'Select department'},
            {'title': 'Assign Manager', 'subtitle': 'Select reporting manager'},
            {'title': 'Generate Employee ID', 'subtitle': 'Create employee ID'},
            {'title': 'Send Credentials', 'subtitle': 'Send login credentials'},
        ],
        'documents': [
            {'title': 'Employee Documents', 'subtitle': '0 Files'},
            {'title': 'Offer Letters', 'subtitle': '0 Files'},
            {'title': 'Company Policies', 'subtitle': '0 Files'},
            {'title': 'Certificates', 'subtitle': '0 Files'},
            {'title': 'Contracts', 'subtitle': '0 Files'},
        ],
        'meetings': [
            {
                'title': meeting.title,
                'subtitle': meeting.location or meeting.meeting_type,
                'time': meeting.time_label,
            }
            for meeting in MdMeeting.objects.all()[:5]
        ],
        'upcoming': [
            {
                'title': meeting.title,
                'subtitle': meeting.location or meeting.meeting_type,
                'time': meeting.time_label,
            }
            for meeting in MdMeeting.objects.all()[:3]
        ],
        'notifications': hr_notifications,
        'performers': active_employees[:5],
        'payroll_items': [
            {'title': 'Salary Structure', 'subtitle': 'Payroll configuration'},
            {'title': 'Payslip Status', 'subtitle': 'Employee payslips'},
            {'title': 'Bonus', 'subtitle': 'Bonus and incentives'},
            {'title': 'Payroll Reports', 'subtitle': 'Payroll analytics'},
        ],
        'training': [],
        'tasks': [],
    })


@api_view(['GET'])
def tl_dashboard_view(request):
    counts = _dashboard_counts()
    today = timezone.localdate()
    employee_users = User.objects.filter(is_active=True, role='employee').order_by('first_name', 'email')
    team = [
        {
            'title': f'{user.first_name} {user.last_name}'.strip() or user.email,
            'subtitle': user.get_role_display(),
            'status': 'Active' if user.is_active else 'Inactive',
            'trailing': 'Active' if user.is_active else 'Inactive',
            'email': user.email,
            'id': user.user_id,
        }
        for user in employee_users[:8]
    ]
    meetings = [
        {
            'title': meeting.title,
            'subtitle': meeting.location or meeting.meeting_type,
            'time': meeting.time_label,
            'status': meeting.get_status_display(),
        }
        for meeting in MdMeeting.objects.all()[:8]
    ]
    return Response({
        'my_tasks': counts['open_tasks'],
        'members_count': len(team),
        'projects_count': 0,
        'pending_approvals': counts['pending_approvals'],
        'tasks_done': '0',
        'tasks_progress': 0,
        'on_track': '0',
        'team_progress': 0,
        'check_in': '',
        'location': '',
        'accuracy': '',
        'work_type': '',
        'calendar_month': today.strftime('%B %Y'),
        'calendar_day': today.day,
        'team': team,
        'tasks': [],
        'projects': [],
        'leaves': [],
        'meetings': meetings,
        'reports': [],
        'approvals': [],
        'notifications': [],
    })


@api_view(['POST'])
def tl_meetings_view(request):
    payload = request.data.copy()
    created_by = payload.get('created_by', '')
    if created_by:
        try:
            creator = User.objects.get(user_id=created_by)
            payload['created_by'] = creator.user_id
        except User.DoesNotExist:
            try:
                creator = User.objects.get(email=created_by)
                payload['created_by'] = creator.user_id
            except User.DoesNotExist:
                pass
    serializer = MdMeetingSerializer(data=payload)
    if serializer.is_valid():
        meeting = serializer.save(status=request.data.get('status', 'upcoming'))
        return Response({'success': True, 'meeting': MdMeetingSerializer(meeting).data})
    return Response({'success': False, 'errors': serializer.errors}, status=400)


@api_view(['GET'])
def md_dashboard_view(request):
    meetings = MdMeeting.objects.all()[:10]
    users = User.objects.filter(is_active=True).exclude(role='md').order_by('first_name', 'email')
    participants = []
    for user in users:
        display_name = f'{user.first_name} {user.last_name}'.strip() or user.email
        participants.append({
            'name': display_name,
            'role': user.get_role_display(),
            'selected': False,
        })

    counts = _dashboard_counts()
    return Response({
        'total_revenue': '0',
        'total_employees': f'{counts["total_active"]:,}',
        'pending_approvals': counts['pending_approvals'],
        'meetings_today': counts['meetings_today'],
        'meetings': MdMeetingSerializer(meetings, many=True).data,
        'participants': participants,
    })


@api_view(['GET', 'POST'])
def md_meetings_view(request):
    if request.method == 'GET':
        meetings = MdMeeting.objects.all()
        return Response({'meetings': MdMeetingSerializer(meetings, many=True).data})

    serializer = MdMeetingSerializer(data=request.data)
    if serializer.is_valid():
        meeting = serializer.save(status=request.data.get('status', 'upcoming'))
        return Response({'success': True, 'meeting': MdMeetingSerializer(meeting).data})
    return Response({'success': False, 'errors': serializer.errors}, status=400)
