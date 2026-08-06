class ClientVisit {
  final int id;
  final String visitId;
  final String employeeUserId;
  final String employeeName;
  final String managerUserId;
  final String clientName;
  final String contactPerson;
  final String contactPhone;
  final String address;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String travelMode;
  final String purpose;
  final String notes;
  final String status;
  final String approvalComment;
  final String approvedBy;
  final String approvedByName;
  final String approvedByRole;
  final DateTime? approvedAt;
  final String outcome;
  final String followUp;
  final DateTime? officeCheckOutAt;
  final DateTime? reachedClientAt;
  final double? officeCheckOutLatitude;
  final double? officeCheckOutLongitude;
  final double? reachedClientLatitude;
  final double? reachedClientLongitude;
  final double? clientLatitude;   // planned destination set at visit creation
  final double? clientLongitude;
  final List<Map<String, dynamic>> travelRoute;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final List<dynamic> attendees;
  final List<dynamic> checklist;
  final String returnMode;
  final String managerVerifiedBy;
  final double expenseTotal;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> expenses;

  const ClientVisit({
    required this.id,
    required this.visitId,
    required this.employeeUserId,
    required this.employeeName,
    required this.managerUserId,
    required this.clientName,
    required this.contactPerson,
    required this.contactPhone,
    required this.address,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.travelMode,
    required this.purpose,
    required this.notes,
    required this.status,
    required this.approvalComment,
    required this.approvedBy,
    required this.approvedByName,
    required this.approvedByRole,
    required this.approvedAt,
    required this.outcome,
    required this.followUp,
    required this.officeCheckOutAt,
    required this.reachedClientAt,
    required this.officeCheckOutLatitude,
    required this.officeCheckOutLongitude,
    required this.reachedClientLatitude,
    required this.reachedClientLongitude,
    required this.clientLatitude,
    required this.clientLongitude,
    required this.travelRoute,
    required this.checkInAt,
    required this.checkOutAt,
    required this.attendees,
    required this.checklist,
    required this.returnMode,
    required this.managerVerifiedBy,
    required this.expenseTotal,
    required this.attachments,
    required this.expenses,
  });

  factory ClientVisit.fromJson(Map<String, dynamic> json) {
    final date = '${json['scheduled_date'] ?? ''}';
    final time = '${json['scheduled_time'] ?? '00:00'}';
    return ClientVisit(
      id: int.tryParse('${json['id']}') ?? 0,
      visitId: '${json['visit_id'] ?? ''}',
      employeeUserId: '${json['employee_user_id'] ?? ''}',
      employeeName: '${json['employee_name'] ?? ''}',
      managerUserId: '${json['manager_user_id'] ?? ''}',
      clientName: '${json['client_name'] ?? ''}',
      contactPerson: '${json['contact_person'] ?? ''}',
      contactPhone: '${json['contact_phone'] ?? ''}',
      address: '${json['address'] ?? ''}',
      scheduledAt: DateTime.tryParse('${date}T$time') ?? DateTime.now(),
      durationMinutes: int.tryParse('${json['duration_minutes']}') ?? 60,
      travelMode: '${json['travel_mode'] ?? 'car'}',
      purpose: '${json['purpose'] ?? ''}',
      notes: '${json['notes'] ?? ''}',
      status: '${json['status'] ?? 'draft'}',
      approvalComment: '${json['approval_comment'] ?? ''}',
      approvedBy: '${json['approved_by'] ?? ''}',
      approvedByName: '${json['approved_by_name'] ?? ''}',
      approvedByRole: '${json['approved_by_role'] ?? ''}',
      approvedAt: DateTime.tryParse('${json['approved_at'] ?? ''}'),
      outcome: '${json['outcome'] ?? ''}',
      followUp: '${json['follow_up'] ?? ''}',
      officeCheckOutAt: DateTime.tryParse(
        '${json['office_check_out_at'] ?? ''}',
      ),
      reachedClientAt: DateTime.tryParse('${json['reached_client_at'] ?? ''}'),
      officeCheckOutLatitude: double.tryParse(
        '${json['office_check_out_latitude'] ?? ''}',
      ),
      officeCheckOutLongitude: double.tryParse(
        '${json['office_check_out_longitude'] ?? ''}',
      ),
      reachedClientLatitude: double.tryParse(
        '${json['reached_client_latitude'] ?? ''}',
      ),
      reachedClientLongitude: double.tryParse(
        '${json['reached_client_longitude'] ?? ''}',
      ),
      clientLatitude: double.tryParse('${json['latitude'] ?? ''}'),
      clientLongitude: double.tryParse('${json['longitude'] ?? ''}'),
      travelRoute: _maps(json['travel_route']),
      checkInAt: DateTime.tryParse('${json['check_in_at'] ?? ''}'),
      checkOutAt: DateTime.tryParse('${json['check_out_at'] ?? ''}'),
      attendees: json['attendees'] is List
          ? List<dynamic>.from(json['attendees'] as List)
          : const [],
      checklist: json['checklist'] is List
          ? List<dynamic>.from(json['checklist'] as List)
          : const [],
      returnMode: '${json['return_mode'] ?? ''}',
      managerVerifiedBy: '${json['manager_verified_by'] ?? ''}',
      expenseTotal: double.tryParse('${json['expense_total']}') ?? 0,
      attachments: _maps(json['attachments']),
      expenses: _maps(json['expenses']),
    );
  }

  static List<Map<String, dynamic>> _maps(Object? source) => source is List
      ? source
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
}

class ClientVisitListResult {
  final List<ClientVisit> visits;
  final Map<String, int> summary;
  const ClientVisitListResult(this.visits, this.summary);
}
