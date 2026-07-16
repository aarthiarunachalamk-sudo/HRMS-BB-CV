import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

import 'employee_shared.dart';

class EmployeeOvertimeDateDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const EmployeeOvertimeDateDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final calc = _OvertimeCalc.fromRecord(record);
    return _OvertimeScaffold(
      title: 'Date Details',
      child: Column(
        children: [
          _DateStatusHeader(calc: calc),
          const SizedBox(height: 12),
          EmployeeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FlowTitle('Attendance Summary'),
                const SizedBox(height: 14),
                _InfoLine('Check In', calc.checkIn),
                _InfoLine('Check Out', calc.checkOut),
                _InfoLine('Working Hours', calc.workingHours),
                _InfoLine('Late Entry', calc.lateEntry),
                _InfoLine('Overtime', calc.overtimeText),
                _InfoLine(
                  'Status',
                  calc.status,
                  valueColor: EmployeeColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FlowMenuTile(
            icon: Icons.badge_outlined,
            title: 'Attendance Details',
            subtitle: 'View check in/out, break, location',
            onTap: () => Navigator.pop(context),
          ),
          _FlowMenuTile(
            icon: Icons.calculate_outlined,
            title: 'Overtime Calculation',
            subtitle: 'View overtime summary',
            highlighted: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    EmployeeOvertimeCalculationScreen(record: record),
              ),
            ),
          ),
          _FlowMenuTile(
            icon: Icons.request_page_outlined,
            title: 'Overtime Request',
            subtitle: 'Submit overtime request',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeOvertimeRequestScreen(record: record),
              ),
            ),
          ),
          _FlowMenuTile(
            icon: Icons.approval_outlined,
            title: 'Approval Status',
            subtitle: 'View approval workflow',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeOvertimeApprovalScreen(record: record),
              ),
            ),
          ),
          _FlowMenuTile(
            icon: Icons.trending_up_rounded,
            title: 'Overtime Trends',
            subtitle: 'View weekly and monthly trends',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeOvertimeTrendsScreen(record: record),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeOvertimeCalculationScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const EmployeeOvertimeCalculationScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final calc = _OvertimeCalc.fromRecord(record);
    return _OvertimeScaffold(
      title: 'Overtime Calculation',
      child: Column(
        children: [
          _DateStatusHeader(
            calc: calc,
            statusText: calc.overtimeMinutes > 0
                ? 'Eligible for Overtime'
                : 'No Overtime',
          ),
          const SizedBox(height: 12),
          EmployeeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FlowTitle('Work Information', icon: Icons.work_outline),
                const SizedBox(height: 14),
                _InfoLine('Shift Time', calc.shiftTime),
                _InfoLine('Standard Hours', calc.regularHours),
                _InfoLine('Check In', calc.checkIn),
                _InfoLine('Check Out', calc.checkOut),
                _InfoLine('Lunch Time', calc.lunchTime),
                _InfoLine('Grace Time', calc.graceTime),
                _InfoLine('Late Entry', calc.lateEntry),
                _InfoLine('Total Working Hours', calc.workingHours),
              ],
            ),
          ),
          const SizedBox(height: 12),
          EmployeeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FlowTitle(
                  'Overtime Summary',
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        'Regular Hours',
                        calc.regularHours,
                        EmployeeColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryBox(
                        'Overtime Hours',
                        calc.overtimeText,
                        EmployeeColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(
                      child: _SummaryBox(
                        'Weekend OT',
                        '00h 00m',
                        EmployeeColors.gold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _SummaryBox(
                        'Holiday OT',
                        '00h 00m',
                        EmployeeColors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          EmployeeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FlowTitle(
                  'Overtime Calculation',
                  icon: Icons.calculate_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CalcText(calc.workingHours),
                    const _CalcText('-'),
                    _CalcText(calc.regularHours),
                    const _CalcText('='),
                    _CalcText(calc.overtimeText, color: EmployeeColors.blue),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: calc.standardProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withAlpha(20),
                    color: EmployeeColors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${((calc.totalMinutes / calc.regularMinutes) * 100).round()}% of Standard Hours',
                    style: const TextStyle(
                      color: EmployeeColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: calc.overtimeMinutes <= 0
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EmployeeOvertimeRequestScreen(record: record),
                      ),
                    ),
              child: const Text('Submit Overtime Request'),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeOvertimeRequestScreen extends StatefulWidget {
  final Map<String, dynamic> record;

  const EmployeeOvertimeRequestScreen({super.key, required this.record});

  @override
  State<EmployeeOvertimeRequestScreen> createState() =>
      _EmployeeOvertimeRequestScreenState();
}

class _EmployeeOvertimeRequestScreenState
    extends State<EmployeeOvertimeRequestScreen> {
  final TextEditingController _reason = TextEditingController(
    text: 'Worked on production deployment and client support.',
  );

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calc = _OvertimeCalc.fromRecord(widget.record);
    return _OvertimeScaffold(
      title: 'Overtime Request',
      child: Column(
        children: [
          _DateStatusHeader(
            calc: calc,
            statusText: 'Total Overtime: ${calc.overtimeText}',
          ),
          const SizedBox(height: 12),
          EmployeeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for Overtime *',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reason,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Attachments (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attachment upload is not available yet.')),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Attachment'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EmployeeOvertimeApprovalScreen(
                          record: widget.record,
                        ),
                      ),
                    ),
                    child: const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeOvertimeApprovalScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const EmployeeOvertimeApprovalScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final calc = _OvertimeCalc.fromRecord(record);
    return _OvertimeScaffold(
      title: 'Approval Status',
      child: Column(
        children: [
          _DateStatusHeader(
            calc: calc,
            statusText: 'Total Overtime: ${calc.overtimeText}',
          ),
          const SizedBox(height: 12),
          EmployeeCard(
            child: Column(
              children: const [
                _ApprovalStep(
                  number: 1,
                  title: 'Employee',
                  status: 'Submitted',
                  note: 'Submitted for manager review',
                  done: true,
                ),
                _ApprovalStep(
                  number: 2,
                  title: 'Manager Approval',
                  status: 'Approved',
                  note: 'Approved by Team Lead',
                  done: true,
                ),
                _ApprovalStep(
                  number: 3,
                  title: 'HR Approval',
                  status: 'Pending',
                  note: 'Waiting for HR Approval',
                  warning: true,
                ),
                _ApprovalStep(
                  number: 4,
                  title: 'Payroll Status',
                  status: 'Pending',
                  note: 'Not Processed',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmployeeOvertimeTrendsScreen(record: record),
                ),
              ),
              icon: const Icon(Icons.trending_up_rounded),
              label: const Text('View Overtime Trends'),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeOvertimeTrendsScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const EmployeeOvertimeTrendsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return _OvertimeScaffold(
      title: 'Overtime Trends',
      child: Column(
        children: const [
          _TrendTabs(),
          SizedBox(height: 12),
          _BarChartCard(),
          SizedBox(height: 12),
          _LineChartCard(),
        ],
      ),
    );
  }
}

class _OvertimeScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _OvertimeScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getBgStart(context);
    final text = ThemeConfig.getTextPrimary(context);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DateStatusHeader extends StatelessWidget {
  final _OvertimeCalc calc;
  final String? statusText;

  const _DateStatusHeader({required this.calc, this.statusText});

  @override
  Widget build(BuildContext context) {
    return EmployeeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: EmployeeColors.blue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              calc.displayDate,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            statusText ?? calc.status,
            style: const TextStyle(
              color: EmployeeColors.green,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const _FlowMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeeCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: highlighted
              ? BoxDecoration(
                  border: Border.all(color: EmployeeColors.blue),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, color: EmployeeColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoLine(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowTitle extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _FlowTitle(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: EmployeeColors.blue, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryBox(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcText extends StatelessWidget {
  final String text;
  final Color color;

  const _CalcText(this.text, {this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w900),
    );
  }
}

class _ApprovalStep extends StatelessWidget {
  final int number;
  final String title;
  final String status;
  final String note;
  final bool done;
  final bool warning;

  const _ApprovalStep({
    required this.number,
    required this.title,
    required this.status,
    required this.note,
    this.done = false,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? EmployeeColors.green
        : warning
        ? EmployeeColors.gold
        : Colors.white54;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withAlpha(35),
            child: Text(
              '$number',
              style: TextStyle(
                color: color,
                fontSize: 11,
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
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                Text(
                  note,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(
            done ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _TrendTabs extends StatelessWidget {
  const _TrendTabs();

  @override
  Widget build(BuildContext context) {
    void showTrendMessage(String label) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label overtime trend selected.')),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => showTrendMessage('Weekly'),
            child: const Text('Weekly'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => showTrendMessage('Monthly'),
            child: const Text('Monthly'),
          ),
        ),
      ],
    );
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard();

  @override
  Widget build(BuildContext context) {
    const values = [2.5, 1.0, 3.0, 2.0, 3.5, 4.0, 0.0];
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return EmployeeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FlowTitle('Weekly Overtime (Hours)'),
          const SizedBox(height: 14),
          SizedBox(
            height: 135,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final value = values[index];
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value == 0 ? '0' : value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: value * 22,
                        width: 18,
                        decoration: BoxDecoration(
                          color: index == 5
                              ? EmployeeColors.gold
                              : EmployeeColors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[index],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard();

  @override
  Widget build(BuildContext context) {
    const values = ['6h', '9h', '12h', '8h', '10h', '14h'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    return EmployeeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FlowTitle('Monthly Overtime (Hours)'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(values.length, (index) {
              return Column(
                children: [
                  Text(
                    values[index],
                    style: const TextStyle(
                      color: EmployeeColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: EmployeeColors.blue.withAlpha(180),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    months[index],
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OvertimeCalc {
  final DateTime date;
  final String status;
  final String checkIn;
  final String checkOut;
  final int totalMinutes;
  final int overtimeMinutesValue;
  final String lateEntry;
  final String shiftTime;
  final String lunchTime;
  final String graceTime;
  final String regularHours;
  final int regularMinutes;

  const _OvertimeCalc({
    required this.date,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.totalMinutes,
    required this.overtimeMinutesValue,
    required this.lateEntry,
    required this.shiftTime,
    required this.lunchTime,
    required this.graceTime,
    required this.regularHours,
    required this.regularMinutes,
  });

  factory _OvertimeCalc.fromRecord(Map<String, dynamic> record) {
    final date = _parseDate('${record['date'] ?? ''}') ?? DateTime.now();
    final totalMinutes = _parseHours('${record['working_hours'] ?? '--'}');
    final overtimeMinutes = int.tryParse('${record['overtime_minutes'] ?? ''}');
    final regularMinutes =
        int.tryParse('${record['regular_minutes'] ?? ''}') ??
        _parseHours('${record['regular_hours'] ?? '08h 00m'}');
    return _OvertimeCalc(
      date: date,
      status: '${record['status'] ?? 'Present'}',
      checkIn: '${record['check_in'] ?? '--:--'}',
      checkOut: '${record['check_out'] ?? '--:--'}',
      totalMinutes: totalMinutes,
      overtimeMinutesValue:
          overtimeMinutes ?? _parseHours('${record['overtime'] ?? '00h 00m'}'),
      lateEntry: '${record['late_entry'] ?? '--'}',
      shiftTime: '${record['shift_time'] ?? '09:00 AM - 06:00 PM'}',
      lunchTime: '${record['lunch_time'] ?? '01:00 PM - 02:00 PM'}',
      graceTime: '${record['grace_time'] ?? '10 min'}',
      regularHours: '${record['regular_hours'] ?? '08h 00m'}',
      regularMinutes: regularMinutes <= 0 ? 480 : regularMinutes,
    );
  }

  int get overtimeMinutes => overtimeMinutesValue.clamp(0, 24 * 60);

  double get standardRatio => totalMinutes / regularMinutes;

  double get standardProgress => standardRatio.clamp(0, 1.5) / 1.5;

  String get workingHours => _formatMinutes(totalMinutes);

  String get overtimeText => _formatMinutes(overtimeMinutes);

  String get displayDate =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
}

int _parseHours(String value) {
  final hours = RegExp(r'(\d+)\s*h').firstMatch(value.toLowerCase())?.group(1);
  final minutes = RegExp(
    r'(\d+)\s*m',
  ).firstMatch(value.toLowerCase())?.group(1);
  return (int.tryParse(hours ?? '0') ?? 0) * 60 +
      (int.tryParse(minutes ?? '0') ?? 0);
}

String _formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
}

DateTime? _parseDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  return DateTime.tryParse(value);
}

String _month(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[(month - 1).clamp(0, 11)];
}
