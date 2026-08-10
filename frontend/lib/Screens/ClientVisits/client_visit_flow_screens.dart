import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart' show FontFeature;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:signature/signature.dart';
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
  final bool reviewerMode;

  const ClientVisitReadOnlyFlowScreen({
    super.key,
    required this.userId,
    required this.visitId,
    required this.step,
    required this.service,
    this.reviewerMode = false,
  });

  @override
  Widget build(BuildContext context) => _VisitFlowPage(
    step: step,
    userId: userId,
    visitId: visitId,
    service: service,
    readOnlyMode: true,
    reviewerMode: reviewerMode,
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
  bool _routeReversed = false;
  String _selectedTravelMode = 'drive';
  double _mapRotation = 0;
  final List<LatLng> _additionalStops = [];
  List<String> _attendees = [];
  List<Map<String, dynamic>> _checklist = [];
  // Local proof images staged for upload (Step 9)
  final List<String> _stagedProofPaths = [];
  // Outcome and follow-up for step 9
  String _outcome9 = '';
  String _followUp9 = '';
  // Hand-drawn signature pad controller (Step 9)
  late final SignatureController _signaturePadController;

  @override
  void initState() {
    super.initState();
    _signaturePadController = SignatureController(
      penStrokeWidth: 2.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
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
    _signaturePadController.dispose();
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
        final hasValidCoords =
            lat != null &&
            lng != null &&
            lat != 0.0 &&
            lng != 0.0 &&
            lat.abs() <= 90 &&
            lng.abs() <= 180;
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
  Future<void> _geocodeDestination(
    String address, [
    String clientName = '',
  ]) async {
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
      final response1 = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/search'
              '?q=$query1&format=json&limit=1&countrycodes=in',
            ),
            headers: {'User-Agent': 'HRMS-Bitbyte/1.0'},
          )
          .timeout(const Duration(seconds: 10));

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
        final response2 = await http
            .get(
              Uri.parse(
                'https://nominatim.openstreetmap.org/search'
                '?q=$query2&format=json&limit=1&countrycodes=in',
              ),
              headers: {'User-Agent': 'HRMS-Bitbyte/1.0'},
            )
            .timeout(const Duration(seconds: 10));
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

  Future<void> _addRouteStop() async {
    final address = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add a stop'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Place or address',
              prefixIcon: Icon(Icons.add_location_alt_outlined),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (address == null || address.isEmpty || !mounted) return;

    try {
      final query = Uri.encodeComponent(
        address.toLowerCase().contains('india') ? address : '$address, India',
      );
      final response = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/search'
              '?q=$query&format=json&limit=1&countrycodes=in',
            ),
            headers: {'User-Agent': 'HRMS-Bitbyte/1.0'},
          )
          .timeout(const Duration(seconds: 10));
      final results = response.statusCode == 200
          ? jsonDecode(response.body) as List
          : const [];
      if (results.isEmpty) {
        _message('Stop not found. Enter a more complete address.');
        return;
      }
      final item = results.first as Map<String, dynamic>;
      final lat = double.tryParse('${item['lat']}');
      final lng = double.tryParse('${item['lon']}');
      if (lat == null || lng == null || !mounted) return;
      setState(() {
        _additionalStops.add(LatLng(lat, lng));
        _routeOptions = [];
        _selectedRouteIndex = 0;
        _etaText = '';
        _distanceText = '';
      });
      _message('Stop added to this route.');
      Future.delayed(const Duration(milliseconds: 250), _fitMapBounds);
    } catch (_) {
      _message('Could not find that stop. Check the network and try again.');
    }
  }

  /// Adjusts the map camera to fit origin, current position and destination.
  void _fitMapBounds() {
    final points = <LatLng>[];

    // Current GPS position
    if (_lastTrackedPosition != null) {
      points.add(
        LatLng(_lastTrackedPosition!.latitude, _lastTrackedPosition!.longitude),
      );
    }

    // Office checkout position (valid only)
    final ocLat = _visit?.officeCheckOutLatitude;
    final ocLng = _visit?.officeCheckOutLongitude;
    if (ocLat != null && ocLng != null && !(ocLat == 0.0 && ocLng == 0.0)) {
      points.add(LatLng(ocLat, ocLng));
    }

    // Destination (valid only)
    final dst = _destinationLatLng;
    if (dst != null && !(dst.latitude == 0.0 && dst.longitude == 0.0)) {
      points.add(dst);
    }
    points.addAll(_additionalStops);

    if (points.length < 2) {
      // At least move to the single known point
      if (points.length == 1) {
        try {
          _mapController.move(points.first, 15);
        } catch (_) {}
      }
      return;
    }
    try {
      _mapController.rotate(0);
      if (_mapRotation != 0 && mounted) {
        setState(() => _mapRotation = 0);
      }
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
      final seeded = _visit!.travelRoute
          .map((p) {
            final lat = double.tryParse('${p['latitude'] ?? p['lat'] ?? ''}');
            final lng = double.tryParse('${p['longitude'] ?? p['lng'] ?? ''}');
            if (lat != null && lng != null) return LatLng(lat, lng);
            return null;
          })
          .whereType<LatLng>()
          .toList();
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
                  _mapController.move(
                    point,
                    _mapController.camera.zoom < 14
                        ? 15
                        : _mapController.camera.zoom,
                  );
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
      _message(
        'A comment is required to ${action == 'approve' ? 'approve' : action} this visit.',
      );
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
          'Your current GPS will be recorded as arrival point.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, arrived'),
          ),
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
    // Client-site photos require consent, so only GPS is mandatory.
    if (_capturedPosition == null) {
      _message('Please capture your GPS location at the client site.');
      return;
    }
    await _run(() async {
      final position = _capturedPosition!;
      final selfiePath = _selfiePath;
      if (selfiePath != null) {
        await widget.service.uploadFiles(
          widget.userId,
          widget.visitId,
          'client_check_in',
          [selfiePath],
          fallbackCategory: 'check_in',
        );
      }
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
        if (_signature.text.trim().isNotEmpty)
          'client_signature_name': _signature.text.trim(),
      });
      // Upload staged proof photos
      if (_stagedProofPaths.isNotEmpty) {
        await widget.service.uploadFiles(
          widget.userId,
          widget.visitId,
          'proof',
          _stagedProofPaths,
        );
        if (mounted) setState(() => _stagedProofPaths.clear());
      }
      // Upload drawn signature as a proof image if the pad was used
      if (_signaturePadController.isNotEmpty) {
        final pngBytes = await _signaturePadController.toPngBytes();
        if (pngBytes != null) {
          final tmp = await getTemporaryDirectory();
          final sigFile = File(
            '${tmp.path}/client_signature_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await sigFile.writeAsBytes(pngBytes);
          await widget.service.uploadFiles(
            widget.userId,
            widget.visitId,
            'proof',
            [sigFile.path],
          );
          await sigFile.delete();
        }
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

  /// Called when the employee taps "Submit Expense" — shows a success dialog
  /// then navigates to the Return / Checkout screen (step 11).
  Future<void> _submitExpense() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ClientVisitColors.green.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: ClientVisitColors.green,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Expense Submitted!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your expense claim has been recorded successfully.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Continue to Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientVisitReturnCheckoutScreen(
            userId: widget.userId,
            visitId: widget.visitId,
            service: widget.service,
          ),
        ),
      );
    }
  }

  Future<void> _complete() async {
    // Step 11 validation: outcome required, selfie + GPS required.
    if (_outcome.text.trim().isEmpty) {
      _message('Visit outcome is required to complete duty.');
      return;
    }
    if (_outcome.text.trim().length < 10) {
      _message(
        'Outcome must be at least 10 characters. Please describe the visit result.',
      );
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
      // Upload drawn signature as a proof image if the pad was used
      if (_signaturePadController.isNotEmpty) {
        final pngBytes = await _signaturePadController.toPngBytes();
        if (pngBytes != null) {
          final tmp = await getTemporaryDirectory();
          final sigFile = File(
            '${tmp.path}/client_signature_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await sigFile.writeAsBytes(pngBytes);
          await widget.service.uploadFiles(
            widget.userId,
            widget.visitId,
            'proof',
            [sigFile.path],
          );
          await sigFile.delete();
        }
      }
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
      ClientVisit reportVisit;
      try {
        reportVisit = await widget.service.fetchVisit(widget.userId, visit.id);
      } catch (_) {
        reportVisit = visit;
      }

      String value(Object? source) {
        final text = '${source ?? ''}'.trim();
        return text.isEmpty ? '—' : text;
      }

      String dateTime(DateTime? source) {
        if (source == null) return '—';
        final local = source.toLocal();
        String two(int number) => number.toString().padLeft(2, '0');
        return '${two(local.day)}/${two(local.month)}/${local.year} '
            '${two(local.hour)}:${two(local.minute)}';
      }

      String elapsed(DateTime? start, DateTime? end) {
        if (start == null || end == null) return '—';
        final duration = end.toLocal().difference(start.toLocal());
        if (duration.isNegative) return '—';
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        return hours == 0 ? '$minutes min' : '${hours}h ${minutes}m';
      }

      String coordinates(double? latitude, double? longitude) {
        if (latitude == null || longitude == null) return '—';
        return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      final routePoints = reportVisit.travelRoute
          .map((point) {
            final latitude = double.tryParse(
              '${point['latitude'] ?? point['lat'] ?? ''}',
            );
            final longitude = double.tryParse(
              '${point['longitude'] ?? point['lng'] ?? ''}',
            );
            return latitude == null || longitude == null
                ? null
                : LatLng(latitude, longitude);
          })
          .whereType<LatLng>()
          .toList();
      var recordedDistanceKm = 0.0;
      const distanceCalculator = Distance();
      for (var index = 1; index < routePoints.length; index++) {
        recordedDistanceKm += distanceCalculator.as(
          LengthUnit.Kilometer,
          routePoints[index - 1],
          routePoints[index],
        );
      }

      pw.Widget sectionTitle(String title) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FE)),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            color: const PdfColor.fromInt(0xFF174EA6),
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

      pw.Widget detailsTable(List<List<String>> rows) =>
          pw.TableHelper.fromTextArray(
            headers: const ['Field', 'Details'],
            data: rows,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F3F4),
            ),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.25),
              1: pw.FlexColumnWidth(3),
            },
          );

      pw.MemoryImage? logo;
      try {
        final logoData = await rootBundle.load('assets/logo.png');
        logo = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {}

      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.fromLTRB(28, 30, 28, 30),
          ),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Confidential · HRMS-ERP Client Visit Report',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          build: (_) => [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF0B1B35),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  if (logo != null) ...[
                    pw.Container(
                      width: 46,
                      height: 46,
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CLIENT VISIT REPORT',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${reportVisit.visitId}  ·  ${_label(reportVisit.status).toUpperCase()}',
                          style: const pw.TextStyle(
                            color: PdfColor.fromInt(0xFF9CC7FF),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated ${dateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),

            sectionTitle('VISIT INFORMATION'),
            detailsTable([
              ['Visit ID', reportVisit.visitId],
              ['Status', _label(reportVisit.status)],
              ['Scheduled', dateTime(reportVisit.scheduledAt)],
              ['Planned duration', '${reportVisit.durationMinutes} minutes'],
              ['Travel mode', _label(reportVisit.travelMode)],
              ['Purpose', value(reportVisit.purpose)],
              ['Notes', value(reportVisit.notes)],
              ['Created', dateTime(reportVisit.createdAt)],
              ['Last updated', dateTime(reportVisit.updatedAt)],
            ]),

            sectionTitle('EMPLOYEE AND REPORTING DETAILS'),
            detailsTable([
              ['Employee name', value(reportVisit.employeeName)],
              ['Employee ID', value(reportVisit.employeeUserId)],
              ['Reporting manager / TL ID', value(reportVisit.managerUserId)],
            ]),

            sectionTitle('CLIENT DETAILS'),
            detailsTable([
              ['Client name', value(reportVisit.clientName)],
              ['Contact person', value(reportVisit.contactPerson)],
              ['Phone', value(reportVisit.contactPhone)],
              ['Address', value(reportVisit.address)],
              [
                'Client coordinates',
                coordinates(
                  reportVisit.clientLatitude,
                  reportVisit.clientLongitude,
                ),
              ],
            ]),

            sectionTitle('APPROVAL AND VERIFICATION'),
            detailsTable([
              [
                'Approved by',
                reportVisit.approvedByName.isEmpty
                    ? value(reportVisit.approvedBy)
                    : '${reportVisit.approvedByName} (${value(reportVisit.approvedByRole)})',
              ],
              ['Approved at', dateTime(reportVisit.approvedAt)],
              ['Approval comment', value(reportVisit.approvalComment)],
              [
                'Manager verification',
                reportVisit.managerVerifiedBy.isEmpty
                    ? 'Pending'
                    : 'Verified by ${reportVisit.managerVerifiedBy}',
              ],
              ['Verified at', dateTime(reportVisit.managerVerifiedAt)],
            ]),

            sectionTitle('VISIT TIMELINE'),
            detailsTable([
              ['Office check-out', dateTime(reportVisit.officeCheckOutAt)],
              ['Reached client', dateTime(reportVisit.reachedClientAt)],
              ['Client check-in', dateTime(reportVisit.checkInAt)],
              ['Visit checkout', dateTime(reportVisit.checkOutAt)],
              [
                'Travel duration',
                elapsed(
                  reportVisit.officeCheckOutAt,
                  reportVisit.reachedClientAt,
                ),
              ],
              [
                'Client visit duration',
                elapsed(reportVisit.checkInAt, reportVisit.checkOutAt),
              ],
              [
                'Total duty duration',
                elapsed(reportVisit.officeCheckOutAt, reportVisit.checkOutAt),
              ],
              [
                'Office check-out GPS',
                coordinates(
                  reportVisit.officeCheckOutLatitude,
                  reportVisit.officeCheckOutLongitude,
                ),
              ],
              [
                'Arrival GPS',
                coordinates(
                  reportVisit.reachedClientLatitude,
                  reportVisit.reachedClientLongitude,
                ),
              ],
              [
                'Starting odometer',
                reportVisit.startOdometer == null
                    ? '—'
                    : reportVisit.startOdometer!.toStringAsFixed(1),
              ],
            ]),

            sectionTitle('LIVE TRACKING / TRAVEL ROUTE'),
            detailsTable([
              ['GPS points recorded', '${routePoints.length}'],
              [
                'Recorded route distance',
                '${recordedDistanceKm.toStringAsFixed(2)} km',
              ],
              [
                'First recorded point',
                routePoints.isEmpty
                    ? '—'
                    : coordinates(
                        routePoints.first.latitude,
                        routePoints.first.longitude,
                      ),
              ],
              [
                'Last recorded point',
                routePoints.isEmpty
                    ? '—'
                    : coordinates(
                        routePoints.last.latitude,
                        routePoints.last.longitude,
                      ),
              ],
            ]),

            sectionTitle('EXPENSE DETAILS'),
            if (reportVisit.expenses.isEmpty)
              pw.Text(
                'No expenses recorded.',
                style: const pw.TextStyle(fontSize: 9),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const ['#', 'Category', 'Amount (INR)', 'Note'],
                data: List.generate(reportVisit.expenses.length, (index) {
                  final expense = reportVisit.expenses[index];
                  final amount =
                      double.tryParse('${expense['amount'] ?? 0}') ?? 0;
                  return [
                    '${index + 1}',
                    _label('${expense['category'] ?? ''}'),
                    amount.toStringAsFixed(2),
                    value(expense['note']),
                  ];
                }),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFF4E5),
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(5),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.35),
                  1: pw.FlexColumnWidth(1.1),
                  2: pw.FlexColumnWidth(0.9),
                  3: pw.FlexColumnWidth(2.3),
                },
              ),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              color: const PdfColor.fromInt(0xFFF8F9FA),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL EXPENSE: INR ${reportVisit.expenseTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            sectionTitle('ATTENDEES'),
            pw.Text(
              reportVisit.attendees.isEmpty
                  ? 'No attendees recorded.'
                  : reportVisit.attendees.map(value).join(', '),
              style: const pw.TextStyle(fontSize: 9),
            ),

            sectionTitle('CHECKLIST'),
            if (reportVisit.checklist.isEmpty)
              pw.Text(
                'No checklist entries recorded.',
                style: const pw.TextStyle(fontSize: 9),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const ['#', 'Checklist item', 'Status'],
                data: List.generate(reportVisit.checklist.length, (index) {
                  final raw = reportVisit.checklist[index];
                  final item = raw is Map
                      ? Map<String, dynamic>.from(raw)
                      : <String, dynamic>{'label': '$raw', 'done': false};
                  return [
                    '${index + 1}',
                    value(item['label']),
                    item['done'] == true ? 'Completed' : 'Pending',
                  ];
                }),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE6F4EA),
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(5),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.35),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(0.9),
                },
              ),

            sectionTitle('OUTCOME AND FOLLOW-UP'),
            detailsTable([
              ['Outcome', value(reportVisit.outcome)],
              ['Follow-up', value(reportVisit.followUp)],
              ['Return mode', value(_label(reportVisit.returnMode))],
            ]),

            sectionTitle('ATTACHMENTS / VISIT PROOF'),
            if (reportVisit.attachments.isEmpty)
              pw.Text(
                'No attachments recorded.',
                style: const pw.TextStyle(fontSize: 9),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const ['#', 'Category', 'File', 'Uploaded'],
                data: List.generate(reportVisit.attachments.length, (index) {
                  final attachment = reportVisit.attachments[index];
                  final uploadedAt = DateTime.tryParse(
                    '${attachment['created_at'] ?? ''}',
                  );
                  return [
                    '${index + 1}',
                    _label('${attachment['category'] ?? ''}'),
                    value(attachment['original_name'] ?? attachment['url']),
                    dateTime(uploadedAt),
                  ];
                }),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF3E8FD),
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.all(5),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(2.3),
                  3: pw.FlexColumnWidth(1),
                },
              ),

            pw.SizedBox(height: 18),
            pw.Text(
              'This report was generated electronically from HRMS-ERP records.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      );
      final bytes = await document.save();
      final fileName = '${reportVisit.visitId}-client-visit-report.pdf';

      // Save to device Downloads/HRMS-ERP and get back the saved URI
      final savedUri = await _filesChannel.invokeMethod<String>(
        'saveToDownloads',
        {'fileName': fileName, 'mimeType': 'application/pdf', 'bytes': bytes},
      );

      // Immediately open the PDF so it appears in recent files / gallery
      if (savedUri != null && savedUri.isNotEmpty) {
        await _filesChannel.invokeMethod('openUrl', {
          'url': savedUri,
          'mimeType': 'application/pdf',
        });
      }

      _message('Report saved to Downloads/HRMS-ERP');
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
    final origin =
        (ocLat != null && ocLng != null && !(ocLat == 0.0 && ocLng == 0.0))
        ? LatLng(ocLat, ocLng)
        : null;
    final current = _lastTrackedPosition != null
        ? LatLng(
            _lastTrackedPosition!.latitude,
            _lastTrackedPosition!.longitude,
          )
        : null;
    final routeCurrent = _routeReversed ? _destinationLatLng : current;
    final routeDestination = _routeReversed ? current : _destinationLatLng;
    final safePad = MediaQuery.of(context).padding;

    return ClientVisitTheme(
      child: Scaffold(
        body: Stack(
          children: [
            // ── Full-screen map ──────────────────────────────────────
            Positioned.fill(
              child: _LiveMapView(
                key: ValueKey(
                  'travel-map-$_routeReversed-${_additionalStops.length}',
                ),
                mapController: _mapController,
                routePoints: _liveRoutePoints,
                waypoints: _routeReversed
                    ? _additionalStops.reversed.toList()
                    : List<LatLng>.from(_additionalStops),
                origin: _routeReversed ? _destinationLatLng : origin,
                current: routeCurrent,
                destination: routeDestination,
                fullScreen: true,
                navigationMode: _navMode,
                showEtaOverlay: false,
                selectedRouteIndex: _selectedRouteIndex,
                onRotationChanged: (rotation) {
                  final normalized = ((rotation + 180) % 360) - 180;
                  if (!mounted || (normalized - _mapRotation).abs() < 0.5) {
                    return;
                  }
                  setState(() => _mapRotation = normalized);
                },
                onEtaUpdate: (eta, dist) {
                  if (mounted) {
                    setState(() {
                      _etaText = eta;
                      _distanceText = dist;
                    });
                  }
                },
                onRoutesReady: (routes, idx) {
                  if (mounted) {
                    setState(() {
                      _routeOptions = routes;
                      _selectedRouteIndex = idx;
                    });
                  }
                },
              ),
            ),

            // ── Google Maps style origin / destination card ─────────
            Positioned(
              top: safePad.top + 8,
              left: 16,
              right: 16,
              child: _travelDirectionsHeader(visit),
            ),

            // ── Map controls (right side) ─────────────────────────
            if (!_navMode)
              Positioned(
                right: 12,
                top: safePad.top + 108,
                child: _travelMapButton(
                  icon: Icons.layers_rounded,
                  color: const Color(0xFF006A72),
                  onTap: _showMapOptions,
                ),
              ),
            if (_mapRotation.abs() > 1)
              Positioned(
                right: 12,
                top: safePad.top + 164,
                child: _travelMapButton(
                  icon: Icons.explore_rounded,
                  rotationDegrees: -_mapRotation,
                  onTap: () {
                    try {
                      _mapController.rotate(0);
                    } catch (_) {}
                    setState(() => _mapRotation = 0);
                  },
                ),
              ),
            Positioned(
              right: 12,
              bottom: _navMode ? 190 : 292,
              child: _travelMapButton(
                icon: Icons.my_location,
                color: const Color(0xFF1A73E8),
                onTap: () {
                  if (_lastTrackedPosition != null) {
                    try {
                      _mapController.move(
                        LatLng(
                          _lastTrackedPosition!.latitude,
                          _lastTrackedPosition!.longitude,
                        ),
                        _navMode ? 17 : 15,
                      );
                    } catch (_) {}
                  }
                },
              ),
            ),

            // ── Bottom panel — Google Maps "Drive" style ──────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 6),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (!_navMode) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedModeTitle,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF202124),
                                ),
                              ),
                            ),
                            _travelSheetAction(
                              icon: Icons.tune_rounded,
                              tooltip: 'Route options',
                              onTap: _showRouteOptions,
                            ),
                            _travelSheetAction(
                              icon: Icons.share_rounded,
                              tooltip: 'Share directions',
                              onTap: () => _shareDirections(visit),
                            ),
                            _travelSheetAction(
                              icon: Icons.close_rounded,
                              tooltip: 'Close directions',
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 58,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _travelMode(
                              mode: 'drive',
                              icon: Icons.directions_car_rounded,
                              label: _etaText.isEmpty ? 'Drive' : _etaText,
                            ),
                            _travelMode(
                              mode: 'bike',
                              icon: Icons.pedal_bike_rounded,
                              label: _estimatedModeEta(15),
                            ),
                            _travelMode(
                              mode: 'transit',
                              icon: Icons.directions_transit_rounded,
                              label: '—',
                              enabled: false,
                            ),
                            _travelMode(
                              mode: 'walk',
                              icon: Icons.directions_walk_rounded,
                              label: _estimatedModeEta(4.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Route options
                    const Divider(height: 1),
                    // ── Google Maps style Drive header ──────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _selectedModeIcon,
                            size: 22,
                            color: const Color(0xFF202124),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Big bold ETA + distance — matches Google Maps
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _selectedModeEta,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF202124),
                                      ),
                                    ),
                                    if (_distanceText.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '($_distanceText)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF5F6368),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // Route description
                                if (_routeOptions.isNotEmpty &&
                                    _selectedRouteIndex <
                                        _routeOptions.length) ...[
                                  Text(
                                    _selectedTravelMode == 'drive'
                                        ? (_selectedRouteIndex == 0
                                              ? 'Fastest route, via ${_routeOptions[0].via.isNotEmpty ? _routeOptions[0].via : 'main road'}'
                                              : 'Via ${_routeOptions[_selectedRouteIndex].via.isNotEmpty ? _routeOptions[_selectedRouteIndex].via : 'alternate road'}')
                                        : _selectedTravelMode == 'bike'
                                        ? 'Estimated cycling time'
                                        : 'Estimated walking time',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5F6368),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Toll + fuel info row
                                  if (_selectedTravelMode == 'drive')
                                    Row(
                                      children: [
                                        if (_routeOptions[_selectedRouteIndex]
                                            .hasTolls) ...[
                                          const Icon(
                                            Icons.toll_rounded,
                                            size: 13,
                                            color: Color(0xFFF29900),
                                          ),
                                          const SizedBox(width: 3),
                                          const Text(
                                            'Tolls  ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFF29900),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Text(
                                            '·  ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9AA0A6),
                                            ),
                                          ),
                                        ],
                                        const Icon(
                                          Icons.local_gas_station_rounded,
                                          size: 13,
                                          color: Color(0xFF34A853),
                                        ),
                                        const SizedBox(width: 3),
                                        const Text(
                                          'Saves fuel',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF34A853),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ],
                            ),
                          ),
                          // Speed chip — top right
                          if (_lastTrackedPosition != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A73E8).withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF1A73E8).withAlpha(50),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    (_lastTrackedPosition!.speed * 3.6)
                                        .toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  ),
                                  const Text(
                                    'km/h',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF1A73E8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Emergency contact row
                    if (_navMode &&
                        (visit.contactPerson.isNotEmpty ||
                            visit.contactPhone.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emergency_rounded,
                              size: 14,
                              color: Color(0xFFEA4335),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Emergency: ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${visit.contactPerson} (${visit.contactPhone})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (visit.contactPhone.isNotEmpty)
                              GestureDetector(
                                onTap: () =>
                                    _message('Calling ${visit.contactPhone}'),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF34A853,
                                    ).withAlpha(15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.call,
                                    size: 16,
                                    color: Color(0xFF34A853),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // ── Action buttons — Google Maps style ───────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        safePad.bottom + 12,
                      ),
                      child: Row(
                        children: [
                          // Start / Stop navigation
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _navMode
                                    ? Colors.grey.shade700
                                    : const Color(0xFF008C95),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  // Client visits always navigate employee → client.
                                  // A reversed route is useful for preview only.
                                  if (!_navMode && _routeReversed) {
                                    _routeReversed = false;
                                    _routeOptions = [];
                                    _selectedRouteIndex = 0;
                                  }
                                  _navMode = !_navMode;
                                });
                                if (_navMode && _lastTrackedPosition != null) {
                                  try {
                                    _mapController.move(
                                      LatLng(
                                        _lastTrackedPosition!.latitude,
                                        _lastTrackedPosition!.longitude,
                                      ),
                                      17,
                                    );
                                  } catch (_) {}
                                } else if (!_navMode) {
                                  _fitMapBounds();
                                }
                              },
                              icon: Icon(
                                _navMode
                                    ? Icons.stop_rounded
                                    : Icons.navigation_rounded,
                                size: 20,
                              ),
                              label: Text(
                                _navMode ? 'Stop' : 'Start',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Arrival is only valid after turn-by-turn mode starts.
                          if (!widget.readOnlyMode && _navMode)
                            Expanded(
                              flex: 3,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A73E8),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _working ? null : _reached,
                                icon: const Icon(Icons.flag_rounded, size: 20),
                                label: const Text(
                                  'Reached client',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          if (!widget.readOnlyMode && !_navMode) ...[
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF006A72),
                                  backgroundColor: const Color(0xFFDDF7FA),
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _addRouteStop,
                                icon: const Icon(
                                  Icons.add_location_alt_outlined,
                                  size: 19,
                                ),
                                label: Text(
                                  _additionalStops.isEmpty
                                      ? 'Add stops'
                                      : '${_additionalStops.length} stop${_additionalStops.length == 1 ? '' : 's'}',
                                  maxLines: 1,
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: 'Share directions',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFDDF7FA),
                                foregroundColor: const Color(0xFF006A72),
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () => _shareDirections(visit),
                              icon: const Icon(Icons.share_rounded),
                            ),
                          ],
                          if (widget.readOnlyMode)
                            Expanded(flex: 3, child: _monitoringNotice()),
                        ],
                      ),
                    ),
                    if (_trackingError != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA4335).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFEA4335),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _trackingError!.replaceFirst('Exception: ', ''),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFEA4335),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _startTravelTracking,
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
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

  Widget _travelDirectionsHeader(ClientVisit visit) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 14,
                  child: _directionPointIcon(currentLocation: !_routeReversed),
                ),
                Positioned(
                  top: 36,
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFBDBDBD),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  child: _directionPointIcon(currentLocation: _routeReversed),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 43.5,
                  child: Row(
                    children: [
                      Expanded(
                        child: _directionLabel(
                          visit,
                          destination: _routeReversed,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'More options',
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'routes') _showRouteOptions();
                          if (value == 'overview') _fitMapBounds();
                          if (value == 'close') {
                            Navigator.of(context).maybePop();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'routes',
                            child: Text('Route options'),
                          ),
                          PopupMenuItem(
                            value: 'overview',
                            child: Text('Route overview'),
                          ),
                          PopupMenuItem(
                            value: 'close',
                            child: Text('Close directions'),
                          ),
                        ],
                        child: const SizedBox(
                          width: 42,
                          height: 40,
                          child: Icon(
                            Icons.more_vert,
                            size: 21,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  endIndent: 48,
                  color: Colors.grey.shade300,
                ),
                SizedBox(
                  height: 43.5,
                  child: Row(
                    children: [
                      Expanded(
                        child: _directionLabel(
                          visit,
                          destination: !_routeReversed,
                        ),
                      ),
                      Tooltip(
                        message: 'Swap start and destination',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _swapRouteEndpoints,
                          child: const SizedBox(
                            width: 42,
                            height: 40,
                            child: Icon(
                              Icons.swap_vert_rounded,
                              size: 24,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionPointIcon({required bool currentLocation}) {
    if (!currentLocation) {
      return const Icon(
        Icons.location_on_outlined,
        size: 23,
        color: Color(0xFFEA4335),
      );
    }
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFD2E3FC),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFF1A73E8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _directionLabel(ClientVisit visit, {required bool destination}) {
    if (!destination) {
      return const Text(
        'Your location',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF1A73E8),
          fontWeight: FontWeight.w500,
        ),
      );
    }
    if (_destinationLatLng == null) {
      return const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF5F6368),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Finding destination…',
            style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
          ),
        ],
      );
    }
    return Text(
      visit.clientName.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF202124),
      ),
    );
  }

  void _swapRouteEndpoints() {
    if (_destinationLatLng == null || _lastTrackedPosition == null) {
      _message('Waiting for both locations before swapping the route.');
      return;
    }
    setState(() {
      _routeReversed = !_routeReversed;
      _routeOptions = [];
      _selectedRouteIndex = 0;
      _etaText = '';
      _distanceText = '';
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _fitMapBounds();
    });
  }

  DropdownMenuItem<String> _expenseItem(
    String value,
    IconData icon,
    String label,
  ) => DropdownMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
        const SizedBox(width: 8),
        Text(label),
      ],
    ),
  );

  /// Google Maps style circular map control button (used in travel screen).
  Widget _travelMapButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    double rotationDegrees = 0,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Transform.rotate(
            angle: rotationDegrees * math.pi / 180,
            child: Icon(
              icon,
              size: 20,
              color: color ?? const Color(0xFF5F6368),
            ),
          ),
        ),
      ),
    );
  }

  void _showMapOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Map details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 56,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1A73E8),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                title: const Text('Default'),
                subtitle: const Text('Road map'),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1A73E8),
                ),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _travelSheetAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: const Color(0xFFF1F3F4),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, size: 21, color: const Color(0xFF202124)),
        ),
      ),
    );
  }

  Widget _travelMode({
    required String mode,
    required IconData icon,
    required String label,
    bool enabled = true,
  }) {
    final selected = _selectedTravelMode == mode;
    final color = selected ? const Color(0xFF007B83) : const Color(0xFF5F6368);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: !enabled
          ? null
          : () {
              setState(() => _selectedTravelMode = mode);
              _fitMapBounds();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F7FA) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: enabled ? color : Colors.grey.shade400),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: enabled ? color : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _selectedModeEta {
    switch (_selectedTravelMode) {
      case 'bike':
        return _estimatedModeEta(15);
      case 'walk':
        return _estimatedModeEta(4.5);
      default:
        return _etaText.isNotEmpty ? _etaText : '—';
    }
  }

  String get _selectedModeTitle {
    switch (_selectedTravelMode) {
      case 'bike':
        return 'Bicycle';
      case 'walk':
        return 'Walk';
      default:
        return 'Drive';
    }
  }

  IconData get _selectedModeIcon {
    switch (_selectedTravelMode) {
      case 'bike':
        return Icons.pedal_bike_rounded;
      case 'walk':
        return Icons.directions_walk_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  String _estimatedModeEta(double speedKmh) {
    if (_routeOptions.isEmpty || _selectedRouteIndex >= _routeOptions.length) {
      return '—';
    }
    final minutes =
        (_routeOptions[_selectedRouteIndex].distanceKm / speedKmh * 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '$hours hr' : '$hours hr $remainder';
  }

  void _chooseRoute(int index) {
    if (index < 0 || index >= _routeOptions.length) return;
    final route = _routeOptions[index];
    setState(() {
      _selectedRouteIndex = index;
      _etaText = route.durationLabel;
      _distanceText = route.distanceLabel;
    });
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.points),
          padding: const EdgeInsets.fromLTRB(40, 150, 40, 330),
        ),
      );
    } catch (_) {}
  }

  void _showRouteOptions() {
    if (_routeOptions.isEmpty) {
      _message('Route options are still loading.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Route options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...List.generate(_routeOptions.length, (index) {
                final route = _routeOptions[index];
                final selected = index == _selectedRouteIndex;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.directions_car_rounded,
                    color: selected
                        ? const Color(0xFF1A73E8)
                        : const Color(0xFF5F6368),
                  ),
                  title: Text(
                    '${route.durationLabel} (${route.distanceLabel})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    index == 0
                        ? 'Fastest route${route.via.isEmpty ? '' : ', via ${route.via}'}'
                        : (route.via.isEmpty
                              ? 'Alternate route'
                              : 'via ${route.via}'),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF1A73E8))
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _chooseRoute(index);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareDirections(ClientVisit visit) async {
    if (_destinationLatLng == null) {
      _message('Please wait while the client location is being resolved.');
      _geocodingDone = false;
      unawaited(_geocodeDestination(visit.address, visit.clientName));
      return;
    }
    try {
      final trackingUrl = await widget.service.createTrackingLink(
        widget.userId,
        widget.visitId,
        destinationLatitude: _destinationLatLng?.latitude,
        destinationLongitude: _destinationLatLng?.longitude,
      );
      final message =
          'Track the live journey to ${visit.clientName}:\n'
          '$trackingUrl\n\n'
          'This secure link expires automatically.';
      await Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        _message('Live tracking link copied. Paste it into WhatsApp or SMS.');
      }
    } catch (error) {
      if (mounted) {
        _message('$error');
      }
    }
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
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClientVisitColors.green,
                  side: const BorderSide(
                    color: ClientVisitColors.green,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _working ? null : () => _review('approve'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Approve',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClientVisitColors.red,
                  side: const BorderSide(
                    color: ClientVisitColors.red,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _working ? null : () => _review('reject'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text(
                  'Reject',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClientVisitColors.orange,
                  side: const BorderSide(
                    color: ClientVisitColors.orange,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _working ? null : () => _review('changes'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Request changes',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
              origin:
                  _visit != null &&
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
            Text(
              'Within Client Location',
              style: TextStyle(
                color: ClientVisitColors.green,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.contactPerson,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        visit.contactPhone,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
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
            _captureTiles(selfieOptional: true),
            const SizedBox(height: 10),
            const Text(
              'GPS is required. Add a selfie only when the client agrees.',
              textAlign: TextAlign.center,
            ),
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
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Attendees (${_attendees.length})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (!widget.readOnlyMode)
                  TextButton.icon(
                    onPressed: () async {
                      final ctrl = TextEditingController();
                      final name = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Add Attendee'),
                          content: TextField(
                            controller: ctrl,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, ctrl.text.trim()),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                      if (name != null && name.isNotEmpty)
                        setState(() => _attendees.add(name));
                    },
                    icon: const Icon(Icons.person_add, size: 14),
                    label: const Text('+ Add', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
              ],
            ),
            if (_attendees.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _attendees
                    .map(
                      (name) => Chip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        onDeleted: widget.readOnlyMode
                            ? null
                            : () => setState(() => _attendees.remove(name)),
                      ),
                    )
                    .toList(),
              ),
            const Divider(height: 20),
            // Checklist with progress bar
            Row(
              children: [
                const Icon(Icons.checklist_rounded, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Checklist',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${_checklist.where((i) => i['done'] == true).length}/${_checklist.length} Completed',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _checklist.isEmpty
                    ? 0
                    : _checklist.where((i) => i['done'] == true).length /
                          _checklist.length,
                backgroundColor: Colors.grey.shade200,
                color: ClientVisitColors.green,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            ..._checklist.asMap().entries.map(
              (entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: entry.value['done'] == true,
                title: Text(
                  '${entry.value['label']}',
                  style: const TextStyle(fontSize: 13),
                ),
                onChanged: widget.readOnlyMode
                    ? null
                    : (value) => setState(
                        () => _checklist[entry.key]['done'] = value == true,
                      ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (!widget.readOnlyMode) ...[
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _push(
                  ClientVisitWorkUpdateScreen(
                    userId: widget.userId,
                    visitId: widget.visitId,
                    service: widget.service,
                  ),
                ),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Add Update'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final images = await ImagePicker().pickMultiImage(
                    imageQuality: 82,
                  );
                  if (images.isNotEmpty && mounted) {
                    await _run(
                      () => widget.service.uploadFiles(
                        widget.userId,
                        widget.visitId,
                        'proof',
                        images.map((i) => i.path).toList(),
                      ),
                    );
                    _message('Proof uploaded.');
                  }
                },
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Proof'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _flowButton(
          Icons.receipt_long,
          'Expense claim',
          () => _push(
            ClientVisitExpenseScreen(
              userId: widget.userId,
              visitId: widget.visitId,
              service: widget.service,
            ),
          ),
        ),
        _flowButton(
          Icons.logout,
          'Return / direct checkout',
          () => _push(
            ClientVisitReturnCheckoutScreen(
              userId: widget.userId,
              visitId: widget.visitId,
              service: widget.service,
            ),
          ),
        ),
      ] else
        _monitoringNotice(),
    ],
    9 => [
      EmployeeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Attendees ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _attendee,
                    readOnly: widget.readOnlyMode,
                    decoration: const InputDecoration(
                      labelText: 'Attendee name',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: widget.readOnlyMode
                      ? null
                      : () {
                          if (_attendee.text.trim().isNotEmpty) {
                            setState(() {
                              _attendees.add(_attendee.text.trim());
                              _attendee.clear();
                            });
                          }
                        },
                ),
              ],
            ),
            if (_attendees.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _attendees
                    .map(
                      (name) => Chip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        onDeleted: widget.readOnlyMode
                            ? null
                            : () => setState(() => _attendees.remove(name)),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Checklist ──────────────────────────────────────────────────
            ..._checklist.asMap().entries.map(
              (entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: entry.value['done'] == true,
                title: Text(
                  '${entry.value['label']}',
                  style: const TextStyle(fontSize: 13),
                ),
                onChanged: widget.readOnlyMode
                    ? null
                    : (v) => setState(
                        () => _checklist[entry.key]['done'] = v == true,
                      ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Notes ──────────────────────────────────────────────────────
            TextField(
              controller: _notes,
              readOnly: widget.readOnlyMode,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes / outcome'),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Photos / Documents ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Photos / Documents (${_stagedProofPaths.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (!widget.readOnlyMode)
                  TextButton.icon(
                    onPressed: () async {
                      final images = await ImagePicker().pickMultiImage(
                        imageQuality: 82,
                      );
                      if (images.isNotEmpty) {
                        setState(
                          () => _stagedProofPaths.addAll(
                            images.map((i) => i.path),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 16,
                    ),
                    label: const Text('+ Add', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
              ],
            ),
            if (_stagedProofPaths.isNotEmpty) ...[
              const SizedBox(height: 8),
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
                        child: Image.file(
                          File(_stagedProofPaths[i]),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.insert_drive_file),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _stagedProofPaths.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Outcome ────────────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _outcome9.isEmpty ? null : _outcome9,
              decoration: const InputDecoration(labelText: 'Outcome'),
              items: const [
                'Positive',
                'Negative',
                'Neutral',
                'Follow-up Required',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: widget.readOnlyMode
                  ? null
                  : (v) => setState(() => _outcome9 = v ?? ''),
            ),

            const SizedBox(height: 12),

            // ── Follow-up ──────────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _followUp9.isEmpty ? null : _followUp9,
              decoration: const InputDecoration(labelText: 'Follow-up'),
              items: const [
                'None',
                'Call tomorrow',
                'Send proposal by next week',
                'Schedule demo',
                'Awaiting client feedback',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: widget.readOnlyMode
                  ? null
                  : (v) => setState(() => _followUp9 = v ?? ''),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Client Signature (hand-drawn pad) ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Client Signature',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (!widget.readOnlyMode)
                  TextButton.icon(
                    onPressed: _signaturePadController.isEmpty
                        ? null
                        : () => setState(() => _signaturePadController.clear()),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      foregroundColor: _signaturePadController.isEmpty
                          ? Colors.grey
                          : Colors.redAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Instruction hint
            Text(
              widget.readOnlyMode
                  ? 'Signature captured'
                  : 'Ask the client to sign in the box below',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            // Signature canvas
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.readOnlyMode
                  ? Center(
                      child: Text(
                        '—',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : Signature(
                      controller: _signaturePadController,
                      backgroundColor: Colors.white,
                      width: double.infinity,
                      height: 140,
                    ),
            ),
            // "Sign here" watermark hint
            if (!widget.readOnlyMode && _signaturePadController.isEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gesture_rounded,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Draw signature above',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // ── Save button ────────────────────────────────────────────────
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
                _expenseItem(
                  'parking',
                  Icons.local_parking_rounded,
                  'Parking / Toll',
                ),
                _expenseItem('other', Icons.more_horiz_rounded, 'Other'),
              ],
              onChanged: widget.readOnlyMode
                  ? null
                  : (v) => setState(() => _expenseCategory = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              readOnly: widget.readOnlyMode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
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
                  'travel' => Icons.directions_car_rounded,
                  'food' => Icons.restaurant_rounded,
                  'parking' => Icons.local_parking_rounded,
                  _ => Icons.more_horiz_rounded,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: const Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _label(cat),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '₹${expense['amount']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    '₹${visit.expenseTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!widget.readOnlyMode)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _working ? null : _submitExpense,
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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Duty completion',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: 'return_office',
              groupValue: _returnMode,
              title: const Text('Return to Office'),
              subtitle: const Text(
                'End of Office',
                style: TextStyle(fontSize: 11),
              ),
              onChanged: widget.readOnlyMode
                  ? null
                  : (v) => setState(() => _returnMode = v!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: 'end_duty_client',
              groupValue: _returnMode,
              title: const Text('End Duty from Client'),
              subtitle: const Text('No Return', style: TextStyle(fontSize: 11)),
              onChanged: widget.readOnlyMode
                  ? null
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
            const SizedBox(height: 12),
            TextField(
              controller: _followUp,
              readOnly: widget.readOnlyMode,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Follow-up'),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Client Signature (hand-drawn pad) ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Client Signature',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (!widget.readOnlyMode)
                  TextButton.icon(
                    onPressed: _signaturePadController.isEmpty
                        ? null
                        : () => setState(() => _signaturePadController.clear()),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      foregroundColor: _signaturePadController.isEmpty
                          ? Colors.grey
                          : Colors.redAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.readOnlyMode
                  ? 'Signature captured'
                  : 'Ask the client to sign in the box below',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            // Signature canvas
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.readOnlyMode
                  ? Center(
                      child: Text(
                        '—',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : Signature(
                      controller: _signaturePadController,
                      backgroundColor: Colors.white,
                      width: double.infinity,
                      height: 140,
                    ),
            ),
            if (!widget.readOnlyMode && _signaturePadController.isEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gesture_rounded,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Draw signature above',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],

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

      // ── Travel route map (if GPS route was recorded) ──────────────
      if (visit.travelRoute.isNotEmpty ||
          (visit.officeCheckOutLatitude != null &&
              visit.officeCheckOutLongitude != null &&
              (visit.reachedClientLatitude != null ||
                  visit.clientLatitude != null))) ...[
        _saSection(
          icon: Icons.route_rounded,
          color: const Color(0xFF9333EA),
          title: 'Travel Route',
          child: _RouteMapCard(visit: visit),
        ),
        const SizedBox(height: 12),
      ],

      // ── Visit timeline ────────────────────────────────────────────
      _timeline(visit),
      const SizedBox(height: 12),

      // ── Client & visit details ────────────────────────────────────
      _saSection(
        icon: Icons.business_rounded,
        color: const Color(0xFF16A34A),
        title: 'Client Details',
        child: Column(
          children: [
            EmployeeInfoRow('Client', visit.clientName),
            EmployeeInfoRow(
              'Contact',
              visit.contactPerson.isEmpty ? '—' : visit.contactPerson,
            ),
            EmployeeInfoRow(
              'Phone',
              visit.contactPhone.isEmpty ? '—' : visit.contactPhone,
            ),
            EmployeeInfoRow(
              'Address',
              visit.address.isEmpty ? '—' : visit.address,
            ),
            EmployeeInfoRow(
              'Purpose',
              visit.purpose.isEmpty ? '—' : visit.purpose,
            ),
            EmployeeInfoRow('Travel Mode', _label(visit.travelMode)),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ── Summary (outcome, follow-up, return mode) ─────────────────
      _summary(visit),
      const SizedBox(height: 12),

      // ── Expenses ──────────────────────────────────────────────────
      if (visit.expenses.isNotEmpty) ...[
        _saSection(
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFEF4444),
          title: 'Expenses',
          child: Column(
            children: [
              ...visit.expenses.map((expense) {
                final cat = '${expense['category']}';
                final icon = switch (cat) {
                  'travel' => Icons.directions_car_rounded,
                  'food' => Icons.restaurant_rounded,
                  'parking' => Icons.local_parking_rounded,
                  _ => Icons.receipt_rounded,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: 15,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _label(cat),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if ('${expense['note'] ?? ''}'.isNotEmpty)
                              Text(
                                '${expense['note']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${expense['amount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    '₹${visit.expenseTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── Checklist ─────────────────────────────────────────────────
      if (visit.checklist.isNotEmpty) ...[
        _saSection(
          icon: Icons.checklist_rounded,
          color: const Color(0xFF34A853),
          title: 'Checklist',
          child: Column(
            children: visit.checklist.map((item) {
              final done = item['done'] == true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: done
                          ? const Color(0xFF34A853)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item['label'] ?? ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: done ? null : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── Attendees ─────────────────────────────────────────────────
      if (visit.attendees.isNotEmpty) ...[
        _saSection(
          icon: Icons.group_rounded,
          color: const Color(0xFF1A73E8),
          title: 'Attendees (${visit.attendees.length})',
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: visit.attendees
                .map(
                  (a) => Chip(
                    avatar: const Icon(Icons.person_rounded, size: 14),
                    label: Text('$a', style: const TextStyle(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── Attachments: selfies + signatures + proof + docs ──────────
      if (visit.attachments.isNotEmpty) ...[
        _attachmentsGallery(visit),
        const SizedBox(height: 12),
      ],

      // ── Action buttons ────────────────────────────────────────────
      Row(
        children: [
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
        ],
      ),
      if (widget.reviewerMode && visit.managerVerifiedBy.isEmpty) ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _working ? null : _verify,
            icon: const Icon(Icons.verified),
            label: const Text('Verify completed visit'),
          ),
        ),
      ],
    ],
    _ =>
      (widget.reviewerMode || widget.readOnlyMode)
          ? _superAdminVisitDetail(visit)
          : [_visitInfo(visit)],
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

  Widget _captureTiles({bool selfieOptional = false}) {
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
            title: selfieOptional ? 'Selfie (optional)' : 'Selfie',
            subtitle: _capturingSelfie
                ? 'Opening camera...'
                : _selfiePath == null
                ? (selfieOptional ? 'With client consent' : 'Tap to capture')
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

  Widget _stepHeader(ClientVisit visit) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF1A73E8).withAlpha(15),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF1A73E8).withAlpha(30)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                visit.clientName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ThemeConfig.getTextPrimary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
        _statusChip(visit.status),
      ],
    ),
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
                      Text(
                        visit.employeeName.isEmpty
                            ? visit.employeeUserId
                            : visit.employeeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        visit.employeeUserId,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
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
        EmployeeInfoRow(
          'Phone',
          visit.contactPhone.isEmpty ? '—' : visit.contactPhone,
        ),
        EmployeeInfoRow('Address', visit.address),
        EmployeeInfoRow(
          'Date & Time',
          '${_date(visit.scheduledAt)}  ${TimeOfDay.fromDateTime(visit.scheduledAt).format(context)}',
        ),
        EmployeeInfoRow(
          'Duration',
          visit.durationMinutes < 60
              ? '${visit.durationMinutes} minutes'
              : '${visit.durationMinutes ~/ 60} hour${visit.durationMinutes == 60 ? '' : 's'}',
        ),
        EmployeeInfoRow('Purpose', visit.purpose),
        EmployeeInfoRow('Travel mode', _label(visit.travelMode)),
        if (visit.notes.isNotEmpty) EmployeeInfoRow('Notes', visit.notes),
      ],
    ),
  );

  // ── SuperAdmin / Reviewer full-detail view ─────────────────────────────────
  /// Returns all widgets shown when SuperAdmin/TL taps any visit from history
  /// or monitoring. Shows: status, employee, client, approval, timeline,
  /// LIVE MAP (active) or ROUTE MAP (completed), outcome, expenses, checklist,
  /// attendees, and all attachments (selfies + signature + proof + docs).
  List<Widget> _superAdminVisitDetail(ClientVisit visit) {
    Color statusColor(String s) => switch (s) {
      'completed' => ClientVisitColors.green,
      'in_progress' => const Color(0xFF34A853),
      'travelling' => const Color(0xFF1A73E8),
      'approved' => const Color(0xFF16A34A),
      'pending' => const Color(0xFFF59E0B),
      'rejected' => const Color(0xFFEF4444),
      _ => Colors.grey,
    };

    final isActive =
        visit.status == 'travelling' || visit.status == 'in_progress';
    final hasRoute =
        visit.travelRoute.isNotEmpty ||
        (visit.officeCheckOutLatitude != null &&
            visit.officeCheckOutLongitude != null &&
            (visit.reachedClientLatitude != null ||
                visit.clientLatitude != null));
    final hasCompleted = visit.status == 'completed';

    return [
      // ── 1. Status badge ───────────────────────────────────────────
      _stageBadge(
        _label(visit.status).toUpperCase(),
        statusColor(visit.status),
      ),
      const SizedBox(height: 14),

      // ── 2. LIVE MAP (travelling/in_progress) ──────────────────────
      if (isActive) ...[
        _saSection(
          icon: Icons.gps_fixed_rounded,
          color: const Color(0xFF1A73E8),
          title: 'Live Location',
          child: _ReviewerLiveMap(
            visitId: visit.id,
            userId: widget.userId,
            service: widget.service,
            visit: visit,
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── 3. ROUTE MAP (completed visit with stored GPS route) ──────
      if (hasCompleted && hasRoute) ...[
        _saSection(
          icon: Icons.route_rounded,
          color: const Color(0xFF9333EA),
          title: 'Travel Route',
          child: _RouteMapCard(visit: visit),
        ),
        const SizedBox(height: 12),
      ],

      // ── 4. Employee card ──────────────────────────────────────────
      _saSection(
        icon: Icons.badge_outlined,
        color: const Color(0xFF1A73E8),
        title: 'Employee',
        child: Column(
          children: [
            Row(
              children: [
                _employeeAvatar(visit),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.employeeName.isEmpty
                            ? visit.employeeUserId
                            : visit.employeeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        visit.employeeUserId,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),
            EmployeeInfoRow(
              'Manager ID',
              visit.managerUserId.isEmpty ? '—' : visit.managerUserId,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ── 5. Client Details ─────────────────────────────────────────
      _saSection(
        icon: Icons.business_rounded,
        color: const Color(0xFF16A34A),
        title: 'Client Details',
        child: Column(
          children: [
            EmployeeInfoRow('Client Name', visit.clientName),
            EmployeeInfoRow(
              'Contact Person',
              visit.contactPerson.isEmpty ? '—' : visit.contactPerson,
            ),
            EmployeeInfoRow(
              'Phone',
              visit.contactPhone.isEmpty ? '—' : visit.contactPhone,
            ),
            EmployeeInfoRow(
              'Address',
              visit.address.isEmpty ? '—' : visit.address,
            ),
            EmployeeInfoRow(
              'Purpose',
              visit.purpose.isEmpty ? '—' : visit.purpose,
            ),
            EmployeeInfoRow(
              'Scheduled',
              '${_date(visit.scheduledAt)}  ${TimeOfDay.fromDateTime(visit.scheduledAt).format(context)}',
            ),
            EmployeeInfoRow(
              'Planned Duration',
              visit.durationMinutes < 60
                  ? '${visit.durationMinutes} min'
                  : '${visit.durationMinutes ~/ 60}h'
                        '${visit.durationMinutes % 60 > 0 ? ' ${visit.durationMinutes % 60}m' : ''}',
            ),
            EmployeeInfoRow('Travel Mode', _label(visit.travelMode)),
            if (visit.notes.isNotEmpty) EmployeeInfoRow('Notes', visit.notes),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ── 6. Approval ───────────────────────────────────────────────
      _saSection(
        icon: Icons.approval_rounded,
        color: const Color(0xFF9333EA),
        title: 'Approval',
        child: Column(
          children: [
            EmployeeInfoRow('Status', _label(visit.status)),
            EmployeeInfoRow(
              'Approved By',
              visit.approvedByName.isEmpty
                  ? '—'
                  : '${visit.approvedByName} (${visit.approvedByRole})',
            ),
            EmployeeInfoRow(
              'Approved At',
              visit.approvedAt == null
                  ? '—'
                  : '${_date(visit.approvedAt!)}  '
                        '${TimeOfDay.fromDateTime(visit.approvedAt!.toLocal()).format(context)}',
            ),
            if (visit.approvalComment.isNotEmpty)
              EmployeeInfoRow('Comment', visit.approvalComment),
            EmployeeInfoRow(
              'Manager Verification',
              visit.managerVerifiedBy.isEmpty
                  ? 'Pending'
                  : '✓ Verified by ${visit.managerVerifiedBy}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ── 7. Visit Timeline ─────────────────────────────────────────
      _saSection(
        icon: Icons.timeline_rounded,
        color: const Color(0xFF0EA5E9),
        title: 'Visit Timeline',
        child: Column(
          children: [
            _timeRow('Office Check-Out', visit.officeCheckOutAt),
            _timeRow('Reached Client', visit.reachedClientAt),
            _timeRow('Visit Start', visit.checkInAt),
            _timeRow('Visit End / Checkout', visit.checkOutAt),
            if (visit.officeCheckOutAt != null || visit.checkOutAt != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  _durationBox(
                    'Travel',
                    visit.officeCheckOutAt != null &&
                            visit.reachedClientAt != null
                        ? _duration(
                            visit.reachedClientAt!.toLocal().difference(
                              visit.officeCheckOutAt!.toLocal(),
                            ),
                          )
                        : '—',
                  ),
                  _durationBox(
                    'Visit',
                    visit.checkInAt != null && visit.checkOutAt != null
                        ? _duration(
                            visit.checkOutAt!.toLocal().difference(
                              visit.checkInAt!.toLocal(),
                            ),
                          )
                        : '—',
                  ),
                  _durationBox(
                    'Total Duty',
                    visit.officeCheckOutAt != null && visit.checkOutAt != null
                        ? _duration(
                            visit.checkOutAt!.toLocal().difference(
                              visit.officeCheckOutAt!.toLocal(),
                            ),
                          )
                        : '—',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ── 8. Outcome & Follow-Up ────────────────────────────────────
      if (visit.outcome.isNotEmpty ||
          visit.followUp.isNotEmpty ||
          visit.returnMode.isNotEmpty) ...[
        _saSection(
          icon: Icons.description_rounded,
          color: const Color(0xFFF59E0B),
          title: 'Outcome & Follow-Up',
          child: Column(
            children: [
              EmployeeInfoRow(
                'Outcome',
                visit.outcome.isEmpty ? '—' : visit.outcome,
              ),
              EmployeeInfoRow(
                'Follow-Up',
                visit.followUp.isEmpty ? '—' : visit.followUp,
              ),
              EmployeeInfoRow('Return Mode', _label(visit.returnMode)),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── 9. Expenses ───────────────────────────────────────────────
      if (visit.expenses.isNotEmpty || visit.expenseTotal > 0) ...[
        _saSection(
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFEF4444),
          title: 'Expenses',
          child: Column(
            children: [
              ...visit.expenses.map((expense) {
                final cat = '${expense['category']}';
                final icon = switch (cat) {
                  'travel' => Icons.directions_car_rounded,
                  'food' => Icons.restaurant_rounded,
                  'parking' => Icons.local_parking_rounded,
                  'expense' => Icons.receipt_rounded,
                  _ => Icons.more_horiz_rounded,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _label(cat),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if ('${expense['note'] ?? ''}'.isNotEmpty)
                              Text(
                                '${expense['note']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${expense['amount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    '₹${visit.expenseTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── 10. Checklist ─────────────────────────────────────────────
      if (visit.checklist.isNotEmpty) ...[
        _saSection(
          icon: Icons.checklist_rounded,
          color: const Color(0xFF34A853),
          title: 'Checklist',
          child: Column(
            children: visit.checklist.map((item) {
              final done = item['done'] == true;
              final label = '${item['label'] ?? ''}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: done
                          ? const Color(0xFF34A853)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: done ? null : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── 11. Attendees ─────────────────────────────────────────────
      if (visit.attendees.isNotEmpty) ...[
        _saSection(
          icon: Icons.group_rounded,
          color: const Color(0xFF1A73E8),
          title: 'Attendees (${visit.attendees.length})',
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: visit.attendees
                .map(
                  (a) => Chip(
                    avatar: const Icon(Icons.person_rounded, size: 14),
                    label: Text('$a', style: const TextStyle(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── 12. Attachments — selfies, signature, proof, docs ─────────
      if (visit.attachments.isNotEmpty) ...[
        _attachmentsGallery(visit),
        const SizedBox(height: 12),
      ],

      // ── 13. Verify button ─────────────────────────────────────────
      if (widget.reviewerMode &&
          visit.managerVerifiedBy.isEmpty &&
          visit.status == 'completed') ...[
        FilledButton.icon(
          onPressed: _working ? null : _verify,
          icon: const Icon(Icons.verified),
          label: const Text('Verify completed visit'),
        ),
        const SizedBox(height: 8),
      ],

      // ── 14. Download report ───────────────────────────────────────
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _working ? null : () => _downloadReport(visit),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download Report'),
        ),
      ),
    ];
  }

  /// Card wrapper for each SuperAdmin detail section.
  Widget _saSection({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return EmployeeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _employeeAvatar(ClientVisit visit) {
    final hasPhoto = visit.employeePhotoUrl.isNotEmpty;
    final name = visit.employeeName;
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A73E8).withAlpha(20),
        border: Border.all(
          color: const Color(0xFF1A73E8).withAlpha(60),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              visit.employeePhotoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A73E8),
                ),
              ),
            ),
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
        visit.reachedClientAt!.toLocal().difference(
          visit.officeCheckOutAt!.toLocal(),
        ),
      );
    }
    if (visit.checkInAt != null && visit.checkOutAt != null) {
      visitDuration = _duration(
        visit.checkOutAt!.toLocal().difference(visit.checkInAt!.toLocal()),
      );
    }
    if (visit.officeCheckOutAt != null && visit.checkOutAt != null) {
      totalDuty = _duration(
        visit.checkOutAt!.toLocal().difference(
          visit.officeCheckOutAt!.toLocal(),
        ),
      );
    }
    final proofCount = visit.attachments
        .where(
          (a) => a['category'] == 'proof' || a['category'] == 'client_check_in',
        )
        .length;

    return EmployeeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visit timeline',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _timeRow('Office Check-Out', visit.officeCheckOutAt),
          _timeRow('Reached Client', visit.reachedClientAt),
          _timeRow('Visit Start', visit.checkInAt),
          _timeRow('Visit End', visit.checkOutAt),
          _timeRow('Return / Checkout', visit.checkOutAt),
          const Divider(height: 16),
          // Duration metrics row
          Row(
            children: [
              _durationBox('Travel\nDuration', travelDuration),
              _durationBox('Visit\nDuration', visitDuration),
              _durationBox('Total Duty', totalDuty),
            ],
          ),
          const Divider(height: 16),
          // Expenses + Proof
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expenses',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '₹${visit.expenseTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proof Uploaded',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '$proofCount file${proofCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          // Manager verification
          Row(
            children: [
              Icon(
                visit.managerVerifiedBy.isEmpty
                    ? Icons.pending_outlined
                    : Icons.verified_rounded,
                size: 16,
                color: visit.managerVerifiedBy.isEmpty
                    ? Colors.orange
                    : ClientVisitColors.green,
              ),
              const SizedBox(width: 6),
              Text(
                'Manager Verification: ',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                visit.managerVerifiedBy.isEmpty ? 'Pending' : '✓ Verified',
                style: TextStyle(
                  fontSize: 12,
                  color: visit.managerVerifiedBy.isEmpty
                      ? Colors.orange
                      : ClientVisitColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _durationBox(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          textAlign: TextAlign.center,
        ),
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

  /// Gallery of all uploaded attachments — shown on the completed stage (12)
  /// Grouped photos gallery — shown on the completed stage (12) for every
  /// role including SuperAdmin and reviewers.
  ///
  /// Selfie categories (office_checkout, client_check_in, checkout, check_in)
  /// are displayed prominently in a dedicated "Selfies" section so SuperAdmin
  /// can clearly see the employee at each stage of the visit.
  /// Proof / expense / other files are shown in a separate "Proof & Documents"
  /// section below.
  Widget _attachmentsGallery(ClientVisit visit) {
    const selfieCategories = {
      'office_checkout',
      'client_check_in',
      'checkout',
      'check_in',
    };

    // Category display meta
    String _catLabel(String cat) => switch (cat) {
      'office_checkout' => 'Office Checkout',
      'client_check_in' => 'Client Check-In',
      'checkout' => 'Return Checkout',
      'check_in' => 'Check-In',
      'proof' => 'Visit Proof',
      'expense' => 'Expense Receipt',
      _ => cat.replaceAll('_', ' '),
    };

    IconData _catIcon(String cat) => switch (cat) {
      'office_checkout' => Icons.login_rounded,
      'client_check_in' => Icons.location_on_rounded,
      'checkout' => Icons.logout_rounded,
      'check_in' => Icons.camera_front_rounded,
      'proof' => Icons.photo_library_rounded,
      'expense' => Icons.receipt_rounded,
      _ => Icons.attach_file_rounded,
    };

    Color _catColor(String cat) => switch (cat) {
      'office_checkout' => const Color(0xFF1A73E8),
      'client_check_in' => const Color(0xFF16A34A),
      'checkout' => const Color(0xFF9333EA),
      'check_in' => const Color(0xFF0EA5E9),
      'proof' => const Color(0xFFF59E0B),
      'expense' => const Color(0xFFEF4444),
      _ => const Color(0xFF64748B),
    };

    final selfies = visit.attachments
        .where((a) => selfieCategories.contains('${a['category']}'))
        .toList();
    // Separate client signatures (proof files with 'signature' in the name)
    final signatures = visit.attachments
        .where(
          (a) =>
              !selfieCategories.contains('${a['category']}') &&
              '${a['category']}' == 'proof' &&
              '${a['original_name'] ?? a['public_id'] ?? ''}'
                  .toLowerCase()
                  .contains('signature'),
        )
        .toList();
    final others = visit.attachments
        .where(
          (a) =>
              !selfieCategories.contains('${a['category']}') &&
              !signatures.contains(a),
        )
        .toList();

    // ── Full-screen viewer ────────────────────────────────────────────────────
    void openViewer(
      BuildContext ctx,
      List<Map<String, dynamic>> items,
      int start,
    ) {
      final pageCtrl = PageController(initialPage: start);
      showDialog(
        context: ctx,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                controller: pageCtrl,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final url = '${item['url'] ?? ''}';
                  final isImg = item['resource_type'] != 'raw';
                  final cat = '${item['category'] ?? ''}';
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: InteractiveViewer(
                          child: isImg && url.isNotEmpty
                              ? Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.insert_drive_file_rounded,
                                    color: Colors.white,
                                    size: 64,
                                  ),
                                ),
                        ),
                      ),
                      // caption
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: Text(
                          _catLabel(cat),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Close
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
              // Page indicator
              if (items.length > 1)
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: pageCtrl,
                      builder: (_, __) {
                        final page = pageCtrl.hasClients
                            ? (pageCtrl.page?.round() ?? start)
                            : start;
                        return Text(
                          '${page + 1} / ${items.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // ── Single photo tile ─────────────────────────────────────────────────────
    Widget photoTile(
      BuildContext ctx,
      Map<String, dynamic> item,
      List<Map<String, dynamic>> group,
      int indexInGroup, {
      double size = 110,
    }) {
      final url = '${item['url'] ?? ''}';
      final cat = '${item['category'] ?? ''}';
      final isImg = item['resource_type'] != 'raw';
      final color = _catColor(cat);
      final icon = _catIcon(cat);

      return GestureDetector(
        onTap: () => openViewer(ctx, group, indexInGroup),
        child: Container(
          width: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(80), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Image / placeholder
              if (isImg && url.isNotEmpty)
                Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _attachPlaceholder(size, icon, color),
                )
              else
                _attachPlaceholder(size, icon, color),

              // Category label strip at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(200), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _catLabel(cat),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Zoom hint icon (top-right corner)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.zoom_in_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Section builder ───────────────────────────────────────────────────────
    Widget section(
      BuildContext ctx,
      String title,
      IconData headerIcon,
      Color headerColor,
      List<Map<String, dynamic>> items, {
      double tileSize = 110,
    }) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: headerColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(headerIcon, size: 14, color: headerColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${items.length})',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Horizontal scroll row of tiles
          SizedBox(
            height: tileSize + 4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx2, i) =>
                  photoTile(ctx2, items[i], items, i, size: tileSize),
            ),
          ),
        ],
      );
    }

    return Builder(
      builder: (ctx) => EmployeeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                const Icon(Icons.photo_library_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Visit Photos & Documents',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '${visit.attachments.length} file${visit.attachments.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            // ── Selfies section ──
            if (selfies.isNotEmpty) ...[
              const SizedBox(height: 14),
              section(
                ctx,
                'Selfies',
                Icons.camera_front_rounded,
                const Color(0xFF1A73E8),
                selfies,
                tileSize: 120,
              ),
            ],

            // ── Client Signatures section ──
            if (signatures.isNotEmpty) ...[
              const SizedBox(height: 16),
              section(
                ctx,
                'Client Signatures',
                Icons.gesture_rounded,
                const Color(0xFF9333EA),
                signatures,
                tileSize: 110,
              ),
            ],

            // ── Proof & documents section ──
            if (others.isNotEmpty) ...[
              const SizedBox(height: 16),
              section(
                ctx,
                'Proof & Documents',
                Icons.photo_library_rounded,
                const Color(0xFFF59E0B),
                others,
                tileSize: 100,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Placeholder shown when an image fails or the file is not an image.
  Widget _attachPlaceholder(double size, IconData icon, Color color) =>
      Container(
        width: size,
        height: size,
        color: color.withAlpha(18),
        child: Center(
          child: Icon(icon, size: size * 0.35, color: color.withAlpha(160)),
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

// ── Reviewer Live Map ─────────────────────────────────────────────────────────
/// Shown in _superAdminVisitDetail for travelling/in_progress visits.
/// Polls fetchVisit every 10 seconds to get the latest GPS route points
/// and renders them on the existing _LiveMapView widget.
class _ReviewerLiveMap extends StatefulWidget {
  final int visitId;
  final String userId;
  final ClientVisitService service;
  final ClientVisit visit;
  const _ReviewerLiveMap({
    required this.visitId,
    required this.userId,
    required this.service,
    required this.visit,
  });
  @override
  State<_ReviewerLiveMap> createState() => _ReviewerLiveMapState();
}

class _ReviewerLiveMapState extends State<_ReviewerLiveMap> {
  final MapController _mapController = MapController();
  Timer? _pollTimer;
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  LatLng? _destination;
  String? _error;
  DateTime? _lastUpdatedAt;
  bool _reachedClient = false;
  int _lastFittedPointCount = -1;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _buildRouteFromVisit(widget.visit, notify: false);
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _buildRouteFromVisit(ClientVisit visit, {bool notify = true}) {
    final points = visit.travelRoute
        .map((p) {
          final lat = double.tryParse('${p['latitude'] ?? p['lat'] ?? ''}');
          final lng = double.tryParse('${p['longitude'] ?? p['lng'] ?? ''}');
          if (lat != null && lng != null) return LatLng(lat, lng);
          return null;
        })
        .whereType<LatLng>()
        .toList();

    LatLng? current;
    if (points.isNotEmpty) current = points.last;

    final reachedLat = visit.reachedClientLatitude;
    final reachedLng = visit.reachedClientLongitude;
    if (visit.reachedClientAt != null &&
        reachedLat != null &&
        reachedLng != null &&
        reachedLat != 0.0 &&
        reachedLng != 0.0) {
      current = LatLng(reachedLat, reachedLng);
    }

    final destLat = visit.clientLatitude;
    final destLng = visit.clientLongitude;
    final dest =
        (destLat != null && destLng != null && destLat != 0.0 && destLng != 0.0)
        ? LatLng(destLat, destLng)
        : null;

    if (!mounted) return;
    void applyUpdate() {
      _routePoints = points;
      _currentPosition = current;
      _destination = dest;
      _lastUpdatedAt = DateTime.now();
      _reachedClient = visit.reachedClientAt != null;
      _error = null;
    }

    if (notify) {
      setState(applyUpdate);
    } else {
      applyUpdate();
    }
    if (_lastFittedPointCount != points.length) {
      _lastFittedPointCount = points.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRouteOverview());
    }
  }

  void _fitRouteOverview() {
    if (!mounted) return;
    final points = <LatLng>[
      if (_currentPosition != null) _currentPosition!,
      if (_destination != null) _destination!,
    ];
    try {
      _mapController.rotate(0);
      if (points.length >= 2) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(34),
            maxZoom: 16,
          ),
        );
      } else if (points.length == 1) {
        _mapController.move(points.first, 16);
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_polling) return;
      _polling = true;
      try {
        final updated = await widget.service.fetchVisit(
          widget.userId,
          widget.visitId,
        );
        if (mounted) _buildRouteFromVisit(updated);
      } catch (_) {
        // Silently ignore poll errors — show stale data
      } finally {
        _polling = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lastUpdated = _lastUpdatedAt == null
        ? '—'
        : TimeOfDay.fromDateTime(_lastUpdatedAt!).format(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status row
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _reachedClient
                    ? const Color(0xFF34A853)
                    : const Color(0xFFEA4335),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _reachedClient ? 'ARRIVED · LIVE ROUTE' : 'LIVE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _reachedClient
                    ? const Color(0xFF34A853)
                    : const Color(0xFFEA4335),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _routePoints.isEmpty
                    ? 'Waiting for GPS…'
                    : _reachedClient
                    ? 'Arrival confirmed · Updated $lastUpdated'
                    : 'Employee location · Updated $lastUpdated',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(width: 6),
            if (_routePoints.isNotEmpty)
              GestureDetector(
                onTap: _fitRouteOverview,
                child: const Icon(
                  Icons.route_rounded,
                  size: 16,
                  color: Color(0xFF1A73E8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 300,
            child: _routePoints.isEmpty && _destination == null
                ? Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text(
                            'Waiting for employee location…',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : _LiveMapView(
                    mapController: _mapController,
                    routePoints: _routePoints,
                    origin: _routePoints.isNotEmpty ? _routePoints.first : null,
                    current: _currentPosition,
                    destination: _destination,
                    fullScreen: false,
                    showBreadcrumb: false,
                    showMapControls: false,
                    showLiveBadge: false,
                    currentPositionIcon: _reachedClient
                        ? Icons.check_rounded
                        : Icons.delivery_dining_rounded,
                    currentPositionColor: _reachedClient
                        ? const Color(0xFF34A853)
                        : const Color(0xFF1A73E8),
                  ),
          ),
        ),
        // Zomato-style employee status instead of technical coordinates.
        if (_currentPosition != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color:
                  (_reachedClient
                          ? const Color(0xFF34A853)
                          : const Color(0xFF1A73E8))
                      .withAlpha(18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Icon(
                  _reachedClient
                      ? Icons.check_circle_rounded
                      : Icons.delivery_dining_rounded,
                  size: 18,
                  color: _reachedClient
                      ? const Color(0xFF34A853)
                      : const Color(0xFF1A73E8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _reachedClient
                        ? '${widget.visit.employeeName} reached ${widget.visit.clientName}'
                        : '${widget.visit.employeeName} is on the way to ${widget.visit.clientName}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Completed Route Map ───────────────────────────────────────────────────────
/// Shows the stored GPS breadcrumb trail for a completed visit.
class _RouteMapCard extends StatefulWidget {
  final ClientVisit visit;
  const _RouteMapCard({required this.visit});
  @override
  State<_RouteMapCard> createState() => _RouteMapCardState();
}

class _RouteMapCardState extends State<_RouteMapCard> {
  final MapController _mapController = MapController();
  final List<LatLng> _rawPoints = [];
  List<LatLng> _roadPoints = [];
  LatLng? _origin;
  LatLng? _destination;
  bool _loadingRoute = true;
  String _routeSummary = '';

  @override
  void initState() {
    super.initState();
    _rawPoints.addAll(
      widget.visit.travelRoute
          .map((p) {
            final lat = double.tryParse('${p['latitude'] ?? p['lat'] ?? ''}');
            final lng = double.tryParse('${p['longitude'] ?? p['lng'] ?? ''}');
            return _validPoint(lat, lng);
          })
          .whereType<LatLng>()
          .toList(),
    );

    _origin =
        _validPoint(
          widget.visit.officeCheckOutLatitude,
          widget.visit.officeCheckOutLongitude,
        ) ??
        (_rawPoints.isNotEmpty ? _rawPoints.first : null);
    _destination =
        _validPoint(
          widget.visit.reachedClientLatitude,
          widget.visit.reachedClientLongitude,
        ) ??
        _validPoint(
          widget.visit.clientLatitude,
          widget.visit.clientLongitude,
        ) ??
        (_rawPoints.isNotEmpty ? _rawPoints.last : null);

    if (_origin != null && _destination != null) {
      _roadPoints = [_origin!, _destination!];
      unawaited(_loadRoadRoute());
    } else {
      _loadingRoute = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitRoute();
    });
  }

  LatLng? _validPoint(double? lat, double? lng) {
    if (lat == null || lng == null || !lat.isFinite || !lng.isFinite) {
      return null;
    }
    if (lat.abs() > 90 || lng.abs() > 180 || (lat == 0 && lng == 0)) {
      return null;
    }
    return LatLng(lat, lng);
  }

  Future<void> _loadRoadRoute() async {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) return;

    final straightMetres = const Distance().as(
      LengthUnit.Meter,
      origin,
      destination,
    );
    if (straightMetres < 30) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeSummary = 'Arrival confirmed at the client location';
      });
      return;
    }

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await http
          .get(uri, headers: const {'User-Agent': 'BBT-HRMS-Mobile/1.0'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw Exception('Route unavailable');

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) throw Exception('No route found');
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.length < 2) {
        throw Exception('Invalid route geometry');
      }

      final roadPoints = coordinates.map((coordinate) {
        final values = coordinate as List<dynamic>;
        return LatLng(
          (values[1] as num).toDouble(),
          (values[0] as num).toDouble(),
        );
      }).toList();
      final distanceKm = ((route['distance'] as num?)?.toDouble() ?? 0) / 1000;
      final durationMinutes =
          (((route['duration'] as num?)?.toDouble() ?? 0) / 60).round();

      if (!mounted) return;
      setState(() {
        _roadPoints = roadPoints;
        _loadingRoute = false;
        _routeSummary = distanceKm > 0
            ? '${distanceKm.toStringAsFixed(1)} km road route'
                  '${durationMinutes > 0 ? ' · about $durationMinutes min' : ''}'
            : 'Office checkout to client arrival';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeSummary = 'Office checkout to client arrival';
      });
    }
  }

  void _fitRoute() {
    final origin = _origin;
    final destination = _destination;
    if (!mounted || origin == null || destination == null) return;
    try {
      if (const Distance().as(LengthUnit.Meter, origin, destination) < 30) {
        _mapController.move(destination, 16);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([origin, destination]),
            padding: const EdgeInsets.all(38),
            maxZoom: 16,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'No route data recorded.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          children: [
            if (_loadingRoute)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.route_rounded,
                size: 14,
                color: Color(0xFF1A73E8),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _routeSummary.isEmpty
                    ? 'Preparing road route...'
                    : _routeSummary,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        if (_rawPoints.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '${_rawPoints.length} GPS samples retained for audit',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
        const SizedBox(height: 8),
        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 270,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: origin, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bitbyte.hrms',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _roadPoints,
                      color: Colors.white,
                      strokeWidth: 10,
                    ),
                    Polyline(
                      points: _roadPoints,
                      color: const Color(0xFF1A73E8),
                      strokeWidth: 6,
                    ),
                  ],
                ),
                MarkerLayer(
                  rotate: true,
                  markers: [
                    // Start marker — green
                    Marker(
                      point: origin,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF34A853),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // End marker — red
                    Marker(
                      point: destination,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA4335),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Color(0xFF34A853)),
            const SizedBox(width: 4),
            const Text('Office checkout', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 12),
            const Icon(Icons.circle, size: 10, color: Color(0xFFEA4335)),
            const SizedBox(width: 4),
            const Text('Client arrival', style: TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }
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
    final h = value.inHours.toString().padLeft(2, '0');
    final m = (value.inMinutes % 60).toString().padLeft(2, '0');
    final s = (value.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A73E8).withAlpha(40)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_rounded,
                color: Color(0xFF1A73E8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$h:$m:$s',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A73E8),
                  letterSpacing: 2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Visit Timer',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
  final String via; // e.g. "NH 44 and AH45"
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
  final List<LatLng> routePoints; // actual GPS breadcrumb trail
  final List<LatLng> waypoints;
  final LatLng? origin;
  final LatLng? current;
  final LatLng? destination;
  final bool fullScreen;
  final bool navigationMode;
  final bool showEtaOverlay;
  final Color? currentPositionColor;
  final IconData? currentPositionIcon;
  final bool showBreadcrumb;
  final bool showMapControls;
  final bool showLiveBadge;
  final void Function(String eta, String distance)? onEtaUpdate;
  final void Function(List<_RouteOption> routes, int selectedIndex)?
  onRoutesReady;
  final ValueChanged<double>? onRotationChanged;
  final int selectedRouteIndex;

  const _LiveMapView({
    super.key,
    required this.mapController,
    required this.routePoints,
    this.waypoints = const [],
    this.origin,
    this.current,
    this.destination,
    this.fullScreen = false,
    this.navigationMode = false,
    this.showEtaOverlay = false,
    this.currentPositionColor,
    this.currentPositionIcon,
    this.showBreadcrumb = true,
    this.showMapControls = true,
    this.showLiveBadge = true,
    this.onEtaUpdate,
    this.onRoutesReady,
    this.onRotationChanged,
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
    _pulseAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
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
          if (RegExp(
            r'^(NH|AH|SH|MDR|ODR)\s*\d+',
            caseSensitive: false,
          ).hasMatch(t)) {
            highways.add(t.replaceAll(RegExp(r'\s+'), ' '));
          }
        }
        if (highways.length >= 3) break;
      }
      if (highways.isNotEmpty) return highways.take(2).join(' and ');
    } catch (_) {}
    return 'road';
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
      final coordinates = <LatLng>[
        from,
        ...widget.waypoints,
        to,
      ].map((point) => '${point.longitude},${point.latitude}').join(';');
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$coordinates'
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
              .map(
                (c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              )
              .toList();
          final via = _viaLabel(route);
          return _RouteOption(
            points: coords,
            distanceKm: distM / 1000,
            durationMinutes: (durS / 60).ceil(),
            via: via,
            hasTolls:
                via.toLowerCase().contains('nh') ||
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
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
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
    final x =
        math.cos(lat1) * math.sin(lat2) -
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
    final validDst =
        (dst != null && !(dst.latitude == 0.0 && dst.longitude == 0.0))
        ? dst
        : null;
    return cur ?? validDst ?? widget.origin ?? const LatLng(20.5937, 78.9629);
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.current;
    final dst = widget.destination;
    final validDst =
        (dst != null && !(dst.latitude == 0.0 && dst.longitude == 0.0))
        ? dst
        : null;
    final heading = (cur != null && validDst != null)
        ? _bearing(cur, validDst)
        : 0.0;
    final currentColor =
        widget.currentPositionColor ??
        (widget.navigationMode
            ? const Color(0xFF34A853)
            : const Color(0xFF1A73E8));
    final hasCustomPositionIcon = widget.currentPositionIcon != null;

    final mapStack = Stack(
      children: [
        // ── MAP ──────────────────────────────────────────────────────
        Positioned.fill(
          child: FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (camera, hasGesture) {
                widget.onRotationChanged?.call(camera.rotation);
              },
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.rotate,
                enableMultiFingerGestureRace: true,
                rotationThreshold: 4,
                pinchZoomThreshold: 0.25,
                pinchMoveThreshold: 8,
                rotationWinGestures:
                    MultiFingerGesture.rotate |
                    MultiFingerGesture.pinchZoom |
                    MultiFingerGesture.pinchMove,
                pinchZoomWinGestures:
                    MultiFingerGesture.rotate |
                    MultiFingerGesture.pinchZoom |
                    MultiFingerGesture.pinchMove,
                pinchMoveWinGestures:
                    MultiFingerGesture.rotate |
                    MultiFingerGesture.pinchZoom |
                    MultiFingerGesture.pinchMove,
              ),
            ),
            children: [
              // OpenStreetMap tiles.
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bitbyte.hrms',
                maxNativeZoom: 19,
              ),

              // ── All alternate routes drawn on map (Google Maps style) ──
              // Draw unselected routes first (behind), selected last (on top).
              ...List.generate(_routes.length, (i) {
                if (_routes[i].points.length < 2)
                  return const SizedBox.shrink();
                final isSelected = i == _selectedRouteIndex;
                if (isSelected)
                  return const SizedBox.shrink(); // drawn separately below
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
                rotate: true,
                markers: List.generate(_routes.length, (i) {
                  if (_routes[i].points.length < 2) {
                    return Marker(
                      point: const LatLng(0, 0),
                      width: 0,
                      height: 0,
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
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
              if (widget.showBreadcrumb && widget.routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      color: Colors.white.withAlpha(200),
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                    ),
                    Polyline(
                      points: widget.routePoints,
                      color: Colors.grey.withAlpha(180),
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),

              // ── Selected road route (Google-Maps style bold blue) ──
              if (_displayRoute.length >= 2)
                PolylineLayer(
                  polylines: [
                    // Thick white border/shadow underneath
                    Polyline(
                      points: _displayRoute,
                      color: Colors.white,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    // Deep indigo route fill used by the reference preview.
                    Polyline(
                      points: _displayRoute,
                      color: const Color(0xFF3F00D7),
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // ── Markers ──────────────────────────────────────────────
              MarkerLayer(
                rotate: true,
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
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Destination — large red Google Maps style teardrop pin ──
                  ...List.generate(
                    widget.waypoints.length,
                    (index) => Marker(
                      point: widget.waypoints[index],
                      width: 28,
                      height: 28,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF5F6368),
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF202124),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (dst != null &&
                      !(dst.latitude == 0.0 && dst.longitude == 0.0))
                    Marker(
                      point: dst,
                      width: 28,
                      height: 38,
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Drop shadow
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: 9,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          // Pin body
                          CustomPaint(
                            size: const Size(28, 34),
                            painter: _RedPinPainter(),
                          ),
                          // Inner white dot
                          const Positioned(
                            top: 7,
                            child: Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 9,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Current position — pulsing green dot + direction arrow ──
                  if (cur != null)
                    Marker(
                      point: cur,
                      width: widget.navigationMode ? 48 : 32,
                      height: widget.navigationMode ? 48 : 32,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            Container(
                              width:
                                  (widget.navigationMode ? 48 : 32) *
                                  _pulseAnim.value,
                              height:
                                  (widget.navigationMode ? 48 : 32) *
                                  _pulseAnim.value,
                              decoration: BoxDecoration(
                                color: currentColor.withAlpha(
                                  (50 * (1.2 - _pulseAnim.value)).round().clamp(
                                    0,
                                    255,
                                  ),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Mid ring
                            Container(
                              width: widget.navigationMode ? 32 : 24,
                              height: widget.navigationMode ? 32 : 24,
                              decoration: BoxDecoration(
                                color: currentColor.withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: currentColor.withAlpha(100),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Directional arrow (rotates toward destination)
                            Transform.rotate(
                              angle: heading * math.pi / 180,
                              child: Container(
                                width: widget.navigationMode
                                    ? 23
                                    : hasCustomPositionIcon
                                    ? 24
                                    : 16,
                                height: widget.navigationMode
                                    ? 23
                                    : hasCustomPositionIcon
                                    ? 24
                                    : 16,
                                decoration: BoxDecoration(
                                  color: currentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.currentPositionIcon ??
                                      (widget.navigationMode
                                          ? Icons.navigation
                                          : Icons.circle),
                                  color: Colors.white,
                                  size: widget.navigationMode
                                      ? 13
                                      : hasCustomPositionIcon
                                      ? 15
                                      : 8,
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
        if (!widget.fullScreen && widget.showLiveBadge)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        if (!widget.fullScreen && widget.showMapControls)
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
                    try {
                      widget.mapController.move(
                        widget.mapController.camera.center,
                        widget.mapController.camera.zoom + 1,
                      );
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 4),
                // Zoom Out
                _mapControlButton(
                  icon: Icons.remove,
                  onTap: () {
                    try {
                      widget.mapController.move(
                        widget.mapController.camera.center,
                        widget.mapController.camera.zoom - 1,
                      );
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 8),
                // Compass / Rotate North
                _mapControlButton(
                  icon: Icons.explore,
                  tooltip: 'Reset north',
                  onTap: () {
                    try {
                      widget.mapController.rotate(0);
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 4),
                // Re-center on current position
                if (cur != null)
                  _mapControlButton(
                    icon: Icons.my_location,
                    iconColor: const Color(0xFF1A73E8),
                    onTap: () {
                      try {
                        widget.mapController.move(cur, 16);
                      } catch (_) {}
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
                  const Icon(
                    Icons.directions_car,
                    color: Color(0xFF1A73E8),
                    size: 22,
                  ),
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
                            fontSize: 11,
                            color: Color(0xFF5F6368),
                          ),
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
        if (widget.showEtaOverlay && _selected != null)
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
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: Color(0xFF1A73E8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selected!.durationLabel}  •  ${_selected!.distanceLabel}',
                    style: const TextStyle(
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
            child: Icon(
              icon,
              size: 20,
              color:
                  iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
