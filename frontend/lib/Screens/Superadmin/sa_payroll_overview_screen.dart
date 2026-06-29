import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaPayrollOverviewScreen extends StatelessWidget {
  const SaPayrollOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Payroll Overview',
      child: saList([
        SaMetricGrid(metrics: [SaMetric('Payroll Processed', r'$125,000', Icons.payments_outlined, c.success), SaMetric('Pending Payroll', r'$32,500', Icons.pending_actions_outlined, c.danger), SaMetric('Employees Paid', '1,156', Icons.groups_rounded, c.warning), SaMetric('Average Salary', r'$4,850', Icons.account_balance_wallet_outlined, c.blue)]),
        const SizedBox(height: 14),
        SaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [saTitle(context, 'Payroll Trend', 14), const SizedBox(height: 14), SizedBox(height: 130, child: CustomPaint(painter: _LinePainter(c)))])),
        const SizedBox(height: 12),
        SaCard(child: Center(child: Text('View Payroll Report', style: TextStyle(color: c.primary, fontWeight: FontWeight.w900)))),
      ]),
    );
  }
}

class _LinePainter extends CustomPainter {
  final SaPalette colors;
  const _LinePainter(this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    const values = [0.35, 0.48, 0.72, 0.44, 0.38, 0.58, 0.78, 0.68, 0.92];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - size.height * values[i];
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = colors.primary.withAlpha(45)..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    canvas.drawPath(path, Paint()..color = colors.primary..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
