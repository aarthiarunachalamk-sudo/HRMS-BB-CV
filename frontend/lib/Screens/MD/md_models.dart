class MdParticipant {
  final String name;
  final String role;
  final bool selected;

  const MdParticipant({
    required this.name,
    required this.role,
    this.selected = false,
  });

  MdParticipant copyWith({bool? selected}) {
    return MdParticipant(
      name: name,
      role: role,
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'selected': selected,
      };

  factory MdParticipant.fromJson(Map<String, dynamic> json) {
    return MdParticipant(
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      selected: json['selected'] == true,
    );
  }
}

class MdMeeting {
  final int? id;
  final String title;
  final String meetingType;
  final String location;
  final String description;
  final String dateLabel;
  final String timeLabel;
  final String duration;
  final String status;
  final List<MdParticipant> participants;
  final List<String> agenda;

  const MdMeeting({
    this.id,
    required this.title,
    required this.meetingType,
    required this.location,
    required this.description,
    required this.dateLabel,
    required this.timeLabel,
    required this.duration,
    required this.status,
    required this.participants,
    required this.agenda,
  });

  factory MdMeeting.empty({
    required String dateLabel,
    required String timeLabel,
    required String duration,
    List<MdParticipant> participants = const <MdParticipant>[],
  }) {
    return MdMeeting(
      title: '',
      meetingType: '',
      location: '',
      description: '',
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      duration: duration,
      status: 'upcoming',
      participants: participants,
      agenda: const <String>[],
    );
  }

  MdMeeting copyWith({
    int? id,
    String? title,
    String? meetingType,
    String? location,
    String? description,
    String? dateLabel,
    String? timeLabel,
    String? duration,
    String? status,
    List<MdParticipant>? participants,
    List<String>? agenda,
  }) {
    return MdMeeting(
      id: id ?? this.id,
      title: title ?? this.title,
      meetingType: meetingType ?? this.meetingType,
      location: location ?? this.location,
      description: description ?? this.description,
      dateLabel: dateLabel ?? this.dateLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      agenda: agenda ?? this.agenda,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'meeting_type': meetingType,
        'location': location,
        'description': description,
        'date_label': dateLabel,
        'time_label': timeLabel,
        'duration': duration,
        'status': status,
        'participants': participants.map((item) => item.toJson()).toList(),
        'agenda': agenda,
      };

  factory MdMeeting.fromJson(Map<String, dynamic> json) {
    final participantJson = json['participants'];
    final agendaJson = json['agenda'];
    return MdMeeting(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      title: json['title']?.toString() ?? '',
      meetingType: json['meeting_type']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dateLabel: json['date_label']?.toString() ?? '',
      timeLabel: json['time_label']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      status: json['status']?.toString() ?? 'upcoming',
      participants: participantJson is List
          ? participantJson
              .whereType<Map>()
              .map((item) => MdParticipant.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const <MdParticipant>[],
      agenda: agendaJson is List ? agendaJson.map((item) => item.toString()).toList() : const <String>[],
    );
  }
}

class MdDashboardData {
  final String totalRevenue;
  final String totalEmployees;
  final int pendingApprovals;
  final int meetingsToday;
  final List<MdMeeting> meetings;
  final List<MdParticipant> participants;

  const MdDashboardData({
    required this.totalRevenue,
    required this.totalEmployees,
    required this.pendingApprovals,
    required this.meetingsToday,
    required this.meetings,
    required this.participants,
  });

  static const empty = MdDashboardData(
    totalRevenue: '0',
    totalEmployees: '0',
    pendingApprovals: 0,
    meetingsToday: 0,
    meetings: <MdMeeting>[],
    participants: <MdParticipant>[],
  );

  factory MdDashboardData.fromJson(Map<String, dynamic> json) {
    final meetingsJson = json['meetings'];
    final participantsJson = json['participants'];
    return MdDashboardData(
      totalRevenue: json['total_revenue']?.toString() ?? '0',
      totalEmployees: json['total_employees']?.toString() ?? '0',
      pendingApprovals: int.tryParse('${json['pending_approvals'] ?? 0}') ?? 0,
      meetingsToday: int.tryParse('${json['meetings_today'] ?? 0}') ?? 0,
      meetings: meetingsJson is List
          ? meetingsJson
              .whereType<Map>()
              .map((item) => MdMeeting.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const <MdMeeting>[],
      participants: participantsJson is List
          ? participantsJson
              .whereType<Map>()
              .map((item) => MdParticipant.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const <MdParticipant>[],
    );
  }
}
