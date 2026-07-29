import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class CeoService {
  static const String _base = '${ApiConfig.baseUrl}/ceo';
  static const Duration _timeout = Duration(seconds: 60);
  static const Duration _cacheTtl = Duration(seconds: 45);
  static final Map<String, _CeoCacheEntry> _cache = {};
  static final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  // ── Dashboard ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchHomeDashboard(String userId) async {
    final key = 'home:$userId';
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) return cached.data;
    final running = _inFlight[key];
    if (running != null) return running;
    try {
      final future = _fetchFastHome(userId).then((data) {
        final resolved = data;
        _cache[key] = _CeoCacheEntry(resolved, DateTime.now().add(_cacheTtl));
        _inFlight.remove(key);
        return resolved;
      }).catchError((error) {
        _inFlight.remove(key);
        throw error;
      });
      _inFlight[key] = future;
      return await future;
    } catch (error) {
      return _emptyHomeDashboard(userId, 'CEO backend unavailable: $error');
    }
  }

  Future<Map<String, dynamic>> _fetchFastHome(String userId) async {
    try {
      return await _getStrictWithTimeout(
        '/home/?user_id=$userId',
        const Duration(seconds: 25),
      );
    } catch (_) {
      return _getStrictWithTimeout(
        '/dashboard/?user_id=$userId',
        _timeout,
      );
    }
  }

  Map<String, dynamic> _emptyHomeDashboard(String userId, String message) => {
        'success': false,
        'message': message,
        'profile': {
          'id': userId,
          'name': 'CEO',
          'role': 'ceo',
          'role_label': 'CEO',
        },
        'attendance_health': {
          'score': 0,
          'label': 'No Data',
          'trend': 0,
          'trend_label': '+0%',
          'total_members': 0,
          'joined_this_month': 0,
          'present_today': 0,
          'on_leave_today': 0,
          'weekly_scores': const <int>[],
        },
        'total_employees': 0,
        'active_employees': 0,
        'departments': 0,
        'branches': 0,
        'attendance': 0,
        'pending_approvals': 0,
        'payroll_cost': 'Rs. 0',
        'expenses': 'Rs. 0',
        'net_profit': 'Rs. 0',
        'workforce_today': {
          'present': 0,
          'absent': 0,
          'late_entry': 0,
          'wfh': 0,
          'hybrid': 0,
          'onsite': 0,
        },
        'absent_today': 0,
        'late_entry': 0,
        'wfh': 0,
        'hybrid': 0,
        'onsite': 0,
        'role_counts': const <Map<String, dynamic>>[],
        'role_members': const <Map<String, dynamic>>[],
        'employee_categories': const <Map<String, dynamic>>[],
        'recent_members': const <Map<String, dynamic>>[],
        'active_employee_list': const <Map<String, dynamic>>[],
        'approvals_summary': const <Map<String, dynamic>>[],
        'project_overview': {
          'active': 0,
          'completed': 0,
          'delayed': 0,
          'at_risk': 0,
        },
        'project_items': const <Map<String, dynamic>>[],
        'critical_alerts': const <Map<String, dynamic>>[],
        'revenue': 'Rs. 0',
        'revenue_amount': 0,
        'revenue_trend': '+0%',
        'revenue_bars': const <int>[],
        'revenue_months': const <String>[],
        'monthly_revenue': const <Map<String, dynamic>>[],
      };

  Future<Map<String, dynamic>> fetchDashboard(String userId) =>
      _cachedGetStrict('dashboard:$userId', '/dashboard/?user_id=$userId');

  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    try {
      return await _cachedGetStrict('profile:$userId', '/profile/?user_id=$userId');
    } catch (_) {
      return fetchDashboard(userId);
    }
  }

  Future<Map<String, dynamic>> fetchOrganization(String userId) =>
      _getStrict('/organization/?user_id=$userId');

  Future<Map<String, dynamic>> saveOrganization(
    String userId,
    String action,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/organization/', {
    'user_id': userId,
    'action': action,
    ...fields,
  });

  // ── Analytics ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchAnalytics(String userId) =>
      _get('/analytics/?user_id=$userId');

  // ── Reports ───────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchReports(String userId) =>
      _get('/reports/?user_id=$userId');

  // ── Approvals ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchApprovals(String userId) =>
      _get('/approvals/?user_id=$userId');

  Future<Map<String, dynamic>> fetchApprovalCategory(
    String category,
    String userId, {
    bool history = false,
  }) async {
    final path = '/approval-categories/$category/?user_id=$userId&history=$history';
    final data = await _get(path);
    if (data['success'] == true) return data;

    if (category == 'leave') {
      final approvals = await fetchApprovals(userId);
      final key = history ? 'history' : 'approvals';
      final items = approvals[key] is List ? approvals[key] as List : const [];
      return {
        'success': true,
        'category': {
          'key': 'leave',
          'title': 'Leave Approval',
          'count': items.length,
          'priority': items.isEmpty ? 'Clear' : 'High',
        },
        'history': history,
        'items': items,
        'message': 'Loaded leave approvals from fallback endpoint.',
      };
    }

    return {
      'success': true,
      'category': {
        'key': category,
        'title': category,
        'count': 0,
        'priority': 'Clear',
      },
      'history': history,
      'items': const <Map<String, dynamic>>[],
      'message': 'No approval data returned by backend.',
    };
  }

  Future<Map<String, dynamic>> fetchLeaveDetail(int leaveId) =>
      _get('/leave-detail/$leaveId/');

  Future<Map<String, dynamic>> updateApproval(
    String leaveId,
    String status,
    String reviewedBy,
  ) => _post('/approvals/$leaveId/', {
    'status': status,
    'user_id': reviewedBy,
    'reviewed_by': reviewedBy,
  });

  // ── Employees ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchEmployees(String userId) =>
      _get('/employees/?user_id=$userId');

  // ── Notifications ─────────────────────────────────────────
  Future<Map<String, dynamic>> fetchEmployeeAttendance(String employeeId) =>
      _get('/employee-attendance/?employee_id=$employeeId');

  Future<Map<String, dynamic>> fetchAttendanceIntelligence(
    String userId, {
    String? dateFrom,
    String? dateTo,
    String? selectedDate,
  }) {
    final query = <String, String>{'user_id': userId};
    if (dateFrom?.isNotEmpty == true) query['date_from'] = dateFrom!;
    if (dateTo?.isNotEmpty == true) query['date_to'] = dateTo!;
    if (selectedDate?.isNotEmpty == true) query['date'] = selectedDate!;
    return _getStrict(
      '/attendance-intelligence/?${Uri(queryParameters: query).query}',
    );
  }

  Future<Map<String, dynamic>> fetchLeaveIntelligence(
    String userId, {
    required int year,
    required int month,
  }) => _getStrict(
    '/leave-intelligence/?${Uri(queryParameters: {
      'user_id': userId,
      'year': '$year',
      'month': '$month',
    }).query}',
  );

  Future<Map<String, dynamic>> announceCompanyLeave(
    String userId, {
    required String title,
    required DateTime fromDate,
    required DateTime toDate,
    String message = '',
  }) => _post('/company-leaves/', {
    'user_id': userId,
    'title': title,
    'message': message,
    'from_date': _companyLeaveDate(fromDate),
    'to_date': _companyLeaveDate(toDate),
  });

  String _companyLeaveDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>> fetchPayrollOverview(
    String userId, {
    required int year,
    required int month,
  }) => _getStrict(
    '/payroll-overview/?${Uri(queryParameters: {
      'user_id': userId,
      'year': '$year',
      'month': '$month',
    }).query}',
  );

  Future<Map<String, dynamic>> updatePayrollOverview(
    String userId, {
    required int year,
    required int month,
    required String action,
    bool declaration = false,
  }) => _postWithResponse('/payroll-overview/', {
    'user_id': userId,
    'year': year,
    'month': month,
    'action': action,
    'declaration': declaration,
  });

  Future<Map<String, dynamic>> fetchDocuments(String userId) =>
      _getStrict('/documents/?user_id=${Uri.encodeQueryComponent(userId)}');

  Future<Map<String, dynamic>> fetchHiringPipeline(String userId) =>
      _getStrict('/hiring-pipeline/?user_id=${Uri.encodeQueryComponent(userId)}');

  Future<Map<String, dynamic>> updateHiringPipeline(
    String userId,
    String action,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/hiring-pipeline/', {
    'user_id': userId,
    'action': action,
    ...fields,
  });

  Future<Map<String, dynamic>> fetchProjectsFlow(String userId) =>
      _getStrict('/projects-flow/?user_id=${Uri.encodeQueryComponent(userId)}');

  Future<Map<String, dynamic>> updateProjectsFlow(
    String userId,
    String action,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/projects-flow/', {
    'user_id': userId,
    'action': action,
    ...fields,
  });

  Future<Map<String, dynamic>> fetchPerformanceMatrix(String userId, String period) =>
      _getStrict('/performance-matrix/?${Uri(queryParameters: {'user_id': userId, 'period': period}).query}');

  Future<Map<String, dynamic>> updatePerformanceMatrix(
    String userId, String period, String action, Map<String, dynamic> fields,
  ) => _postWithResponse('/performance-matrix/', {'user_id': userId, 'period': period, 'action': action, ...fields});

  Future<Map<String,dynamic>> fetchReportsFlow(String userId)=>_getStrict('/reports-flow/?user_id=${Uri.encodeQueryComponent(userId)}');
  Future<Map<String,dynamic>> updateReportsFlow(String userId,String action,Map<String,dynamic> fields)=>_postWithResponse('/reports-flow/',{'user_id':userId,'action':action,...fields});

  Future<Map<String, dynamic>> fetchAuditFlow(
    String userId,
    Map<String, dynamic> filters,
  ) {
    final query = <String, String>{'user_id': userId};
    for (final entry in filters.entries) {
      if (entry.value is String && '${entry.value}'.isNotEmpty) {
        query[entry.key] = '${entry.value}';
      }
    }
    final modules = (filters['modules'] as List?) ?? const [];
    final severities = (filters['severities'] as List?) ?? const [];
    var path = '/audit-flow/?${Uri(queryParameters: query).query}';
    for (final value in modules) {
      path += '&module=${Uri.encodeQueryComponent('$value')}';
    }
    for (final value in severities) {
      path += '&severity=${Uri.encodeQueryComponent('$value')}';
    }
    return _getStrict(path);
  }

  Future<Map<String, dynamic>> emailAuditReport(
    String userId,
    Map<String, dynamic> filters,
    String format,
    List<String> include,
  ) => _postWithResponse('/audit-flow/', {
    'user_id': userId,
    'action': 'export',
    'filters': filters,
    'format': format,
    'include': include,
  });

  Future<Map<String, dynamic>> fetchNotifications(String userId) =>
      _get('/notifications/?user_id=$userId');

  Future<Map<String, dynamic>> markNotificationRead(
    int notificationId,
    String userId,
  ) => _post('/notifications/$notificationId/read/', {'user_id': userId});

  // ── Meetings ──────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchMeetings(String userId) =>
      _cachedGet('meetings:$userId', '/meetings/?user_id=$userId');

  Future<Map<String, dynamic>> scheduleMeeting(
    String userId,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/meetings/', {
        'user_id': userId,
        ...fields,
      }).then((result) {
        if (result['success'] == true) {
          _cache.remove('meetings:$userId');
          _inFlight.remove('meetings:$userId');
        }
        return result;
      });

  // ── Budget ────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchBudget(String userId) =>
      _get('/budget/?user_id=$userId');

  // ── Department performance ────────────────────────────────
  Future<Map<String, dynamic>> fetchDepartmentPerformance(String userId) =>
      _get('/department-performance/?user_id=$userId');

  Future<Map<String, dynamic>> saveDepartment(
    String userId,
    String action,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/department-performance/', {
    'user_id': userId,
    'action': action,
    ...fields,
  });

  // ── Branch performance ────────────────────────────────────
  Future<Map<String, dynamic>> fetchBranchPerformance(String userId) =>
      _get('/branch-performance/?user_id=$userId');

  // ── HTTP helpers ──────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'))
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> _getStrict(String path) async {
    final res = await http
        .get(Uri.parse('$_base$path'))
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend returned ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw Exception('Backend returned invalid dashboard data');
  }

  Future<Map<String, dynamic>> _getStrictWithTimeout(
    String path,
    Duration timeout,
  ) async {
    final res = await http.get(Uri.parse('$_base$path')).timeout(timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend returned ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw Exception('Backend returned invalid data');
  }

  Future<Map<String, dynamic>> _cachedGet(String key, String path) {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return Future.value(cached.data);
    }
    final running = _inFlight[key];
    if (running != null) return running;
    final future = _get(path).then((data) {
      if (data.isNotEmpty) {
        _cache[key] = _CeoCacheEntry(data, DateTime.now().add(_cacheTtl));
      }
      _inFlight.remove(key);
      return data;
    }).catchError((error) {
      _inFlight.remove(key);
      throw error;
    });
    _inFlight[key] = future;
    return future;
  }

  Future<Map<String, dynamic>> _cachedGetStrict(String key, String path) {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return Future.value(cached.data);
    }
    final running = _inFlight[key];
    if (running != null) return running;
    final future = _getStrict(path).then((data) {
      _cache[key] = _CeoCacheEntry(data, DateTime.now().add(_cacheTtl));
      _inFlight.remove(key);
      return data;
    }).catchError((error) {
      _inFlight.remove(key);
      throw error;
    });
    _inFlight[key] = future;
    return future;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> _postWithResponse(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final decoded = jsonDecode(res.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (error) {
      return {'success': false, 'message': error.toString()};
    }
    return {'success': false, 'message': 'Invalid server response.'};
  }

}

class _CeoCacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;

  const _CeoCacheEntry(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
