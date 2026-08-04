import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import '../Employee/employee_shared.dart';
import 'client_visit_models.dart';
import 'client_visit_service.dart';

class ClientVisitManagerApprovalScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitManagerApprovalScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 3,
    userId: userId,
    visitId: visitId,
    service: service,
    reviewerMode: true,
  );
}

class ClientVisitApprovedScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitApprovedScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 4,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitOfficeCheckoutScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitOfficeCheckoutScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 5,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitTravelProgressScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitTravelProgressScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 6,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitCheckInScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitCheckInScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 7,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitActiveScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitActiveScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 8,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitWorkUpdateScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitWorkUpdateScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 9,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitExpenseScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitExpenseScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 10,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitReturnCheckoutScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitReturnCheckoutScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 11,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitSummaryScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  final bool reviewerMode;
  const ClientVisitSummaryScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
    this.reviewerMode = false,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 12,
    userId: userId,
    visitId: visitId,
    service: service,
    reviewerMode: reviewerMode,
  );
}

class _VisitFlowPage extends StatefulWidget {
  final int step;
  final String userId;
  final int visitId;
  final ClientVisitService service;
  final bool reviewerMode;
  const _VisitFlowPage({
    required this.step,
    required this.userId,
    required this.visitId,
    required this.service,
    this.reviewerMode = false,
  });
  @override
  State<_VisitFlowPage> createState() => _VisitFlowPageState();
}

class _VisitFlowPageState extends State<_VisitFlowPage> {
  static const _filesChannel = MethodChannel('hrms/files');
  ClientVisit? _visit;
  String? _error;
  bool _working = false;
  final _notes = TextEditingController();
  final _attendee = TextEditingController();
  final _amount = TextEditingController();
  final _expenseNote = TextEditingController();
  final _outcome = TextEditingController();
  final _followUp = TextEditingController();
  final _signature = TextEditingController();
  final _odometer = TextEditingController();
  String _expenseCategory = 'travel';
  String _returnMode = 'return_office';
  List<String> _attendees = [];
  List<Map<String, dynamic>> _checklist = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _notes,
      _attendee,
      _amount,
      _expenseNote,
      _outcome,
      _followUp,
      _signature,
      _odometer,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final visit = await widget.service.fetchVisit(
        widget.userId,
        widget.visitId,
      );
      if (!mounted) return;
      setState(() {
        _visit = visit;
        _error = null;
        _notes.text = visit.notes;
        _attendees = visit.attendees.map((item) => '$item').toList();
        _checklist = visit.checklist.isEmpty
            ? _defaultChecklist()
            : visit.checklist
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    }
  }

  List<Map<String, dynamic>> _defaultChecklist() => [
    {'label': 'Discuss visit purpose', 'done': false},
    {'label': 'Capture client requirements', 'done': false},
    {'label': 'Confirm next action', 'done': false},
    {'label': 'Upload visit proof', 'done': false},
  ];

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

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _working = true);
    try {
      await task();
      await _load();
    } catch (error) {
      if (mounted) _message('$error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(value.replaceFirst('Exception: ', ''))),
  );
  void _replace(Widget screen) => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => screen));

  Future<void> _review(String action) async {
    final comment = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'approve' ? 'Approve visit' : 'Request changes'),
        content: TextField(
          controller: comment,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'TL comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action == 'approve' ? 'Approve' : 'Send back'),
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
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _officeCheckout() async {
    await _run(() async {
      final selfie = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
      );
      if (selfie == null) return;
      await widget.service.uploadFiles(
        widget.userId,
        widget.visitId,
        'check_in',
        [selfie.path],
      );
      await widget.service
          .action(widget.userId, widget.visitId, 'start-travel', {
            ...await _position(),
            if (_odometer.text.trim().isNotEmpty)
              'odometer': _odometer.text.trim(),
          });
      if (mounted) {
        _replace(
          ClientVisitTravelProgressScreen(
            userId: widget.userId,
            visitId: widget.visitId,
            service: widget.service,
          ),
        );
      }
    });
  }

  Future<void> _reached() async {
    await _run(() async {
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'reached-client',
        await _position(),
      );
    });
    if (mounted) {
      _replace(
        ClientVisitCheckInScreen(
          userId: widget.userId,
          visitId: widget.visitId,
          service: widget.service,
        ),
      );
    }
  }

  Future<void> _clientCheckIn() async {
    await _run(() async {
      final selfie = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
      );
      if (selfie == null) return;
      await widget.service.uploadFiles(
        widget.userId,
        widget.visitId,
        'check_in',
        [selfie.path],
      );
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'check-in',
        await _position(),
      );
      if (mounted) {
        _replace(
          ClientVisitActiveScreen(
            userId: widget.userId,
            visitId: widget.visitId,
            service: widget.service,
          ),
        );
      }
    });
  }

  Future<void> _saveWorkUpdate() async {
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'progress', {
        'notes': _notes.text.trim(),
        'attendees': _attendees,
        'checklist': _checklist,
      });
      final images = await ImagePicker().pickMultiImage(imageQuality: 82);
      if (images.isNotEmpty) {
        await widget.service.uploadFiles(
          widget.userId,
          widget.visitId,
          'proof',
          images.map((item) => item.path).toList(),
        );
      }
    });
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addExpense() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _message('Enter a valid expense amount.');
      return;
    }
    await _run(() async {
      await widget.service.addExpense(
        widget.userId,
        widget.visitId,
        _expenseCategory,
        amount,
        _expenseNote.text.trim(),
      );
      final receipt = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (receipt != null) {
        await widget.service.uploadFiles(
          widget.userId,
          widget.visitId,
          'expense',
          [receipt.path],
        );
      }
      _amount.clear();
      _expenseNote.clear();
    });
  }

  Future<void> _complete() async {
    if (_outcome.text.trim().isEmpty) {
      _message('Visit outcome is required.');
      return;
    }
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'complete', {
        ...await _position(),
        'outcome': _outcome.text.trim(),
        'follow_up': _followUp.text.trim(),
        'client_signature_name': _signature.text.trim(),
        'return_mode': _returnMode,
      });
      if (mounted) {
        _replace(
          ClientVisitSummaryScreen(
            userId: widget.userId,
            visitId: widget.visitId,
            service: widget.service,
          ),
        );
      }
    });
  }

  Future<void> _verify() async {
    await _run(() async {
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'verify',
        const {},
      );
    });
  }

  Future<void> _downloadReport(ClientVisit visit) async {
    await _run(() async {
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Text(
              'HRMS-ERP Client Visit Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const ['Field', 'Details'],
              data: [
                ['Visit ID', visit.visitId],
                ['Employee', visit.employeeName],
                ['Client', visit.clientName],
                ['Contact', visit.contactPerson],
                ['Address', visit.address],
                ['Purpose', visit.purpose],
                ['Status', _label(visit.status)],
                ['Attendees', visit.attendees.join(', ')],
                ['Expenses', 'INR ${visit.expenseTotal.toStringAsFixed(2)}'],
                ['Outcome', visit.outcome],
                ['Follow-up', visit.followUp],
                ['Return mode', _label(visit.returnMode)],
                [
                  'Manager verification',
                  visit.managerVerifiedBy.isEmpty ? 'Pending' : 'Verified',
                ],
              ],
            ),
          ],
        ),
      );
      final bytes = await document.save();
      final location = await _filesChannel
          .invokeMethod<String>('saveToDownloads', {
            'fileName': '${visit.visitId}-client-visit-report.pdf',
            'mimeType': 'application/pdf',
            'bytes': bytes,
          });
      _message('Report downloaded to ${location ?? 'Downloads/HRMS-ERP'}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final visit = _visit;
    return Scaffold(
      appBar: AppBar(
        title: AppBarLogoTitle(
          title:
              '${widget.step.toString().padLeft(2, '0')} ${_title(widget.step)}',
        ),
      ),
      body: _error != null
          ? _stateMessage(Icons.error_outline, _error!, _load)
          : visit == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _stepHeader(visit),
                const SizedBox(height: 12),
                ..._content(visit),
                if (_working)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
    );
  }

  List<Widget> _content(ClientVisit visit) => switch (widget.step) {
    3 => [
      _visitInfo(visit),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _working ? null : () => _review('changes'),
              icon: const Icon(Icons.undo),
              label: const Text('Request changes'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: _working ? null : () => _review('approve'),
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
            ),
          ),
        ],
      ),
    ],
    4 => [
      _visitInfo(visit),
      const SizedBox(height: 12),
      if (visit.status == 'approved')
        FilledButton.icon(
          onPressed: () => _replace(
            ClientVisitOfficeCheckoutScreen(
              userId: widget.userId,
              visitId: widget.visitId,
              service: widget.service,
            ),
          ),
          icon: const Icon(Icons.directions_car),
          label: const Text('Start from office'),
        )
      else
        _statusNotice(visit),
    ],
    5 => [
      _visitInfo(visit),
      const SizedBox(height: 12),
      EmployeeCard(
        child: Column(
          children: [
            const Icon(
              Icons.camera_alt_rounded,
              size: 52,
              color: EmployeeColors.blue,
            ),
            const SizedBox(height: 10),
            const Text('A selfie and current GPS location are required.'),
            TextField(
              controller: _odometer,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Odometer (optional)',
                suffixText: 'km',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _working ? null : _officeCheckout,
                child: const Text('Confirm office check-out'),
              ),
            ),
          ],
        ),
      ),
    ],
    6 => [
      EmployeeCard(
        child: Column(
          children: [
            const Icon(
              Icons.route_rounded,
              size: 56,
              color: EmployeeColors.blue,
            ),
            const SizedBox(height: 8),
            Text(visit.address, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Live GPS journey in progress'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _working ? null : _reached,
                icon: const Icon(Icons.flag),
                label: const Text('Reached client'),
              ),
            ),
          ],
        ),
      ),
    ],
    7 => [
      _visitInfo(visit),
      const SizedBox(height: 12),
      EmployeeCard(
        child: Column(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 54,
              color: EmployeeColors.green,
            ),
            Text(
              'Within client location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Capture arrival selfie and GPS to begin the visit.'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _working ? null : _clientCheckIn,
                child: const Text('Client check-in'),
              ),
            ),
          ],
        ),
      ),
    ],
    8 => [
      if (visit.checkInAt != null) _FlowTimer(startedAt: visit.checkInAt!),
      const SizedBox(height: 12),
      EmployeeCard(
        child: Column(
          children: [
            EmployeeInfoRow('Attendees', '${visit.attendees.length}'),
            EmployeeInfoRow(
              'Checklist',
              '${visit.checklist.where((item) => item is Map && item['done'] == true).length}/${visit.checklist.length} completed',
            ),
            const SizedBox(height: 8),
            _flowButton(
              Icons.edit_note,
              'Work update & proof',
              () => _push(
                ClientVisitWorkUpdateScreen(
                  userId: widget.userId,
                  visitId: widget.visitId,
                  service: widget.service,
                ),
              ),
            ),
            _flowButton(
              Icons.receipt_long,
              'Expense claim',
              () => _push(
                ClientVisitExpenseScreen(
                  userId: widget.userId,
                  visitId: widget.visitId,
                  service: widget.service,
                ),
              ),
            ),
            _flowButton(
              Icons.logout,
              'Return / direct checkout',
              () => _push(
                ClientVisitReturnCheckoutScreen(
                  userId: widget.userId,
                  visitId: widget.visitId,
                  service: widget.service,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
    9 => [
      EmployeeCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _attendee,
                    decoration: const InputDecoration(
                      labelText: 'Attendee name',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_attendee.text.trim().isNotEmpty) {
                      setState(() {
                        _attendees.add(_attendee.text.trim());
                        _attendee.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.person_add),
                ),
              ],
            ),
            if (_attendees.isNotEmpty)
              Wrap(
                spacing: 6,
                children: _attendees
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        onDeleted: () =>
                            setState(() => _attendees.remove(name)),
                      ),
                    )
                    .toList(),
              ),
            ..._checklist.asMap().entries.map(
              (entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: entry.value['done'] == true,
                title: Text('${entry.value['label']}'),
                onChanged: (value) => setState(
                  () => _checklist[entry.key]['done'] = value == true,
                ),
              ),
            ),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes / outcome'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _working ? null : _saveWorkUpdate,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Save & upload proof'),
              ),
            ),
          ],
        ),
      ),
    ],
    10 => [
      EmployeeCard(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _expenseCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const ['travel', 'food', 'parking', 'other']
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_label(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _expenseCategory = value!),
            ),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
            TextField(
              controller: _expenseNote,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _working ? null : _addExpense,
                icon: const Icon(Icons.add),
                label: const Text('Add expense & receipt'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      EmployeeCard(
        child: Column(
          children: [
            for (final expense in visit.expenses)
              EmployeeInfoRow(
                _label('${expense['category']}'),
                '₹${expense['amount']}',
              ),
            const Divider(),
            EmployeeInfoRow(
              'Total',
              '₹${visit.expenseTotal.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    ],
    11 => [
      EmployeeCard(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _returnMode,
              decoration: const InputDecoration(labelText: 'Duty completion'),
              items: const [
                DropdownMenuItem(
                  value: 'return_office',
                  child: Text('Return to office'),
                ),
                DropdownMenuItem(
                  value: 'end_duty_client',
                  child: Text('End duty from client'),
                ),
              ],
              onChanged: (value) => setState(() => _returnMode = value!),
            ),
            TextField(
              controller: _outcome,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Outcome *'),
            ),
            TextField(
              controller: _followUp,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Follow-up'),
            ),
            TextField(
              controller: _signature,
              decoration: const InputDecoration(
                labelText: 'Client signature / OTP name',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _working ? null : _complete,
                icon: const Icon(Icons.task_alt),
                label: const Text('Complete duty'),
              ),
            ),
          ],
        ),
      ),
    ],
    12 => [
      _timeline(visit),
      const SizedBox(height: 12),
      _summary(visit),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _working ? null : () => _downloadReport(visit),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Download report'),
      ),
      if (widget.reviewerMode && visit.managerVerifiedBy.isEmpty) ...[
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _working ? null : _verify,
          icon: const Icon(Icons.verified),
          label: const Text('Verify completed visit'),
        ),
      ],
    ],
    _ => [_visitInfo(visit)],
  };

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  Widget _flowButton(IconData icon, String label, VoidCallback onPressed) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      );
  Widget _stepHeader(ClientVisit visit) => Row(
    children: [
      CircleAvatar(
        backgroundColor: EmployeeColors.blue,
        child: Text(
          '${widget.step}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visit.clientName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(visit.visitId),
          ],
        ),
      ),
      _statusChip(visit.status),
    ],
  );
  Widget _visitInfo(ClientVisit visit) => EmployeeCard(
    child: Column(
      children: [
        EmployeeInfoRow(
          'Employee',
          visit.employeeName.isEmpty
              ? visit.employeeUserId
              : visit.employeeName,
        ),
        EmployeeInfoRow('Contact', visit.contactPerson),
        EmployeeInfoRow(
          'Phone',
          visit.contactPhone.isEmpty ? '—' : visit.contactPhone,
        ),
        EmployeeInfoRow('Date', _date(visit.scheduledAt)),
        EmployeeInfoRow('Purpose', visit.purpose),
        EmployeeInfoRow('Travel mode', _label(visit.travelMode)),
        Align(alignment: Alignment.centerLeft, child: Text(visit.address)),
      ],
    ),
  );
  Widget _statusNotice(ClientVisit visit) => EmployeeCard(
    child: Column(
      children: [
        Icon(
          visit.status == 'rejected' ? Icons.info_outline : Icons.hourglass_top,
          color: employeeStatusColor(visit.status),
        ),
        const SizedBox(height: 8),
        Text(
          visit.status == 'rejected'
              ? visit.approvalComment
              : 'Waiting for TL approval',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
  Widget _timeline(ClientVisit visit) => EmployeeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visit timeline', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _timeRow('Office check-out', visit.officeCheckOutAt),
        _timeRow('Reached client', visit.reachedClientAt),
        _timeRow('Client check-in', visit.checkInAt),
        _timeRow('Visit completed', visit.checkOutAt),
      ],
    ),
  );
  Widget _timeRow(String label, DateTime? time) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      time == null ? Icons.radio_button_unchecked : Icons.check_circle,
      color: time == null ? Colors.grey : EmployeeColors.green,
    ),
    title: Text(label),
    trailing: Text(
      time == null
          ? '—'
          : TimeOfDay.fromDateTime(time.toLocal()).format(context),
    ),
  );
  Widget _summary(ClientVisit visit) => EmployeeCard(
    child: Column(
      children: [
        EmployeeInfoRow('Status', _label(visit.status)),
        EmployeeInfoRow(
          'Duration',
          visit.checkInAt == null
              ? '—'
              : _duration(
                  DateTime.now().difference(visit.checkInAt!.toLocal()),
                ),
        ),
        EmployeeInfoRow('Attendees', '${visit.attendees.length}'),
        EmployeeInfoRow(
          'Expenses',
          '₹${visit.expenseTotal.toStringAsFixed(2)}',
        ),
        EmployeeInfoRow('Return mode', _label(visit.returnMode)),
        EmployeeInfoRow('Outcome', visit.outcome.isEmpty ? '—' : visit.outcome),
        EmployeeInfoRow(
          'Manager verification',
          visit.managerVerifiedBy.isEmpty ? 'Pending' : 'Verified',
        ),
      ],
    ),
  );
  Widget _statusChip(String status) {
    final color = employeeStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
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

  Widget _stateMessage(
    IconData icon,
    String text,
    Future<void> Function() retry,
  ) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _FlowTimer extends StatefulWidget {
  final DateTime startedAt;
  const _FlowTimer({required this.startedAt});
  @override
  State<_FlowTimer> createState() => _FlowTimerState();
}

class _FlowTimerState extends State<_FlowTimer> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = DateTime.now().difference(widget.startedAt.toLocal());
    return EmployeeCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: EmployeeColors.blue),
          const SizedBox(width: 8),
          Text(
            _duration(value),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: EmployeeColors.blue),
          ),
        ],
      ),
    );
  }
}

String _title(int step) =>
    const {
      3: 'Manager Approval',
      4: 'Approved Visit',
      5: 'Office Check-Out',
      6: 'Travel in Progress',
      7: 'Client Check-In',
      8: 'Active Client Visit',
      9: 'Work Update & Proof',
      10: 'Expense Claim',
      11: 'Return / Direct Checkout',
      12: 'Visit Summary & Verification',
    }[step] ??
    'Client Visit';
String _label(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
String _duration(Duration value) =>
    '${value.inHours.toString().padLeft(2, '0')}:${(value.inMinutes % 60).toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
