import 'dart:math' as math;
import 'package:flutter/material.dart';

const _monthNames = <String>[
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

/// A Material calendar whose month and year are always independent controls.
class SeparatedCalendarDatePicker extends StatefulWidget {
  const SeparatedCalendarDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    this.selectableDayPredicate,
    this.onDisplayedMonthChanged,
    this.currentDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;
  final SelectableDayPredicate? selectableDayPredicate;
  final ValueChanged<DateTime>? onDisplayedMonthChanged;
  final DateTime? currentDate;

  @override
  State<SeparatedCalendarDatePicker> createState() =>
      _SeparatedCalendarDatePickerState();
}

class _SeparatedCalendarDatePickerState
    extends State<SeparatedCalendarDatePicker> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate);
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  void didUpdateWidget(SeparatedCalendarDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.initialDate, widget.initialDate)) {
      _selectedDate = _dateOnly(widget.initialDate);
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isAllowed(DateTime date) {
    final day = _dateOnly(date);
    final first = _dateOnly(widget.firstDate);
    final last = _dateOnly(widget.lastDate);
    return !day.isBefore(first) &&
        !day.isAfter(last) &&
        (widget.selectableDayPredicate?.call(day) ?? true);
  }

  bool _canShow(DateTime month) {
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    return !month.isBefore(firstMonth) && !month.isAfter(lastMonth);
  }

  void _showMonth(DateTime month) {
    if (_canShow(month)) {
      setState(() => _displayedMonth = month);
      widget.onDisplayedMonthChanged?.call(month);
    }
  }

  void _changeYear(int? year) {
    if (year == null) return;
    final minMonth = year == widget.firstDate.year ? widget.firstDate.month : 1;
    final maxMonth = year == widget.lastDate.year ? widget.lastDate.month : 12;
    final month = _displayedMonth.month.clamp(minMonth, maxMonth);
    _showMonth(DateTime(year, month));
  }

  void _changeMonth(int? month) {
    if (month == null) return;
    _showMonth(DateTime(_displayedMonth.year, month));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstWeekday = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    ).weekday;
    final leadingDays = firstWeekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final validMonths = <int>[
      for (var month = 1; month <= 12; month++)
        if (_canShow(DateTime(_displayedMonth.year, month))) month,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('month-${_displayedMonth.year}'),
                      value: _displayedMonth.month,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final month in validMonths)
                          DropdownMenuItem(
                            value: month,
                            child: Text(_monthNames[month - 1]),
                          ),
                      ],
                      onChanged: _changeMonth,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<int>(
                      value: _displayedMonth.year,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (
                          var year = widget.firstDate.year;
                          year <= widget.lastDate.year;
                          year++
                        )
                          DropdownMenuItem(value: year, child: Text('$year')),
                      ],
                      onChanged: _changeYear,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed:
                        _canShow(
                          DateTime(
                            _displayedMonth.year,
                            _displayedMonth.month - 1,
                          ),
                        )
                        ? () => _showMonth(
                            DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month - 1,
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed:
                        _canShow(
                          DateTime(
                            _displayedMonth.year,
                            _displayedMonth.month + 1,
                          ),
                        )
                        ? () => _showMonth(
                            DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month + 1,
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (final label in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              Expanded(child: Center(child: Text(label))),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.15,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final dayNumber = index - leadingDays + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(
              _displayedMonth.year,
              _displayedMonth.month,
              dayNumber,
            );
            final allowed = _isAllowed(date);
            final selected = DateUtils.isSameDay(date, _selectedDate);
            final today = DateUtils.isSameDay(
              date,
              widget.currentDate ?? DateTime.now(),
            );
            return Padding(
              padding: const EdgeInsets.all(2),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: allowed
                    ? () {
                        setState(() => _selectedDate = date);
                        widget.onDateChanged(date);
                      }
                    : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? theme.colorScheme.primary : null,
                    border: today && !selected
                        ? Border.all(color: theme.colorScheme.primary)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : allowed
                            ? null
                            : theme.disabledColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<DateTime?> showSeparatedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  DatePickerEntryMode? initialEntryMode,
  SelectableDayPredicate? selectableDayPredicate,
  TransitionBuilder? builder,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      DateTime selected = DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      );
      Widget dialog = StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(helpText ?? 'Select date'),
          contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
          content: LayoutBuilder(
            builder: (ctx, constraints) {
              final screenWidth = MediaQuery.of(dialogContext).size.width;
              final dialogWidth = math.min(380.0, screenWidth - 40.0);
              return SizedBox(
                width: dialogWidth,
                child: SeparatedCalendarDatePicker(
                  initialDate: selected,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  selectableDayPredicate: selectableDayPredicate,
                  onDateChanged: (value) => setDialogState(() => selected = value),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (builder != null) dialog = builder(dialogContext, dialog);
      return dialog;
    },
  );
}
