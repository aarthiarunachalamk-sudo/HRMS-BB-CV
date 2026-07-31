import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/separated_date_picker.dart';

import 'hr_service.dart';
import 'hr_shared.dart';

class HrMeetingsScreen extends StatefulWidget {
  final String userId;

  const HrMeetingsScreen({super.key, required this.userId});

  @override
  State<HrMeetingsScreen> createState() => _HrMeetingsScreenState();
}

class _HrMeetingsScreenState extends State<HrMeetingsScreen> {
  static const MethodChannel _platformChannel = MethodChannel('hrms/location');
  final HrService _service = HrService();

  List<Map<String, dynamic>> _meetings = const [];
  List<Map<String, dynamic>> _participants = const [];
  Map<String, dynamic> _counts = const {};
  late DateTime _displayMonth;
  DateTime? _selectedDate;
  String _status = 'upcoming';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await _service.fetchMeetingCenter(widget.userId);
      if (!mounted) return;
      setState(() {
        _meetings = _mapList(response['meetings']);
        _participants = _mapList(response['participants']);
        _counts = response['counts'] is Map
            ? Map<String, dynamic>.from(response['counts'] as Map)
            : const {};
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _visibleMeetings {
    return _meetings.where((meeting) {
      final status = '${meeting['status'] ?? 'upcoming'}'.toLowerCase();
      if (_status != 'all' && status != _status) return false;
      final selected = _selectedDate;
      if (selected == null) return true;
      return _isSameDay(_meetingDate(meeting), selected);
    }).toList()..sort((first, second) {
      final firstDate = _meetingDateTime(first);
      final secondDate = _meetingDateTime(second);
      return firstDate.compareTo(secondDate);
    });
  }

  Future<void> _openScheduler() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => HrScheduleMeetingScreen(
          userId: widget.userId,
          participants: _participants,
          service: _service,
        ),
      ),
    );
    if (result == null || !mounted) return;
    await _load(showLoader: false);
    if (!mounted) return;
    final notified = result['notified_to'] ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result['message'] ?? 'Meeting scheduled.'} $notified participant(s) notified.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDetails(Map<String, dynamic> meeting) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HrMeetingDetailsSheet(meeting: meeting),
    );
    if (action == null || !mounted) return;
    if (action == 'join') {
      await _openMeetingLink(meeting);
    } else if (action == 'cancel') {
      await _confirmCancel(meeting);
    }
  }

  Future<void> _openMeetingLink(Map<String, dynamic> meeting) async {
    final link = '${meeting['meeting_link'] ?? meeting['location'] ?? ''}'
        .trim();
    if (!link.startsWith('http')) {
      _showError('A valid meeting link is not available.');
      return;
    }
    try {
      final opened = await _platformChannel.invokeMethod<bool>('openUrl', {
        'url': link,
      });
      if (opened != true && mounted) {
        _showError('Unable to open the meeting link.');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showError(error.message ?? 'Unable to open the meeting link.');
      }
    }
  }

  Future<void> _confirmCancel(Map<String, dynamic> meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel meeting?'),
        content: Text(
          '“${meeting['title'] ?? 'Meeting'}” will be cancelled and every participant will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep meeting'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel meeting'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final id = _intValue(meeting['id']);
    if (id == null) return;
    try {
      final response = await _service.cancelMeeting(widget.userId, id);
      await _load(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${response['message'] ?? 'Meeting cancelled.'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (mounted) _showError(_errorText(error));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: HrPalette.of(context).danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return RefreshIndicator(
      onRefresh: () => _load(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppLayout.pagePadding,
        children: [
          _meetingHeader(c),
          const SizedBox(height: 14),
          _summary(c),
          const SizedBox(height: 14),
          _calendar(c),
          const SizedBox(height: 14),
          _filters(c),
          const SizedBox(height: 12),
          if (_loading)
            const _MeetingLoading()
          else if (_error != null)
            _errorState(c)
          else if (_visibleMeetings.isEmpty)
            _emptyState(c)
          else
            ..._visibleMeetings.map(
              (meeting) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _meetingCard(c, meeting),
              ),
            ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _meetingHeader(HrPalette c) {
    return HrCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.video_call_rounded,
                  color: c.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting center',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Schedule employees and Team Leads with automatic notifications',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _openScheduler,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Schedule meeting'),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(HrPalette c) {
    return Row(
      children: [
        Expanded(
          child: _MeetingSummary(
            label: 'Upcoming',
            value: '${_counts['upcoming'] ?? 0}',
            color: c.primary,
            icon: Icons.upcoming_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MeetingSummary(
            label: 'Past',
            value: '${_counts['past'] ?? 0}',
            color: c.success,
            icon: Icons.history_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MeetingSummary(
            label: 'Cancelled',
            value: '${_counts['cancelled'] ?? 0}',
            color: c.danger,
            icon: Icons.event_busy_rounded,
          ),
        ),
      ],
    );
  }

  Widget _calendar(HrPalette c) {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final days = DateUtils.getDaysInMonth(
      _displayMonth.year,
      _displayMonth.month,
    );
    final leadingBlanks = firstDay.weekday - 1;
    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return HrCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => setState(() {
                  _displayMonth = DateTime(
                    _displayMonth.year,
                    _displayMonth.month - 1,
                  );
                  _selectedDate = null;
                }),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '${_monthName(_displayMonth.month)} ${_displayMonth.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => setState(() {
                  _displayMonth = DateTime(
                    _displayMonth.year,
                    _displayMonth.month + 1,
                  );
                  _selectedDate = null;
                }),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: [
              ...weekDays.map(
                (day) => Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              ...List.generate(leadingBlanks, (_) => const SizedBox.shrink()),
              ...List.generate(days, (index) {
                final date = DateTime(
                  _displayMonth.year,
                  _displayMonth.month,
                  index + 1,
                );
                final selected =
                    _selectedDate != null && _isSameDay(date, _selectedDate!);
                final today = _isSameDay(date, DateTime.now());
                final meetingCount = _meetings
                    .where(
                      (meeting) =>
                          '${meeting['status']}' != 'cancelled' &&
                          _isSameDay(_meetingDate(meeting), date),
                    )
                    .length;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() {
                    _selectedDate = selected ? null : date;
                  }),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 31,
                        height: 31,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? c.primary
                              : today
                              ? c.primary.withAlpha(22)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: today && !selected
                              ? Border.all(color: c.primary.withAlpha(100))
                              : null,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: selected ? Colors.white : c.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                        child: meetingCount > 0
                            ? Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: c.success,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filters(HrPalette c) {
    const statuses = {
      'upcoming': 'Upcoming',
      'past': 'Past',
      'cancelled': 'Cancelled',
      'all': 'All',
    };
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: _status == entry.key,
                        label: Text(entry.value),
                        onSelected: (_) => setState(() => _status = entry.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (_selectedDate != null)
          IconButton(
            tooltip: 'Clear selected date',
            onPressed: () => setState(() => _selectedDate = null),
            icon: Icon(Icons.event_busy_rounded, color: c.primary),
          ),
      ],
    );
  }

  Widget _meetingCard(HrPalette c, Map<String, dynamic> meeting) {
    final status = '${meeting['status'] ?? 'upcoming'}'.toLowerCase();
    final statusColor = _meetingStatusColor(c, status);
    final participants = _mapList(meeting['participants']);
    final platform =
        '${meeting['platform'] ?? meeting['meeting_type'] ?? 'Meeting'}'.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetails(meeting),
        borderRadius: BorderRadius.circular(8),
        child: HrCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_meetingDate(meeting).day}'.padLeft(2, '0'),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _shortMonth(_meetingDate(meeting).month),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${meeting['title'] ?? 'Meeting'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${meeting['time_label'] ?? ''}  •  ${meeting['duration'] ?? ''}',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.videocam_outlined, color: c.muted, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            platform.isEmpty ? 'Meeting' : platform,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.muted, fontSize: 10),
                          ),
                        ),
                        Icon(Icons.groups_rounded, color: c.muted, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${participants.length}',
                          style: TextStyle(color: c.muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MeetingStatusBadge(
                status: _meetingStatusLabel(status),
                color: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(HrPalette c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 52, color: c.muted),
          const SizedBox(height: 12),
          Text(
            _selectedDate == null
                ? 'No ${_status == 'all' ? '' : '$_status '}meetings'
                : 'No meetings on this date',
            style: TextStyle(
              color: c.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Schedule a meeting and selected employees and Team Leads will be notified automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _openScheduler,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Schedule meeting'),
          ),
        ],
      ),
    );
  }

  Widget _errorState(HrPalette c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: c.danger),
          const SizedBox(height: 12),
          Text(
            'Couldn’t load meetings',
            style: TextStyle(
              color: c.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class HrScheduleMeetingScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> participants;
  final HrService service;

  const HrScheduleMeetingScreen({
    super.key,
    required this.userId,
    required this.participants,
    required this.service,
  });

  @override
  State<HrScheduleMeetingScreen> createState() =>
      _HrScheduleMeetingScreenState();
}

class _HrScheduleMeetingScreenState extends State<HrScheduleMeetingScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _agenda = TextEditingController();
  final TextEditingController _link = TextEditingController();
  final TextEditingController _participantSearch = TextEditingController();

  int _step = 0;
  late DateTime _date;
  late TimeOfDay _time;
  String _duration = '30 Minutes';
  String _platform = 'Google Meet';
  String _roleFilter = 'all';
  final Set<String> _selectedIds = {};
  bool _inviteEmail = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final future = DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(future.year, future.month, future.day);
    _time = TimeOfDay(hour: future.hour, minute: future.minute);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _agenda.dispose();
    _link.dispose();
    _participantSearch.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredParticipants {
    final search = _participantSearch.text.trim().toLowerCase();
    return widget.participants.where((participant) {
      final role = '${participant['role'] ?? 'employee'}'.toLowerCase();
      if (_roleFilter != 'all' && role != _roleFilter) return false;
      if (search.isEmpty) return true;
      final searchable =
          '${participant['name'] ?? ''} ${participant['id'] ?? ''} '
                  '${participant['department'] ?? ''} ${participant['email'] ?? ''}'
              .toLowerCase();
      return searchable.contains(search);
    }).toList();
  }

  Future<void> _pickDate() async {
    final selected = await showSeparatedDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) setState(() => _time = selected);
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_title.text.trim().isEmpty) {
        _message('Enter a meeting title.');
        return false;
      }
      if (_agenda.text.trim().isEmpty) {
        _message('Add at least one agenda item.');
        return false;
      }
    }
    if (_step == 1) {
      final scheduledAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      if (!scheduledAt.isAfter(DateTime.now())) {
        _message('Choose a meeting date and time in the future.');
        return false;
      }
      final link = _link.text.trim();
      if (_platform == 'In Person' && link.isEmpty) {
        _message('Enter the meeting room or office location.');
        return false;
      }
      if (_platform != 'In Person' &&
          link.isNotEmpty &&
          !link.startsWith('http://') &&
          !link.startsWith('https://')) {
        _message('Meeting link must start with http:// or https://.');
        return false;
      }
    }
    if (_step == 2 && _selectedIds.isEmpty) {
      _message('Select at least one employee or Team Lead.');
      return false;
    }
    return true;
  }

  void _continue() {
    if (!_validateStep()) return;
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _schedule();
    }
  }

  Future<void> _schedule() async {
    if (_saving || !_validateStep()) return;
    setState(() => _saving = true);
    try {
      final selected = widget.participants
          .where(
            (participant) =>
                _selectedIds.contains('${participant['id'] ?? ''}'),
          )
          .toList();
      final response = await widget.service.scheduleMeeting(widget.userId, {
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty
            ? _agenda.text.trim()
            : _description.text.trim(),
        'date_label':
            '${_date.day.toString().padLeft(2, '0')}-'
            '${_date.month.toString().padLeft(2, '0')}-${_date.year}',
        'time_label': _formatTime(_time),
        'duration': _duration,
        'platform': _platform,
        'meeting_type': _platform,
        'meeting_link': _link.text.trim(),
        'location': _link.text.trim(),
        'participants': selected,
        'agenda': _agenda.text
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        'invite_email': _inviteEmail,
        'invite_sms': false,
      });
      if (mounted) Navigator.of(context).pop(response);
    } catch (error) {
      if (mounted) _message(_errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Schedule Meeting'),
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _progress(c),
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [
                  _detailsStep(c),
                  _scheduleStep(c),
                  _participantsStep(c),
                ],
              ),
            ),
            _footer(c),
          ],
        ),
      ),
    );
  }

  Widget _progress(HrPalette c) {
    const labels = ['Details', 'Schedule', 'People'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= _step;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? c.primary : c.row,
                    shape: BoxShape.circle,
                    border: Border.all(color: active ? c.primary : c.border),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : c.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? c.text : c.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (index < labels.length - 1)
                  Container(
                    width: 12,
                    height: 1,
                    color: index < _step ? c.primary : c.border,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _detailsStep(HrPalette c) {
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        _StepIntro(
          icon: Icons.edit_calendar_rounded,
          title: 'Meeting details',
          subtitle: 'Keep the invitation concise and action-oriented.',
          color: c.primary,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Meeting title *',
            hintText: 'e.g. Monthly delivery review',
            prefixIcon: Icon(Icons.title_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Purpose (optional)',
            hintText: 'What outcome should this meeting produce?',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _agenda,
          textCapitalization: TextCapitalization.sentences,
          minLines: 4,
          maxLines: 7,
          maxLength: 800,
          decoration: const InputDecoration(
            labelText: 'Agenda *',
            hintText: 'One agenda item per line',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.format_list_bulleted_rounded),
          ),
        ),
      ],
    );
  }

  Widget _scheduleStep(HrPalette c) {
    const durations = [
      '15 Minutes',
      '30 Minutes',
      '45 Minutes',
      '60 Minutes',
      '90 Minutes',
    ];
    const platforms = ['Google Meet', 'Microsoft Teams', 'Zoom', 'In Person'];
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        _StepIntro(
          icon: Icons.schedule_rounded,
          title: 'Date, time and location',
          subtitle: 'A future time is validated again by the backend.',
          color: c.purple,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PickerField(
                label: 'Date',
                value:
                    '${_date.day.toString().padLeft(2, '0')}/'
                    '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                icon: Icons.calendar_month_rounded,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerField(
                label: 'Time',
                value: _formatTime(_time),
                icon: Icons.schedule_rounded,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _duration,
          decoration: const InputDecoration(
            labelText: 'Duration',
            prefixIcon: Icon(Icons.timelapse_rounded),
          ),
          items: durations
              .map(
                (duration) =>
                    DropdownMenuItem(value: duration, child: Text(duration)),
              )
              .toList(),
          onChanged: (value) => setState(() => _duration = value ?? _duration),
        ),
        const SizedBox(height: 18),
        Text(
          'Meeting format',
          style: TextStyle(color: c.text, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: platforms
              .map(
                (platform) => ChoiceChip(
                  selected: _platform == platform,
                  label: Text(platform),
                  avatar: Icon(
                    platform == 'In Person'
                        ? Icons.meeting_room_rounded
                        : Icons.videocam_rounded,
                    size: 16,
                  ),
                  onSelected: (_) => setState(() => _platform = platform),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _link,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: _platform == 'In Person'
                ? 'Room / location (optional)'
                : 'Meeting link (optional)',
            hintText: _platform == 'In Person'
                ? 'Conference Room A'
                : 'https://meet.google.com/...',
            prefixIcon: Icon(
              _platform == 'In Person'
                  ? Icons.location_on_outlined
                  : Icons.link_rounded,
            ),
            helperText: _platform == 'In Person'
                ? null
                : 'If empty, the platform’s meeting page will be used.',
          ),
        ),
      ],
    );
  }

  Widget _participantsStep(HrPalette c) {
    final visible = _filteredParticipants;
    final employeeCount = widget.participants
        .where(
          (item) =>
              '${item['role'] ?? ''}'.toLowerCase() == 'employee' &&
              _selectedIds.contains('${item['id'] ?? ''}'),
        )
        .length;
    final tlCount = widget.participants
        .where(
          (item) =>
              '${item['role'] ?? ''}'.toLowerCase() == 'tl' &&
              _selectedIds.contains('${item['id'] ?? ''}'),
        )
        .length;
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        _StepIntro(
          icon: Icons.groups_rounded,
          title: 'Select participants',
          subtitle:
              'Selected employees and Team Leads receive “Meeting Scheduled” in-app and push notifications.',
          color: c.success,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _participantSearch,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search name, ID, department or email',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final entry in const {
              'all': 'All',
              'employee': 'Employees',
              'tl': 'Team Leads',
            }.entries)
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  selected: _roleFilter == entry.key,
                  label: Text(entry.value),
                  onSelected: (_) => setState(() => _roleFilter = entry.key),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        HrCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedIds.length} selected • $employeeCount employees • $tlCount TLs',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: visible.isEmpty
                    ? null
                    : () => setState(() {
                        final visibleIds = visible
                            .map((item) => '${item['id'] ?? ''}')
                            .where((id) => id.isNotEmpty)
                            .toSet();
                        final allSelected = visibleIds.every(
                          _selectedIds.contains,
                        );
                        if (allSelected) {
                          _selectedIds.removeAll(visibleIds);
                        } else {
                          _selectedIds.addAll(visibleIds);
                        }
                      }),
                child: const Text('Select visible'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No matching participants',
                style: TextStyle(color: c.muted),
              ),
            ),
          )
        else
          ...visible.map((participant) {
            final id = '${participant['id'] ?? ''}';
            final selected = _selectedIds.contains(id);
            final isTl = '${participant['role'] ?? ''}'.toLowerCase() == 'tl';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: selected,
                onChanged: (_) => setState(() {
                  if (selected) {
                    _selectedIds.remove(id);
                  } else {
                    _selectedIds.add(id);
                  }
                }),
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: CircleAvatar(
                  backgroundColor: (isTl ? c.purple : c.primary).withAlpha(24),
                  child: Icon(
                    isTl
                        ? Icons.supervisor_account_rounded
                        : Icons.person_rounded,
                    color: isTl ? c.purple : c.primary,
                  ),
                ),
                title: Text(
                  '${participant['name'] ?? id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  [
                    id,
                    '${participant['role_label'] ?? ''}',
                    '${participant['department'] ?? ''}',
                  ].where((value) => value.trim().isNotEmpty).join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: selected ? c.primary : c.border),
                ),
                tileColor: selected ? c.primary.withAlpha(12) : c.surface,
              ),
            );
          }),
        const SizedBox(height: 10),
        SwitchListTile(
          value: _inviteEmail,
          onChanged: (value) => setState(() => _inviteEmail = value),
          title: const Text(
            'Email calendar invitation',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text(
            'Send meeting details and an ICS calendar attachment when email is configured.',
          ),
          secondary: Icon(Icons.mark_email_read_rounded, color: c.primary),
        ),
      ],
    );
  }

  Widget _footer(HrPalette c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _step -= 1),
                child: const Text('Back'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _saving ? null : _continue,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _step == 2
                          ? Icons.event_available_rounded
                          : Icons.arrow_forward_rounded,
                    ),
              label: Text(
                _saving
                    ? 'Scheduling…'
                    : _step == 2
                    ? 'Schedule & notify'
                    : 'Continue',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HrMeetingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> meeting;

  const _HrMeetingDetailsSheet({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final participants = _mapList(meeting['participants']);
    final agenda = meeting['agenda'] is List
        ? (meeting['agenda'] as List)
              .where((item) => item is! Map || item['_meta'] != 'meeting')
              .map((item) => '$item')
              .where((item) => item.trim().isNotEmpty)
              .toList()
        : const <String>[];
    final status = '${meeting['status'] ?? 'upcoming'}'.toLowerCase();
    final color = _meetingStatusColor(c, status);
    final link = '${meeting['meeting_link'] ?? meeting['location'] ?? ''}'
        .trim();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${meeting['title'] ?? 'Meeting'}',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MeetingStatusBadge(
                status: _meetingStatusLabel(status),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.calendar_month_rounded,
            label: 'Date',
            value: '${meeting['date_label'] ?? '-'}',
          ),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: 'Time',
            value:
                '${meeting['time_label'] ?? '-'} • ${meeting['duration'] ?? '-'}',
          ),
          _DetailRow(
            icon: Icons.videocam_outlined,
            label: 'Format',
            value: '${meeting['platform'] ?? meeting['meeting_type'] ?? '-'}',
          ),
          if ('${meeting['description'] ?? ''}'.trim().isNotEmpty)
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Purpose',
              value: '${meeting['description']}',
            ),
          const SizedBox(height: 14),
          Text(
            'Participants (${participants.length})',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: participants
                .map(
                  (participant) => Chip(
                    avatar: Icon(
                      '${participant['role']}' == 'tl'
                          ? Icons.supervisor_account_rounded
                          : Icons.person_rounded,
                      size: 16,
                    ),
                    label: Text(
                      '${participant['name'] ?? participant['id'] ?? ''}',
                    ),
                  ),
                )
                .toList(),
          ),
          if (agenda.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Agenda',
              style: TextStyle(color: c.text, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...agenda.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: c.primary.withAlpha(24),
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(color: c.primary, fontSize: 9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (link.startsWith('http') && status != 'cancelled')
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, 'join'),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open meeting link'),
            ),
          if (status == 'upcoming') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: c.danger),
              onPressed: () => Navigator.pop(context, 'cancel'),
              icon: const Icon(Icons.event_busy_rounded),
              label: const Text('Cancel meeting'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MeetingSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MeetingSummary({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return HrCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingStatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _MeetingStatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StepIntro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _StepIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return HrCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(24),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: c.muted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.primary, size: 19),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(label, style: TextStyle(color: c.muted, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: c.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingLoading extends StatelessWidget {
  const _MeetingLoading();

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HrCard(
            child: Row(
              children: [
                Container(width: 46, height: 52, color: c.border),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 10, width: 170, color: c.border),
                      const SizedBox(height: 8),
                      Container(height: 8, width: 220, color: c.border),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

DateTime _meetingDate(Map<String, dynamic> meeting) {
  final raw = '${meeting['date_label'] ?? meeting['date'] ?? ''}'.trim();
  for (final separator in ['-', '/']) {
    final parts = raw.split(separator);
    if (parts.length != 3) continue;
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) continue;
    if (parts[0].length == 4) return DateTime(first, second, third);
    return DateTime(third, second, first);
  }
  return DateTime.now();
}

DateTime _meetingDateTime(Map<String, dynamic> meeting) {
  final date = _meetingDate(meeting);
  final time = '${meeting['time_label'] ?? meeting['time'] ?? ''}'.trim();
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(time);
  if (match == null) return date;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)!.toUpperCase();
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

bool _isSameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

Color _meetingStatusColor(HrPalette c, String status) {
  switch (status) {
    case 'past':
      return c.success;
    case 'cancelled':
      return c.danger;
    default:
      return c.primary;
  }
}

String _meetingStatusLabel(String status) {
  switch (status) {
    case 'past':
      return 'Past';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Upcoming';
  }
}

String _formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
}

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

String _shortMonth(int month) => const [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
][month - 1];

int? _intValue(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value');
}

String _errorText(Object error) =>
    '$error'.replaceFirst('Exception: ', '').trim();
