import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _openStatusList(
    String title,
    Set<String> statuses, {
    bool historyMode = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ClientVisitStatusListScreen(
          title: title,
          userId: widget.userId,
          statuses: statuses,
          historyMode: historyMode,
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
      child: Scaffold(
        floatingActionButton: (!widget.readOnlyMode && widget.allowCreate)
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('New Visit'),
            )
          : null,
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16,
              (!widget.readOnlyMode && widget.allowCreate) ? 90 : 16),
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
                  }, historyMode: true),
                ),
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
      ),
    );
  }
}

class _ClientVisitStatusListScreen extends StatefulWidget {
  final String title;
  final String userId;
  final Set<String> statuses;
  final bool historyMode;
  final Future<void> Function(ClientVisit visit) onOpenVisit;

  const _ClientVisitStatusListScreen({
    required this.title,
    required this.userId,
    required this.statuses,
    this.historyMode = false,
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
        _visits = widget.historyMode
            ? result.visits.where(_isHistoryVisit).toList()
            : result.visits
                  .where((visit) => widget.statuses.contains(visit.status))
                  .toList();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    }
  }

  bool _isHistoryVisit(ClientVisit visit) {
    final ownVisit = visit.employeeUserId == widget.userId;
    if (ownVisit) return !const {'draft', 'pending'}.contains(visit.status);
    return visit.managerUserId == widget.userId &&
        !ownVisit &&
        !const {'draft', 'pending'}.contains(visit.status);
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
            else if (widget.historyMode)
              ..._historySections(_visits!)
            else
              ..._visits!.map(_visitCard),
          ],
        ),
      ),
    ),
  );

  List<Widget> _historySections(List<ClientVisit> visits) {
    final own = visits
        .where((visit) => visit.employeeUserId == widget.userId)
        .toList();
    final approvals = visits
        .where((visit) => visit.employeeUserId != widget.userId)
        .toList();
    return [
      _HistoryHeader(title: 'My Visit History', count: own.length),
      if (own.isEmpty)
        const _HistoryEmpty('No reviewed personal visits yet.')
      else
        ...own.map(_visitCard),
      if (approvals.isNotEmpty) ...[
        const SizedBox(height: 12),
        _HistoryHeader(title: 'My Approval History', count: approvals.length),
        ...approvals.map(_visitCard),
      ],
    ];
  }

  Widget _visitCard(ClientVisit visit) => _VisitCard(
    visit: visit,
    historyViewerUserId: widget.historyMode ? widget.userId : '',
    onTap: () async {
      await widget.onOpenVisit(visit);
      await _load();
    },
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
  final _locationCoords = TextEditingController(); // paste coords from WhatsApp
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
      _locationCoords,
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

  /// Parses a coordinate string pasted from WhatsApp / Google Maps.
  /// Handles formats:
  ///   "11.686478, 78.120482"
  ///   "11°41'11.3\"N 78°07'13.7\"E"
  ///   "11.686478,78.120482"
  ///   Google Maps share URL containing @lat,lng
  static ({double lat, double lng})? _parseCoords(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    // Google Maps URL: contains @lat,lng,zoom or ?q=lat,lng
    final urlLatLng = RegExp(r'[/@](-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(text);
    if (urlLatLng != null) {
      final lat = double.tryParse(urlLatLng.group(1)!);
      final lng = double.tryParse(urlLatLng.group(2)!);
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }

    // Decimal degrees: "11.686478, 78.120482" or "11.686478,78.120482"
    final decimal = RegExp(r'^(-?\d+\.?\d*)[,\s]+(-?\d+\.?\d*)$').firstMatch(text);
    if (decimal != null) {
      final lat = double.tryParse(decimal.group(1)!);
      final lng = double.tryParse(decimal.group(2)!);
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }

    // DMS: 11°41'11.3"N 78°07'13.7"E
    final dms = RegExp(
      r'''(\d+)[°]\s*(\d+)[\'′]\s*(\d+\.?\d*)["″]\s*([NS])\s+(\d+)[°]\s*(\d+)[\'′]\s*(\d+\.?\d*)["″]\s*([EW])''',
      caseSensitive: false,
    ).firstMatch(text);
    if (dms != null) {
      double toDecimal(String d, String m, String s) =>
          double.parse(d) + double.parse(m) / 60 + double.parse(s) / 3600;
      double lat = toDecimal(dms.group(1)!, dms.group(2)!, dms.group(3)!);
      double lng = toDecimal(dms.group(5)!, dms.group(6)!, dms.group(7)!);
      if (dms.group(4)!.toUpperCase() == 'S') lat = -lat;
      if (dms.group(8)!.toUpperCase() == 'W') lng = -lng;
      return (lat: lat, lng: lng);
    }

    return null;
  }

  String? _validateCoords(String? value) {
    if ((value ?? '').trim().isEmpty) return null; // optional field
    final text = value!.trim();
    // Accept shortened Google Maps links as valid input
    if (RegExp(r'https?://(maps\.app\.goo\.gl|goo\.gl/maps)/\S+', caseSensitive: false).hasMatch(text)) {
      return null;
    }
    if (_parseCoords(text) == null) {
      return 'Paste a Google Maps link or coordinates (e.g. 11.686478, 78.120482)';
    }
    return null;
  }

  /// Resolves a shortened Google Maps URL (maps.app.goo.gl/...)
  /// by following redirects and extracting the lat/lng from the final URL.
  static Future<({double lat, double lng})?> _resolveShortUrl(String url) async {
    try {
      // Follow the redirect chain (up to 5 hops) without downloading the body
      String current = url;
      for (int i = 0; i < 5; i++) {
        final request = http.Request('HEAD', Uri.parse(current))
          ..followRedirects = false;
        final response = await request.send().timeout(const Duration(seconds: 8));
        final location = response.headers['location'];
        if (location == null) break;
        current = location;
        // Try to extract coords from this URL
        final coords = _parseCoords(current);
        if (coords != null) return coords;
      }
      // Last attempt: GET the final URL and look for coords in the body
      final resp = await http.get(Uri.parse(current),
        headers: {'User-Agent': 'HRMS-Bitbyte/1.0'})
        .timeout(const Duration(seconds: 8));
      // Look for @lat,lng pattern in the response body or final URL
      final bodyCoords = _parseCoords(resp.request?.url.toString() ?? '');
      if (bodyCoords != null) return bodyCoords;
      // Scan the HTML body for coordinates
      final match = RegExp(r'[/@](-?\d{1,3}\.\d{4,}),(-?\d{1,3}\.\d{4,})').firstMatch(resp.body);
      if (match != null) {
        final lat = double.tryParse(match.group(1)!);
        final lng = double.tryParse(match.group(2)!);
        if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
          return (lat: lat, lng: lng);
        }
      }
    } catch (_) {}
    return null;
  }

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
      final rawLocation = _locationCoords.text.trim();
      // Resolve coordinates: parse directly, or follow short URL redirect
      var coords = _parseCoords(rawLocation);
      if (coords == null && RegExp(
        r'https?://(maps\.app\.goo\.gl|goo\.gl/maps)/\S+',
        caseSensitive: false,
      ).hasMatch(rawLocation)) {
        coords = await _resolveShortUrl(rawLocation);
      }
      await widget.service.create(widget.userId, {
        'client_name': _client.text.trim(),
        'contact_person': _contact.text.trim(),
        'contact_phone': _phone.text.trim(),
        'address': _address.text.trim(),
        if (coords != null) 'latitude': coords.lat,
        if (coords != null) 'longitude': coords.lng,
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
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  submit ? 'Submitted Successfully' : 'Draft Saved',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  submit
                      ? 'Your visit request has been submitted for approval.'
                      : 'Your visit request has been saved as a draft.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      }
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _submit(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : () => _submit(true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 8),
                        Text('Saving…'),
                      ])
                    : const Text('Submit request'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Contact number',
                    hintText: 'Enter 10-digit mobile number',
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
                const SizedBox(height: 4),
                TextFormField(
                  controller: _locationCoords,
                  validator: _validateCoords,
                  decoration: InputDecoration(
                    labelText: 'Client location (paste from WhatsApp / Maps)',
                    hintText: 'https://maps.app.goo.gl/...',
                    helperText:
                        'Paste a Google Maps share link or coordinates',
                    helperMaxLines: 2,
                    suffixIcon: _locationCoords.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(
                              () => _locationCoords.clear(),
                            ),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
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
                              '${tl['label'] ?? 'Approver'} (${tl['role_label'] ?? tl['role'] ?? ''})',
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
            const SizedBox(height: 8),
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

class _HistoryHeader extends StatelessWidget {
  final String title;
  final int count;
  const _HistoryHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Chip(label: Text('$count')),
      ],
    ),
  );
}

class _HistoryEmpty extends StatelessWidget {
  final String message;
  const _HistoryEmpty(this.message);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: EmployeeCard(
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: EmployeeColors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _VisitCard extends StatelessWidget {
  final ClientVisit visit;
  final VoidCallback onTap;
  final String historyViewerUserId;
  const _VisitCard({
    required this.visit,
    required this.onTap,
    this.historyViewerUserId = '',
  });

  Color get _statusColor => employeeStatusColor(visit.status);

  String get _statusLabel => _label(visit.status);

  String get _historyDetails {
    if (historyViewerUserId.isEmpty) return '';
    final ownVisit = visit.employeeUserId == historyViewerUserId;
    final relation = ownVisit
        ? 'My visit'
        : 'Approval for ${visit.employeeName.isEmpty ? visit.employeeUserId : visit.employeeName}';
    if (visit.approvedBy.isEmpty) return relation;
    final approver = visit.approvedByName.isNotEmpty
        ? visit.approvedByName
        : visit.approvedBy;
    final role = visit.approvedByRole.isEmpty
        ? ''
        : '${visit.approvedByRole.toUpperCase()} · ';
    final action = visit.status == 'rejected' ? 'Returned by' : 'Approved by';
    return '$relation · $action $role$approver';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF0D1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: client name + status chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visit icon circle
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.business_rounded,
                        color: _statusColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(visit.clientName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ThemeConfig.getTextPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(visit.visitId,
                            style: TextStyle(
                              fontSize: 11,
                              color: ThemeConfig.getTextMuted(context),
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withAlpha(60)),
                      ),
                      child: Text(_statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        )),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // Details row
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _detailChip(context, Icons.person_outline, visit.contactPerson),
                    _detailChip(context, Icons.calendar_today_outlined,
                      '${visit.scheduledAt.day.toString().padLeft(2,'0')}/'
                      '${visit.scheduledAt.month.toString().padLeft(2,'0')}/'
                      '${visit.scheduledAt.year}  '
                      '${TimeOfDay.fromDateTime(visit.scheduledAt).format(context)}'),
                    _detailChip(context, Icons.directions_car_outlined,
                      _label(visit.travelMode)),
                  ],
                ),
                const SizedBox(height: 8),
                // Purpose
                Text(visit.purpose,
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConfig.getTextMuted(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                if (_historyDetails.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(_historyDetails,
                    style: TextStyle(
                      fontSize: 11,
                      color: ThemeConfig.getTextMuted(context),
                      fontStyle: FontStyle.italic,
                    )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailChip(BuildContext context, IconData icon, String label) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: ThemeConfig.getTextMuted(context)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12,
        color: ThemeConfig.getTextMuted(context))),
    ]);
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
