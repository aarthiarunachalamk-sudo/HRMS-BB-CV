bool _missing(Object? value) =>
    value == null ||
    const ['', '--', '--:--', 'null'].contains('$value'.trim());

/// Compatibility with servers that omit duration fields on HTTP 202.
/// This only fills the request summary; it never records a checkout.
Map<String, dynamic> attendanceRequestSummary(
  Map<String, dynamic> response,
  DateTime capturedAt,
) {
  final result = Map<String, dynamic>.from(response);
  if (result['permission_required'] != true) return result;
  if (_missing(result['requested_check_out_time'])) {
    final hour = capturedAt.hour % 12 == 0 ? 12 : capturedAt.hour % 12;
    String two(int value) => value.toString().padLeft(2, '0');
    result['requested_check_out_time'] =
        '${two(hour)}:${two(capturedAt.minute)}:${two(capturedAt.second)} ${capturedAt.hour < 12 ? 'AM' : 'PM'}';
  }
  if (!_missing(result['working_hours'])) return result;
  DateTime? start = DateTime.tryParse(
    '${result['check_in_timestamp'] ?? ''}',
  )?.toLocal();
  var approximate = false;
  if (start == null) {
    final date = DateTime.tryParse('${result['date'] ?? ''}');
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)$',
    ).firstMatch('${result['check_in'] ?? ''}'.trim().toUpperCase());
    if (date == null || match == null) return result;
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    final second = int.parse(match[3] ?? '0');
    if (hour < 1 || hour > 12 || minute > 59 || second > 59) return result;
    start = DateTime(
      date.year,
      date.month,
      date.day,
      hour % 12 + (match[4] == 'PM' ? 12 : 0),
      minute,
      second,
    );
    approximate = match[3] == null;
  }
  if (capturedAt.isBefore(start)) return result;
  final duration = capturedAt.difference(start);
  final seconds = duration.inSeconds;
  String two(int value) => value.toString().padLeft(2, '0');
  result['working_hours'] =
      '${two(seconds ~/ 3600)}h ${two(seconds ~/ 60 % 60)}m'
      '${approximate ? '' : ' ${two(seconds % 60)}s'}';
  result['working_hours_approximate'] = approximate;
  result['working_hours_as_of'] = capturedAt.toIso8601String();
  if (!approximate) result['working_seconds'] = seconds;
  return result;
}
