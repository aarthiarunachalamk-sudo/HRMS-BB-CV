import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import '../Employee/employee_shared.dart';
import 'client_service_details_cache.dart';
import 'client_visit_models.dart';
import 'client_visit_service_catalog.dart';
import 'client_visit_service.dart';
import 'client_visit_flow_screens.dart';
import 'client_visit_theme.dart';
import 'client_visit_downloads.dart';

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
  final String title;
  final String roleLabel;
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
    this.title = 'Visit Dashboard',
    this.roleLabel = '',
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
  int _downloadCount = 0;
  Timer? _statusClock;

  @override
  void initState() {
    super.initState();
    _load();
    _loadDownloads();
    _statusClock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusClock?.cancel();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    final files = await ClientVisitDownloads.load(widget.userId);
    if (mounted) setState(() => _downloadCount = files.length);
  }

  Future<void> _openDownloads() async {
    await _openHistory(initialTab: 1);
    await _loadDownloads();
  }

  Future<void> _openHistory({int initialTab = 0, int? initialVisitId}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientVisitHistoryScreen(
          userId: widget.userId,
          viewerRole: widget.requesterRole,
          initialTab: initialTab,
          initialVisitId: initialVisitId,
          onOpenVisit: _openVisit,
        ),
      ),
    );
    await _load();
    await _loadDownloads();
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

  Future<void> _openServices() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientVisitClientDetailsScreen(userId: widget.userId),
      ),
    );
    await _loadDownloads();
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
          viewerRole: widget.requesterRole,
          statuses: statuses,
          historyMode: historyMode,
          onOpenVisit: _openVisit,
        ),
      ),
    );
    await _load();
  }

  Widget _monitoringScreen(ClientVisit visit, {bool canVerify = false}) {
    // All visits — completed or not — use step 0 → _superAdminVisitDetail
    // so TL/SuperAdmin always see the full detail view with route map,
    // attachments, signatures, expenses, checklist, and verify button.
    return ClientVisitReadOnlyFlowScreen(
      userId: widget.userId,
      visitId: visit.id,
      step: 0,
      service: _service,
      reviewerMode: canVerify,
      viewerRole: widget.requesterRole,
      onViewHistory: () => _openHistory(initialVisitId: visit.id),
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
      onViewHistory: () => _openHistory(initialVisitId: visit.id),
    ),
    _ => ClientVisitApprovedScreen(
      userId: widget.userId,
      visitId: visit.id,
      service: _service,
    ),
  };

  Future<void> _openVisit(ClientVisit visit) async {
    if (visit.status == 'travelling' && visit.reachedClientAt == null) {
      if (!widget.readOnlyMode && visit.employeeUserId == widget.userId) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientVisitTravelProgressScreen(
              userId: widget.userId,
              visitId: visit.id,
              service: _service,
            ),
          ),
        );
        await _load();
        return;
      }
    }

    late final Widget screen;
    if (widget.readOnlyMode) {
      screen = _monitoringScreen(visit);
    } else if (widget.reviewerMode && visit.employeeUserId == widget.userId) {
      screen = _employeeFlowScreen(visit);
    } else if (widget.reviewerMode) {
      final canReview =
          !widget.assignedApprovalsOnly || visit.managerUserId == widget.userId;
      final isHrFinalApproval =
          visit.tlApprovedBy.isNotEmpty &&
          widget.requesterRole.trim().toLowerCase() == 'hr';
      screen =
          visit.status == 'pending' &&
              canReview &&
              (visit.tlApprovedBy.isEmpty || isHrFinalApproval)
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
    await _loadDownloads();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          actions: [
            if (widget.roleLabel.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Text(
                    widget.roleLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: 'Refresh',
            ),
          ],
        ),
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
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              (!widget.readOnlyMode && widget.allowCreate) ? 90 : 16,
            ),
            children: [
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
                  onHistory: () => _openHistory(),
                  downloadCount: _downloadCount,
                  onDownloads: _openDownloads,
                  onServices: _openServices,
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

class ClientVisitClientDetailsScreen extends StatefulWidget {
  final String userId;

  const ClientVisitClientDetailsScreen({super.key, required this.userId});

  @override
  State<ClientVisitClientDetailsScreen> createState() =>
      _ClientVisitClientDetailsScreenState();
}

class _ClientVisitClientDetailsScreenState
    extends State<ClientVisitClientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ClientVisitService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label is required.';
    return null;
  }

  String? _nameValidator(String? value) {
    final requiredError = _required(value, 'Client name');
    if (requiredError != null) return requiredError;
    final name = value!.trim();
    if (name.length < 2) return 'Client name must have at least 2 characters.';
    if (name.length > 160) return 'Client name is too long.';
    return null;
  }

  String? _emailValidator(String? value) {
    final requiredError = _required(value, 'Client email ID');
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid client email ID.';
    }
    return null;
  }

  String? _mobileValidator(String? value) {
    final requiredError = _required(value, 'Client mobile number');
    if (requiredError != null) return requiredError;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Enter exactly 10 digits for the client mobile number.';
    }
    return null;
  }

  String? _detailsValidator(String? value) {
    final requiredError = _required(value, 'Client details');
    if (requiredError != null) return requiredError;
    final details = value!.trim();
    if (details.length < 3) {
      return 'Client details must have at least 3 characters.';
    }
    if (details.length > 2000) return 'Client details is too long.';
    return null;
  }

  String? _gstValidator(String? value) {
    final gst = value!.trim().toUpperCase();
    if (gst.isEmpty) return null;
    if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z\d]$').hasMatch(gst)) {
      return 'Enter a valid 15-character GSTIN or leave it blank.';
    }
    return null;
  }

  String? _addressValidator(String? value) {
    final requiredError = _required(value, 'Client address');
    if (requiredError != null) return requiredError;
    final address = value!.trim();
    if (address.length < 3) return 'Client address must have at least 3 characters.';
    if (address.length > 500) return 'Client address is too long.';
    return null;
  }

  Future<void> _openServices({
    bool syncPending = false,
    required Map<String, dynamic> clientDetails,
  }) =>
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientVisitServicesScreen(
            userId: widget.userId,
            clientDetailsSyncPending: syncPending,
            clientDetails: clientDetails,
          ),
        ),
      );

  Future<void> _saveAndContinue() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final clientName = _nameController.text.trim();
    final clientEmail = _emailController.text.trim().toLowerCase();
    final clientMobile = _mobileController.text.trim();
    final clientGst = _gstController.text.trim().toUpperCase();
    final clientAddress = _addressController.text.trim();
    final clientDetails = _detailsController.text.trim();
    final invoiceClient = <String, dynamic>{
      'client_name': clientName,
      'client_email': clientEmail,
      'client_mobile': clientMobile,
      'client_gst': clientGst,
      'client_address': clientAddress,
      'client_details': clientDetails,
    };
    setState(() => _saving = true);
    try {
      await _service.saveClientDetails(
        widget.userId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientMobile: clientMobile,
        clientGst: clientGst,
        clientAddress: clientAddress,
        clientDetails: clientDetails,
      );
      if (!mounted) return;
      await _openServices(clientDetails: invoiceClient);
    } on ClientDetailsApiUnavailableException {
      await ClientServiceDetailsCache.savePending(
        userId: widget.userId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientMobile: clientMobile,
        clientGst: clientGst,
        clientAddress: clientAddress,
        clientDetails: clientDetails,
      );
      if (!mounted) return;
      await _openServices(
        syncPending: true,
        clientDetails: invoiceClient,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'.replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ClientVisitTheme(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ClientVisitDownloadedFilesScreen(userId: widget.userId),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0568D8), Color(0xFF00A7C7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter the client information before choosing services.',
                            style: TextStyle(color: Color(0xFFDDF5FF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _field(
                controller: _nameController,
                label: 'Client name',
                icon: Icons.person_outline_rounded,
                maxLength: 160,
                validator: _nameValidator,
              ),
              _field(
                controller: _emailController,
                label: 'Client email ID',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                maxLength: 254,
                validator: _emailValidator,
              ),
              _field(
                controller: _mobileController,
                label: 'Client mobile number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _mobileValidator,
              ),
              _field(
                controller: _gstController,
                label: 'GSTIN (optional)',
                icon: Icons.receipt_long_outlined,
                maxLength: 15,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) => newValue.copyWith(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection,
                    ),
                  ),
                ],
                validator: _gstValidator,
              ),
              _field(
                controller: _addressController,
                label: 'Client address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
                maxLength: 500,
                validator: _addressValidator,
              ),
              _field(
                controller: _detailsController,
                label: 'Client details',
                icon: Icons.description_outlined,
                maxLines: 5,
                maxLength: 2000,
                validator: _detailsValidator,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveAndContinue,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _saving ? 'Saving...' : 'Save & Continue to Services',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ClientVisitServicesScreen extends StatefulWidget {
  final String userId;
  final bool clientDetailsSyncPending;
  final Map<String, dynamic> clientDetails;

  const ClientVisitServicesScreen({
    super.key,
    required this.userId,
    this.clientDetailsSyncPending = false,
    this.clientDetails = const <String, dynamic>{},
  });

  @override
  State<ClientVisitServicesScreen> createState() =>
      _ClientVisitServicesScreenState();

  static Color _serviceColor(String module) => switch (module) {
    'Digital Marketing' => const Color(0xFFFF8A1F),
    'SEO' => const Color(0xFF12B981),
    'Performance Marketing' => const Color(0xFFEF476F),
    'Web Apps' => const Color(0xFF1687FF),
    'Hosting' => const Color(0xFF00A7C7),
    'Personal Branding' => const Color(0xFF8B5CF6),
    'Mobile Apps' => const Color(0xFFE8B20E),
    _ => ClientVisitColors.blue,
  };

  static IconData _serviceIcon(String module) => switch (module) {
    'Digital Marketing' => Icons.campaign_rounded,
    'SEO' => Icons.manage_search_rounded,
    'Performance Marketing' => Icons.ads_click_rounded,
    'Web Apps' => Icons.web_rounded,
    'Hosting' => Icons.cloud_rounded,
    'Personal Branding' => Icons.badge_rounded,
    'Mobile Apps' => Icons.phone_android_rounded,
    _ => Icons.business_center_rounded,
  };
}

class _ClientVisitServicesScreenState extends State<ClientVisitServicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, int> _selectedServicePackageIndexes = <String, int>{};

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: clientVisitPackageNames.length, vsync: this)
          ..addListener(() {
            if (!_tabController.indexIsChanging) setState(() {});
          });
    if (widget.clientDetailsSyncPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Client details saved on this device. Backend sync is pending.',
            ),
            backgroundColor: Color(0xFFB26A00),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleService(String id, int packageIndex, bool selected) {
    setState(() {
      if (selected) {
        _selectedServicePackageIndexes[id] = packageIndex;
      } else {
        _selectedServicePackageIndexes.remove(id);
      }
    });
  }

  Widget _serviceOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    final packageIndex = _tabController.index;
    final packageName = clientVisitPackageNames[packageIndex];
    return ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Services'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Invoice history',
              icon: const Icon(Icons.history_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ClientVisitDownloadedFilesScreen(userId: widget.userId),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 18),
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1687FF), Color(0xFF00B7D7)],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: ClientVisitColors.blue.withAlpha(75),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: clientVisitPackageNames
                .map((name) => Tab(text: name))
                .toList(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0568D8), Color(0xFF00A7C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ClientVisitColors.blue.withAlpha(55),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -26,
                    top: -42,
                    child: _serviceOrb(106, Colors.white.withAlpha(24)),
                  ),
                  Positioned(
                    right: 43,
                    bottom: -34,
                    child: _serviceOrb(70, Colors.white.withAlpha(18)),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$packageName package',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Choose the services your client needs. You can select more than one.',
                              style: TextStyle(
                                color: Color(0xFFDDF5FF),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(28),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedServicePackageIndexes.length} services in your shortlist',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Services in $packageName',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a card for full details. Use the check box to add it to the preview.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeConfig.getTextMuted(context),
              ),
            ),
            const SizedBox(height: 12),
            ...clientVisitServiceCatalog.map(
              (service) => _serviceCard(service, packageIndex),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _selectedServicePackageIndexes.isEmpty
                ? null
                : () async {
                    final reviewedSelections = await Navigator.of(context)
                        .push<Map<String, int>>(
                          MaterialPageRoute(
                            builder: (_) =>
                                ClientVisitServiceSelectionPreviewScreen(
                                  userId: widget.userId,
                                  clientDetails: widget.clientDetails,
                                  selectedServices: clientVisitServiceCatalog
                                      .where(
                                        (service) =>
                                            _selectedServicePackageIndexes
                                                .containsKey(service.id),
                                      )
                                      .map(
                                        (service) => ClientVisitSelectedService(
                                          service: service,
                                          packageIndex:
                                              _selectedServicePackageIndexes[service
                                                  .id]!,
                                        ),
                                      )
                                      .toList(),
                                ),
                          ),
                        );
                    if (!mounted || reviewedSelections == null) return;
                    setState(() {
                      _selectedServicePackageIndexes
                        ..clear()
                        ..addAll(reviewedSelections);
                    });
                  },
            icon: const Icon(Icons.visibility_rounded),
            label: Text(
              'Preview selected services (${_selectedServicePackageIndexes.length})',
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(ClientVisitServiceItem service, int packageIndex) {
    final color = ClientVisitServicesScreen._serviceColor(service.module);
    final selected = _selectedServicePackageIndexes[service.id] == packageIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EmployeeCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _toggleService(service.id, packageIndex, !selected),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withAlpha(24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    ClientVisitServicesScreen._serviceIcon(service.module),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.module.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 3),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientVisitServiceDetailScreen(
                              service: service,
                              selectedPackageIndex: packageIndex,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.getTextMuted(context),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '₹${service.prices[packageIndex]}  •  ${service.payable}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _serviceMetaChip(
                            Icons.schedule_rounded,
                            service.frequency,
                            color,
                          ),
                          _serviceMetaChip(
                            Icons.inventory_2_outlined,
                            service.unit,
                            color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _toggleService(service.id, packageIndex, !selected),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? color : color.withAlpha(18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withAlpha(selected ? 255 : 80),
                      ),
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.add_rounded,
                      color: selected ? Colors.white : color,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceMetaChip(IconData icon, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class ClientVisitServiceDetailScreen extends StatelessWidget {
  final ClientVisitServiceItem service;
  final int? selectedPackageIndex;

  const ClientVisitServiceDetailScreen({
    super.key,
    required this.service,
    this.selectedPackageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final color = ClientVisitServicesScreen._serviceColor(service.module);
    return ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Service Details')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, .28)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      ClientVisitServicesScreen._serviceIcon(service.module),
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: const TextStyle(
                      color: Color(0xFFEAF6FF),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _overviewCard(context, color),
            const SizedBox(height: 14),
            _pricingCard(context, color),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(65)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedPackageIndex == null
                          ? 'Review the package pricing before choosing this service.'
                          : '${clientVisitPackageNames[selectedPackageIndex!]} price is highlighted below.',
                      style: TextStyle(fontSize: 12, height: 1.35),
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

  Widget _overviewCard(BuildContext context, Color color) => EmployeeCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fact_check_rounded, color: color, size: 21),
            const SizedBox(width: 9),
            Text(
              'Service information',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _infoRow('Module', service.module),
        _infoRow('Unit', service.unit),
        _infoRow('Frequency', service.frequency),
        _infoRow('Payable', service.payable),
      ],
    ),
  );

  Widget _pricingCard(BuildContext context, Color color) => EmployeeCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.currency_rupee_rounded, color: color, size: 21),
            const SizedBox(width: 9),
            const Text(
              'Package pricing',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(clientVisitPackageNames.length, (index) {
          final highlighted = index == selectedPackageIndex;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: highlighted ? color.withAlpha(18) : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    clientVisitPackageNames[index],
                    style: TextStyle(
                      fontWeight: highlighted
                          ? FontWeight.w900
                          : FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '₹${service.prices[index]}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          );
        }),
        Text(
          'Prices are exclusive of GST.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class ClientVisitSelectedService {
  final ClientVisitServiceItem service;
  final int packageIndex;

  const ClientVisitSelectedService({
    required this.service,
    required this.packageIndex,
  });
}

class ClientVisitGeneratedInvoice {
  final Uint8List bytes;
  final String fileName;
  final String invoiceNumber;
  final String shareFilePath;

  const ClientVisitGeneratedInvoice({
    required this.bytes,
    required this.fileName,
    required this.invoiceNumber,
    required this.shareFilePath,
  });
}

class ClientVisitServiceSelectionPreviewScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> clientDetails;
  final List<ClientVisitSelectedService> selectedServices;

  const ClientVisitServiceSelectionPreviewScreen({
    super.key,
    required this.userId,
    required this.clientDetails,
    required this.selectedServices,
  });

  @override
  State<ClientVisitServiceSelectionPreviewScreen> createState() =>
      _ClientVisitServiceSelectionPreviewScreenState();
}

class _ClientVisitServiceSelectionPreviewScreenState
    extends State<ClientVisitServiceSelectionPreviewScreen> {
  late final Set<String> _acceptedServiceIds;
  bool _generatingInvoice = false;

  @override
  void initState() {
    super.initState();
    _acceptedServiceIds = widget.selectedServices
        .map((selection) => selection.service.id)
        .toSet();
  }

  void _setAccepted(String serviceId, bool accepted) {
    setState(() {
      if (accepted) {
        _acceptedServiceIds.add(serviceId);
      } else {
        _acceptedServiceIds.remove(serviceId);
      }
    });
  }

  void _returnToServices() => Navigator.of(context).pop(<String, int>{
    for (final selection in widget.selectedServices)
      if (_acceptedServiceIds.contains(selection.service.id))
        selection.service.id: selection.packageIndex,
  });

  Future<ClientVisitGeneratedInvoice?> _generateInvoicePdf(
    List<ClientVisitSelectedService> acceptedServices,
  ) async {
    if (acceptedServices.isEmpty || _generatingInvoice) return null;
    setState(() => _generatingInvoice = true);
    try {
      final total = acceptedServices.fold<int>(
        0,
        (sum, selection) =>
            sum + selection.service.prices[selection.packageIndex],
      );
      final gst = acceptedServices.fold<int>(
        0,
        (sum, selection) =>
            sum +
            (selection.service.prices[selection.packageIndex] * .18).round(),
      );
      final grandTotal = total + gst;
      final oneTimeServices = acceptedServices
          .where(
            (selection) =>
                selection.service.payable.trim().toLowerCase() == 'one time',
          )
          .toList();
      final monthlyServices = acceptedServices
          .where(
            (selection) =>
                selection.service.payable.trim().toLowerCase() == 'monthly',
          )
          .toList();
      final now = DateTime.now();
      final clientName = '${widget.clientDetails['client_name'] ?? ''}'.trim();
      final clientEmail = '${widget.clientDetails['client_email'] ?? ''}'.trim();
      final clientMobile = '${widget.clientDetails['client_mobile'] ?? ''}'.trim();
      final clientAddress =
          '${widget.clientDetails['client_address'] ?? ''}'.trim();
      final clientNotes =
          '${widget.clientDetails['client_details'] ?? ''}'.trim();
      final invoiceNumber =
          'BBT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
      pw.MemoryImage? logo;
      try {
        final logoData = await rootBundle.load('assets/logo.png');
        logo = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {
        // Keep invoice generation available even when the optional logo is absent.
      }
      pw.MemoryImage? watermark;
      try {
        final watermarkData = await rootBundle.load(
          'assets/invoice_watermark_transparent.png',
        );
        watermark = pw.MemoryImage(watermarkData.buffer.asUint8List());
      } catch (_) {
        // Fall back to the header logo watermark when the dedicated asset is absent.
      }
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 66),
            buildBackground: (_) => (watermark ?? logo) == null
                ? pw.SizedBox()
                : pw.Center(
                    child: pw.Opacity(
                      opacity: .12,
                      child: pw.Image(
                        watermark ?? logo!,
                        width: 390,
                        height: 390,
                      ),
                    ),
                  ),
          ),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF3F8FC),
              border: pw.Border(
                top: const pw.BorderSide(
                  color: PdfColor.fromInt(0xFF4D8AC8),
                  width: 1.2,
                ),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  '2nd Floor - West Wing, Raja Complex, Opp: Sago Serve, Omalur main road, Salem-636302, TN-India.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: const PdfColor.fromInt(0xFF34495E),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text(
                      'reachus@bitbytetech.org',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF1769AA),
                      ),
                    ),
                    pw.Text(
                      'www.bitbytetech.org',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF1769AA),
                      ),
                    ),
                    pw.Text(
                      '+91 99437 43136 (WhatsApp Only).',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF1769AA),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text(
                      'Internal Document',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF34495E),
                      ),
                    ),
                    pw.Text(
                      'Confidential',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF34495E),
                      ),
                    ),
                    pw.Text(
                      'All rights reserved.  Page ${context.pageNumber} of ${context.pagesCount}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF34495E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          build: (_) => [
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFF8EBCE7),
                  width: .7,
                ),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'Bit Byte Technologies',
                              style: pw.TextStyle(
                                fontSize: 17,
                                fontWeight: pw.FontWeight.bold,
                                decoration: pw.TextDecoration.underline,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              '2nd Floor - West Wing, Raja Complex,',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'opp. to: Sago Serve Factory, Omalur main road, Salem - 636302, Tamil Nadu, India.',
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'GST No: 33BLNPN5359J1ZL',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (logo != null)
                        pw.Container(
                          width: 48,
                          height: 48,
                          margin: const pw.EdgeInsets.only(left: 10),
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    height: 2.5,
                    color: const PdfColor.fromInt(0xFF4D8AC8),
                  ),
                  pw.SizedBox(height: 7),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Text(
                        'reachus@bitbytetech.org',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.Text(
                        'www.bitbytetech.org',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.Text(
                        '+91 99437 43136 (WhatsApp Only)',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    fontSize: 15,
                    color: const PdfColor.fromInt(0xFF0B5FA5),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'SERVICE SELECTION & PRICING',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 7),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF4F8FC),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE DETAILS',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: const PdfColor.fromInt(0xFF1687FF),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Invoice no: $invoiceNumber',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Date: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(width: .7, height: 44, color: PdfColors.grey300),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PACKAGE',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: const PdfColor.fromInt(0xFF1687FF),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Mixed package selection',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${acceptedServices.length} selected services',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: .7),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BILL TO',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: const PdfColor.fromInt(0xFF1687FF),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    clientName.isEmpty ? 'Client' : clientName,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (clientAddress.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(clientAddress, style: const pw.TextStyle(fontSize: 9)),
                  ],
                  if (clientEmail.isNotEmpty || clientMobile.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      [clientEmail, clientMobile]
                          .where((value) => value.isNotEmpty)
                          .join('  |  '),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                  if (clientNotes.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Client requirements: $clientNotes',
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: const [
                '#',
                'Service / Package',
                'Delivery details',
                'Base (INR)',
                'GST 18%',
                'Total (INR)',
              ],
              data: List<List<String>>.generate(acceptedServices.length, (
                index,
              ) {
                final selection = acceptedServices[index];
                final service = selection.service;
                final basePrice = service.prices[selection.packageIndex];
                final serviceGst = (basePrice * .18).round();
                return [
                  '${index + 1}',
                  '${service.name}\n${clientVisitPackageNames[selection.packageIndex]} package',
                  '${service.unit} / ${service.frequency}',
                  _formatInvoiceAmount(basePrice),
                  _formatInvoiceAmount(serviceGst),
                  _formatInvoiceAmount(basePrice + serviceGst),
                ];
              }),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1687FF),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              cellPadding: const pw.EdgeInsets.all(8),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
              columnWidths: const {
                0: pw.FlexColumnWidth(.35),
                1: pw.FlexColumnWidth(2.45),
                2: pw.FlexColumnWidth(1.35),
                3: pw.FlexColumnWidth(.86),
                4: pw.FlexColumnWidth(.78),
                5: pw.FlexColumnWidth(.95),
              },
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFE8F4FF),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PAYMENT SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: const PdfColor.fromInt(0xFF0B5FA5),
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _invoiceTotalRow(
                      'Subtotal',
                      'INR ${_formatInvoiceAmount(total)}',
                    ),
                    pw.SizedBox(height: 6),
                    _invoiceTotalRow(
                      'GST (18%)',
                      'INR ${_formatInvoiceAmount(gst)}',
                    ),
                    pw.Divider(color: PdfColors.blueGrey, height: 16),
                    _invoiceTotalRow(
                      'Grand total',
                      'INR ${_formatInvoiceAmount(grandTotal)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            pw.NewPage(),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF0B5FA5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'FREQUENCY ROUTINE OF THE SERVICES',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            ..._invoiceServiceGroupWidgets(
              'ONE TIME SERVICES',
              oneTimeServices,
            ),
            pw.SizedBox(height: 18),
            ..._invoiceServiceGroupWidgets(
              'ROUTINE SERVICES (MONTHLY)',
              monthlyServices,
            ),
          ],
        ),
      );
      final fileName = 'BitByte_Invoice_$invoiceNumber.pdf';
      final bytes = await document.save();
      final temporaryDirectory = await getTemporaryDirectory();
      final shareFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}$fileName',
      );
      await shareFile.writeAsBytes(bytes, flush: true);
      return ClientVisitGeneratedInvoice(
        bytes: bytes,
        fileName: fileName,
        invoiceNumber: invoiceNumber,
        shareFilePath: shareFile.path,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate invoice PDF: $error')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _generatingInvoice = false);
    }
  }

  List<pw.Widget> _invoiceServiceGroupWidgets(
    String title,
    List<ClientVisitSelectedService> services,
  ) {
    final baseTotal = services.fold<int>(
      0,
      (sum, selection) =>
          sum + selection.service.prices[selection.packageIndex],
    );
    final gstTotal = services.fold<int>(
      0,
      (sum, selection) =>
          sum +
          (selection.service.prices[selection.packageIndex] * .18).round(),
    );
    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F4FF)),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            color: const PdfColor.fromInt(0xFF0B5FA5),
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(height: 6),
      if (services.isEmpty)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: .5),
          ),
          child: pw.Text(
            'No ${title.toLowerCase()} selected.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        )
      else
        pw.TableHelper.fromTextArray(
          headers: const [
            '#',
            'Service / Package',
            'Delivery details',
            'Base (INR)',
            'GST 18%',
            'Total (INR)',
          ],
          data: List<List<String>>.generate(services.length, (index) {
            final selection = services[index];
            final service = selection.service;
            final basePrice = service.prices[selection.packageIndex];
            final serviceGst = (basePrice * .18).round();
            return [
              '${index + 1}',
              '${service.name}\n${clientVisitPackageNames[selection.packageIndex]} package',
              '${service.unit} / ${service.frequency}',
              _formatInvoiceAmount(basePrice),
              _formatInvoiceAmount(serviceGst),
              _formatInvoiceAmount(basePrice + serviceGst),
            ];
          }),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1687FF),
          ),
          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          cellPadding: const pw.EdgeInsets.all(7),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
          columnWidths: const {
            0: pw.FlexColumnWidth(.35),
            1: pw.FlexColumnWidth(2.45),
            2: pw.FlexColumnWidth(1.35),
            3: pw.FlexColumnWidth(.86),
            4: pw.FlexColumnWidth(.78),
            5: pw.FlexColumnWidth(.95),
          },
        ),
      pw.SizedBox(height: 7),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 280,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF3F8FC),
            border: pw.Border.all(
              color: const PdfColor.fromInt(0xFF8EBCE7),
              width: .7,
            ),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '$title TOTAL (INCL. GST)',
                  style: pw.TextStyle(
                    color: const PdfColor.fromInt(0xFF0B5FA5),
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'INR ${_formatInvoiceAmount(baseTotal + gstTotal)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  pw.Widget _invoiceTotalRow(String label, String value, {bool bold = false}) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: bold ? 11 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: bold ? 12 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      );

  String _formatInvoiceAmount(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  Widget _reviewPill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final acceptedServices = widget.selectedServices
        .where(
          (selection) => _acceptedServiceIds.contains(selection.service.id),
        )
        .toList();
    final total = acceptedServices.fold<int>(
      0,
      (sum, selection) =>
          sum + selection.service.prices[selection.packageIndex],
    );
    final gst = acceptedServices.fold<int>(
      0,
      (sum, selection) =>
          sum +
          (selection.service.prices[selection.packageIndex] * .18).round(),
    );
    final grandTotal = total + gst;
    return ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Final Service Check'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ClientVisitColors.blue.withAlpha(42),
                    const Color(0xFF00A7C7).withAlpha(24),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ClientVisitColors.blue.withAlpha(90)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom service selection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Accept or reject each service before sharing this selection with the client.',
                    style: TextStyle(
                      color: ThemeConfig.getTextMuted(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _reviewPill(
                        Icons.check_circle_rounded,
                        '${acceptedServices.length} accepted',
                        const Color(0xFF12B981),
                      ),
                      _reviewPill(
                        Icons.pending_actions_rounded,
                        '${widget.selectedServices.length - acceptedServices.length} rejected',
                        const Color(0xFFD93A4A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subtotal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '₹$total',
                        style: const TextStyle(
                          color: ClientVisitColors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'GST (18%)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeConfig.getTextMuted(context),
                              ),
                        ),
                      ),
                      Text(
                        '₹$gst',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Grand total',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '₹$grandTotal',
                        style: const TextStyle(
                          color: ClientVisitColors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...widget.selectedServices.map((selection) {
              final service = selection.service;
              final color = ClientVisitServicesScreen._serviceColor(
                service.module,
              );
              final accepted = _acceptedServiceIds.contains(service.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EmployeeCard(
                  child: Opacity(
                    opacity: accepted ? 1 : .55,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          ClientVisitServicesScreen._serviceIcon(
                            service.module,
                          ),
                          color: color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  decoration: accepted
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                service.description,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: ThemeConfig.getTextMuted(context),
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${service.unit} • ${service.frequency}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: ThemeConfig.getTextMuted(context),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              _reviewPill(
                                Icons.workspace_premium_rounded,
                                clientVisitPackageNames[selection.packageIndex],
                                color,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 82,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${service.prices[selection.packageIndex]}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () =>
                                    _setAccepted(service.id, !accepted),
                                child: Icon(
                                  accepted
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_outlined,
                                  color: accepted
                                      ? const Color(0xFF12B981)
                                      : const Color(0xFFD93A4A),
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _returnToServices,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add another service'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _acceptedServiceIds.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ClientVisitInvoiceConfirmationScreen(
                                  userId: widget.userId,
                                  selectedServices: acceptedServices,
                                  clientDetails: widget.clientDetails,
                                  onGenerate: () =>
                                      _generateInvoicePdf(acceptedServices),
                                ),
                          ),
                        ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'Confirm ${_acceptedServiceIds.length} service${_acceptedServiceIds.length == 1 ? '' : 's'}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientVisitInvoiceConfirmationScreen extends StatefulWidget {
  final String userId;
  final List<ClientVisitSelectedService> selectedServices;
  final Map<String, dynamic> clientDetails;
  final Future<ClientVisitGeneratedInvoice?> Function() onGenerate;

  const ClientVisitInvoiceConfirmationScreen({
    super.key,
    required this.userId,
    required this.selectedServices,
    required this.clientDetails,
    required this.onGenerate,
  });

  @override
  State<ClientVisitInvoiceConfirmationScreen> createState() =>
      _ClientVisitInvoiceConfirmationScreenState();
}

class _ClientVisitInvoiceConfirmationScreenState
    extends State<ClientVisitInvoiceConfirmationScreen> {
  bool _generating = false;

  Future<void> _generate() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final invoice = await widget.onGenerate();
      if (!mounted || invoice == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClientVisitInvoicePreviewScreen(
            userId: widget.userId,
            invoiceBytes: invoice.bytes,
            fileName: invoice.fileName,
            invoiceNumber: invoice.invoiceNumber,
            shareFilePath: invoice.shareFilePath,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.selectedServices.fold<int>(
      0,
      (sum, item) => sum + item.service.prices[item.packageIndex],
    );
    final gst = widget.selectedServices.fold<int>(
      0,
      (sum, item) =>
          sum + (item.service.prices[item.packageIndex] * .18).round(),
    );
    return ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Confirmed Services'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Invoice history',
              icon: const Icon(Icons.history_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ClientVisitDownloadedFilesScreen(userId: widget.userId),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            EmployeeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invoice summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  _amountRow(
                    'Confirmed services',
                    '${widget.selectedServices.length}',
                  ),
                  _amountRow('Subtotal', '₹$subtotal'),
                  _amountRow('GST (18%)', '₹$gst'),
                  const Divider(height: 20),
                  _amountRow('Grand total', '₹${subtotal + gst}', total: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...widget.selectedServices.map((selection) {
              final service = selection.service;
              final color = ClientVisitServicesScreen._serviceColor(
                service.module,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EmployeeCard(
                  child: Row(
                    children: [
                      Icon(
                        ClientVisitServicesScreen._serviceIcon(service.module),
                        color: color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${clientVisitPackageNames[selection.packageIndex]} package',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${service.prices[selection.packageIndex]}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                _generating ? 'Generating invoice...' : 'Generate invoice',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountRow(String label, String value, {bool total = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: total ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: total ? ClientVisitColors.blue : null,
                fontSize: total ? 18 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class ClientVisitInvoicePreviewScreen extends StatefulWidget {
  final String userId;
  final Uint8List invoiceBytes;
  final String fileName;
  final String invoiceNumber;
  final String shareFilePath;

  const ClientVisitInvoicePreviewScreen({
    super.key,
    required this.userId,
    required this.invoiceBytes,
    required this.fileName,
    required this.invoiceNumber,
    required this.shareFilePath,
  });

  @override
  State<ClientVisitInvoicePreviewScreen> createState() =>
      _ClientVisitInvoicePreviewScreenState();
}

class _ClientVisitInvoicePreviewScreenState
    extends State<ClientVisitInvoicePreviewScreen> {
  static const _filesChannel = MethodChannel('hrms/files');
  final TransformationController _pdfZoomController =
      TransformationController();
  bool _downloading = false;
  bool _downloaded = false;
  bool _zoomEnabled = false;

  @override
  void dispose() {
    _pdfZoomController.dispose();
    super.dispose();
  }

  void _setZoomEnabled(bool enabled) {
    setState(() {
      _zoomEnabled = enabled;
      if (!enabled) _pdfZoomController.value = Matrix4.identity();
    });
  }

  void _changeZoom(double factor) {
    if (!_zoomEnabled) _setZoomEnabled(true);
    final currentScale = _pdfZoomController.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(.75, 5.0).toDouble();
    _pdfZoomController.value = Matrix4.diagonal3Values(nextScale, nextScale, 1);
  }

  Widget _pdfPage(PdfPreviewPageData page) => Container(
    margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(offset: Offset(0, 3), blurRadius: 5)],
    ),
    child: AspectRatio(
      aspectRatio: page.aspectRatio,
      child: Image(image: page.image, fit: BoxFit.cover),
    ),
  );

  Widget _pdfPages(BuildContext context, List<PdfPreviewPageData> pages) {
    if (!_zoomEnabled) {
      return ListView.builder(
        itemCount: pages.length,
        itemBuilder: (_, index) => _pdfPage(pages[index]),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => InteractiveViewer(
        transformationController: _pdfZoomController,
        constrained: false,
        minScale: .75,
        maxScale: 5,
        boundaryMargin: const EdgeInsets.all(100),
        panEnabled: true,
        scaleEnabled: true,
        child: SizedBox(
          width: constraints.maxWidth,
          child: Column(children: pages.map(_pdfPage).toList()),
        ),
      ),
    );
  }

  Future<void> _share() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.shareFilePath)],
        text: 'Please find the Bit Byte service invoice attached.',
        subject: 'Bit Byte service invoice',
      );
    } catch (error) {
      if (mounted) _message('Could not share invoice PDF: $error');
    }
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final uri = await _filesChannel.invokeMethod<String>('saveToDownloads', {
        'fileName': widget.fileName,
        'mimeType': 'application/pdf',
        'bytes': widget.invoiceBytes,
      });
      await ClientVisitDownloads.save(
        userId: widget.userId,
        visitId: 0,
        visitReference: widget.invoiceNumber,
        clientName: 'Service invoice',
        fileName: widget.fileName,
        uri: uri ?? 'Downloads/BBT-HRMS/${widget.fileName}',
      );
      if (!mounted) return;
      setState(() => _downloaded = true);
      _message('Invoice saved in Downloads/BBT-HRMS.');
    } catch (error) {
      if (mounted) _message('Could not download invoice PDF: $error');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => ClientVisitTheme(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Invoice history',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ClientVisitDownloadedFilesScreen(userId: widget.userId),
              ),
            ),
          ),
        ],
      ),
      body: PdfPreview.builder(
        build: (_) async => widget.invoiceBytes,
        pagesBuilder: _pdfPages,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: widget.fileName,
        allowPrinting: true,
        allowSharing: false,
        dpi: 144,
        actions: [
          IconButton(
            tooltip: 'Zoom out',
            onPressed: () => _changeZoom(.8),
            icon: const Icon(Icons.zoom_out_rounded),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: () => _changeZoom(1.25),
            icon: const Icon(Icons.zoom_in_rounded),
          ),
          Tooltip(
            message: _zoomEnabled ? 'Disable zoom mode' : 'Enable zoom mode',
            child: Switch(value: _zoomEnabled, onChanged: _setZoomEnabled),
          ),
        ],
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _downloading || _downloaded ? null : _download,
                icon: _downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _downloaded
                            ? Icons.check_rounded
                            : Icons.download_rounded,
                      ),
                label: Text(_downloaded ? 'Downloaded' : 'Download PDF'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ClientVisitStatusListScreen extends StatefulWidget {
  final String title;
  final String userId;
  final String viewerRole;
  final Set<String> statuses;
  final bool historyMode;
  final Future<void> Function(ClientVisit visit) onOpenVisit;

  const _ClientVisitStatusListScreen({
    required this.title,
    required this.userId,
    required this.viewerRole,
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
    if (!const {'completed', 'rejected'}.contains(visit.status)) return false;
    final role = widget.viewerRole.trim().toLowerCase();
    if (const {'hr', 'ceo', 'md', 'superadmin'}.contains(role)) return true;
    return visit.employeeUserId == widget.userId ||
        visit.managerUserId == widget.userId;
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
    final role = widget.viewerRole.trim().toLowerCase();
    final organizationHistory = const {
      'hr',
      'ceo',
      'md',
      'superadmin',
    }.contains(role);
    if (organizationHistory) {
      return [
        _HistoryHeader(title: 'Completed Visit History', count: visits.length),
        if (visits.isEmpty)
          const _HistoryEmpty('No completed client visits yet.')
        else
          ...visits.map(_visitCard),
      ];
    }
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

class ClientVisitHistoryScreen extends StatelessWidget {
  final String userId;
  final String viewerRole;
  final int initialTab;
  final int? initialVisitId;
  final Future<void> Function(ClientVisit visit)? onOpenVisit;

  const ClientVisitHistoryScreen({
    super.key,
    required this.userId,
    required this.viewerRole,
    this.onOpenVisit,
    this.initialTab = 0,
    this.initialVisitId,
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: initialTab,
    child: ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Visit History'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'History'),
              Tab(
                icon: Icon(Icons.folder_copy_rounded),
                text: 'Downloaded Documents',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CalendarVisitHistoryTab(
              userId: userId,
              viewerRole: viewerRole,
              onOpenVisit: onOpenVisit,
              initialVisitId: initialVisitId,
            ),
            ClientVisitDownloadedFilesScreen(userId: userId, embedded: true),
          ],
        ),
      ),
    ),
  );
}

class _CalendarVisitHistoryTab extends StatefulWidget {
  final String userId;
  final String viewerRole;
  final int? initialVisitId;
  final Future<void> Function(ClientVisit visit)? onOpenVisit;

  const _CalendarVisitHistoryTab({
    required this.userId,
    required this.viewerRole,
    this.onOpenVisit,
    this.initialVisitId,
  });

  @override
  State<_CalendarVisitHistoryTab> createState() =>
      _CalendarVisitHistoryTabState();
}

class _CalendarVisitHistoryTabState extends State<_CalendarVisitHistoryTab> {
  final _service = ClientVisitService();
  List<ClientVisit>? _visits;
  DateTime? _selectedDate;
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
      final visits = result.visits.where(_isVisibleHistoryVisit).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      if (!mounted) return;
      setState(() {
        _visits = visits;
        ClientVisit? initialVisit;
        final initialVisitId = widget.initialVisitId;
        if (initialVisitId != null) {
          for (final visit in visits) {
            if (visit.id == initialVisitId) {
              initialVisit = visit;
              break;
            }
          }
        }
        _selectedDate ??= initialVisit != null
            ? _dateOnly(initialVisit.scheduledAt)
            : visits.isEmpty
            ? DateTime.now()
            : _dateOnly(visits.first.scheduledAt);
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    }
  }

  bool _isVisibleHistoryVisit(ClientVisit visit) {
    if (!const {'completed', 'rejected'}.contains(visit.status)) return false;
    final role = widget.viewerRole.trim().toLowerCase();
    if (const {
      'hr',
      'admin',
      'superadmin',
      'ceo',
      'md',
      'director',
    }.contains(role)) {
      return true;
    }
    return visit.employeeUserId == widget.userId ||
        visit.managerUserId == widget.userId;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  Future<void> _openVisit(ClientVisit visit) async {
    final callback = widget.onOpenVisit;
    if (callback != null) {
      await callback(visit);
      await _load();
      return;
    }

    final role = widget.viewerRole.trim().toLowerCase();
    final ownVisit = visit.employeeUserId == widget.userId;
    final leadershipView = const {
      'hr',
      'admin',
      'superadmin',
      'ceo',
      'md',
      'director',
    }.contains(role);
    final screen = ownVisit && !leadershipView
        ? ClientVisitSummaryScreen(
            userId: widget.userId,
            visitId: visit.id,
            service: _service,
          )
        : ClientVisitReadOnlyFlowScreen(
            userId: widget.userId,
            visitId: visit.id,
            step: 0,
            service: _service,
            viewerRole: role,
          );
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visits = _visits;
    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        text: _error!,
        onRetry: _load,
      );
    }
    if (visits == null || _selectedDate == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = visits
        .where((visit) => _sameDate(visit.scheduledAt, _selectedDate!))
        .toList();
    final selectedLabel =
        '${_selectedDate!.day.toString().padLeft(2, '0')}/'
        '${_selectedDate!.month.toString().padLeft(2, '0')}/'
        '${_selectedDate!.year}';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: CalendarDatePicker(
              key: ValueKey(selectedLabel),
              initialDate: _selectedDate!,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              onDateChanged: (date) =>
                  setState(() => _selectedDate = _dateOnly(date)),
            ),
          ),
          const SizedBox(height: 12),
          _HistoryHeader(
            title: 'Visits on $selectedLabel',
            count: filtered.length,
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const _HistoryEmpty('No completed visits on this date.')
          else
            ...filtered.map(
              (visit) => _VisitCard(
                visit: visit,
                historyViewerUserId: widget.userId,
                onTap: () => _openVisit(visit),
              ),
            ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => ClientVisitDashboardScreen(
    userId: userId,
    title: 'Client Visits',
    roleLabel: roleLabel,
    reviewerMode: reviewerMode,
    readOnlyMode: readOnlyMode,
    allowCreate: allowCreate,
    assignedApprovalsOnly: assignedApprovalsOnly,
    allowVerification: allowVerification,
    requesterRole: requesterRole,
    initialVisitId: initialVisitId,
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
  String? _serviceType;
  int _durationMinutes = 60;
  List<Map<String, dynamic>> _visitApprovers = const [];
  String? _selectedManagerId;
  String? _tlLoadError;
  bool _saving = false;

  bool get _selfApprovingRole => const {
    'admin',
    'superadmin',
    'ceo',
    'md',
    'director',
  }.contains(widget.requesterRole.trim().toLowerCase());

  @override
  void initState() {
    super.initState();
    if (!_selfApprovingRole) _loadReportingTls();
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
    var text = raw.trim();
    try {
      text = Uri.decodeFull(text);
    } on FormatException {
      // Continue with the original value when a shared page contains an
      // incomplete percent-escape sequence.
    }
    if (text.isEmpty) return null;

    // Google Maps URL: contains @lat,lng,zoom or ?q=lat,lng
    final urlLatLng = RegExp(
      r'[/@](-?\d+\.?\d*),(-?\d+\.?\d*)',
    ).firstMatch(text);
    if (urlLatLng != null) {
      final lat = double.tryParse(urlLatLng.group(1)!);
      final lng = double.tryParse(urlLatLng.group(2)!);
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }

    // Google Maps place links often store their exact pin as !3dLAT!4dLNG.
    final dataLatLng = RegExp(
      r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)',
    ).firstMatch(text);
    if (dataLatLng != null) {
      final lat = double.tryParse(dataLatLng.group(1)!);
      final lng = double.tryParse(dataLatLng.group(2)!);
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }

    // Direction/share links can carry q, query, destination, ll or center.
    final queryLatLng = RegExp(
      r'(?:[?&](?:q|query|destination|ll|center)=)(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(text);
    if (queryLatLng != null) {
      final lat = double.tryParse(queryLatLng.group(1)!);
      final lng = double.tryParse(queryLatLng.group(2)!);
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }

    // Decimal degrees: "11.686478, 78.120482" or "11.686478,78.120482"
    final decimal = RegExp(
      r'^(-?\d+\.?\d*)[,\s]+(-?\d+\.?\d*)$',
    ).firstMatch(text);
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
    // Accept Google Maps links; exact coordinates are resolved on submit.
    if (_mapsUrl(text) != null) {
      return null;
    }
    if (_parseCoords(text) == null) {
      return 'Paste a Google Maps link or coordinates (e.g. 11.686478, 78.120482)';
    }
    return null;
  }

  /// Resolves a shortened Google Maps URL (maps.app.goo.gl/...)
  /// by following redirects and extracting the lat/lng from the final URL.
  static Future<({double lat, double lng})?> _resolveShortUrl(
    String url,
  ) async {
    try {
      final extractedUrl = _mapsUrl(url);
      if (extractedUrl == null) return null;
      // Follow the redirect chain (up to 5 hops) without downloading the body
      String current = extractedUrl;
      for (int i = 0; i < 5; i++) {
        final request = http.Request('HEAD', Uri.parse(current))
          ..followRedirects = false;
        final response = await request.send().timeout(
          const Duration(seconds: 8),
        );
        final location = response.headers['location'];
        if (location == null) break;
        current = Uri.parse(current).resolve(location).toString();
        // Try to extract coords from this URL
        final coords = _parseCoords(current);
        if (coords != null) return coords;
      }
      // Last attempt: GET the final URL and look for coords in the body
      final resp = await http
          .get(Uri.parse(current), headers: {'User-Agent': 'HRMS-Bitbyte/1.0'})
          .timeout(const Duration(seconds: 8));
      // Look for @lat,lng pattern in the response body or final URL
      final bodyCoords =
          _parseCoords(resp.request?.url.toString() ?? '') ??
          _parseCoords(resp.body);
      if (bodyCoords != null) return bodyCoords;
      // Scan the HTML body for coordinates
      final match = RegExp(
        r'[/@](-?\d{1,3}\.\d{4,}),(-?\d{1,3}\.\d{4,})',
      ).firstMatch(resp.body);
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

  static String? _mapsUrl(String text) {
    final match = RegExp(
      r'https?://(?:(?:maps\.app\.goo\.gl|goo\.gl/maps)(?:/|\?|$)|(?:www\.)?google\.[a-z.]+/maps(?:/|\?|$)|maps\.google\.[a-z.]+(?:/|\?|$))[^\s]*',
      caseSensitive: false,
    ).firstMatch(text.trim());
    return match?.group(0)?.replaceAll(RegExp(r'[),.;]+$'), '');
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
      if (coords == null && _mapsUrl(rawLocation) != null) {
        coords = await _resolveShortUrl(rawLocation);
      }
      if (rawLocation.isNotEmpty && coords == null) {
        throw Exception(
          'Could not locate this shared Maps link. Check the link and try again.',
        );
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
        'service_type': _serviceType,
        'purpose': _purpose.text.trim(),
        'notes': _notes.text.trim(),
        if (!_selfApprovingRole)
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
                  submit
                      ? (_selfApprovingRole
                            ? 'Visit Created Successfully'
                            : 'Submitted Successfully')
                      : 'Draft Saved',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  submit
                      ? (_selfApprovingRole
                            ? 'Your visit is approved and ready for the scheduled flow.'
                            : 'Your visit request has been submitted for approval.')
                      : 'Your visit request has been saved as a draft.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : () => _submit(true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Saving…'),
                          ],
                        )
                      : Text(
                          _selfApprovingRole
                              ? 'Create visit'
                              : 'Submit request',
                        ),
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
                    helperText: 'Paste a Google Maps share link or coordinates',
                    helperMaxLines: 2,
                    suffixIcon: _locationCoords.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _locationCoords.clear()),
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
                DropdownButtonFormField<String>(
                  initialValue: _serviceType,
                  validator: _required,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    hintText: 'Select the client service',
                  ),
                  items: clientVisitServiceCatalog
                      .map(
                        (service) => DropdownMenuItem<String>(
                          value: service.id,
                          child: Text(
                            '${service.module} • ${service.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _serviceType = value),
                ),
                TextFormField(
                  controller: _purpose,
                  validator: _required,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                ),
                if (!_selfApprovingRole && _visitApprovers.isNotEmpty)
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
                else if (!_selfApprovingRole)
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
                labelText: 'Your signature / OTP name',
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
                    EmployeeInfoRow(
                      'Service',
                      visit.serviceName.isEmpty ? '—' : visit.serviceName,
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
  final int downloadCount;
  final VoidCallback onDownloads;
  final VoidCallback onServices;
  const _Summary({
    required this.summary,
    required this.onInProgress,
    required this.onPendingCheckIn,
    required this.onUpcoming,
    required this.onPendingApproval,
    required this.onHistory,
    required this.downloadCount,
    required this.onDownloads,
    required this.onServices,
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
      const SizedBox(height: 8),
      _wideBox(
        context,
        'Downloaded Documents',
        downloadCount,
        ClientVisitColors.blue,
        onDownloads,
      ),
      const SizedBox(height: 12),
      Text('Services', style: _sectionStyle(context)),
      const SizedBox(height: 7),
      _menuBox(
        context,
        'Services',
        'View Bit Byte service catalogue',
        Icons.design_services_rounded,
        ClientVisitColors.blue,
        onServices,
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

  Widget _menuBox(
    BuildContext context,
    String label,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: EmployeeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ThemeConfig.getTextPrimary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: ThemeConfig.getTextMuted(context),
                    fontSize: 10,
                  ),
                ),
              ],
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

  String get _statusLabel =>
      visit.status == 'approved' ? 'Start to Visit' : _label(visit.status);

  String get _nextActionLabel => switch (visit.status) {
    'draft' => 'Complete request',
    'pending' => 'View request',
    'approved' => 'Start to Visit',
    'travelling' => 'View travel options',
    'in_progress' => 'Continue client visit',
    'completed' => 'View visit summary',
    'rejected' => 'Review requested changes',
    _ => 'Open visit',
  };

  IconData get _nextActionIcon => switch (visit.status) {
    'approved' => Icons.logout_rounded,
    'travelling' => Icons.navigation_rounded,
    'in_progress' => Icons.play_arrow_rounded,
    'completed' => Icons.receipt_long_rounded,
    'rejected' => Icons.edit_note_rounded,
    _ => Icons.arrow_forward_rounded,
  };

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
    final hasPhoto = visit.employeePhotoUrl.isNotEmpty;
    final empName = visit.employeeName.trim();
    final parts = empName.split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : empName.isNotEmpty
        ? empName[0].toUpperCase()
        : '?';

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
                // Top row: employee avatar + client name + status chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee profile photo / initials avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _statusColor.withAlpha(60),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasPhoto
                          ? Image.network(
                              visit.employeePhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: _statusColor,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _statusColor,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Employee name (shown if reviewer/different user)
                          if (empName.isNotEmpty &&
                              visit.employeeUserId != historyViewerUserId)
                            Text(
                              empName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ThemeConfig.getTextMuted(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            visit.clientName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ThemeConfig.getTextPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            visit.visitId,
                            style: TextStyle(
                              fontSize: 11,
                              color: ThemeConfig.getTextMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withAlpha(60)),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                    _detailChip(
                      context,
                      Icons.person_outline,
                      visit.contactPerson,
                    ),
                    _detailChip(
                      context,
                      Icons.calendar_today_outlined,
                      '${visit.scheduledAt.day.toString().padLeft(2, '0')}/'
                      '${visit.scheduledAt.month.toString().padLeft(2, '0')}/'
                      '${visit.scheduledAt.year}  '
                      '${TimeOfDay.fromDateTime(visit.scheduledAt).format(context)}',
                    ),
                    _detailChip(
                      context,
                      Icons.directions_car_outlined,
                      _label(visit.travelMode),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (visit.serviceName.isNotEmpty) ...[
                  Text(
                    visit.serviceName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  visit.purpose,
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConfig.getTextMuted(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_historyDetails.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _historyDetails,
                    style: TextStyle(
                      fontSize: 11,
                      color: ThemeConfig.getTextMuted(context),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Divider(height: 1, color: _statusColor.withAlpha(35)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(_nextActionIcon, size: 16, color: _statusColor),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _nextActionLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailChip(BuildContext context, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: ThemeConfig.getTextMuted(context)),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: ThemeConfig.getTextMuted(context),
        ),
      ),
    ],
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
