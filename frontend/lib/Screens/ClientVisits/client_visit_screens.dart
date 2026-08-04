import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import '../Employee/employee_shared.dart';
import 'client_visit_models.dart';
import 'client_visit_service.dart';

const _statuses = [
  'all',
  'draft',
  'pending',
  'approved',
  'in_progress',
  'completed',
  'rejected',
];

class ClientVisitDashboardScreen extends StatefulWidget {
  final String userId;
  final bool reviewerMode;
  const ClientVisitDashboardScreen({
    super.key,
    required this.userId,
    this.reviewerMode = false,
  });

  @override
  State<ClientVisitDashboardScreen> createState() =>
      _ClientVisitDashboardScreenState();
}

class _ClientVisitDashboardScreenState
    extends State<ClientVisitDashboardScreen> {
  final _service = ClientVisitService();
  ClientVisitListResult? _result;
  String _filter = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final value = await _service.fetchVisits(
        widget.userId,
        status: _filter == 'all' ? '' : _filter,
      );
      if (mounted) setState(() => _result = value);
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _create() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ClientVisitCreateScreen(userId: widget.userId, service: _service),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Visits',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Office → Client location → Closure',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result != null) _Summary(summary: result.summary),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((status) {
                final selected = status == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(_label(status)),
                    onSelected: (_) {
                      setState(() => _filter = status);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (_error != null)
            _Message(
              icon: Icons.cloud_off_rounded,
              text: _error!,
              onRetry: _load,
            )
          else if (result == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (result.visits.isEmpty)
            _Message(
              icon: Icons.location_off_outlined,
              text:
                  'No ${_filter == 'all' ? '' : '${_label(_filter)} '}visits yet.',
              onRetry: _create,
            )
          else
            ...result.visits.map(
              (visit) => _VisitCard(
                visit: visit,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClientVisitDetailScreen(
                        userId: widget.userId,
                        visitId: visit.id,
                        service: _service,
                        reviewerMode: widget.reviewerMode,
                      ),
                    ),
                  );
                  _load();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ClientVisitCreateScreen extends StatefulWidget {
  final String userId;
  final ClientVisitService service;
  const ClientVisitCreateScreen({
    super.key,
    required this.userId,
    required this.service,
  });
  @override
  State<ClientVisitCreateScreen> createState() =>
      _ClientVisitCreateScreenState();
}

class _ClientVisitCreateScreenState extends State<ClientVisitCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _client = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _purpose = TextEditingController();
  final _notes = TextEditingController();
  final _manager = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _travelMode = 'car';
  bool _saving = false;

  @override
  void dispose() {
    for (final value in [
      _client,
      _contact,
      _phone,
      _address,
      _purpose,
      _notes,
      _manager,
    ]) {
      value.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Required' : null;

  Future<void> _submit(bool submit) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.create(widget.userId, {
        'client_name': _client.text.trim(),
        'contact_person': _contact.text.trim(),
        'contact_phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'scheduled_date': _ymd(_date),
        'scheduled_time':
            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
        'duration_minutes': 60,
        'travel_mode': _travelMode,
        'purpose': _purpose.text.trim(),
        'notes': _notes.text.trim(),
        'manager_user_id': _manager.text.trim(),
        'submit': submit,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _snack(context, '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const AppBarLogoTitle(title: 'Create Visit Request')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Client',
            children: [
              TextFormField(
                controller: _client,
                validator: _required,
                decoration: const InputDecoration(
                  labelText: 'Client / company name',
                ),
              ),
              TextFormField(
                controller: _contact,
                validator: _required,
                decoration: const InputDecoration(labelText: 'Contact person'),
              ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact phone'),
              ),
              TextFormField(
                controller: _address,
                validator: _required,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Client address'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Visit plan',
            children: [
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(_ymd(_date)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                        );
                        if (date != null) setState(() => _date = date);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time'),
                      subtitle: Text(_time.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (time != null) setState(() => _time = time);
                      },
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: _travelMode,
                decoration: const InputDecoration(labelText: 'Travel mode'),
                items: const ['car', 'bike', 'public_transport', 'walk']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_label(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _travelMode = value!),
              ),
              TextFormField(
                controller: _purpose,
                validator: _required,
                decoration: const InputDecoration(labelText: 'Purpose'),
              ),
              TextFormField(
                controller: _manager,
                decoration: const InputDecoration(
                  labelText: 'Reporting manager user ID',
                ),
              ),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _submit(false),
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => _submit(true),
                  child: Text(_saving ? 'Saving…' : 'Submit request'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class ClientVisitDetailScreen extends StatefulWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  final bool reviewerMode;
  const ClientVisitDetailScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
    this.reviewerMode = false,
  });
  @override
  State<ClientVisitDetailScreen> createState() =>
      _ClientVisitDetailScreenState();
}

class _ClientVisitDetailScreenState extends State<ClientVisitDetailScreen> {
  ClientVisit? _visit;
  String? _error;
  bool _working = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await widget.service.fetchVisit(
        widget.userId,
        widget.visitId,
      );
      if (mounted) {
        setState(() {
          _visit = value;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<Map<String, double>> _position() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required.');
    }
    final value = await Geolocator.getCurrentPosition();
    return {'latitude': value.latitude, 'longitude': value.longitude};
  }

  Future<void> _checkIn() async {
    await _run(() async {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return;
      await widget.service.uploadFiles(
        widget.userId,
        widget.visitId,
        'check_in',
        [image.path],
      );
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'check-in',
        await _position(),
      );
    });
  }

  Future<void> _uploadProof() async {
    await _run(() async {
      final images = await ImagePicker().pickMultiImage(imageQuality: 82);
      if (images.isEmpty) return;
      await widget.service.uploadFiles(
        widget.userId,
        widget.visitId,
        'proof',
        images.map((e) => e.path).toList(),
      );
    });
  }

  Future<void> _complete() async {
    final outcome = TextEditingController();
    final follow = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: outcome,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Outcome *'),
            ),
            TextField(
              controller: follow,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Follow-up'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (accepted != true || outcome.text.trim().isEmpty) return;
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'complete', {
        ...await _position(),
        'outcome': outcome.text.trim(),
        'follow_up': follow.text.trim(),
      });
    });
  }

  Future<void> _expense() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    String category = 'travel';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                items: const ['travel', 'food', 'parking', 'other']
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(_label(e))),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => category = v!),
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    final value = double.tryParse(amount.text);
    if (accepted != true || value == null) return;
    await _run(
      () => widget.service.addExpense(
        widget.userId,
        widget.visitId,
        category,
        value,
        note.text.trim(),
      ),
    );
  }

  Future<void> _review(String action) async {
    final comment = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'approve' ? 'Approve visit' : 'Return request'),
        content: TextField(
          controller: comment,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Manager comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action == 'approve' ? 'Approve' : 'Return'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'approval', {
        'action': action,
        'comment': comment.text.trim(),
      });
    });
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _working = true);
    try {
      await task();
      await _load();
    } catch (e) {
      if (mounted) _snack(context, '$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = _visit;
    return Scaffold(
      appBar: AppBar(title: const AppBarLogoTitle(title: 'Visit Details')),
      body: _error != null
          ? _Message(icon: Icons.error_outline, text: _error!, onRetry: _load)
          : visit == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.clientName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(visit.visitId),
                        ],
                      ),
                    ),
                    _StatusChip(visit.status),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Visit information',
                  children: [
                    EmployeeInfoRow('Contact', visit.contactPerson),
                    EmployeeInfoRow(
                      'Phone',
                      visit.contactPhone.isEmpty ? '—' : visit.contactPhone,
                    ),
                    EmployeeInfoRow(
                      'Schedule',
                      '${_ymd(visit.scheduledAt)} ${TimeOfDay.fromDateTime(visit.scheduledAt).format(context)}',
                    ),
                    EmployeeInfoRow('Purpose', visit.purpose),
                    EmployeeInfoRow('Travel', _label(visit.travelMode)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        visit.address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (visit.approvalComment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Manager response',
                    children: [Text(visit.approvalComment)],
                  ),
                ],
                const SizedBox(height: 12),
                _Section(
                  title: 'Work update & proof',
                  children: [
                    EmployeeInfoRow(
                      'Uploaded files',
                      '${visit.attachments.length}',
                    ),
                    EmployeeInfoRow(
                      'Expenses',
                      '₹${visit.expenseTotal.toStringAsFixed(2)}',
                    ),
                    if (visit.outcome.isNotEmpty)
                      EmployeeInfoRow('Outcome', visit.outcome),
                    if (!widget.reviewerMode)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _working ? null : _uploadProof,
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Upload proof'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _working ? null : _expense,
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('Add expense'),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!widget.reviewerMode && visit.status == 'approved')
                  FilledButton.icon(
                    onPressed: _working ? null : _checkIn,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Client check-in'),
                  ),
                if (!widget.reviewerMode && visit.status == 'in_progress')
                  FilledButton.icon(
                    onPressed: _working ? null : _complete,
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Complete visit'),
                  ),
                if (widget.reviewerMode && visit.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _working ? null : () => _review('changes'),
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Request changes'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _working ? null : () => _review('approve'),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                if (_working)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  final Map<String, int> summary;
  const _Summary({required this.summary});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _box(
        context,
        'Active',
        (summary['approved'] ?? 0) + (summary['in_progress'] ?? 0),
        EmployeeColors.blue,
      ),
      const SizedBox(width: 8),
      _box(context, 'Pending', summary['pending'] ?? 0, EmployeeColors.gold),
      const SizedBox(width: 8),
      _box(
        context,
        'Completed',
        summary['completed'] ?? 0,
        EmployeeColors.green,
      ),
    ],
  );
  Widget _box(BuildContext context, String label, int count, Color color) =>
      Expanded(
        child: EmployeeCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                '$count',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: color),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _VisitCard extends StatelessWidget {
  final ClientVisit visit;
  final VoidCallback onTap;
  const _VisitCard({required this.visit, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: EmployeeCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: employeeStatusColor(visit.status).withAlpha(35),
          child: Icon(
            Icons.business_rounded,
            color: employeeStatusColor(visit.status),
          ),
        ),
        title: Text(visit.clientName),
        subtitle: Text(
          '${_ymd(visit.scheduledAt)} • ${visit.contactPerson}\n${visit.purpose}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: _StatusChip(visit.status),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);
  @override
  Widget build(BuildContext context) {
    final color = employeeStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => EmployeeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...children.map(
          (e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: e),
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Future<void> Function() onRetry;
  const _Message({
    required this.icon,
    required this.text,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(icon, size: 48, color: ThemeConfig.getTextMuted(context)),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

String _label(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
String _ymd(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
void _snack(BuildContext context, String value) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(value.replaceFirst('Exception: ', ''))));
