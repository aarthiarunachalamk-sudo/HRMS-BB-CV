import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'payslip_repository.dart';
import 'payslip_widgets.dart';

class PayslipDetailScreen extends StatelessWidget {
  static const MethodChannel _channel = MethodChannel('hrms/location');

  final Map<String, dynamic> payslip;
  final String? viewerId;

  const PayslipDetailScreen({super.key, required this.payslip, this.viewerId});

  @override
  Widget build(BuildContext context) {
    final employee = _map(payslip['employee']);
    final earnings = _listOfMaps(payslip['earnings']);
    final deductions = _listOfMaps(payslip['deductions']);
    return Scaffold(
      backgroundColor: PayslipColors.background,
      appBar: AppBar(title: const Text('Payslip Details')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          PayslipCard(
            child: Column(
              children: [
                PayslipInfoRow('Employee', '${payslip['employeeName'] ?? ''}'),
                PayslipInfoRow('Employee ID', '${payslip['employeeId'] ?? ''}'),
                PayslipInfoRow('Department', '${employee['department'] ?? ''}'),
                PayslipInfoRow('Designation', '${employee['designation'] ?? ''}'),
                PayslipInfoRow('Location', '${employee['branch'] ?? ''}'),
              ],
            ),
          ),
          PayslipCard(
            child: Column(
              children: [
                PayslipInfoRow('Total Days', '${payslip['totalDays'] ?? 0}'),
                PayslipInfoRow('Working Days', '${payslip['workingDays'] ?? 0}'),
                PayslipInfoRow('Present Days', '${payslip['presentDays'] ?? 0}'),
                PayslipInfoRow('Paid Leave Days', '${payslip['paidLeaveDays'] ?? 0}'),
                PayslipInfoRow('LOP Days', '${payslip['lopDays'] ?? 0}'),
                PayslipInfoRow('Payable Days', '${payslip['payableDays'] ?? 0}'),
              ],
            ),
          ),
          _table('Earnings', earnings, ['name', 'actualAmount', 'earnedAmount']),
          _table('Deductions', deductions, ['name', 'amount']),
          PayslipCard(
            child: Column(
              children: [
                PayslipInfoRow('Gross Earnings', money(payslip['grossEarnings'])),
                PayslipInfoRow('Total Deductions', money(payslip['totalDeductions'])),
                PayslipInfoRow('Net Pay', money(payslip['netPay'])),
                PayslipInfoRow('In Words', '${payslip['netPayInWords'] ?? ''}'),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  Widget _table(String title, List<Map<String, dynamic>> rows, List<String> keys) {
    return PayslipCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: PayslipColors.secondaryNavy)),
          const SizedBox(height: 8),
          ...rows.map((row) => PayslipInfoRow('${row[keys[0]] ?? ''}', keys.length == 3 ? '${money(row[keys[1]])} / ${money(row[keys[2]])}' : money(row[keys[1]]))),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
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
        await PayslipRepository().audit(
          payslipId,
          'downloaded',
          viewerId ?? '${payslip['employeeId'] ?? ''}',
        );
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

  Map<String, dynamic> _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
