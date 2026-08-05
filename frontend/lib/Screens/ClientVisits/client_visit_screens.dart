import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import '../Employee/employee_shared.dart';
import 'client_visit_models.dart';
import 'client_visit_service.dart';
import 'client_visit_flow_screens.dart';
import 'client_visit_theme.dart';

const _statuses = [
  'all',
  'draft',
  'pending',
  'approved',
  'travelling',
  'in_progress',
  'completed',
  'rejected',
];

class ClientVisitDashboardScreen extends StatefulWidget {
  final String userId;
  final bool reviewerMode;
  final bool readOnlyMode;
  final bool allowCreate;
  final bool assignedApprovalsOnly;
  final bool allowVerification;
  final String requesterRole;
  final int? initialVisitId;
  const ClientVisitDashboardScreen({
    super.key,
    required this.userId,
    this.reviewerMode = false,
    this.readOnlyMode = false,
    this.allowCreate = true,
    this.assignedApprovalsOnly = false,
    this.allowVerification = true,
    this.requesterRole = '',
    this.initialVisitId,
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
  bool _initialVisitOpened = false;

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
      if (!mounted) return;
      setState(() => _result = value);
      final initialVisitId = widget.initialVisitId;
      if (!_initialVisitOpened && initialVisitId != null) {
        ClientVisit? initialVisit;
        for (final visit in value.visits) {
          if (visit.id == initialVisitId) {
            initialVisit = visit;
            break;
          }
        }
        _initialVisitOpened = true;
        if (initialVisit != null) {
          final visit = initialVisit;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openVisit(visit);
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _create() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientVisitCreateScreen(
          userId: widget.userId,
          service: _service,
          requesterRole: widget.requesterRole,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _openStatusList(String title, Set<String> statuses) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ClientVisitStatusListScreen(
          title: title,
          userId: widget.userId,
          statuses: statuses,
          onOpenVisit: _openVisit,
        ),
      ),
    );
    await _load();
  }

  int _currentFlowStep(ClientVisit visit) => switch (visit.status) {
    'pending' || 'rejected' || 'draft' => 3,
    'approved' => 4,
    'travelling' => visit.reachedClientAt == null ? 6 : 7,
    'in_progress' => 8,
    'completed' => 12,
    _ => 3,
  };

  Widget _monitoringScreen(ClientVisit visit, {bool canVerify = false}) {
    if (visit.status == 'completed') {
      return ClientVisitSummaryScreen(
        userId: widget.userId,
        visitId: visit.id,
        service: _service,
        reviewerMode: canVerify,
      );
    }
    return ClientVisitReadOnlyFlowScreen(
      userId: widget.userId,
      visitId: visit.id,
      step: _currentFlowStep(visit),
      service: _service,
    );
  }

  Widget _employeeFlowScreen(ClientVisit visit) => switch (visit.status) {
    'approved' => ClientVisitApprovedScreen(
      userId: widget.userId,
      visitId: visit.id,
      service: _service,
    ),
    'travelling' =>
      visit.reachedClientAt == null
          ? ClientVisitTravelProgressScreen(
              userId: widget.userId,
              visitId: visit.id,
              service: _service,
            )
          : ClientVisitCheckInScreen(
              userId: widget.userId,
              visitId: visit.id,
              service: _service,
            ),
    'in_progress' => ClientVisitActiveScreen(
      userId: widget.userId,
      visitId: visit.id,
      service: _service,
    ),
    'completed' => ClientVisitSummaryScreen(
      userId: widget.userId,
      visitId: visit.id,
      service: _service,
    ),
    _ => ClientVisitApprovedScreen(
      userId: widget.userId,
      visitId: visit.id,
      service: _service,
    ),
  };

  Future<void> _openVisit(ClientVisit visit) async {
    late final Widget screen;
    if (widget.readOnlyMode) {
      screen = _monitoringScreen(visit);
    } else if (widget.reviewerMode && visit.employeeUserId == widget.userId) {
      screen = _employeeFlowScreen(visit);
    } else if (widget.reviewerMode) {
      final canReview =
          !widget.assignedApprovalsOnly || visit.managerUserId == widget.userId;
      screen = visit.status == 'pending' && canReview
          ? ClientVisitManagerApprovalScreen(
              userId: widget.userId,
              visitId: visit.id,
              service: _service,
            )
          : _monitoringScreen(
              visit,
              canVerify: widget.allowVerification && canReview,
            );
    } else {
      screen = _employeeFlowScreen(visit);
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ClientVisitTheme(
      child: RefreshIndicator(
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
                        'VISIT DASHBOARD',
                        style: TextStyle(
                          color: ThemeConfig.getTextPrimary(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (result != null)
              _Summary(
                summary: result.summary,
                onInProgress: () => _openStatusList(
                  'In Progress Visits',
                  const {'travelling', 'in_progress'},
                ),
                onPendingCheckIn: () =>
                    _openStatusList('Pending Check-In', const {'approved'}),
                onUpcoming: () =>
                    _openStatusList('Upcoming Visits', const {'approved'}),
                onPendingApproval: () =>
                    _openStatusList('Pending Approval', const {'pending'}),
                onHistory: () => _openStatusList('Visit History', const {
                  'completed',
                  'rejected',
                }),
              ),
            if (!widget.readOnlyMode && widget.allowCreate) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('+ New Visit'),
                ),
              ),
            ],
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
                onRetry: widget.readOnlyMode || !widget.allowCreate
                    ? _load
                    : _create,
              )
            else
              ...result.visits.map(
                (visit) =>
                    _VisitCard(visit: visit, onTap: () => _openVisit(visit)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClientVisitStatusListScreen extends StatefulWidget {
  final String title;
  final String userId;
  final Set<String> statuses;
  final Future<void> Function(ClientVisit visit) onOpenVisit;

  const _ClientVisitStatusListScreen({
    required this.title,
    required this.userId,
    required this.statuses,
    required this.onOpenVisit,
  });

  @override
  State<_ClientVisitStatusListScreen> createState() =>
      _ClientVisitStatusListScreenState();
}

class _ClientVisitStatusListScreenState
    extends State<_ClientVisitStatusListScreen> {
  final _service = ClientVisitService();
  List<ClientVisit>? _visits;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await _service.fetchVisits(widget.userId);
      if (!mounted) return;
      setState(() {
        _visits = result.visits
            .where((visit) => widget.statuses.contains(visit.status))
            .toList();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ClientVisitTheme(
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              _Message(
                icon: Icons.cloud_off_rounded,
                text: _error!,
                onRetry: _load,
              )
            else if (_visits == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_visits!.isEmpty)
              _Message(
                icon: Icons.event_available_outlined,
                text: 'No ${widget.title.toLowerCase()} found.',
                onRetry: _load,
              )
            else
              ..._visits!.map(
                (visit) => _VisitCard(
                  visit: visit,
                  onTap: () async {
                    await widget.onOpenVisit(visit);
                    await _load();
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class ClientVisitModuleScreen extends StatelessWidget {
  final String userId;
  final String roleLabel;
  final String requesterRole;
  final bool reviewerMode;
  final bool readOnlyMode;
  final bool allowCreate;
  final bool assignedApprovalsOnly;
  final bool allowVerification;
  final int? initialVisitId;

  const ClientVisitModuleScreen({
    super.key,
    required this.userId,
    required this.roleLabel,
    this.requesterRole = '',
    this.reviewerMode = false,
    this.readOnlyMode = false,
    this.allowCreate = true,
    this.assignedApprovalsOnly = false,
    this.allowVerification = true,
    this.initialVisitId,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Client Visits'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Text(
                roleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ),
      ],
    ),
    body: ClientVisitDashboardScreen(
      userId: userId,
      reviewerMode: reviewerMode,
      readOnlyMode: readOnlyMode,
      allowCreate: allowCreate,
      assignedApprovalsOnly: assignedApprovalsOnly,
      allowVerification: allowVerification,
      requesterRole: requesterRole,
      initialVisitId: initialVisitId,
    ),
  );
}

class ClientVisitCreateScreen extends StatefulWidget {
  final String userId;
  final ClientVisitService service;
  final String requesterRole;
  const ClientVisitCreateScreen({
    super.key,
    required this.userId,
    required this.service,
    this.requesterRole = '',
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
  int _durationMinutes = 60;
  List<Map<String, dynamic>> _visitApprovers = const [];
  String? _selectedManagerId;
  String? _tlLoadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadReportingTls();
  }

  Future<void> _loadReportingTls() async {
    setState(() => _tlLoadError = null);
    try {
      final values = await widget.service.fetchVisitApprovers(
        widget.userId,
        requiresRoleAwareApprovers:
            widget.requesterRole == 'tl' || widget.requesterRole == 'hr',
      );
      if (!mounted) return;
      setState(() {
        _visitApprovers = values;
        _selectedManagerId = values.length == 1
            ? '${values.first['employee_id']}'
            : null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _visitApprovers = const [];
          _tlLoadError = '$error'.replaceFirst('Exception: ', '');
        });
      }
    }
  }

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

  String? _mobileNumber(String? value) {
    final mobile = (value ?? '').trim();
    if (mobile.isEmpty) return 'Required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

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
        'duration_minutes': _durationMinutes,
        'travel_mode': _travelMode,
        'purpose': _purpose.text.trim(),
        'notes': _notes.text.trim(),
        'manager_user_id': _selectedManagerId ?? _manager.text.trim(),
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
  Widget build(BuildContext context) => ClientVisitTheme(
    child: Scaffold(
      appBar: AppBar(title: const Text('Create Visit Request')),
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
                  decoration: const InputDecoration(
                    labelText: 'Contact person',
                  ),
                ),
                TextFormField(
                  controller: _phone,
                  validator: _mobileNumber,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    hintText: '9876543210',
                    counterText: '',
                  ),
                ),
                TextFormField(
                  controller: _address,
                  validator: _required,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Client address',
                  ),
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
                DropdownButtonFormField<int>(
                  initialValue: _durationMinutes,
                  decoration: const InputDecoration(labelText: 'Duration'),
                  items: const [30, 60, 120, 240, 480]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            minutes < 60
                                ? '$minutes minutes'
                                : '${minutes ~/ 60} hour${minutes == 60 ? '' : 's'}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _durationMinutes = value!),
                ),
                TextFormField(
                  controller: _purpose,
                  validator: _required,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                ),
                if (_visitApprovers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedManagerId,
                    validator: _required,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '${_approverRoleLabel()} approver',
                    ),
                    items: _visitApprovers
                        .map(
                          (tl) => DropdownMenuItem<String>(
                            value: '${tl['employee_id']}',
                            child: Text(
                              '${tl['label'] ?? 'Approver'} · ${tl['role_label'] ?? tl['role'] ?? ''} (${tl['employee_id']})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedManagerId = value),
                  )
                else
                  TextFormField(
                    controller: _manager,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${_approverRoleLabel()} approver user ID',
                      hintText: _approverHint(),
                      helperText: _tlLoadError == null
                          ? 'Loading ${_approverRoleLabel()} approvers…'
                          : '${_approverRoleLabel()} list unavailable. Enter an approver user ID.',
                      suffixIcon: _tlLoadError == null
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip:
                                  'Reload ${_approverRoleLabel()} approvers',
                              onPressed: _loadReportingTls,
                              icon: const Icon(Icons.refresh),
                            ),
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
    ),
  );

  String _approverRoleLabel() => switch (widget.requesterRole) {
    'tl' => 'HR',
    'hr' => 'CEO',
    _ => 'TL / HR',
  };

  String _approverHint() => switch (widget.requesterRole) {
    'tl' => 'Example: BBHR0001',
    'hr' => 'Example: BBCEO0001',
    _ => 'Example: BBTL0001 or BBHR0001',
  };
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

  Future<void> _startTravel() async {
    final odometer = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Office check-out'),
        content: TextField(
          controller: odometer,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Odometer (optional)',
            suffixText: 'km',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Take selfie'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await _run(() async {
      final selfie = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
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
        'start-travel',
        {
          ...await _position(),
          if (odometer.text.trim().isNotEmpty) 'odometer': odometer.text.trim(),
        },
      );
    });
  }

  Future<void> _reachedClient() async {
    await _run(() async {
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'reached-client',
        await _position(),
      );
    });
  }

  Future<void> _updateActiveVisit() async {
    final visit = _visit!;
    final attendee = TextEditingController();
    final notes = TextEditingController(text: visit.notes);
    final checklist = visit.checklist.isEmpty
        ? <Map<String, dynamic>>[
            {'label': 'Discuss visit purpose', 'done': false},
            {'label': 'Capture client requirements', 'done': false},
            {'label': 'Confirm follow-up', 'done': false},
            {'label': 'Upload visit proof', 'done': false},
          ]
        : visit.checklist
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
    final attendees = visit.attendees.map((item) => '$item').toList();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Active visit update'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: attendee,
                          decoration: const InputDecoration(
                            labelText: 'Add attendee',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (attendee.text.trim().isNotEmpty) {
                            setLocal(() {
                              attendees.add(attendee.text.trim());
                              attendee.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),
                  if (attendees.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        children: attendees
                            .map(
                              (name) => Chip(
                                label: Text(name),
                                onDeleted: () =>
                                    setLocal(() => attendees.remove(name)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ...checklist.asMap().entries.map(
                    (entry) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: entry.value['done'] == true,
                      title: Text('${entry.value['label']}'),
                      onChanged: (value) => setLocal(
                        () => checklist[entry.key]['done'] = value == true,
                      ),
                    ),
                  ),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Visit notes'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save update'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'progress', {
        'attendees': attendees,
        'checklist': checklist,
        'notes': notes.text.trim(),
      });
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
    final signature = TextEditingController();
    String returnMode = 'return_office';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Complete visit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: outcome,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Outcome *'),
              ),
              DropdownButtonFormField<String>(
                initialValue: returnMode,
                decoration: const InputDecoration(labelText: 'After visit'),
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
                onChanged: (value) => setLocal(() => returnMode = value!),
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
            TextField(
              controller: signature,
              decoration: const InputDecoration(
                labelText: 'Client signature / OTP name',
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || outcome.text.trim().isEmpty) return;
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'complete', {
        ...await _position(),
        'outcome': outcome.text.trim(),
        'follow_up': follow.text.trim(),
        'return_mode': returnMode,
        'client_signature_name': signature.text.trim(),
      });
    });
  }

  Future<void> _verifyVisit() async {
    await _run(() async {
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'verify',
        const {},
      );
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
    final receipt = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (receipt != null) {
      await _run(() async {
        await widget.service.uploadFiles(
          widget.userId,
          widget.visitId,
          'expense',
          [receipt.path],
        );
      });
    }
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
                    if (visit.attendees.isNotEmpty)
                      EmployeeInfoRow('Attendees', '${visit.attendees.length}'),
                    if (visit.checklist.isNotEmpty)
                      EmployeeInfoRow(
                        'Checklist',
                        '${visit.checklist.where((item) => item is Map && item['done'] == true).length}/${visit.checklist.length} completed',
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
                    onPressed: _working ? null : _startTravel,
                    icon: const Icon(Icons.directions_car_filled_rounded),
                    label: const Text('Office check-out & start travel'),
                  ),
                if (!widget.reviewerMode && visit.status == 'travelling') ...[
                  _Section(
                    title: 'Travel in progress',
                    children: [
                      EmployeeInfoRow('Destination', visit.address),
                      EmployeeInfoRow('GPS', 'Live tracking active'),
                      if (visit.reachedClientAt == null)
                        FilledButton.icon(
                          onPressed: _working ? null : _reachedClient,
                          icon: const Icon(Icons.flag_rounded),
                          label: const Text('Reached client'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _working ? null : _checkIn,
                          icon: const Icon(Icons.location_on),
                          label: const Text('Client check-in'),
                        ),
                    ],
                  ),
                ],
                if (!widget.reviewerMode && visit.status == 'in_progress')
                  Column(
                    children: [
                      if (visit.checkInAt != null) ...[
                        _ElapsedTimer(startedAt: visit.checkInAt!),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: _working ? null : _updateActiveVisit,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Add active visit update'),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _working ? null : _complete,
                          icon: const Icon(Icons.task_alt),
                          label: const Text('Complete visit'),
                        ),
                      ),
                    ],
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
                if (widget.reviewerMode &&
                    visit.status == 'completed' &&
                    visit.managerVerifiedBy.isEmpty)
                  FilledButton.icon(
                    onPressed: _working ? null : _verifyVisit,
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Verify completed visit'),
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
  final VoidCallback onInProgress;
  final VoidCallback onPendingCheckIn;
  final VoidCallback onUpcoming;
  final VoidCallback onPendingApproval;
  final VoidCallback onHistory;
  const _Summary({
    required this.summary,
    required this.onInProgress,
    required this.onPendingCheckIn,
    required this.onUpcoming,
    required this.onPendingApproval,
    required this.onHistory,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Today', style: _sectionStyle(context)),
      const SizedBox(height: 7),
      Row(
        children: [
          _box(
            context,
            'In Progress',
            (summary['travelling'] ?? 0) + (summary['in_progress'] ?? 0),
            ClientVisitColors.blue,
            onInProgress,
          ),
          const SizedBox(width: 8),
          _box(
            context,
            'Pending Check-In',
            summary['approved'] ?? 0,
            ClientVisitColors.orange,
            onPendingCheckIn,
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Upcoming', style: _sectionStyle(context)),
      const SizedBox(height: 7),
      _wideBox(
        context,
        'Upcoming Visits',
        summary['approved'] ?? 0,
        ClientVisitColors.blue,
        onUpcoming,
      ),
      const SizedBox(height: 12),
      Text('Pending Approval', style: _sectionStyle(context)),
      const SizedBox(height: 7),
      _wideBox(
        context,
        'Pending Approval',
        summary['pending'] ?? 0,
        ClientVisitColors.orange,
        onPendingApproval,
      ),
      const SizedBox(height: 12),
      Text('History', style: _sectionStyle(context)),
      const SizedBox(height: 7),
      _wideBox(
        context,
        'Completed Visits',
        (summary['completed'] ?? 0) + (summary['rejected'] ?? 0),
        ClientVisitColors.green,
        onHistory,
      ),
    ],
  );

  TextStyle _sectionStyle(BuildContext context) => TextStyle(
    color: ThemeConfig.getTextPrimary(context),
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

  Widget _box(
    BuildContext context,
    String label,
    int count,
    Color color,
    VoidCallback onTap,
  ) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
    ),
  );

  Widget _wideBox(
    BuildContext context,
    String label,
    int count,
    Color color,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: EmployeeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: ThemeConfig.getTextPrimary(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    ),
  );
}

class _ElapsedTimer extends StatefulWidget {
  final DateTime startedAt;
  const _ElapsedTimer({required this.startedAt});

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
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
    final elapsed = DateTime.now().difference(widget.startedAt.toLocal());
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return EmployeeCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: EmployeeColors.blue),
          const SizedBox(width: 8),
          Text(
            '$hours:$minutes:$seconds',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: EmployeeColors.blue),
          ),
        ],
      ),
    );
  }
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
