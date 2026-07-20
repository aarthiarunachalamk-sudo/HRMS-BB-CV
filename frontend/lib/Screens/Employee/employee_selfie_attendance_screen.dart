import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'employee_service.dart';
import 'employee_shared.dart';

enum EmployeeAttendanceAction { checkIn, checkOut }

const int _fullDayCheckInCutoffHour = 12;
const double _selfiePreviewAspectRatio = .76;

class EmployeeSelfieAttendanceScreen extends StatefulWidget {
  final String userId;
  final EmployeeService service;
  final EmployeeAttendanceAction action;

  const EmployeeSelfieAttendanceScreen({
    super.key,
    required this.userId,
    required this.service,
    required this.action,
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

  String? _capturedPath;
  Position? _position;
  Map<String, dynamic>? _result;
  String? _error;
  bool _submitting = false;
  bool _processingCapture = false;
  bool _loadingLocation = true;
  bool _openingLocationSettings = false;
  bool _locationPermissionDeniedForever = false;
  String? _policyStatus;

  bool get _isCheckIn => widget.action == EmployeeAttendanceAction.checkIn;
  bool get _locationReady => _position != null;

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
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
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

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
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

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _loadingLocation = false;
        _error = null;
      });
      await _initCamera();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _error = 'Unable to capture GPS location.';
        });
      }
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
    if (_position == null) {
      await _loadLocation();
      if (_position == null) return;
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
      final watermarkedPath = await _burnWatermark(rawFile.path);
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

  Future<String> _burnWatermark(String rawPath) async {
    final bytes = await File(rawPath).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return rawPath;

    // Correct orientation using EXIF data captured by the camera sensor.
    decoded = img.bakeOrientation(decoded);

    final watermarked = _drawWatermark(decoded, _position, DateTime.now());

    final directory = await getTemporaryDirectory();
    final outPath =
        '${directory.path}/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(watermarked, quality: 85));
    return outPath;
  }

  img.Image _drawWatermark(img.Image photo, Position? position, DateTime now) {
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

    final latitude = position?.latitude ?? 11.686539;
    final longitude = position?.longitude ?? 78.12028;

    final mapSize = (h * 0.14).round().clamp(76, 190) as int;
    final mapLeft = (w * 0.04).round();
    final mapTop = h - mapSize - (h * 0.02).round();
    _drawMiniMapStamp(photo, x: mapLeft, y: mapTop, size: mapSize);

    // Text block to the right of the map stamp.
    final textLeft = mapLeft + mapSize + (w * 0.04).round();
    int textY = mapTop + (h * 0.005).round();

    const place = 'Salem, Tamil Nadu, India';
    const address =
        '1550-4, Subbarayan Nagar, Jagir Ammapalayam, Salem, Tamil Nadu 636302, India';
    final latLong =
        'Lat ${latitude.toStringAsFixed(6)}\u00B0 Long ${longitude.toStringAsFixed(5)}\u00B0';
    final timestamp = _formatTimestamp(now);

    img.drawString(
      photo,
      place,
      font: img.arial24,
      x: textLeft,
      y: textY,
      color: img.ColorRgb8(255, 255, 255),
    );
    textY += 30;

    img.drawString(
      photo,
      address,
      font: img.arial14,
      x: textLeft,
      y: textY,
      color: img.ColorRgb8(255, 255, 255),
      wrap: true,
    );
    textY += 38;

    img.drawString(
      photo,
      latLong,
      font: img.arial14,
      x: textLeft,
      y: textY,
      color: img.ColorRgb8(255, 255, 255),
    );
    textY += 20;

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
      'mobile_timestamp': mobileTime.toIso8601String(),
      'timezone_offset_minutes': mobileTime.timeZoneOffset.inMinutes,
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
        children: [
          Text(
            waitingForLocation
                ? 'Enable geo location to open selfie camera'
                : 'Please capture your selfie',
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
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 3),
                    ),
                    child: (_submitting || _processingCapture)
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const SizedBox.shrink(),
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
    final time = _isCheckIn
        ? '${result['check_in'] ?? '--:--'}'
        : '${result['check_out'] ?? '--:--'}';
    final date = '${result['date'] ?? '17 Jun 2026, Monday'}';
    final successText = _isCheckIn
        ? 'Check-In Successful!'
        : 'Check-Out Successful!';
    final confirmTitle = _isCheckIn
        ? 'Check-in Confirmed'
        : 'Check-Out Confirmed';
    final confirmMessage = _isCheckIn
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
            style: const TextStyle(
              color: EmployeeColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            time,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 12)),
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
            _LocationRows(result: result),
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

  const _LocationRows({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LocationRow(
          icon: Icons.location_on_rounded,
          label: 'Location',
          value: 'Gandhipet, Hyd, India',
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
          value: '${result['accuracy'] ?? '--'} meters',
        ),
      ],
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
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
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(onPressed: onAction, child: Text(actionText)),
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
