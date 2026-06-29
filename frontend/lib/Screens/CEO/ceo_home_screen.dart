import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoHomeScreen extends StatelessWidget {
  final String firstName;
  final String email;
  final String userId;
  final VoidCallback onOpenApprovals;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenDirectory;

  const CeoHomeScreen({
    super.key,
    required this.firstName,
    required this.email,
    required this.userId,
    required this.onOpenApprovals,
    required this.onOpenReports,
    required this.onOpenDirectory,
  });

  @override
  Widget build(BuildContext context) {
    return CeoFutureBody(
      future: CeoService().fetchDashboard(userId),
      builder: (data) => pageList([
        Row(children: [
          const CircleAvatar(radius: 24, backgroundColor: CeoColors.cardAlt, child: Icon(Icons.person_rounded, color: CeoColors.cyan)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            muted('Welcome back,', 12),
            title(firstName.isEmpty ? 'CEO' : firstName, 17),
            muted(email, 11),
            if (userId.isNotEmpty) small(userId),
          ])),
        ]),
        const SizedBox(height: 18),
        CeoMetricGrid(cards: [
          CeoMetric('Total Employees', '${data['total_employees']}', '+12.5%', Icons.groups_rounded, CeoColors.cyan),
          CeoMetric('Active Employees', '${data['active_employees']}', '+11.8%', Icons.verified_user_rounded, CeoColors.green),
          CeoMetric('Departments', '${data['departments']}', '', Icons.apartment_rounded, CeoColors.purple),
          CeoMetric('Branches', '${data['branches']}', '', Icons.business_rounded, CeoColors.gold),
        ]),
        const SizedBox(height: 16),
        title('Revenue Overview', 15),
        const SizedBox(height: 10),
        chartCard('${data['revenue']}', const [34, 42, 38, 48, 44, 58], trend: '+15.6%', color: CeoColors.green),
        Row(children: [
          Expanded(child: _Summary('Attendance', '${data['attendance']}', 'Present Today', CeoColors.green)),
          const SizedBox(width: 10),
          Expanded(child: _Summary('Pending Approvals', '${data['pending_approvals']}', 'Requests', CeoColors.pink)),
          const SizedBox(width: 10),
          Expanded(child: _Summary('Payroll Cost', '${data['payroll_cost']}', 'This Month', CeoColors.cyan)),
        ]),
        const SizedBox(height: 18),
        title('Quick Actions', 15),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ActionTile(icon: Icons.groups_rounded, label: 'Employees', onTap: onOpenDirectory)),
          const SizedBox(width: 10),
          Expanded(child: _ActionTile(icon: Icons.beach_access_rounded, label: 'Leave', onTap: onOpenApprovals)),
          const SizedBox(width: 10),
          Expanded(child: _ActionTile(icon: Icons.payments_rounded, label: 'Payroll', onTap: onOpenReports)),
          const SizedBox(width: 10),
          Expanded(child: _ActionTile(icon: Icons.summarize_rounded, label: 'Reports', onTap: onOpenReports)),
        ]),
      ]),
    );
  }
}

class _Summary extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color color;

  const _Summary(this.label, this.value, this.caption, this.color);

  @override
  Widget build(BuildContext context) {
    return CeoCard(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        muted(label, 10),
        const SizedBox(height: 5),
        title(value, 16),
        const SizedBox(height: 2),
        small(caption, color: color),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 70,
        decoration: BoxDecoration(color: CeoColors.cardAlt, borderRadius: BorderRadius.circular(8), border: Border.all(color: CeoColors.border)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: CeoColors.cyan, size: 22),
          const SizedBox(height: 6),
          FittedBox(child: muted(label, 10)),
        ]),
      ),
    );
  }
}
