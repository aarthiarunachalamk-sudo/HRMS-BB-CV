import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
  LatLng? _destinationLatLng;       // geocoded client address
  bool _geocodingDone = false;
  String? _trackingError;
  bool _sendingLocation = false;
  Timer? _trackingRetryTimer;
  List<String> _attendees = [];
  List<Map<String, dynamic>> _checklist = [];

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
        // Use exact stored coordinates if available, else geocode the address.
        if (!_geocodingDone) {
          if (visit.clientLatitude != null && visit.clientLongitude != null) {
            _geocodingDone = true;
            setState(() {
              _destinationLatLng = LatLng(
                visit.clientLatitude!,
                visit.clientLongitude!,
              );
            });
            _fitMapBounds();
          } else {
            unawaited(_geocodeDestination(visit.address));
          }
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
  Future<void> _geocodeDestination(String address) async {
    if (_geocodingDone || address.trim().isEmpty) return;
    _geocodingDone = true;
    try {
      final query = Uri.encodeComponent(
        address.contains('India') ? address : '$address, India',
      );
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$query&format=json&limit=1&countrycodes=in',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'HRMS-Bitbyte/1.0'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body) as List;
        if (results.isNotEmpty && mounted) {
          final first = results.first as Map<String, dynamic>;
          final lat = double.tryParse('${first['lat']}');
          final lon = double.tryParse('${first['lon']}');
          if (lat != null && lon != null) {
            final dest = LatLng(lat, lon);
            setState(() => _destinationLatLng = dest);
            _fitMapBounds();
          }
        }
      }
    } catch (_) {
      // Geocoding failed silently — map still works without destination pin.
    }
  }

  /// Adjusts the map camera to fit origin, current position and destination.
  void _fitMapBounds() {
    final points = <LatLng>[
      if (_lastTrackedPosition != null)
        LatLng(_lastTrackedPosition!.latitude, _lastTrackedPosition!.longitude),
      if (_visit?.officeCheckOutLatitude != null)
        LatLng(
          _visit!.officeCheckOutLatitude!,
          _visit!.officeCheckOutLongitude!,
        ),
      if (_destinationLatLng != null) _destinationLatLng!,
    ];
    if (points.length < 2) return;
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
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
              // Pan map to follow current position.
              try {
                _mapController.move(point, _mapController.camera.zoom < 14
                    ? 15
                    : _mapController.camera.zoom);
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
          decoration: const InputDecoration(labelText: 'TL comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'approval', {
        'action': action,
        'comment': comment.text.trim(),
      });
    });
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _officeCheckout() async {
    await _run(() async {
      final selfiePath = _selfiePath ?? await _captureSelfie();
      if (selfiePath == null) return;
      final position = _capturedPosition ?? await _capturePosition();
      if (position == null) return;
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
    await _run(() async {
      final selfiePath = _selfiePath ?? await _captureSelfie();
      if (selfiePath == null) return;
      final position = _capturedPosition ?? await _capturePosition();
      if (position == null) return;
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
    await _run(() async {
      await widget.service.action(widget.userId, widget.visitId, 'progress', {
        'notes': _notes.text.trim(),
        'attendees': _attendees,
        'checklist': _checklist,
      });
      final images = await ImagePicker().pickMultiImage(imageQuality: 82);
      if (images.isNotEmpty) {
        await widget.service.uploadFiles(
          widget.userId,
          widget.visitId,
          'proof',
          images.map((item) => item.path).toList(),
        );
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
    if (_outcome.text.trim().isEmpty) {
      _message('Visit outcome is required.');
      return;
    }
    await _run(() async {
      final selfiePath = _selfiePath ?? await _captureSelfie();
      if (selfiePath == null) return;
      final position = _capturedPosition ?? await _capturePosition();
      if (position == null) return;
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
      _visitInfo(visit),
      const SizedBox(height: 12),
      EmployeeCard(
        child: Column(
          children: [
            _captureTiles(),
            const SizedBox(height: 10),
            Text(
              'Within client location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
            EmployeeInfoRow('Attendees', '${visit.attendees.length}'),
            EmployeeInfoRow(
              'Checklist',
              '${visit.checklist.where((item) => item is Map && item['done'] == true).length}/${visit.checklist.length} completed',
            ),
            const SizedBox(height: 8),
            if (widget.readOnlyMode)
              _monitoringNotice()
            else ...[
              _flowButton(
                Icons.edit_note,
                'Work update & proof',
                () => _push(
                  ClientVisitWorkUpdateScreen(
                    userId: widget.userId,
                    visitId: widget.visitId,
                    service: widget.service,
                  ),
                ),
              ),
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
            ],
          ],
        ),
      ),
    ],
    9 => [
      EmployeeCard(
        child: Column(
          children: [
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
                IconButton(
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
                  icon: const Icon(Icons.person_add),
                ),
              ],
            ),
            if (_attendees.isNotEmpty)
              Wrap(
                spacing: 6,
                children: _attendees
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        onDeleted: widget.readOnlyMode
                            ? null
                            : () => setState(() => _attendees.remove(name)),
                      ),
                    )
                    .toList(),
              ),
            ..._checklist.asMap().entries.map(
              (entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: entry.value['done'] == true,
                title: Text('${entry.value['label']}'),
                onChanged: widget.readOnlyMode
                    ? null
                    : (value) => setState(
                        () => _checklist[entry.key]['done'] = value == true,
                      ),
              ),
            ),
            TextField(
              controller: _notes,
              readOnly: widget.readOnlyMode,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes / outcome'),
            ),
            const SizedBox(height: 12),
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
          children: [
            DropdownButtonFormField<String>(
              initialValue: _expenseCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const ['travel', 'food', 'parking', 'other']
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_label(item)),
                    ),
                  )
                  .toList(),
              onChanged: widget.readOnlyMode
                  ? null
                  : (value) => setState(() => _expenseCategory = value!),
            ),
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
            TextField(
              controller: _expenseNote,
              readOnly: widget.readOnlyMode,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 12),
            if (widget.readOnlyMode)
              _monitoringNotice()
            else
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
      EmployeeCard(
        child: Column(
          children: [
            for (final expense in visit.expenses)
              EmployeeInfoRow(
                _label('${expense['category']}'),
                '₹${expense['amount']}',
              ),
            const Divider(),
            EmployeeInfoRow(
              'Total',
              '₹${visit.expenseTotal.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    ],
    11 => [
      EmployeeCard(
        child: Column(
          children: [
            _captureTiles(),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _returnMode,
              decoration: const InputDecoration(labelText: 'Duty completion'),
              items: const [
                DropdownMenuItem(
                  value: 'return_office',
                  child: Text('Return to office'),
                ),
                DropdownMenuItem(
                  value: 'end_duty_client',
                  child: Text('End duty from client'),
                ),
              ],
              onChanged: widget.readOnlyMode
                  ? null
                  : (value) => setState(() => _returnMode = value!),
            ),
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
              decoration: const InputDecoration(
                labelText: 'Client signature / OTP name',
              ),
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
                  label: const Text('Complete duty'),
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
      OutlinedButton.icon(
        onPressed: _working ? null : () => _downloadReport(visit),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Download report'),
      ),
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
        EmployeeInfoRow(
          'Employee',
          visit.employeeName.isEmpty
              ? visit.employeeUserId
              : visit.employeeName,
        ),
        EmployeeInfoRow('Contact', visit.contactPerson),
        EmployeeInfoRow(
          'Phone',
          visit.contactPhone.isEmpty ? '—' : visit.contactPhone,
        ),
        EmployeeInfoRow('Date', _date(visit.scheduledAt)),
        EmployeeInfoRow('Purpose', visit.purpose),
        EmployeeInfoRow('Travel mode', _label(visit.travelMode)),
        Align(alignment: Alignment.centerLeft, child: Text(visit.address)),
      ],
    ),
  );
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
  Widget _timeline(ClientVisit visit) => EmployeeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visit timeline', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _timeRow('Office check-out', visit.officeCheckOutAt),
        _timeRow('Reached client', visit.reachedClientAt),
        _timeRow('Client check-in', visit.checkInAt),
        _timeRow('Visit completed', visit.checkOutAt),
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

/// Full Google-Maps-style live tracking map.
/// - Road route fetched from OSRM (free, no API key).
/// - Animated pulsing dot + navigation arrow for current position.
/// - Bottom info card with remaining distance and ETA.
/// - Camera follows position automatically; re-center button snaps back.
class _LiveMapView extends StatefulWidget {
  final MapController mapController;
  final List<LatLng> routePoints;   // actual GPS breadcrumb trail
  final LatLng? origin;
  final LatLng? current;
  final LatLng? destination;

  const _LiveMapView({
    required this.mapController,
    required this.routePoints,
    this.origin,
    this.current,
    this.destination,
  });

  @override
  State<_LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<_LiveMapView>
    with SingleTickerProviderStateMixin {
  // Animated pulse for the current-position dot.
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  // Road route fetched from OSRM.
  List<LatLng> _roadRoute = [];
  double _remainingKm = 0;
  int _etaMinutes = 0;
  bool _fetchingRoute = false;
  LatLng? _lastRouteFetch;   // avoid re-fetching for tiny moves

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
    if (cur == null || dst == null) return;
    // Re-fetch road route every ~100 m of movement.
    if (_lastRouteFetch == null ||
        const Distance().as(LengthUnit.Meter, cur, _lastRouteFetch!) > 100) {
      _fetchRoute(cur, dst);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Fetches a driving route from OSRM and calculates remaining distance + ETA.
  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    if (_fetchingRoute) return;
    _fetchingRoute = true;
    _lastRouteFetch = from;
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'HRMS-Bitbyte/1.0'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distanceM = (route['distance'] as num).toDouble();
          final durationS = (route['duration'] as num).toDouble();
          final coords = (route['geometry']['coordinates'] as List)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted) {
            setState(() {
              _roadRoute = coords;
              _remainingKm = distanceM / 1000;
              _etaMinutes = (durationS / 60).ceil();
            });
          }
        }
      }
    } catch (_) {
      // Route fetch failed — fall back to straight line between points.
    } finally {
      _fetchingRoute = false;
    }
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

  String _distanceLabel() {
    if (_remainingKm <= 0) return '';
    return _remainingKm < 1
        ? '${(_remainingKm * 1000).round()} m'
        : '${_remainingKm.toStringAsFixed(1)} km';
  }

  String _etaLabel() {
    if (_etaMinutes <= 0) return '';
    if (_etaMinutes < 60) return '$_etaMinutes min';
    final h = _etaMinutes ~/ 60;
    final m = _etaMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // The road route to draw — prefer OSRM, fall back to breadcrumb trail.
  List<LatLng> get _displayRoute =>
      _roadRoute.isNotEmpty ? _roadRoute : widget.routePoints;

  LatLng get _center =>
      widget.current ??
      widget.destination ??
      widget.origin ??
      const LatLng(20.5937, 78.9629);

  @override
  Widget build(BuildContext context) {
    final cur = widget.current;
    final dst = widget.destination;
    final heading = (cur != null && dst != null) ? _bearing(cur, dst) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            // ── MAP ──────────────────────────────────────────────────────
            FlutterMap(
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

                // ── Road route ahead (blue, Google-Maps style) ──
                if (_displayRoute.length >= 2)
                  PolylineLayer(
                    polylines: [
                      // White border/outline
                      Polyline(
                        points: _displayRoute,
                        color: Colors.white,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                      // Blue fill
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
                    // Origin — green circle pin.
                    if (widget.origin != null)
                      Marker(
                        point: widget.origin!,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),

                    // Destination — red Google-style pin.
                    if (dst != null)
                      Marker(
                        point: dst,
                        width: 40,
                        height: 50,
                        alignment: const Alignment(0, -1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA4335),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'CLIENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFFEA4335),
                              size: 32,
                            ),
                          ],
                        ),
                      ),

                    // Current position — pulsing blue dot + navigation arrow.
                    if (cur != null)
                      Marker(
                        point: cur,
                        width: 56,
                        height: 56,
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulse ring.
                              Container(
                                width: 56 * _pulseAnim.value,
                                height: 56 * _pulseAnim.value,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8).withAlpha(
                                      (60 * (1.0 - _pulseAnim.value + 0.3))
                                          .round()),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Accuracy ring (semi-transparent).
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8).withAlpha(40),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF1A73E8)
                                        .withAlpha(80),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Navigation arrow (rotates toward destination).
                              Transform.rotate(
                                angle: heading * math.pi / 180,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A73E8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 13,
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

            // ── Re-center button ─────────────────────────────────────────
            if (cur != null)
              Positioned(
                right: 10,
                top: 10,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      try {
                        widget.mapController.move(cur, 15);
                      } catch (_) {}
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.my_location,
                        size: 20,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Bottom info card (distance + ETA) ─────────────────────
            if (_distanceLabel().isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white.withAlpha(242),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
                              _etaLabel().isNotEmpty
                                  ? '${_etaLabel()} away'
                                  : 'Calculating…',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF202124),
                              ),
                            ),
                            Text(
                              _distanceLabel(),
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
          ],
        ),
      ),
    );
  }
}

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
