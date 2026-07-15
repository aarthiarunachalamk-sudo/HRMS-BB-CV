import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'payslip_detail_screen.dart';
import 'payslip_repository.dart';
import 'payslip_widgets.dart';

class EmployeePayslipListScreen extends StatelessWidget {
  static const MethodChannel _channel = MethodChannel('hrms/location');

  final String employeeId;
  final PayslipRepository repository;

  EmployeePayslipListScreen({
    super.key,
    required this.employeeId,
    PayslipRepository? repository,
  }) : repository = repository ?? PayslipRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayslipColors.background,
      appBar: AppBar(title: const Text('Payslips')),
      body: StreamBuilder(
        stream: repository.releasedPayslipsForEmployee(employeeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No released payslips found'));
          }
          return ListView(
            padding: const EdgeInsets.all(14),
            children: docs.map((doc) {
              final data = doc.data();
              return PayslipCard(
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: PayslipColors.accentCyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${data['payrollMonth']}/${data['payrollYear']}', style: const TextStyle(fontWeight: FontWeight.w900, color: PayslipColors.text)),
                          Text('${data['status'] ?? ''}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(money(data['netPay']), style: const TextStyle(fontWeight: FontWeight.w900, color: PayslipColors.secondaryNavy)),
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () => _download(context, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PayslipDetailScreen(
                            payslip: data,
                            viewerId: employeeId,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _download(BuildContext context, Map<String, dynamic> payslip) async {
    final url = '${payslip['pdfUrl'] ?? ''}';
    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payslip PDF is not available yet.')),
      );
      return;
    }
    try {
      final payslipId = '${payslip['payslipId'] ?? ''}';
      if (payslipId.isNotEmpty) {
        await repository.audit(payslipId, 'downloaded', employeeId);
      }
      await _channel.invokeMethod<bool>('openUrl', {'url': url});
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }
}
