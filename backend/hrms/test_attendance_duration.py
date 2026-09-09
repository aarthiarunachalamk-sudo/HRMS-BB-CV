from datetime import datetime, timedelta, timezone

from django.test import SimpleTestCase

from .employee_views import _attendance_calculation


IST = timezone(timedelta(hours=5, minutes=30))


class AttendanceDurationTests(SimpleTestCase):
    def test_seconds_are_preserved(self):
        start = datetime(2026, 9, 9, 9, 0, 35, tzinfo=IST)
        end = datetime(2026, 9, 9, 18, 2, 10, tzinfo=IST)
        result = _attendance_calculation(start, end, 330)
        self.assertEqual(result['working_seconds'], 8 * 3600 + 95)
        self.assertEqual(result['working_minutes'], 481)
        self.assertEqual(result['working_hours'], '08h 01m 35s')

    def test_partial_lunch_is_subtracted_before_rounding(self):
        start = datetime(2026, 9, 9, 12, 59, 30, tzinfo=IST)
        end = datetime(2026, 9, 9, 13, 0, 10, tzinfo=IST)
        result = _attendance_calculation(start, end, 330)
        self.assertEqual(result['working_seconds'], 30)
        self.assertEqual(result['working_minutes'], 0)
        self.assertEqual(result['working_hours'], '00h 00m 30s')

    def test_same_instant_with_different_offsets_has_zero_duration(self):
        start = datetime(2026, 9, 9, 9, 0, tzinfo=IST)
        result = _attendance_calculation(start, start.astimezone(timezone.utc), 330)
        self.assertEqual(result['working_seconds'], 0)

    def test_overnight_elapsed_time(self):
        start = datetime(2026, 9, 9, 23, 59, 45, tzinfo=IST)
        end = datetime(2026, 9, 10, 0, 1, 5, tzinfo=IST)
        self.assertEqual(_attendance_calculation(start, end, 330)['working_hours'], '00h 01m 20s')

    def test_no_checkout_has_no_finished_duration(self):
        result = _attendance_calculation(datetime(2026, 9, 9, 9, tzinfo=IST))
        self.assertEqual(result['working_hours'], '--')
        self.assertEqual(result['working_seconds'], 0)
