from rest_framework.decorators import api_view
from rest_framework.response import Response
from .serializers import LoginSerializer, CreateUserSerializer, EmployeeRegistrationSerializer
from .models import User, EmployeeRegistration
import os
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from .models import EmployeeAccount
from .serializers import EmployeeAccountSerializer
import random
import string

@api_view(['POST'])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']
        try:
            user = User.objects.get(email=email)
            if user.check_password(password):
                # Check if employee account exists and OTC is still active
                try:
                    from .models import EmployeeAccount
                    emp_account = EmployeeAccount.objects.get(employee_email=user.email)
                    if emp_account.otc == password:
                        return Response({
                            'success': True,
                            'requires_password_change': True,
                            'user_id': user.user_id,
                            'email': user.email,
                        })
                except:
                    pass
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

@api_view(['POST'])
def register_employee_view(request):
    serializer = EmployeeRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        emp = serializer.save()
        doc_fields = [
            'doc_passport_photo', 'doc_aadhar', 'doc_pan', 'doc_bank_passbook',
            'doc_10th', 'doc_12th', 'doc_degree', 'doc_consolidated',
            'doc_resume', 'doc_experience_cert', 'doc_relieving', 'doc_salary_slips',
            'doc_passport_copy', 'doc_driving', 'doc_vaccination',
        ]
        updated = False
        for field in doc_fields:
            if field in request.FILES:
                setattr(emp, field, request.FILES[field])
                updated = True
        if updated:
            emp.save()
        return Response({'success': True, 'message': 'Registration submitted!', 'id': emp.id})
    return Response({'success': False, 'errors': serializer.errors}, status=400)

@api_view(['GET'])
def get_registered_employees_view(request):
    employees = EmployeeRegistration.objects.all().order_by('-submitted_at')
    serializer = EmployeeRegistrationSerializer(employees, many=True)
    return Response({'success': True, 'employees': serializer.data})


@api_view(['PATCH'])
def update_employee_status_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)
        emp.status = request.data.get('status', emp.status)
        emp.save()
        return Response({'success': True, 'message': 'Status updated!'})
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Not found'}, status=404)



def send_email(to_email, subject, html_content):
    try:
        sg = SendGridAPIClient(os.getenv('SENDGRID_API_KEY'))
        message = Mail(
            from_email=os.getenv('EMAIL_FROM', 'noreply@bitbyte.com'),
            to_emails=to_email,
            subject=subject,
            html_content=html_content,
        )
        sg.send(message)
    except Exception as e:
        print(f'SendGrid error: {e}')


@api_view(['POST'])
def verify_employee_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)
        emp.status = 'approved'
        emp.save()
        return Response({'success': True, 'message': 'Employee verified!'})
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Not found'}, status=404)


@api_view(['POST'])
def reject_employee_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)
        emp.status = 'rejected'
        emp.save()

        # Send rejection email
        html = f"""
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:20px;border:1px solid #eee;border-radius:10px;">
            <h2 style="color:#e53e3e;">Application Update - Bitbyte</h2>
            <p>Dear <b>{emp.first_name} {emp.last_name}</b>,</p>
            <p>We regret to inform you that your employment application has been <b style="color:#e53e3e;">rejected</b>.</p>
            <p>If you have any questions, please contact our HR team.</p>
            <br/>
            <p>Regards,</p>
            <p><b>Bitbyte HR Team</b></p>
        </div>
        """
        send_email(emp.personal_email, 'Application Status - Bitbyte', html)

        return Response({'success': True, 'message': 'Employee rejected and email sent!'})
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Not found'}, status=404)


@api_view(['POST'])
def add_employee_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)

        # Create employee account
        account = EmployeeAccount(
            registration=emp,
            employee_email=request.data.get('employee_email'),
            department=request.data.get('department'),
            designation=request.data.get('designation'),
            date_of_joining=request.data.get('date_of_joining'),
            employment_type=request.data.get('employment_type'),
            reporting_tl=request.data.get('reporting_tl', ''),
            work_location=request.data.get('work_location', ''),
        )
        account.save()

        # Create User account with OTC as password
        user = User(
            email=account.employee_email,
            role='employee',
            first_name=emp.first_name,
            last_name=emp.last_name,
            phone=emp.mobile,
        )
        user.set_password(account.otc)
        user.user_id = account.employee_id
        user.save()

        # Send welcome email with OTC
        html = f"""
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:30px;border:1px solid #eee;border-radius:10px;">
            <h2 style="color:#4FACFE;">Welcome to Bitbyte! 🎉</h2>
            <p>Dear <b>{emp.first_name} {emp.last_name}</b>,</p>
            <p>Congratulations! Your employment has been confirmed.</p>
            <div style="background:#f0f9ff;padding:20px;border-radius:8px;margin:20px 0;">
                <h3 style="margin:0 0 10px 0;color:#2d3748;">Your Login Credentials</h3>
                <p><b>Employee ID:</b> {account.employee_id}</p>
                <p><b>Email:</b> {account.employee_email}</p>
                <p><b>One Time Password (OTC):</b> <span style="font-size:20px;color:#4FACFE;font-weight:bold;">{account.otc}</span></p>
            </div>
            <div style="background:#f0fff4;padding:20px;border-radius:8px;margin:20px 0;">
                <h3 style="margin:0 0 10px 0;color:#2d3748;">Employment Details</h3>
                <p><b>Department:</b> {account.department}</p>
                <p><b>Designation:</b> {account.designation}</p>
                <p><b>Date of Joining:</b> {account.date_of_joining}</p>
                <p><b>Employment Type:</b> {account.employment_type}</p>
                <p><b>Reporting TL:</b> {account.reporting_tl or 'N/A'}</p>
                <p><b>Work Location:</b> {account.work_location or 'N/A'}</p>
            </div>
            <p>Please login with your Employee ID or Email and the OTC above.</p>
            <p>You will be asked to change your password on first login.</p>
            <p style="color:#e53e3e;"><b>Note: This OTC is valid for first login only.</b></p>
            <br/>
            <p>Regards,</p>
            <p><b>Bitbyte HR Team</b></p>
        </div>
        """
        send_email(account.employee_email, 'Welcome to Bitbyte - Your Login Credentials', html)
        # Also send to personal email
        send_email(emp.personal_email, 'Welcome to Bitbyte - Your Login Credentials', html)

        return Response({
            'success': True,
            'employee_id': account.employee_id,
            'otc': account.otc,
            'message': 'Employee added and credentials sent!'
        })
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Registration not found'}, status=404)
    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=400)        

@api_view(['POST'])
def change_password_view(request):
    employee_id = request.data.get('employee_id')
    otc = request.data.get('otc')
    new_password = request.data.get('new_password')

    try:
        user = User.objects.get(user_id=employee_id)
        if not user.check_password(otc):
            return Response({'success': False, 'message': 'Invalid OTC'}, status=400)
        user.set_password(new_password)
        user.save()
        return Response({'success': True, 'message': 'Password changed!'})
    except User.DoesNotExist:
        return Response({'success': False, 'message': 'Employee not found'}, status=404)        