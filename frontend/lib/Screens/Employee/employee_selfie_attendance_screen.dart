import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'employee_service.dart';
import 'employee_shared.dart';

enum EmployeeAttendanceAction { checkIn, checkOut }

const int _fullDayCheckInCutoffHour = 12;
const double _selfiePreviewAspectRatio = .76;
const double _targetGpsAccuracyMeters = 25;
const double _maximumGpsAccuracyMeters = 50;
const Duration _gpsCaptureTimeout = Duration(seconds: 12);
const Duration _maximumGpsAge = Duration(seconds: 45);

class _GpsCaptureException implements Exception {
  final String message;

  const _GpsCaptureException(this.message);

  @override
  String toString() => message;
}

class EmployeeSelfieAttendanceScreen extends StatefulWidget {
  final String userId;
  final EmployeeService service;
  final EmployeeAttendanceAction action;
  final String workMode;

  const EmployeeSelfieAttendanceScreen({
    super.key,
    required this.userId,
    required this.service,
    required this.action,
    required this.workMode,
  });

  @override
  State<EmployeeSelfieAttendanceScreen> createState() =>
      _EmployeeSelfieAttendanceScreenState();
}

class _EmployeeSelfieAttendanceScreenState
    extends State<EmployeeSelfieAttendanceScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  final Geocoding _geocoding = Geocoding();

  String? _capturedPath;
  Position? _position;
  String? _gpsAddress;
  Map<String, dynamic>? _result;
  String? _error;
  bool _submitting = false;
  bool _processingCapture = false;
  bool _loadingLocation = true;
  bool _openingLocationSettings = false;
  bool _locationPermissionDeniedForever = false;
  String? _policyStatus;

  bool get _isCheckIn => widget.action == EmployeeAttendanceAction.checkIn;
  bool get _locationReady {
    final position = _position;
    return position != null &&
        !position.isMocked &&
        position.accuracy > 0 &&
        position.accuracy <= _maximumGpsAccuracyMeters;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _position != null) return;
    _loadLocation();
  }

  // ---------------------------------------------------------------------
  // Camera setup
  // ---------------------------------------------------------------------

  Future<void> _initCamera() async {
    if (_position == null || _cameraController != null) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _error = 'No camera found on this device.');
        }
        return;
      }
      final frontCameras = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (frontCameras.isEmpty) {
        if (mounted) {
          setState(
            () => _error =
                'A front-facing camera is required for selfie attendance.',
          );
        }
        return;
      }
      final frontCamera = frontCameras.first;
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;
      _initializeControllerFuture = controller.initialize();
      await _initializeControllerFuture;
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Camera permission is required for selfie attendance.',
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------

  Future<void> _loadLocation() async {
    if (!mounted) return;
    setState(() {
      _loadingLocation = true;
      _locationPermissionDeniedForever = false;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _loadingLocation = false;
            _error = 'Please enable GPS to continue with selfie attendance.';
          });
        }
        return;
      }

      // Check permission status without immediately requesting it.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Only show the OS permission dialog when it has never been asked.
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _loadingLocation = false;
            _locationPermissionDeniedForever =
                permission == LocationPermission.deniedForever;
            _error = permission == LocationPermission.deniedForever
                ? 'Location permission is permanently denied. Enable it from app settings.'
                : 'Location permission is required before opening the selfie camera.';
          });
        }
        return;
      }

      // --- Fast path: reuse a recent last-known position ---
      // This avoids re-acquiring GPS from scratch when the user already has a
      // fresh fix (e.g. returning from the settings screen).
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null &&
          !lastKnown.isMocked &&
          lastKnown.accuracy > 0 &&
          lastKnown.accuracy <= _maximumGpsAccuracyMeters) {
        final age = DateTime.now().difference(lastKnown.timestamp).abs();
        if (age <= _maximumGpsAge) {
          if (mounted) {
            setState(() {
              _position = lastKnown;
              _loadingLocation = false;
              _error = null;
            });
          }
          await _loadAddress(lastKnown);
          await _initCamera();
          return;
        }
      }

      // --- Slow path: acquire a fresh GPS fix ---
      final position = await _capturePrecisePosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _loadingLocation = false;
        _error = null;
      });
      await _loadAddress(position);
      await _initCamera();
    } on _GpsCaptureException catch (error) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _error = 'Unable to capture an exact GPS location. Please retry.';
        });
      }
    }
  }

  Future<Position> _capturePrecisePosition() async {
    final completer = Completer<Position>();
    Position? bestPosition;
    late final StreamSubscription<Position> subscription;
    final timer = Timer(_gpsCaptureTimeout, () {
      if (completer.isCompleted) return;
      final best = bestPosition;
      if (best != null && best.accuracy <= _maximumGpsAccuracyMeters) {
        completer.complete(best);
      } else {
        final accuracy = best == null ? '' : ' (${best.accuracy.round()} m)';
        completer.completeError(
          _GpsCaptureException(
            'GPS accuracy is too low$accuracy. Move near a window or outdoors, keep GPS on, and retry.',
          ),
        );
      }
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
    subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (candidate) {
        if (completer.isCompleted) return;
        if (candidate.isMocked) {
          completer.completeError(
            const _GpsCaptureException(
              'Mock location detected. Disable mock-location apps and retry with device GPS.',
            ),
          );
          return;
        }
        // Some platform builds may return a null timestamp; treat that as fresh.
        final age = candidate.timestamp == null
          ? Duration.zero
          : DateTime.now().difference(candidate.timestamp!).abs();
        if (age > _maximumGpsAge || candidate.accuracy <= 0) return;
        if (bestPosition == null ||
            candidate.accuracy < bestPosition!.accuracy) {
          bestPosition = candidate;
        }
        if (candidate.accuracy <= _targetGpsAccuracyMeters) {
          completer.complete(candidate);
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(
            const _GpsCaptureException(
              'Unable to receive a fresh GPS signal. Check location settings and retry.',
            ),
          );
        }
      },
    );

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
    }
  }

  Future<void> _loadAddress(Position position) async {
    try {
      final placemarks = await _geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 8));
      if (placemarks.isEmpty || !mounted) return;
      final place = placemarks.first;
      final parts = <String>[
        place.name ?? '',
        place.street ?? '',
        place.thoroughfare ?? '',
        place.subThoroughfare ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
        place.postalCode ?? '',
        place.country ?? '',
      ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
      final uniqueParts = <String>[];
      for (final part in parts) {
        if (!uniqueParts.contains(part)) uniqueParts.add(part);
      }
      if (uniqueParts.isNotEmpty) {
        setState(() => _gpsAddress = uniqueParts.join(', '));
      }
    } catch (_) {
      // Coordinates remain available when reverse geocoding is unavailable.
    }
  }

  Future<void> _openLocationSettings() async {
    if (_openingLocationSettings) return;
    setState(() => _openingLocationSettings = true);
    if (_locationPermissionDeniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }
    if (!mounted) return;
    setState(() => _openingLocationSettings = false);
  }

  // ---------------------------------------------------------------------
  // Capture + watermark burn-in
  // ---------------------------------------------------------------------

  Future<void> _captureSelfie() async {
    if (_submitting || _processingCapture) return;
    final currentPosition = _position;
    final locationIsStale =
        currentPosition == null ||
        DateTime.now().difference(currentPosition.timestamp).abs() >
            _maximumGpsAge;
    if (!_locationReady || locationIsStale) {
      await _loadLocation();
      if (!_locationReady) return;
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      await _initCamera();
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        if (mounted) {
          setState(() => _error = 'Camera is not ready yet. Please wait.');
        }
        return;
      }
    }

    final readyController = _cameraController;
    if (readyController == null) {
      return;
    }

    setState(() {
      _processingCapture = true;
      _error = null;
    });

    try {
      final rawFile = await readyController.takePicture();
      final watermarkedPath = await _burnWatermark(
        rawFile.path,
        flipHorizontally:
            readyController.description.lensDirection ==
            CameraLensDirection.front,
      );
      if (!mounted) return;
      setState(() {
        _capturedPath = watermarkedPath;
        _processingCapture = false;
      });
      await _submit(watermarkedPath);
    } catch (_) {
      if (mounted) {
        setState(() {
          _processingCapture = false;
          _error = 'Unable to capture selfie. Please try again.';
        });
      }
    }
  }

  Future<String> _burnWatermark(
    String rawPath, {
    required bool flipHorizontally,
  }) async {
    final bytes = await File(rawPath).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return rawPath;

    // Correct orientation using EXIF data captured by the camera sensor.
    decoded = img.bakeOrientation(decoded);
    // Some devices save front-camera captures as the mirrored sensor image.
    // Normalize it before watermarking so the uploaded and fetched selfie has
    // the same natural, non-mirrored orientation as a regular photograph.
    if (flipHorizontally) {
      decoded = img.flipHorizontal(decoded);
    }

    final watermarked = _drawWatermark(
      decoded,
      _position,
      DateTime.now(),
      _gpsAddress,
    );

    final directory = await getTemporaryDirectory();
    final outPath =
        '${directory.path}/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(watermarked, quality: 85));
    return outPath;
  }

  img.Image _drawWatermark(
    img.Image photo,
    Position? position,
    DateTime now,
    String? gpsAddress,
  ) {
    final w = photo.width;
    final h = photo.height;
    final bandHeight = (h * 0.24).round();
    final bandTop = h - bandHeight;

    // Semi-transparent gradient band (transparent -> black) at the bottom,
    // matching the on-screen preview overlay.
    for (int y = bandTop; y < h; y++) {
      final t = (y - bandTop) / bandHeight;
      final alpha = (60 + (200 - 60) * t).clamp(0, 255).round();
      for (int x = 0; x < w; x++) {
        final pixel = photo.getPixel(x, y);
        int blend(int channel) {
          return ((channel * (255 - alpha)) / 255).round().clamp(0, 255);
        }

        photo.setPixelRgba(
          x,
          y,
          blend(pixel.r.toInt()),
          blend(pixel.g.toInt()),
          blend(pixel.b.toInt()),
          255,
        );
      }
    }

    final latitude = position?.latitude;
    final longitude = position?.longitude;

    final mapSize = (h * 0.14).round().clamp(76, 190);
    final mapLeft = (w * 0.04).round();
    final mapTop = h - mapSize - (h * 0.02).round();
    _drawMiniMapStamp(photo, x: mapLeft, y: mapTop, size: mapSize);

    // Text block to the right of the map stamp.
    final textLeft = mapLeft + mapSize + (w * 0.04).round();
    int textY = mapTop + (h * 0.005).round();

    final address = gpsAddress?.trim().isNotEmpty == true
        ? gpsAddress!.trim()
        : 'GPS location';
    final latLong = latitude != null && longitude != null
        ? 'Lat ${latitude.toStringAsFixed(6)}\u00B0 Long ${longitude.toStringAsFixed(6)}\u00B0'
        : 'GPS coordinates unavailable';
    final timestamp = _formatTimestamp(now);

    img.drawString(
      photo,
      address,
      font: img.arial24,
      x: textLeft,
      y: textY,
      color: img.ColorRgb8(255, 255, 255),
    );
    textY += 30;

    img.drawString(
      photo,
      latLong,
      font: img.arial14,
      x: textLeft,
      y: textY,
      color: img.ColorRgb8(255, 255, 255),
      wrap: true,
    );
    textY += 38;

    img.drawString(
      photo,
      timestamp,
      font: img.arial14,
      x: textLeft,
      y: textY,
      color: img.ColorRgb8(255, 255, 255),
    );

    return photo;
  }

  void _drawMiniMapStamp(
    img.Image photo, {
    required int x,
    required int y,
    required int size,
  }) {
    final right = x + size;
    final bottom = y + size;
    int sx(double value) => x + (size * value).round();
    int sy(double value) => y + (size * value).round();

    img.fillRect(
      photo,
      x1: x,
      y1: y,
      x2: right,
      y2: bottom,
      color: img.ColorRgb8(215, 229, 216),
    );

    final park = img.ColorRgb8(174, 216, 177);
    final water = img.ColorRgb8(140, 196, 222);
    final block = img.ColorRgb8(232, 220, 199);
    final road = img.ColorRgb8(250, 250, 245);
    final roadEdge = img.ColorRgb8(188, 198, 203);

    img.fillRect(
      photo,
      x1: sx(.02),
      y1: sy(.05),
      x2: sx(.38),
      y2: sy(.34),
      color: park,
    );
    img.fillRect(
      photo,
      x1: sx(.67),
      y1: sy(.03),
      x2: sx(.98),
      y2: sy(.28),
      color: water,
    );
    img.fillRect(
      photo,
      x1: sx(.08),
      y1: sy(.62),
      x2: sx(.38),
      y2: sy(.92),
      color: block,
    );
    img.fillRect(
      photo,
      x1: sx(.58),
      y1: sy(.55),
      x2: sx(.93),
      y2: sy(.88),
      color: block,
    );

    void mapLine(
      double x1,
      double y1,
      double x2,
      double y2,
      img.Color color,
      double thickness,
    ) {
      img.drawLine(
        photo,
        x1: sx(x1),
        y1: sy(y1),
        x2: sx(x2),
        y2: sy(y2),
        color: color,
        thickness: (size * thickness).clamp(1, 18),
        antialias: true,
      );
    }

    mapLine(.03, .48, .98, .18, roadEdge, .065);
    mapLine(.03, .48, .98, .18, road, .045);
    mapLine(.12, .96, .88, .08, roadEdge, .055);
    mapLine(.12, .96, .88, .08, road, .036);
    mapLine(.00, .73, .98, .70, roadEdge, .05);
    mapLine(.00, .73, .98, .70, road, .032);
    mapLine(.47, .00, .52, 1.00, roadEdge, .052);
    mapLine(.47, .00, .52, 1.00, road, .034);
    mapLine(.22, .08, .87, .93, img.ColorRgb8(31, 142, 255), .022);

    final pinX = sx(.53);
    final pinY = sy(.52);
    img.fillCircle(
      photo,
      x: pinX,
      y: pinY,
      radius: (size * .17).round(),
      color: img.ColorRgb8(255, 255, 255),
    );
    img.fillCircle(
      photo,
      x: pinX,
      y: pinY,
      radius: (size * .125).round(),
      color: img.ColorRgb8(244, 67, 54),
    );
    img.fillCircle(
      photo,
      x: pinX,
      y: pinY,
      radius: (size * .045).round(),
      color: img.ColorRgb8(255, 255, 255),
    );

    img.drawRect(
      photo,
      x1: x,
      y1: y,
      x2: right,
      y2: bottom,
      color: img.ColorRgb8(255, 255, 255),
      thickness: 2,
    );
  }

  String _formatTimestamp(DateTime now) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    String two(int value) => value.toString().padLeft(2, '0');
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '${days[now.weekday - 1]}, ${two(now.day)}/${two(now.month)}/${now.year} '
        '${two(hour12)}:${two(now.minute)} $ampm GMT +05:30';
  }

  // ---------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------

  Future<void> _submit(String selfiePath) async {
    var position = _position;
    if (position == null) {
      await _loadLocation();
      position = _position;
    }
    if (position == null) return;

    setState(() => _submitting = true);
    final mobileTime = DateTime.now();
    final policyStatus = _isCheckIn ? _statusForCheckIn(mobileTime) : null;
    final payload = {
      'selfie_path': selfiePath,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'location_address': _gpsAddress ?? '',
      'location_timestamp': position.timestamp.toIso8601String(),
      'is_mocked': position.isMocked,
      'mobile_timestamp': mobileTime.toIso8601String(),
      'timezone_offset_minutes': mobileTime.timeZoneOffset.inMinutes,
      if (_isCheckIn) 'work_mode': widget.workMode,
      if (policyStatus != null) 'client_attendance_status': policyStatus,
    };

    try {
      final result = _isCheckIn
          ? await widget.service.checkIn(widget.userId, payload)
          : await widget.service.checkOut(widget.userId, payload);
      if (!mounted) return;
      final normalized = Map<String, dynamic>.from(result);
      if (policyStatus != null) {
        normalized['status'] = normalized['status'] ?? policyStatus;
      }
      setState(() {
        _result = normalized;
        _policyStatus = normalized['status'] == null
            ? null
            : '${normalized['status']}';
        _submitting = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        });
      }
    }
  }

  String _statusForCheckIn(DateTime checkIn) {
    if (_isAfterNoon(checkIn)) return 'Half Day';
    return 'Present';
  }

  bool _isAfterNoon(DateTime value) {
    if (value.hour != _fullDayCheckInCutoffHour) {
      return value.hour > _fullDayCheckInCutoffHour;
    }
    return value.minute > 0 ||
        value.second > 0 ||
        value.millisecond > 0 ||
        value.microsecond > 0;
  }

  void _finish() {
    Navigator.of(context).pop(_result);
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getBgStart(context);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: AppBarLogoTitle(title: _successTitle),
      ),
      body: SafeArea(child: _result == null ? _captureBody() : _successBody()),
    );
  }

  String get _successTitle {
    if (_result != null) {
      if (_result?['permission_required'] == true) {
        return 'Permission Requested';
      }
      return _isCheckIn ? 'Check-In Success' : 'Check-Out Success';
    }
    if (!_locationReady) return 'Capturing Location';
    return _isCheckIn ? 'Check-In (Selfie)' : 'Check-Out (Selfie)';
  }

  Widget _captureBody() {
    final waitingForLocation = !_locationReady;
    final cardBg = ThemeConfig.getCardBg(context);
    final previewBg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            waitingForLocation
                ? 'Enable geo location to open selfie camera'
                : 'Please capture your selfie',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: _selfiePreviewAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Container(color: previewBg, child: _cameraPreview()),
            ),
          ),
          const SizedBox(height: 14),
          if (_locationReady) ...[
            _LiveGpsCard(
              position: _position!,
              address: _gpsAddress,
              refreshing: _loadingLocation,
              onRefresh: _loadLocation,
            ),
            const SizedBox(height: 14),
          ],
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIconButton(
                  icon: Icons.flash_off_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Flash control is not available on this camera flow.',
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: waitingForLocation ? _loadLocation : _captureSelfie,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: (_submitting || _processingCapture)
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            waitingForLocation
                                ? Icons.location_searching_rounded
                                : Icons.camera_alt_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                  ),
                ),
                _RoundIconButton(
                  icon: waitingForLocation
                      ? Icons.location_on_rounded
                      : Icons.camera_alt_rounded,
                  onTap: waitingForLocation ? _loadLocation : _captureSelfie,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InfoPopupCard(
            color: _isCheckIn ? EmployeeColors.red : EmployeeColors.blue,
            icon: waitingForLocation
                ? Icons.location_on_rounded
                : (_isCheckIn ? Icons.close_rounded : Icons.logout_rounded),
            title: waitingForLocation
                ? 'Geo Location Required'
                : (_isCheckIn ? 'Selfie Required' : 'Check-Out Required'),
            message: waitingForLocation
                ? 'Turn on GPS and allow location access. The selfie camera opens only after your location is captured.'
                : (_isCheckIn
                      ? 'Please capture your selfie to mark your attendance.'
                      : 'Capture your selfie to complete check-out.'),
            actionText: waitingForLocation
                ? (_openingLocationSettings ? 'Opening...' : 'Enable GPS')
                : 'OK',
            onAction: waitingForLocation
                ? _openLocationSettings
                : _captureSelfie,
          ),
          if (waitingForLocation) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadingLocation ? null : _loadLocation,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('I enabled location'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: EmployeeColors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cameraPreview() {
    if (!_locationReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _loadingLocation
                ? const CircularProgressIndicator(color: EmployeeColors.blue)
                : const Icon(
                    Icons.location_on_rounded,
                    color: EmployeeColors.blue,
                    size: 82,
                  ),
            const SizedBox(height: 14),
            Text(
              _loadingLocation
                  ? 'Capturing geo location...'
                  : 'Geo location must be enabled first',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final capturedPath = _capturedPath;
    if (capturedPath != null) {
      return Image.file(
        File(capturedPath),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    final controller = _cameraController;
    final initFuture = _initializeControllerFuture;
    if (controller == null || initFuture == null) {
      return const Center(
        child: Icon(Icons.person_rounded, color: Colors.white54, size: 82),
      );
    }

    return FutureBuilder<void>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            controller.value.isInitialized) {
          return _CameraPreviewFrame(controller: controller);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _successBody() {
    final result = _result!;
    final permissionRequired = result['permission_required'] == true;
    final time = _isCheckIn
        ? '${result['check_in'] ?? '--:--'}'
        : '${result['check_out'] ?? '--:--'}';
    final date = '${result['date'] ?? '17 Jun 2026, Monday'}';
    final successText = permissionRequired
        ? 'Permission Request Sent!'
        : _isCheckIn
        ? 'Check-In Successful!'
        : 'Check-Out Successful!';
    final confirmTitle = permissionRequired
        ? 'Approval Pending'
        : _isCheckIn
        ? 'Check-in Confirmed'
        : 'Check-Out Confirmed';
    final confirmMessage = permissionRequired
        ? '${result['message'] ?? 'Your request is waiting for TL or HR approval.'}'
        : _isCheckIn
        ? 'Your attendance has been recorded successfully.'
        : 'You have successfully checked out.';
    final statusText = '${result['status'] ?? _policyStatus ?? 'Present'}';
    final statusLower = statusText.toLowerCase();
    final statusColor =
        statusLower.contains('half') || statusLower.contains('late')
        ? EmployeeColors.gold
        : EmployeeColors.green;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: EmployeeColors.green, width: 3),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 58,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            successText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EmployeeColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            time,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withAlpha(110)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!_isCheckIn) ...[
            const SizedBox(height: 24),
            const Text(
              'Working Hours',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              '${result['working_hours'] ?? '--'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ResultMetric(
                    label: 'Late Entry',
                    value: '${result['late_entry'] ?? '--'}',
                    color: EmployeeColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultMetric(
                    label: 'Overtime',
                    value: '${result['overtime'] ?? '00h 00m'}',
                    color: EmployeeColors.green,
                  ),
                ),
              ],
            ),
          ],
          if (_isCheckIn) ...[
            const SizedBox(height: 22),
            _LocationRows(result: result, gpsAddress: _gpsAddress),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EmployeeColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              onPressed: _finish,
              child: const Text('View Details'),
            ),
          ),
          const SizedBox(height: 18),
          _InfoPopupCard(
            color: EmployeeColors.gold,
            icon: Icons.warning_rounded,
            title: confirmTitle,
            message: confirmMessage,
            actionText: 'OK',
            onAction: _finish,
          ),
        ],
      ),
    );
  }
}

class _LocationRows extends StatelessWidget {
  final Map<String, dynamic> result;
  final String? gpsAddress;

  const _LocationRows({required this.result, required this.gpsAddress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LocationRow(
          icon: Icons.gps_fixed_rounded,
          label: 'Exact GPS coordinates',
          value:
              '${result['latitude'] ?? '--'}, ${result['longitude'] ?? '--'}',
        ),
        _LocationRow(
          icon: Icons.location_on_rounded,
          label: 'Nearest mapped address',
          value: gpsAddress?.trim().isNotEmpty == true
              ? gpsAddress!.trim()
              : 'Address lookup unavailable',
        ),
        _LocationRow(
          icon: Icons.my_location_rounded,
          label: 'Latitude',
          value: '${result['latitude'] ?? '--'}',
        ),
        _LocationRow(
          icon: Icons.my_location_rounded,
          label: 'Longitude',
          value: '${result['longitude'] ?? '--'}',
        ),
        _LocationRow(
          icon: Icons.adjust_rounded,
          label: 'Accuracy',
          value: _accuracyText(result['accuracy']),
        ),
      ],
    );
  }

  String _accuracyText(dynamic value) {
    final text = '${value ?? '--'}'.trim();
    return text.toLowerCase().contains('meter') ? text : '$text meters';
  }
}

class _LiveGpsCard extends StatelessWidget {
  final Position position;
  final String? address;
  final bool refreshing;
  final VoidCallback onRefresh;

  const _LiveGpsCard({
    required this.position,
    required this.address,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = position.accuracy;
    final accuracyColor = accuracy <= _targetGpsAccuracyMeters
        ? EmployeeColors.green
        : EmployeeColors.gold;
    final mappedAddress = address?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThemeConfig.getCardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accuracyColor.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gps_fixed_rounded, color: accuracyColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Exact GPS captured',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accuracyColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '±${accuracy.toStringAsFixed(1)} m',
                  style: TextStyle(
                    color: accuracyColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            '${position.latitude.toStringAsFixed(7)}, ${position.longitude.toStringAsFixed(7)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            mappedAddress.isEmpty
                ? 'Nearest mapped address is unavailable.'
                : 'Nearest mapped address: $mappedAddress',
            style: TextStyle(
              color: ThemeConfig.getTextSecondary(context),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh exact GPS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewFrame extends StatelessWidget {
  final CameraController controller;

  const _CameraPreviewFrame({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    final previewAspect = previewSize.height / previewSize.width;
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewAspect,
            height: 1,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: EmployeeColors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPopupCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const _InfoPopupCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF061B2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withAlpha(190)),
              ),
              child: Text(actionText),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(90),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
