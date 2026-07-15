import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'employee_models.dart';
import 'employee_service.dart';
import 'employee_shared.dart';

class EmployeeMeetingsScreen extends StatefulWidget {
  final String userId;
  final EmployeeDashboardData data;
  final EmployeeService service;

  const EmployeeMeetingsScreen({
    super.key,
    required this.userId,
    required this.data,
    required this.service,
  });

  @override
  State<EmployeeMeetingsScreen> createState() => _EmployeeMeetingsScreenState();
}

class _EmployeeMeetingsScreenState extends State<EmployeeMeetingsScreen> {
  static const MethodChannel _channel = MethodChannel('hrms/location');

  late EmployeeDashboardData _data = widget.data;
  bool _loading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final email = '${_data.profile['email'] ?? ''}';
      final latest = await widget.service.fetchDashboard(widget.userId, email);
      if (mounted) setState(() => _data = latest);
    } catch (_) {
      // Keep the current meeting list if the refresh cannot reach the backend.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetings = _selectedDate == null
        ? _data.meetings
        : _data.meetings
            .where((item) => _isSameDay(_meetingDate(item), _selectedDate!))
            .toList();
    return EmployeePage(
      title: 'Meetings',
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_loading) const SizedBox(height: 10),
        EmployeeCard(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: EmployeeColors.purple.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: EmployeeColors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'All Scheduled Meetings'
                          : _formatSelectedDate(_selectedDate!),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _selectedDate == null
                          ? 'Pick a date to view meetings by calendar'
                          : '${meetings.length} meeting(s) on this date',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Select date',
                onPressed: _pickDate,
                icon: const Icon(
                  Icons.event_rounded,
                  color: EmployeeColors.blue,
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  tooltip: 'Show all',
                  onPressed: () => setState(() => _selectedDate = null),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (meetings.isEmpty)
          EmployeeCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _selectedDate == null
                      ? 'No meetings scheduled'
                      : 'No meetings scheduled on this date',
                ),
              ),
            ),
          )
        else
          ...meetings.map(
            (item) => EmployeeListTile(
              icon: Icons.video_call_rounded,
              title: '${item['title'] ?? ''}',
              subtitle: _subtitle(item),
              trailing: 'Join',
              color: EmployeeColors.green,
              onTap: () => _openMeetingDetails(context, item),
            ),
          ),
        const SizedBox(height: 8),
        EmployeeCard(
          child: Column(
            children: const [
              Text(
                'Meeting Reminder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Upcoming TL meetings will appear here with their join link.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openMeetingDetails(BuildContext context, Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Meeting Details')),
          body: EmployeeMeetingDetailsScreen(meeting: item),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 2),
    );
    if (selected != null && mounted) {
      setState(() => _selectedDate = selected);
    }
  }

  DateTime? _meetingDate(Map<String, dynamic> item) {
    final raw = '${item['date'] ?? item['date_label'] ?? ''}'.trim();
    return EmployeeMeetingDetailsScreen.parseMeetingDate(raw);
  }

  bool _isSameDay(DateTime? first, DateTime second) {
    if (first == null) return false;
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatSelectedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  String _subtitle(Map<String, dynamic> item) {
    final date = '${item['date'] ?? item['date_label'] ?? ''}'.trim();
    final time = '${item['time'] ?? item['time_label'] ?? ''}'.trim();
    final mode = '${item['mode'] ?? item['meeting_type'] ?? ''}'.trim();
    final parts = [
      if (date.isNotEmpty) date,
      if (time.isNotEmpty) time,
      if (mode.isNotEmpty) mode,
    ];
    return parts.join(' - ');
  }

  Future<void> _joinMeeting(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final link = '${item['link'] ?? item['location'] ?? ''}'.trim();
    if (!link.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting link is not available.')),
      );
      return;
    }
    try {
      final opened = await _channel.invokeMethod<bool>('openUrl', {'url': link});
      if (opened != true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open meeting link.')),
        );
      }
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to open meeting link.')),
      );
    }
  }
}

class EmployeeMeetingDetailsScreen extends StatelessWidget {
  static const MethodChannel _channel = MethodChannel('hrms/location');

  final Map<String, dynamic> meeting;

  const EmployeeMeetingDetailsScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    final agenda = meeting['agenda'] is List
        ? (meeting['agenda'] as List)
            .where((item) => item is! Map || item['_meta'] != 'meeting')
            .toList()
        : const [];
    final link = _meetingLink(meeting);
    final canJoin = link.isNotEmpty && _isMeetingDate(meeting);
    final joinColor = canJoin ? EmployeeColors.blue : Colors.blueGrey;
    return EmployeePage(
      title: 'Meeting Details',
      children: [
        EmployeeCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: EmployeeColors.purple.withAlpha(35), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.video_call_rounded, color: EmployeeColors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${meeting['title'] ?? 'Meeting'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${meeting['platform'] ?? meeting['mode'] ?? ''}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              ])),
            ]),
            const SizedBox(height: 18),
            _MeetingDetailRow(Icons.calendar_month_rounded, 'Date', '${meeting['date'] ?? meeting['date_label'] ?? ''}'),
            _MeetingDetailRow(Icons.schedule_rounded, 'Time', '${meeting['time'] ?? meeting['time_label'] ?? ''}'),
            _MeetingDetailRow(Icons.timer_rounded, 'Duration', '${meeting['duration'] ?? ''}'),
            if ('${meeting['description'] ?? ''}'.trim().isNotEmpty)
              _MeetingDetailRow(Icons.notes_rounded, 'Description', '${meeting['description']}'),
          ]),
        ),
        const SizedBox(height: 12),
        EmployeeCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Meeting Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            InkWell(
              onTap: canJoin ? () => _openLink(context, link) : () => _showJoinUnavailable(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: joinColor.withAlpha(24), borderRadius: BorderRadius.circular(8), border: Border.all(color: joinColor.withAlpha(90))),
                child: Row(children: [
                  Icon(Icons.link_rounded, color: joinColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(link.isEmpty ? 'Meeting link is not available' : link, style: const TextStyle(fontWeight: FontWeight.w800))),
                  Icon(Icons.open_in_new_rounded, color: joinColor, size: 18),
                ]),
              ),
            ),
            if (!canJoin && link.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Join button will be enabled on the meeting date.', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: joinColor,
                  disabledBackgroundColor: Colors.blueGrey.withAlpha(130),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                ),
                onPressed: canJoin ? () => _openLink(context, link) : null,
                icon: const Icon(Icons.video_call_rounded),
                label: Text(canJoin ? 'Join Meeting' : 'Available on Meeting Date', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
        if (agenda.isNotEmpty) ...[
          const SizedBox(height: 12),
          EmployeeCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Agenda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...agenda.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_circle_outline_rounded, color: EmployeeColors.green, size: 17),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$item', style: const TextStyle(fontWeight: FontWeight.w700))),
                    ]),
                  )),
            ]),
          ),
        ],
      ],
    );
  }

  static String _meetingLink(Map<String, dynamic> item) {
    final link = '${item['meeting_link'] ?? item['link'] ?? item['location'] ?? ''}'.trim();
    if (link.contains('meet.bitbyte.in')) {
      return _defaultPlatformLink('${item['platform'] ?? item['mode'] ?? ''}');
    }
    return link;
  }

  static String _defaultPlatformLink(String platform) {
    final value = platform.toLowerCase();
    if (value.contains('google')) return 'https://meet.google.com/new';
    if (value.contains('team')) return 'https://teams.microsoft.com/';
    return 'https://zoom.us/join';
  }

  static bool _isMeetingDate(Map<String, dynamic> item) {
    final raw = '${item['date'] ?? item['date_label'] ?? ''}'.trim();
    final date = parseMeetingDate(raw);
    if (date == null) return true;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static DateTime? parseMeetingDate(String value) {
    final normalized = value.trim();
    final dashParts = normalized.split('-');
    if (dashParts.length == 3) {
      final first = int.tryParse(dashParts[0]);
      final second = int.tryParse(dashParts[1]);
      final third = int.tryParse(dashParts[2]);
      if (first != null && second != null && third != null) {
        if (dashParts[0].length == 4) return DateTime(first, second, third);
        return DateTime(third, second, first);
      }
    }
    return DateTime.tryParse(normalized);
  }

  static void _showJoinUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Join button will be enabled on the meeting date.')),
    );
  }

  static Future<void> _openLink(BuildContext context, String link) async {
    if (!link.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting link is not available.')),
      );
      return;
    }
    try {
      final opened = await _channel.invokeMethod<bool>('openUrl', {'url': link});
      if (opened != true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open meeting link.')),
        );
      }
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to open meeting link.')),
      );
    }
  }
}

class _MeetingDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MeetingDetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: EmployeeColors.blue, size: 19),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        ])),
      ]),
    );
  }
}
