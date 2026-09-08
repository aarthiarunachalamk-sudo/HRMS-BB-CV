from datetime import timedelta

from django.test import TestCase
from django.utils import timezone

from .models import TeamTask
from .performance_service import calculate_employee_performance


class WeightedPerformanceServiceTests(TestCase):
    employee_id = 'BBTESTPERF01'

    def setUp(self):
        today = timezone.localdate()
        self.period = f'Q{((today.month - 1) // 3) + 1} {today.year}'
        self.due = (today + timedelta(days=2)).isoformat()

    def task(self, **overrides):
        values = {
            'title': 'Performance task',
            'assignee_id': self.employee_id,
            'priority': 'Medium',
            'due_date': self.due,
            'status': 'pending',
        }
        values.update(overrides)
        return TeamTask.objects.create(**values)

    def test_unfinished_task_stays_low_regardless_of_working_hours(self):
        self.task()
        result = calculate_employee_performance(self.employee_id, self.period)
        self.assertLess(result['score'], 50)
        self.assertEqual(result['task_summary']['approved_completed'], 0)

    def test_three_approved_quality_tasks_score_high(self):
        for priority in ('Low', 'High', 'Critical'):
            self.task(
                title=f'{priority} task', priority=priority,
                status='completed', review_status='approved',
                quality_score=90, completed_at=timezone.now(),
            )
        result = calculate_employee_performance(self.employee_id, self.period)
        self.assertGreaterEqual(result['score'], 80)
        self.assertEqual(result['rating'], 'Outstanding')

    def test_reopened_task_loses_completion_credit(self):
        task = self.task(
            status='completed', review_status='approved', quality_score=100,
            completed_at=timezone.now(),
        )
        self.assertGreater(calculate_employee_performance(self.employee_id, self.period)['score'], 80)
        task.status = 'reopened'
        task.save(update_fields=['status'])
        self.assertLess(calculate_employee_performance(self.employee_id, self.period)['score'], 50)

    def test_pending_quality_review_is_provisional(self):
        self.task(status='completed', review_status='pending', completed_at=timezone.now())
        result = calculate_employee_performance(self.employee_id, self.period)
        self.assertTrue(result['provisional'])

    def test_no_tasks_returns_not_enough_data(self):
        result = calculate_employee_performance(self.employee_id, self.period)
        self.assertIsNone(result['score'])
        self.assertEqual(result['rating'], 'Not Enough Data')
