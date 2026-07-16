class EmployeeDashboardData {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> attendance;
  final Map<String, dynamic> leaveBalances;
  final List<Map<String, dynamic>> leaves;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> meetings;
  final List<Map<String, dynamic>> tasks;
  final Map<String, dynamic> payslip;
  final List<Map<String, dynamic>> documents;

  const EmployeeDashboardData({
    required this.profile,
    required this.attendance,
    required this.leaveBalances,
    required this.leaves,
    required this.notifications,
    required this.meetings,
    required this.tasks,
    required this.payslip,
    required this.documents,
  });

  factory EmployeeDashboardData.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(
      json['data'] is Map ? json['data'] as Map : json,
    );
    return EmployeeDashboardData(
      profile: _map(data['profile']),
      attendance: _map(data['attendance']),
      leaveBalances: _map(data['leave_balances']),
      leaves: _list(data['leaves']),
      notifications: _list(data['notifications']),
      meetings: _list(data['meetings']),
      tasks: _list(data['tasks']),
      payslip: _map(data['payslip']),
      documents: _list(data['documents']),
    );
  }

  Map<String, dynamic> toJson() => {
    'profile': profile,
    'attendance': attendance,
    'leave_balances': leaveBalances,
    'leaves': leaves,
    'notifications': notifications,
    'meetings': meetings,
    'tasks': tasks,
    'payslip': payslip,
    'documents': documents,
  };

  static Map<String, dynamic> _map(Object? value) {
    return Map<String, dynamic>.from(value is Map ? value : const {});
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    return List<Map<String, dynamic>>.from(
      (value is List ? value : const []).map((item) => _map(item)),
    );
  }

  /// Returns a minimal fallback used only when the backend is unreachable.
  /// No fake names, salaries, tasks, or documents — only the identity values
  /// passed in from the login session, everything else empty.
  static EmployeeDashboardData fallback({
    required String email,
    required String firstName,
    required String userId,
  }) {
    return EmployeeDashboardData(
      profile: {
        'name': firstName.isEmpty ? 'Employee' : firstName,
        'first_name': firstName,
        'email': email,
        'employee_id': userId,
        'department': '',
        'designation': '',
        'date_of_joining': '',
        'reporting_tl': '',
        'work_location': '',
      },
      attendance: const {},
      leaveBalances: const {},
      leaves: const [],
      notifications: const [],
      meetings: const [],
      tasks: const [],
      payslip: const {},
      documents: const [],
    );
  }
}
