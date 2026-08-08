import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import '../Employee/employee_shared.dart';
import 'client_visit_models.dart';
import 'client_visit_service.dart';
import 'client_visit_theme.dart';

class ClientVisitManagerApprovalScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitManagerApprovalScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 3,
    userId: userId,
    visitId: visitId,
    service: service,
    reviewerMode: true,
  );
}

class ClientVisitApprovedScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitApprovedScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 4,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitOfficeCheckoutScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitOfficeCheckoutScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 5,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitTravelProgressScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitTravelProgressScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 6,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitCheckInScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitCheckInScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 7,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitActiveScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitActiveScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 8,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitWorkUpdateScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitWorkUpdateScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 9,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitExpenseScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitExpenseScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 10,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitReturnCheckoutScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  const ClientVisitReturnCheckoutScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 11,
    userId: userId,
    visitId: visitId,
    service: service,
  );
}

class ClientVisitSummaryScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final ClientVisitService service;
  final bool reviewerMode;
  const ClientVisitSummaryScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.service,
    this.reviewerMode = false,
  });
  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: 12,
    userId: userId,
    visitId: visitId,
    service: service,
    reviewerMode: reviewerMode,
  );
}

/// Displays the visit at its current workflow stage without exposing employee
/// journey actions or approval controls.
class ClientVisitReadOnlyFlowScreen extends StatelessWidget {
  final String userId;
  final int visitId;
  final int step;
  final ClientVisitService service;

  const ClientVisitReadOnlyFlowScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.step,
    required this.service,
  });

  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: step,
    userId: userId,
    visitId: visitId,
    service: service,
    readOnlyMode: true,
  );
}

class _VisitFlowPage extends StatefulWidget {
  final int step;
  final String userId;
  final int visitId;
  final ClientVisitService service;
  final bool reviewerMode;
  final bool readOnlyMode;
  const _VisitFlowPage({
    required this.step,
    required this.userId,
    required this.visitId,
    required this.service,
    this.reviewerMode = false,
    this.readOnlyMode = false,
  });
  @override
  State<_VisitFlowPage> createState() => _VisitFlowPageState();
}

class _VisitFlowPageState extends State<_VisitFlowPage> {
  static const _filesChannel = MethodChannel('hrms/files');
  ClientVisit? _visit;
  String? _error;
  bool _working = false;
  final _notes = TextEditingController();
  final _attendee = TextEditingController();
  final _amount = TextEditingController();
  final _expenseNote = TextEditingController();
  final _outcome = TextEditingController();
  final _followUp = TextEditingController();
  final _signature = TextEditingController();
  final _odometer = TextEditingController();
  String _expenseCategory = 'travel';
  String _returnMode = 'return_office';
  String? _selfiePath;
  Map<String, double>? _capturedPosition;
  bool _capturingSelfie = false;
  bool _capturingPosition = false;
  StreamSubscription<Position>? _travelSubscription;
  Position? _lastTrackedPosition;
  final List<LatLng> _liveRoutePoints = [];
  final MapController _mapController = MapController();
  LatLng? _destinationLatLng;
  bool _geocodingDone = false;
  String? _trackingError;
  bool _sendingLocation = false;
  Timer? _trackingRetryTimer;
  String _etaText = '';
  String _distanceText = '';
  List<_RouteOption> _routeOptions = [];
  int _selectedRouteIndex = 0;
  bool _navMode = false;
  List<String> _attendees = [];
  List<Map<String, dynamic>> _checklist = [];
  // Local proof images staged for upload (Step 9)
  final List<String> _stagedProofPaths = [];
  // Outcome and follow-up for step 9
  String _outcome9 = '';
  String _followUp9 = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _notes,
      _attendee,
      _amount,
      _expenseNote,
      _outcome,
      _followUp,
      _signature,
      _odometer,
    ]) {
      controller.dispose();
    }
    _travelSubscription?.cancel();
    _trackingRetryTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final visit = await widget.service.fetchVisit(
        widget.userId,
        widget.visitId,
      );
      if (!mounted) return;
      setState(() {
        _visit = visit;
        _error = null;
        _notes.text = visit.notes;
        _attendees = visit.attendees.map((item) => '$item').toList();
        _checklist = visit.checklist.isEmpty
            ? _defaultChecklist()
            : visit.checklist
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
      });
      if (widget.step == 6 && visit.status == 'travelling') {
        unawaited(_startTravelTracking());
        // Set destination — try stored coords first, then geocode.
        final lat = visit.clientLatitude;
        final lng = visit.clientLongitude;
        final hasValidCoords = lat != null && lng != null &&
            lat != 0.0 && lng != 0.0 &&
            lat.abs() <= 90 && lng.abs() <= 180;
        if (hasValidCoords) {
          setState(() => _destinationLatLng = LatLng(lat, lng));
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _fitMapBounds();
          });
        } else {
          // Always retry geocoding if destination still not set
          _geocodingDone = false;
          unawaited(_geocodeDestination(visit.address, visit.clientName));
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    }
  }

  List<Map<String, dynamic>> _defaultChecklist() => [
    {'label': 'Discuss visit purpose', 'done': false},
    {'label': 'Capture client requirements', 'done': false},
    {'label': 'Confirm next action', 'done': false},
    {'label': 'Upload visit proof', 'done': false},
  ];

  /// Geocodes the client address string to a LatLng for the destination pin.
  /// Uses OpenStreetMap Nominatim — no API key required.
  Future<void> _geocodeDestination(String address, [String clientName = '']) async {
    if (_geocodingDone || address.trim().isEmpty) return;
    // Don't set _geocodingDone=true upfront — allow retry if this call fails
    try {
      LatLng? dest;

      // Try 1: client name + address (most specific)
      final combined = clientName.isNotEmpty
          ? '$clientName, $address'
          : address;
      final query1 = Uri.encodeComponent(
        combined.contains('India') ? combined : '$combined, India',
      );
      final response1 = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search'
            '?q=$query1&format=json&limit=1&countrycodes=in'),
        headers: {'User-Agent': 'HRMS-Bitbyte/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response1.statusCode == 200) {
        final results = jsonDecode(response1.body) as List;
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final lat = double.tryParse('${first['lat']}');
          final lon = double.tryParse('${first['lon']}');
          if (lat != null && lon != null) dest = LatLng(lat, lon);
        }
      }

      // Try 2: address only (fallback)
      if (dest == null && clientName.isNotEmpty) {
        final query2 = Uri.encodeComponent(
          address.contains('India') ? address : '$address, India',
        );
        final response2 = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/search'
              '?q=$query2&format=json&limit=1&countrycodes=in'),
          headers: {'User-Agent': 'HRMS-Bitbyte/1.0'},
        ).timeout(const Duration(seconds: 10));
        if (response2.statusCode == 200) {
          final results = jsonDecode(response2.body) as List;
          if (results.isNotEmpty) {
            final first = results.first as Map<String, dynamic>;
            final lat = double.tryParse('${first['lat']}');
            final lon = double.tryParse('${first['lon']}');
            if (lat != null && lon != null) dest = LatLng(lat, lon);
          }
        }
      }

      if (dest != null && mounted) {
        _geocodingDone = true; // mark success only
        setState(() => _destinationLatLng = dest);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _fitMapBounds();
        });
      }
    } catch (_) {
      // Geocoding failed silently — will retry on next _load()
    }
  }

  /// Adjusts the map camera to fit origin, current position and destination.
  void _fitMapBounds() {
    final points = <LatLng>[];

    // Current GPS position
    if (_lastTrackedPosition != null) {
      points.add(LatLng(
        _lastTrackedPosition!.latitude,
        _lastTrackedPosition!.longitude,
      ));
    }

    // Office checkout position (valid only)
    final ocLat = _visit?.officeCheckOutLatitude;
    final ocLng = _visit?.officeCheckOutLongitude;
    if (ocLat != null && ocLng != null &&
        !(ocLat == 0.0 && ocLng == 0.0)) {
      points.add(LatLng(ocLat, ocLng));
    }

    // Destination (valid only)
    final dst = _destinationLatLng;
    if (dst != null && !(dst.latitude == 0.0 && dst.longitude == 0.0)) {
      points.add(dst);
    }

    if (points.length < 2) {
      // At least move to the single known point
      if (points.length == 1) {
        try { _mapController.move(points.first, 15); } catch (_) {}
      }
      return;
    }
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 320),
        ),
      );
    } catch (_) {}
  }

  Future<Map<String, double>> _position() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final opened = await Geolocator.openLocationSettings();
      throw Exception(
        opened
            ? 'Turn on GPS, then tap GPS Location again.'
            : 'GPS is turned off. Enable Location in device settings.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception(
        'Location permission is permanently denied. Allow it in App settings, then retry.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is required to continue.');
    }
    final value = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return {
      'latitude': value.latitude,
      'longitude': value.longitude,
      'accuracy': value.accuracy,
      'speed': value.speed,
    };
  }

  Future<String?> _captureSelfie() async {
    if (_capturingSelfie) return _selfiePath;
    setState(() => _capturingSelfie = true);
    try {
      final selfie = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 82,
      );
      if (selfie == null) {
        _message('Selfie capture was cancelled.');
        return null;
      }
      if (mounted) setState(() => _selfiePath = selfie.path);
      return selfie.path;
    } on PlatformException catch (error) {
      if (error.code.contains('denied') || error.code.contains('permission')) {
        await Geolocator.openAppSettings();
        throw Exception(
          'Camera permission is disabled. Allow Camera in App settings, then retry.',
        );
      }
      throw Exception(error.message ?? 'Unable to open the camera.');
    } finally {
      if (mounted) setState(() => _capturingSelfie = false);
    }
  }

  Future<Map<String, double>?> _capturePosition() async {
    if (_capturingPosition) return _capturedPosition;
    setState(() => _capturingPosition = true);
    try {
      final position = await _position();
      if (mounted) setState(() => _capturedPosition = position);
      return position;
    } finally {
      if (mounted) setState(() => _capturingPosition = false);
    }
  }

  Future<void> _startTravelTracking() async {
    if (_travelSubscription != null) return;
    // Pre-seed the polyline with any waypoints already stored on the backend.
    if (_visit != null && _visit!.travelRoute.isNotEmpty) {
      final seeded = _visit!.travelRoute.map((p) {
        final lat = double.tryParse('${p['latitude'] ?? p['lat'] ?? ''}');
        final lng = double.tryParse('${p['longitude'] ?? p['lng'] ?? ''}');
        if (lat != null && lng != null) return LatLng(lat, lng);
        return null;
      }).whereType<LatLng>().toList();
      if (seeded.isNotEmpty && mounted) {
        setState(() => _liveRoutePoints.addAll(seeded));
      }
    }
    try {
      await _position();
      if (!mounted || _travelSubscription != null) return;
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      _travelSubscription =
          Geolocator.getPositionStream(locationSettings: settings).listen(
            (position) {
              if (!mounted) return;
              final point = LatLng(position.latitude, position.longitude);
              setState(() {
                _lastTrackedPosition = position;
                _trackingError = null;
                _liveRoutePoints.add(point);
              });
              // On first GPS fix, fit map to show both current + destination
              if (_liveRoutePoints.length == 1 && _destinationLatLng != null) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _fitMapBounds();
                });
              }
              // Pan map to follow current position.
              try {
                if (_navMode) {
                  // Navigation mode: always follow at zoom 17
                  _mapController.move(point, 17);
                } else {
                  _mapController.move(point, _mapController.camera.zoom < 14
                      ? 15
                      : _mapController.camera.zoom);
                }
              } catch (_) {}
              unawaited(_sendTravelPosition(position));
            },
            onError: (Object error) {
              if (!mounted) return;
              setState(() => _trackingError = '$error');
              // Auto-retry after 10 seconds if the stream dies.
              _travelSubscription?.cancel();
              _travelSubscription = null;
              _trackingRetryTimer?.cancel();
              _trackingRetryTimer = Timer(const Duration(seconds: 10), () {
                if (mounted) unawaited(_startTravelTracking());
              });
            },
          );
    } catch (error) {
      if (mounted) setState(() => _trackingError = '$error');
    }
  }

  Future<void> _sendTravelPosition(Position position) async {
    if (_sendingLocation) return;
    _sendingLocation = true;
    try {
      await widget.service.trackLocation(
        widget.userId,
        widget.visitId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
      );
    } catch (error) {
      if (mounted) setState(() => _trackingError = '$error');
    } finally {
      _sendingLocation = false;
    }
  }

  Future<void> _captureSelfieFromTile() async {
    try {
      await _captureSelfie();
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _capturePositionFromTile() async {
    try {
      await _capturePosition();
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _working = true);
    try {
      await task();
      await _load();
    } catch (error) {
      if (mounted) _message('$error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(value.replaceFirst('Exception: ', ''))),
  );
  void _replace(Widget screen) => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => screen));

  Future<void> _review(String action) async {
    final comment = TextEditingController();
    final title = switch (action) {
      'approve' => 'Approve visit',
      'reject' => 'Reject visit',
      _ => 'Request changes',
    };
    final confirmLabel = switch (action) {
      'approve' => 'Approve',
      'reject' => 'Reject',
      _ => 'Send changes',
    };
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: comment,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Comment (required)',
            hintText: action == 'approve'
                ? 'e.g. Approved — proceed with visit'
                : action == 'reject'
                ? 'e.g. Visit purpose not clear'
                : 'e.g. Please update the client address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (comment.text.trim().isEmpty) return; // enforce non-empty
              Navigator.pop(context, true);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    if (comment.text.trim().isEmpty) {
      _message('A comment is required to ${action == 'approve' ? 'approve' : action} this visit.');
      return;
    }
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'approval', {
        'action': action,
        'comment': comment.text.trim(),
      });
    });
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _officeCheckout() async {
    // Step 5 validation: both selfie AND GPS location required.
    if (_selfiePath == null) {
      _message('Please capture your selfie before checking out.');
      return;
    }
    if (_capturedPosition == null) {
      _message('Please capture your GPS location before checking out.');
      return;
    }
    await _run(() async {
      final selfiePath = _selfiePath!;
      final position = _capturedPosition!;
      await widget.service.uploadFiles(
        widget.userId,
        widget.visitId,
        'office_checkout',
        [selfiePath],
        fallbackCategory: 'check_in',
      );
      await widget.service
          .action(widget.userId, widget.visitId, 'start-travel', {
            ...position,
            if (_odometer.text.trim().isNotEmpty)
              'odometer': _odometer.text.trim(),
          });
      if (mounted) {
        _replace(
          ClientVisitTravelProgressScreen(
            userId: widget.userId,
            visitId: widget.visitId,
            service: widget.service,
          ),
        );
      }
    });
  }

  Future<void> _reached() async {
    // Step 6 validation: confirm the employee has physically reached.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reached client?'),
        content: const Text(
          'Confirm you have arrived at the client location. '
          'Your current GPS will be recorded as arrival point.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, arrived')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await _travelSubscription?.cancel();
      _travelSubscription = null;
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'reached-client',
        await _position(),
      );
    });
    if (mounted) {
      _replace(
        ClientVisitCheckInScreen(
          userId: widget.userId,
          visitId: widget.visitId,
          service: widget.service,
        ),
      );
    }
  }

  Future<void> _clientCheckIn() async {
    // Step 7 validation: both selfie AND GPS required for client check-in.
    if (_selfiePath == null) {
      _message('Please capture your selfie at the client location.');
      return;
    }
    if (_capturedPosition == null) {
      _message('Please capture your GPS location at the client site.');
      return;
    }
    await _run(() async {
      final selfiePath = _selfiePath!;
      final position = _capturedPosition!;
      await widget.service.uploadFiles(
        widget.userId,
        widget.visitId,
        'client_check_in',
        [selfiePath],
        fallbackCategory: 'check_in',
      );
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'check-in',
        position,
      );
      if (mounted) {
        _replace(
          ClientVisitActiveScreen(
            userId: widget.userId,
            visitId: widget.visitId,
            service: widget.service,
          ),
        );
      }
    });
  }

  Future<void> _saveWorkUpdate() async {
    if (_notes.text.trim().isEmpty) {
      _message('Please add notes about the work done during this visit.');
      return;
    }
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'progress', {
        'notes': _notes.text.trim(),
        'attendees': _attendees,
        'checklist': _checklist,
        if (_outcome9.isNotEmpty) 'outcome': _outcome9,
        if (_followUp9.isNotEmpty) 'follow_up': _followUp9,
        if (_signature.text.trim().isNotEmpty) 'client_signature_name': _signature.text.trim(),
      });
      if (_stagedProofPaths.isNotEmpty) {
        await widget.service.uploadFiles(
          widget.userId, widget.visitId, 'proof', _stagedProofPaths);
        if (mounted) setState(() => _stagedProofPaths.clear());
      }
    });
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addExpense() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _message('Enter a valid expense amount.');
      return;
    }
    await _run(() async {
      await widget.service.addExpense(
        widget.userId,
        widget.visitId,
        _expenseCategory,
        amount,
        _expenseNote.text.trim(),
      );
      final receipt = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (receipt != null) {
        await widget.service.uploadFiles(
          widget.userId,
          widget.visitId,
          'expense',
          [receipt.path],
        );
      }
      _amount.clear();
      _expenseNote.clear();
    });
  }

  Future<void> _complete() async {
    // Step 11 validation: outcome required, selfie + GPS required.
    if (_outcome.text.trim().isEmpty) {
      _message('Visit outcome is required to complete duty.');
      return;
    }
    if (_outcome.text.trim().length < 10) {
      _message('Outcome must be at least 10 characters. Please describe the visit result.');
      return;
    }
    if (_selfiePath == null) {
      _message('Please capture your selfie for checkout.');
      return;
    }
    if (_capturedPosition == null) {
      _message('Please capture your GPS location for checkout.');
      return;
    }
    await _run(() async {
      final selfiePath = _selfiePath!;
      final position = _capturedPosition!;
      await widget.service.uploadFiles(
        widget.userId,
        widget.visitId,
        'checkout',
        [selfiePath],
        fallbackCategory: 'proof',
      );
      await widget.service.action(widget.userId, widget.visitId, 'complete', {
        ...position,
        'outcome': _outcome.text.trim(),
        'follow_up': _followUp.text.trim(),
        'client_signature_name': _signature.text.trim(),
        'return_mode': _returnMode,
      });
      if (mounted) {
        _replace(
          ClientVisitSummaryScreen(
            userId: widget.userId,
            visitId: widget.visitId,
            service: widget.service,
          ),
        );
      }
    });
  }

  Future<void> _verify() async {
    await _run(() async {
      await widget.service.action(
        widget.userId,
        widget.visitId,
        'verify',
        const {},
      );
    });
  }

  Future<void> _downloadReport(ClientVisit visit) async {
    await _run(() async {
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Text(
              'HRMS-ERP Client Visit Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const ['Field', 'Details'],
              data: [
                ['Visit ID', visit.visitId],
                ['Employee', visit.employeeName],
                ['Client', visit.clientName],
                ['Contact', visit.contactPerson],
                ['Address', visit.address],
                ['Purpose', visit.purpose],
                ['Status', _label(visit.status)],
                ['Attendees', visit.attendees.join(', ')],
                ['Expenses', 'INR ${visit.expenseTotal.toStringAsFixed(2)}'],
                ['Outcome', visit.outcome],
                ['Follow-up', visit.followUp],
                ['Return mode', _label(visit.returnMode)],
                [
                  'Manager verification',
                  visit.managerVerifiedBy.isEmpty ? 'Pending' : 'Verified',
                ],
              ],
            ),
          ],
        ),
      );
      final bytes = await document.save();
      final location = await _filesChannel
          .invokeMethod<String>('saveToDownloads', {
            'fileName': '${visit.visitId}-client-visit-report.pdf',
            'mimeType': 'application/pdf',
            'bytes': bytes,
          });
      _message('Report downloaded to ${location ?? 'Downloads/HRMS-ERP'}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final visit = _visit;

    // Step 6 (travelling) gets a full-screen Google-Maps-style layout.
    if (widget.step == 6 && visit != null && _error == null) {
      return _buildTravelScreen(visit);
    }

    return ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(title: Text(_title(widget.step))),
        body: _error != null
            ? _stateMessage(Icons.error_outline, _error!, _load)
            : visit == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _stepHeader(visit),
                  const SizedBox(height: 12),
                  ..._content(visit),
                  if (_working)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
      ),
    );
  }

  /// Full-screen Google Maps navigation layout for the travelling step.
  Widget _buildTravelScreen(ClientVisit visit) {
    final ocLat = _visit!.officeCheckOutLatitude;
    final ocLng = _visit!.officeCheckOutLongitude;
    final origin = (ocLat != null && ocLng != null && !(ocLat == 0.0 && ocLng == 0.0))
        ? LatLng(ocLat, ocLng) : null;
    final current = _lastTrackedPosition != null
        ? LatLng(_lastTrackedPosition!.latitude, _lastTrackedPosition!.longitude) : null;
    final safePad = MediaQuery.of(context).padding;

    return ClientVisitTheme(
      child: Scaffold(
        body: Stack(
          children: [
            // ── Full-screen map ──────────────────────────────────────
            Positioned.fill(
              child: _LiveMapView(
                mapController: _mapController,
                routePoints: const [],
                origin: origin,
                current: current,
                destination: _destinationLatLng,
                fullScreen: true,
                selectedRouteIndex: _selectedRouteIndex,
                onEtaUpdate: (eta, dist) {
                  if (mounted) setState(() {
                    _etaText = eta;
                    _distanceText = dist;
                  });
                },
                onRoutesReady: (routes, idx) {
                  if (mounted) setState(() {
                    _routeOptions = routes;
                    _selectedRouteIndex = idx;
                  });
                },
              ),
            ),

            // ── Google Maps style top search bar ─────────────────────
            Positioned(
              top: safePad.top + 8,
              left: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back arrow + Your location row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(children: [
                        // Only the arrow navigates back
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF5F6368)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.circle, size: 11, color: Color(0xFF1A73E8)),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Your location',
                          style: TextStyle(fontSize: 14, color: Color(0xFF1A73E8), fontWeight: FontWeight.w500))),
                        const Icon(Icons.more_vert, size: 18, color: Color(0xFF5F6368)),
                      ]),
                    ),
                    // Dotted separator
                    Padding(
                      padding: const EdgeInsets.only(left: 44),
                      child: Row(children: List.generate(3, (_) =>
                        Container(width: 3, height: 3, margin: const EdgeInsets.only(right: 3),
                          decoration: const BoxDecoration(color: Color(0xFFBDBDBD), shape: BoxShape.circle)))),
                    ),
                    // Destination row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(children: [
                        const SizedBox(width: 32),
                        const Icon(Icons.location_on, size: 18, color: Color(0xFFEA4335)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _destinationLatLng == null
                              ? Row(children: [
                                  const SizedBox(width: 12, height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5F6368))),
                                  const SizedBox(width: 8),
                                  const Text('Finding destination…',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                                ])
                              : Text(visit.clientName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202124)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        // Fit map to show both points
                        GestureDetector(
                          onTap: _fitMapBounds,
                          child: Icon(Icons.swap_vert, size: 20, color: Colors.grey.shade400),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            // ── Map controls (right side) ─────────────────────────
            Positioned(
              right: 10,
              bottom: 220,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _travelMapButton(icon: Icons.add, onTap: () {
                    try { _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1); } catch (_) {}
                  }),
                  const SizedBox(height: 4),
                  _travelMapButton(icon: Icons.remove, onTap: () {
                    try { _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1); } catch (_) {}
                  }),
                  const SizedBox(height: 8),
                  _travelMapButton(icon: Icons.explore_outlined, onTap: _fitMapBounds),
                  const SizedBox(height: 4),
                  _travelMapButton(
                    icon: Icons.my_location,
                    color: const Color(0xFF1A73E8),
                    onTap: () {
                      if (_lastTrackedPosition != null) {
                        try { _mapController.move(LatLng(_lastTrackedPosition!.latitude, _lastTrackedPosition!.longitude), 15); } catch (_) {}
                      }
                    }),
                ],
              ),
            ),

            // ── Bottom panel — Google Maps "Drive" style ──────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -2))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 6),
                      width: 36, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    )),
                    // Route options
                    if (_routeOptions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                        child: Column(
                          children: List.generate(_routeOptions.length, (i) {
                            final r = _routeOptions[i];
                            final isSel = i == _selectedRouteIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedRouteIndex = i);
                                try {
                                  if (r.points.length >= 2) _mapController.fitCamera(CameraFit.bounds(
                                    bounds: LatLngBounds.fromPoints(r.points),
                                    padding: const EdgeInsets.fromLTRB(40, 160, 40, 260)));
                                } catch (_) {}
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF1967D2) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(children: [
                                  Icon(Icons.directions_car_rounded,
                                    color: isSel ? Colors.white : Colors.grey.shade600, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text(r.durationLabel, style: TextStyle(fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: isSel ? Colors.white : const Color(0xFF202124))),
                                        const SizedBox(width: 8),
                                        Text(r.distanceLabel, style: TextStyle(fontSize: 12,
                                          color: isSel ? Colors.white70 : const Color(0xFF5F6368))),
                                        if (i == 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isSel ? Colors.white24 : const Color(0xFF34A853).withAlpha(30),
                                              borderRadius: BorderRadius.circular(4)),
                                            child: Text('Fastest', style: TextStyle(fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isSel ? Colors.white : const Color(0xFF34A853)))),
                                        ],
                                      ]),
                                      if (r.via.isNotEmpty) Text(r.via, style: TextStyle(fontSize: 11,
                                        color: isSel ? Colors.white70 : const Color(0xFF5F6368))),
                                      if (r.hasTolls) Row(children: [
                                        Icon(Icons.toll_rounded, size: 11,
                                          color: isSel ? Colors.orangeAccent : const Color(0xFFF29900)),
                                        const SizedBox(width: 3),
                                        Text('Tolls', style: TextStyle(fontSize: 11,
                                          color: isSel ? Colors.orangeAccent : const Color(0xFFF29900))),
                                      ]),
                                    ],
                                  )),
                                  if (isSel) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                ]),
                              ),
                            );
                          }),
                        ),
                      ),
                    const Divider(height: 1),
                    // Drive label row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Row(children: [
                        const Icon(Icons.directions_car_rounded, size: 18, color: Color(0xFF202124)),
                        const SizedBox(width: 8),
                        const Text('Drive', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF202124))),
                        const Spacer(),
                        if (_etaText.isNotEmpty) Text(_etaText,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                        if (_distanceText.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text('· $_distanceText',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                        ],
                        // Speed indicator
                        if (_lastTrackedPosition != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A73E8).withAlpha(15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(_lastTrackedPosition!.speed * 3.6).toStringAsFixed(0)} km/h',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: Color(0xFF1A73E8))),
                          ),
                        ],
                      ]),
                    ),
                    // Emergency contact row
                    if (visit.contactPerson.isNotEmpty || visit.contactPhone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: Row(children: [
                          const Icon(Icons.emergency_rounded, size: 14, color: Color(0xFFEA4335)),
                          const SizedBox(width: 6),
                          Text('Emergency Contact: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Expanded(child: Text('${visit.contactPerson} (${visit.contactPhone})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (visit.contactPhone.isNotEmpty)
                            GestureDetector(
                              onTap: () => _message('Calling ${visit.contactPhone}'),
                              child: const Icon(Icons.call, size: 16, color: Color(0xFF34A853)),
                            ),
                        ]),
                      ),
                    // Action buttons row
                    Padding(
                      padding: EdgeInsets.fromLTRB(12, 4, 12, safePad.bottom + 12),
                      child: Row(children: [
                        // Start / Stop
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _navMode ? Colors.grey.shade600 : const Color(0xFF34A853),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() => _navMode = !_navMode);
                              if (_navMode && _lastTrackedPosition != null) {
                                try { _mapController.move(LatLng(_lastTrackedPosition!.latitude, _lastTrackedPosition!.longitude), 17); } catch (_) {}
                              } else if (!_navMode) {
                                _fitMapBounds();
                              }
                            },
                            icon: Icon(_navMode ? Icons.stop_rounded : Icons.navigation_rounded, size: 18),
                            label: Text(_navMode ? 'Stop' : 'Start',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reached client
                        if (!widget.readOnlyMode)
                          Expanded(
                            flex: 3,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1A73E8),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _working ? null : _reached,
                              icon: const Icon(Icons.flag_rounded, size: 18),
                              label: const Text('Reached client',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        if (widget.readOnlyMode) Expanded(flex: 3, child: _monitoringNotice()),
                      ]),
                    ),
                    if (_trackingError != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA4335).withAlpha(15),
                          borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA4335), size: 14),
                          const SizedBox(width: 6),
                          Expanded(child: Text(_trackingError!.replaceFirst('Exception: ', ''),
                            style: const TextStyle(fontSize: 11, color: Color(0xFFEA4335)))),
                          TextButton(onPressed: _startTravelTracking,
                            style: TextButton.styleFrom(minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: const Text('Retry', style: TextStyle(fontSize: 11))),
                        ]),
                      ),
                    if (_working) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          ], // Stack children
        ), // Stack
      ), // Scaffold
    ); // ClientVisitTheme
  } // _buildTravelScreen
  /// Google Maps style circular map control button (used in travel screen).
  Widget _travelMapButton({required IconData icon, required VoidCallback onTap, Color? color}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 40, height: 40,
          child: Icon(icon, size: 20, color: color ?? const Color(0xFF5F6368)),
        ),
      ),
    );
  }

  /// Google Maps style circular map control button.

  List<Widget> _content(ClientVisit visit) => switch (widget.step) {
    3 => [
      _visitInfo(visit),
      const SizedBox(height: 12),
      if (widget.readOnlyMode)
        _monitoringNotice()
      else
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ClientVisitColors.green,
                ),
                onPressed: _working ? null : () => _review('approve'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Approve'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ClientVisitColors.red,
                ),
                onPressed: _working ? null : () => _review('reject'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Reject'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ClientVisitColors.orange,
                ),
                onPressed: _working ? null : () => _review('changes'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Request changes'),
              ),
            ),
          ],
        ),
    ],
    4 => [
      if (visit.status == 'approved') ...[
        _stageBadge(
          _approvalBadgeLabel(visit.approvedByRole),
          ClientVisitColors.green,
        ),
        const SizedBox(height: 12),
      ],
      _visitInfo(visit),
      if (visit.status == 'approved') ...[
        const SizedBox(height: 12),
        _approvalInfo(visit),
      ],
      const SizedBox(height: 12),
      if (widget.readOnlyMode)
        _monitoringNotice()
      else if (visit.status == 'approved')
        FilledButton.icon(
          onPressed: () => _replace(
            ClientVisitOfficeCheckoutScreen(
              userId: widget.userId,
              visitId: widget.visitId,
              service: widget.service,
            ),
          ),
          icon: const Icon(Icons.directions_car),
          label: const Text('Start from office'),
        )
      else
        _statusNotice(visit),
    ],
    5 => [
      _visitInfo(visit),
      const SizedBox(height: 12),
      EmployeeCard(
        child: Column(
          children: [
            _captureTiles(),
            const SizedBox(height: 10),
            const Text('A selfie and current GPS location are required.'),
            TextField(
              controller: _odometer,
              readOnly: widget.readOnlyMode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Odometer (optional)',
                suffixText: 'km',
              ),
            ),
            const SizedBox(height: 12),
            if (widget.readOnlyMode)
              _monitoringNotice()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _working ? null : _officeCheckout,
                  child: const Text('Confirm office check-out'),
                ),
              ),
          ],
        ),
      ),
    ],
    6 => [
      EmployeeCard(
        child: Column(
          children: [
            _LiveMapView(
              mapController: _mapController,
              routePoints: _liveRoutePoints,
              origin: _visit != null &&
                      _visit!.officeCheckOutLatitude != null &&
                      _visit!.officeCheckOutLongitude != null
                  ? LatLng(
                      _visit!.officeCheckOutLatitude!,
                      _visit!.officeCheckOutLongitude!,
                    )
                  : null,
              current: _lastTrackedPosition != null
                  ? LatLng(
                      _lastTrackedPosition!.latitude,
                      _lastTrackedPosition!.longitude,
                    )
                  : null,
              destination: _destinationLatLng,
            ),
            const SizedBox(height: 8),
            Text(visit.address, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Live GPS journey in progress'),
            const SizedBox(height: 6),
            if (_lastTrackedPosition != null)
              Text(
                '${_lastTrackedPosition!.latitude.toStringAsFixed(6)}, '
                '${_lastTrackedPosition!.longitude.toStringAsFixed(6)} '
                '(±${_lastTrackedPosition!.accuracy.toStringAsFixed(0)} m)',
                textAlign: TextAlign.center,
              )
            else
              const Text('Waiting for the first GPS route point...'),
            if (_trackingError != null) ...[
              const SizedBox(height: 6),
              Text(
                _trackingError!.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: ClientVisitColors.red),
              ),
              TextButton.icon(
                onPressed: _startTravelTracking,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry GPS tracking'),
              ),
            ],
            if (widget.readOnlyMode) ...[
              const SizedBox(height: 14),
              _monitoringNotice(),
            ] else ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _reached,
                  icon: const Icon(Icons.flag),
                  label: const Text('Reached client'),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
    7 => [
      // Within Client Location badge
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: ClientVisitColors.green.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ClientVisitColors.green.withAlpha(80)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: ClientVisitColors.green, size: 18),
            SizedBox(width: 6),
            Text('Within Client Location',
              style: TextStyle(color: ClientVisitColors.green,
                fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _visitInfo(visit),
      // Client Contact with call button
      if (visit.contactPhone.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: EmployeeCard(
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visit.contactPerson,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(visit.contactPhone,
                      style: const TextStyle(fontSize: 12)),
                  ],
                )),
                IconButton(
                  icon: const Icon(Icons.call, color: ClientVisitColors.green),
                  onPressed: () => _message('Calling ${visit.contactPhone}'),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 12),
      EmployeeCard(
        child: Column(
          children: [
            _captureTiles(),
            const SizedBox(height: 10),
            const Text('Capture arrival selfie and GPS to begin the visit.'),
            const SizedBox(height: 14),
            if (widget.readOnlyMode)
              _monitoringNotice()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _working ? null : _clientCheckIn,
                  child: const Text('Client check-in'),
                ),
              ),
          ],
        ),
      ),
    ],
    8 => [
      if (visit.checkInAt != null) _FlowTimer(startedAt: visit.checkInAt!),
      const SizedBox(height: 12),
      EmployeeCard(
        child: Column(
          children: [
            // Attendees
            Row(children: [
              const Icon(Icons.people_outline, size: 16),
              const SizedBox(width: 6),
              Text('Attendees (${_attendees.length})',
                style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (!widget.readOnlyMode)
                TextButton.icon(
                  onPressed: () async {
                    final ctrl = TextEditingController();
                    final name = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Add Attendee'),
                        content: TextField(controller: ctrl,
                          autofocus: true,
                          decoration: const InputDecoration(labelText: 'Name')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Add')),
                        ],
                      ),
                    );
                    if (name != null && name.isNotEmpty) setState(() => _attendees.add(name));
                  },
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('+ Add', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                ),
            ]),
            if (_attendees.isNotEmpty)
              Wrap(spacing: 6, runSpacing: 4,
                children: _attendees.map((name) => Chip(
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  onDeleted: widget.readOnlyMode ? null
                    : () => setState(() => _attendees.remove(name)),
                )).toList(),
              ),
            const Divider(height: 20),
            // Checklist with progress bar
            Row(children: [
              const Icon(Icons.checklist_rounded, size: 16),
              const SizedBox(width: 6),
              Text('Checklist', style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${_checklist.where((i) => i['done'] == true).length}/${_checklist.length} Completed',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _checklist.isEmpty ? 0
                  : _checklist.where((i) => i['done'] == true).length / _checklist.length,
                backgroundColor: Colors.grey.shade200,
                color: ClientVisitColors.green,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            ..._checklist.asMap().entries.map((entry) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: entry.value['done'] == true,
              title: Text('${entry.value['label']}', style: const TextStyle(fontSize: 13)),
              onChanged: widget.readOnlyMode ? null
                : (value) => setState(() => _checklist[entry.key]['done'] = value == true),
            )),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (!widget.readOnlyMode) ...[
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _push(ClientVisitWorkUpdateScreen(
              userId: widget.userId, visitId: widget.visitId, service: widget.service)),
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Add Update'),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: () async {
              final images = await ImagePicker().pickMultiImage(imageQuality: 82);
              if (images.isNotEmpty && mounted) {
                await _run(() => widget.service.uploadFiles(
                  widget.userId, widget.visitId, 'proof',
                  images.map((i) => i.path).toList()));
                _message('Proof uploaded.');
              }
            },
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload Proof'),
          )),
        ]),
        const SizedBox(height: 8),
        _flowButton(Icons.receipt_long, 'Expense claim', () => _push(
          ClientVisitExpenseScreen(userId: widget.userId, visitId: widget.visitId, service: widget.service))),
        _flowButton(Icons.logout, 'Return / direct checkout', () => _push(
          ClientVisitReturnCheckoutScreen(userId: widget.userId, visitId: widget.visitId, service: widget.service))),
      ] else _monitoringNotice(),
    ],
    9 => [
      EmployeeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attendee field
            Row(children: [
              Expanded(child: TextField(
                controller: _attendee,
                readOnly: widget.readOnlyMode,
                decoration: const InputDecoration(labelText: 'Attendee name'),
              )),
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: widget.readOnlyMode ? null : () {
                  if (_attendee.text.trim().isNotEmpty) {
                    setState(() { _attendees.add(_attendee.text.trim()); _attendee.clear(); });
                  }
                },
              ),
            ]),
            if (_attendees.isNotEmpty)
              Wrap(spacing: 6, children: _attendees.map((name) => Chip(
                label: Text(name),
                onDeleted: widget.readOnlyMode ? null
                  : () => setState(() => _attendees.remove(name)),
              )).toList()),
            // Checklist
            ..._checklist.asMap().entries.map((entry) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: entry.value['done'] == true,
              title: Text('${entry.value['label']}'),
              onChanged: widget.readOnlyMode ? null
                : (v) => setState(() => _checklist[entry.key]['done'] = v == true),
            )),
            const SizedBox(height: 8),
            // Notes
            TextField(
              controller: _notes,
              readOnly: widget.readOnlyMode,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes / outcome'),
            ),
            const SizedBox(height: 12),
            // Photos / Documents grid
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Photos / Documents (${_stagedProofPaths.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (!widget.readOnlyMode)
                TextButton.icon(
                  onPressed: () async {
                    final images = await ImagePicker().pickMultiImage(imageQuality: 82);
                    if (images.isNotEmpty) {
                      setState(() => _stagedProofPaths.addAll(images.map((i) => i.path)));
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                  label: const Text('+ Add', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                ),
            ]),
            if (_stagedProofPaths.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stagedProofPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_stagedProofPaths[i]),
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80, height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.insert_drive_file)),
                        ),
                      ),
                      Positioned(top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _stagedProofPaths.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Outcome dropdown
            DropdownButtonFormField<String>(
              value: _outcome9.isEmpty ? null : _outcome9,
              decoration: const InputDecoration(labelText: 'Outcome'),
              items: const ['Positive', 'Negative', 'Neutral', 'Follow-up Required']
                .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: widget.readOnlyMode ? null
                : (v) => setState(() => _outcome9 = v ?? ''),
            ),
            // Follow-up dropdown
            DropdownButtonFormField<String>(
              value: _followUp9.isEmpty ? null : _followUp9,
              decoration: const InputDecoration(labelText: 'Follow-up'),
              items: const ['None', 'Call tomorrow', 'Send proposal by next week',
                'Schedule demo', 'Awaiting client feedback']
                .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: widget.readOnlyMode ? null
                : (v) => setState(() => _followUp9 = v ?? ''),
            ),
            // Client Signature / OTP
            TextField(
              controller: _signature,
              readOnly: widget.readOnlyMode,
              decoration: const InputDecoration(labelText: 'Client Signature / OTP'),
            ),
            const SizedBox(height: 14),
            if (widget.readOnlyMode)
              _monitoringNotice()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _saveWorkUpdate,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Save & upload proof'),
                ),
              ),
          ],
        ),
      ),
    ],
    10 => [
      EmployeeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category with icons
            DropdownButtonFormField<String>(
              value: _expenseCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                _expenseItem('travel', Icons.directions_car_rounded, 'Travel'),
                _expenseItem('food', Icons.restaurant_rounded, 'Food'),
                _expenseItem('parking', Icons.local_parking_rounded, 'Parking / Toll'),
                _expenseItem('other', Icons.more_horiz_rounded, 'Other'),
              ],
              onChanged: widget.readOnlyMode ? null
                : (v) => setState(() => _expenseCategory = v!),
            ),
            TextField(
              controller: _amount,
              readOnly: widget.readOnlyMode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
            ),
            TextField(
              controller: _expenseNote,
              readOnly: widget.readOnlyMode,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 12),
            if (!widget.readOnlyMode)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _addExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Add expense & receipt'),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // Expense list with icons
      if (visit.expenses.isNotEmpty)
        EmployeeCard(
          child: Column(
            children: [
              ...visit.expenses.map((expense) {
                final cat = '${expense['category']}';
                final icon = switch (cat) {
                  'travel'  => Icons.directions_car_rounded,
                  'food'    => Icons.restaurant_rounded,
                  'parking' => Icons.local_parking_rounded,
                  _         => Icons.more_horiz_rounded,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withAlpha(15),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, size: 16, color: const Color(0xFF1A73E8)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_label(cat),
                      style: const TextStyle(fontWeight: FontWeight.w500))),
                    Text('₹${expense['amount']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                );
              }),
              const Divider(height: 16),
              Row(children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                Text('₹${visit.expenseTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              if (!widget.readOnlyMode)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _working ? null : () => _message('Expenses submitted.'),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Submit Expense'),
                  ),
                ),
            ],
          ),
        ),
    ],
    11 => [
      EmployeeCard(
        child: Column(
          children: [
            // Return mode as radio buttons
            const Align(alignment: Alignment.centerLeft,
              child: Text('Duty completion', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 4),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: 'return_office',
              groupValue: _returnMode,
              title: const Text('Return to Office'),
              subtitle: const Text('End of Office', style: TextStyle(fontSize: 11)),
              onChanged: widget.readOnlyMode ? null
                : (v) => setState(() => _returnMode = v!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: 'end_duty_client',
              groupValue: _returnMode,
              title: const Text('End Duty from Client'),
              subtitle: const Text('No Return', style: TextStyle(fontSize: 11)),
              onChanged: widget.readOnlyMode ? null
                : (v) => setState(() => _returnMode = v!),
            ),
            const Divider(height: 16),
            _captureTiles(),
            const SizedBox(height: 12),
            TextField(
              controller: _outcome,
              readOnly: widget.readOnlyMode,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Outcome *'),
            ),
            TextField(
              controller: _followUp,
              readOnly: widget.readOnlyMode,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Follow-up'),
            ),
            TextField(
              controller: _signature,
              readOnly: widget.readOnlyMode,
              decoration: const InputDecoration(labelText: 'Client Signature / OTP'),
            ),
            const SizedBox(height: 12),
            if (widget.readOnlyMode)
              _monitoringNotice()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _complete,
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Complete Duty'),
                ),
              ),
          ],
        ),
      ),
    ],
    12 => [
      _stageBadge('COMPLETED', ClientVisitColors.green),
      const SizedBox(height: 12),
      _timeline(visit),
      const SizedBox(height: 12),
      _summary(visit),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _working ? null : () => _downloadReport(visit),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Report'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.history_rounded),
            label: const Text('View History'),
          ),
        ),
      ]),
      if (widget.reviewerMode && visit.managerVerifiedBy.isEmpty) ...[
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _working ? null : _verify,
          icon: const Icon(Icons.verified),
          label: const Text('Verify completed visit'),
        ),
      ],
    ],
    _ => [_visitInfo(visit)],
  };

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  Widget _flowButton(IconData icon, String label, VoidCallback onPressed) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      );

  Widget _captureTiles() {
    final isDark = ThemeConfig.isDark(context);
    final border = ThemeConfig.getCardBorder(context);
    final neutralSurface = isDark
        ? const Color(0xFF182238)
        : const Color(0xFFF2F4F7);
    final mapSurface = isDark
        ? const Color(0xFF102743)
        : const Color(0xFFEAF3FC);
    return Row(
      children: [
        Expanded(
          child: _captureTile(
            background: neutralSurface,
            border: border,
            icon: _selfiePath == null
                ? Icons.camera_alt_rounded
                : Icons.check_circle_rounded,
            title: 'Selfie',
            subtitle: _capturingSelfie
                ? 'Opening camera...'
                : _selfiePath == null
                ? 'Tap to capture'
                : 'Captured - tap to retake',
            ready: _selfiePath != null,
            busy: _capturingSelfie,
            onTap: widget.readOnlyMode ? null : _captureSelfieFromTile,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _captureTile(
            background: mapSurface,
            border: border,
            icon: _capturedPosition == null
                ? Icons.location_on_rounded
                : Icons.check_circle_rounded,
            title: 'GPS Location',
            subtitle: _capturingPosition
                ? 'Getting location...'
                : _capturedPosition == null
                ? 'Tap to enable GPS'
                : 'Location captured',
            ready: _capturedPosition != null,
            busy: _capturingPosition,
            onTap: widget.readOnlyMode ? null : _capturePositionFromTile,
          ),
        ),
      ],
    );
  }

  Widget _captureTile({
    required Color background,
    required Color border,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool ready,
    required bool busy,
    required Future<void> Function()? onTap,
  }) => Material(
    color: background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: ready ? ClientVisitColors.green : border,
        width: ready ? 1.5 : 1,
      ),
    ),
    child: InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 132,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox.square(
                dimension: 34,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else if (title == 'Selfie' && _selfiePath != null)
              ClipOval(
                child: Image.file(
                  File(_selfiePath!),
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.check_circle_rounded,
                    color: ClientVisitColors.green,
                    size: 40,
                  ),
                ),
              )
            else
              Icon(
                icon,
                color: ready ? ClientVisitColors.green : ClientVisitColors.blue,
                size: 40,
              ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: ThemeConfig.getTextPrimary(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ready
                      ? ClientVisitColors.green
                      : ThemeConfig.getTextSecondary(context),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _stepHeader(ClientVisit visit) => Row(
    children: [
      CircleAvatar(
        backgroundColor: EmployeeColors.blue,
        child: Text(
          '${widget.step}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visit.clientName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(visit.visitId),
          ],
        ),
      ),
      _statusChip(visit.status),
    ],
  );
  Widget _visitInfo(ClientVisit visit) => EmployeeCard(
    child: Column(
      children: [
        // Employee photo + name header
        if (visit.employeePhotoUrl.isNotEmpty || visit.employeeName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                _employeeAvatar(visit),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(visit.employeeName.isEmpty ? visit.employeeUserId : visit.employeeName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(visit.employeeUserId,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        const SizedBox(height: 6),
        EmployeeInfoRow('Client', visit.clientName),
        EmployeeInfoRow('Contact', visit.contactPerson),
        EmployeeInfoRow('Phone', visit.contactPhone.isEmpty ? '—' : visit.contactPhone),
        EmployeeInfoRow('Address', visit.address),
        EmployeeInfoRow('Date & Time',
          '${_date(visit.scheduledAt)}  ${TimeOfDay.fromDateTime(visit.scheduledAt).format(context)}'),
        EmployeeInfoRow('Duration',
          visit.durationMinutes < 60
            ? '${visit.durationMinutes} minutes'
            : '${visit.durationMinutes ~/ 60} hour${visit.durationMinutes == 60 ? '' : 's'}'),
        EmployeeInfoRow('Purpose', visit.purpose),
        EmployeeInfoRow('Travel mode', _label(visit.travelMode)),
        if (visit.notes.isNotEmpty) EmployeeInfoRow('Notes', visit.notes),
      ],
    ),
  );

  Widget _employeeAvatar(ClientVisit visit) {
    final hasPhoto = visit.employeePhotoUrl.isNotEmpty;
    final name = visit.employeeName;
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A73E8).withAlpha(20),
        border: Border.all(color: const Color(0xFF1A73E8).withAlpha(60), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(visit.employeePhotoUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: Text(initials,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: Color(0xFF1A73E8)))))
          : Center(child: Text(initials,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                color: Color(0xFF1A73E8)))),
    );
  }
  Widget _approvalInfo(ClientVisit visit) => EmployeeCard(
    child: Column(
      children: [
        EmployeeInfoRow(
          'Approved by',
          visit.approvedByName.isNotEmpty
              ? '${_approverRoleLabel(visit.approvedByRole)} - ${visit.approvedByName}'
              : _approverRoleLabel(visit.approvedByRole),
        ),
        if (visit.approvedAt != null)
          EmployeeInfoRow('Approved at', _dateTime(visit.approvedAt!)),
        if (visit.approvalComment.isNotEmpty)
          EmployeeInfoRow('Comment', visit.approvalComment),
      ],
    ),
  );
  Widget _statusNotice(ClientVisit visit) => EmployeeCard(
    child: Column(
      children: [
        Icon(
          visit.status == 'rejected' ? Icons.info_outline : Icons.hourglass_top,
          color: employeeStatusColor(visit.status),
        ),
        const SizedBox(height: 8),
        Text(
          visit.status == 'rejected'
              ? visit.approvalComment
              : 'Waiting for TL approval',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
  Widget _monitoringNotice() => EmployeeCard(
    child: const Row(
      children: [
        Icon(Icons.visibility_rounded, color: EmployeeColors.blue),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Monitoring view. Visit actions are available only to the assigned employee.',
          ),
        ),
      ],
    ),
  );
  Widget _timeline(ClientVisit visit) {
    // Calculate durations
    String travelDuration = '—';
    String visitDuration = '—';
    String totalDuty = '—';
    if (visit.officeCheckOutAt != null && visit.reachedClientAt != null) {
      travelDuration = _duration(
        visit.reachedClientAt!.toLocal().difference(visit.officeCheckOutAt!.toLocal()));
    }
    if (visit.checkInAt != null && visit.checkOutAt != null) {
      visitDuration = _duration(
        visit.checkOutAt!.toLocal().difference(visit.checkInAt!.toLocal()));
    }
    if (visit.officeCheckOutAt != null && visit.checkOutAt != null) {
      totalDuty = _duration(
        visit.checkOutAt!.toLocal().difference(visit.officeCheckOutAt!.toLocal()));
    }
    final proofCount = visit.attachments.where((a) =>
      a['category'] == 'proof' || a['category'] == 'client_check_in').length;

    return EmployeeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Visit timeline', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _timeRow('Office Check-Out', visit.officeCheckOutAt),
          _timeRow('Reached Client', visit.reachedClientAt),
          _timeRow('Visit Start', visit.checkInAt),
          _timeRow('Visit End', visit.checkOutAt),
          _timeRow('Return / Checkout', visit.checkOutAt),
          const Divider(height: 16),
          // Duration metrics row
          Row(children: [
            _durationBox('Travel\nDuration', travelDuration),
            _durationBox('Visit\nDuration', visitDuration),
            _durationBox('Total Duty', totalDuty),
          ]),
          const Divider(height: 16),
          // Expenses + Proof
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text('₹${visit.expenseTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            )),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proof Uploaded', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text('$proofCount file${proofCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            )),
          ]),
          const Divider(height: 16),
          // Manager verification
          Row(children: [
            Icon(
              visit.managerVerifiedBy.isEmpty ? Icons.pending_outlined : Icons.verified_rounded,
              size: 16,
              color: visit.managerVerifiedBy.isEmpty ? Colors.orange : ClientVisitColors.green,
            ),
            const SizedBox(width: 6),
            Text('Manager Verification: ',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              visit.managerVerifiedBy.isEmpty ? 'Pending' : '✓ Verified',
              style: TextStyle(
                fontSize: 12,
                color: visit.managerVerifiedBy.isEmpty ? Colors.orange : ClientVisitColors.green,
                fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }

  Widget _durationBox(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          textAlign: TextAlign.center),
      ],
    ),
  );
  Widget _timeRow(String label, DateTime? time) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      time == null ? Icons.radio_button_unchecked : Icons.check_circle,
      color: time == null ? Colors.grey : EmployeeColors.green,
    ),
    title: Text(label),
    trailing: Text(
      time == null
          ? '—'
          : TimeOfDay.fromDateTime(time.toLocal()).format(context),
    ),
  );
  Widget _summary(ClientVisit visit) => EmployeeCard(
    child: Column(
      children: [
        EmployeeInfoRow('Status', _label(visit.status)),
        EmployeeInfoRow(
          'Duration',
          visit.checkInAt == null
              ? '—'
              : _duration(
                  (visit.checkOutAt ?? DateTime.now()).toLocal().difference(
                    visit.checkInAt!.toLocal(),
                  ),
                ),
        ),
        EmployeeInfoRow('Attendees', '${visit.attendees.length}'),
        EmployeeInfoRow(
          'Expenses',
          '₹${visit.expenseTotal.toStringAsFixed(2)}',
        ),
        EmployeeInfoRow('Return mode', _label(visit.returnMode)),
        EmployeeInfoRow('Outcome', visit.outcome.isEmpty ? '—' : visit.outcome),
        EmployeeInfoRow(
          'Manager verification',
          visit.managerVerifiedBy.isEmpty ? 'Pending' : 'Verified',
        ),
      ],
    ),
  );
  Widget _statusChip(String status) {
    final color = employeeStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
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

  Widget _stageBadge(String label, Color color) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: color.withAlpha(22),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withAlpha(90)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: color, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: .3,
          ),
        ),
      ],
    ),
  );

  Widget _stateMessage(
    IconData icon,
    String text,
    Future<void> Function() retry,
  ) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _FlowTimer extends StatefulWidget {
  final DateTime startedAt;
  const _FlowTimer({required this.startedAt});
  @override
  State<_FlowTimer> createState() => _FlowTimerState();
}

class _FlowTimerState extends State<_FlowTimer> {
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
    final value = DateTime.now().difference(widget.startedAt.toLocal());
    return EmployeeCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: EmployeeColors.blue),
          const SizedBox(width: 8),
          Text(
            _duration(value),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: EmployeeColors.blue),
          ),
        ],
      ),
    );
  }
}

/// Represents one OSRM route option (there can be up to 3 alternatives).
class _RouteOption {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final String via;        // e.g. "NH 44 and AH45"
  final bool hasTolls;

  const _RouteOption({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.via,
    required this.hasTolls,
  });

  String get durationLabel {
    if (durationMinutes < 60) return '$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get distanceLabel {
    return distanceKm < 1
        ? '${(distanceKm * 1000).round()} m'
        : '${distanceKm.toStringAsFixed(0)} km';
  }
}

/// Full Google-Maps-style live tracking map.
/// - Fetches up to 3 alternate road routes from OSRM.
/// - User can tap a route to select it (blue = selected, grey = alternate).
/// - Animated pulsing dot + navigation arrow for current position.
/// - Callback reports ETA/distance to parent for bottom sheet display.
class _LiveMapView extends StatefulWidget {
  final MapController mapController;
  final List<LatLng> routePoints;   // actual GPS breadcrumb trail
  final LatLng? origin;
  final LatLng? current;
  final LatLng? destination;
  final bool fullScreen;
  final void Function(String eta, String distance)? onEtaUpdate;
  final void Function(List<_RouteOption> routes, int selectedIndex)? onRoutesReady;
  final int selectedRouteIndex;

  const _LiveMapView({
    required this.mapController,
    required this.routePoints,
    this.origin,
    this.current,
    this.destination,
    this.fullScreen = false,
    this.onEtaUpdate,
    this.onRoutesReady,
    this.selectedRouteIndex = 0,
  });

  @override
  State<_LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<_LiveMapView>
    with SingleTickerProviderStateMixin {
  // Animated pulse for the current-position dot.
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  // Multiple route alternatives from OSRM.
  List<_RouteOption> _routes = [];
  int _selectedRouteIndex = 0;
  bool _fetchingRoute = false;
  LatLng? _lastRouteFetch;

  _RouteOption? get _selected =>
      _routes.isEmpty ? null : _routes[_selectedRouteIndex];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.current != null && widget.destination != null) {
      _fetchRoute(widget.current!, widget.destination!);
    }
  }

  @override
  void didUpdateWidget(_LiveMapView old) {
    super.didUpdateWidget(old);
    final cur = widget.current;
    final dst = widget.destination;
    // Sync route selection from parent (bottom sheet tap).
    if (widget.selectedRouteIndex != old.selectedRouteIndex &&
        widget.selectedRouteIndex < _routes.length) {
      setState(() => _selectedRouteIndex = widget.selectedRouteIndex);
    }
    if (cur == null || dst == null) return;
    // Skip if destination is invalid (0,0 sentinel)
    if (dst.latitude == 0.0 && dst.longitude == 0.0) return;
    // Re-fetch every ~500 m of movement.
    if (_lastRouteFetch == null ||
        const Distance().as(LengthUnit.Meter, cur, _lastRouteFetch!) > 500) {
      _fetchRoute(cur, dst);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Builds a human-readable "via" label from OSRM leg steps.
  static String _viaLabel(Map<String, dynamic> route) {
    try {
      final legs = route['legs'] as List?;
      if (legs == null || legs.isEmpty) return '';
      final steps = (legs.first as Map)['steps'] as List? ?? [];
      // Collect road names that look like highway refs (NH, AH, SH, etc.)
      final highways = <String>{};
      for (final step in steps) {
        final ref = '${(step as Map)['ref'] ?? ''}'.trim();
        final name = '${step['name'] ?? ''}'.trim();
        for (final token in [...ref.split(';'), ...name.split(' ')]) {
          final t = token.trim();
          if (RegExp(r'^(NH|AH|SH|MDR|ODR)\s*\d+', caseSensitive: false)
              .hasMatch(t)) {
            highways.add(t.replaceAll(RegExp(r'\s+'), ' '));
          }
        }
        if (highways.length >= 3) break;
      }
      if (highways.isNotEmpty) return 'via ${highways.take(2).join(' and ')}';
    } catch (_) {}
    return 'via road';
  }

  /// Fetches up to 3 driving route alternatives from OSRM.
  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    if (_fetchingRoute) return;
    // Never route to invalid coordinates
    if (to.latitude == 0.0 && to.longitude == 0.0) return;
    if (from.latitude == 0.0 && from.longitude == 0.0) return;
    _fetchingRoute = true;
    _lastRouteFetch = from;
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson&alternatives=3&steps=true&annotations=false',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'HRMS-Bitbyte/1.0'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawRoutes = data['routes'] as List? ?? [];
        if (rawRoutes.isEmpty) return;

        final parsed = rawRoutes.take(3).map((r) {
          final route = r as Map<String, dynamic>;
          final distM = (route['distance'] as num).toDouble();
          final durS = (route['duration'] as num).toDouble();
          final coords = (route['geometry']['coordinates'] as List)
              .map((c) =>
                  LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          final via = _viaLabel(route);
          return _RouteOption(
            points: coords,
            distanceKm: distM / 1000,
            durationMinutes: (durS / 60).ceil(),
            via: via,
            hasTolls: via.toLowerCase().contains('nh') ||
                via.toLowerCase().contains('ah'),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _routes = parsed;
            // Keep previous selection if still valid.
            if (_selectedRouteIndex >= parsed.length) _selectedRouteIndex = 0;
          });
          widget.onEtaUpdate?.call(
            _selected?.durationLabel ?? '',
            _selected?.distanceLabel ?? '',
          );
          widget.onRoutesReady?.call(parsed, _selectedRouteIndex);
        }
      }
    } catch (_) {
      // Silently fall back — map still works without road route.
    } finally {
      _fetchingRoute = false;
    }
  }

  void _selectRoute(int index) {
    if (index < 0 || index >= _routes.length) return;
    setState(() => _selectedRouteIndex = index);
    widget.onEtaUpdate?.call(
      _routes[index].durationLabel,
      _routes[index].distanceLabel,
    );
    widget.onRoutesReady?.call(_routes, index);
    // Pan map to fit selected route.
    try {
      if (_routes[index].points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_routes[index].points);
        widget.mapController.fitCamera(
          CameraFit.bounds(
              bounds: bounds, padding: const EdgeInsets.all(60)),
        );
      }
    } catch (_) {}
  }

  /// Bearing from [from] to [to] in degrees (0 = north, 90 = east).
  double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitudeInRad;
    final lat2 = to.latitudeInRad;
    final dLng = to.longitudeInRad - from.longitudeInRad;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  // The selected road route to draw — empty list if no OSRM route yet.
  // Never fall back to raw GPS breadcrumb as route (causes spider-web mess).
  List<LatLng> get _displayRoute =>
      _selected != null && _selected!.points.length >= 2
          ? _selected!.points
          : [];

  LatLng get _center {
    final cur = widget.current;
    final dst = widget.destination;
    // Don't center on invalid 0,0 destination
    final validDst = (dst != null && !(dst.latitude == 0.0 && dst.longitude == 0.0))
        ? dst : null;
    return cur ?? validDst ?? widget.origin ?? const LatLng(20.5937, 78.9629);
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.current;
    final dst = widget.destination;
    final validDst = (dst != null && !(dst.latitude == 0.0 && dst.longitude == 0.0)) ? dst : null;
    final heading = (cur != null && validDst != null) ? _bearing(cur, validDst) : 0.0;

    final mapStack = Stack(
      children: [
        // ── MAP ──────────────────────────────────────────────────────
        Positioned.fill(
          child: FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              // OpenStreetMap tiles.
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bitbyte.hrms',
                maxNativeZoom: 19,
              ),

              // ── All alternate routes drawn on map (Google Maps style) ──
              // Draw unselected routes first (behind), selected last (on top).
              ...List.generate(_routes.length, (i) {
                if (_routes[i].points.length < 2) return const SizedBox.shrink();
                final isSelected = i == _selectedRouteIndex;
                if (isSelected) return const SizedBox.shrink(); // drawn separately below
                final altColor = i == 1
                    ? const Color(0xFF4FC3F7)
                    : Colors.grey.shade400;
                return GestureDetector(
                  onTap: () => _selectRoute(i),
                  child: PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routes[i].points,
                        color: Colors.white,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                      Polyline(
                        points: _routes[i].points,
                        color: altColor.withAlpha(180),
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),
                );
              }),

              // ── Time labels on each route (mid-point bubble) ──
              MarkerLayer(
                markers: List.generate(_routes.length, (i) {
                  if (_routes[i].points.length < 2) {
                    return Marker(
                      point: const LatLng(0, 0),
                      width: 0, height: 0,
                      child: const SizedBox.shrink(),
                    );
                  }
                  final pts = _routes[i].points;
                  final mid = pts[pts.length ~/ 2];
                  final isSelected = i == _selectedRouteIndex;
                  return Marker(
                    point: mid,
                    width: 80,
                    height: 30,
                    child: GestureDetector(
                      onTap: () => _selectRoute(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2)),
                          ],
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _routes[i].durationLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF202124),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // ── Travelled breadcrumb (grey) ──
              if (widget.routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      color: Colors.grey.withAlpha(180),
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),

              // ── Selected road route (Google-Maps style blue, drawn on top) ──
              if (_displayRoute.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _displayRoute,
                      color: Colors.white,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    Polyline(
                      points: _displayRoute,
                      color: const Color(0xFF1A73E8),
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // ── Markers ──────────────────────────────────────────────
              MarkerLayer(
                markers: [
                  // ── Origin — small green dot (office start point) ──
                  if (widget.origin != null)
                    Marker(
                      point: widget.origin!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),

                  // ── Destination — large red Google Maps style teardrop pin ──
                  if (dst != null && !(dst.latitude == 0.0 && dst.longitude == 0.0))
                    Marker(
                      point: dst,
                      width: 44,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Drop shadow
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          // Pin body
                          CustomPaint(
                            size: const Size(44, 52),
                            painter: _RedPinPainter(),
                          ),
                          // Inner white dot
                          const Positioned(
                            top: 10,
                            child: Icon(Icons.circle, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ),

                  // ── Current position — pulsing green dot + direction arrow ──
                  if (cur != null)
                    Marker(
                      point: cur,
                      width: 64,
                      height: 64,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            Container(
                              width: 64 * _pulseAnim.value,
                              height: 64 * _pulseAnim.value,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34A853).withAlpha(
                                  (50 * (1.2 - _pulseAnim.value)).round().clamp(0, 255),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Mid ring
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34A853).withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF34A853).withAlpha(100),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Directional arrow (rotates toward destination)
                            Transform.rotate(
                              angle: heading * math.pi / 180,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34A853),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // ── LIVE badge ───────────────────────────────────────────────
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(170),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFFEA4335), size: 8),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Map control buttons (right side, Google Maps style) ─────
        Positioned(
          right: 10,
          bottom: widget.fullScreen ? 260 : 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom In
              _mapControlButton(
                icon: Icons.add,
                onTap: () {
                  try { widget.mapController.move(widget.mapController.camera.center, widget.mapController.camera.zoom + 1); } catch (_) {}
                },
              ),
              const SizedBox(height: 4),
              // Zoom Out
              _mapControlButton(
                icon: Icons.remove,
                onTap: () {
                  try { widget.mapController.move(widget.mapController.camera.center, widget.mapController.camera.zoom - 1); } catch (_) {}
                },
              ),
              const SizedBox(height: 8),
              // Compass / Rotate North
              _mapControlButton(
                icon: Icons.explore,
                tooltip: 'Reset north',
                onTap: () {
                  try { widget.mapController.rotate(0); } catch (_) {}
                },
              ),
              const SizedBox(height: 4),
              // Re-center on current position
              if (cur != null)
                _mapControlButton(
                  icon: Icons.my_location,
                  iconColor: const Color(0xFF1A73E8),
                  onTap: () {
                    try { widget.mapController.move(cur, 16); } catch (_) {}
                  },
                ),
            ],
          ),
        ),

        // ── Bottom ETA card — only shown in card (non-fullscreen) mode ──
        if (!widget.fullScreen && _selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white.withAlpha(242),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.directions_car,
                      color: Color(0xFF1A73E8), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selected!.durationLabel} away',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF202124),
                          ),
                        ),
                        Text(
                          _selected!.distanceLabel,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF5F6368)),
                        ),
                      ],
                    ),
                  ),
                  if (_fetchingRoute)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

        // ── ETA pill (full-screen mode, above bottom sheet) ──────────
        if (widget.fullScreen && _selected != null)
          Positioned(
            left: 12,
            right: 60,
            bottom: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car,
                      color: Color(0xFF1A73E8), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_selected!.durationLabel}  •  ${_selected!.distanceLabel}',                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),
                  if (_fetchingRoute) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  if (_routes.length > 1) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${_routes.length} routes',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );

    // Full-screen: just return the stack (fills Positioned.fill from parent).
    if (widget.fullScreen) return mapStack;

    // Card mode: wrap in rounded clip with fixed height.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(height: 300, child: mapStack),
    );
  }
  // Helper: single square map control button (Google Maps style white card).
  Widget _mapControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    String? tooltip,
  }) {
    final btn = Builder(
      builder: (context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20,
                color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }
} // end _LiveMapViewState

String _title(int step) =>
    const {
      3: 'Manager Approval',
      4: 'Approved Visit',
      5: 'Office Check-Out',
      6: 'Travel in Progress',
      7: 'Client Check-In',
      8: 'Active Client Visit',
      9: 'Work Update & Proof',
      10: 'Expense Claim',
      11: 'Return / Direct Checkout',
      12: 'Visit Summary & Verification',
    }[step] ??
    'Client Visit';
String _label(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
String _dateTime(DateTime value) {
  final local = value.toLocal();
  return '${_date(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _approverRoleLabel(String role) => switch (role.toLowerCase()) {
  'hr' => 'HR',
  'ceo' => 'CEO',
  'tl' => 'TL',
  'manager' => 'MANAGER',
  'admin' => 'ADMIN',
  'superadmin' => 'SUPER ADMIN',
  _ => 'Approver',
};
String _approvalBadgeLabel(String role) => role.trim().isEmpty
    ? 'APPROVED'
    : '${_approverRoleLabel(role).toUpperCase()} APPROVED';
String _duration(Duration value) =>
    '${value.inHours.toString().padLeft(2, '0')}:${(value.inMinutes % 60).toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

/// Paints a Google Maps style teardrop/pin shape in red.
class _RedPinPainter extends CustomPainter {
  const _RedPinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r = w / 2;

    final shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final fillPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = _pinPath(cx, r, r, h);
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  ui.Path _pinPath(double cx, double r, double radius, double h) {
    const tipAngle = 0.42;
    final path = ui.Path();
    path.moveTo(cx, h - 2);
    path.arcTo(
      Rect.fromCircle(center: Offset(cx, r), radius: radius),
      math.pi / 2 + tipAngle,
      math.pi * 2 - tipAngle * 2,
      false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_RedPinPainter oldDelegate) => false;
}