import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'journey_location_queue.dart';
import 'journey_models.dart';
import 'journey_repository.dart';

enum JourneyPermissionState {
  ready,
  gpsDisabled,
  denied,
  deniedForever,
  backgroundUnavailable,
  notificationDenied,
  batteryOptimizationRestricted,
}

class JourneyTracker {
  JourneyTracker._();
  static final instance = JourneyTracker._();

  static void initialize() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'client_journey_tracking',
        channelName: 'Client journey tracking',
        channelDescription: 'Visible while a client journey shares location.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(90000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<JourneyPermissionState> checkAndRequestPermissions({
    bool requireBackground = true,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return JourneyPermissionState.gpsDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return JourneyPermissionState.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return JourneyPermissionState.deniedForever;
    }
    if (requireBackground &&
        Platform.isAndroid &&
        permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        return JourneyPermissionState.backgroundUnavailable;
      }
    }
    final notification =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notification != NotificationPermission.granted) {
      final requested =
          await FlutterForegroundTask.requestNotificationPermission();
      if (requested != NotificationPermission.granted) {
        return JourneyPermissionState.notificationDenied;
      }
    }
    if (Platform.isAndroid &&
        !await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      return JourneyPermissionState.batteryOptimizationRestricted;
    }
    return JourneyPermissionState.ready;
  }

  Future<ServiceRequestResult> start(ClientJourney journey) async {
    await FlutterForegroundTask.saveData(key: 'journey_id', value: journey.id);
    await FlutterForegroundTask.saveData(
      key: 'journey_client_name',
      value: journey.clientName,
    );
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }
    return FlutterForegroundTask.startService(
      serviceId: 4107,
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: 'Client journey tracking is active',
      notificationText: 'Location is being shared for: ${journey.clientName}',
      callback: journeyTrackingCallback,
    );
  }

  Future<ServiceRequestResult> stop() async {
    final result = await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.removeData(key: 'journey_id');
    await FlutterForegroundTask.removeData(key: 'journey_client_name');
    return result;
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  Future<void> openAppSettings() => Geolocator.openAppSettings();
  Future<void> requestBatteryOptimizationExemption() =>
      FlutterForegroundTask.requestIgnoreBatteryOptimization();
}

@pragma('vm:entry-point')
void journeyTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(_JourneyLocationTaskHandler());
}

class _JourneyLocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _subscription;
  int? _journeyId;
  int _sequence = 1;
  DateTime? _lastCapturedAt;
  bool _saving = false;
  bool _syncing = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    WidgetsFlutterBinding.ensureInitialized();
    _journeyId = await FlutterForegroundTask.getData<int>(key: 'journey_id');
    if (_journeyId == null) return;
    _sequence = await SqliteJourneyPointQueue.instance.nextSequence(
      _journeyId!,
    );
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
      intervalDuration: Duration(seconds: 15),
    );
    _subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          _record,
          onError: (Object error) {
            FlutterForegroundTask.sendDataToMain({
              'type': 'tracking_error',
              'message': '$error',
            });
          },
        );
  }

  Future<void> _record(Position position) async {
    if (_journeyId == null || _saving) return;
    _saving = true;
    try {
      final point = JourneyLocationPoint(
        clientGeneratedId: const Uuid().v4(),
        journeyId: _journeyId!,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
        altitude: position.altitude,
        speedMetresPerSecond: position.speed < 0 ? 0 : position.speed,
        heading: position.heading < 0 ? null : position.heading,
        capturedAt: position.timestamp.toUtc(),
        sequenceNumber: _sequence++,
        isMocked: position.isMocked,
      );
      await SqliteJourneyPointQueue.instance.enqueue(point);
      _lastCapturedAt = point.capturedAt;
      FlutterForegroundTask.sendDataToMain({
        'type': 'location_recorded',
        'journey_id': _journeyId,
        ...point.toUploadJson(),
      });
      if (!_syncing) {
        _syncing = true;
        try {
          await JourneyRepository().syncPending(_journeyId!);
        } catch (_) {
          // The SQLite row remains pending and will be retried on the next GPS
          // point, connectivity change, app resume, or manual retry.
        } finally {
          _syncing = false;
        }
      }
    } finally {
      _saving = false;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_lastCapturedAt == null ||
        timestamp.difference(_lastCapturedAt!).inSeconds >= 90) {
      unawaited(
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        ).then(_record),
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
