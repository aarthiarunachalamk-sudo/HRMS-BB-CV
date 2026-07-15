import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:image_picker/image_picker.dart';

import 'employee_models.dart';
import 'employee_service.dart';
import 'employee_shared.dart';

enum _LeaveStep {
  dashboard,
  type,
  details,
  document,
  review,
  submitted,
  leaves,
}

class EmployeeLeaveScreen extends StatefulWidget {
  final String userId;
  final EmployeeDashboardData data;
  final EmployeeService service;

  const EmployeeLeaveScreen({
    super.key,
    required this.userId,
    required this.data,
    required this.service,
  });

  @override
  State<EmployeeLeaveScreen> createState() => _EmployeeLeaveScreenState();
}

class _EmployeeLeaveScreenState extends State<EmployeeLeaveScreen> {
  static const List<_LeaveTypeOption> _leaveTypes = [
    _LeaveTypeOption(
      'Sick Leave',
      '8 days per annum',
      Icons.healing_rounded,
    ),
    _LeaveTypeOption(
      'Casual Leave',
      '4 days per annum',
      Icons.event_available_rounded,
    ),
    _LeaveTypeOption(
      'Annual Leave',
      '12 days per annum',
      Icons.card_giftcard_rounded,
    ),
    _LeaveTypeOption(
      'Compensatory Leave',
      'For holidays/weekends, use within 30 days',
      Icons.swap_horiz_rounded,
    ),
    _LeaveTypeOption(
      'Maternity Leave',
      'As per Labour law, Govt of India',
      Icons.pregnant_woman_rounded,
    ),
    _LeaveTypeOption(
      'Paternity Leave',
      'As per Labour law, Govt of India',
      Icons.family_restroom_rounded,
    ),
    _LeaveTypeOption(
      'LOP',
      'Loss of Pay when balance is exhausted',
      Icons.money_off_rounded,
    ),
  ];

  _LeaveStep _step = _LeaveStep.dashboard;
  String _selectedType = _leaveTypes.first.title;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  String _session = 'Full Day';
  String _reason = '';
  String _emergencyContact = '';
  String _documentName = '';
  String _documentPath = '';
  List<Map<String, dynamic>> _records = const [];
  Map<String, dynamic> _leaveBalances = const {};
  bool _loadingRecords = false;
  bool _submitting = false;
  String? _error;

  int get _days => _toDate.difference(_fromDate).inDays + 1;

  bool get _needsDocument => _selectedType == 'Sick Leave';

  @override
  void initState() {
    super.initState();
    _records = widget.data.leaves;
    _leaveBalances = widget.data.leaveBalances;
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() => _loadingRecords = true);
    final now = DateTime.now();
    try {
      final result = await widget.service.fetchLeaveHistory(
        widget.userId,
        DateTime(now.year, 1, 1),
        DateTime(now.year, 12, 31),
      );
      if (mounted) {
        setState(() {
          _records = result.records;
          if (result.leaveBalances.isNotEmpty) {
            _leaveBalances = result.leaveBalances;
          }
        });
      }
    } catch (_) {
      // Keep dashboard-provided leave records if the history refresh fails.
    } finally {
      if (mounted) setState(() => _loadingRecords = false);
    }
  }

  void _startFlow() {
    setState(() {
      _step = _LeaveStep.type;
      _error = null;
    });
  }

  void _goBack() {
    setState(() {
      _error = null;
      switch (_step) {
        case _LeaveStep.dashboard:
          break;
        case _LeaveStep.type:
        case _LeaveStep.leaves:
          _step = _LeaveStep.dashboard;
          break;
        case _LeaveStep.details:
          _step = _LeaveStep.type;
          break;
        case _LeaveStep.document:
          _step = _LeaveStep.details;
          break;
        case _LeaveStep.review:
          _step = _needsDocument ? _LeaveStep.document : _LeaveStep.details;
          break;
        case _LeaveStep.submitted:
          _step = _LeaveStep.dashboard;
          break;
      }
    });
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type;
      _step = _LeaveStep.details;
      _error = null;
    });
  }

  void _continueDetails({
    required DateTime fromDate,
    required DateTime toDate,
    required String session,
    required String reason,
    required String emergencyContact,
  }) {
    if (toDate.isBefore(fromDate)) {
      setState(() => _error = 'To date cannot be before from date.');
      return;
    }
    if (reason.trim().isEmpty) {
      setState(() => _error = 'Please enter leave reason.');
      return;
    }

    setState(() {
      _fromDate = fromDate;
      _toDate = toDate;
      _session = session;
      _reason = reason.trim();
      _emergencyContact = emergencyContact.trim();
      _error = null;
      _step = _needsDocument ? _LeaveStep.document : _LeaveStep.review;
    });
  }

  void _continueDocument(String documentName, String documentPath) {
    if (_needsDocument && documentPath.isEmpty) {
      setState(() => _error = 'Please upload medical certificate.');
      return;
    }
    setState(() {
      _documentName = documentName;
      _documentPath = documentPath;
      _error = null;
      _step = _LeaveStep.review;
    });
  }

  Future<void> _submitRequest() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.service.submitLeave(widget.userId, {
        'leave_type': _selectedType,
        'from_date': _dateParam(_fromDate),
        'to_date': _dateParam(_toDate),
        'reason': _reason,
        'session': _session,
        'emergency_contact': _emergencyContact,
        'document_name': _documentName,
        'medical_certificate_path': _documentPath,
      });
      await _loadLeaves();
      if (!mounted) return;
      setState(() => _step = _LeaveStep.submitted);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: switch (_step) {
          _LeaveStep.dashboard => _LeaveDashboard(
            profile: widget.data.profile,
            leaveBalances: _leaveBalances,
            records: _records,
            loading: _loadingRecords,
            onApply: _startFlow,
            onLeaves: () => setState(() => _step = _LeaveStep.leaves),
          ),
          _LeaveStep.type => _SelectLeaveTypePage(
            selectedType: _selectedType,
            leaveTypes: _leaveTypes,
            onBack: _goBack,
            onSelect: _selectType,
          ),
          _LeaveStep.details => _LeaveDetailsPage(
            leaveType: _selectedType,
            initialFrom: _fromDate,
            initialTo: _toDate,
            initialSession: _session,
            initialReason: _reason,
            initialEmergencyContact: _emergencyContact,
            error: _error,
            onBack: _goBack,
            onContinue: _continueDetails,
          ),
          _LeaveStep.document => _UploadDocumentPage(
            leaveType: _selectedType,
            error: _error,
            onBack: _goBack,
            onContinue: _continueDocument,
          ),
          _LeaveStep.review => _ReviewLeavePage(
            leaveType: _selectedType,
            records: _records,
            joiningDate: _profileJoiningDate(widget.data.profile),
            fromDate: _fromDate,
            toDate: _toDate,
            session: _session,
            reason: _reason,
            emergencyContact: _emergencyContact,
            documentName: _documentName,
            submitting: _submitting,
            error: _error,
            onBack: _goBack,
            onSubmit: _submitRequest,
          ),
          _LeaveStep.submitted => _LeaveSubmittedPage(
            leaveType: _selectedType,
            fromDate: _fromDate,
            toDate: _toDate,
            days: _days,
            onViewLeaves: () => setState(() => _step = _LeaveStep.leaves),
            onHome: () => setState(() => _step = _LeaveStep.dashboard),
          ),
          _LeaveStep.leaves => _MyLeavesPage(
            records: _records,
            loading: _loadingRecords,
            onBack: _goBack,
            onRefresh: _loadLeaves,
          ),
        },
      ),
    );
  }

  String _dateParam(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _LeaveDashboard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> leaveBalances;
  final List<Map<String, dynamic>> records;
  final bool loading;
  final VoidCallback onApply;
  final VoidCallback onLeaves;

  const _LeaveDashboard({
    required this.profile,
    required this.leaveBalances,
    required this.records,
    required this.loading,
    required this.onApply,
    required this.onLeaves,
  });

  @override
  Widget build(BuildContext context) {
    final overview = _LeaveBalanceOverview.fromSource(
      source: leaveBalances,
      profile: profile,
      records: records,
    );
    return _LeavePageShell(
      title: 'Leave',
      child: _LeaveDashboardBody(
        overview: overview,
        loading: loading,
        onApply: onApply,
        onLeaves: onLeaves,
      ),
    );
  }
}

class _LeaveDashboardBody extends StatelessWidget {
  final _LeaveBalanceOverview overview;
  final bool loading;
  final VoidCallback onApply;
  final VoidCallback onLeaves;

  const _LeaveDashboardBody({
    required this.overview,
    required this.loading,
    required this.onApply,
    required this.onLeaves,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero card ──────────────────────────────────────────────
        _LeaveHeroCard(overview: overview, loading: loading),
        const SizedBox(height: 16),
        // ── 4-metric row ──────────────────────────────────────────
        _LeaveMetricRow(overview: overview),
        const SizedBox(height: 20),
        // ── Leave Type Summary ────────────────────────────────────
        _LeaveTypeSummaryCard(overview: overview),
        const SizedBox(height: 16),
        // ── Accrual footer cards ──────────────────────────────────
        _AccrualFooterRow(overview: overview),
        const SizedBox(height: 20),
        // ── Action buttons ────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.edit_note_rounded,
                label: 'Apply Leave',
                backgroundColor: const Color(0xFFE2F5FF),
                accentColor: const Color(0xFF1597D3),
                onTap: onApply,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.calendar_month_rounded,
                label: 'My Leaves',
                backgroundColor: const Color(0xFFE5FFF2),
                accentColor: const Color(0xFF16A66A),
                onTap: onLeaves,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectLeaveTypePage extends StatelessWidget {
  final String selectedType;
  final List<_LeaveTypeOption> leaveTypes;
  final VoidCallback onBack;
  final ValueChanged<String> onSelect;

  const _SelectLeaveTypePage({
    required this.selectedType,
    required this.leaveTypes,
    required this.onBack,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return _LeavePageShell(
      title: 'Apply Leave',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(current: 1),
          const SizedBox(height: 20),
          const Text(
            'Select Leave Type',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...leaveTypes.map((type) {
            final selected = type.title == selectedType;
            return EmployeeCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: () => onSelect(type.title),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    _IconBox(
                      icon: type.icon,
                      color: employeeStatusColor(type.title),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            type.subtitle,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: selected ? EmployeeColors.blue : textSecondary,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LeaveDetailsPage extends StatefulWidget {
  final String leaveType;
  final DateTime initialFrom;
  final DateTime initialTo;
  final String initialSession;
  final String initialReason;
  final String initialEmergencyContact;
  final String? error;
  final VoidCallback onBack;
  final void Function({
    required DateTime fromDate,
    required DateTime toDate,
    required String session,
    required String reason,
    required String emergencyContact,
  })
  onContinue;

  const _LeaveDetailsPage({
    required this.leaveType,
    required this.initialFrom,
    required this.initialTo,
    required this.initialSession,
    required this.initialReason,
    required this.initialEmergencyContact,
    required this.error,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<_LeaveDetailsPage> createState() => _LeaveDetailsPageState();
}

class _LeaveDetailsPageState extends State<_LeaveDetailsPage> {
  late DateTime _fromDate = widget.initialFrom;
  late DateTime _toDate = widget.initialTo;
  late String _session = widget.initialSession;
  late final TextEditingController _reasonController = TextEditingController(
    text: widget.initialReason,
  );
  late final TextEditingController _contactController = TextEditingController(
    text: widget.initialEmergencyContact,
  );

  int get _days => _toDate.difference(_fromDate).inDays + 1;

  @override
  void dispose() {
    _reasonController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = from ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _fromDate = picked;
        if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
      } else {
        _toDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _LeavePageShell(
      title: 'Apply Leave',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(current: 2),
          const SizedBox(height: 18),
          Text(
            widget.leaveType,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _DateField(
            label: 'From Date',
            date: _fromDate,
            onTap: () => _pickDate(from: true),
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'To Date',
            date: _toDate,
            onTap: () => _pickDate(from: false),
          ),
          const SizedBox(height: 12),
          AppDropdownButtonFormField<String>(
            initialValue: _session,
            items: const ['Full Day', 'First Half', 'Second Half']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _session = value);
            },
            decoration: const InputDecoration(labelText: 'Half Day / Full Day'),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Number of Days',
              hintText: _dayCountText(_days),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Reason',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact (Optional)',
            ),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.error!,
              style: const TextStyle(color: EmployeeColors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => widget.onContinue(
                fromDate: _fromDate,
                toDate: _toDate,
                session: _session,
                reason: _reasonController.text,
                emergencyContact: _contactController.text,
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDocumentPage extends StatefulWidget {
  final String leaveType;
  final String? error;
  final VoidCallback onBack;
  final void Function(String documentName, String documentPath) onContinue;

  const _UploadDocumentPage({
    required this.leaveType,
    required this.error,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<_UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<_UploadDocumentPage> {
  String _documentName = '';
  String _documentPath = '';
  bool _picking = false;

  Future<void> _pickDocument() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final name = picked.name.isNotEmpty
          ? picked.name
          : picked.path.split(RegExp(r'[\\/]')).last;
      setState(() {
        _documentName = name;
        _documentPath = picked.path;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return _LeavePageShell(
      title: 'Upload Document',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeCard(
            child: Row(
              children: [
                _IconBox(
                  icon: Icons.description_rounded,
                  color: EmployeeColors.green,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Medical certificate is required for sick leave.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Upload Medical Certificate',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDocument,
            borderRadius: BorderRadius.circular(10),
            child: EmployeeCard(
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
              child: Column(
                children: [
                  _picking
                      ? const SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: textSecondary,
                        ),
                  const SizedBox(height: 10),
                  Text(
                    _documentName.isEmpty
                        ? 'Tap to upload certificate'
                        : _documentName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG or PNG',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.error!,
              style: const TextStyle(color: EmployeeColors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _documentPath.isEmpty
                  ? null
                  : () => widget.onContinue(_documentName, _documentPath),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewLeavePage extends StatefulWidget {
  final String leaveType;
  final List<Map<String, dynamic>> records;
  final DateTime? joiningDate;
  final DateTime fromDate;
  final DateTime toDate;
  final String session;
  final String reason;
  final String emergencyContact;
  final String documentName;
  final bool submitting;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _ReviewLeavePage({
    required this.leaveType,
    required this.records,
    required this.joiningDate,
    required this.fromDate,
    required this.toDate,
    required this.session,
    required this.reason,
    required this.emergencyContact,
    required this.documentName,
    required this.submitting,
    required this.error,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<_ReviewLeavePage> createState() => _ReviewLeavePageState();
}

class _ReviewLeavePageState extends State<_ReviewLeavePage> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final days = widget.toDate.difference(widget.fromDate).inDays + 1;
    final calculation = _calculateLeave(
      leaveType: widget.leaveType,
      requestedDays: days,
      records: widget.records,
      year: widget.fromDate.year,
      joiningDate: widget.joiningDate,
      asOf: widget.fromDate,
    );
    return _LeavePageShell(
      title: 'Review & Submit',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(current: 3),
          const SizedBox(height: 18),
          const Text(
            'Review Your Request',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          EmployeeCard(
            child: Column(
              children: [
                EmployeeInfoRow('Leave Type', widget.leaveType),
                EmployeeInfoRow('From Date', _displayDate(widget.fromDate)),
                EmployeeInfoRow('To Date', _displayDate(widget.toDate)),
                EmployeeInfoRow('Number of Days', _dayCountText(days)),
                EmployeeInfoRow('Paid Leave', _dayCountText(calculation.paidDays)),
                if (calculation.lopDays > 0)
                  EmployeeInfoRow('LOP', _dayCountText(calculation.lopDays)),
                EmployeeInfoRow('Session', widget.session),
                EmployeeInfoRow('Reason', widget.reason),
                if (widget.emergencyContact.isNotEmpty)
                  EmployeeInfoRow('Emergency Contact', widget.emergencyContact),
                if (widget.documentName.isNotEmpty)
                  EmployeeInfoRow('Document', widget.documentName),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (value) => setState(() => _confirmed = value ?? false),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I confirm that the above information is correct.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          if (widget.error != null)
            Text(
              widget.error!,
              style: const TextStyle(color: EmployeeColors.red, fontSize: 12),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _confirmed && !widget.submitting
                  ? widget.onSubmit
                  : null,
              child: widget.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveSubmittedPage extends StatelessWidget {
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final int days;
  final VoidCallback onViewLeaves;
  final VoidCallback onHome;

  const _LeaveSubmittedPage({
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.onViewLeaves,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return _LeavePageShell(
      title: 'Leave Submitted',
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: EmployeeColors.green, width: 3),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: EmployeeColors.green,
              size: 62,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Request Submitted!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Your $leaveType request has been submitted successfully.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          EmployeeCard(
            child: Column(
              children: [
                EmployeeInfoRow('From', _displayDate(fromDate)),
                EmployeeInfoRow('To', _displayDate(toDate)),
                EmployeeInfoRow('Days', '$days Days'),
                const EmployeeInfoRow('Status', 'Pending Approval'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onViewLeaves,
              child: const Text('View My Leaves'),
            ),
          ),
          TextButton(onPressed: onHome, child: const Text('Back to Home')),
        ],
      ),
    );
  }
}

class _MyLeavesPage extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  final bool loading;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;

  const _MyLeavesPage({
    required this.records,
    required this.loading,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  State<_MyLeavesPage> createState() => _MyLeavesPageState();
}

class _MyLeavesPageState extends State<_MyLeavesPage> {
  String _filter = 'All';
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  // Build a map: "yyyy-MM-dd" -> list of leave records that cover that day
  Map<String, List<Map<String, dynamic>>> get _leavesByDay {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in widget.records) {
      final from = _parseIsoDate('${r['from_date'] ?? ''}');
      final to = _parseIsoDate('${r['to_date'] ?? ''}');
      if (from == null || to == null) continue;
      for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
        final key = _isoDay(d);
        map.putIfAbsent(key, () => []).add(r);
      }
    }
    return map;
  }

  List<Map<String, dynamic>> _leavesForDay(DateTime day) {
    return _leavesByDay[_isoDay(day)] ?? [];
  }

  String _isoDay(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? widget.records
        : widget.records.where((r) {
            // overall_status has the raw value: "Pending", "Approved", "Rejected"
            // status has display values like "Pending TL", "Pending HR", "Approved"
            final overall = '${r['overall_status'] ?? ''}'.toLowerCase();
            final display = '${r['status'] ?? ''}'.toLowerCase();
            final f = _filter.toLowerCase();
            return overall == f || display.contains(f);
          }).toList();

    final selectedLeaves = _selectedDay != null ? _leavesForDay(_selectedDay!) : <Map<String, dynamic>>[];

    return _LeavePageShell(
      title: 'My Leaves',
      onBack: widget.onBack,
      action: IconButton(
        onPressed: widget.onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: Column(
        children: [
          // ── Filter chips ──────────────────────────────────
          Row(
            children: ['All', 'Pending', 'Approved', 'Rejected']
                .map((item) => Expanded(
                      child: _FilterChip(
                        label: item,
                        selected: _filter == item,
                        onTap: () => setState(() => _filter = item),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          // ── Calendar (All tab only) ───────────────────────
          if (_filter == 'All') ...[
            _LeaveCalendar(
              focusedMonth: _focusedMonth,
              selectedDay: _selectedDay,
              leavesByDay: _leavesByDay,
              onPrevMonth: _prevMonth,
              onNextMonth: _nextMonth,
              onDayTap: (day) => setState(() => _selectedDay = day),
            ),
            const SizedBox(height: 16),
            if (_selectedDay != null) ...[
              _DayDetailSection(
                day: _selectedDay!,
                leaves: selectedLeaves,
              ),
              const SizedBox(height: 16),
            ],
          ],
          // ── Leave list ────────────────────────────────────
          if (widget.loading)
            const Center(child: CircularProgressIndicator())
          else if (filtered.isEmpty)
            const _EmptyState(message: 'No leaves found')
          else
            ...filtered.map((r) => _LeaveRecordCard(r)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Custom inline calendar widget
// ════════════════════════════════════════════════════════════
class _LeaveCalendar extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<String, List<Map<String, dynamic>>> leavesByDay;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDayTap;

  const _LeaveCalendar({
    required this.focusedMonth,
    required this.selectedDay,
    required this.leavesByDay,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
  });

  static const _weekLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _isoDay(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _dotColor(List<Map<String, dynamic>> leaves) {
    if (leaves.isEmpty) return Colors.transparent;
    final status = '${leaves.first['status'] ?? ''}'.toLowerCase();
    if (status.contains('approved')) return const Color(0xFF00D46A);
    if (status.contains('reject')) return const Color(0xFFFF3B3B);
    return const Color(0xFFFF9F1C);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = isDark ? const Color(0xFF1A2035) : Colors.white;
    final border = ThemeConfig.getCardBorder(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final today = DateTime.now();

    // Days in month + leading offset
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);
    final leadingBlanks = firstDay.weekday % 7; // Sun=0

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: Icon(Icons.chevron_left_rounded, color: textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Expanded(
                child: Text(
                  '${_months[focusedMonth.month - 1]} ${focusedMonth.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: Icon(Icons.chevron_right_rounded, color: textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Week day headers
          Row(
            children: _weekLabels
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.85,
            ),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = DateTime(focusedMonth.year, focusedMonth.month, index - leadingBlanks + 1);
              final key = _isoDay(day);
              final dayLeaves = leavesByDay[key] ?? [];
              final isSelected = selectedDay != null &&
                  selectedDay!.year == day.year &&
                  selectedDay!.month == day.month &&
                  selectedDay!.day == day.day;
              final isToday = today.year == day.year &&
                  today.month == day.month &&
                  today.day == day.day;
              final hasLeave = dayLeaves.isNotEmpty;
              final dotColor = _dotColor(dayLeaves);

              return GestureDetector(
                onTap: () => onDayTap(day),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : (isToday ? const Color(0xFF4FACFE).withAlpha(30) : null),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF4FACFE), width: 1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF4FACFE)
                                  : textPrimary,
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasLeave
                              ? (isSelected ? Colors.white : dotColor)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CalLegend(color: const Color(0xFF00D46A), label: 'Approved'),
              const SizedBox(width: 14),
              _CalLegend(color: const Color(0xFFFF9F1C), label: 'Pending'),
              const SizedBox(width: 14),
              _CalLegend(color: const Color(0xFFFF3B3B), label: 'Rejected'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _CalLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: ThemeConfig.getTextSecondary(context),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Day detail section below the calendar
// ════════════════════════════════════════════════════════════
class _DayDetailSection extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> leaves;

  const _DayDetailSection({required this.day, required this.leaves});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = isDark ? const Color(0xFF1A2035) : Colors.white;
    final border = ThemeConfig.getCardBorder(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final label =
        '${day.day.toString().padLeft(2, '0')} ${_months[day.month - 1]} ${day.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, size: 16, color: Color(0xFF4FACFE)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (leaves.isEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF00D46A)),
                const SizedBox(width: 8),
                Text(
                  'No leave on this day',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            ...leaves.map((r) {
              final status = '${r['status'] ?? ''}';
              final statusColor = employeeStatusColor(status);
              final type = '${r['leave_type'] ?? r['type'] ?? 'Leave'}';
              final from = '${r['from_date'] ?? ''}';
              final to = '${r['to_date'] ?? ''}';
              final days = '${r['days'] ?? 1}';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.beach_access_rounded, color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$from → $to  •  $days Day${days == '1' ? '' : 's'}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LeavePageShell extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? action;

  const _LeavePageShell({
    required this.title,
    required this.child,
    this.onBack,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Expanded(
                child: Text(
                  title,
                  textAlign: onBack == null ? TextAlign.left : TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              action ?? SizedBox(width: onBack == null ? 0 : 48),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int current;

  const _StepHeader({required this.current});

  @override
  Widget build(BuildContext context) {
    final dividerColor = ThemeConfig.isDark(context)
        ? EmployeeColors.blue.withAlpha(85)
        : EmployeeColors.blue.withAlpha(55);
    return Row(
      children: [
        _StepDot(number: 1, label: 'Type', active: current >= 1),
        Expanded(child: Divider(color: dividerColor)),
        _StepDot(number: 2, label: 'Details', active: current >= 2),
        Expanded(child: Divider(color: dividerColor)),
        _StepDot(number: 3, label: 'Review', active: current >= 3),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool active;

  const _StepDot({
    required this.number,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final activeText = ThemeConfig.isDark(context)
        ? Colors.white
        : const Color(0xFF1F3654);
    final inactiveBg = ThemeConfig.isDark(context)
        ? Colors.white.withAlpha(24)
        : const Color(0xFFEAF7FF);
    final inactiveText = ThemeConfig.getTextSecondary(context);
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? null : inactiveBg,
            gradient: active
                ? const LinearGradient(
                    colors: [
                      Color(0xFF10C7F4),
                      Color(0xFF3EDC81),
                      Color(0xFF1C8BFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: active ? Colors.white : EmployeeColors.blue,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? activeText : inactiveText,
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_rounded),
        ),
        child: Text(_displayDate(date)),
      ),
    );
  }
}

class _LeaveRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _LeaveRecordCard(this.record);

  @override
  Widget build(BuildContext context) {
    final status = '${record['status'] ?? ''}';
    return EmployeeListTile(
      icon: Icons.beach_access_rounded,
      title: '${record['leave_type'] ?? record['type'] ?? 'Leave'}',
      subtitle:
          '${record['from_date'] ?? ''} to ${record['to_date'] ?? ''} - ${record['days'] ?? 0} Days',
      trailing: status,
      color: employeeStatusColor(status),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Hero card – gradient "Total Available" banner
// ════════════════════════════════════════════════════════════
class _LeaveHeroCard extends StatelessWidget {
  final _LeaveBalanceOverview overview;
  final bool loading;

  const _LeaveHeroCard({required this.overview, required this.loading});

  @override
  Widget build(BuildContext context) {
    final progress = overview.totalEntitlement <= 0
        ? 0.0
        : (overview.totalAvailable / overview.totalEntitlement)
              .clamp(0.0, 1.0)
              .toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1060), Color(0xFF3B2494), Color(0xFF2D5FD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B2494).withAlpha(100),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL AVAILABLE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatOneDecimal(overview.totalAvailable),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text(
                                'Days',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withAlpha(18),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white54,
                          size: 42,
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00D46A),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D46A).withAlpha(100),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: loading
                    ? LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: Colors.white.withAlpha(30),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF4FACFE)),
                      )
                    : LinearProgressIndicator(
                        minHeight: 8,
                        value: progress,
                        backgroundColor: Colors.white.withAlpha(30),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4FACFE)),
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                'Out of ${_formatOneDecimal(overview.totalEntitlement)} Days (Annual Entitlement)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  4-metric stat card row
// ════════════════════════════════════════════════════════════
class _LeaveMetricRow extends StatelessWidget {
  final _LeaveBalanceOverview overview;

  const _LeaveMetricRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.arrow_upward_rounded,
            label: 'Accrued\nThis Year',
            value: _formatOneDecimal(overview.accruedThisYear),
            unit: 'Days',
            iconColor: const Color(0xFF00D46A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.arrow_downward_rounded,
            label: 'Used\nThis Year',
            value: _formatOneDecimal(overview.usedThisYear),
            unit: 'Days',
            iconColor: const Color(0xFFFF9F1C),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.access_time_rounded,
            label: 'Pending\nApproval',
            value: _formatOneDecimal(overview.pendingApproval),
            unit: overview.pendingApproval == 1 ? 'Day' : 'Days',
            iconColor: const Color(0xFF4FACFE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.sync_rounded,
            label: 'Carry\nForward',
            value: _formatOneDecimal(overview.carryForward),
            unit: 'Days',
            iconColor: const Color(0xFF8B5CFF),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = isDark ? const Color(0xFF1A2035) : Colors.white;
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ThemeConfig.getCardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              color: textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Leave Type Summary card
// ════════════════════════════════════════════════════════════
class _LeaveTypeSummaryCard extends StatelessWidget {
  final _LeaveBalanceOverview overview;

  const _LeaveTypeSummaryCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = isDark ? const Color(0xFF1A2035) : Colors.white;
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final border = ThemeConfig.getCardBorder(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Leave Type Summary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Total Leaves: ${_formatOneDecimal(overview.totalEntitlement)} Days',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF4FACFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              _ColHeader('Entitlement', textSecondary, width: 58),
              _ColHeader('Used', textSecondary, width: 46),
              _ColHeader('Available', textSecondary, width: 58),
            ],
          ),
          const SizedBox(height: 8),
          ...overview.types.map(
            (item) => _LeaveTypeSummaryRow(item: item),
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  final Color color;
  final double width;

  const _ColHeader(this.label, this.color, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Accrual footer row (2 cards side by side)
// ════════════════════════════════════════════════════════════
class _AccrualFooterRow extends StatelessWidget {
  final _LeaveBalanceOverview overview;

  const _AccrualFooterRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccrualCard(
            icon: Icons.calendar_today_rounded,
            title: 'Next Accrual',
            value: '+${_formatOneDecimal(overview.nextAccrualDays)} Days on\n${_displayShortDate(overview.nextAccrualDate)}',
            valueColor: const Color(0xFF148F62),
            backgroundColor: const Color(0xFFEAF6FF),
            accentColor: const Color(0xFF3A8DDE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccrualCard(
            icon: Icons.sync_rounded,
            title: 'Accrual Frequency',
            value: overview.accrualFrequency,
            valueColor: const Color(0xFF6D43D9),
            backgroundColor: const Color(0xFFF1EAFF),
            accentColor: const Color(0xFF8B5CFF),
          ),
        ),
      ],
    );
  }
}

class _AccrualCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;
  final Color backgroundColor;
  final Color accentColor;

  const _AccrualCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor.withAlpha(210),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Action buttons (Apply / My Leaves)
// ════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withAlpha(90)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveTypeSummaryRow extends StatelessWidget {
  final _LeaveTypeBalance item;

  const _LeaveTypeSummaryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final progress = item.entitlement <= 0
        ? 0.0
        : (item.available / item.entitlement).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(42),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: progress,
                          backgroundColor: textSecondary.withAlpha(35),
                          valueColor: AlwaysStoppedAnimation(item.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SummaryValue(_formatOneDecimal(item.entitlement), textPrimary, width: 58),
          _SummaryValue(_formatOneDecimal(item.used), EmployeeColors.gold, width: 46),
          _SummaryValue(_formatOneDecimal(item.available), EmployeeColors.green, width: 58),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String value;
  final Color color;
  final double width;

  const _SummaryValue(this.value, this.color, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _FooterInfo({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = label == 'Apply Leave'
        ? 'Request new leave'
        : label == 'My Leaves'
        ? 'View leave history'
        : '';
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: EmployeeCard(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        child: Row(
          children: [
            Icon(icon, color: EmployeeColors.blue, size: 28),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveBalanceTile extends StatelessWidget {
  final String label;
  final String title;
  final _AccruedLeaveBalance balance;
  final Color color;
  final IconData icon;

  const _LeaveBalanceTile({
    required this.label,
    required this.title,
    required this.balance,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatLeaveDays(balance.availableDays),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            'Available',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Accrued ${_formatLeaveDays(balance.accruedDays)} | Pending ${_formatLeaveDays(balance.pendingDays)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textSecondary, fontSize: 10, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeShadow = ThemeConfig.isDark(context)
        ? Colors.black.withAlpha(30)
        : EmployeeColors.blue.withAlpha(35);
    final inactiveText = ThemeConfig.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? null : Colors.transparent,
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF10C7F4),
                      Color(0xFF3EDC81),
                      Color(0xFF1C8BFF),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : inactiveText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return EmployeeCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveTypeOption {
  final String title;
  final String subtitle;
  final IconData icon;

  const _LeaveTypeOption(this.title, this.subtitle, this.icon);
}

class _LeaveBalanceOverview {
  final String fiscalYear;
  final double totalEntitlement;
  final double totalAvailable;
  final double accruedThisYear;
  final double usedThisYear;
  final double pendingApproval;
  final double carryForward;
  final double nextAccrualDays;
  final DateTime nextAccrualDate;
  final String accrualFrequency;
  final List<_LeaveTypeBalance> types;

  const _LeaveBalanceOverview({
    required this.fiscalYear,
    required this.totalEntitlement,
    required this.totalAvailable,
    required this.accruedThisYear,
    required this.usedThisYear,
    required this.pendingApproval,
    required this.carryForward,
    required this.nextAccrualDays,
    required this.nextAccrualDate,
    required this.accrualFrequency,
    required this.types,
  });

  factory _LeaveBalanceOverview.fromSource({
    required Map<String, dynamic> source,
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> records,
  }) {
    final rawTypes = source['types'];
    if (source.isNotEmpty && rawTypes is List) {
      final types = rawTypes
          .whereType<Map>()
          .map((item) => _LeaveTypeBalance.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      return _LeaveBalanceOverview(
        fiscalYear: '${source['fiscal_year'] ?? _currentFiscalYear()}',
        totalEntitlement: _doubleFrom(source['total_entitlement']),
        totalAvailable: _doubleFrom(source['total_available']),
        accruedThisYear: _doubleFrom(source['accrued_this_year']),
        usedThisYear: _doubleFrom(source['used_this_year']),
        pendingApproval: _doubleFrom(source['pending_approval']),
        carryForward: _doubleFrom(source['carry_forward']),
        nextAccrualDays: _doubleFrom(source['next_accrual_days'], fallback: 1.5),
        nextAccrualDate:
            _parseIsoDate('${source['next_accrual_date'] ?? ''}') ??
            _nextAccrualDate(DateTime.now()),
        accrualFrequency:
            '${source['accrual_frequency'] ?? 'Monthly (1.5 Days / Month)'}',
        types: types.isEmpty ? _fallbackLeaveTypes(profile, records) : types,
      );
    }

    final types = _fallbackLeaveTypes(profile, records);
    final totalEntitlement = types.fold<double>(
      0,
      (sum, item) => sum + item.entitlement,
    );
    final accrued = types.fold<double>(0, (sum, item) => sum + item.accrued);
    final used = types.fold<double>(0, (sum, item) => sum + item.used);
    final pending = types.fold<double>(0, (sum, item) => sum + item.pending);
    final available = types.fold<double>(0, (sum, item) => sum + item.available);
    return _LeaveBalanceOverview(
      fiscalYear: _currentFiscalYear(),
      totalEntitlement: totalEntitlement,
      totalAvailable: available,
      accruedThisYear: accrued,
      usedThisYear: used,
      pendingApproval: pending,
      carryForward: 0,
      nextAccrualDays: 1.5,
      nextAccrualDate: _nextAccrualDate(DateTime.now()),
      accrualFrequency: 'Monthly (1.5 Days / Month)',
      types: types,
    );
  }
}

class _LeaveTypeBalance {
  final String title;
  final double entitlement;
  final double accrued;
  final double used;
  final double pending;
  final double available;
  final IconData icon;
  final Color color;

  const _LeaveTypeBalance({
    required this.title,
    required this.entitlement,
    required this.accrued,
    required this.used,
    required this.pending,
    required this.available,
    required this.icon,
    required this.color,
  });

  factory _LeaveTypeBalance.fromMap(Map<String, dynamic> map) {
    final title = '${map['type'] ?? map['title'] ?? 'Leave'}';
    return _LeaveTypeBalance(
      title: title,
      entitlement: _doubleFrom(map['entitlement']),
      accrued: _doubleFrom(map['accrued']),
      used: _doubleFrom(map['used']),
      pending: _doubleFrom(map['pending']),
      available: _doubleFrom(map['available']),
      icon: _leaveTypeIcon(title, '${map['icon'] ?? ''}'),
      color: _leaveTypeColor(title),
    );
  }
}

class _LeaveCalculation {
  final int requestedDays;
  final int usedDays;
  final int? yearlyAllowance;
  final int paidDays;
  final int lopDays;
  final String policyNote;

  const _LeaveCalculation({
    required this.requestedDays,
    required this.usedDays,
    required this.yearlyAllowance,
    required this.paidDays,
    required this.lopDays,
    required this.policyNote,
  });

  int? get availableDays {
    final allowance = yearlyAllowance;
    if (allowance == null) return null;
    return (allowance - usedDays).clamp(0, allowance).toInt();
  }
}

_LeaveCalculation _calculateLeave({
  required String leaveType,
  required int requestedDays,
  required List<Map<String, dynamic>> records,
  required int year,
  DateTime? joiningDate,
  DateTime? asOf,
}) {
  if (leaveType == 'LOP') {
    return _LeaveCalculation(
      requestedDays: requestedDays,
      usedDays: 0,
      yearlyAllowance: 0,
      paidDays: 0,
      lopDays: requestedDays,
      policyNote: 'Loss of Pay will deduct salary proportionately.',
    );
  }
  final allowance = _yearlyLeaveAllowance(leaveType);
  final balance = allowance == null
      ? null
      : _calculateAccruedBalance(
          leaveType: leaveType,
          records: records,
          joiningDate: joiningDate,
          asOf: asOf ?? DateTime.now(),
        );
  final usedDays = balance == null ? 0 : balance.usedDays.round();
  final available = balance == null
      ? requestedDays
      : balance.availableDays
            .floor()
            .clamp(0, balance.annualAllowance.floor())
            .toInt();
  final paidDays = allowance == null
      ? requestedDays
      : requestedDays.clamp(0, available).toInt();
  final lopDays = allowance == null
      ? 0
      : (requestedDays - paidDays).clamp(0, requestedDays).toInt();
  return _LeaveCalculation(
    requestedDays: requestedDays,
    usedDays: usedDays,
    yearlyAllowance: allowance,
    paidDays: paidDays,
    lopDays: lopDays,
    policyNote: _leavePolicyNote(leaveType, allowance, lopDays),
  );
}

int? _yearlyLeaveAllowance(String leaveType) {
  switch (_normalizeLeaveType(leaveType)) {
    case 'annualleave':
      return 12;
    case 'sickleave':
      return 8;
    case 'casualleave':
      return 4;
    case 'compoff':
      return 0;
  }
  return null;
}

String _leavePolicyNote(String leaveType, int? allowance, int lopDays) {
  if (leaveType == 'Compensatory Leave' || leaveType == 'Comp Off') {
    return 'Compensatory leave is for holidays/weekends and must be used within 30 days.';
  }
  if (allowance == null) {
    return 'This leave type follows company or statutory approval rules.';
  }
  if (lopDays > 0) {
    return 'Leave balance is exhausted. Extra days will be treated as Loss of Pay.';
  }
  if (leaveType == 'Annual Leave') {
    return 'Annual Leave has 12 days per annum and follows monthly accrual.';
  }
  return '$leaveType has $allowance days per annum and lapses at the end of the calendar year.';
}

List<_LeaveTypeBalance> _fallbackLeaveTypes(
  Map<String, dynamic> profile,
  List<Map<String, dynamic>> records,
) {
  final joiningDate = _profileJoiningDate(profile);
  final now = DateTime.now();
  return [
    _fallbackTypeBalance('Annual Leave', records, joiningDate, now),
    _fallbackTypeBalance('Sick Leave', records, joiningDate, now),
    _fallbackTypeBalance('Casual Leave', records, joiningDate, now),
    _fallbackTypeBalance('Comp-Off', records, joiningDate, now),
  ];
}

_LeaveTypeBalance _fallbackTypeBalance(
  String title,
  List<Map<String, dynamic>> records,
  DateTime? joiningDate,
  DateTime asOf,
) {
  final balance = _calculateAccruedBalance(
    leaveType: title,
    records: records,
    joiningDate: joiningDate,
    asOf: asOf,
  );
  return _LeaveTypeBalance(
    title: title,
    entitlement: balance.annualAllowance,
    accrued: balance.accruedDays,
    used: balance.approvedDays,
    pending: balance.pendingDays,
    available: balance.availableDays,
    icon: _leaveTypeIcon(title, ''),
    color: _leaveTypeColor(title),
  );
}

double _doubleFrom(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

String _currentFiscalYear() {
  final now = DateTime.now();
  return 'FY ${now.year}-${(now.year + 1).toString().substring(2)}';
}

DateTime _nextAccrualDate(DateTime date) {
  final month = date.month == 12 ? 1 : date.month + 1;
  final year = date.month == 12 ? date.year + 1 : date.year;
  return DateTime(year, month, 1);
}

IconData _leaveTypeIcon(String title, String backendIcon) {
  final key = _normalizeLeaveType(backendIcon.isEmpty ? title : backendIcon);
  if (key.contains('palm') || key == 'annualleave') return Icons.park_rounded;
  if (key.contains('health') || key == 'sickleave') {
    return Icons.health_and_safety_rounded;
  }
  if (key.contains('umbrella') || key == 'casualleave') return Icons.beach_access_rounded;
  if (key.contains('event') || key == 'compoff') return Icons.event_available_rounded;
  return Icons.beach_access_rounded;
}

Color _leaveTypeColor(String title) {
  switch (_normalizeLeaveType(title)) {
    case 'annualleave':
    case 'sickleave':
      return EmployeeColors.green;
    case 'casualleave':
      return EmployeeColors.blue;
    case 'compoff':
      return EmployeeColors.purple;
  }
  return EmployeeColors.blue;
}

class _AccruedLeaveBalance {
  final String leaveType;
  final double annualAllowance;
  final double accruedDays;
  final double approvedDays;
  final double pendingDays;

  const _AccruedLeaveBalance({
    required this.leaveType,
    required this.annualAllowance,
    required this.accruedDays,
    required this.approvedDays,
    required this.pendingDays,
  });

  double get usedDays => approvedDays;

  double get availableDays {
    final available = annualAllowance - approvedDays;
    if (available < 0) return 0;
    if (available > annualAllowance) return annualAllowance;
    return available;
  }
}

_AccruedLeaveBalance _calculateAccruedBalance({
  required String leaveType,
  required List<Map<String, dynamic>> records,
  required DateTime? joiningDate,
  required DateTime asOf,
}) {
  final allowance = (_yearlyLeaveAllowance(leaveType) ?? 0).toDouble();
  final accrualStart = _accrualStartDate(joiningDate, asOf);
  final activeMonths = _activeAccrualMonths(accrualStart, asOf);
  final accruedDays = ((allowance / 12) * activeMonths)
      .clamp(0, allowance)
      .toDouble();
  double approvedDays = 0;
  double pendingDays = 0;

  for (final record in records) {
    if (!_countsTowardBalance(record, leaveType, asOf.year)) continue;
    final days = _recordDays(record).toDouble();
    if (_isPendingLeave(record)) {
      pendingDays += days;
    } else {
      approvedDays += days;
    }
  }

  return _AccruedLeaveBalance(
    leaveType: leaveType,
    annualAllowance: allowance,
    accruedDays: accruedDays,
    approvedDays: approvedDays,
    pendingDays: pendingDays,
  );
}

DateTime _accrualStartDate(DateTime? joiningDate, DateTime asOf) {
  final yearStart = DateTime(asOf.year, 1, 1);
  if (joiningDate == null || joiningDate.isBefore(yearStart)) {
    return yearStart;
  }
  return DateTime(joiningDate.year, joiningDate.month, joiningDate.day);
}

int _activeAccrualMonths(DateTime start, DateTime asOf) {
  if (start.isAfter(asOf)) return 0;
  final months = (asOf.year - start.year) * 12 + asOf.month - start.month + 1;
  return months.clamp(0, 12).toInt();
}

bool _countsTowardBalance(
  Map<String, dynamic> record,
  String leaveType,
  int year,
) {
  final type = '${record['leave_type'] ?? record['type'] ?? ''}';
  if (_normalizeLeaveType(type) != _normalizeLeaveType(leaveType)) return false;
  final status = '${record['overall_status'] ?? record['status'] ?? ''}'.toLowerCase();
  if (status.contains('reject')) return false;
  final fromDate = _parseIsoDate('${record['from_date'] ?? ''}');
  return fromDate != null && fromDate.year == year;
}

bool _isPendingLeave(Map<String, dynamic> record) {
  final status =
      '${record['overall_status'] ?? record['status'] ?? ''}'.toLowerCase();
  final tlStatus = '${record['tl_status'] ?? ''}'.toLowerCase();
  final hrStatus = '${record['hr_status'] ?? ''}'.toLowerCase();
  return status.contains('pending') ||
      tlStatus.contains('pending') ||
      hrStatus.contains('pending');
}

String _normalizeLeaveType(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  if (normalized == 'al' || normalized.contains('annual') || normalized.contains('earned')) {
    return 'annualleave';
  }
  if (normalized == 'cl' || normalized.contains('casual')) return 'casualleave';
  if (normalized == 'sl' || normalized.contains('sick')) return 'sickleave';
  if (normalized.contains('comp')) return 'compoff';
  return normalized;
}

int _recordDays(Map<String, dynamic> record) {
  final value = record['days'];
  if (value is int) return value;
  return int.tryParse('$value'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

DateTime? _parseIsoDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

DateTime? _profileJoiningDate(Map<String, dynamic> profile) {
  final raw = '${profile['date_of_joining'] ?? profile['joining_date'] ?? ''}';
  final isoDate = _parseIsoDate(raw);
  if (isoDate != null) return isoDate;

  final parts = raw.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = _monthNumber(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

int? _monthNumber(String value) {
  const months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };
  return months[value.toLowerCase().substring(0, value.length < 3 ? value.length : 3)];
}

String _formatLeaveDays(double days) {
  final rounded = (days * 100).round() / 100;
  if (rounded == rounded.roundToDouble()) return '${rounded.toInt()} Days';
  return '${rounded.toStringAsFixed(2)} Days';
}

String _formatOneDecimal(double value) {
  return value.toStringAsFixed(1);
}

String _dayCountText(int days) {
  return '$days ${days == 1 ? 'Day' : 'Days'}';
}

String _displayDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _displayShortDate(DateTime date) {
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
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
