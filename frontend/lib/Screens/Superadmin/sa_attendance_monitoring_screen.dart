import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaAttendanceMonitoringScreen extends StatelessWidget {
  const SaAttendanceMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Attendance Monitoring',
      trailing: Icon(Icons.calendar_month_rounded, color: c.text),
      child: FutureBuilder<Map<String, dynamic>>(
        future: SaService().fetchDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          final data = snapshot.data ?? {};
          final attendance = Map<String, dynamic>.from(
            (data['attendance_detail'] as Map?) ?? const {},
          );
          final total = int.tryParse('${attendance['total'] ?? 0}') ?? 0;
          if (total == 0) {
            return saList([_empty(context, c)]);
          }
          final present = int.tryParse('${attendance['present'] ?? 0}') ?? 0;
          final absent = int.tryParse('${attendance['absent'] ?? 0}') ?? 0;
          final late = int.tryParse('${attendance['late'] ?? 0}') ?? 0;
          final percent = total == 0 ? 0.0 : present / total;
          return saList([
            SaCard(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 136,
                    height: 136,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: percent.clamp(0, 1).toDouble(),
                          strokeWidth: 14,
                          color: c.primary,
                          backgroundColor: c.border,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            saTitle(context, '${(percent * 100).round()}%', 28),
                            saMuted(context, 'Total Attendance', 11),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Legend('Present', '$present', c.primary),
                  _Legend('Absent', '$absent', c.danger),
                  _Legend('Late', '$late', c.warning),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _empty(BuildContext context, SaPalette c) => SaCard(
    child: Center(
      child: Text(
        'No attendance data found in backend.',
        textAlign: TextAlign.center,
        style: TextStyle(color: c.muted, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Legend(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [CircleAvatar(radius: 4, backgroundColor: color), const SizedBox(width: 8), Expanded(child: saTitle(context, label, 12)), saMuted(context, value, 12)]));
}
