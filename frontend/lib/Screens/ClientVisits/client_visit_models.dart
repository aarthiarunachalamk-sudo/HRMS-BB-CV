class ClientVisit {
  final int id;
  final String visitId;
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
  final String outcome;
  final String followUp;
  final double expenseTotal;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> expenses;

  const ClientVisit({
    required this.id,
    required this.visitId,
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
    required this.outcome,
    required this.followUp,
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
      outcome: '${json['outcome'] ?? ''}',
      followUp: '${json['follow_up'] ?? ''}',
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
