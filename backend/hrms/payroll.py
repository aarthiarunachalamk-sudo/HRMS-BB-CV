from calendar import monthrange
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP

from django.core.files.base import ContentFile
from django.utils import timezone

from .models import (
    EmployeeAccount,
    EmployeeAttendanceRecord,
    EmployeeLeaveRequest,
    Payslip,
    SalaryStructure,
)


def payslip_payload(payslip, request=None):
    download_url = ''
    if payslip and payslip.pdf_file:
        download_url = payslip.pdf_file.url
        if request is not None:
            download_url = request.build_absolute_uri(download_url)
    return {
        'id': payslip.id,
        'employee_id': payslip.employee_id,
        'month': f'{_month_name(payslip.month)} {payslip.year}',
        'year': payslip.year,
        'month_number': payslip.month,
        'working_days': payslip.working_days,
        'paid_days': payslip.paid_days,
        'lop_days': payslip.lop_days,
        'overtime_minutes': payslip.overtime_minutes,
        'overtime_hours': _money(Decimal(payslip.overtime_minutes) / Decimal(60)),
        'gross_salary': _money(payslip.gross_salary),
        'total_earnings': _money(payslip.total_earnings),
        'total_deductions': _money(payslip.total_deductions),
        'net_salary': _money(payslip.net_salary),
        'earnings': payslip.earnings,
        'deductions': payslip.deductions,
        'status': payslip.status.title(),
        'paid_date': payslip.paid_date.isoformat() if payslip.paid_date else '',
        'generated_at': payslip.generated_at.isoformat() if payslip.generated_at else '',
        'download_url': download_url,
    }


def latest_payslip_for_employee(employee_id, request=None):
    payslip = Payslip.objects.filter(employee_id=employee_id).first()
    if not payslip:
        return {}
    return payslip_payload(payslip, request)


def generate_payroll_for_month(year, month, generated_by=''):
    accounts = EmployeeAccount.objects.filter(is_active=True).select_related('registration')
    payslips = [
        calculate_employee_payslip(account, year, month, generated_by)
        for account in accounts
    ]
    return payslips


def calculate_employee_payslip(account, year, month, generated_by=''):
    structure, _ = SalaryStructure.objects.get_or_create(employee_id=account.employee_id)
    start_date = date(year, month, 1)
    end_date = date(year, month, monthrange(year, month)[1])
    working_days = _working_days(start_date, end_date)

    attendance = EmployeeAttendanceRecord.objects.filter(
        employee_id=account.employee_id,
        attendance_date__gte=start_date,
        attendance_date__lte=end_date,
    )
    present_days = 0
    overtime_minutes = 0
    for record in attendance:
        status = (record.status or '').lower()
        if 'half' in status:
            present_days += Decimal('0.5')
        elif any(value in status for value in ['present', 'late']):
            present_days += Decimal('1')
        overtime_minutes += _attendance_overtime_minutes(record)

    approved_leaves = EmployeeLeaveRequest.objects.filter(
        employee_id=account.employee_id,
        status='approved',
        from_date__lte=end_date,
        to_date__gte=start_date,
    )
    paid_leave_days = Decimal('0')
    explicit_lop_days = Decimal('0')
    for leave in approved_leaves:
        overlap_start = max(leave.from_date, start_date)
        overlap_end = min(leave.to_date, end_date)
        days = Decimal((overlap_end - overlap_start).days + 1)
        if leave.leave_type.upper() == 'LOP':
            explicit_lop_days += days
        else:
            paid_leave_days += days

    paid_days = min(Decimal(working_days), present_days + paid_leave_days)
    lop_days = max(Decimal('0'), Decimal(working_days) - paid_days) + explicit_lop_days

    earnings = {
        'Basic Salary': structure.basic_salary,
        'HRA': structure.hra,
        'Conveyance Allowance': structure.conveyance_allowance,
        'Medical Allowance': structure.medical_allowance,
        'Special Allowance': structure.special_allowance,
        'Other Allowance': structure.other_allowance,
    }
    gross_salary = sum(earnings.values(), Decimal('0'))
    per_day_salary = gross_salary / Decimal(working_days or 1)
    overtime_amount = (Decimal(overtime_minutes) / Decimal(60)) * structure.overtime_rate_per_hour
    lop_deduction = per_day_salary * lop_days

    earnings['Overtime'] = overtime_amount
    deductions = {
        'PF': structure.pf_employee,
        'ESI': structure.esi_employee,
        'Professional Tax': structure.professional_tax,
        'TDS': structure.tds,
        'LOP Deduction': lop_deduction,
        'Other Deduction': structure.other_deduction,
    }

    total_earnings = sum(earnings.values(), Decimal('0'))
    total_deductions = sum(deductions.values(), Decimal('0'))
    net_salary = max(Decimal('0'), total_earnings - total_deductions)

    payslip, _ = Payslip.objects.update_or_create(
        employee_id=account.employee_id,
        year=year,
        month=month,
        defaults={
            'working_days': working_days,
            'paid_days': int(paid_days),
            'lop_days': int(lop_days),
            'overtime_minutes': overtime_minutes,
            'gross_salary': _round(gross_salary),
            'total_earnings': _round(total_earnings),
            'total_deductions': _round(total_deductions),
            'net_salary': _round(net_salary),
            'earnings': {key: _money(value) for key, value in earnings.items()},
            'deductions': {key: _money(value) for key, value in deductions.items()},
            'status': 'approved',
            'generated_by': generated_by,
            'paid_date': timezone.localdate(),
        },
    )
    payslip.pdf_file.save(
        f'{account.employee_id}-{year}-{month:02d}-payslip.pdf',
        ContentFile(_simple_pdf(_payslip_lines(account, payslip))),
        save=True,
    )
    return payslip


def _payslip_lines(account, payslip):
    name = f'{account.registration.first_name} {account.registration.last_name}'.strip()
    lines = [
        'BitByte HRMS Payslip',
        f'Employee: {name or account.employee_id}',
        f'Employee ID: {account.employee_id}',
        f'Pay Period: {_month_name(payslip.month)} {payslip.year}',
        f'Working Days: {payslip.working_days}',
        f'Paid Days: {payslip.paid_days}',
        f'LOP Days: {payslip.lop_days}',
        '',
        'Earnings',
        *[f'{key}: Rs {value}' for key, value in payslip.earnings.items()],
        '',
        'Deductions',
        *[f'{key}: Rs {value}' for key, value in payslip.deductions.items()],
        '',
        f'Gross Salary: Rs {_money(payslip.gross_salary)}',
        f'Total Deductions: Rs {_money(payslip.total_deductions)}',
        f'Net Salary: Rs {_money(payslip.net_salary)}',
    ]
    return lines


def _simple_pdf(lines):
    escaped = [line.replace('\\', '\\\\').replace('(', '\\(').replace(')', '\\)') for line in lines]
    content = ['BT', '/F1 12 Tf', '50 790 Td']
    for index, line in enumerate(escaped):
        if index:
            content.append('0 -18 Td')
        content.append(f'({line}) Tj')
    content.append('ET')
    stream = '\n'.join(content).encode('latin-1', errors='replace')
    objects = [
        b'1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n',
        b'2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n',
        b'3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj\n',
        b'4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n',
        b'5 0 obj << /Length ' + str(len(stream)).encode() + b' >> stream\n' + stream + b'\nendstream endobj\n',
    ]
    pdf = b'%PDF-1.4\n'
    offsets = []
    for obj in objects:
        offsets.append(len(pdf))
        pdf += obj
    xref = len(pdf)
    pdf += b'xref\n0 6\n0000000000 65535 f \n'
    for offset in offsets:
        pdf += f'{offset:010d} 00000 n \n'.encode()
    pdf += b'trailer << /Size 6 /Root 1 0 R >>\nstartxref\n' + str(xref).encode() + b'\n%%EOF'
    return pdf


def _working_days(start_date, end_date):
    days = 0
    current = start_date
    while current <= end_date:
        if current.weekday() < 5:
            days += 1
        current = current + timedelta(days=1)
    return days


def _attendance_overtime_minutes(record):
    """Calculate overtime without relying on a non-existent model field."""
    if not record.check_in or not record.check_out:
        return 0
    gross_minutes = max(
        0,
        int((record.check_out - record.check_in).total_seconds() // 60),
    )
    # Attendance uses an eight-hour workday with a one-hour lunch break.
    worked_minutes = max(0, gross_minutes - 60)
    return max(0, worked_minutes - (8 * 60))


def _round(value):
    return Decimal(value).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


def _money(value):
    return str(_round(value))


def _month_name(month):
    return date(2000, month, 1).strftime('%B')
