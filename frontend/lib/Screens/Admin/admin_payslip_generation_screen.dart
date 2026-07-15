import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';

import '../Payslip/payslip_detail_screen.dart';
import '../Payslip/payslip_repository.dart';
import '../Payslip/payslip_service.dart';
import '../Payslip/payslip_widgets.dart';

class AdminPayslipGenerationScreen extends StatefulWidget {
  final String adminId;
  final bool canApproveAndLock;

  const AdminPayslipGenerationScreen({
    super.key,
    required this.adminId,
    this.canApproveAndLock = false,
  });

  @override
  State<AdminPayslipGenerationScreen> createState() =>
      _AdminPayslipGenerationScreenState();
}

class _AdminPayslipGenerationScreenState
    extends State<AdminPayslipGenerationScreen> {
  final _repository = PayslipRepository();
  final _service = PayslipService();
  DateTime _month = DateTime.now();
  String? _employeeId;
  Map<String, dynamic>? _summary;
  bool _loading = false;
  bool _releasing = false;

  Future<void> _generate() async {
    final employeeId = _employeeId;
    if (employeeId == null || _loading) return;
    setState(() => _loading = true);
    try {
      final generatedPayslip = await _service.generatePayslip(
        employeeId: employeeId,
        month: _month.month,
        year: _month.year,
        generatedBy: widget.adminId,
      );
      setState(() => _summary = generatedPayslip);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payslip generated')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _release() async {
    final id = _summary?['payslipId'];
    if (id == null || _releasing) return;
    setState(() => _releasing = true);
    try {
      await _repository.releasePayslip('$id', widget.adminId);
      if (mounted) {
        setState(() => _summary = {...?_summary, 'status': 'released'});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payslip released to employee')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _releasing = false);
    }
  }

  Future<void> _approveAndLock() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _repository.approveAndLockPayroll(
        month: _month.month,
        year: _month.year,
        actorId: widget.adminId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll approved and locked')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayslipColors.background,
      appBar: AppBar(title: const Text('Generate Payslip')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          PayslipCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payroll Period',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickMonth,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text('${_month.month}/${_month.year}'),
                ),
                if (widget.canApproveAndLock) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _approveAndLock,
                    icon: const Icon(Icons.lock_rounded),
                    label: const Text('Approve & Lock Payroll'),
                  ),
                ],
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('employees')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    return AppDropdownButtonFormField<String>(
                      value: _employeeId,
                      items: docs.map((doc) {
                        final data = doc.data();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text('${data['name'] ?? doc.id}'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        _employeeId = value;
                        _summary = null;
                      }),
                      decoration: const InputDecoration(labelText: 'Employee'),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_summary != null)
            PayslipCard(
              child: Column(
                children: [
                  PayslipInfoRow('Employee', '${_summary!['employeeName']}'),
                  PayslipInfoRow(
                    'Gross Earnings',
                    money(_summary!['grossEarnings']),
                  ),
                  PayslipInfoRow(
                    'Total Deductions',
                    money(_summary!['totalDeductions']),
                  ),
                  PayslipInfoRow('Net Pay', money(_summary!['netPay'])),
                  PayslipInfoRow('Status', '${_summary!['status']}'),
                ],
              ),
            ),
          ElevatedButton.icon(
            onPressed: _loading ? null : _generate,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_loading ? 'Generating...' : 'Generate PDF'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _summary == null || _releasing ? null : _release,
            icon: _releasing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_rounded),
            label: Text(_releasing ? 'Releasing...' : 'Release Payslip'),
          ),
          if (_summary != null)
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PayslipDetailScreen(
                    payslip: _summary!,
                    viewerId: widget.adminId,
                  ),
                ),
              ),
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('View Details'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() {
        _month = DateTime(selected.year, selected.month);
        _summary = null;
      });
    }
  }
}
