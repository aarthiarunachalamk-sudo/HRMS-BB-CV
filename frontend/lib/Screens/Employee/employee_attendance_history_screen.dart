import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_module_tabs.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

import 'employee_calendar_range.dart';
import 'employee_overtime_flow_screen.dart';
import 'employee_service.dart';
import 'employee_shared.dart';

class EmployeeAttendanceHistoryScreen extends StatefulWidget {
  final String userId;
  final EmployeeService service;
  final Map<String, dynamic> profile;
  final String? profileImagePath;

  const EmployeeAttendanceHistoryScreen({
    super.key,
    required this.userId,
    required this.service,
    this.profile = const {},
    this.profileImagePath,
  });

  @override
  State<EmployeeAttendanceHistoryScreen> createState() =>
      _EmployeeAttendanceHistoryScreenState();
}

class _EmployeeAttendanceHistoryScreenState
    extends State<EmployeeAttendanceHistoryScreen> {
  EmployeeCalendarMode _mode = EmployeeCalendarMode.weekly;
  late DateTime _selectedDate;
  late DateTime _fromDate;
  late DateTime _toDate;
  List<Map<String, dynamic>> _records = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _setRangeForMode(_mode, anchor: _selectedDate, shouldLoad: false);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await widget.service.fetchAttendanceHistory(
        widget.userId,
        _fromDate,
        _toDate,
      );
      if (!mounted) return;
      // Keep records and print resolved selfie URLs for debugging image loads
      for (final r in records) {
        try {
          final raw = '${r['check_in_selfie'] ?? ''}';
          final resolved = _attendanceImageUrl(raw);
          // Use debugPrint so release builds omit verbose logs when Flutter
          // strips debugPrint calls in release mode.
          debugPrint('Attendance selfie raw: $raw -> resolved: $resolved');
        } catch (_) {}
      }
      setState(() {
        _records = records;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _records = const [];
        _error = 'Attendance history not reachable.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setMode(EmployeeCalendarMode mode) {
    setState(() => _mode = mode);
    _setRangeForMode(mode, anchor: _selectedDate);
  }

  void _shiftRange(int direction) {
    final anchor = switch (_mode) {
      EmployeeCalendarMode.weekly => _selectedDate.add(
        Duration(days: direction * 7),
      ),
      EmployeeCalendarMode.monthly => DateTime(
        _selectedDate.year,
        _selectedDate.month + direction,
        _selectedDate.day,
      ),
      EmployeeCalendarMode.yearly => DateTime(
        _selectedDate.year + direction,
        _selectedDate.month,
        _selectedDate.day,
      ),
    };
    _setRangeForMode(_mode, anchor: anchor);
  }

  void _setRangeForMode(
    EmployeeCalendarMode mode, {
    required DateTime anchor,
    bool shouldLoad = true,
  }) {
    setState(() {
      _selectedDate = _dateOnly(anchor);
      if (mode == EmployeeCalendarMode.weekly) {
        _fromDate = _dateOnly(
          anchor.subtract(Duration(days: anchor.weekday - 1)),
        );
        _toDate = _fromDate.add(const Duration(days: 6));
      } else if (mode == EmployeeCalendarMode.monthly) {
        _fromDate = DateTime(anchor.year, anchor.month, 1);
        _toDate = DateTime(anchor.year, anchor.month + 1, 0);
      } else {
        _fromDate = DateTime(anchor.year, 1, 1);
        _toDate = DateTime(anchor.year, 12, 31);
      }
    });
    if (shouldLoad) _load();
  }

  void _selectDate(DateTime date) {
    if (_mode == EmployeeCalendarMode.weekly) {
      setState(() => _selectedDate = _dateOnly(date));
      return;
    }
    _setRangeForMode(_mode, anchor: date);
  }

  List<Map<String, dynamic>> _recordsForSelection() {
    return _records.where((record) {
      final date = _parseDate('${record['date'] ?? ''}');
      if (date == null) return false;
      return switch (_mode) {
        EmployeeCalendarMode.weekly => _sameDay(date, _selectedDate),
        EmployeeCalendarMode.monthly =>
          date.year == _selectedDate.year && date.month == _selectedDate.month,
        EmployeeCalendarMode.yearly => date.year == _selectedDate.year,
      };
    }).toList();
  }

  Map<String, dynamic>? _recordForSelection() {
    final selectedRecords = _recordsForSelection();
    if (selectedRecords.isEmpty) return null;
    selectedRecords.sort((a, b) => '${b['date']}'.compareTo('${a['date']}'));
    return selectedRecords.first;
  }

  @override
  Widget build(BuildContext context) {
    final selectedRecord = _recordForSelection();
    final bg = ThemeConfig.getBgStart(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 22),
          child: Column(
            children: [
              _HistoryHeader(onRefresh: _load),
              const SizedBox(height: 12),
              _ModeTabs(mode: _mode, onChanged: _setMode),
              const SizedBox(height: 12),
              _DateStrip(
                mode: _mode,
                fromDate: _fromDate,
                toDate: _toDate,
                selectedDate: _selectedDate,
                onPrevious: () => _shiftRange(-1),
                onNext: () => _shiftRange(1),
                onSelectDate: _selectDate,
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 46),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _EmptyState(message: _error!)
              else if (_records.isEmpty || selectedRecord == null)
                const _EmptyState(message: 'No data found')
              else ...[
                _ReferenceAttendanceCard(
                  userId: widget.userId,
                  profile: widget.profile,
                  profileImagePath: widget.profileImagePath,
                  record: selectedRecord,
                ),
                const SizedBox(height: 14),
                _AttendanceRows(
                  records: _records,
                  selectedDate: _selectedDate,
                  onSelectDate: _selectDate,
                  onOpenRecord: (record) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EmployeeOvertimeDateDetailsScreen(record: record),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HistoryHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final text = ThemeConfig.getTextPrimary(context);
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _HeaderButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Text(
            'Attendance History',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _HeaderButton(
              icon: Icons.calendar_month_rounded,
              onTap: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final text = ThemeConfig.getTextPrimary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: EmployeeColors.blue.withAlpha(90)),
        ),
        child: Icon(icon, color: text, size: 22),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final EmployeeCalendarMode mode;
  final ValueChanged<EmployeeCalendarMode> onChanged;

  const _ModeTabs({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppModuleTabs<EmployeeCalendarMode>(
      tabs: const [
        AppModuleTab(EmployeeCalendarMode.weekly, 'Weekly'),
        AppModuleTab(EmployeeCalendarMode.monthly, 'Monthly'),
        AppModuleTab(EmployeeCalendarMode.yearly, 'Yearly'),
      ],
      selected: mode,
      onSelected: onChanged,
    );
  }
}

class _HistoryAvatar extends StatelessWidget {
  final String title;
  final String? filePath;

  const _HistoryAvatar({required this.title, this.filePath});

  @override
  Widget build(BuildContext context) {
    final text = ThemeConfig.getTextPrimary(context);
    return CircleAvatar(
      radius: 28,
      backgroundColor: EmployeeColors.blue.withAlpha(45),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: EmployeeColors.blue.withAlpha(45),
        backgroundImage: _imageProvider,
        child: _imageProvider == null
            ? Text(
                title.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }

  ImageProvider? get _imageProvider {
    final path = filePath?.trim() ?? '';
    final provider = employeeProfileImageProvider(path);
    return provider == null
        ? null
        : ResizeImage(provider, width: 220, height: 220);
  }
}

class _DateStrip extends StatelessWidget {
  final EmployeeCalendarMode mode;
  final DateTime fromDate;
  final DateTime toDate;
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDate;

  const _DateStrip({
    required this.mode,
    required this.fromDate,
    required this.toDate,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final dates = _stripDates();
    return EmployeeCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              _RoundArrow(icon: Icons.chevron_left_rounded, onTap: onPrevious),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _rangeTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _RoundArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dates
                  .map(
                    (date) => SizedBox(
                      width: 54,
                      child: _DateBox(
                        date: date,
                        mode: mode,
                        selectedDate: selectedDate,
                        selected: _sameDay(date, selectedDate),
                        onTap: () => onSelectDate(date),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String get _rangeTitle {
    if (mode == EmployeeCalendarMode.yearly) return '${fromDate.year}';
    if (mode == EmployeeCalendarMode.monthly) {
      return '${_monthName(fromDate.month)} ${fromDate.year}';
    }
    return '${_dayMonth(fromDate)} - ${_dayMonth(toDate)}';
  }

  List<DateTime> _stripDates() {
    if (mode == EmployeeCalendarMode.weekly) {
      return List.generate(7, (index) => fromDate.add(Duration(days: index)));
    }
    if (mode == EmployeeCalendarMode.monthly) {
      return List.generate(
        12,
        (index) => DateTime(fromDate.year, index + 1, 1),
      );
    }
    return List.generate(
      7,
      (index) => DateTime(fromDate.year - 3 + index, 1, 1),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF092A56),
          shape: BoxShape.circle,
          border: Border.all(color: EmployeeColors.blue.withAlpha(70)),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final DateTime date;
  final EmployeeCalendarMode mode;
  final DateTime selectedDate;
  final bool selected;
  final VoidCallback onTap;

  const _DateBox({
    required this.date,
    required this.mode,
    required this.selectedDate,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      EmployeeCalendarMode.weekly => _weekday(date.weekday).toUpperCase(),
      EmployeeCalendarMode.monthly => _monthName(
        date.month,
      ).substring(0, 3).toUpperCase(),
      EmployeeCalendarMode.yearly => 'YEAR',
    };
    final value = switch (mode) {
      EmployeeCalendarMode.weekly => date.day.toString().padLeft(2, '0'),
      EmployeeCalendarMode.monthly => _monthName(date.month).substring(0, 3),
      EmployeeCalendarMode.yearly => '${date.year}',
    };
    final selectedForMode = switch (mode) {
      EmployeeCalendarMode.weekly => selected,
      EmployeeCalendarMode.monthly =>
        date.year == selectedDate.year && date.month == selectedDate.month,
      EmployeeCalendarMode.yearly => date.year == selectedDate.year,
    };
    final muted = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final markerColor = date.weekday == DateTime.saturday
        ? const Color(0xFFFFC928)
        : date.weekday == DateTime.sunday
        ? EmployeeColors.red
        : muted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selectedForMode ? Colors.white : markerColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 53,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selectedForMode ? EmployeeColors.blue : cardBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: EmployeeColors.blue.withAlpha(45)),
                boxShadow: selectedForMode
                    ? [
                        BoxShadow(
                          color: EmployeeColors.blue.withAlpha(70),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: selectedForMode ? Colors.white : markerColor,
                      fontSize: mode == EmployeeCalendarMode.weekly ? 19 : 12,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (mode == EmployeeCalendarMode.weekly) ...[
                    const SizedBox(height: 3),
                    Text(
                      _monthName(date.month).substring(0, 3),
                      style: TextStyle(
                        color: selectedForMode ? Colors.white : Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceAttendanceCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> profile;
  final String? profileImagePath;
  final Map<String, dynamic> record;

  const _ReferenceAttendanceCard({
    required this.userId,
    required this.profile,
    this.profileImagePath,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final status = '${record['status'] ?? 'Present'}';
    final color = _attendanceStatusColor(status);
    final date = _parseDate('${record['date']}') ?? DateTime.now();
    final name = _profileValue(profile, ['name', 'full_name', 'first_name']);
    final employeeId = _profileValue(profile, [
      'employee_id',
      'emp_id',
    ], userId);
    final designation = _profileValue(profile, [
      'designation',
      'role',
      'department',
    ], 'Employee');
    final title = name.isEmpty ? 'Employee' : name;

    return EmployeeCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HistoryAvatar(title: title, filePath: profileImagePath),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$employeeId  -  $designation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(status: status, color: color),
                  const SizedBox(height: 6),
                  _DateChip(date: date),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withAlpha(18), height: 1),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 9, child: _TimePanel(record: record)),
                  _TallDivider(),
                  Expanded(flex: 11, child: _LocationPanel(record: record)),
                  _TallDivider(),
                  Expanded(flex: 12, child: _SelfieProof(record: record)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimePanel extends StatelessWidget {
  final Map<String, dynamic> record;

  const _TimePanel({required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.schedule_rounded,
          label: 'Attendance Time',
        ),
        const SizedBox(height: 18),
        _TimeRow(label: 'Check In', value: '${record['check_in'] ?? '--:--'}'),
        const SizedBox(height: 14),
        _TimeRow(
          label: 'Check Out',
          value: '${record['check_out'] ?? '--:--'}',
        ),
        const SizedBox(height: 14),
        _TimeRow(
          label: 'Working Hours',
          value: '${record['working_hours'] ?? '--'}',
          valueColor: Colors.white,
        ),
        const SizedBox(height: 14),
        _TimeRow(
          label: 'Late Entry',
          value: '${record['late_entry'] ?? '--'}',
          valueColor: EmployeeColors.gold,
        ),
        const SizedBox(height: 14),
        _TimeRow(
          label: 'Overtime',
          value: '${record['overtime'] ?? '00h 00m'}',
          valueColor: EmployeeColors.green,
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TimeRow({
    required this.label,
    required this.value,
    this.valueColor = EmployeeColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LocationPanel extends StatelessWidget {
  final Map<String, dynamic> record;

  const _LocationPanel({required this.record});

  @override
  Widget build(BuildContext context) {
    final latitude = '${record['latitude'] ?? ''}';
    final longitude = '${record['longitude'] ?? ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.location_on_outlined,
          label: 'Location',
        ),
        const SizedBox(height: 12),
        _MapPreview(latitude: latitude, longitude: longitude),
        const SizedBox(height: 8),
        _MapTile(latitude: latitude, longitude: longitude),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  final String latitude;
  final String longitude;

  const _MapPreview({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        double.tryParse(latitude.trim()) != null &&
        double.tryParse(longitude.trim()) != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 78,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0B263E),
          border: Border.all(color: Colors.white.withAlpha(35)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _MapPreviewPainter()),
            Center(
              child: Icon(
                Icons.location_on_rounded,
                color: hasLocation ? EmployeeColors.red : Colors.white38,
                size: 30,
              ),
            ),
            if (hasLocation)
              Positioned(
                left: 12,
                bottom: 10,
                child: Text(
                  '${double.parse(latitude).toStringAsFixed(4)}, ${double.parse(longitude).toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = EmployeeColors.blue.withAlpha(60)
      ..strokeWidth = 2;
    final thinPaint = Paint()
      ..color = Colors.white.withAlpha(22)
      ..strokeWidth = 1;

    for (var i = 0; i < 6; i++) {
      final y = size.height * (i + 1) / 7;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 22), thinPaint);
    }
    for (var i = 0; i < 5; i++) {
      final x = size.width * (i + 1) / 6;
      canvas.drawLine(Offset(x, 0), Offset(x - 24, size.height), thinPaint);
    }
    canvas.drawLine(
      Offset(size.width * .18, size.height),
      Offset(size.width * .82, 0),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * .62),
      Offset(size.width, size.height * .36),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ignore: unused_element
class _ExpandedAttendanceCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> record;

  const _ExpandedAttendanceCard({
    required this.userId,
    required this.profile,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final status = '${record['status'] ?? 'Present'}';
    final color = _attendanceStatusColor(status);
    final date = _parseDate('${record['date']}') ?? DateTime.now();
    final name = _profileValue(profile, ['name', 'full_name', 'first_name']);
    final employeeId = _profileValue(profile, [
      'employee_id',
      'emp_id',
    ], userId);
    final designation = _profileValue(profile, [
      'designation',
      'role',
      'department',
    ], 'Employee');
    final title = name.isEmpty ? 'Employee' : name;

    return EmployeeCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: EmployeeColors.blue.withAlpha(45),
                child: Text(
                  title.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$employeeId  •  $designation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusPill(status: status.toUpperCase(), color: color),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _DateChip(date: date),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 26,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withAlpha(18), height: 1),
          const SizedBox(height: 12),
          _AttendanceDetails(
            record: record,
            status: status,
            statusColor: color,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withAlpha(18), height: 1),
          const SizedBox(height: 12),
          _LocationDetails(record: record),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withAlpha(18), height: 1),
          const SizedBox(height: 12),
          _SelfieProof(record: record),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusPill({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;

  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF082A52),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: EmployeeColors.blue,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            _displayDate(date),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: EmployeeColors.blue, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: EmployeeColors.blue,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AttendanceDetails extends StatelessWidget {
  final Map<String, dynamic> record;
  final String status;
  final Color statusColor;

  const _AttendanceDetails({
    required this.record,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.schedule_rounded,
          label: 'ATTENDANCE DETAILS',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCell(
                icon: Icons.login_rounded,
                label: 'CHECK IN',
                value: '${record['check_in'] ?? '--:--'}',
                color: EmployeeColors.green,
              ),
            ),
            _SmallDivider(),
            Expanded(
              child: _MetricCell(
                icon: Icons.logout_rounded,
                label: 'CHECK OUT',
                value: '${record['check_out'] ?? '--:--'}',
                color: EmployeeColors.red,
              ),
            ),
            _SmallDivider(),
            Expanded(
              child: _MetricCell(
                icon: Icons.access_time_rounded,
                label: 'WORKING HOURS',
                value: '${record['working_hours'] ?? '--'}',
                color: EmployeeColors.purple,
              ),
            ),
            _SmallDivider(),
            Expanded(
              child: _MetricCell(
                icon: Icons.verified_user_outlined,
                label: 'STATUS',
                value: status,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCell(
                icon: Icons.warning_amber_rounded,
                label: 'LATE ENTRY',
                value: '${record['late_entry'] ?? '--'}',
                color: EmployeeColors.gold,
              ),
            ),
            _SmallDivider(),
            Expanded(
              child: _MetricCell(
                icon: Icons.timer_outlined,
                label: 'OVERTIME',
                value: '${record['overtime'] ?? '00h 00m'}',
                color: EmployeeColors.green,
              ),
            ),
            _SmallDivider(),
            Expanded(
              child: _MetricCell(
                icon: Icons.restaurant_rounded,
                label: 'LUNCH',
                value: '${record['lunch_time'] ?? '01:00 PM - 02:00 PM'}',
                color: EmployeeColors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationDetails extends StatelessWidget {
  final Map<String, dynamic> record;

  const _LocationDetails({required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.location_on_outlined,
          label: 'LOCATION (GPS)',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PlainMetric(
                label: 'LATITUDE',
                value: '${record['latitude'] ?? '--'}',
              ),
            ),
            _SmallDivider(),
            Expanded(
              child: _PlainMetric(
                label: 'LONGITUDE',
                value: '${record['longitude'] ?? '--'}',
              ),
            ),
            _SmallDivider(),
            Expanded(
              child: _PlainMetric(
                label: 'ACCURACY',
                value: _accuracyText(record['accuracy']),
              ),
            ),
            const SizedBox(width: 8),
            _MapTile(
              latitude: '${record['latitude'] ?? ''}',
              longitude: '${record['longitude'] ?? ''}',
            ),
          ],
        ),
      ],
    );
  }
}

class _SelfieProof extends StatelessWidget {
  final Map<String, dynamic> record;

  const _SelfieProof({required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.camera_alt_outlined,
          label: 'SELFIE PROOF',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SelfieBox(
                label: 'Check-In Selfie',
                time: '${record['check_in'] ?? '--:--'}',
                url: '${record['check_in_selfie'] ?? ''}',
                latitude: '${record['latitude'] ?? ''}',
                longitude: '${record['longitude'] ?? ''}',
                accuracy: _accuracyText(record['accuracy']),
                color: EmployeeColors.green,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SelfieBox(
                label: 'Check-Out Selfie',
                time: '${record['check_out'] ?? '--:--'}',
                url: '${record['check_out_selfie'] ?? ''}',
                latitude: '${record['latitude'] ?? ''}',
                longitude: '${record['longitude'] ?? ''}',
                accuracy: _accuracyText(record['accuracy']),
                color: EmployeeColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _PlainMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PlainMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _MapTile extends StatelessWidget {
  static const MethodChannel _channel = MethodChannel('hrms/location');

  final String latitude;
  final String longitude;

  const _MapTile({required this.latitude, required this.longitude});

  bool get _hasLocation =>
      double.tryParse(latitude.trim()) != null &&
      double.tryParse(longitude.trim()) != null;

  Future<void> _openMap(BuildContext context) async {
    if (!_hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available for this record')),
      );
      return;
    }

    try {
      final opened = await _channel.invokeMethod<bool>('openMap', {
        'latitude': double.parse(latitude.trim()),
        'longitude': double.parse(longitude.trim()),
      });
      if (opened != true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open map on this device')),
        );
      }
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to open map')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openMap(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF06213D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (_hasLocation ? EmployeeColors.blue : Colors.white30)
                .withAlpha(90),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              color: _hasLocation ? EmployeeColors.blue : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'View Map',
              style: TextStyle(
                color: _hasLocation ? EmployeeColors.blue : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelfieImage extends StatelessWidget {
  final String imageUrl;
  final Color color;

  const _SelfieImage({required this.imageUrl, required this.color});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _SelfiePlaceholder(color: color);

    return Image(
      image: ResizeImage(
        NetworkImage(imageUrl, headers: const {'Accept': 'image/*'}),
        width: 520,
        height: 520,
      ),
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
              value: progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => _SelfieError(url: imageUrl, color: color),
    );
  }
}

class _SelfieBox extends StatelessWidget {
  final String label;
  final String time;
  final String url;
  final String latitude;
  final String longitude;
  final String accuracy;
  final Color color;

  const _SelfieBox({
    required this.label,
    required this.time,
    required this.url,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _attendanceImageUrl(url);
    final hasImage = imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: hasImage
              ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _SelfieViewer(
                      title: label,
                      imageUrl: imageUrl,
                      latitude: latitude,
                      longitude: longitude,
                      accuracy: accuracy,
                      color: color,
                    ),
                  ),
                )
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selfie image not available.'),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: EmployeeColors.blue.withAlpha(32),
                    child: hasImage
                        ? _SelfieImage(imageUrl: imageUrl, color: color)
                        : _SelfiePlaceholder(color: color),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white70,
                            size: 9,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        size: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelfieError extends StatelessWidget {
  final String url;
  final Color color;

  const _SelfieError({required this.url, required this.color});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final label = uri == null ? 'Image not found' : uri.toString();
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: color.withAlpha(170)),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SelfieViewer extends StatelessWidget {
  static const MethodChannel _channel = MethodChannel('hrms/location');

  final String title;
  final String imageUrl;
  final String latitude;
  final String longitude;
  final String accuracy;
  final Color color;

  const _SelfieViewer({
    required this.title,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.color,
  });

  bool get _hasLocation =>
      double.tryParse(latitude.trim()) != null &&
      double.tryParse(longitude.trim()) != null;

  Future<void> _openMap(BuildContext context) async {
    if (!_hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geo location is not available.')),
      );
      return;
    }

    try {
      final opened = await _channel.invokeMethod<bool>('openMap', {
        'latitude': double.parse(latitude.trim()),
        'longitude': double.parse(longitude.trim()),
      });
      if (opened != true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open map on this device.')),
        );
      }
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to open map.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: AppBarLogoTitle(title: title),
        actions: [
          IconButton(
            tooltip: 'View Map',
            onPressed: () => _openMap(context),
            icon: const Icon(Icons.map_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.6,
          maxScale: 4,
          child: Center(
            child: Image.network(
              imageUrl,
              headers: const {'Accept': 'image/*'},
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return CircularProgressIndicator(
                  color: color,
                  value: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!,
                );
              },
              errorBuilder: (_, _, _) =>
                  _SelfieError(url: imageUrl, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelfiePlaceholder extends StatelessWidget {
  final Color color;

  const _SelfiePlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.person_rounded, color: color.withAlpha(150), size: 42),
    );
  }
}

class _AttendanceRows extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<Map<String, dynamic>> onOpenRecord;

  const _AttendanceRows({
    required this.records,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onOpenRecord,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeeCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: records.map((record) {
          final date = _parseDate('${record['date']}') ?? DateTime.now();
          final status = '${record['status'] ?? 'Present'}';
          final color = _attendanceStatusColor(status);
          final selected = _sameDay(date, selectedDate);

          return InkWell(
            onTap: () {
              onSelectDate(date);
              onOpenRecord(record);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: selected ? EmployeeColors.blue.withAlpha(18) : null,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withAlpha(14)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: EmployeeColors.blue,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayDateWithWeekday(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SmallDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withAlpha(18),
    );
  }
}

class _TallDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 135,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withAlpha(20),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return EmployeeCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime? _parseDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _dayMonth(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month).substring(0, 3)} ${date.year}';
}

String _displayDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month).substring(0, 3)} ${date.year}';
}

String _displayDateWithWeekday(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month).substring(0, 3)} ${date.year}, ${_weekday(date.weekday)}';
}

String _monthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[month - 1];
}

String _weekday(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[weekday - 1];
}

String _profileValue(
  Map<String, dynamic> profile,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = '${profile[key] ?? ''}'.trim();
    if (value.isNotEmpty && value != 'null') return value;
  }
  return fallback;
}

Color _attendanceStatusColor(String status) {
  final value = status.toLowerCase();
  if (value.contains('absent') || value.contains('reject')) {
    return EmployeeColors.red;
  }
  if (value.contains('half')) return EmployeeColors.gold;
  if (value.contains('off')) return EmployeeColors.blue;
  return EmployeeColors.green;
}

String _accuracyText(Object? value) {
  final text = '${value ?? '--'}'.trim();
  if (text.isEmpty || text == 'null' || text == '--') return '--';
  return text.toLowerCase().contains('m') ? text : '$text m';
}

String _attendanceImageUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == 'null') return '';
  if (trimmed.startsWith('http')) return _normalizeBackendUrl(trimmed);
  if (trimmed.startsWith('/')) return _backendOrigin() + trimmed;
  if (trimmed.startsWith('attendance/')) {
    return '${_backendOrigin()}/media/$trimmed';
  }
  return '${_backendOrigin()}/media/$trimmed';
}

String _backendOrigin() {
  final uri = Uri.parse(ApiConfig.baseUrl);
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port';
}

String _normalizeBackendUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) return value;
  if (uri.host != 'localhost' &&
      uri.host != '127.0.0.1' &&
      uri.host != '0.0.0.0') {
    return value;
  }
  return _backendOrigin() + uri.path;
}
