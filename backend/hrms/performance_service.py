from datetime import date, datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP

from django.db.models import Q
from django.utils import timezone

from .models import EmployeeAttendanceRecord, EmployeeLeaveRequest, TeamTask


PRIORITY_WEIGHTS = {
    'low': Decimal('1'),
    'medium': Decimal('2'),
    'high': Decimal('3'),
    'critical': Decimal('4'),
    'urgent': Decimal('4'),  # Backwards-compatible alias.
}


def period_bounds(period, today=None):
    today = today or timezone.localdate()
    value = str(period or '').strip()
    try:
        if value.startswith('Q'):
            quarter, year = value.split()
            quarter_number = int(quarter[1:])
            start = date(int(year), (quarter_number - 1) * 3 + 1, 1)
            end_month = start.month + 2
            next_month = date(start.year + (end_month // 12), end_month % 12 + 1, 1)
            return start, next_month - timedelta(days=1)
        parsed = datetime.strptime(value, '%Y-%m').date()
        next_month = date(parsed.year + (parsed.month // 12), parsed.month % 12 + 1, 1)
        return parsed.replace(day=1), next_month - timedelta(days=1)
    except (TypeError, ValueError):
        start_month = ((today.month - 1) // 3) * 3 + 1
        start = date(today.year, start_month, 1)
        next_month = date(today.year + ((start_month + 2) // 12), (start_month + 2) % 12 + 1, 1)
        return start, next_month - timedelta(days=1)


def _due_date(task):
    try:
        return datetime.strptime(str(task.due_date)[:10], '%Y-%m-%d').date()
    except (TypeError, ValueError):
        return None


def _working_dates(start, end):
    current = start
    while current <= end:
        if current.weekday() < 5:
            yield current
        current += timedelta(days=1)


def _attendance_discipline(employee_id, start, end):
    effective_end = min(end, timezone.localdate())
    expected = set(_working_dates(start, effective_end)) if effective_end >= start else set()
    for leave in EmployeeLeaveRequest.objects.filter(
        employee_id=employee_id,
        status='approved',
        from_date__lte=effective_end,
        to_date__gte=start,
    ):
        current = max(start, leave.from_date)
        while current <= min(effective_end, leave.to_date):
            expected.discard(current)
            current += timedelta(days=1)
    if not expected:
        return Decimal('100')
    records = EmployeeAttendanceRecord.objects.filter(
        employee_id=employee_id,
        attendance_date__in=expected,
    )
    credit = Decimal('0')
    for record in records:
        credit += Decimal('0.5') if 'half' in record.status.lower() else Decimal('1')
    return min(Decimal('100'), credit * Decimal('100') / len(expected))


def performance_rating(score):
    if score is None:
        return 'Not Enough Data'
    if score >= 90:
        return 'Outstanding'
    if score >= 80:
        return 'Excellent'
    if score >= 70:
        return 'Very Good'
    if score >= 60:
        return 'Good'
    if score >= 50:
        return 'Needs Improvement'
    return 'Poor'


def calculate_employee_performance(employee_id, period):
    start, end = period_bounds(period)
    tasks = list(TeamTask.objects.filter(
        assignee_id=employee_id,
        created_at__date__lte=end,
    ).filter(Q(due_date='') | Q(due_date__gte=start.isoformat())))
    excluded = [task for task in tasks if task.status == 'cancelled' or (
        task.status == 'blocked' and task.blocked_approved
    )]
    valid = [task for task in tasks if task not in excluded]
    if not valid:
        return {
            'score': None,
            'rating': 'Not Enough Data',
            'provisional': False,
            'breakdown': {},
            'task_summary': {'valid': 0, 'excluded': len(excluded)},
            'explanation': 'No valid assigned tasks were found for this period.',
        }

    def weight(task):
        return PRIORITY_WEIGHTS.get(task.priority.lower(), Decimal('2'))

    total_weight = sum((weight(task) for task in valid), Decimal('0'))
    approved = [task for task in valid if task.status == 'completed' and task.review_status == 'approved']
    completed_weight = sum((weight(task) for task in approved), Decimal('0'))
    completion = completed_weight * 100 / total_weight
    quality = (
        sum((Decimal(task.quality_score) * weight(task) for task in approved), Decimal('0')) / completed_weight
        if completed_weight else Decimal('0')
    )
    quality = max(Decimal('0'), min(Decimal('100'), quality))
    on_time_weight = sum((
        weight(task) for task in approved
        if task.completed_at and (_due_date(task) is None or timezone.localtime(task.completed_at).date() <= _due_date(task))
    ), Decimal('0'))
    on_time = on_time_weight * 100 / total_weight
    productivity = Decimal(len(approved)) * 100 / len(valid)
    attendance = _attendance_discipline(employee_id, start, end)
    components = {
        'task_completion': completion,
        'task_quality': quality,
        'on_time_completion': on_time,
        'productivity': productivity,
        'attendance_discipline': attendance,
    }
    score = (
        completion * Decimal('0.40') + quality * Decimal('0.25') +
        on_time * Decimal('0.20') + productivity * Decimal('0.10') +
        attendance * Decimal('0.05')
    ).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    provisional = any(task.status == 'completed' and task.review_status == 'pending' for task in valid)
    breakdown = {
        key: {
            'score': float(value.quantize(Decimal('0.01'))),
            'weight': weight_value,
            'contribution': float((value * Decimal(str(weight_value))).quantize(Decimal('0.01'))),
        }
        for key, value, weight_value in [
            ('task_completion', completion, .40), ('task_quality', quality, .25),
            ('on_time_completion', on_time, .20), ('productivity', productivity, .10),
            ('attendance_discipline', attendance, .05),
        ]
    }
    return {
        'score': float(score),
        'rating': performance_rating(score),
        'provisional': provisional,
        'breakdown': breakdown,
        'task_summary': {
            'valid': len(valid), 'approved_completed': len(approved),
            'pending_review': sum(task.status == 'completed' and task.review_status == 'pending' for task in valid),
            'excluded': len(excluded),
        },
        'explanation': (
            f'{len(approved)} of {len(valid)} valid tasks are completed and approved. '
            'Working hours and checkout time do not add performance points.'
        ),
    }
