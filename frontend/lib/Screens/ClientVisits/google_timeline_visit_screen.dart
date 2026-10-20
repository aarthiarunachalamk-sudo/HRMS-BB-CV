import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import 'client_visit_models.dart';
import 'client_visit_service.dart';
import 'client_visit_theme.dart';
import 'client_visit_team_members.dart';

/// Represents a staff member for live tracking across Marketing and Development teams.
class LiveStaffMember {
  final String id;
  final String name;
  final String role;
  final String team; // 'marketing' or 'development'
  final String phone;
  final String email;
  final bool isLiveActive;
  final int currentStopIndex; // 0 to 9 (corresponds to Stop 1 to 10)
  final int totalStopsToday;
  final String currentStatusText;

  const LiveStaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.team,
    this.phone = '',
    this.email = '',
    this.isLiveActive = true,
    this.currentStopIndex = 3, // Default to stop 4 being active
    this.totalStopsToday = 10,
    this.currentStatusText = 'En Route to Stop #4',
  });
}

/// Represents one of the dynamic 10 stops visited/scheduled in a single day.
class TimelinePlaceStop {
  final int stopNumber; // 1 to 10
  final String clientName;
  final String address;
  final ll.LatLng location;
  final String serviceName;
  final String requirementStatus;
  final String contactPerson;
  final String contactPhone;
  final String arrivalTimeStr;
  final String departureTimeStr;
  final String transitFromPrev;
  final double distanceKm;
  final String stopStatus; // 'completed', 'active', 'travelling', 'upcoming'
  final ClientVisit? underlyingVisit;

  const TimelinePlaceStop({
    required this.stopNumber,
    required this.clientName,
    required this.address,
    required this.location,
    required this.serviceName,
    required this.requirementStatus,
    this.contactPerson = '',
    this.contactPhone = '',
    required this.arrivalTimeStr,
    required this.departureTimeStr,
    required this.transitFromPrev,
    required this.distanceKm,
    required this.stopStatus,
    this.underlyingVisit,
  });
}

class GoogleTimelineVisitScreen extends StatefulWidget {
  final ClientVisit? visit;
  final List<ClientVisit> allVisits;
  final String userId;
  final ClientVisitService? service;
  final String? initialStaffId;
  final String? initialStaffName;

  const GoogleTimelineVisitScreen({
    super.key,
    this.visit,
    this.allVisits = const [],
    required this.userId,
    this.service,
    this.initialStaffId,
    this.initialStaffName,
  });

  @override
  State<GoogleTimelineVisitScreen> createState() =>
      _GoogleTimelineVisitScreenState();
}

class _GoogleTimelineVisitScreenState extends State<GoogleTimelineVisitScreen> {
  final MapController _mapController = MapController();
  late DateTime _selectedDate;
  late List<ClientVisit> _visits;
  late String _selectedStaffId;
  String _staffSearchQuery = '';
  String _selectedTeamFilter = 'all'; // 'all', 'marketing', 'development', 'active'
  int _selectedStopIndex = -1; // -1 means whole route overview, 0..9 means Stop 1..10
  bool _loading = false;
  Timer? _liveRefreshTimer;

  // BitByte HQ default start coords (Salem, Tamil Nadu)
  static const double _officeLat = 11.6643;
  static const double _officeLng = 78.1460;
  static const ll.LatLng _officePoint = ll.LatLng(_officeLat, _officeLng);

  @override
  void initState() {
    super.initState();
    _visits = List<ClientVisit>.from(widget.allVisits);
    if (widget.visit != null && !_visits.any((v) => v.id == widget.visit!.id)) {
      _visits.add(widget.visit!);
    }

    final initialDate = widget.visit?.scheduledAt ?? DateTime.now();
    _selectedDate = DateTime(initialDate.year, initialDate.month, initialDate.day);

    // Initial staff selection priority
    if (widget.initialStaffId != null && widget.initialStaffId!.isNotEmpty) {
      _selectedStaffId = widget.initialStaffId!;
    } else if (widget.visit != null && widget.visit!.employeeUserId.isNotEmpty) {
      _selectedStaffId = widget.visit!.employeeUserId;
    } else if (kMarketingMembers.isNotEmpty) {
      _selectedStaffId = kMarketingMembers.first.id;
    } else {
      _selectedStaffId = 'BB-MKT-001';
    }

    if (_visits.isEmpty) {
      _loadVisits();
    }

    // Auto-refresh live tracking every 12 seconds
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    final s = widget.service ?? ClientVisitService();
    setState(() => _loading = true);
    try {
      final res = await s.fetchVisits(widget.userId);
      if (mounted) {
        setState(() {
          _visits = res.visits;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Unified Staff Members List (Marketing + Development + Local) ──
  List<LiveStaffMember> get _allStaffMembers {
    final list = <LiveStaffMember>[];

    // 1. Marketing Team Members
    for (int i = 0; i < kMarketingMembers.length; i++) {
      final m = kMarketingMembers[i];
      // Distribute realistic live states for active demo
      final isActive = i % 2 == 0;
      final stopIdx = (i * 2 + 3) % 10;
      list.add(
        LiveStaffMember(
          id: m.id,
          name: m.name,
          role: m.role,
          team: 'marketing',
          phone: m.phone,
          email: m.email,
          isLiveActive: isActive,
          currentStopIndex: stopIdx,
          totalStopsToday: 10,
          currentStatusText: isActive
              ? (stopIdx % 2 == 0
                  ? 'At Client Premises (Stop #${stopIdx + 1})'
                  : 'Travelling En Route to Stop #${stopIdx + 1}')
              : 'Completed 10/10 Stops Today',
        ),
      );
    }

    // 2. Development Team Members
    for (int i = 0; i < kDevelopmentMembers.length; i++) {
      final m = kDevelopmentMembers[i];
      final isActive = i % 2 == 1;
      final stopIdx = (i * 3 + 2) % 10;
      list.add(
        LiveStaffMember(
          id: m.id,
          name: m.name,
          role: m.role,
          team: 'development',
          phone: m.phone,
          email: m.email,
          isLiveActive: isActive,
          currentStopIndex: stopIdx,
          totalStopsToday: 10,
          currentStatusText: isActive
              ? (stopIdx % 2 == 0
                  ? 'At Client Premises (Stop #${stopIdx + 1})'
                  : 'Travelling En Route to Stop #${stopIdx + 1}')
              : 'Completed 10/10 Stops Today',
        ),
      );
    }

    // 3. Dynamic visits employees from database
    for (final v in _visits) {
      if (v.employeeUserId.isNotEmpty &&
          !list.any((s) => s.id == v.employeeUserId || s.name == v.employeeName)) {
        list.add(
          LiveStaffMember(
            id: v.employeeUserId,
            name: v.employeeName.isNotEmpty ? v.employeeName : 'Staff Member',
            role: v.team.isNotEmpty ? '${v.team.toUpperCase()} Specialist' : 'Field Representative',
            team: v.team.toLowerCase().contains('dev') ? 'development' : 'marketing',
            phone: v.contactPhone,
            isLiveActive: v.status == 'travelling' || v.status == 'in_progress',
            currentStopIndex: 4,
            totalStopsToday: 10,
            currentStatusText: v.status == 'travelling'
                ? 'Travelling En Route to Client'
                : 'Active at Client Premises',
          ),
        );
      }
    }

    return list;
  }

  List<LiveStaffMember> get _filteredStaffMembers {
    return _allStaffMembers.where((staff) {
      // Team filter
      if (_selectedTeamFilter == 'marketing' && staff.team != 'marketing') {
        return false;
      }
      if (_selectedTeamFilter == 'development' && staff.team != 'development') {
        return false;
      }
      if (_selectedTeamFilter == 'active' && !staff.isLiveActive) {
        return false;
      }
      // Search query
      if (_staffSearchQuery.trim().isNotEmpty) {
        final q = _staffSearchQuery.trim().toLowerCase();
        final match = staff.name.toLowerCase().contains(q) ||
            staff.id.toLowerCase().contains(q) ||
            staff.role.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  LiveStaffMember get _selectedStaff {
    final staffList = _allStaffMembers;
    final found = staffList.firstWhere(
      (s) => s.id == _selectedStaffId,
      orElse: () => staffList.isNotEmpty
          ? staffList.first
          : const LiveStaffMember(
              id: 'BB-MKT-001',
              name: 'Karthik M',
              role: 'Marketing Lead',
              team: 'marketing',
            ),
    );
    return found;
  }

  // ── Dynamic 10 Stops per Day for Selected Person ──
  List<TimelinePlaceStop> _buildTenPlacesFor(LiveStaffMember staff, DateTime date) {
    final isDev = staff.team == 'development';
    final isToday = _isToday(date);
    final activeStopIdx = staff.currentStopIndex;

    // Base coordinate locations around Salem & surrounding industrial zones
    final marketingStopsData = [
      {
        'client': 'Apex Tech Solutions',
        'address': '142/3 Fairlands Main Road, Opp. Reliance Trends, Salem - 636016',
        'lat': 11.6745,
        'lng': 78.1410,
        'service': 'Meta Ads & Brand Identity',
        'status': 'INTERESTED',
        'contact': 'Rajesh Verma',
        'phone': '+91 98401 22331',
        'arr': '09:30 AM',
        'dep': '10:15 AM',
        'transit': '4.2 km · 14 mins from BitByte Salem HQ',
        'km': 4.2,
      },
      {
        'client': 'Tata Motors Dealership',
        'address': 'Kandhampatti Bypass, NH44, Near Flyover, Salem - 636005',
        'lat': 11.6420,
        'lng': 78.1180,
        'service': 'Creative Studio & Ad Creatives',
        'status': 'REQUIREMENT CONFIRMED',
        'contact': 'Anandhan K',
        'phone': '+91 98401 33442',
        'arr': '10:35 AM',
        'dep': '11:20 AM',
        'transit': '5.8 km · 18 mins from Fairlands',
        'km': 5.8,
      },
      {
        'client': 'Zenith Retail Hub',
        'address': '58 Meyyanur Bypass Road, Near New Bus Stand, Salem - 636004',
        'lat': 11.6612,
        'lng': 78.1345,
        'service': 'Social Media Marketing & Reels Production',
        'status': 'PROPOSAL UNDER REVIEW',
        'contact': 'Senthil Nathan',
        'phone': '+91 98401 44553',
        'arr': '11:40 AM',
        'dep': '12:25 PM',
        'transit': '3.9 km · 12 mins from Kandhampatti',
        'km': 3.9,
      },
      {
        'client': 'Greenfield Organics',
        'address': '89/2 Alagapuram Main Road, Periyapudur, Salem - 636016',
        'lat': 11.6820,
        'lng': 78.1480,
        'service': 'Paid Advertising & Google Ads Campaign',
        'status': 'INTERESTED',
        'contact': 'Dr. Manivannan',
        'phone': '+91 98401 55664',
        'arr': '12:45 PM',
        'dep': '01:30 PM',
        'transit': '3.4 km · 11 mins from Meyyanur',
        'km': 3.4,
      },
      {
        'client': 'Skyline Real Estate',
        'address': '21 Hasthampatti Roundana, Yercaud Foot Hills, Salem - 636007',
        'lat': 11.6890,
        'lng': 78.1620,
        'service': 'Lead Generation & Video Shoots',
        'status': 'ACTIVE CLIENT ORDER',
        'contact': 'Murali Dharan',
        'phone': '+91 98401 66775',
        'arr': '02:15 PM',
        'dep': '03:00 PM',
        'transit': '4.1 km · 15 mins from Alagapuram',
        'km': 4.1,
      },
      {
        'client': 'MedPlus Pharmacy Hub',
        'address': '34 Trichy Main Road, Gugai, Salem - 636006',
        'lat': 11.6480,
        'lng': 78.1560,
        'service': 'Enterprise SEO Audit & WhatsApp API',
        'status': 'FOLLOW UP SCHEDULED',
        'contact': 'R. Balaji',
        'phone': '+91 98401 77886',
        'arr': '03:20 PM',
        'dep': '04:00 PM',
        'transit': '5.2 km · 19 mins from Hasthampatti',
        'km': 5.2,
      },
      {
        'client': 'Apollo Tyre Distributors',
        'address': '112 Junction Road, Suramangalam, Salem - 636005',
        'lat': 11.6710,
        'lng': 78.1120,
        'service': 'WhatsApp CRM Automation & Chatbot',
        'status': 'REQUIREMENT CONFIRMED',
        'contact': 'Praveen Kumar',
        'phone': '+91 98401 88997',
        'arr': '04:20 PM',
        'dep': '05:05 PM',
        'transit': '6.4 km · 21 mins from Gugai',
        'km': 6.4,
      },
      {
        'client': 'Velan Silks Enterprise',
        'address': '76 Bazaar Street, Shevapet Commercial Belt, Salem - 636002',
        'lat': 11.6560,
        'lng': 78.1380,
        'service': 'Festive Campaign & Catalog Photo Shoot',
        'status': 'INTERESTED',
        'contact': 'Velusamy',
        'phone': '+91 98401 99008',
        'arr': '05:25 PM',
        'dep': '06:05 PM',
        'transit': '3.8 km · 13 mins from Suramangalam',
        'km': 3.8,
      },
      {
        'client': 'Prime Logistics Corp',
        'address': '45 Ammapet Main Road, Near Old Colony, Salem - 636003',
        'lat': 11.6590,
        'lng': 78.1810,
        'service': 'Google Business Profile & Local Map Ads',
        'status': 'FOLLOW UP SCHEDULED',
        'contact': 'Karthikeyan',
        'phone': '+91 98402 11229',
        'arr': '06:20 PM',
        'dep': '07:00 PM',
        'transit': '5.1 km · 18 mins from Shevapet',
        'km': 5.1,
      },
      {
        'client': 'Heritage Foods Central',
        'address': 'NH44 Bypass Junction, Seelanaickenpatti, Salem - 636201',
        'lat': 11.6280,
        'lng': 78.1520,
        'service': 'Brand Outreach & Packaging Design',
        'status': 'ACTIVE CLIENT ORDER',
        'contact': 'Gunasekaran',
        'phone': '+91 98402 22330',
        'arr': '07:15 PM',
        'dep': '07:55 PM',
        'transit': '5.6 km · 20 mins from Ammapet',
        'km': 5.6,
      },
    ];

    final devStopsData = [
      {
        'client': 'Apex Financial Corp',
        'address': '114 Fairlands Executive Tower, Salem - 636016',
        'lat': 11.6745,
        'lng': 78.1410,
        'service': 'Dynamic Web App Architecture & Cloud Deployment',
        'status': 'REQUIREMENT CONFIRMED',
        'contact': 'Ganesh Subramanian',
        'phone': '+91 98402 33441',
        'arr': '09:30 AM',
        'dep': '10:15 AM',
        'transit': '4.2 km · 14 mins from BitByte HQ',
        'km': 4.2,
      },
      {
        'client': 'Skyline ERP Solutions',
        'address': '72 Meyyanur High Road, Salem - 636004',
        'lat': 11.6612,
        'lng': 78.1345,
        'service': 'Cloud ERP Database Migration & API Integration',
        'status': 'INTERESTED',
        'contact': 'Venkatesh R',
        'phone': '+91 98402 44552',
        'arr': '10:35 AM',
        'dep': '11:20 AM',
        'transit': '3.9 km · 12 mins from Fairlands',
        'km': 3.9,
      },
      {
        'client': 'GreenTech IoT Labs',
        'address': '18 Alagapuram Tech Park, Salem - 636016',
        'lat': 11.6820,
        'lng': 78.1480,
        'service': 'Mobile App Hardware API Integration & Telemetry',
        'status': 'ACTIVE CLIENT ORDER',
        'contact': 'Murugesan',
        'phone': '+91 98402 55663',
        'arr': '11:40 AM',
        'dep': '12:25 PM',
        'transit': '3.4 km · 11 mins from Meyyanur',
        'km': 3.4,
      },
      {
        'client': 'Velan E-Commerce Central',
        'address': '102 Shevapet Textile Mall, Salem - 636002',
        'lat': 11.6560,
        'lng': 78.1380,
        'service': 'Payment Gateway & Multi-Vendor Inventory Sync',
        'status': 'PROPOSAL UNDER REVIEW',
        'contact': 'Mohan Kumar',
        'phone': '+91 98402 66774',
        'arr': '12:45 PM',
        'dep': '01:30 PM',
        'transit': '4.3 km · 15 mins from Alagapuram',
        'km': 4.3,
      },
      {
        'client': 'Prime Logistics IT Centre',
        'address': '88 Ammapet Industrial Estate, Salem - 636003',
        'lat': 11.6590,
        'lng': 78.1810,
        'service': 'Real-time GPS Tracking Engine & Dispatch Portal',
        'status': 'REQUIREMENT CONFIRMED',
        'contact': 'Saravanan',
        'phone': '+91 98402 77885',
        'arr': '02:15 PM',
        'dep': '03:00 PM',
        'transit': '5.1 km · 17 mins from Shevapet',
        'km': 5.1,
      },
      {
        'client': 'MedPlus Cloud Health',
        'address': '64 Trichy Road Medical Enclave, Gugai, Salem - 636006',
        'lat': 11.6480,
        'lng': 78.1560,
        'service': 'Patient EHR Portal & Doctor Tele-consultation App',
        'status': 'INTERESTED',
        'contact': 'Dr. Sivakumar',
        'phone': '+91 98402 88996',
        'arr': '03:20 PM',
        'dep': '04:00 PM',
        'transit': '4.8 km · 16 mins from Ammapet',
        'km': 4.8,
      },
      {
        'client': 'Kandhampatti Auto Automation',
        'address': 'Kandhampatti Industrial Corridor, Salem - 636005',
        'lat': 11.6420,
        'lng': 78.1180,
        'service': 'Vehicle Telematics & OBD-II Diagnostics API',
        'status': 'FOLLOW UP SCHEDULED',
        'contact': 'Dhanapal',
        'phone': '+91 98402 99007',
        'arr': '04:20 PM',
        'dep': '05:05 PM',
        'transit': '5.5 km · 19 mins from Gugai',
        'km': 5.5,
      },
      {
        'client': 'Hasthampatti Smart Systems',
        'address': '30 Hasthampatti Valley Plaza, Salem - 636007',
        'lat': 11.6890,
        'lng': 78.1620,
        'service': 'Microservices Backend & Docker Kubernetes Cluster',
        'status': 'ACTIVE CLIENT ORDER',
        'contact': 'Naveen Raj',
        'phone': '+91 98403 11228',
        'arr': '05:25 PM',
        'dep': '06:05 PM',
        'transit': '6.8 km · 22 mins from Kandhampatti',
        'km': 6.8,
      },
      {
        'client': 'Suramangalam Warehouse Tech',
        'address': '145 Junction Godown Road, Suramangalam, Salem - 636005',
        'lat': 11.6710,
        'lng': 78.1120,
        'service': 'Barcode Scanner Mobile Client & Offline Sync',
        'status': 'REQUIREMENT CONFIRMED',
        'contact': 'Shanmugam',
        'phone': '+91 98403 22339',
        'arr': '06:20 PM',
        'dep': '07:00 PM',
        'transit': '6.1 km · 20 mins from Hasthampatti',
        'km': 6.1,
      },
      {
        'client': 'Seelanaickenpatti Industrial ERP',
        'address': 'NH44 Manufacturing Zone, Seelanaickenpatti, Salem - 636201',
        'lat': 11.6280,
        'lng': 78.1520,
        'service': 'Multi-tenant SaaS Architecture Final Verification',
        'status': 'PROPOSAL UNDER REVIEW',
        'contact': 'Jayaprakash',
        'phone': '+91 98403 33440',
        'arr': '07:15 PM',
        'dep': '07:55 PM',
        'transit': '6.4 km · 22 mins from Suramangalam',
        'km': 6.4,
      },
    ];

    final rawSource = isDev ? devStopsData : marketingStopsData;

    // Check if staff member has actual visits from backend on this day
    final realVisitsForStaff = _visits.where((v) {
      final isSameEmp = v.employeeUserId == staff.id ||
          v.employeeName.toLowerCase().trim() == staff.name.toLowerCase().trim();
      final local = v.scheduledAt.toLocal();
      return isSameEmp &&
          local.year == date.year &&
          local.month == date.month &&
          local.day == date.day;
    }).toList();

    final result = <TimelinePlaceStop>[];

    for (int i = 0; i < 10; i++) {
      final raw = rawSource[i % rawSource.length];

      // Determine stop status based on live progress
      String status;
      if (!isToday) {
        final now = DateTime.now();
        status = date.isBefore(DateTime(now.year, now.month, now.day))
            ? 'completed'
            : 'upcoming';
      } else {
        if (i < activeStopIdx) {
          status = 'completed';
        } else if (i == activeStopIdx) {
          status = staff.isLiveActive ? 'active' : 'completed';
        } else if (i == activeStopIdx + 1 && staff.isLiveActive) {
          status = 'travelling';
        } else {
          status = 'upcoming';
        }
      }

      // If an actual visit exists at this index, overlay its true client details
      ClientVisit? realVisit;
      if (i < realVisitsForStaff.length) {
        realVisit = realVisitsForStaff[i];
      }

      final client = realVisit?.clientName.isNotEmpty == true
          ? realVisit!.clientName
          : raw['client'] as String;
      final addr = realVisit?.address.isNotEmpty == true
          ? realVisit!.address
          : raw['address'] as String;
      final lat = realVisit?.clientLatitude != null && realVisit!.clientLatitude! != 0.0
          ? realVisit.clientLatitude!
          : raw['lat'] as double;
      final lng = realVisit?.clientLongitude != null && realVisit!.clientLongitude! != 0.0
          ? realVisit.clientLongitude!
          : raw['lng'] as double;
      final srv = realVisit?.serviceName.isNotEmpty == true
          ? realVisit!.serviceName
          : raw['service'] as String;
      final req = realVisit?.requirementStatus.isNotEmpty == true
          ? realVisit!.requirementStatus.replaceAll('_', ' ').toUpperCase()
          : raw['status'] as String;
      final cnt = realVisit?.contactPerson.isNotEmpty == true
          ? realVisit!.contactPerson
          : raw['contact'] as String;
      final ph = realVisit?.contactPhone.isNotEmpty == true
          ? realVisit!.contactPhone
          : raw['phone'] as String;

      result.add(
        TimelinePlaceStop(
          stopNumber: i + 1,
          clientName: client,
          address: addr,
          location: ll.LatLng(lat, lng),
          serviceName: srv,
          requirementStatus: req,
          contactPerson: cnt,
          contactPhone: ph,
          arrivalTimeStr: raw['arr'] as String,
          departureTimeStr: raw['dep'] as String,
          transitFromPrev: raw['transit'] as String,
          distanceKm: (raw['km'] as num).toDouble(),
          stopStatus: status,
          underlyingVisit: realVisit,
        ),
      );
    }

    return result;
  }

  // ── Polyline Route connecting all 10 Places ──
  List<ll.LatLng> _buildFullRoutePolyline(List<TimelinePlaceStop> stops) {
    final points = <ll.LatLng>[_officePoint];
    for (final s in stops) {
      points.add(s.location);
    }
    points.add(_officePoint); // return to HQ
    return points;
  }

  // ── Staff Member Current Live Position Marker ──
  ll.LatLng _calculateStaffLivePosition(
    LiveStaffMember staff,
    List<TimelinePlaceStop> stops,
  ) {
    if (stops.isEmpty) return _officePoint;
    final idx = staff.currentStopIndex;
    if (idx >= 0 && idx < stops.length) {
      return stops[idx].location;
    }
    return stops.first.location;
  }

  double _totalRouteDistanceKm(List<TimelinePlaceStop> stops) {
    double total = 0.0;
    for (final s in stops) {
      total += s.distanceKm;
    }
    // Return leg to Salem HQ
    total += 4.5;
    return total;
  }

  Future<void> _openGoogleMapsNavigation(TimelinePlaceStop stop) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$_officeLat,$_officeLng&destination=${stop.location.latitude},${stop.location.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _selectedStopIndex = -1;
      });
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

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final staffList = _filteredStaffMembers;
    final currentStaff = _selectedStaff;
    final stops = _buildTenPlacesFor(currentStaff, _selectedDate);

    return ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF10B981), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Staff Tracking & Timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF00E5FF)),
              tooltip: 'Choose Date',
              onPressed: _openDatePicker,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // 1. Staff Members Directory (Marketing & Development)
                  _buildStaffDirectorySection(isDark, staffList),
                  const SizedBox(height: 14),

                  // 2. Active Staff Hero Card & Live Status Indicator
                  _buildActiveStaffBanner(isDark, currentStaff, stops),
                  const SizedBox(height: 12),

                  // 3. Calendar Strip Navigation
                  _buildCalendarSection(isDark),
                  const SizedBox(height: 14),

                  // 4. Quick Stop Navigator Chips (Stop 1 to Stop 10)
                  _buildStopNavigator(isDark, stops),
                  const SizedBox(height: 12),

                  // 5. Interactive Multi-Stop Map with 10 Pins & Polyline
                  _buildMultiStopMapSection(isDark, currentStaff, stops),
                  const SizedBox(height: 16),

                  // 6. Detailed Google Timeline Feed for all 10 places
                  _buildTenStopsTimelineFeed(isDark, currentStaff, stops),
                ],
              ),
      ),
    );
  }

  // ── 1. Staff Members Directory Header & Horizontal Card Selector ──
  Widget _buildStaffDirectorySection(bool isDark, List<LiveStaffMember> staffList) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 35 : 10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_rounded, color: Color(0xFF1A73E8), size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TEAM MEMBERS (Marketing & Development)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                ),
                child: Text(
                  '${_allStaffMembers.length} Staff Total',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _staffSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search staff by name, ID or team...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _staffSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => setState(() => _staffSearchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Team Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTeamFilterChip('all', 'All Teams', Icons.groups_rounded, isDark),
                const SizedBox(width: 6),
                _buildTeamFilterChip('marketing', 'Marketing Team', Icons.campaign_rounded, isDark),
                const SizedBox(width: 6),
                _buildTeamFilterChip('development', 'Development Team', Icons.code_rounded, isDark),
                const SizedBox(width: 6),
                _buildTeamFilterChip('active', '● Live Active', Icons.radar_rounded, isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Staff Cards List
          if (staffList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No staff members match "$_staffSearchQuery"',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: staffList.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  final isSelected = staff.id == _selectedStaffId;
                  final isDev = staff.team == 'development';
                  final teamColor = isDev ? const Color(0xFF00E5FF) : const Color(0xFFFF9100);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStaffId = staff.id;
                        _selectedStopIndex = -1; // reset to full view
                      });
                      // Auto-center map on selected staff's current position
                      final currentStops = _buildTenPlacesFor(staff, _selectedDate);
                      final pos = _calculateStaffLivePosition(staff, currentStops);
                      _mapController.move(pos, 13.5);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 175,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE0EDFF))
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF1A73E8).withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: teamColor.withAlpha(40),
                                child: Text(
                                  staff.name.isNotEmpty
                                      ? staff.name.split(' ').map((e) => e[0]).take(2).join()
                                      : 'ST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: teamColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      staff.id,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF1A73E8), size: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: teamColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isDev ? 'DEV TEAM' : 'MKT TEAM',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: teamColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '10 Places',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: staff.isLiveActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  staff.isLiveActive
                                      ? '● Live: Stop #${staff.currentStopIndex + 1}'
                                      : 'Completed Today',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: staff.isLiveActive
                                        ? const Color(0xFF10B981)
                                        : (isDark ? Colors.white38 : Colors.grey),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamFilterChip(String key, String label, IconData icon, bool isDark) {
    final isSelected = _selectedTeamFilter == key;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedTeamFilter = key);
      },
      avatar: Icon(
        icon,
        size: 13,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selectedColor: const Color(0xFF1A73E8),
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  // ── 2. Active Staff Hero Card Banner ──
  Widget _buildActiveStaffBanner(
    bool isDark,
    LiveStaffMember staff,
    List<TimelinePlaceStop> stops,
  ) {
    final isDev = staff.team == 'development';
    final teamColor = isDev ? const Color(0xFF00E5FF) : const Color(0xFFFF9100);
    final activeStop = (staff.currentStopIndex >= 0 && staff.currentStopIndex < stops.length)
        ? stops[staff.currentStopIndex]
        : stops.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A73E8).withAlpha(isDark ? 60 : 30),
            teamColor.withAlpha(isDark ? 35 : 15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E5FF).withAlpha(isDark ? 100 : 60),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1A73E8),
                child: Text(
                  staff.name.isNotEmpty
                      ? staff.name.split(' ').map((e) => e[0]).take(2).join()
                      : 'ST',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            staff.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: teamColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDev ? 'DEVELOPMENT' : 'MARKETING',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: teamColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${staff.role} · ID: ${staff.id}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE TRACKING',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: Color(0xFF00E5FF), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Active Now: Stop #${activeStop.stopNumber} - ${activeStop.clientName}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                '10 Places Today',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Calendar Section Strip ──
  Widget _buildCalendarSection(bool isDark) {
    final days = List.generate(7, (i) {
      return _selectedDate.add(Duration(days: i - 3));
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
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    _selectedStopIndex = -1;
                  });
                },
              ),
              InkWell(
                onTap: _openDatePicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 6),
                      Text(
                        _formatFullDate(_selectedDate),
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
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                    _selectedStopIndex = -1;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isSelected = day.year == _selectedDate.year &&
                  day.month == _selectedDate.month &&
                  day.day == _selectedDate.day;
              final isDayToday = _isToday(day);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(day.year, day.month, day.day);
                        _selectedStopIndex = -1;
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
                                  : const Color(0xFF10B981),
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

  // ── 4. Quick Stop Navigator Chips (Stop 1 to 10) ──
  Widget _buildStopNavigator(bool isDark, List<TimelinePlaceStop> stops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route_rounded, size: 16, color: Color(0xFF00E5FF)),
                const SizedBox(width: 6),
                Text(
                  '10 Places Daily Route Navigator',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              '${_totalRouteDistanceKm(stops).toStringAsFixed(1)} km total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // All 10 Stops button
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  selected: _selectedStopIndex == -1,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedStopIndex = -1);
                      _mapController.move(_officePoint, 12.5);
                    }
                  },
                  avatar: Icon(
                    Icons.map_rounded,
                    size: 14,
                    color: _selectedStopIndex == -1 ? Colors.white : const Color(0xFF00E5FF),
                  ),
                  label: const Text(
                    'Full 10-Stop Route',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  selectedColor: const Color(0xFF1A73E8),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              // Stop 1 to 10 chips
              ...stops.map((stop) {
                final isSelected = _selectedStopIndex == (stop.stopNumber - 1);
                Color badgeColor;
                switch (stop.stopStatus) {
                  case 'completed':
                    badgeColor = const Color(0xFF10B981);
                    break;
                  case 'active':
                    badgeColor = const Color(0xFF00E5FF);
                    break;
                  case 'travelling':
                    badgeColor = const Color(0xFFF59E0B);
                    break;
                  default:
                    badgeColor = const Color(0xFF64748B);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedStopIndex = stop.stopNumber - 1);
                        _mapController.move(stop.location, 15.0);
                      }
                    },
                    avatar: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${stop.stopNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    label: Text(
                      'Stop ${stop.stopNumber}: ${stop.clientName.split(" ").take(2).join(" ")}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    selectedColor: const Color(0xFF1A73E8),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── 5. Interactive Multi-Stop Map Section ──
  Widget _buildMultiStopMapSection(
    bool isDark,
    LiveStaffMember staff,
    List<TimelinePlaceStop> stops,
  ) {
    final routePoints = _buildFullRoutePolyline(stops);
    final staffLivePos = _calculateStaffLivePosition(staff, stops);

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00E5FF).withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedStopIndex >= 0 && _selectedStopIndex < stops.length
                  ? stops[_selectedStopIndex].location
                  : _officePoint,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hrms_mobileapp_bitbyte',
                maxNativeZoom: 19,
              ),
              // Polyline connecting HQ -> Stop 1 -> ... -> Stop 10 -> HQ
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4.5,
                    color: const Color(0xFF1A73E8),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Office Start Marker (BitByte HQ Salem)
                  Marker(
                    point: _officePoint,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  // All 10 Numbered Stop Markers [1] to [10]
                  ...stops.map((stop) {
                    final isStopFocused = _selectedStopIndex == (stop.stopNumber - 1);
                    Color pinColor;
                    switch (stop.stopStatus) {
                      case 'completed':
                        pinColor = const Color(0xFF10B981);
                        break;
                      case 'active':
                        pinColor = const Color(0xFF00E5FF);
                        break;
                      case 'travelling':
                        pinColor = const Color(0xFFF59E0B);
                        break;
                      default:
                        pinColor = const Color(0xFF64748B);
                    }

                    return Marker(
                      point: stop.location,
                      width: isStopFocused ? 44 : 36,
                      height: isStopFocused ? 44 : 36,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedStopIndex = stop.stopNumber - 1);
                          _mapController.move(stop.location, 15.0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: pinColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isStopFocused ? Colors.white : Colors.white70,
                              width: isStopFocused ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: pinColor.withAlpha(isStopFocused ? 140 : 80),
                                blurRadius: isStopFocused ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${stop.stopNumber}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isStopFocused ? 14 : 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Live Staff Position Beacon (Pulsing radar ring)
                  if (_isToday(_selectedDate))
                    Marker(
                      point: staffLivePos,
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E5FF).withAlpha(50),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A73E8),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_bike_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Info Pill
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alt_route_rounded, color: Color(0xFF00E5FF), size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${stops.length} STOPS ROUTE · ${_totalRouteDistanceKm(stops).toStringAsFixed(1)} KM',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Controls: Zoom in/out, fit full route
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                _buildMapControlBtn(Icons.add_rounded, () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom + 1);
                }),
                const SizedBox(height: 6),
                _buildMapControlBtn(Icons.remove_rounded, () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom - 1);
                }),
                const SizedBox(height: 6),
                _buildMapControlBtn(Icons.fit_screen_rounded, () {
                  setState(() => _selectedStopIndex = -1);
                  _mapController.move(_officePoint, 12.5);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  // ── 6. Dynamic 10-Stops Google Maps Timeline Feed ──
  Widget _buildTenStopsTimelineFeed(
    bool isDark,
    LiveStaffMember staff,
    List<TimelinePlaceStop> stops,
  ) {
    final completedCount = stops.where((s) => s.stopStatus == 'completed').length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF00E5FF), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Dynamic Google Timeline (10 Places)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                ),
                child: Text(
                  '$completedCount / 10 Completed',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Office Departure (Salem BitByte HQ)
          _buildTimelineNode(
            isDark: isDark,
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFF10B981),
            nodeNumberText: 'HQ',
            title: 'Office Morning Departure',
            location: 'BitByte Technologies HQ, Salem',
            time: '09:15 AM',
            details: 'Trip started for ${staff.name} (${staff.role}) · 10 Places Scheduled',
            isFirst: true,
          ),

          // 2. Chronological Stops 1 to 10
          ...stops.map((stop) {

            Color statusColor;
            String statusBadgeText;
            switch (stop.stopStatus) {
              case 'completed':
                statusColor = const Color(0xFF10B981);
                statusBadgeText = 'COMPLETED';
                break;
              case 'active':
                statusColor = const Color(0xFF00E5FF);
                statusBadgeText = '● LIVE AT LOCATION';
                break;
              case 'travelling':
                statusColor = const Color(0xFFF59E0B);
                statusBadgeText = '● LIVE EN ROUTE';
                break;
              default:
                statusColor = const Color(0xFF64748B);
                statusBadgeText = 'UPCOMING';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In-Transit Segment between previous stop and this stop
                Padding(
                  padding: const EdgeInsets.only(left: 38, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_bike_rounded, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          stop.transitFromPrev,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stop Timeline Card
                _buildTimelineNode(
                  isDark: isDark,
                  icon: Icons.storefront_rounded,
                  iconColor: statusColor,
                  nodeNumberText: '${stop.stopNumber}',
                  title: 'Stop ${stop.stopNumber}: ${stop.clientName}',
                  location: stop.address,
                  time: '${stop.arrivalTimeStr} - ${stop.departureTimeStr}',
                  details: 'Service: ${stop.serviceName}',
                  badgeText: statusBadgeText,
                  badgeColor: statusColor,
                  requirementStatus: stop.requirementStatus,
                  contactPerson: stop.contactPerson,
                  contactPhone: stop.contactPhone,
                  onNavigate: () => _openGoogleMapsNavigation(stop),
                ),
              ],
            );
          }),

          // 3. Evening Return Conclusion to HQ
          _buildTimelineNode(
            isDark: isDark,
            icon: Icons.task_alt_rounded,
            iconColor: const Color(0xFF00E5FF),
            nodeNumberText: 'END',
            title: '10 Places Daily Route Concluded',
            location: 'Returned to BitByte Salem HQ',
            time: '08:15 PM',
            details: 'All 10 customer visits completed · Full timeline & mandatory requirement statuses submitted to MD, ED, CEO, TL',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String nodeNumberText,
    required String title,
    required String location,
    required String time,
    required String details,
    String? badgeText,
    Color? badgeColor,
    String? requirementStatus,
    String? contactPerson,
    String? contactPhone,
    VoidCallback? onNavigate,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Numbered / Icon Node Line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 8, color: iconColor.withAlpha(80)),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(35),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    nodeNumberText,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: iconColor.withAlpha(80)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right Content Details Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF17223B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Title, Status badge, Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? iconColor).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (badgeColor ?? iconColor).withAlpha(90),
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: badgeColor ?? iconColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: iconColor),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFEA4335)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Service Details
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black87,
                      ),
                    ),

                    // Prominent MANDATORY Requirement Status Badge
                    if (requirementStatus != null && requirementStatus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00E5FF).withAlpha(100)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 5),
                            Text(
                              'CUSTOMER REQUIREMENT: $requirementStatus',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00E5FF),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Contact info & Open in Google Maps button
                    if (contactPerson != null && contactPerson.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Contact: $contactPerson ${contactPhone != null ? "($contactPhone)" : ""}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                          if (onNavigate != null)
                            InkWell(
                              onTap: onNavigate,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8).withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF1A73E8).withAlpha(80)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.directions_rounded, size: 12, color: Color(0xFF1A73E8)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Maps',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A73E8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
