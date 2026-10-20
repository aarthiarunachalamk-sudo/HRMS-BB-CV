import 'package:flutter/material.dart';
import 'client_visit_service_catalog.dart';

class ClientVisit {
  final int id;
  final String visitId;
  final String employeeUserId;
  final String employeeName;
  final String employeePhotoUrl;
  final String managerUserId;
  final String clientName;
  final String contactPerson;
  final String contactPhone;
  final String address;
  final String industry;
  final String clientEmail;
  final String location;
  final String team;
  final List<String> creativeStudioServices;
  final String requirementStatus;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String travelMode;
  final String serviceType;
  final String serviceName;
  final String purpose;
  final String notes;
  final String status;
  final String approvalComment;
  final String approvedBy;
  final String approvedByName;
  final String approvedByRole;
  final DateTime? approvedAt;
  final String tlApprovalComment;
  final String tlApprovedBy;
  final String tlApprovedByName;
  final String tlApprovedByRole;
  final DateTime? tlApprovedAt;
  final String outcome;
  final String followUp;
  final DateTime? officeCheckOutAt;
  final DateTime? reachedClientAt;
  final double? officeCheckOutLatitude;
  final double? officeCheckOutLongitude;
  final double? reachedClientLatitude;
  final double? reachedClientLongitude;
  final double? clientLatitude; // planned destination set at visit creation
  final double? clientLongitude;
  final double? startOdometer;
  final List<Map<String, dynamic>> travelRoute;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final List<dynamic> attendees;
  final List<dynamic> checklist;
  final String returnMode;
  final String managerVerifiedBy;
  final DateTime? managerVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double expenseTotal;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> expenses;

  const ClientVisit({
    required this.id,
    required this.visitId,
    required this.employeeUserId,
    required this.employeeName,
    required this.employeePhotoUrl,
    required this.managerUserId,
    required this.clientName,
    required this.contactPerson,
    required this.contactPhone,
    required this.address,
    this.industry = '',
    this.clientEmail = '',
    this.location = '',
    this.team = '',
    this.creativeStudioServices = const [],
    this.requirementStatus = '',
    required this.scheduledAt,
    required this.durationMinutes,
    required this.travelMode,
    required this.serviceType,
    required this.serviceName,
    required this.purpose,
    required this.notes,
    required this.status,
    required this.approvalComment,
    required this.approvedBy,
    required this.approvedByName,
    required this.approvedByRole,
    required this.approvedAt,
    required this.tlApprovalComment,
    required this.tlApprovedBy,
    required this.tlApprovedByName,
    required this.tlApprovedByRole,
    required this.tlApprovedAt,
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
    required this.startOdometer,
    required this.travelRoute,
    required this.checkInAt,
    required this.checkOutAt,
    required this.attendees,
    required this.checklist,
    required this.returnMode,
    required this.managerVerifiedBy,
    required this.managerVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.expenseTotal,
    required this.attachments,
    required this.expenses,
  });

  factory ClientVisit.fromJson(Map<String, dynamic> json) {
    final date = '${json['scheduled_date'] ?? ''}';
    final time = '${json['scheduled_time'] ?? '00:00'}';
    final serviceType = '${json['service_type'] ?? ''}';
    final backendServiceName = '${json['service_name'] ?? ''}';
    final service = clientVisitServiceById(serviceType);

    var parsedReq = '${json['requirement_status'] ?? json['client_status'] ?? ''}'.trim();
    if (parsedReq.isEmpty || parsedReq == 'null') {
      if (json['checklist'] is List && (json['checklist'] as List).isNotEmpty) {
        final firstItem = (json['checklist'] as List).first;
        if (firstItem is Map && firstItem['status'] != null) {
          parsedReq = '${firstItem['status']}'.trim();
        }
      }
      if (parsedReq.isEmpty || parsedReq == 'null') {
        final outcomeStr = '${json['outcome'] ?? ''}';
        final match = RegExp(r'Customer Requirement Status:\s*([A-Za-z\s]+)', caseSensitive: false).firstMatch(outcomeStr);
        if (match != null) {
          parsedReq = match.group(1)?.trim() ?? '';
        }
      }
      if (parsedReq.isEmpty || parsedReq == 'null') {
        final notesStr = '${json['notes'] ?? ''}';
        final match = RegExp(r'Status:\s*([A-Za-z\s]+)', caseSensitive: false).firstMatch(notesStr);
        if (match != null) {
          parsedReq = match.group(1)?.trim() ?? '';
        }
      }
    }

    return ClientVisit(
      id: int.tryParse('${json['id']}') ?? 0,
      visitId: '${json['visit_id'] ?? ''}',
      employeeUserId: '${json['employee_user_id'] ?? ''}',
      employeeName: '${json['employee_name'] ?? ''}',
      employeePhotoUrl: '${json['employee_photo_url'] ?? ''}',
      managerUserId: '${json['manager_user_id'] ?? ''}',
      clientName: '${json['client_name'] ?? ''}',
      contactPerson: '${json['contact_person'] ?? ''}',
      contactPhone: '${json['contact_phone'] ?? ''}',
      address: '${json['address'] ?? ''}',
      industry: '${json['industry'] ?? ''}',
      clientEmail: '${json['client_email'] ?? json['email'] ?? ''}',
      location: '${json['location'] ?? ''}',
      team: '${json['team'] ?? ''}',
      creativeStudioServices: (json['creative_studio_services'] as List?)
              ?.map((e) => '$e')
              .toList() ??
          const [],
      requirementStatus: parsedReq,
      scheduledAt: DateTime.tryParse('${date}T$time') ?? DateTime.now(),
      durationMinutes: int.tryParse('${json['duration_minutes']}') ?? 60,
      travelMode: '${json['travel_mode'] ?? 'car'}',
      serviceType: serviceType,
      serviceName:
          backendServiceName.isNotEmpty && backendServiceName != serviceType
          ? backendServiceName
          : (service?.name ??
              (clientVisitServiceDisplayName(serviceType).isNotEmpty
                  ? clientVisitServiceDisplayName(serviceType)
                  : backendServiceName)),
      purpose: '${json['purpose'] ?? ''}',
      notes: '${json['notes'] ?? ''}',
      status: '${json['status'] ?? 'draft'}',
      approvalComment: '${json['approval_comment'] ?? ''}',
      approvedBy: '${json['approved_by'] ?? ''}',
      approvedByName: '${json['approved_by_name'] ?? ''}',
      approvedByRole: '${json['approved_by_role'] ?? ''}',
      approvedAt: DateTime.tryParse('${json['approved_at'] ?? ''}'),
      tlApprovalComment: '${json['tl_approval_comment'] ?? ''}',
      tlApprovedBy: '${json['tl_approved_by'] ?? ''}',
      tlApprovedByName: '${json['tl_approved_by_name'] ?? ''}',
      tlApprovedByRole: '${json['tl_approved_by_role'] ?? ''}',
      tlApprovedAt: DateTime.tryParse('${json['tl_approved_at'] ?? ''}'),
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
      startOdometer: double.tryParse('${json['start_odometer'] ?? ''}'),
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
      managerVerifiedAt: DateTime.tryParse(
        '${json['manager_verified_at'] ?? ''}',
      ),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
      expenseTotal: double.tryParse('${json['expense_total']}') ?? 0,
      attachments: _maps(json['attachments']),
      expenses: _maps(json['expenses']),
    );
  }



  ClientVisit copyWith({
    String? requirementStatus,
    String? status,
  }) {
    return ClientVisit(
      id: id,
      visitId: visitId,
      employeeUserId: employeeUserId,
      employeeName: employeeName,
      employeePhotoUrl: employeePhotoUrl,
      managerUserId: managerUserId,
      clientName: clientName,
      contactPerson: contactPerson,
      contactPhone: contactPhone,
      address: address,
      industry: industry,
      clientEmail: clientEmail,
      location: location,
      team: team,
      creativeStudioServices: creativeStudioServices,
      requirementStatus: requirementStatus ?? this.requirementStatus,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      travelMode: travelMode,
      serviceType: serviceType,
      serviceName: serviceName,
      purpose: purpose,
      notes: notes,
      status: status ?? this.status,
      approvalComment: approvalComment,
      approvedBy: approvedBy,
      approvedByName: approvedByName,
      approvedByRole: approvedByRole,
      approvedAt: approvedAt,
      tlApprovalComment: tlApprovalComment,
      tlApprovedBy: tlApprovedBy,
      tlApprovedByName: tlApprovedByName,
      tlApprovedByRole: tlApprovedByRole,
      tlApprovedAt: tlApprovedAt,
      outcome: outcome,
      followUp: followUp,
      officeCheckOutAt: officeCheckOutAt,
      reachedClientAt: reachedClientAt,
      officeCheckOutLatitude: officeCheckOutLatitude,
      officeCheckOutLongitude: officeCheckOutLongitude,
      reachedClientLatitude: reachedClientLatitude,
      reachedClientLongitude: reachedClientLongitude,
      clientLatitude: clientLatitude,
      clientLongitude: clientLongitude,
      startOdometer: startOdometer,
      travelRoute: travelRoute,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      attendees: attendees,
      checklist: checklist,
      returnMode: returnMode,
      managerVerifiedBy: managerVerifiedBy,
      managerVerifiedAt: managerVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expenseTotal: expenseTotal,
      attachments: attachments,
      expenses: expenses,
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


class RequirementStatusOption {
  final String key;
  final String label;
  final String description;
  final int colorValue;
  final IconData icon;

  const RequirementStatusOption({
    required this.key,
    required this.label,
    required this.description,
    required this.colorValue,
    required this.icon,
  });
}

const List<RequirementStatusOption> kRequirementStatusOptions = [
  RequirementStatusOption(
    key: 'required',
    label: 'Required',
    description: 'Customer needs the service',
    colorValue: 0xFF10B981, // Green
    icon: Icons.check_circle_rounded,
  ),
  RequirementStatusOption(
    key: 'not_required',
    label: 'Not Required',
    description: 'Customer does not need the service',
    colorValue: 0xFF94A3B8, // Grey
    icon: Icons.cancel_rounded,
  ),
  RequirementStatusOption(
    key: 'interested',
    label: 'Interested',
    description: "Customer is interested but hasn't confirmed",
    colorValue: 0xFF00E5FF, // Cyan
    icon: Icons.thumb_up_rounded,
  ),
  RequirementStatusOption(
    key: 'need_to_discuss',
    label: 'Need to Discuss',
    description: 'Customer needs more information',
    colorValue: 0xFF3B82F6, // Blue
    icon: Icons.forum_rounded,
  ),
  RequirementStatusOption(
    key: 'future_requirement',
    label: 'Future Requirement',
    description: 'Customer may need the service later',
    colorValue: 0xFFFF9100, // Orange
    icon: Icons.schedule_rounded,
  ),
  RequirementStatusOption(
    key: 'already_have',
    label: 'Already Have',
    description: 'Customer already has the service',
    colorValue: 0xFFA855F7, // Purple
    icon: Icons.inventory_2_rounded,
  ),
  RequirementStatusOption(
    key: 'not_decided',
    label: 'Not Decided',
    description: "Customer hasn't decided yet",
    colorValue: 0xFFEAB308, // Yellow
    icon: Icons.help_outline_rounded,
  ),
];

String requirementStatusLabel(String key) {
  final clean = key.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  for (final opt in kRequirementStatusOptions) {
    if (opt.key == clean || opt.label.toLowerCase() == key.trim().toLowerCase()) {
      return opt.label;
    }
  }
  return key.trim();
}

int requirementStatusColorValue(String key) {
  final clean = key.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  for (final opt in kRequirementStatusOptions) {
    if (opt.key == clean || opt.label.toLowerCase() == key.trim().toLowerCase()) {
      return opt.colorValue;
    }
  }
  return 0xFF78909C;
}

IconData requirementStatusIcon(String key) {
  final clean = key.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  for (final opt in kRequirementStatusOptions) {
    if (opt.key == clean || opt.label.toLowerCase() == key.trim().toLowerCase()) {
      return opt.icon;
    }
  }
  return Icons.stars_rounded;
}
