import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'employee_service.dart';
import 'employee_shared.dart';

class EmployeeApprovalsScreen extends StatefulWidget {
  final String userId;
  final EmployeeService service;

  const EmployeeApprovalsScreen({super.key, required this.userId, required this.service});

  @override
  State<EmployeeApprovalsScreen> createState() => _EmployeeApprovalsScreenState();
}

class _EmployeeApprovalsScreenState extends State<EmployeeApprovalsScreen> {
  bool _sent = false;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _received = [];
  List<Map<String, dynamic>> _sentItems = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
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
      ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
      : [];

  Future<void> _newRequest() async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => _ApprovalTemplatesScreen(userId: widget.userId, service: widget.service),
    ));
    if (changed == true) { _sent = true; await _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final items = _sent ? _sentItems : _received;
    return EmployeePage(
      title: 'Approvals',
      children: [
        Row(children: [
          Expanded(child: SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, label: Text('Received')), ButtonSegment(value: true, label: Text('Sent'))],
            selected: {_sent},
            onSelectionChanged: (value) => setState(() => _sent = value.first),
          )),
          const SizedBox(width: 10),
          FilledButton.icon(onPressed: _newRequest, icon: const Icon(Icons.add_rounded), label: const Text('New')),
        ]),
        const SizedBox(height: 16),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null) EmployeeListTile(icon: Icons.error_outline, title: 'Unable to load approvals', subtitle: _error!, trailing: 'Retry', color: EmployeeColors.red, onTap: _load),
        if (!_loading && _error == null && items.isEmpty)
          EmployeeListTile(icon: Icons.approval_outlined, title: 'No ${_sent ? 'sent' : 'received'} approvals', subtitle: _sent ? 'Tap New to create an approval request' : 'Requests assigned to you will appear here', trailing: '', color: EmployeeColors.purple),
        ...items.map((item) {
          final status = '${item['status'] ?? 'Requested'}';
          final color = status.toLowerCase() == 'approved' ? EmployeeColors.green : status.toLowerCase() == 'cancelled' ? EmployeeColors.red : EmployeeColors.purple;
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

  const EmployeeApprovalDetailScreen({super.key, required this.item, required this.userId, required this.service, required this.received});

  @override
  State<EmployeeApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<EmployeeApprovalDetailScreen> {
  bool _busy = false;

  List<Map<String, dynamic>> get _decisions {
    final value = widget.item['decisions'];
    return value is List ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : [];
  }

  Future<void> _action(String action) async {
    final comment = TextEditingController();
    if (action == 'reject') {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(controller: comment, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject'))],
      ));
      if (confirmed != true) { comment.dispose(); return; }
    }
    setState(() => _busy = true);
    try {
      await widget.service.updateApproval(widget.userId, widget.item['id']!, action, comment: comment.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to update request: $error')));
    } finally {
      comment.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = '${widget.item['status'] ?? 'Requested'}';
    final currentStage = int.tryParse('${widget.item['current_stage'] ?? 0}') ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Details')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text('${widget.item['title'] ?? 'Approval request'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text('$status • ${widget.item['date'] ?? ''} • ${widget.item['session'] ?? ''}'),
        const SizedBox(height: 20),
        _detail('Task details', widget.item['task_details']),
        _detail('Expected result', widget.item['expected_result']),
        _detail('Actual result', widget.item['actual_result']),
        const SizedBox(height: 8),
        const Text('Approval flow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _stage('1', 'Team Lead', _stageStatus('tl', status, currentStage, 0)),
        _stage('2', 'CEO (Final Approval)', _stageStatus('ceo', status, currentStage, 1)),
        ..._decisions.map((decision) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(decision['action'] == 'approve' ? Icons.check_circle_rounded : Icons.cancel_rounded, color: decision['action'] == 'approve' ? EmployeeColors.green : EmployeeColors.red),
          title: Text('${decision['role'] ?? ''}'.toUpperCase()),
          subtitle: Text('${decision['action'] ?? ''}${'${decision['comment'] ?? ''}'.isEmpty ? '' : ' • ${decision['comment']}'}'),
        )),
        const SizedBox(height: 18),
        if (widget.received && status.toLowerCase() == 'requested') Row(children: [
          Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _action('reject'), child: const Text('Reject'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(onPressed: _busy ? null : () => _action('approve'), child: Text(_busy ? 'Updating...' : 'Approve'))),
        ]),
        if (!widget.received && status.toLowerCase() == 'requested') OutlinedButton.icon(onPressed: _busy ? null : () => _action('cancel'), icon: const Icon(Icons.close_rounded), label: const Text('Cancel Request')),
      ]),
    );
  }

  Widget _detail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${value ?? '-'}')]),
  );

  Widget _stage(String number, String label, String status) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Text(number)),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    trailing: Text(status),
  );

  String _stageStatus(String role, String overall, int current, int stage) {
    final decision = _decisions.where((item) => item['role'] == role).firstOrNull;
    if (decision != null) return '${decision['action']}'.toUpperCase();
    if (overall.toLowerCase() == 'cancelled') return 'CANCELLED';
    if (current == stage && overall.toLowerCase() == 'requested') return 'PENDING';
    return current > stage || overall.toLowerCase() == 'approved' ? 'APPROVED' : 'WAITING';
  }
}

class _ApprovalTemplatesScreen extends StatelessWidget {
  final String userId;
  final EmployeeService service;
  const _ApprovalTemplatesScreen({required this.userId, required this.service});

  @override
  Widget build(BuildContext context) {
    final templates = [
      ('Daily Reports', 'Daily work report for employees', Icons.today_rounded, true),
      ('Social Media Posts', 'Social media post approval', Icons.campaign_rounded, false),
      ('Leave Request', 'Employee leave approval', Icons.beach_access_rounded, false),
      ('Notice Period Serving', 'Notice period workflow', Icons.event_busy_rounded, false),
      ('Project Documentation', 'Project document approval', Icons.folder_copy_rounded, false),
      ('Purchase Order', 'Purchase order approval', Icons.shopping_cart_rounded, false),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('New Approval Request')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Templates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Choose an organization template'),
          const SizedBox(height: 18),
          ...templates.map((template) => Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: EmployeeColors.purple.withAlpha(30), child: Icon(template.$3, color: EmployeeColors.purple)),
              title: Text('BBT Approvals - ${template.$1}', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(template.$2),
              trailing: template.$4 ? const Icon(Icons.chevron_right_rounded) : const Text('Soon'),
              onTap: template.$4 ? () async {
                final sent = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _DailyApprovalForm(userId: userId, service: service)));
                if (sent == true && context.mounted) Navigator.of(context).pop(true);
              } : null,
            ),
          )),
        ],
      ),
    );
  }
}

class _DailyApprovalForm extends StatefulWidget {
  final String userId;
  final EmployeeService service;
  const _DailyApprovalForm({required this.userId, required this.service});
  @override State<_DailyApprovalForm> createState() => _DailyApprovalFormState();
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

  @override void dispose() { _title.dispose(); _tasks.dispose(); _expected.dispose(); _actual.dispose(); super.dispose(); }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate() || _date == null || _session == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete all required fields.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.submitDailyApproval(widget.userId, {
        'title': _title.text.trim(), 'date': DateFormat('yyyy-MM-dd').format(_date!), 'session': _session,
        'task_details': _tasks.text.trim(), 'expected_result': _expected.text.trim(), 'actual_result': _actual.text.trim(),
        'approvers': const ['Team Lead', 'CEO'],
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to send: $error')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  InputDecoration _fieldDecoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(110),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide.none,
    ),
  );

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daily Reports')),
    bottomNavigationBar: SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(children: [
          TextButton.icon(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
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
        ]),
      ),
    ),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('BBT Approvals - Daily Reports', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const Text('Bit Byte Daily Approvals for Employees'), const SizedBox(height: 18),
      TextFormField(controller: _title, validator: _required, onChanged: (_) => setState(() {}), decoration: _fieldDecoration('Name of request *', 'Use a name that is easy to understand')),
      const SizedBox(height: 16), const Text('Approvers *', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
      const Wrap(spacing: 7, runSpacing: 7, children: [Chip(label: Text('1  Team Lead')), Chip(label: Text('2  CEO • Final'))]),
      const SizedBox(height: 16),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Date *'), subtitle: Text(_date == null ? 'Select a date' : DateFormat('dd MMM yyyy').format(_date!)), trailing: const Icon(Icons.calendar_month_rounded), onTap: () async { final value = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 30))); if (value != null) setState(() => _date = value); }),
      const Text('Session *', style: TextStyle(fontWeight: FontWeight.w800)),
      RadioListTile(value: 'Forenoon', groupValue: _session, title: const Text('Forenoon'), onChanged: (value) => setState(() => _session = value)),
      RadioListTile(value: 'Afternoon', groupValue: _session, title: const Text('Afternoon'), onChanged: (value) => setState(() => _session = value)),
      const SizedBox(height: 8),
      TextFormField(controller: _tasks, validator: _required, onChanged: (_) => setState(() {}), minLines: 3, maxLines: 5, decoration: _fieldDecoration('Tasks Details - Brief Description *', 'Enter your response')), const SizedBox(height: 16),
      TextFormField(controller: _expected, validator: _required, onChanged: (_) => setState(() {}), minLines: 2, maxLines: 3, decoration: _fieldDecoration('Expected Result *', 'Enter your response')), const SizedBox(height: 16),
      TextFormField(controller: _actual, validator: _required, onChanged: (_) => setState(() {}), minLines: 2, maxLines: 3, decoration: _fieldDecoration('Actual Result (With Justification) *', 'Enter your response')), const SizedBox(height: 24),
    ])),
  );
}
