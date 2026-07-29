import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_module_tabs.dart';

import 'employee_service.dart';
import 'employee_shared.dart';

class EmployeeApprovalsScreen extends StatefulWidget {
  final String userId;
  final EmployeeService service;

  const EmployeeApprovalsScreen({
    super.key,
    required this.userId,
    required this.service,
  });

  @override
  State<EmployeeApprovalsScreen> createState() =>
      _EmployeeApprovalsScreenState();
}

class _EmployeeApprovalsScreenState extends State<EmployeeApprovalsScreen> {
  bool _sent = false;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _received = [];
  List<Map<String, dynamic>> _sentItems = [];
  DateTime? _historyDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.service.fetchApprovals(widget.userId);
      if (!mounted) return;
      setState(() {
        _received = _list(data['received']);
        _sentItems = _list(data['sent']);
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : [];

  Future<void> _newRequest() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ApprovalTemplatesScreen(
          userId: widget.userId,
          service: widget.service,
        ),
      ),
    );
    if (changed == true) {
      _sent = true;
      await _load();
    }
  }

  DateTime? _itemHistoryDate(Map<String, dynamic> item) {
    for (final key in const [
      'reviewed_at',
      'updated_at',
      'date',
      'created_at',
    ]) {
      final value = '${item[key] ?? ''}'.trim();
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _selectHistoryDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _historyDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) setState(() => _historyDate = selected);
  }

  @override
  Widget build(BuildContext context) {
    final sourceItems = _sent ? _sentItems : _received;
    final items = !_sent || _historyDate == null
        ? sourceItems
        : sourceItems.where((item) {
            final date = _itemHistoryDate(item);
            return date != null && _sameDate(date, _historyDate!);
          }).toList();
    return EmployeePage(
      title: 'Approvals',
      children: [
        Row(
          children: [
            Expanded(
              child: AppModuleTabs<bool>(
                tabs: const [
                  AppModuleTab(false, 'Received'),
                  AppModuleTab(true, 'Sent'),
                ],
                selected: _sent,
                onSelected: (value) => setState(() => _sent = value),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _newRequest,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New'),
            ),
          ],
        ),
        if (_sent) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectHistoryDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    _historyDate == null
                        ? 'History date: All'
                        : 'History: ${_dateLabel(_historyDate!)}',
                  ),
                ),
              ),
              if (_historyDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Show all dates',
                  onPressed: () => setState(() => _historyDate = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null)
          EmployeeListTile(
            icon: Icons.error_outline,
            title: 'Unable to load approvals',
            subtitle: _error!,
            trailing: 'Retry',
            color: EmployeeColors.red,
            onTap: _load,
          ),
        if (!_loading && _error == null && items.isEmpty)
          EmployeeListTile(
            icon: Icons.approval_outlined,
            title: _sent && _historyDate != null
                ? 'No approval history on this date'
                : 'No ${_sent ? 'sent' : 'received'} approvals',
            subtitle: _sent
                ? (_historyDate == null
                      ? 'Tap New to create an approval request'
                      : 'Select another date or clear the filter')
                : 'Requests assigned to you will appear here',
            trailing: '',
            color: EmployeeColors.purple,
          ),
        ...items.map((item) {
          final status = _approvalWorkflowStatus(item);
          final color = status == 'Approved'
              ? EmployeeColors.green
              : status == 'Rejected' || status == 'Cancelled'
              ? EmployeeColors.red
              : EmployeeColors.purple;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EmployeeListTile(
              icon: Icons.approval_rounded,
              title: '${item['title'] ?? 'Approval request'}',
              subtitle: '${item['date'] ?? ''} • ${item['session'] ?? ''}',
              trailing: status,
              color: color,
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EmployeeApprovalDetailScreen(
                      item: item,
                      userId: widget.userId,
                      service: widget.service,
                      received: !_sent,
                    ),
                  ),
                );
                if (changed == true) _load();
              },
            ),
          );
        }),
      ],
    );
  }
}

class EmployeeApprovalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String userId;
  final EmployeeService service;
  final bool received;

  const EmployeeApprovalDetailScreen({
    super.key,
    required this.item,
    required this.userId,
    required this.service,
    required this.received,
  });

  @override
  State<EmployeeApprovalDetailScreen> createState() =>
      _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<EmployeeApprovalDetailScreen> {
  bool _busy = false;
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _decisions {
    final value = widget.item['decisions'];
    return value is List
        ? value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : [];
  }

  Future<void> _action(String action) async {
    if (_reply.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a reply to the employee before continuing.'),
        ),
      );
      return;
    }
    if (action == 'reject') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject this request?'),
          content: const Text('Your reply will be sent to the employee.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.updateApproval(
        widget.userId,
        widget.item['id']!,
        action,
        comment: _reply.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update request: $error')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = '${widget.item['status'] ?? 'Requested'}';
    final status = _approvalWorkflowStatus(widget.item);
    final currentStage =
        int.tryParse('${widget.item['current_stage'] ?? 0}') ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Details')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            '${widget.item['title'] ?? 'Approval request'}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            '$status • ${widget.item['date'] ?? ''} • ${widget.item['session'] ?? ''}',
          ),
          const SizedBox(height: 20),
          if (widget.item['request_type'] == 'social_media_post') ...[
            _detail(
              'Platforms',
              widget.item['platforms'] is List
                  ? (widget.item['platforms'] as List).join(', ')
                  : '-',
            ),
            _detail('Date to be posted', widget.item['date']),
            _detail('To be posted by', widget.item['posted_by']),
            _detail('Scheduled post', widget.item['scheduled_post']),
            _detail('Attachment', widget.item['attachment_name']),
          ] else if (widget.item['request_type'] == 'leave_request') ...[
            _detail('Leave type', widget.item['leave_type']),
            _detail('Details about the leave', widget.item['task_details']),
            _detail('Leave start date', widget.item['date']),
            _detail('Leave end date', widget.item['leave_end_date']),
            _detail('Attachment', widget.item['attachment_name']),
          ] else ...[
            _detail('Task details', widget.item['task_details']),
            _detail('Expected result', widget.item['expected_result']),
            _detail('Actual result', widget.item['actual_result']),
          ],
          const SizedBox(height: 8),
          const Text(
            'Approval flow',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _stage(
            '1',
            'Team Lead',
            _stageStatus('tl', rawStatus, currentStage, 0),
          ),
          _stage(
            '2',
            'CEO (Final Approval)',
            _stageStatus('ceo', rawStatus, currentStage, 1),
          ),
          ..._decisions.map(
            (decision) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                decision['action'] == 'approve'
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: decision['action'] == 'approve'
                    ? EmployeeColors.green
                    : EmployeeColors.red,
              ),
              title: Text('${decision['role'] ?? ''}'.toUpperCase()),
              subtitle: Text(
                '${decision['action'] ?? ''}${'${decision['comment'] ?? ''}'.isEmpty ? '' : ' • ${decision['comment']}'}',
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (widget.received && rawStatus.toLowerCase() == 'requested') ...[
            TextField(
              controller: _reply,
              minLines: 3,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Reply to employee *',
                hintText: 'Enter feedback about the submitted task',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy || _reply.text.trim().isEmpty
                        ? null
                        : () => _action('reject'),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy || _reply.text.trim().isEmpty
                        ? null
                        : () => _action('approve'),
                    child: Text(_busy ? 'Updating...' : 'Approve'),
                  ),
                ),
              ],
            ),
          ],
          if (!widget.received && rawStatus.toLowerCase() == 'requested')
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _action('cancel'),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel Request'),
            ),
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${value ?? '-'}'),
      ],
    ),
  );

  Widget _stage(String number, String label, String status) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Text(number)),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    trailing: Text(status),
  );

  String _stageStatus(String role, String overall, int current, int stage) {
    final decision = _decisions
        .where((item) => item['role'] == role)
        .firstOrNull;
    if (decision != null) return '${decision['action']}'.toUpperCase();
    if (overall.toLowerCase() == 'cancelled') return 'CANCELLED';
    if (current == stage && overall.toLowerCase() == 'requested')
      return 'PENDING';
    return current > stage || overall.toLowerCase() == 'approved'
        ? 'APPROVED'
        : 'WAITING';
  }
}

String _approvalWorkflowStatus(Map<String, dynamic> item) {
  final status = '${item['status'] ?? 'requested'}'.toLowerCase();
  if (status == 'approved') return 'Approved';
  if (status == 'rejected') return 'Rejected';
  if (status == 'cancelled') return 'Cancelled';

  final stage = int.tryParse('${item['current_stage'] ?? 0}') ?? 0;
  final rawApprovers = item['approvers'];
  final approvers = rawApprovers is List
      ? rawApprovers.map((value) => '$value'.trim()).toList()
      : const <String>[];
  if (stage >= 0 && stage < approvers.length && approvers[stage].isNotEmpty) {
    return 'Pending ${approvers[stage]} Approval';
  }
  return stage > 0 ? 'Pending Final Approval' : 'Pending TL Approval';
}

class _ApprovalTemplatesScreen extends StatelessWidget {
  final String userId;
  final EmployeeService service;
  const _ApprovalTemplatesScreen({required this.userId, required this.service});

  @override
  Widget build(BuildContext context) {
    final templates = [
      (
        'Daily Reports',
        'Daily work report for employees',
        Icons.today_rounded,
        true,
      ),
      (
        'Social Media Posts',
        'Social media post approval',
        Icons.campaign_rounded,
        true,
      ),
      (
        'Leave Request',
        'Employee leave approval',
        Icons.beach_access_rounded,
        true,
      ),
      (
        'Notice Period Serving',
        'Notice period workflow',
        Icons.event_busy_rounded,
        false,
      ),
      (
        'Project Documentation',
        'Project document approval',
        Icons.folder_copy_rounded,
        false,
      ),
      (
        'Purchase Order',
        'Purchase order approval',
        Icons.shopping_cart_rounded,
        false,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('New Approval Request')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Templates',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text('Choose an organization template'),
          const SizedBox(height: 18),
          ...templates.map(
            (template) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: EmployeeColors.purple.withAlpha(30),
                  child: Icon(template.$3, color: EmployeeColors.purple),
                ),
                title: Text(
                  'BBT Approvals - ${template.$1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(template.$2),
                trailing: template.$4
                    ? const Icon(Icons.chevron_right_rounded)
                    : const Text('Soon'),
                onTap: template.$4
                    ? () async {
                        final social = template.$1 == 'Social Media Posts';
                        final leave = template.$1 == 'Leave Request';
                        final sent = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => social
                                ? _SocialMediaApprovalForm(
                                    userId: userId,
                                    service: service,
                                  )
                                : leave
                                ? _LeaveApprovalForm(
                                    userId: userId,
                                    service: service,
                                  )
                                : _DailyApprovalForm(
                                    userId: userId,
                                    service: service,
                                  ),
                          ),
                        );
                        if (sent == true && context.mounted)
                          Navigator.of(context).pop(true);
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyApprovalForm extends StatefulWidget {
  final String userId;
  final EmployeeService service;
  const _DailyApprovalForm({required this.userId, required this.service});
  @override
  State<_DailyApprovalForm> createState() => _DailyApprovalFormState();
}

class _DailyApprovalFormState extends State<_DailyApprovalForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _tasks = TextEditingController();
  final _expected = TextEditingController();
  final _actual = TextEditingController();
  DateTime? _date;
  String? _session;
  bool _saving = false;

  bool get _canSend =>
      !_saving &&
      _title.text.trim().isNotEmpty &&
      _date != null &&
      _session != null &&
      _tasks.text.trim().isNotEmpty &&
      _expected.text.trim().isNotEmpty &&
      _actual.text.trim().isNotEmpty;

  @override
  void dispose() {
    _title.dispose();
    _tasks.dispose();
    _expected.dispose();
    _actual.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String _apiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate() ||
        _date == null ||
        _session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all required fields.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.submitDailyApproval(widget.userId, {
        'title': _title.text.trim(),
        'date': _apiDate(_date!),
        'session': _session,
        'task_details': _tasks.text.trim(),
        'expected_result': _expected.text.trim(),
        'actual_result': _actual.text.trim(),
        'approvers': const ['Team Lead', 'CEO'],
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to send: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration(String label, String hint) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(110),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daily Reports')),
    bottomNavigationBar: SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Back'),
            ),
            const Spacer(),
            SizedBox(
              width: 120,
              child: FilledButton(
                onPressed: _canSend ? _send : null,
                child: Text(_saving ? 'Sending...' : 'Send'),
              ),
            ),
          ],
        ),
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'BBT Approvals - Daily Reports',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const Text('Bit Byte Daily Approvals for Employees'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _title,
            validator: _required,
            onChanged: (_) => setState(() {}),
            decoration: _fieldDecoration(
              'Name of request *',
              'Use a name that is easy to understand',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Approvers *',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(label: Text('1  Team Lead')),
              Chip(label: Text('2  CEO • Final')),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date *'),
            subtitle: Text(
              _date == null ? 'Select a date' : _displayDate(_date!),
            ),
            trailing: const Icon(Icons.calendar_month_rounded),
            onTap: () async {
              final value = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (value != null) setState(() => _date = value);
            },
          ),
          const Text(
            'Session *',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          RadioListTile(
            value: 'Forenoon',
            groupValue: _session,
            title: const Text('Forenoon'),
            onChanged: (value) => setState(() => _session = value),
          ),
          RadioListTile(
            value: 'Afternoon',
            groupValue: _session,
            title: const Text('Afternoon'),
            onChanged: (value) => setState(() => _session = value),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tasks,
            validator: _required,
            onChanged: (_) => setState(() {}),
            minLines: 3,
            maxLines: 5,
            decoration: _fieldDecoration(
              'Tasks Details - Brief Description *',
              'Enter your response',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _expected,
            validator: _required,
            onChanged: (_) => setState(() {}),
            minLines: 2,
            maxLines: 3,
            decoration: _fieldDecoration(
              'Expected Result *',
              'Enter your response',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _actual,
            validator: _required,
            onChanged: (_) => setState(() {}),
            minLines: 2,
            maxLines: 3,
            decoration: _fieldDecoration(
              'Actual Result (With Justification) *',
              'Enter your response',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _SocialMediaApprovalForm extends StatefulWidget {
  final String userId;
  final EmployeeService service;
  const _SocialMediaApprovalForm({required this.userId, required this.service});
  @override
  State<_SocialMediaApprovalForm> createState() =>
      _SocialMediaApprovalFormState();
}

class _SocialMediaApprovalFormState extends State<_SocialMediaApprovalForm> {
  static const _options = [
    'Facebook',
    'WhatsApp',
    'Instagram',
    'LinkedIn',
    'Snapchat',
    'X (formerly Twitter)',
    'YouTube Shorts',
    'Other',
  ];
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _postedBy = TextEditingController();
  final _other = TextEditingController();
  final Set<String> _platforms = {};
  DateTime? _date;
  String? _scheduled;
  XFile? _attachment;
  bool _saving = false;

  bool get _canSend =>
      !_saving &&
      _title.text.trim().isNotEmpty &&
      _postedBy.text.trim().isNotEmpty &&
      _date != null &&
      _scheduled != null &&
      _platforms.isNotEmpty &&
      _attachment != null &&
      (!_platforms.contains('Other') || _other.text.trim().isNotEmpty);

  @override
  void dispose() {
    _title.dispose();
    _postedBy.dispose();
    _other.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
  String _apiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';

  Future<void> _pickAttachment() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null && mounted) setState(() => _attachment = file);
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate() || !_canSend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete all required fields and add an attachment.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.submitSocialMediaApproval(widget.userId, {
        'request_type': 'social_media_post',
        'title': _title.text.trim(),
        'date': _apiDate(_date!),
        'platforms': _platforms
            .map((value) => value == 'Other' ? _other.text.trim() : value)
            .toList(),
        'posted_by': _postedBy.text.trim(),
        'scheduled_post': _scheduled!,
      }, _attachment!.path);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to send: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withAlpha(110),
    border: const OutlineInputBorder(borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Social Media Posts')),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Back'),
            ),
            const Spacer(),
            SizedBox(
              width: 120,
              child: FilledButton(
                onPressed: _canSend ? _send : null,
                child: Text(_saving ? 'Sending...' : 'Send'),
              ),
            ),
          ],
        ),
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'BBT Approvals - Social Media Posts Approval Flow',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const Text('Social Media Posts - Approval Flow for all Platforms'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _title,
            validator: _required,
            onChanged: (_) => setState(() {}),
            decoration: _decoration(
              'Name of request *',
              'Use a name that is easy to understand',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Approvers *',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(label: Text('1  Digital Marketing Team Lead')),
              Chip(label: Text('2  CEO • Final')),
              Chip(label: Text('MD • Notified')),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Platforms *',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          ..._options.map(
            (platform) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _platforms.contains(platform),
              title: Text(platform),
              onChanged: (checked) => setState(() {
                checked == true
                    ? _platforms.add(platform)
                    : _platforms.remove(platform);
              }),
            ),
          ),
          if (_platforms.contains('Other'))
            TextFormField(
              controller: _other,
              validator: _required,
              onChanged: (_) => setState(() {}),
              decoration: _decoration(
                'Other platform *',
                'Enter platform name',
              ),
            ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date to be Posted *'),
            subtitle: Text(
              _date == null ? 'Select a date' : _displayDate(_date!),
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final now = DateTime.now();
              final value = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (value != null) setState(() => _date = value);
            },
          ),
          TextFormField(
            controller: _postedBy,
            validator: _required,
            onChanged: (_) => setState(() {}),
            decoration: _decoration(
              'To be posted by (Employee Name) *',
              'Enter employee name',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Is it Scheduled post? *',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          ...['Yes', 'No', 'Maybe'].map(
            (value) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: value,
              groupValue: _scheduled,
              title: Text(value),
              onChanged: (selected) => setState(() => _scheduled = selected),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file),
            title: const Text('Attachment *'),
            subtitle: Text(_attachment?.name ?? 'Add image attachment'),
            trailing: TextButton(
              onPressed: _saving ? null : _pickAttachment,
              child: Text(_attachment == null ? 'Add attachment' : 'Change'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _LeaveApprovalForm extends StatefulWidget {
  final String userId;
  final EmployeeService service;
  const _LeaveApprovalForm({required this.userId, required this.service});
  @override
  State<_LeaveApprovalForm> createState() => _LeaveApprovalFormState();
}

class _LeaveApprovalFormState extends State<_LeaveApprovalForm> {
  static const _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Earned Leave',
    'Early Off',
    'Emergency Leave',
    'Others',
  ];
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _details = TextEditingController();
  String? _leaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  XFile? _attachment;
  bool _saving = false;

  bool get _canSend =>
      !_saving &&
      _title.text.trim().isNotEmpty &&
      _details.text.trim().isNotEmpty &&
      _leaveType != null &&
      _startDate != null &&
      _endDate != null &&
      _attachment != null;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
  String _apiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';

  Future<void> _pickAttachment() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null && mounted) setState(() => _attachment = file);
  }

  Future<DateTime?> _pickDate(DateTime? initial, {DateTime? firstDate}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? firstDate ?? now,
      firstDate: firstDate ?? DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate() || !_canSend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete all required fields and add an attachment.'),
        ),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave end date cannot be before start date.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.submitApprovalWithAttachment(widget.userId, {
        'request_type': 'leave_request',
        'title': _title.text.trim(),
        'leave_type': _leaveType!,
        'task_details': _details.text.trim(),
        'date': _apiDate(_startDate!),
        'leave_end_date': _apiDate(_endDate!),
      }, _attachment!.path);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to send: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withAlpha(110),
    border: const OutlineInputBorder(borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Leave Request')),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Back'),
            ),
            const Spacer(),
            SizedBox(
              width: 120,
              child: FilledButton(
                onPressed: _canSend ? _send : null,
                child: Text(_saving ? 'Sending...' : 'Send'),
              ),
            ),
          ],
        ),
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'BBT Approvals - Leave Request',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const Text('All Leave Approvals for the organization'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _title,
            validator: _required,
            onChanged: (_) => setState(() {}),
            decoration: _decoration(
              'Name of request *',
              'Use a name that is easy to understand',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Approvers *',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(label: Text('1  Department Team Lead')),
              Chip(label: Text('2  CEO • Final')),
              Chip(label: Text('MD • Notified')),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Leave Type *',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          ..._leaveTypes.map(
            (value) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: value,
              groupValue: _leaveType,
              title: Text(value),
              onChanged: (selected) => setState(() => _leaveType = selected),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _details,
            validator: _required,
            onChanged: (_) => setState(() {}),
            minLines: 2,
            maxLines: 4,
            decoration: _decoration(
              'Details about the Leave *',
              'Enter your response',
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Leave Start Date *'),
            subtitle: Text(
              _startDate == null ? 'Select a date' : _displayDate(_startDate!),
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final value = await _pickDate(_startDate);
              if (value != null)
                setState(() {
                  _startDate = value;
                  if (_endDate != null && _endDate!.isBefore(value))
                    _endDate = value;
                });
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Leave End Date *'),
            subtitle: Text(
              _endDate == null ? 'Select a date' : _displayDate(_endDate!),
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: _startDate == null
                ? null
                : () async {
                    final value = await _pickDate(
                      _endDate,
                      firstDate: _startDate,
                    );
                    if (value != null) setState(() => _endDate = value);
                  },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file),
            title: const Text('Attachment *'),
            subtitle: Text(_attachment?.name ?? 'Add supporting image'),
            trailing: TextButton(
              onPressed: _saving ? null : _pickAttachment,
              child: Text(_attachment == null ? 'Add attachment' : 'Change'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
