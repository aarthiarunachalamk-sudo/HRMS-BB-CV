import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'journey_models.dart';
import 'journey_map_utils.dart';
import 'journey_repository.dart';
import 'journey_tracker.dart';

const _trackingDisclosure =
    'Your live location will be shared with your assigned Team Lead during '
    'this client journey. Tracking will stop when the journey is completed or cancelled.';

class ClientJourneyHubScreen extends StatefulWidget {
  final String userId;
  final bool teamMode;
  const ClientJourneyHubScreen({
    super.key,
    required this.userId,
    this.teamMode = false,
  });

  @override
  State<ClientJourneyHubScreen> createState() => _ClientJourneyHubScreenState();
}

class _ClientJourneyHubScreenState extends State<ClientJourneyHubScreen> {
  final _repository = JourneyRepository();
  List<ClientJourney>? _journeys;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final journeys = widget.teamMode
          ? (await Future.wait([
              _repository.list(team: true),
              _repository.list(team: true, history: true),
            ])).expand((items) => items).toList(growable: false)
          : await _repository.list();
      if (mounted) setState(() => _journeys = journeys);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateClientJourneyScreen(
          userId: widget.userId,
          repository: _repository,
        ),
      ),
    );
    if (created == true) await _load();
  }

  Future<void> _open(ClientJourney journey) async {
    final screen = widget.teamMode
        ? JourneyMapScreen(journey: journey, repository: _repository)
        : EmployeeJourneyScreen(journey: journey, repository: _repository);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.teamMode ? 'Team Live Journeys' : 'Live Journeys'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: widget.teamMode
        ? null
        : FloatingActionButton.extended(
            onPressed: _create,
            icon: const Icon(Icons.add_road),
            label: const Text('New journey'),
          ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            _ErrorCard(message: _error!, retry: _load)
          else if (_journeys == null)
            const Center(child: CircularProgressIndicator())
          else if (_journeys!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: Text('No journeys are available.')),
            )
          else
            ..._journeys!.map(
              (journey) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      journey.isActive ? Icons.navigation : Icons.route,
                    ),
                  ),
                  title: Text(journey.clientName),
                  subtitle: Text(
                    widget.teamMode
                        ? '${journey.employeeName}\n${journey.status.replaceAll('_', ' ')}'
                        : '${journey.meetingPurpose}\n${journey.status.replaceAll('_', ' ')}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(journey),
                ),
              ),
            ),
          const SizedBox(height: 90),
        ],
      ),
    ),
  );
}

class CreateClientJourneyScreen extends StatefulWidget {
  final String userId;
  final JourneyRepository repository;
  const CreateClientJourneyScreen({
    super.key,
    required this.userId,
    required this.repository,
  });

  @override
  State<CreateClientJourneyScreen> createState() =>
      _CreateClientJourneyScreenState();
}

class _CreateClientJourneyScreenState extends State<CreateClientJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _client = TextEditingController();
  final _contact = TextEditingController();
  final _purpose = TextEditingController();
  final _address = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  List<Map<String, dynamic>> _teamLeads = const [];
  String? _teamLead;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.repository.assignees().then((value) {
      if (mounted) setState(() => _teamLeads = value);
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _client,
      _contact,
      _purpose,
      _address,
      _latitude,
      _longitude,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _teamLead == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.create({
        'assigned_team_lead_id': _teamLead,
        'client_name': _client.text.trim(),
        'client_contact': _contact.text.trim(),
        'meeting_purpose': _purpose.text.trim(),
        'destination_address': _address.text.trim(),
        'destination_latitude': double.parse(_latitude.text.trim()),
        'destination_longitude': double.parse(_longitude.text.trim()),
        'scheduled_at': _scheduledAt.toUtc().toIso8601String(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create client journey')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _client,
            decoration: const InputDecoration(labelText: 'Client name'),
            validator: _required,
          ),
          TextFormField(
            controller: _contact,
            decoration: const InputDecoration(
              labelText: 'Client contact (optional)',
            ),
          ),
          TextFormField(
            controller: _purpose,
            decoration: const InputDecoration(labelText: 'Meeting purpose'),
            validator: _required,
          ),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Destination address (optional)',
            ),
            maxLines: 2,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  validator: _coordinateValidator(-90, 90),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _longitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  validator: _coordinateValidator(-180, 180),
                ),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _teamLead,
            decoration: const InputDecoration(labelText: 'Assigned Team Lead'),
            items: _teamLeads
                .map(
                  (item) => DropdownMenuItem(
                    value: '${item['user_id']}',
                    child: Text('${item['name']} (${item['user_id']})'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _teamLead = value),
            validator: (value) => value == null ? 'Select a Team Lead' : null,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Scheduled date and time'),
            subtitle: Text(_localDateTime(_scheduledAt)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _pickSchedule,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Create journey'),
          ),
        ],
      ),
    ),
  );

  FormFieldValidator<String> _coordinateValidator(double min, double max) =>
      (value) {
        final parsed = double.tryParse((value ?? '').trim());
        return parsed == null || parsed < min || parsed > max
            ? 'Enter $min to $max'
            : null;
      };

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time != null) {
      setState(
        () => _scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }
}

class EmployeeJourneyScreen extends StatefulWidget {
  final ClientJourney journey;
  final JourneyRepository repository;
  const EmployeeJourneyScreen({
    super.key,
    required this.journey,
    required this.repository,
  });

  @override
  State<EmployeeJourneyScreen> createState() => _EmployeeJourneyScreenState();
}

class _EmployeeJourneyScreenState extends State<EmployeeJourneyScreen> {
  late ClientJourney _journey;
  JourneyLocationPoint? _latest;
  String _network = 'Checking';
  String? _error;
  bool _busy = false;
  bool _trackingServiceRunning = true;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;

  @override
  void initState() {
    super.initState();
    _journey = widget.journey;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _networkSubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (!mounted) return;
      setState(
        () => _network =
            results.any((result) => result != ConnectivityResult.none)
            ? 'Online'
            : 'Offline',
      );
      if (_network == 'Online' && _journey.isActive) unawaited(_sync());
    });
    if (_journey.isActive) {
      unawaited(_checkTrackingService());
      unawaited(
        widget.repository.latest(_journey.id).then((point) {
          if (mounted) setState(() => _latest = point);
        }),
      );
      _syncTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => unawaited(_sync()),
      );
    }
  }

  Future<void> _checkTrackingService() async {
    final running = await FlutterForegroundTask.isRunningService;
    if (mounted) setState(() => _trackingServiceRunning = running);
  }

  Future<void> _resumeTracking() async {
    final permission = await JourneyTracker.instance
        .checkAndRequestPermissions();
    if (permission != JourneyPermissionState.ready) {
      await _explainPermission(permission);
      return;
    }
    await JourneyTracker.instance.start(_journey);
    if (mounted) setState(() => _trackingServiceRunning = true);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _networkSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  void _onTaskData(Object data) {
    if (data is! Map ||
        data['journey_id'] != _journey.id ||
        data['type'] != 'location_recorded') {
      return;
    }
    final point = JourneyLocationPoint.fromJson(
      Map<String, dynamic>.from(data),
    );
    if (mounted) setState(() => _latest = point);
    unawaited(_sync());
  }

  Future<void> _sync() async {
    try {
      await widget.repository.syncPending(_journey.id);
      final latest = await widget.repository.latest(_journey.id);
      if (mounted) {
        setState(() {
          _latest = latest ?? _latest;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Saved offline. Upload will retry: $error');
      }
    }
  }

  Future<void> _start() async {
    final consented = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location sharing consent'),
        content: const Text(_trackingDisclosure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start Journey'),
          ),
        ],
      ),
    );
    if (consented != true || !mounted) return;
    final permission = await JourneyTracker.instance
        .checkAndRequestPermissions();
    if (permission != JourneyPermissionState.ready) {
      await _explainPermission(permission);
      return;
    }
    setState(() => _busy = true);
    try {
      if (_journey.status == 'SCHEDULED') {
        _journey = await widget.repository.action(_journey.id, 'ready');
      }
      _journey = await widget.repository.action(_journey.id, 'start');
      await JourneyTracker.instance.start(_journey);
      _trackingServiceRunning = true;
      _syncTimer ??= Timer.periodic(
        const Duration(seconds: 20),
        (_) => unawaited(_sync()),
      );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _explainPermission(JourneyPermissionState state) async {
    final message = switch (state) {
      JourneyPermissionState.gpsDisabled =>
        'Turn on device location so the journey can record real GPS points.',
      JourneyPermissionState.denied =>
        'Precise location is required only while you explicitly run a client journey.',
      JourneyPermissionState.deniedForever =>
        'Location permission is blocked. Open app settings and allow precise location.',
      JourneyPermissionState.backgroundUnavailable =>
        'Allow location “all the time” so tracking continues with the visible notification when the screen is locked.',
      JourneyPermissionState.notificationDenied =>
        'Notifications are required to keep journey tracking visibly disclosed.',
      JourneyPermissionState.batteryOptimizationRestricted =>
        'Battery optimization may stop long journeys. Allow unrestricted battery use for reliable tracking.',
      JourneyPermissionState.ready => '',
    };
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tracking permission needed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (open != true) return;
    if (state == JourneyPermissionState.gpsDisabled) {
      await JourneyTracker.instance.openLocationSettings();
    } else if (state == JourneyPermissionState.batteryOptimizationRestricted) {
      await JourneyTracker.instance.requestBatteryOptimizationExemption();
    } else {
      await JourneyTracker.instance.openAppSettings();
    }
  }

  Future<void> _finish(bool cancelled) async {
    String reason = '';
    if (cancelled) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel journey'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Cancellation reason'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim().isNotEmpty),
              child: const Text('Cancel journey'),
            ),
          ],
        ),
      );
      reason = controller.text.trim();
      controller.dispose();
      if (confirmed != true) return;
    }
    setState(() => _busy = true);
    try {
      await _sync();
      _journey = await widget.repository.action(
        _journey.id,
        cancelled ? 'cancel' : 'complete',
        body: cancelled ? {'reason': reason} : null,
      );
      await JourneyTracker.instance.stop();
      _trackingServiceRunning = false;
      _syncTimer?.cancel();
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_journey.clientName)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_journey.isActive &&
            _journey.status != 'COMPLETED' &&
            _journey.status != 'CANCELLED')
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(_trackingDisclosure),
            ),
          ),
        _Metric('Journey status', _journey.status.replaceAll('_', ' ')),
        _Metric(
          'Journey started',
          _journey.startedAt == null
              ? 'Not started'
              : _localDateTime(_journey.startedAt!.toLocal()),
        ),
        _Metric(
          'GPS accuracy',
          _latest == null
              ? 'Waiting for GPS'
              : '${_latest!.accuracyMetres.toStringAsFixed(1)} m${_latest!.accuracyMetres > 100 ? ' · low accuracy' : ''}',
        ),
        _Metric(
          'Last successful upload',
          _latest?.receivedAt == null
              ? 'Pending/offline'
              : _localDateTime(_latest!.receivedAt!.toLocal()),
        ),
        _Metric('Network', _network),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 20),
        if (!_journey.isActive &&
            _journey.status != 'COMPLETED' &&
            _journey.status != 'CANCELLED')
          FilledButton.icon(
            onPressed: _busy ? null : _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Journey'),
          ),
        if (_journey.isActive) ...[
          if (!_trackingServiceRunning) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text(
                      'This journey is active, but the tracking service is not running. Resume it to continue recording.',
                    ),
                    TextButton.icon(
                      onPressed: _resumeTracking,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Resume tracking'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _busy ? null : () => _finish(false),
            icon: const Icon(Icons.flag),
            label: const Text('Reached Client'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _finish(true),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Journey'),
          ),
        ],
        if (_journey.status == 'COMPLETED' ||
            _journey.status == 'CANCELLED') ...[
          _Metric(
            'Distance',
            '${(_journey.totalDistanceMetres / 1000).toStringAsFixed(2)} km',
          ),
          _Metric('Duration', _duration(_journey.totalDurationSeconds)),
          _Metric('Recorded points', '${_journey.pointCount}'),
          _Metric('Low-accuracy points', '${_journey.lowAccuracyPointCount}'),
          _Metric('Detected stops', '${_journey.stopCount}'),
          if (_journey.cancelReason.isNotEmpty)
            _Metric('Cancellation reason', _journey.cancelReason),
        ],
      ],
    ),
  );
}

class JourneyMapScreen extends StatefulWidget {
  final ClientJourney journey;
  final JourneyRepository repository;
  const JourneyMapScreen({
    super.key,
    required this.journey,
    required this.repository,
  });
  @override
  State<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends State<JourneyMapScreen> {
  final List<JourneyLocationPoint> _points = [];
  GoogleMapController? _controller;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeat;
  int _attempt = 0;
  bool _online = false;
  String? _error;
  int _gapCount = 0;
  int _stopCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final route = await widget.repository.route(widget.journey.id);
      if (!mounted) return;
      setState(() {
        _points
          ..clear()
          ..addAll(route.points);
        _gapCount = route.gaps.length;
        _stopCount = route.stops.length;
        _error = null;
      });
      _fit();
      if (widget.journey.isActive) await _connect();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _connect() async {
    await _socketSubscription?.cancel();
    await _channel?.sink.close();
    try {
      final latest = await widget.repository.latest(widget.journey.id);
      _addPoint(latest);
      _channel = await widget.repository.connect(widget.journey.id);
      _attempt = 0;
      if (mounted) setState(() => _online = true);
      _socketSubscription = _channel!.stream.listen(
        (event) {
          final data = jsonDecode('$event');
          if (data is Map && data['type'] == 'location_update') {
            _addPoint(
              JourneyLocationPoint.fromJson({
                ...Map<String, dynamic>.from(data),
                'journey_id': widget.journey.id,
              }),
            );
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(
        const Duration(seconds: 25),
        (_) => _channel?.sink.add(jsonEncode({'type': 'ping'})),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!mounted || !widget.journey.isActive) return;
    setState(() => _online = false);
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (1 << _attempt.clamp(0, 5)));
    _attempt++;
    _reconnectTimer = Timer(delay, () => unawaited(_connect()));
  }

  void _addPoint(JourneyLocationPoint? point) {
    if (point == null ||
        _points.any(
          (item) => item.clientGeneratedId == point.clientGeneratedId,
        )) {
      return;
    }
    if (mounted) {
      setState(() {
        _points.add(point);
        _points.sort((a, b) {
          final time = a.capturedAt.compareTo(b.capturedAt);
          return time != 0
              ? time
              : a.sequenceNumber.compareTo(b.sequenceNumber);
        });
      });
    }
  }

  Future<void> _fit() async {
    if (_controller == null || _points.isEmpty) return;
    if (_points.length == 1) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_points.first.latitude, _points.first.longitude),
          16,
        ),
      );
      return;
    }
    final latitudes = _points.map((p) => p.latitude),
        longitudes = _points.map((p) => p.longitude);
    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            latitudes.reduce((a, b) => a < b ? a : b),
            longitudes.reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            latitudes.reduce((a, b) => a > b ? a : b),
            longitudes.reduce((a, b) => a > b ? a : b),
          ),
        ),
        60,
      ),
    );
  }

  Set<Polyline> get _polylines {
    final segments = buildJourneyRouteSegments(_points);
    return {
      for (var index = 0; index < segments.length; index++)
        Polyline(
          polylineId: PolylineId('segment-$index'),
          points: segments[index].points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          color: segments[index].lowAccuracy ? Colors.orange : Colors.blue,
          width: 5,
        ),
    };
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    _socketSubscription?.cancel();
    _channel?.sink.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latest = _points.isEmpty ? null : _points.last;
    final start = _points.isEmpty ? null : _points.first;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
          widget.journey.destinationLatitude,
          widget.journey.destinationLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
      if (start != null)
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(start.latitude, start.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      if (latest != null)
        Marker(
          markerId: const MarkerId('employee'),
          position: LatLng(latest.latitude, latest.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: widget.journey.employeeName),
        ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(widget.journey.clientName)),
      body: Column(
        children: [
          Expanded(
            child: _error != null
                ? _ErrorCard(message: _error!, retry: _loadRoute)
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        widget.journey.destinationLatitude,
                        widget.journey.destinationLongitude,
                      ),
                      zoom: 13,
                    ),
                    markers: markers,
                    polylines: _polylines,
                    myLocationButtonEnabled: false,
                    onMapCreated: (controller) {
                      _controller = controller;
                      _fit();
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.journey.employeeName} · ${widget.journey.status.replaceAll('_', ' ')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        avatar: Icon(
                          Icons.circle,
                          size: 10,
                          color: _online ? Colors.green : Colors.grey,
                        ),
                        label: Text(_online ? 'Online' : 'Offline'),
                      ),
                    ],
                  ),
                  _Metric(
                    'Last update',
                    latest?.receivedAt == null
                        ? 'No location received'
                        : _localDateTime(latest!.receivedAt!.toLocal()),
                  ),
                  _Metric(
                    'GPS / movement',
                    latest == null
                        ? 'Waiting'
                        : '${latest.accuracyMetres.toStringAsFixed(1)} m · ${(latest.speedMetresPerSecond ?? 0) >= 1 ? 'Moving' : 'Stationary'}',
                  ),
                  _Metric(
                    'Recorded distance',
                    '${(calculateRecordedDistanceMetres(_points) / 1000).toStringAsFixed(2)} km',
                  ),
                  if (!widget.journey.isActive) ...[
                    _Metric(
                      'Journey duration',
                      _duration(widget.journey.totalDurationSeconds),
                    ),
                    _Metric(
                      'Moving duration',
                      _duration(widget.journey.movingDurationSeconds),
                    ),
                    _Metric(
                      'Stationary duration',
                      _duration(widget.journey.stationaryDurationSeconds),
                    ),
                    _Metric('Recorded points', '${_points.length}'),
                    _Metric(
                      'Low-accuracy points',
                      '${_points.where((point) => point.isLowAccuracy).length}',
                    ),
                    _Metric('Detected stops', '$_stopCount'),
                    _Metric('GPS/network gaps', '$_gapCount'),
                    if (widget.journey.cancelReason.isNotEmpty)
                      _Metric(
                        'Cancellation reason',
                        widget.journey.cancelReason,
                      ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: latest == null
                              ? null
                              : () => _controller?.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(latest.latitude, latest.longitude),
                                    17,
                                  ),
                                ),
                          icon: const Icon(Icons.my_location),
                          label: const Text('Recenter'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _fit,
                          icon: const Icon(Icons.fit_screen),
                          label: const Text('Fit journey'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() retry;
  const _ErrorCard({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

String _localDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _duration(int seconds) =>
    '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
