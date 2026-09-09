import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/attendance_request_summary.dart';

void main() {
  test(
    'legacy pending response displays request time and approximate hours',
    () {
      final response = attendanceRequestSummary({
        'permission_required': true,
        'date': '2026-09-09',
        'check_in': '12:49 PM',
        'check_out': '--:--',
        'working_hours': '--',
      }, DateTime(2026, 9, 9, 13, 9, 15));
      expect(response['requested_check_out_time'], '01:09:15 PM');
      expect(response['working_hours'], '00h 11m');
      expect(response['working_hours_approximate'], true);
      expect(response['check_out'], '--:--');
    },
  );

  test('full check-in timestamp preserves seconds and subtracts lunch', () {
    final response = attendanceRequestSummary({
      'permission_required': true,
      'check_in_timestamp': DateTime(2026, 9, 9, 12, 49, 23).toIso8601String(),
    }, DateTime(2026, 9, 9, 13, 9, 15));
    expect(response['working_hours'], '00h 10m 37s');
    expect(response['working_seconds'], 637);
    expect(response['working_hours_approximate'], false);
  });

  test(
    'server duration is authoritative and missing checkin is not invented',
    () {
      final capturedAt = DateTime(2026, 9, 9, 13, 9, 15);
      expect(
        attendanceRequestSummary({
          'permission_required': true,
          'working_hours': '00h 09m 42s',
        }, capturedAt)['working_hours'],
        '00h 09m 42s',
      );
      expect(
        attendanceRequestSummary({
          'permission_required': true,
          'working_hours': '--',
        }, capturedAt)['working_hours'],
        '--',
      );
      expect(attendanceRequestSummary({'check_out': '06:00 PM'}, capturedAt), {
        'check_out': '06:00 PM',
      });
    },
  );
}
