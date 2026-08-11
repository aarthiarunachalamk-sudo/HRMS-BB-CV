class JourneyLocationPoint {
  final String clientGeneratedId;
  final int journeyId;
  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final double? altitude;
  final double? speedMetresPerSecond;
  final double? heading;
  final DateTime capturedAt;
  final DateTime? receivedAt;
  final int sequenceNumber;
  final bool? isMocked;
  final bool isLowAccuracy;
  final bool isSuspicious;

  const JourneyLocationPoint({
    required this.clientGeneratedId,
    required this.journeyId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    this.altitude,
    this.speedMetresPerSecond,
    this.heading,
    required this.capturedAt,
    this.receivedAt,
    required this.sequenceNumber,
    this.isMocked,
    this.isLowAccuracy = false,
    this.isSuspicious = false,
  });

  factory JourneyLocationPoint.fromJson(Map<String, dynamic> json) =>
      JourneyLocationPoint(
        clientGeneratedId: '${json['client_generated_id'] ?? ''}',
        journeyId: _integer(json['journey_id']),
        latitude: _number(json['latitude']),
        longitude: _number(json['longitude']),
        accuracyMetres: _number(json['accuracy_metres']),
        altitude: _nullableNumber(json['altitude']),
        speedMetresPerSecond: _nullableNumber(json['speed_metres_per_second']),
        heading: _nullableNumber(json['heading']),
        capturedAt: DateTime.parse('${json['captured_at']}').toUtc(),
        receivedAt: json['received_at'] == null
            ? null
            : DateTime.parse('${json['received_at']}').toUtc(),
        sequenceNumber: _integer(json['sequence_number']),
        isMocked: json['is_mocked'] as bool?,
        isLowAccuracy: json['is_low_accuracy'] == true,
        isSuspicious: json['is_suspicious'] == true,
      );

  Map<String, dynamic> toUploadJson() => {
    'client_generated_id': clientGeneratedId,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_metres': accuracyMetres,
    'altitude': altitude,
    'speed_metres_per_second': speedMetresPerSecond,
    'heading': heading,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'sequence_number': sequenceNumber,
    'is_mocked': isMocked,
  };
}

class ClientJourney {
  final int id;
  final String employeeId;
  final String employeeName;
  final String assignedTeamLeadId;
  final String clientName;
  final String clientContact;
  final String meetingPurpose;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final DateTime scheduledAt;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastLocationAt;
  final String cancelReason;
  final double totalDistanceMetres;
  final int totalDurationSeconds;
  final int movingDurationSeconds;
  final int stationaryDurationSeconds;
  final int pointCount;
  final int lowAccuracyPointCount;
  final int stopCount;

  const ClientJourney({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.assignedTeamLeadId,
    required this.clientName,
    required this.clientContact,
    required this.meetingPurpose,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.scheduledAt,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.lastLocationAt,
    required this.cancelReason,
    required this.totalDistanceMetres,
    required this.totalDurationSeconds,
    required this.movingDurationSeconds,
    required this.stationaryDurationSeconds,
    required this.pointCount,
    required this.lowAccuracyPointCount,
    required this.stopCount,
  });

  bool get isActive => status == 'IN_PROGRESS' || status == 'PAUSED';

  factory ClientJourney.fromJson(Map<String, dynamic> json) => ClientJourney(
    id: _integer(json['id']),
    employeeId: '${json['employee_id'] ?? ''}',
    employeeName: '${json['employee_name'] ?? ''}',
    assignedTeamLeadId: '${json['assigned_team_lead_id'] ?? ''}',
    clientName: '${json['client_name'] ?? ''}',
    clientContact: '${json['client_contact'] ?? ''}',
    meetingPurpose: '${json['meeting_purpose'] ?? ''}',
    destinationAddress: '${json['destination_address'] ?? ''}',
    destinationLatitude: _number(json['destination_latitude']),
    destinationLongitude: _number(json['destination_longitude']),
    scheduledAt: DateTime.parse('${json['scheduled_at']}').toUtc(),
    status: '${json['status'] ?? ''}',
    startedAt: _date(json['started_at']),
    completedAt: _date(json['completed_at']),
    lastLocationAt: _date(json['last_location_at']),
    cancelReason: '${json['cancel_reason'] ?? ''}',
    totalDistanceMetres: _number(json['total_distance_metres']),
    totalDurationSeconds: _integer(json['total_duration_seconds']),
    movingDurationSeconds: _integer(json['moving_duration_seconds']),
    stationaryDurationSeconds: _integer(json['stationary_duration_seconds']),
    pointCount: _integer(json['point_count']),
    lowAccuracyPointCount: _integer(json['low_accuracy_point_count']),
    stopCount: _integer(json['stop_count']),
  );
}

double _number(dynamic value) => double.tryParse('$value') ?? 0;
double? _nullableNumber(dynamic value) =>
    value == null ? null : double.tryParse('$value');
int _integer(dynamic value) => int.tryParse('$value') ?? 0;
DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse('$value')?.toUtc();
