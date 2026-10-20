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
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'dart:convert';
import 'client_service_details_cache.dart';
import 'client_visit_models.dart';
import 'client_visit_service_catalog.dart';
import 'client_visit_service.dart';
import 'client_visit_flow_screens.dart';
import 'client_visit_theme.dart';
import 'client_visit_downloads.dart';
import 'client_visit_service_status_screen.dart';
import 'client_visit_team_members.dart';
import 'google_timeline_visit_screen.dart';

bool isLiveTimelineViewerRole(String roleStr, {String team = '', String userId = ''}) {
  final r = roleStr.trim().toLowerCase();
  final t = team.trim().toLowerCase();
  final u = userId.trim().toLowerCase();

  // No timeline in admin (including marketing), development, marketing, or employee
  if (r.contains('admin') ||
      r == 'superadmin' ||
      r.contains('marketing') ||
      r.contains('development') ||
      r.contains('dev') ||
      r == 'employee' ||
      t.contains('dev') ||
      t.contains('development') ||
      t.contains('marketing') ||
      u.contains('admin') ||
      u.contains('bbadm')) {
    return false;
  }

  // Live timeline is ONLY for MD, CEO, TL, ED (when not in development or marketing)
  return r == 'md' ||
      r == 'managing_director' ||
      r == 'managing director' ||
      r == 'ceo' ||
      r == 'chief_executive_officer' ||
      r == 'chief executive officer' ||
      r == 'ed' ||
      r == 'director' ||
      r == 'executive director' ||
      r == 'executive_director' ||
      r == 'tl-dm' ||
      r == 'tl_dm' ||
      r == 'tldm' ||
      r == 'tl' ||
      r == 'team_lead' ||
      r == 'team lead';
}



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
  late String _filter;
  String? _error;
  bool _initialVisitOpened = false;
  int _downloadCount = 0;
  Timer? _statusClock;
  DateTime _calendarDate = DateTime.now();

  bool get _isAdminRole {
    final r = widget.requesterRole.trim().toLowerCase();
    final uid = widget.userId.trim().toLowerCase();
    return r == 'admin' ||
        r == 'superadmin' ||
        r.contains('admin') ||
        uid.contains('admin') ||
        uid.contains('bbadm');
  }

  List<String> get _availableStatuses {
    if (_isAdminRole) {
      return const [
        'my_history',
        'all',
        'pending',
        'approved',
        'travelling',
        'in_progress',
        'completed',
        'rejected',
        'draft',
      ];
    }
    if (isLiveTimelineViewerRole(widget.requesterRole, userId: widget.userId)) {
      return const [
        'live_timeline',
        'my_visits',
        'all',
        'draft',
        'pending',
        'approved',
        'travelling',
        'in_progress',
        'completed',
        'rejected',
      ];
    }
    return const [
      'my_history',
      'my_visits',
      'all',
      'draft',
      'pending',
      'approved',
      'travelling',
      'in_progress',
      'completed',
      'rejected',
    ];
  }

  @override
  void initState() {
    super.initState();
    _filter = _isAdminRole
        ? 'my_history'
        : (isLiveTimelineViewerRole(widget.requesterRole, userId: widget.userId)
            ? 'live_timeline'
            : 'my_history');
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
      final isHistory = _filter == 'history';
      final isMyVisits = _filter == 'my_visits';
      final isLiveTimeline = _filter == 'live_timeline';
      final statusParam = (isHistory || isMyVisits || isLiveTimeline || _filter == 'all') ? '' : _filter;
      final value = await _service.fetchVisits(
        widget.userId,
        status: statusParam,
      );
      if (!mounted) return;
      if (isHistory || isMyVisits) {
        final isLeadership = isLiveTimelineViewerRole(widget.requesterRole) || _isAdminRole;
        if (isLeadership) {
          setState(() => _result = value);
        } else {
          final uid = widget.userId.toLowerCase();
          final filtered = value.visits.where((v) {
            return v.employeeUserId.toLowerCase() == uid ||
                v.managerUserId.toLowerCase() == uid ||
                v.approvedBy.toLowerCase() == uid ||
                v.tlApprovedBy.toLowerCase() == uid ||
                v.employeeName.toLowerCase().contains(uid) ||
                uid.contains('admin') ||
                uid.contains('bbadm');
          }).toList();
          setState(() => _result = ClientVisitListResult(
            filtered.isNotEmpty ? filtered : value.visits,
            value.summary,
          ));
        }
      } else {
        setState(() => _result = value);
      }
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

  bool get _isManagementOrAdmin {
    final role = widget.requesterRole.trim().toLowerCase();
    return role == 'admin' ||
        role == 'superadmin' ||
        role == 'marketing' ||
        role == 'md' ||
        role == 'ed' ||
        role == 'director' ||
        role == 'ceo' ||
        role == 'management';
  }

  Future<void> _openServices() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientVisitServicesScreen(userId: widget.userId),
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
    if (_isAdminRole || widget.requesterRole.trim().toLowerCase().contains('admin')) {
      return ClientVisitTableDetailScreen(
        visit: visit,
        userId: widget.userId,
        viewerRole: widget.requesterRole,
        onRequirementChanged: (newReq) => _load(),
      );
    }
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
    final role = widget.requesterRole.trim().toLowerCase();
    final team = visit.team.trim().toLowerCase();

    final isAdmin = _isAdminRole;

    // MD, CEO, ED, TL should see Live Google Timeline
    // Admin should see the history NOT timeline
    final isLiveTimelineViewer = !isAdmin && isLiveTimelineViewerRole(role, team: team, userId: widget.userId);

    if (isLiveTimelineViewer &&
        (_filter == 'live_timeline' ||
            isLiveTimelineViewerRole(role, team: team, userId: widget.userId))) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GoogleTimelineVisitScreen(
            visit: visit,
            allVisits: _result?.visits ?? [visit],
            userId: widget.userId,
            service: _service,
            initialStaffId: visit.employeeUserId,
            initialStaffName: visit.employeeName,
          ),
        ),
      );
      await _load();
      await _loadDownloads();
      return;
    }

    final isDevVisitOrRole = team == 'development' &&
        (role == 'tl' || role == 'employee' || role == 'hr') &&
        !isLiveTimelineViewer;

    if (visit.status == 'approved' && isDevVisitOrRole) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _employeeFlowScreen(visit)),
      );
      await _load();
      await _loadDownloads();
      return;
    }

    if (_isManagementOrAdmin) {
      final canReview =
          !widget.assignedApprovalsOnly || visit.managerUserId == widget.userId;
      final screen = (visit.status == 'pending' && canReview)
          ? ClientVisitManagerApprovalScreen(
              userId: widget.userId,
              visitId: visit.id,
              service: _service,
            )
          : _monitoringScreen(visit, canVerify: true);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      await _load();
      await _loadDownloads();
      return;
    }

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
              canVerify: widget.allowVerification && canReview &&
                  (widget.requesterRole.trim().toLowerCase() != 'tl' ||
                      visit.managerUserId == widget.userId),
            );
    } else {
      screen = _employeeFlowScreen(visit);
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    await _load();
    await _loadDownloads();
  }

  Future<void> _editRequirementStatus(ClientVisit visit) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = ThemeConfig.isDark(ctx);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2338) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Requirement Status — ${visit.clientName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Update the requirement status for this client visit',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConfig.getTextMuted(ctx),
                  ),
                ),
                const SizedBox(height: 16),
                ...kRequirementStatusOptions.map((opt) {
                  final isCurrent =
                      visit.requirementStatus.trim().toLowerCase() == opt.key;
                  final optColor = Color(opt.colorValue);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(opt.key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? optColor.withAlpha(30)
                              : (isDark
                                  ? Colors.white.withAlpha(8)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? optColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(opt.icon, size: 20, color: optColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isCurrent
                                          ? optColor
                                          : ThemeConfig.getTextPrimary(ctx),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ThemeConfig.getTextMuted(ctx),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Icon(
                                Icons.check_circle_rounded,
                                color: optColor,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != visit.requirementStatus) {
      try {
        final updatedVisit = await _service.updateRequirementStatus(
          widget.userId,
          visit.id,
          selected,
          fallbackVisit: visit,
        );
        if (!mounted) return;
        setState(() {
          final current = _result;
          if (current != null) {
            final idx = current.visits.indexWhere((v) => v.id == visit.id);
            if (idx != -1) {
              final newVisits = List<ClientVisit>.from(current.visits);
              newVisits[idx] = updatedVisit;
              _result = ClientVisitListResult(newVisits, current.summary);
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Requirement status set to "${requirementStatusLabel(selected)}"',
            ),
            backgroundColor: Color(requirementStatusColorValue(selected)),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          final current = _result;
          if (current != null) {
            final idx = current.visits.indexWhere((v) => v.id == visit.id);
            if (idx != -1) {
              final newVisits = List<ClientVisit>.from(current.visits);
              newVisits[idx] = visit.copyWith(requirementStatus: selected);
              _result = ClientVisitListResult(newVisits, current.summary);
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Requirement status set to "${requirementStatusLabel(selected)}"',
            ),
            backgroundColor: Color(requirementStatusColorValue(selected)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatFullDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildDailyCalendarStrip(bool isDark, List<ClientVisit> allVisits) {
    final days = List.generate(7, (i) {
      return _calendarDate.add(Duration(days: i - 3));
    });
    const weekdayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _calendarDate = _calendarDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _calendarDate,
                    firstDate: DateTime(2025, 1, 1),
                    lastDate: DateTime(2027, 12, 31),
                  );
                  if (picked != null) {
                    setState(() {
                      _calendarDate = DateTime(picked.year, picked.month, picked.day);
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 6),
                      Text(
                        _formatFullDate(_calendarDate),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _calendarDate = _calendarDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isSelected = day.year == _calendarDate.year &&
                  day.month == _calendarDate.month &&
                  day.day == _calendarDate.day;
              final now = DateTime.now();
              final isDayToday = day.year == now.year && day.month == now.month && day.day == now.day;
              final hasVisits = allVisits.any((v) {
                final d = v.scheduledAt.toLocal();
                return d.year == day.year && d.month == day.month && d.day == day.day;
              });

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _calendarDate = DateTime(day.year, day.month, day.day);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1687FF)
                            : isDayToday
                                ? const Color(0xFF1687FF).withAlpha(30)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1687FF)
                              : isDayToday
                                  ? const Color(0xFF1687FF)
                                  : (isDark ? Colors.white10 : Colors.grey.shade200),
                          width: isSelected || isDayToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weekdayShort[day.weekday - 1],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : (hasVisits
                                      ? const Color(0xFF10B981)
                                      : (isDayToday ? const Color(0xFF1687FF) : Colors.transparent)),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyVisitsTableView(bool isDark, List<ClientVisit> visits) {
    if (visits.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No visits',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'No visits recorded for ${_formatFullDate(_calendarDate)}.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart_rounded, size: 16, color: Color(0xFF00E5FF)),
                const SizedBox(width: 6),
                Text(
                  'Daily Visit History Table (${visits.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isAdminRole ? 'Role: Admin History' : 'Staff: ${widget.userId}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Scrollable Table
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF162A42) : const Color(0xFFF1F5F9),
              ),
              columnSpacing: 16,
              horizontalMargin: 12,
              headingRowHeight: 40,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columns: [
                const DataColumn(label: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const DataColumn(label: Text('Client & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const DataColumn(label: Text('Requirement Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const DataColumn(label: Text('Visit Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(_isAdminRole ? 'History' : 'Timeline', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: visits.map((v) {
                final reqStatus = v.requirementStatus.trim();
                final hasReq = reqStatus.isNotEmpty;
                final reqLabel = hasReq ? requirementStatusLabel(reqStatus) : 'Not Set';
                final reqColor = Color(hasReq ? requirementStatusColorValue(reqStatus) : 0xFF78909C);
                final statusCol = employeeStatusColor(v.status);
                final staffName = v.employeeName.isNotEmpty ? v.employeeName : widget.userId;

                return DataRow(
                  cells: [
                    // Staff cell
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: const Color(0xFF00E5FF).withAlpha(30),
                            child: Text(
                              staffName.isNotEmpty ? staffName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(staffName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(v.employeeUserId.isNotEmpty ? v.employeeUserId : widget.userId, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Client & Location cell
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(v.clientName.isNotEmpty ? v.clientName : 'Client', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            v.address.isNotEmpty ? v.address : (v.serviceName.isNotEmpty ? v.serviceName : 'Salem'),
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Requirement Status cell
                    DataCell(
                      InkWell(
                        onTap: () => _editRequirementStatus(v),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: reqColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: reqColor.withAlpha(90)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(requirementStatusIcon(reqStatus), size: 12, color: reqColor),
                              const SizedBox(width: 4),
                              Text(
                                reqLabel,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: reqColor),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down, size: 12, color: reqColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Visit status cell
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusCol.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusCol.withAlpha(90)),
                        ),
                        child: Text(
                          _label(v.status),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusCol),
                        ),
                      ),
                    ),
                    // Action cell: History for Admin & others, Timeline ONLY for MD/CEO/TL/ED
                    DataCell(
                      IconButton(
                        icon: Icon(
                          (!_isAdminRole && isLiveTimelineViewerRole(widget.requesterRole, team: v.team, userId: widget.userId))
                              ? Icons.timeline_rounded
                              : Icons.history_rounded,
                          color: (!_isAdminRole && isLiveTimelineViewerRole(widget.requesterRole, team: v.team, userId: widget.userId))
                              ? const Color(0xFF4285F4)
                              : const Color(0xFF10B981),
                          size: 20,
                        ),
                        tooltip: (!_isAdminRole && isLiveTimelineViewerRole(widget.requesterRole, team: v.team, userId: widget.userId))
                            ? 'Google Timeline'
                            : 'My History',
                        onPressed: () {
                          if (!_isAdminRole && isLiveTimelineViewerRole(widget.requesterRole, team: v.team, userId: widget.userId)) {
                            _openVisit(v);
                          } else {
                            _openHistory(initialVisitId: v.id);
                          }
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Structured History Cards
        ...visits.map((v) => _VisitCard(
          visit: v,
          historyViewerUserId: widget.userId,
          viewerRole: widget.requesterRole,
          onTap: () => _openVisit(v),
          onEditRequirementStatus: () => _editRequirementStatus(v),
        )),
      ],
    );
  }

  Widget _buildAdminHistoryHeaderCard(bool isDark, List<ClientVisit> allVisits) {
    final completedCount = allVisits.where((v) => v.status == 'completed').length;
    final totalCount = allVisits.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F766E).withAlpha(isDark ? 55 : 30),
            const Color(0xFF0284C7).withAlpha(isDark ? 35 : 20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF14B8A6).withAlpha(isDark ? 80 : 120),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openHistory(),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'My Visit History',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF14B8A6),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$completedCount / $totalCount COMPLETED',
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF14B8A6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Full individual visits history, daily calendar logs & status reports',
                        style: TextStyle(
                          fontSize: 11,
                          color: ThemeConfig.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
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

  Widget _buildLiveTimelineHeaderCard(bool isDark, List<ClientVisit> allVisits) {
    final inTransitCount = allVisits.where((v) => v.status == 'travelling' || v.status == 'in_progress').length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A73E8).withAlpha(isDark ? 50 : 25),
            const Color(0xFF00E5FF).withAlpha(isDark ? 30 : 15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withAlpha(isDark ? 90 : 50),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GoogleTimelineVisitScreen(
                  visit: allVisits.isNotEmpty ? allVisits.first : null,
                  allVisits: allVisits,
                  userId: widget.userId,
                  service: _service,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A73E8).withAlpha(90),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.timeline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Live Staff Tracking & Google Timeline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  inTransitCount > 0 ? '$inTransitCount ACTIVE' : 'LIVE GPS',
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Live tracking for Marketing & Development teams · 10 Places Google Timeline',
                        style: TextStyle(
                          fontSize: 11,
                          color: ThemeConfig.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Live Tracking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
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
                  children: _availableStatuses.map((status) {
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
              else if (_filter == 'history' || _filter == 'my_history' || _filter == 'my_visits' || _filter == 'live_timeline') ...[
                if ((_isAdminRole || !isLiveTimelineViewerRole(widget.requesterRole, userId: widget.userId)) &&
                    (_filter == 'history' || _filter == 'my_history' || _filter == 'my_visits')) ...[
                  _buildAdminHistoryHeaderCard(ThemeConfig.isDark(context), result.visits),
                  const SizedBox(height: 14),
                ] else if ((_filter == 'live_timeline' || isLiveTimelineViewerRole(widget.requesterRole, userId: widget.userId)) &&
                    !_isAdminRole) ...[
                  _buildLiveTimelineHeaderCard(ThemeConfig.isDark(context), result.visits),
                  const SizedBox(height: 14),
                ],
                _buildDailyCalendarStrip(ThemeConfig.isDark(context), result.visits),
                const SizedBox(height: 14),
                _buildMyVisitsTableView(
                  ThemeConfig.isDark(context),
                  result.visits.where((v) {
                    final d = v.scheduledAt.toLocal();
                    return d.year == _calendarDate.year &&
                        d.month == _calendarDate.month &&
                        d.day == _calendarDate.day;
                  }).toList(),
                ),
              ]
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
                  (visit) => _VisitCard(
                    visit: visit,
                    historyViewerUserId: widget.userId,
                    viewerRole: widget.requesterRole,
                    onTap: () => _openVisit(visit),
                    onEditRequirementStatus: () =>
                        _editRequirementStatus(visit),
                  ),
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
            tooltip: 'Browse services',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => _openServices(clientDetails: const {}),
          ),
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
  final bool isPickerMode;
  final List<String> preSelectedServiceNames;

  const ClientVisitServicesScreen({
    super.key,
    required this.userId,
    this.clientDetailsSyncPending = false,
    this.clientDetails = const <String, dynamic>{},
    this.isPickerMode = false,
    this.preSelectedServiceNames = const <String>[],
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: clientVisitPackageNames.length, vsync: this)
          ..addListener(() {
            if (!_tabController.indexIsChanging) setState(() {});
          });
    if (widget.preSelectedServiceNames.isNotEmpty) {
      for (final service in clientVisitServiceCatalog) {
        if (widget.preSelectedServiceNames.any(
          (name) =>
              name.trim().toLowerCase() == service.name.trim().toLowerCase(),
        )) {
          _selectedServicePackageIndexes[service.id] = 0;
        }
      }
    }
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
              tooltip: 'Client details',
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ClientVisitClientDetailsScreen(userId: widget.userId),
                ),
              ),
            ),
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
              'Tap a card or its checkbox to select or deselect. Tap the service name for details.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeConfig.getTextMuted(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withAlpha(50),
                ),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search services by name or category...',
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF00E5FF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            ...clientVisitServiceCatalog
                .where((service) {
                  if (_searchQuery.isEmpty) return true;
                  return service.name.toLowerCase().contains(_searchQuery) ||
                      service.module.toLowerCase().contains(_searchQuery) ||
                      service.description.toLowerCase().contains(_searchQuery);
                })
                .map((service) => _serviceCard(service, packageIndex)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: widget.isPickerMode
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final selectedNames = clientVisitServiceCatalog
                        .where(
                          (service) => _selectedServicePackageIndexes
                              .containsKey(service.id),
                        )
                        .map((service) => service.name)
                        .toList();
                    Navigator.of(context).pop(selectedNames);
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'Add ${_selectedServicePackageIndexes.length} Services to Visit',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : FilledButton.icon(
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
    final selected = widget.isPickerMode
        ? _selectedServicePackageIndexes.containsKey(service.id)
        : _selectedServicePackageIndexes[service.id] == packageIndex;
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
                const SizedBox(width: 8),
                Checkbox(
                  value: selected,
                  semanticLabel: service.name,
                  activeColor: const Color(0xFF1687FF),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: ThemeConfig.getTextMuted(context),
                    width: 2,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onChanged: (value) =>
                      _toggleService(service.id, packageIndex, value ?? false),
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
            TextButton.icon(
              onPressed: _generating
                  ? null
                  : () => Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('Exit'),
            ),
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
          TextButton.icon(
            onPressed: _downloading
                ? null
                : () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.exit_to_app_rounded),
            label: const Text('Exit'),
          ),
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
    if (const {'admin', 'hr', 'ceo', 'tl', 'md', 'superadmin'}.contains(role)) return true;
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
      'tl',
      'admin',
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

  Future<void> _editRequirementStatus(ClientVisit visit) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = ThemeConfig.isDark(ctx);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2338) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set Requirement — ${visit.clientName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Select requirement status to update for this client visit',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConfig.getTextMuted(ctx),
                  ),
                ),
                const SizedBox(height: 16),
                ...kRequirementStatusOptions.map((opt) {
                  final isCurrent =
                      visit.requirementStatus.trim().toLowerCase() == opt.key;
                  final optColor = Color(opt.colorValue);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(opt.key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? optColor.withAlpha(30)
                              : (isDark
                                  ? Colors.white.withAlpha(8)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? optColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(opt.icon, size: 20, color: optColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isCurrent
                                          ? optColor
                                          : ThemeConfig.getTextPrimary(ctx),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ThemeConfig.getTextMuted(ctx),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Icon(
                                Icons.check_circle_rounded,
                                color: optColor,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != visit.requirementStatus) {
      try {
        final updatedVisit = await _service.updateRequirementStatus(
          widget.userId,
          visit.id,
          selected,
          fallbackVisit: visit,
        );
        if (!mounted) return;
        setState(() {
          final idx = _visits?.indexWhere((v) => v.id == visit.id) ?? -1;
          if (idx != -1) {
            final list = List<ClientVisit>.from(_visits!);
            list[idx] = updatedVisit;
            _visits = list;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Requirement status set to "${requirementStatusLabel(selected)}"',
            ),
            backgroundColor: Color(requirementStatusColorValue(selected)),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          final idx = _visits?.indexWhere((v) => v.id == visit.id) ?? -1;
          if (idx != -1) {
            final list = List<ClientVisit>.from(_visits!);
            list[idx] = visit.copyWith(requirementStatus: selected);
            _visits = list;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Requirement status set to "${requirementStatusLabel(selected)}"',
            ),
            backgroundColor: Color(requirementStatusColorValue(selected)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _visitCard(ClientVisit visit) => _VisitCard(
    visit: visit,
    historyViewerUserId: widget.historyMode ? widget.userId : '',
    viewerRole: widget.viewerRole,
    onTap: () async {
      await widget.onOpenVisit(visit);
      await _load();
    },
    onEditRequirementStatus: () => _editRequirementStatus(visit),
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ClientVisit>? _visits;
  DateTime? _selectedDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final today = _dateOnly(DateTime.now());
        if (_selectedDate == null) {
          if (initialVisit != null) {
            _selectedDate = _dateOnly(initialVisit.scheduledAt);
          } else if (visits.any((v) => _sameDate(v.scheduledAt, today))) {
            _selectedDate = today;
          } else if (visits.isNotEmpty) {
            _selectedDate = _dateOnly(visits.first.scheduledAt);
          } else {
            _selectedDate = today;
          }
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    }
  }

  bool _isVisibleHistoryVisit(ClientVisit visit) {
    final role = widget.viewerRole.trim().toLowerCase();
    final uid = widget.userId.trim().toLowerCase();
    final isAdmin = role.contains('admin') ||
        role == 'superadmin' ||
        uid.contains('admin') ||
        uid.contains('bbadm');

    if (isAdmin) {
      return true;
    }

    if (const {
      'tl',
      'hr',
      'ceo',
      'md',
      'ed',
      'director',
    }.contains(role)) {
      return true;
    }

    return visit.employeeUserId.toLowerCase() == uid ||
        visit.managerUserId.toLowerCase() == uid ||
        role.isEmpty;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  bool _isLeadershipReadOnly(String role) {
    final r = role.trim().toLowerCase();
    return r == 'md' ||
        r == 'managing_director' ||
        r == 'managing director' ||
        r == 'ceo' ||
        r == 'chief_executive_officer' ||
        r == 'chief executive officer' ||
        r == 'ed' ||
        r == 'director' ||
        r == 'executive director' ||
        r == 'executive_director' ||
        r == 'tl' ||
        r == 'tl-dm' ||
        r == 'tl_dm' ||
        r == 'tldm' ||
        r == 'team_lead' ||
        r == 'team lead';
  }

  Future<void> _editRequirementStatus(ClientVisit visit) async {
    if (_isLeadershipReadOnly(widget.viewerRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'View-only: Requirement status is managed by Admin and Development team.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Color(0xFF0F2338),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = ThemeConfig.isDark(ctx);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2338) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set Requirement — ${visit.clientName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Select requirement status to update for this client visit',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConfig.getTextMuted(ctx),
                  ),
                ),
                const SizedBox(height: 16),
                ...kRequirementStatusOptions.map((opt) {
                  final isCurrent =
                      visit.requirementStatus.trim().toLowerCase() == opt.key;
                  final optColor = Color(opt.colorValue);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(opt.key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? optColor.withAlpha(30)
                              : (isDark
                                  ? Colors.white.withAlpha(8)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? optColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(opt.icon, size: 20, color: optColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isCurrent
                                          ? optColor
                                          : ThemeConfig.getTextPrimary(ctx),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ThemeConfig.getTextMuted(ctx),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Icon(
                                Icons.check_circle_rounded,
                                color: optColor,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != visit.requirementStatus) {
      try {
        final updatedVisit = await _service.updateRequirementStatus(
          widget.userId,
          visit.id,
          selected,
          fallbackVisit: visit,
        );
        if (!mounted) return;
        setState(() {
          final idx = _visits?.indexWhere((v) => v.id == visit.id) ?? -1;
          if (idx != -1) {
            final list = List<ClientVisit>.from(_visits!);
            list[idx] = updatedVisit;
            _visits = list;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Requirement status set to "${requirementStatusLabel(selected)}"',
            ),
            backgroundColor: Color(requirementStatusColorValue(selected)),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          final idx = _visits?.indexWhere((v) => v.id == visit.id) ?? -1;
          if (idx != -1) {
            final list = List<ClientVisit>.from(_visits!);
            list[idx] = visit.copyWith(requirementStatus: selected);
            _visits = list;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Requirement status set to "${requirementStatusLabel(selected)}"',
            ),
            backgroundColor: Color(requirementStatusColorValue(selected)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openVisit(ClientVisit visit) async {
    final callback = widget.onOpenVisit;
    if (callback != null) {
      await callback(visit);
      await _load();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientVisitTableDetailScreen(
          visit: visit,
          userId: widget.userId,
          viewerRole: widget.viewerRole,
          onRequirementChanged: (_) => _load(),
        ),
      ),
    );
    await _load();
  }

  Widget _buildHistoryTableView(
    bool isDark,
    List<ClientVisit> displayVisits,
    String title,
  ) {
    if (displayVisits.isEmpty) {
      return const _HistoryEmpty('No visits found.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${displayVisits.length} Visits',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF162A42) : const Color(0xFFF1F5F9),
              ),
              columnSpacing: 16,
              horizontalMargin: 12,
              headingRowHeight: 40,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 88,
              columns: const [
                DataColumn(
                  label: Text(
                    'Client Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Staff / Admin',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Requirement Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Final Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Table Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
              rows: displayVisits.map((v) {
                final reqStatus = v.requirementStatus.trim();
                final hasReq = reqStatus.isNotEmpty;
                final reqLabel = hasReq
                    ? requirementStatusLabel(reqStatus)
                    : 'Set Requirement';
                final reqColor = Color(
                  hasReq
                      ? requirementStatusColorValue(reqStatus)
                      : 0xFF00E5FF,
                );
                final reqIcon = hasReq
                    ? requirementStatusIcon(reqStatus)
                    : Icons.add_circle_outline_rounded;
                final statusCol = employeeStatusColor(v.status);
                final staffName = v.employeeName.isNotEmpty
                    ? v.employeeName
                    : widget.userId;

                return DataRow(
                  cells: [
                    // Client Details cell (Client name, code, contact, service, address, requirement badge)
                    DataCell(
                      InkWell(
                        onTap: () => _openVisit(v),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    v.clientName.isNotEmpty ? v.clientName : 'Client',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (v.visitId.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      v.visitId,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: ThemeConfig.getTextMuted(context),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${v.contactPerson} · ${v.contactPhone}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              if (v.serviceName.isNotEmpty)
                                Text(
                                  v.serviceName,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF00E5FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                v.address,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Requirement Status directly visible and editable here!
                              InkWell(
                                onTap: () => _editRequirementStatus(v),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: reqColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: reqColor.withAlpha(90),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        reqIcon,
                                        size: 11,
                                        color: reqColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        reqLabel,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: reqColor,
                                        ),
                                      ),
                                      if (!_isLeadershipReadOnly(widget.viewerRole)) ...[
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 13,
                                          color: reqColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Staff / Admin cell
                    DataCell(
                      InkWell(
                        onTap: () => _openVisit(v),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              staffName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${v.employeeUserId} · ${_label(v.team.isNotEmpty ? v.team : "Admin")}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            Text(
                              v.approvedBy.isNotEmpty
                                  ? 'Admin: ${v.approvedBy}'
                                  : (v.tlApprovedBy.isNotEmpty
                                      ? 'TL: ${v.tlApprovedBy}'
                                      : 'Manager: ${v.managerUserId}'),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Requirement Status cell (Interactive & Editable!)
                    DataCell(
                      InkWell(
                        onTap: () => _editRequirementStatus(v),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: reqColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: reqColor.withAlpha(90)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reqIcon,
                                size: 12,
                                color: reqColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                reqLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: reqColor,
                                ),
                              ),
                              if (!_isLeadershipReadOnly(widget.viewerRole)) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 12,
                                  color: reqColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Final Status cell
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusCol.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusCol.withAlpha(90)),
                        ),
                        child: Text(
                          _label(v.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusCol,
                          ),
                        ),
                      ),
                    ),
                    // Action cell: View Table Details
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.table_view_rounded, size: 14),
                        label: const Text(
                          'View Table',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _openVisit(v),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
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

    final isSearching = _searchQuery.isNotEmpty;
    final searchLower = _searchQuery.toLowerCase();
    final searchResults = isSearching
        ? visits.where((v) {
            final clientName = v.clientName.toLowerCase();
            final visitId = v.visitId.toLowerCase();
            final contact = v.contactPerson.toLowerCase();
            final phone = v.contactPhone.toLowerCase();
            final address = v.address.toLowerCase();
            final loc = v.location.toLowerCase();
            final service = v.serviceName.toLowerCase();
            final status = v.status.toLowerCase();
            final req = v.requirementStatus.toLowerCase();
            final reqLabel = requirementStatusLabel(v.requirementStatus).toLowerCase();
            final staff = v.employeeName.toLowerCase();
            return clientName.contains(searchLower) ||
                visitId.contains(searchLower) ||
                contact.contains(searchLower) ||
                phone.contains(searchLower) ||
                address.contains(searchLower) ||
                loc.contains(searchLower) ||
                service.contains(searchLower) ||
                status.contains(searchLower) ||
                req.contains(searchLower) ||
                reqLabel.contains(searchLower) ||
                staff.contains(searchLower);
          }).toList()
        : const <ClientVisit>[];

    final filtered = visits
        .where((visit) => _sameDate(visit.scheduledAt, _selectedDate!))
        .toList();
    final selectedLabel =
        '${_selectedDate!.day.toString().padLeft(2, '0')}/'
        '${_selectedDate!.month.toString().padLeft(2, '0')}/'
        '${_selectedDate!.year}';

    final isDark = ThemeConfig.isDark(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // 1. Search Bar at Top
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2338) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _searchQuery.isNotEmpty
                    ? const Color(0xFF00E5FF)
                    : (isDark ? Colors.white12 : Colors.grey.shade300),
                width: _searchQuery.isNotEmpty ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search visits (client, ID, phone, status...)',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: ThemeConfig.getTextMuted(context),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF00E5FF),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // 2. Search Results View (when query is active)
          if (isSearching) ...[
            if (searchResults.isNotEmpty)
              _buildHistoryTableView(
                isDark,
                searchResults,
                'Search Results for "$_searchQuery"',
              )
            else
              Card(
                color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No visits matching "$_searchQuery"',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try searching by client name, visit ID, phone, or status',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeConfig.getTextMuted(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear search'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ] else ...[
            // Quick Jump Action Bar (Today / Latest / Refresh)
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(
                    Icons.today_rounded,
                    size: 14,
                    color: Color(0xFF00E5FF),
                  ),
                  label: const Text(
                    'Today',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _sameDate(_selectedDate!, DateTime.now())
                      ? const Color(0xFF00E5FF).withAlpha(35)
                      : (isDark ? const Color(0xFF0F2338) : Colors.white),
                  side: BorderSide(
                    color: _sameDate(_selectedDate!, DateTime.now())
                        ? const Color(0xFF00E5FF)
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  onPressed: () {
                    setState(() => _selectedDate = _dateOnly(DateTime.now()));
                  },
                ),
                const SizedBox(width: 8),
                if (visits.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(
                      Icons.access_time_filled_rounded,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                    label: const Text(
                      'Latest Visit',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _sameDate(_selectedDate!, visits.first.scheduledAt)
                        ? const Color(0xFF10B981).withAlpha(35)
                        : (isDark ? const Color(0xFF0F2338) : Colors.white),
                    side: BorderSide(
                      color: _sameDate(_selectedDate!, visits.first.scheduledAt)
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    onPressed: () {
                      setState(() => _selectedDate = _dateOnly(visits.first.scheduledAt));
                    },
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh visits',
                  onPressed: _load,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Calendar Card
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
            const SizedBox(height: 14),

            // Visits on Selected Date
            _buildHistoryTableView(
              isDark,
              filtered,
              'Visits on $selectedLabel in Table Format',
            ),
            const SizedBox(height: 20),

            // All Visits History Table
            if (filtered.isEmpty || visits.length > filtered.length) ...[
              const Divider(),
              const SizedBox(height: 10),
              _buildHistoryTableView(
                isDark,
                visits,
                'All Visit History in Table Format',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class ClientVisitTableDetailScreen extends StatefulWidget {
  final ClientVisit visit;
  final String userId;
  final String viewerRole;
  final ValueChanged<String>? onRequirementChanged;

  const ClientVisitTableDetailScreen({
    super.key,
    required this.visit,
    required this.userId,
    this.viewerRole = '',
    this.onRequirementChanged,
  });

  @override
  State<ClientVisitTableDetailScreen> createState() =>
      _ClientVisitTableDetailScreenState();
}

class _ClientVisitTableDetailScreenState
    extends State<ClientVisitTableDetailScreen> {
  final _service = ClientVisitService();
  late ClientVisit _visit;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _visit = widget.visit;
  }

  String _resolveRequirementStatus(ClientVisit visit) {
    var s = visit.requirementStatus.trim();
    if (s.isNotEmpty && s.toLowerCase() != 'null') return s;

    // Check checklist items for status
    for (final item in visit.checklist) {
      if (item is Map && item['status'] != null) {
        final st = '${item['status']}'.trim();
        if (st.isNotEmpty && st.toLowerCase() != 'null') return st;
      }
    }

    // Check outcome text for status
    final outcomeStr = visit.outcome;
    if (outcomeStr.isNotEmpty) {
      final match = RegExp(
        r'Customer Requirement Status:\s*([^(\n\r]+)',
        caseSensitive: false,
      ).firstMatch(outcomeStr);
      if (match != null) {
        final val = match.group(1)?.trim() ?? '';
        if (val.isNotEmpty && val.toLowerCase() != 'null') return val;
      }
    }

    // Check notes
    final notesStr = visit.notes;
    if (notesStr.isNotEmpty) {
      final match = RegExp(
        r'(?:Requirement\s*)?Status:\s*([A-Za-z\s]+)',
        caseSensitive: false,
      ).firstMatch(notesStr);
      if (match != null) {
        final val = match.group(1)?.trim() ?? '';
        if (val.isNotEmpty && val.toLowerCase() != 'null') return val;
      }
    }

    return '';
  }

  Widget _buildTableSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<MapEntry<String, dynamic>> items,
    bool isDark = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(isDark ? 80 : 120),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 35 : 20),
              border: Border(
                bottom: BorderSide(color: color.withAlpha(isDark ? 60 : 80)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2.0),
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                width: 0.8,
              ),
            ),
            children: items.map((entry) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: entry.value is Widget
                        ? entry.value as Widget
                        : Text(
                            '${entry.value}'.isEmpty ? '—' : '${entry.value}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final statusColor = employeeStatusColor(_visit.status);
    final reqStatus = _resolveRequirementStatus(_visit);
    final hasReq = reqStatus.isNotEmpty;
    final reqLabel = hasReq
        ? requirementStatusLabel(reqStatus)
        : 'Not Specified';
    final reqColor = Color(
      hasReq ? requirementStatusColorValue(reqStatus) : 0xFF64748B,
    );
    final reqIcon = hasReq
        ? requirementStatusIcon(reqStatus)
        : Icons.remove_circle_outline_rounded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Visit Details (Table)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () async {
              setState(() => _updating = true);
              try {
                final v = await _service.fetchVisit(widget.userId, _visit.id);
                if (mounted) {
                  setState(() {
                    _visit = v;
                    _updating = false;
                  });
                }
              } catch (_) {
                if (mounted) setState(() => _updating = false);
              }
            },
          ),
        ],
      ),
      body: _updating
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Header badge card
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withAlpha(isDark ? 80 : 120),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: statusColor.withAlpha(30),
                        child: Text(
                          _visit.clientName.isNotEmpty
                              ? _visit.clientName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _visit.clientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _visit.visitId,
                              style: TextStyle(
                                fontSize: 11,
                                color: ThemeConfig.getTextMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _label(_visit.status).toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table 1: All details from client
                _buildTableSection(
                  context: context,
                  title: 'All Details from Client',
                  icon: Icons.business_rounded,
                  color: const Color(0xFF0D9488),
                  isDark: isDark,
                  items: [
                    MapEntry('Client Name', _visit.clientName),
                    MapEntry('Contact Person', _visit.contactPerson),
                    MapEntry('Contact Phone', _visit.contactPhone),
                    MapEntry(
                      'Email ID',
                      _visit.clientEmail.isNotEmpty ? _visit.clientEmail : '—',
                    ),
                    MapEntry('Address', _visit.address),
                    MapEntry(
                      'Location / City',
                      _visit.location.isNotEmpty ? _visit.location : 'Salem',
                    ),
                    MapEntry(
                      'Service Required',
                      _visit.serviceName.isNotEmpty ? _visit.serviceName : '—',
                    ),
                    MapEntry('Purpose of Visit', _visit.purpose),
                    MapEntry(
                      'Scheduled Date & Time',
                      '${_ymd(_visit.scheduledAt)} ${TimeOfDay.fromDateTime(_visit.scheduledAt).format(context)}',
                    ),
                    MapEntry(
                      'Planned Duration',
                      '${_visit.durationMinutes} mins',
                    ),
                    MapEntry('Travel Mode', _label(_visit.travelMode)),
                    MapEntry(
                      'Client Notes',
                      _visit.notes.isNotEmpty ? _visit.notes : '—',
                    ),
                  ],
                ),

                // Table 2: Admin details
                _buildTableSection(
                  context: context,
                  title: 'Admin & Staff Details',
                  icon: Icons.badge_rounded,
                  color: const Color(0xFF0284C7),
                  isDark: isDark,
                  items: [
                    MapEntry(
                      'Staff / Admin Name',
                      _visit.employeeName.isNotEmpty
                          ? _visit.employeeName
                          : widget.userId,
                    ),
                    MapEntry('Employee / Admin ID', _visit.employeeUserId),
                    MapEntry(
                      'Department / Team',
                      _visit.team.isNotEmpty
                          ? _label(_visit.team)
                          : 'Marketing',
                    ),
                    MapEntry(
                      'Manager User ID',
                      _visit.managerUserId.isNotEmpty
                          ? _visit.managerUserId
                          : '—',
                    ),
                    MapEntry(
                      'Approved By',
                      _visit.approvedByName.isNotEmpty
                          ? _visit.approvedByName
                          : (_visit.approvedBy.isNotEmpty
                                ? _visit.approvedBy
                                : '—'),
                    ),
                    MapEntry(
                      'Approval Role',
                      _visit.approvedByRole.isNotEmpty
                          ? _visit.approvedByRole.toUpperCase()
                          : 'ADMIN',
                    ),
                    MapEntry(
                      'Approval Comment',
                      _visit.approvalComment.isNotEmpty
                          ? _visit.approvalComment
                          : 'Approved',
                    ),
                    MapEntry(
                      'Approval Date',
                      _visit.approvedAt != null
                          ? _ymd(_visit.approvedAt!)
                          : '—',
                    ),
                  ],
                ),

                // Table 3: Final status & Execution
                _buildTableSection(
                  context: context,
                  title: 'Final Status & Execution',
                  icon: Icons.fact_check_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  items: [
                    MapEntry(
                      'Final Visit Status',
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withAlpha(90)),
                        ),
                        child: Text(
                          _label(_visit.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                    MapEntry(
                      'Requirement Status',
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: reqColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: reqColor.withAlpha(90)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(reqIcon, size: 14, color: reqColor),
                            const SizedBox(width: 5),
                            Text(
                              reqLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: reqColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    MapEntry(
                      'Reached Client At',
                      _visit.reachedClientAt != null
                          ? '${_ymd(_visit.reachedClientAt!)} ${TimeOfDay.fromDateTime(_visit.reachedClientAt!).format(context)}'
                          : '—',
                    ),
                    MapEntry(
                      'Check-Out / Completed At',
                      _visit.checkOutAt != null
                          ? '${_ymd(_visit.checkOutAt!)} ${TimeOfDay.fromDateTime(_visit.checkOutAt!).format(context)}'
                          : '—',
                    ),
                    MapEntry(
                      'Total Expenses',
                      '₹${_visit.expenseTotal.toStringAsFixed(2)}',
                    ),
                    MapEntry(
                      'Proof Files Attached',
                      '${_visit.attachments.length} files attached',
                    ),
                    MapEntry(
                      'Final Outcome / Notes',
                      _visit.outcome.isNotEmpty
                          ? _visit.outcome
                          : (_visit.followUp.isNotEmpty
                                ? _visit.followUp
                                : '—'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
  final String roleLabel;
  final String initialTeam;

  const ClientVisitCreateScreen({
    super.key,
    required this.userId,
    required this.service,
    this.requesterRole = '',
    this.roleLabel = '',
    this.initialTeam = 'marketing',
  });

  @override
  State<ClientVisitCreateScreen> createState() => _ClientVisitCreateScreenState();
}

class _ClientVisitCreateScreenState extends State<ClientVisitCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _client = TextEditingController();
  final _industry = TextEditingController();
  final _location = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _contact = TextEditingController();
  final _locationCoords = TextEditingController(); // paste coords from WhatsApp
  final _purpose = TextEditingController();
  final _notes = TextEditingController();
  final _manager = TextEditingController();
  ({double lat, double lng})? _selectedCoords;
  bool _locating = false;
  bool _resolvingUrl = false;
  final MapController _mapController = MapController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _travelMode = 'car';
  String? _serviceType;
  String? _selectedManagerId;
  bool _saving = false;

  bool get _selfApprovingRole => const {
    'admin',
    'superadmin',
    'ceo',
    'md',
    'director',
  }.contains(widget.requesterRole.trim().toLowerCase());

  late String _selectedTeam;
  final Set<String> _selectedMemberIds = <String>{};
  final Set<String> _selectedCreativeServices = <String>{};
  bool _servicesExpanded = true;
  bool _timelineSectionExpanded = true;
  final Set<String> _expandedServiceCategories = <String>{
    'CREATIVE STUDIO',
    'SOCIAL MEDIA MARKETING',
    'SEO SERVICES',
    'PAID ADVERTISING',
    'WEB APP DEVELOPMENT',
  };
  String _selectedCategoryFilter = 'all';

  static const List<({String title, IconData icon, String desc})> _creativeStudioItems = [
    (title: 'Photo Design', icon: Icons.photo_camera_back_rounded, desc: 'Commercial photography & image assets'),
    (title: 'Video Design', icon: Icons.videocam_rounded, desc: 'Promo videos, reels, motion graphics'),
    (title: 'Ad Creative Design', icon: Icons.campaign_rounded, desc: 'Meta/Google display ads & banners'),
    (title: 'Brand Logo Design', icon: Icons.brush_rounded, desc: 'Custom vectors, logo marks & typography'),
    (title: 'Brand Identity Kit', icon: Icons.palette_rounded, desc: 'Color palettes, style guides & collateral'),
  ];
  static const List<({String title, IconData icon, String desc})> _socialMediaMarketingItems = [
    (title: 'Social Media Account Handling', icon: Icons.manage_accounts_rounded, desc: 'Account management, content curation & posting'),
    (title: 'Meta Ads Campaign', icon: Icons.ads_click_rounded, desc: 'Targeted Facebook & Instagram ad campaigns'),
    (title: 'Ad Copywriting', icon: Icons.edit_note_rounded, desc: 'High-converting ad copies & creative scripts'),
    (title: 'WhatsApp Campaign', icon: Icons.mark_chat_unread_rounded, desc: 'Broadcast promotions & targeted messaging'),
    (title: 'WhatsApp Automation / Chatbot Setup', icon: Icons.smart_toy_rounded, desc: 'Automated chatbots, flows & instant reply setup'),
  ];
  static const List<({String title, IconData icon, String desc})> _seoServicesItems = [
    (title: 'Basic SEO', icon: Icons.search_rounded, desc: 'On-page optimization & basic keyword setup'),
    (title: 'Advanced SEO', icon: Icons.manage_search_rounded, desc: 'Technical SEO, deep audits & backlink indexing'),
    (title: 'Enterprise SEO', icon: Icons.business_rounded, desc: 'Large-scale architecture, multi-page indexing'),
    (title: 'Local SEO', icon: Icons.pin_drop_rounded, desc: 'Google Business Profile & local citation ranking'),
    (title: 'SEO Content Writing', icon: Icons.article_rounded, desc: 'Keyword-focused SEO articles & blogs'),
    (title: 'Competitor Analysis Report', icon: Icons.analytics_rounded, desc: 'Comprehensive domain & competitor rank analysis'),
  ];
  static const List<({String title, IconData icon, String desc})> _paidAdvertisingItems = [
    (title: 'Google Ads Campaign', icon: Icons.ads_click_rounded, desc: 'Search, display & video advertising campaigns'),
    (title: 'Conversion Tracking Setup', icon: Icons.track_changes_rounded, desc: 'Google Tag Manager & pixel event tracking setup'),
  ];
  static const List<({String title, IconData icon, String desc})> _webAppDevelopmentItems = [
    (title: 'Basic Website Design', icon: Icons.web_asset_rounded, desc: 'Standard informative business landing pages'),
    (title: 'Advanced Website Design', icon: Icons.laptop_chromebook_rounded, desc: 'Custom UX/UI with interactive animations'),
    (title: 'Dynamic Website', icon: Icons.dynamic_feed_rounded, desc: 'Database-driven web application with CMS'),
    (title: 'E-Commerce Website', icon: Icons.shopping_cart_rounded, desc: 'Full online store, payment gateway & catalogue'),
    (title: 'Website Maintenance', icon: Icons.build_circle_rounded, desc: 'Security updates, backups & uptime monitoring'),
    (title: 'Website Speed Optimization', icon: Icons.speed_rounded, desc: 'Core Web Vitals, caching & performance tuning'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.initialTeam.isNotEmpty ? widget.initialTeam : 'marketing';
    final initialMembers = getTeamMembersFor(_selectedTeam);
    _selectedMemberIds.addAll(initialMembers.map((m) => m.id));
  }

  @override
  void dispose() {
    _mapController.dispose();
    for (final value in [
      _client,
      _industry,
      _location,
      _email,
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

  void _onLocationInputChanged(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _selectedCoords = null);
      return;
    }
    final direct = _parseCoords(trimmed);
    if (direct != null) {
      setState(() => _selectedCoords = direct);
      try {
        _mapController.move(ll.LatLng(direct.lat, direct.lng), 15);
      } catch (_) {}
      return;
    }
    final url = _mapsUrl(trimmed);
    if (url != null) {
      _resolveUrlAsync(url);
    }
  }

  Future<void> _resolveUrlAsync(String url) async {
    setState(() => _resolvingUrl = true);
    try {
      final resolved = await _resolveShortUrl(url);
      if (resolved != null && mounted) {
        setState(() => _selectedCoords = resolved);
        try {
          _mapController.move(ll.LatLng(resolved.lat, resolved.lng), 15);
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _resolvingUrl = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _snack(context, 'Location permission is required.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final coords = (lat: pos.latitude, lng: pos.longitude);
      if (!mounted) return;
      setState(() {
        _selectedCoords = coords;
        _locationCoords.text =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
      try {
        _mapController.move(ll.LatLng(coords.lat, coords.lng), 16);
      } catch (_) {}

      // Auto-fetch city & address
      try {
        final resp = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json'),
          headers: {'User-Agent': 'HRMS-Bitbyte/1.0'},
        ).timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final addr = data['address'] as Map<String, dynamic>?;
          if (addr != null && mounted) {
            final city = addr['city'] ?? addr['town'] ?? addr['suburb'] ?? addr['county'] ?? addr['state_district'] ?? '';
            final state = addr['state'] ?? '';
            final fullCity = [city, state].where((s) => s.toString().isNotEmpty).join(', ');
            setState(() {
              if (fullCity.isNotEmpty) {
                _location.text = fullCity;
              } else if (data['name'] != null && data['name'].toString().isNotEmpty) {
                _location.text = data['name'].toString();
              } else {
                _location.text = 'Salem, Tamil Nadu';
              }
              if (data['display_name'] != null) {
                _address.text = data['display_name'].toString();
              }
            });
          }
        }
      } catch (_) {}

      if (_location.text.isEmpty) {
        setState(() => _location.text = 'Salem, Tamil Nadu');
      }

      try {
        _mapController.move(ll.LatLng(coords.lat, coords.lng), 16);
      } catch (_) {}

      if (mounted) {
        _snack(
          context,
          'Current Location pinned on map (${coords.lat.toStringAsFixed(4)}, ${coords.lng.toStringAsFixed(4)})',
        );
      }
    } catch (e) {
      if (mounted) _snack(context, 'Could not get current location: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapTap(ll.LatLng point) {
    final coords = (lat: point.latitude, lng: point.longitude);
    setState(() {
      _selectedCoords = coords;
      _locationCoords.text =
          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
    });
  }

  Widget _buildMapSection() {
    final center = _selectedCoords != null
        ? ll.LatLng(_selectedCoords!.lat, _selectedCoords!.lng)
        : const ll.LatLng(11.6643, 78.1460); // Default to Salem, TN

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          _selectedCoords != null
              ? 'Pinned: ${_selectedCoords!.lat.toStringAsFixed(4)}, ${_selectedCoords!.lng.toStringAsFixed(4)}'
              : 'Tap map to drop pin',
          style: TextStyle(
            fontSize: 12,
            color: _selectedCoords != null
                ? const Color(0xFF00E5FF)
                : Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedCoords != null
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                  : Colors.white24,
              width: _selectedCoords != null ? 2.0 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _selectedCoords != null ? 16 : 12,
                  onTap: (tapPosition, point) => _onMapTap(point),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bitbyte.hrms',
                    maxNativeZoom: 19,
                  ),
                  if (_selectedCoords != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: ll.LatLng(
                            _selectedCoords!.lat,
                            _selectedCoords!.lng,
                          ),
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 42,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: FloatingActionButton.small(
                  heroTag: 'map_gps_locate_btn',
                  onPressed: _locating ? null : _useCurrentLocation,
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  tooltip: 'Center on my GPS',
                  child: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _emailValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
    return null;
  }

  static ({double lat, double lng})? _parseCoords(String raw) {
    final text = raw.trim();
    final atMatch = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(text);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }
    final qMatch = RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(text);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }
    final simpleMatch = RegExp(r'^(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)$').firstMatch(text);
    if (simpleMatch != null) {
      final lat = double.tryParse(simpleMatch.group(1)!);
      final lng = double.tryParse(simpleMatch.group(2)!);
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }
    return null;
  }

  String? _validateCoords(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final direct = _parseCoords(trimmed);
    if (direct != null) return null;
    final url = _mapsUrl(trimmed);
    if (url != null) return null;
    return 'Enter coordinates as "lat, lng" or paste Google Maps link';
  }

  static Future<({double lat, double lng})?> _resolveShortUrl(
    String shortUrl,
  ) async {
    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(shortUrl))
          ..followRedirects = false;
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 8));
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          final coords = _parseCoords(location);
          if (coords != null) return coords;
          if (location.startsWith('http')) {
            final deepReq = http.Request('GET', Uri.parse(location))
              ..followRedirects = true;
            final deepResp = await client
                .send(deepReq)
                .timeout(const Duration(seconds: 8));
            final deepLocation =
                deepResp.headers['location'] ??
                deepResp.request?.url.toString() ??
                '';
            final deepCoords = _parseCoords(deepLocation);
            if (deepCoords != null) return deepCoords;
          }
        }
      } finally {
        client.close();
      }
    } catch (_) {}
    return null;
  }

  static String? _mapsUrl(String text) {
    final match = RegExp(r'https?://[^\s]+').firstMatch(text);
    if (match == null) return null;
    final url = match.group(0)!;
    if (url.contains('maps.app.goo.gl') ||
        url.contains('goo.gl/maps') ||
        url.contains('google.com/maps')) {
      return url;
    }
    return null;
  }

  String? _mobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Contact number is required';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 10) return 'Must be exactly 10 digits';
    return null;
  }

  String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDateFull(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime12(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildTeamSwitcher() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teams = [
      (
        id: 'marketing',
        name: 'Marketing',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFFF9100),
      ),
      (
        id: 'development',
        name: 'Development',
        icon: Icons.code_rounded,
        color: const Color(0xFF00E5FF),
      ),
      (
        id: 'management',
        name: 'Management',
        icon: Icons.business_center_rounded,
        color: const Color(0xFFA855F7),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: teams.map((t) {
          final isSelected = _selectedTeam == t.id;
          final isDisabled = !isSelected;

          return Expanded(
            child: Opacity(
              opacity: isDisabled ? 0.42 : 1.0,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTeam = t.id;
                    final newMembers = getTeamMembersFor(_selectedTeam);
                    _selectedMemberIds.clear();
                    _selectedMemberIds.addAll(newMembers.map((m) => m.id));
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: t.color, width: 1.5)
                        : Border.all(
                            color: isDisabled
                                ? (isDark ? Colors.white10 : Colors.grey.shade300)
                                : Colors.transparent,
                            width: 1.0,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: t.color.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDisabled ? Icons.lock_outline_rounded : t.icon,
                        size: 18,
                        color: isSelected
                            ? t.color
                            : (isDisabled
                                ? (isDark ? Colors.white30 : Colors.grey.shade400)
                                : (isDark ? Colors.white54 : Colors.grey.shade600)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDisabled
                                  ? (isDark ? Colors.white38 : Colors.grey.shade400)
                                  : (isDark ? Colors.white60 : Colors.grey.shade600)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isDisabled
                            ? 'Disabled'
                            : (isSelected
                                ? (t.id == 'marketing' ? 'Tap to switch' : 'Active')
                                : 'Team'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? t.color
                              : (isDisabled
                                  ? (isDark ? Colors.white38 : Colors.grey.shade400)
                                  : Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceCheckboxes(List<({String title, IconData icon, String desc})> items) {
    return Column(
      children: items.map((item) {
        final isSelected = _selectedCreativeServices.contains(item.title);
        return Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            value: isSelected,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF00E5FF) : null,
              ),
            ),
            subtitle: Text(
              item.desc,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isSelected ? const Color(0xFF00E5FF) : Colors.white24).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 16,
                color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
              ),
            ),
            activeColor: const Color(0xFF00E5FF),
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedCreativeServices.add(item.title);
                } else {
                  _selectedCreativeServices.remove(item.title);
                }
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceCategoryDropdownTile({
    required String title,
    required IconData icon,
    required Color color,
    required List<({String title, IconData icon, String desc})> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedServiceCategories.contains(title);
    final selectedCount = items.where((i) => _selectedCreativeServices.contains(i.title)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedCount > 0
              ? color.withValues(alpha: 0.6)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: selectedCount > 0 ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedServiceCategories.remove(title);
                } else {
                  _expandedServiceCategories.add(title);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: color,
                          ),
                        ),
                        Text(
                          selectedCount > 0
                              ? '$selectedCount of ${items.length} selected'
                              : '${items.length} services • Tap dropdown to view',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selectedCount > 0 ? FontWeight.w700 : FontWeight.w500,
                            color: selectedCount > 0 ? color : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
              child: _buildServiceCheckboxes(items),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSelected = _selectedCreativeServices.length;

    return _CollapsibleSection(
      title: 'Services',
      icon: Icons.miscellaneous_services_rounded,
      iconColor: const Color(0xFF10B981),
      badgeText: _selectedTeam != 'development'
          ? '$totalSelected services selected'
          : (_serviceType != null ? '1 service selected' : 'Select service'),
      isExpanded: _servicesExpanded,
      onToggle: () => setState(() => _servicesExpanded = !_servicesExpanded),
      children: [
        if (_selectedTeam != 'development') ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCategoryFilter,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Select Service Category Dropdown',
                prefixIcon: const Icon(Icons.filter_list_rounded, color: Color(0xFF00E5FF), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Service Categories (5)')),
                DropdownMenuItem(value: 'CREATIVE STUDIO', child: Text('Creative Studio (5 services)')),
                DropdownMenuItem(value: 'SOCIAL MEDIA MARKETING', child: Text('Social Media Marketing (5 services)')),
                DropdownMenuItem(value: 'SEO SERVICES', child: Text('SEO Services (6 services)')),
                DropdownMenuItem(value: 'PAID ADVERTISING', child: Text('Paid Advertising (2 services)')),
                DropdownMenuItem(value: 'WEB APP DEVELOPMENT', child: Text('Web App Development (6 services)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategoryFilter = val;
                    if (val == 'all') {
                      _expandedServiceCategories.addAll([
                        'CREATIVE STUDIO',
                        'SOCIAL MEDIA MARKETING',
                        'SEO SERVICES',
                        'PAID ADVERTISING',
                        'WEB APP DEVELOPMENT',
                      ]);
                    } else {
                      _expandedServiceCategories.add(val);
                    }
                  });
                }
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Category Dropdowns:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _expandedServiceCategories.addAll([
                          'CREATIVE STUDIO',
                          'SOCIAL MEDIA MARKETING',
                          'SEO SERVICES',
                          'PAID ADVERTISING',
                          'WEB APP DEVELOPMENT',
                        ]);
                      });
                    },
                    icon: const Icon(Icons.unfold_more_rounded, size: 14),
                    label: const Text('Expand All', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _expandedServiceCategories.clear());
                    },
                    icon: const Icon(Icons.unfold_less_rounded, size: 14),
                    label: const Text('Collapse All', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_selectedCategoryFilter == 'all' || _selectedCategoryFilter == 'CREATIVE STUDIO')
            _buildServiceCategoryDropdownTile(
              title: 'CREATIVE STUDIO',
              icon: Icons.palette_outlined,
              color: const Color(0xFF00E5FF),
              items: _creativeStudioItems,
            ),
          if (_selectedCategoryFilter == 'all' || _selectedCategoryFilter == 'SOCIAL MEDIA MARKETING')
            _buildServiceCategoryDropdownTile(
              title: 'SOCIAL MEDIA MARKETING',
              icon: Icons.campaign_outlined,
              color: const Color(0xFFFF9100),
              items: _socialMediaMarketingItems,
            ),
          if (_selectedCategoryFilter == 'all' || _selectedCategoryFilter == 'SEO SERVICES')
            _buildServiceCategoryDropdownTile(
              title: 'SEO SERVICES',
              icon: Icons.manage_search_outlined,
              color: const Color(0xFF10B981),
              items: _seoServicesItems,
            ),
          if (_selectedCategoryFilter == 'all' || _selectedCategoryFilter == 'PAID ADVERTISING')
            _buildServiceCategoryDropdownTile(
              title: 'PAID ADVERTISING',
              icon: Icons.ads_click_rounded,
              color: const Color(0xFFEF4444),
              items: _paidAdvertisingItems,
            ),
          if (_selectedCategoryFilter == 'all' || _selectedCategoryFilter == 'WEB APP DEVELOPMENT')
            _buildServiceCategoryDropdownTile(
              title: 'WEB APP DEVELOPMENT',
              icon: Icons.code_rounded,
              color: const Color(0xFF8B5CF6),
              items: _webAppDevelopmentItems,
            ),
        ] else ...[
          DropdownButtonFormField<String>(
            initialValue: _serviceType,
            validator: _required,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Service *',
              hintText: 'Select development service',
              prefixIcon: Icon(Icons.miscellaneous_services_rounded, color: Color(0xFF00E5FF)),
            ),
            items: coreVisitServiceOptions
                .map(
                  (service) => DropdownMenuItem<String>(
                    value: service.id,
                    child: Row(
                      children: [
                        Icon(service.icon, size: 20, color: const Color(0xFF00E5FF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _serviceType = value),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleSection() {
    final isDark = ThemeConfig.isDark(context);
    final now = DateTime.now();
    final isToday = _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = _date.year == tomorrow.year &&
        _date.month == tomorrow.month &&
        _date.day == tomorrow.day;

    // Quick time slots (1-tap selection)
    const quickSlots = [
      (label: '10:00 AM', hour: 10, minute: 0),
      (label: '11:30 AM', hour: 11, minute: 30),
      (label: '02:00 PM', hour: 14, minute: 0),
      (label: '04:00 PM', hour: 16, minute: 0),
      (label: '05:30 PM', hour: 17, minute: 30),
    ];

    const travelModes = [
      (mode: 'car', label: 'Car', icon: Icons.directions_car_rounded),
      (mode: 'bike', label: 'Bike', icon: Icons.two_wheeler_rounded),
      (mode: 'train', label: 'Train', icon: Icons.train_rounded),
      (mode: 'bus', label: 'Bus', icon: Icons.directions_bus_rounded),
    ];

    return _CollapsibleSection(
      title: 'Timeline schedule',
      icon: Icons.calendar_month_rounded,
      iconColor: const Color(0xFFFF9100),
      badgeText: '${_formatDateFull(_date)} • ${_formatTime12(_time)} • ${_travelMode.toUpperCase()}',
      isExpanded: _timelineSectionExpanded,
      onToggle: () => setState(() => _timelineSectionExpanded = !_timelineSectionExpanded),
      children: [
        // Quick Date Selector Chips
        const Text(
          'SELECT DATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Today'),
                selected: isToday,
                onSelected: (_) => setState(() => _date = DateTime.now()),
                selectedColor: const Color(0xFF00E5FF).withAlpha(40),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isToday ? const Color(0xFF00E5FF) : null,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Tomorrow'),
                selected: isTomorrow,
                onSelected: (_) => setState(() => _date = DateTime.now().add(const Duration(days: 1))),
                selectedColor: const Color(0xFF00E5FF).withAlpha(40),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isTomorrow ? const Color(0xFF00E5FF) : null,
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFFFF9100)),
                label: const Text('Pick Other Date'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date != null) setState(() => _date = date);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Visual Date & Time Display Cards (Side-by-side)
        Row(
          children: [
            // Date Card
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date != null) setState(() => _date = date);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F2033) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFFF9100)),
                          const SizedBox(width: 6),
                          Text(
                            isToday ? 'TODAY' : (isTomorrow ? 'TOMORROW' : 'DATE'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF9100),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.touch_app_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateFull(_date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Time Card
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );
                  if (time != null) setState(() => _time = time);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F2033) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF00E5FF)),
                          const SizedBox(width: 6),
                          const Text(
                            'TIME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.touch_app_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime12(_time),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Quick Time Slots (1-tap selection)
        const Text(
          'QUICK TIME SLOTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: quickSlots.map((slot) {
              final isSelected = _time.hour == slot.hour && _time.minute == slot.minute;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(slot.label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _time = TimeOfDay(hour: slot.hour, minute: slot.minute));
                  },
                  selectedColor: const Color(0xFF00E5FF).withAlpha(45),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF00E5FF) : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Travel Mode Selector
        const Text(
          'TRAVEL MODE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: travelModes.map((tm) {
            final isSelected = _travelMode == tm.mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => setState(() => _travelMode = tm.mode),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00E5FF).withAlpha(35)
                          : (isDark ? Colors.white.withAlpha(8) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tm.icon,
                          size: 20,
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tm.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF00E5FF) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _proceedToServiceStatus() {
    if (!_formKey.currentState!.validate()) {
      _snack(context, 'Please complete all required fields.');
      return;
    }

    final isDev = _selectedTeam == 'development';
    final wholeTeam = getTeamMembersFor(_selectedTeam);
    final assignedMembers =
        wholeTeam.where((m) => _selectedMemberIds.contains(m.id)).toList();
    final membersForVisit =
        assignedMembers.isNotEmpty ? assignedMembers : wholeTeam;
    final coords = _selectedCoords;

    List<String> servicesList;
    if (isDev) {
      servicesList = [_serviceType ?? 'Web App Development'];
    } else if (_selectedCreativeServices.isNotEmpty) {
      servicesList = _selectedCreativeServices.toList();
    } else {
      servicesList = [
        'Creative Studio & Ad Creatives',
        'Social Media Marketing',
        'Google Ads Campaign',
        'SEO Services',
      ];
    }

    final basePayload = <String, dynamic>{
      'client_name': _client.text.trim(),
      'contact_person': _contact.text.trim(),
      'contact_phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'industry': _industry.text.trim(),
      'location': _location.text.trim(),
      'client_email': _email.text.trim(),
      'email': _email.text.trim(),
      'creative_studio_services': servicesList,
      if (coords != null) 'latitude': coords.lat,
      if (coords != null) 'longitude': coords.lng,
      'scheduled_date': _ymd(_date),
      'scheduled_time':
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      'duration_minutes': 60,
      'travel_mode': _travelMode,
      'service_type': isDev
          ? (_serviceType ?? 'web_app_development')
          : (_serviceType ?? 'digital_marketing'),
      'purpose': isDev ? 'Development Client Visit' : 'Client Visit',
      'notes': '',
      if (!_selfApprovingRole)
        'manager_user_id': _selectedManagerId ?? _manager.text.trim(),
      'team': _selectedTeam,
      'attendees': membersForVisit.map((m) => {
        'id': m.id,
        'name': m.name,
        'role': m.role,
        'phone': m.phone,
        'email': m.email,
      }).toList(),
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientVisitServiceStatusScreen(
          userId: widget.userId,
          service: widget.service,
          selfApprovingRole: _selfApprovingRole,
          selectedTeam: _selectedTeam,
          visitPayload: basePayload,
          initialServices: servicesList,
          assignedMembers: membersForVisit,
          wholeTeam: wholeTeam,
          scheduledDateStr: _formatDateFull(_date),
          scheduledTimeStr: _formatTime12(_time),
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _submit(bool submit) async {
    final clientName = _client.text.trim();
    if (clientName.isEmpty) {
      _snack(context, 'Please enter a client name.');
      return;
    }

    final isDev = _selectedTeam == 'development';
    final wholeTeam = getTeamMembersFor(_selectedTeam);
    final assignedMembers =
        wholeTeam.where((m) => _selectedMemberIds.contains(m.id)).toList();
    final membersForVisit =
        assignedMembers.isNotEmpty ? assignedMembers : wholeTeam;
    final coords = _selectedCoords;

    final servicesList = _selectedCreativeServices.isNotEmpty
        ? _selectedCreativeServices.toList()
        : [
            'Creative Studio & Ad Creatives',
            'Social Media Marketing',
          ];

    final payload = <String, dynamic>{
      'client_name': clientName,
      'contact_person': _contact.text.trim(),
      'contact_phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'industry': _industry.text.trim(),
      'location': _location.text.trim(),
      'client_email': _email.text.trim(),
      'email': _email.text.trim(),
      'creative_studio_services': servicesList,
      if (coords != null) 'latitude': coords.lat,
      if (coords != null) 'longitude': coords.lng,
      'scheduled_date': _ymd(_date),
      'scheduled_time':
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      'duration_minutes': 60,
      'travel_mode': _travelMode,
      'service_type': isDev
          ? (_serviceType ?? 'web_app_development')
          : (_serviceType ?? 'digital_marketing'),
      'purpose': isDev ? 'Development Client Visit' : 'Client Visit',
      'notes': '',
      if (!_selfApprovingRole)
        'manager_user_id': _selectedManagerId ?? _manager.text.trim(),
      'team': _selectedTeam,
      'submit': submit,
      'attendees': membersForVisit.map((m) => {
        'id': m.id,
        'name': m.name,
        'role': m.role,
        'phone': m.phone,
        'email': m.email,
      }).toList(),
    };

    setState(() => _saving = true);
    try {
      ClientVisit? created;
      try {
        created = await widget.service.create(widget.userId, payload);
      } catch (_) {
        created = ClientVisit(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          visitId: 'VST-2026-${(DateTime.now().millisecondsSinceEpoch % 90000 + 10000)}',
          employeeUserId: widget.userId,
          employeeName: 'BitByte Staff',
          employeePhotoUrl: '',
          managerUserId: '',
          clientName: clientName,
          contactPerson: _contact.text.trim(),
          contactPhone: _phone.text.trim(),
          address: _address.text.trim(),
          scheduledAt: DateTime.now(),
          durationMinutes: 60,
          travelMode: _travelMode,
          serviceType: isDev ? 'web_app_development' : 'digital_marketing',
          serviceName: 'Client Services',
          purpose: isDev ? 'Development Client Visit' : 'Client Visit',
          notes: '',
          status: _selfApprovingRole ? 'approved' : 'pending',
          requirementStatus: 'interested',
          team: _selectedTeam,
          approvalComment: '',
          approvedBy: '',
          approvedByName: '',
          approvedByRole: '',
          approvedAt: null,
          tlApprovalComment: '',
          tlApprovedBy: '',
          tlApprovedByName: '',
          tlApprovedByRole: '',
          tlApprovedAt: null,
          outcome: '',
          followUp: '',
          officeCheckOutAt: null,
          reachedClientAt: null,
          officeCheckOutLatitude: null,
          officeCheckOutLongitude: null,
          reachedClientLatitude: null,
          reachedClientLongitude: null,
          clientLatitude: coords?.lat,
          clientLongitude: coords?.lng,
          startOdometer: null,
          travelRoute: const [],
          checkInAt: null,
          checkOutAt: null,
          attendees: const [],
          checklist: const [],
          returnMode: '',
          managerVerifiedBy: '',
          managerVerifiedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          expenseTotal: 0.0,
          attachments: const [],
          expenses: const [],
        );
      }
      if (mounted) {
        await showVisitSuccessTableDialog(
          context: context,
          visit: created,
          assignedMembers: membersForVisit,
          wholeTeam: wholeTeam,
          scheduledDateStr: _formatDateFull(_date),
          scheduledTimeStr: _formatTime12(_time),
          isSelfApproving: _selfApprovingRole,
          isDraft: !submit,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : _proceedToServiceStatus,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next: Service Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
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
            _buildTeamSwitcher(),
            _Section(
              title: 'Client details',
              children: [
                TextFormField(
                  controller: _client,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Client Name *',
                    hintText: 'Enter client / company name',
                  ),
                ),
                TextFormField(
                  controller: _industry,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Industry *',
                    hintText: 'e.g. Retail, Tech, Healthcare',
                    prefixIcon: Icon(Icons.apartment_rounded, color: Color(0xFF00E5FF)),
                  ),
                ),
                TextFormField(
                  controller: _location,
                  validator: _required,
                  decoration: InputDecoration(
                    labelText: 'Location *',
                    hintText: 'Enter city / area / landmark',
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.pin_drop_rounded, color: Color(0xFF00E5FF)),
                      tooltip: 'Auto-fetch GPS location',
                      onPressed: _locating ? null : _useCurrentLocation,
                    ),
                    suffixIcon: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00E5FF)),
                            tooltip: 'Auto-fetch GPS location',
                            onPressed: _useCurrentLocation,
                          ),
                  ),
                ),
                TextFormField(
                  controller: _email,
                  validator: _emailValidator,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'client@company.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF00E5FF)),
                  ),
                ),
                TextFormField(
                  controller: _address,
                  validator: _required,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    hintText: 'Full client premises address',
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
                    labelText: 'phone number *',
                    hintText: 'Enter 10-digit mobile number',
                    counterText: '',
                  ),
                ),
                TextFormField(
                  controller: _contact,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Contact person *',
                    hintText: 'Contact person name',
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _locationCoords,
                  validator: _validateCoords,
                  decoration: InputDecoration(
                    labelText: 'Client location (paste from WhatsApp / Maps)',
                    hintText: 'https://maps.app.goo.gl/... or 11.6864, 78.1204',
                    helperText: 'Tap location icon to automatically fetch GPS coordinates',
                    helperMaxLines: 2,
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.location_on_outlined, color: Color(0xFF00E5FF)),
                      tooltip: 'Auto-fetch GPS location',
                      onPressed: _locating ? null : _useCurrentLocation,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_locationCoords.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _locationCoords.clear();
                                _selectedCoords = null;
                              });
                            },
                          ),
                        _locating || _resolvingUrl
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.my_location_rounded,
                                  color: Color(0xFF00E5FF),
                                ),
                                tooltip: 'Use current GPS location',
                                onPressed: _useCurrentLocation,
                              ),
                      ],
                    ),
                  ),
                  onChanged: _onLocationInputChanged,
                ),
                _buildMapSection(),
              ],
            ),
            const SizedBox(height: 12),
            _buildServicesSection(),
            const SizedBox(height: 12),
            _buildScheduleSection(),
          ],
        ),
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
  final VoidCallback onUpcoming;
  final VoidCallback onPendingApproval;
  final VoidCallback onHistory;
  final int downloadCount;
  final VoidCallback onDownloads;
  final VoidCallback onServices;
  const _Summary({
    required this.summary,
    required this.onInProgress,
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
      _wideBox(
        context,
        'In Progress Visits',
        (summary['travelling'] ?? 0) + (summary['in_progress'] ?? 0),
        ClientVisitColors.blue,
        onInProgress,
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
  final String viewerRole;
  final VoidCallback? onEditRequirementStatus;
  const _VisitCard({
    required this.visit,
    required this.onTap,
    this.historyViewerUserId = '',
    this.viewerRole = '',
    this.onEditRequirementStatus,
  });

  bool get _isDevelopmentVisitOrRole {
    if (_isLiveTimelineRole) return false;
    final team = visit.team.trim().toLowerCase();
    if (team == 'development') return true;
    final role = viewerRole.trim().toLowerCase();
    return role == 'tl' || role == 'employee' || role == 'hr';
  }

  Color get _statusColor => employeeStatusColor(visit.status);

  String get _statusLabel {
    return _label(visit.status);
  }

  bool get _isLiveTimelineRole {
    return isLiveTimelineViewerRole(viewerRole, team: visit.team, userId: historyViewerUserId);
  }

  String get _nextActionLabel {
    if (_isLiveTimelineRole) {
      return 'Live Google Timeline';
    }
    return switch (visit.status) {
      'draft' => 'Draft Visit',
      'pending' => 'Pending Approval',
      'approved' => _isDevelopmentVisitOrRole ? 'Start to Visit' : 'Approved Visit',
      'travelling' => 'Travelling to Client',
      'in_progress' => 'Meeting in Progress',
      'completed' => 'Completed Visit',
      'rejected' => 'Rejected Visit',
      _ => '${_label(visit.status)} Visit',
    };
  }

  IconData get _nextActionIcon {
    if (_isLiveTimelineRole) {
      return Icons.timeline_rounded;
    }
    return switch (visit.status) {
      'draft' => Icons.edit_document,
      'pending' => Icons.pending_actions_rounded,
      'approved' => _isDevelopmentVisitOrRole ? Icons.navigation_rounded : Icons.check_circle_outline_rounded,
      'travelling' => Icons.near_me_rounded,
      'in_progress' => Icons.play_arrow_rounded,
      'completed' => Icons.task_alt_rounded,
      'rejected' => Icons.cancel_outlined,
      _ => Icons.arrow_forward_rounded,
    };
  }

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

    final reqStatus = visit.requirementStatus.trim();
    final hasReq = reqStatus.isNotEmpty;
    final reqLabel =
        hasReq ? requirementStatusLabel(reqStatus) : 'Set Requirement';
    final reqColor =
        Color(hasReq ? requirementStatusColorValue(reqStatus) : 0xFF78909C);
    final reqIcon =
        hasReq ? requirementStatusIcon(reqStatus) : Icons.add_circle_outline_rounded;

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
                const SizedBox(height: 8),
                // Requirement Status chip & Service module row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onEditRequirementStatus,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: reqColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: reqColor.withAlpha(90),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(reqIcon, size: 13, color: reqColor),
                            const SizedBox(width: 4),
                            Text(
                              reqLabel,
                              style: TextStyle(
                                color: reqColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (onEditRequirementStatus != null) ...[
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 14,
                                color: reqColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (visit.serviceName.isNotEmpty)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            visit.serviceName,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ThemeConfig.getTextMuted(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
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
                    if (_isLiveTimelineRole)
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GoogleTimelineVisitScreen(
                                visit: visit,
                                allVisits: [visit],
                                userId: historyViewerUserId.isNotEmpty
                                    ? historyViewerUserId
                                    : 'BBADM001',
                                initialStaffId: visit.employeeUserId,
                                initialStaffName: visit.employeeName,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4285F4).withAlpha(80),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timeline_rounded,
                                size: 13,
                                color: Color(0xFF4285F4),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Google Timeline',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClientVisitHistoryScreen(
                                userId: historyViewerUserId.isNotEmpty
                                    ? historyViewerUserId
                                    : (visit.employeeUserId.isNotEmpty
                                        ? visit.employeeUserId
                                        : 'BBADM001'),
                                viewerRole: viewerRole,
                                initialVisitId: visit.id,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF10B981).withAlpha(80),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 13,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'MY HISTORY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
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

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String? badgeText;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isExpanded,
    required this.onToggle,
    this.badgeText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isExpanded
                    ? (isDark ? const Color(0xFF243048) : const Color(0xFFF1F5F9))
                    : Colors.transparent,
                border: isExpanded ? Border(bottom: BorderSide(color: borderColor)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        if (badgeText != null)
                          Text(
                            badgeText!,
                            style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children.map(
                  (e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: e),
                ).toList(),
              ),
            ),
        ],
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

String _label(String value) {
  if (value == 'history' || value == 'my_history') return 'My History';
  if (value == 'live_timeline') return 'Live Timeline';
  if (value == 'my_visits') return 'My Visits';
  return value
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
String _ymd(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
void _snack(BuildContext context, String value) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(value.replaceFirst('Exception: ', ''))));
