import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'employee_models.dart';
import 'employee_service.dart';
import 'employee_shared.dart';

class EmployeePayslipScreen extends StatefulWidget {
  final String userId;
  final EmployeeDashboardData data;
  final EmployeeService service;

  const EmployeePayslipScreen({
    super.key,
    required this.userId,
    required this.data,
    required this.service,
  });

  @override
  State<EmployeePayslipScreen> createState() => _EmployeePayslipScreenState();
}

class _EmployeePayslipScreenState extends State<EmployeePayslipScreen> {
  static const MethodChannel _channel = MethodChannel('hrms/location');

  late Map<String, dynamic> _payslip = Map<String, dynamic>.from(widget.data.payslip);
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final latest = await widget.service.fetchPayslip(widget.userId);
      if (mounted) setState(() => _payslip = latest);
    } catch (_) {
      // Keep dashboard payslip fallback if backend is not reachable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payslip = _payslip;
    if (payslip.isEmpty) {
      return EmployeePage(
        title: 'Payslip',
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          const EmployeeCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Payslip not generated yet')),
            ),
          ),
        ],
      );
    }
    final earnings = Map<String, dynamic>.from(payslip['earnings'] is Map ? payslip['earnings'] as Map : const {});
    final deductions = Map<String, dynamic>.from(payslip['deductions'] is Map ? payslip['deductions'] as Map : const {});
    return EmployeePage(
      title: 'Payslip',
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_loading) const SizedBox(height: 10),
        EmployeeCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${payslip['month'] ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Rs ${payslip['net_salary'] ?? '0'}', style: const TextStyle(color: EmployeeColors.green, fontSize: 30, fontWeight: FontWeight.bold)),
              Text('Status: ${payslip['status'] ?? 'Generated'}'),
              Text('Paid Days: ${payslip['paid_days'] ?? 0} | LOP: ${payslip['lop_days'] ?? 0}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        EmployeeCard(
          child: Column(
            children: [
              ...earnings.entries.map((entry) => EmployeeInfoRow(entry.key, 'Rs ${entry.value}')),
              EmployeeInfoRow('Gross Salary', 'Rs ${payslip['gross_salary'] ?? '0'}'),
              const Divider(),
              ...deductions.entries.map((entry) => EmployeeInfoRow(entry.key, 'Rs ${entry.value}')),
              EmployeeInfoRow('Total Deductions', 'Rs ${payslip['total_deductions'] ?? '0'}'),
              const Divider(),
              EmployeeInfoRow('Net Salary', 'Rs ${payslip['net_salary'] ?? '0'}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Payslip'),
          ),
        ),
      ],
    );
  }

  Future<void> _download(BuildContext context) async {
    final url = '${_payslip['download_url'] ?? ''}'.trim();
    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payslip PDF is not available yet.')),
      );
      return;
    }
    try {
      final opened = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      if (opened == true || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open payslip PDF.')),
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to open payslip PDF.')),
      );
    }
  }
}
