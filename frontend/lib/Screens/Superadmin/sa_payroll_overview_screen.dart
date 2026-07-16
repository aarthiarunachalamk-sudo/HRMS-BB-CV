import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaPayrollOverviewScreen extends StatelessWidget {
  const SaPayrollOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Payroll Overview',
      child: FutureBuilder<Map<String, dynamic>>(
        future: SaService().fetchDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          final payroll = Map<String, dynamic>.from(
            (snapshot.data?['payroll'] as Map?) ?? const {},
          );
          final metrics = [
            SaMetric(
              'Payroll Processed',
              'Rs. ${payroll['processed'] ?? 0}',
              Icons.payments_outlined,
              c.success,
            ),
            SaMetric(
              'Pending Payroll',
              '${payroll['pending'] ?? 0}',
              Icons.pending_actions_outlined,
              c.danger,
            ),
            SaMetric(
              'Employees Paid',
              '${payroll['employees_paid'] ?? 0}',
              Icons.groups_rounded,
              c.warning,
            ),
            SaMetric(
              'Average Salary',
              'Rs. ${payroll['average_salary'] ?? 0}',
              Icons.account_balance_wallet_outlined,
              c.blue,
            ),
          ];
          final hasData = '${payroll['processed'] ?? 0}' != '0' ||
              '${payroll['employees_paid'] ?? 0}' != '0';
          return saList([
            if (hasData) SaMetricGrid(metrics: metrics) else _empty(context, c),
          ]);
        },
      ),
    );
  }

  Widget _empty(BuildContext context, SaPalette c) => SaCard(
        child: Center(
          child: Text(
            'No payroll data found in backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontWeight: FontWeight.w800),
          ),
        ),
      );
}
