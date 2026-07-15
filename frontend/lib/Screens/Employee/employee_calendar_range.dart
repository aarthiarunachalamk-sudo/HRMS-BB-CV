import 'package:flutter/material.dart';

import 'employee_shared.dart';

enum EmployeeCalendarMode { weekly, monthly, yearly }

class EmployeeDateRange {
  final DateTime from;
  final DateTime to;

  const EmployeeDateRange({required this.from, required this.to});
}

class EmployeeCalendarRangePicker extends StatelessWidget {
  final EmployeeCalendarMode mode;
  final DateTime visibleMonth;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<EmployeeCalendarMode> onModeChanged;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const EmployeeCalendarRangePicker({
    super.key,
    required this.mode,
    required this.visibleMonth,
    required this.fromDate,
    required this.toDate,
    required this.onModeChanged,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeeCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _ModeButton(
                label: 'Weekly',
                selected: mode == EmployeeCalendarMode.weekly,
                onTap: () => onModeChanged(EmployeeCalendarMode.weekly),
              ),
              _ModeButton(
                label: 'Monthly',
                selected: mode == EmployeeCalendarMode.monthly,
                onTap: () => onModeChanged(EmployeeCalendarMode.monthly),
              ),
              _ModeButton(
                label: 'Yearly',
                selected: mode == EmployeeCalendarMode.yearly,
                onTap: () => onModeChanged(EmployeeCalendarMode.yearly),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => onMonthChanged(
                  DateTime(visibleMonth.year, visibleMonth.month - 1),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  mode == EmployeeCalendarMode.yearly
                      ? '${visibleMonth.year}'
                      : '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onMonthChanged(
                  DateTime(visibleMonth.year, visibleMonth.month + 1),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (mode == EmployeeCalendarMode.yearly)
            _YearGrid(
              year: visibleMonth.year,
              fromDate: fromDate,
              toDate: toDate,
              onDateSelected: onDateSelected,
            )
          else
            _MonthGrid(
              visibleMonth: visibleMonth,
              onlyCurrentWeek: mode == EmployeeCalendarMode.weekly,
              fromDate: fromDate,
              toDate: toDate,
              onDateSelected: onDateSelected,
            ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
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
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? EmployeeColors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white.withAlpha(28)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime visibleMonth;
  final bool onlyCurrentWeek;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthGrid({
    required this.visibleMonth,
    required this.onlyCurrentWeek,
    required this.fromDate,
    required this.toDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = onlyCurrentWeek
        ? _weekDays(DateTime.now())
        : _monthDays(visibleMonth);
    return Column(
      children: [
        const Row(
          children: [
            _Weekday('M'),
            _Weekday('T'),
            _Weekday('W'),
            _Weekday('T'),
            _Weekday('F'),
            _Weekday('S'),
            _Weekday('S'),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: days
              .map(
                (day) => _DateCell(
                  date: day,
                  inMonth: day.month == visibleMonth.month || onlyCurrentWeek,
                  selected: _isInRange(day, fromDate, toDate),
                  isRangeEnd: _sameDay(day, fromDate) || _sameDay(day, toDate),
                  onTap: () => onDateSelected(day),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  List<DateTime> _monthDays(DateTime month) {
    final first = DateTime(month.year, month.month);
    final start = first.subtract(Duration(days: first.weekday - 1));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  List<DateTime> _weekDays(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }
}

class _YearGrid extends StatelessWidget {
  final int year;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTime> onDateSelected;

  const _YearGrid({
    required this.year,
    required this.fromDate,
    required this.toDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.65,
      children: List.generate(12, (index) {
        final month = DateTime(year, index + 1);
        final monthEnd = DateTime(year, index + 2, 0);
        final selected =
            fromDate != null &&
            toDate != null &&
            !monthEnd.isBefore(_dateOnly(fromDate!)) &&
            !month.isAfter(_dateOnly(toDate!));
        return InkWell(
          onTap: () => onDateSelected(month),
          borderRadius: BorderRadius.circular(7),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? EmployeeColors.blue.withAlpha(90)
                  : const Color(0xFF061B2D),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected
                    ? EmployeeColors.blue
                    : Colors.white.withAlpha(24),
              ),
            ),
            child: Text(
              EmployeeCalendarRangePicker._monthName(index + 1).substring(0, 3),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        );
      }),
    );
  }
}

class _Weekday extends StatelessWidget {
  final String label;

  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  final DateTime date;
  final bool inMonth;
  final bool selected;
  final bool isRangeEnd;
  final VoidCallback onTap;

  const _DateCell({
    required this.date,
    required this.inMonth,
    required this.selected,
    required this.isRangeEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? EmployeeColors.blue.withAlpha(isRangeEnd ? 210 : 75)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isRangeEnd
                ? EmployeeColors.blue
                : Colors.white.withAlpha(18),
          ),
        ),
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: inMonth ? Colors.white : Colors.white30,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

bool _isInRange(DateTime date, DateTime? from, DateTime? to) {
  if (from == null) return false;
  final current = _dateOnly(date);
  final start = _dateOnly(from);
  final end = _dateOnly(to ?? from);
  return !current.isBefore(start) && !current.isAfter(end);
}

bool _sameDay(DateTime a, DateTime? b) {
  if (b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
