import 'package:flutter/material.dart';

import 'hr_service.dart';
import 'hr_shared.dart';

class HrPayrollScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onChanged;

  const HrPayrollScreen({super.key, required this.data, required this.userId, required this.onChanged});

  @override
  State<HrPayrollScreen> createState() => _HrPayrollScreenState();
}

class _HrPayrollScreenState extends State<HrPayrollScreen> {
  int _stage = 0;
  int _employeeIndex = 0;
  bool _publishing = false;
  bool _published = false;
  bool _generatePayslips = true;
  bool _emailEmployees = true;
  bool _pushNotification = true;
  bool _bankAdvice = true;
  bool _processLoading = true;
  List<Map<String, dynamic>> _processValidation = const [];
  final Set<String> _resolvedIssues = {};

  @override
  void initState() {
    super.initState();
    _loadProcess();
  }

  List<Map<String, dynamic>> get _employees => hrList(widget.data, 'total_employees_list');
  List<Map<String, dynamic>> get _payslips => hrList(widget.data, 'payroll_items');
  int get _total => int.tryParse('${widget.data['total_employees'] ?? 0}') ?? 0;
  int get _processed => int.tryParse('${widget.data['payroll_processed'] ?? 0}') ?? 0;
  int get _pending => int.tryParse('${widget.data['payroll_pending'] ?? 0}') ?? 0;

  List<_PayrollIssue> get _issues {
    final issues = <_PayrollIssue>[];
    final validation = _processValidation.isNotEmpty ? _processValidation : hrList(widget.data, 'payroll_validation');
    for (final employee in validation) {
      final id = '${employee['employee_id'] ?? ''}';
      final name = '${employee['employee_name'] ?? 'Employee'}';
      if (employee['bank_missing'] == true) {
        issues.add(_PayrollIssue(id: '$id-bank', employeeId: id, name: name, title: 'Bank details missing', detail: 'Account number or IFSC is unavailable', colorKey: 'critical'));
      }
      if (employee['attendance_conflict'] == true) {
        issues.add(_PayrollIssue(
          id: '$id-attendance',
          employeeId: id,
          name: name,
          title: 'Attendance needs confirmation',
          detail: '${employee['attendance_days'] ?? 0}/${employee['expected_attendance_days'] ?? 0} working days recorded',
          colorKey: 'warning',
        ));
      }
      if (employee['salary_configured'] != true) {
        issues.add(_PayrollIssue(id: '$id-salary', employeeId: id, name: name, title: 'Salary structure missing', detail: 'Configure salary components before payroll', colorKey: 'critical'));
      }
    }
    return issues;
  }

  @override
  Widget build(BuildContext context) {
    if (_processLoading) {
      final c = HrPalette.of(context);
      return Center(child: CircularProgressIndicator(color: c.primary));
    }
    switch (_stage) {
      case 1:
        return _validationHub(context);
      case 2:
        return _salaryWorkspace(context);
      case 3:
        return _publishPayroll(context);
      default:
        return _commandCenter(context);
    }
  }

  Widget _commandCenter(BuildContext context) {
    final c = HrPalette.of(context);
    final readiness = int.tryParse('${widget.data['payroll_readiness'] ?? 0}') ?? 0;
    return ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 20), children: [
      _pageTitle(context, 'Payroll Command Center', badge: 'HR'),
      const SizedBox(height: 12),
      HrCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.data['payroll_month'] ?? ''} Payroll', style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(children: [
            SizedBox(width: 112, height: 112, child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 104, height: 104, child: CircularProgressIndicator(value: readiness / 100, strokeWidth: 11, color: c.primary, backgroundColor: c.border)),
              Column(mainAxisSize: MainAxisSize.min, children: [Text('$readiness%', style: TextStyle(color: c.text, fontSize: 25, fontWeight: FontWeight.w900)), Text('Ready', style: TextStyle(color: c.muted, fontSize: 10))]),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Payroll Period', style: TextStyle(color: c.muted, fontSize: 10)),
              const SizedBox(height: 4),
              Text(_monthPeriod(), style: TextStyle(color: c.text, fontSize: 11, fontWeight: FontWeight.w800)),
              Divider(height: 20, color: c.border),
              Text('Employees', style: TextStyle(color: c.muted, fontSize: 10)),
              const SizedBox(height: 4),
              Text('$_total included', style: TextStyle(color: c.text, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 11),
              ElevatedButton(onPressed: () => _advance('start', 1), style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Continue Payroll'), SizedBox(width: 5), Icon(Icons.chevron_right_rounded, size: 17)])),
            ])),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      _stepRail(context, 0),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _metric(context, 'Gross Pay', _money(widget.data['payroll_gross']), c.primary, Icons.account_balance_wallet_outlined)),
        const SizedBox(width: 7),
        Expanded(child: _metric(context, 'Processed', '$_processed', c.danger, Icons.receipt_long_outlined)),
        const SizedBox(width: 7),
        Expanded(child: _metric(context, 'Pending', '$_pending', c.success, Icons.payments_outlined)),
      ]),
      const SizedBox(height: 16),
      _sectionTitle(context, 'Needs Attention', '${_issues.length} issues'),
      const SizedBox(height: 8),
      if (_issues.isEmpty)
        _attentionCard(context, Icons.verified_rounded, 'Payroll data verified', 'No blocking issues found', c.success)
      else ...[
        _attentionCard(context, Icons.warning_amber_rounded, '${_issues.where((e) => e.colorKey == 'warning').length} attendance conflicts', 'Review payable days before calculation', c.warning),
        const SizedBox(height: 8),
        _attentionCard(context, Icons.cancel_outlined, '${_issues.where((e) => e.colorKey == 'critical').length} missing bank details', 'Required before bank transfer', c.danger),
      ],
    ]);
  }

  Widget _validationHub(BuildContext context) {
    final c = HrPalette.of(context);
    final issues = _issues;
    final unresolved = issues.where((issue) => !_resolvedIssues.contains(issue.id)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 20), children: [
      _flowHeader(context, 'Validation Hub', 'Fix issues before calculation', () => setState(() => _stage = 0)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _filterTile(context, 'All', '${issues.length}', c.primary, true)),
        const SizedBox(width: 7),
        Expanded(child: _filterTile(context, 'Critical', '${issues.where((e) => e.colorKey == 'critical').length}', c.danger, false)),
        const SizedBox(width: 7),
        Expanded(child: _filterTile(context, 'Warnings', '${issues.where((e) => e.colorKey == 'warning').length}', c.warning, false)),
      ]),
      const SizedBox(height: 12),
      if (issues.isEmpty)
        _successCard(context, 'All employee records are ready for calculation.')
      else
        ...issues.map((issue) => Padding(padding: const EdgeInsets.only(bottom: 9), child: _issueCard(context, issue))),
      const SizedBox(height: 8),
      HrCard(child: Row(children: [
        CircleAvatar(backgroundColor: c.primary.withAlpha(28), child: Icon(Icons.check_rounded, color: c.primary)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${issues.length - unresolved.length} of ${issues.length} resolved', style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w900)), const SizedBox(height: 6), LinearProgressIndicator(value: issues.isEmpty ? 1 : (issues.length - unresolved.length) / issues.length, color: c.primary, backgroundColor: c.border)])),
      ])),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () => _advance('validate', 2), style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)), child: const Text('Validate & Continue')),
    ]);
  }

  Widget _salaryWorkspace(BuildContext context) {
    final c = HrPalette.of(context);
    final employee = _employees.isEmpty ? <String, dynamic>{} : _employees[_employeeIndex.clamp(0, _employees.length - 1).toInt()];
    final name = '${employee['name'] ?? 'Employee'}';
    final employeeId = '${employee['id'] ?? employee['trailing'] ?? '-'}';
    Map<String, dynamic>? slip;
    for (final item in _payslips) {
      if ('${item['employee_id'] ?? ''}' == employeeId) {
        slip = item;
        break;
      }
    }
    final net = double.tryParse('${slip?['net_salary'] ?? 0}') ?? 0.0;
    final gross = double.tryParse('${slip?['total_earnings'] ?? slip?['gross_salary'] ?? 0}') ?? 0.0;
    final deductions = double.tryParse('${slip?['total_deductions'] ?? 0}') ?? 0.0;
    final earningRows = _componentRows(slip?['earnings']);
    final deductionRows = _componentRows(slip?['deductions']);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 20), children: [
      _flowHeader(context, 'Salary Workspace', 'Review employee calculation', () => setState(() => _stage = 1)),
      const SizedBox(height: 12),
      HrCard(child: Row(children: [
        IconButton(onPressed: _employeeIndex > 0 ? () => setState(() => _employeeIndex--) : null, icon: const Icon(Icons.chevron_left_rounded)),
        CircleAvatar(radius: 23, backgroundColor: c.primary.withAlpha(30), child: Text(name.isEmpty ? '?' : name[0], style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w900)), Text('$employeeId  •  ${employee['role'] ?? employee['designation'] ?? ''}', style: TextStyle(color: c.primary, fontSize: 9, fontWeight: FontWeight.w700))])),
        Icon(Icons.verified_user_outlined, color: c.success, size: 20),
        IconButton(onPressed: _employeeIndex + 1 < _employees.length ? () => setState(() => _employeeIndex++) : null, icon: const Icon(Icons.chevron_right_rounded)),
      ])),
      const SizedBox(height: 10),
      HrCard(child: Row(children: [
        Expanded(child: _salaryArc(context, 'Earnings', gross, c.primary)),
        Container(width: 1, height: 70, color: c.border),
        Expanded(child: Column(children: [Text('Net Pay', style: TextStyle(color: c.muted, fontSize: 10)), Text(_money(net), style: TextStyle(color: c.text, fontSize: 22, fontWeight: FontWeight.w900))])),
        Container(width: 1, height: 70, color: c.border),
        Expanded(child: _salaryArc(context, 'Deductions', deductions, c.danger)),
      ])),
      const SizedBox(height: 10),
      _salaryComponents(context, 'EARNINGS', c.primary, earningRows),
      const SizedBox(height: 10),
      _salaryComponents(context, 'DEDUCTIONS', c.danger, deductionRows),
      const SizedBox(height: 10),
      HrCard(child: Row(children: [Icon(Icons.verified_user_outlined, color: c.success, size: 34), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Payroll Check', style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w900)), Text('Salary matches available attendance and policy data.', style: TextStyle(color: c.muted, fontSize: 9))])), Icon(Icons.chevron_right_rounded, color: c.muted)])),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.save_outlined), label: const Text('Save Adjustment'))),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(onPressed: () => _advance('approve', 3), style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white), icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('Confirm Employee'))),
      ]),
    ]);
  }

  Widget _publishPayroll(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 20), children: [
      _flowHeader(context, 'Publish Payroll', _published ? 'Payroll completed' : 'Final review and publishing', () => setState(() => _stage = 2)),
      const SizedBox(height: 12),
      HrCard(child: Column(children: [
        Row(children: [Icon(Icons.calendar_month_rounded, color: c.primary, size: 29), const SizedBox(width: 10), Expanded(child: Text('${widget.data['payroll_month'] ?? ''}', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900)))]),
        Divider(height: 22, color: c.border),
        Row(children: [Expanded(child: _publishMetric(context, '$_total', 'Employees')), Container(width: 1, height: 40, color: c.border), Expanded(child: _publishMetric(context, _money(widget.data['payroll_net']), 'Total Payout'))]),
      ])),
      const SizedBox(height: 10),
      HrCard(child: Column(children: [
        _timeline(context, 'Prepared by HR', 'Payroll inputs and validation', true),
        _timeline(context, 'HR Manager Review', 'Calculation confirmed', true),
        _timeline(context, 'Payroll Approval', 'Ready to publish', true),
        _timeline(context, 'Payslip Generation', _published ? 'Completed' : 'Ready to generate', _published),
      ])),
      const SizedBox(height: 10),
      HrCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Publishing Options', style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w900)),
        _switchRow(context, Icons.description_outlined, 'Generate Payslips', _generatePayslips, (v) => setState(() => _generatePayslips = v)),
        _switchRow(context, Icons.mail_outline_rounded, 'Email Employees', _emailEmployees, (v) => setState(() => _emailEmployees = v)),
        _switchRow(context, Icons.notifications_none_rounded, 'Push Notification', _pushNotification, (v) => setState(() => _pushNotification = v)),
        _switchRow(context, Icons.account_balance_outlined, 'Create Bank Advice', _bankAdvice, (v) => setState(() => _bankAdvice = v)),
      ])),
      const SizedBox(height: 12),
      if (!_published)
        ElevatedButton.icon(onPressed: _publishing ? null : _publish, style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)), icon: _publishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded), label: Text(_publishing ? 'Publishing Payroll...' : 'Publish Payroll'))
      else
        HrCard(child: Column(children: [
          CircleAvatar(radius: 31, backgroundColor: c.success.withAlpha(30), child: Icon(Icons.check_rounded, color: c.success, size: 38)),
          const SizedBox(height: 10),
          Text('Payroll Published', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$_total payslips generated successfully', style: TextStyle(color: c.muted, fontSize: 10)),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Download Report'))), const SizedBox(width: 8), Expanded(child: ElevatedButton(onPressed: () { widget.onChanged(); setState(() => _stage = 0); }, style: ElevatedButton.styleFrom(backgroundColor: c.success, foregroundColor: Colors.white), child: const Text('Done')))]),
        ])),
    ]);
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final result = await HrService().updatePayrollProcess(
        widget.userId,
        DateTime.now(),
        'publish',
        options: {
          'generate_payslips': _generatePayslips,
          'email_employees': _emailEmployees,
          'push_notification': _pushNotification,
          'create_bank_advice': _bankAdvice,
        },
      );
      if (!mounted) return;
      setState(() => _published = true);
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Payroll published successfully'}')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _loadProcess() async {
    try {
      final result = await HrService().fetchPayrollProcess(DateTime.now());
      if (!mounted) return;
      _applyProcess(result);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _processLoading = false);
    }
  }

  Future<void> _advance(String action, int nextStage) async {
    setState(() => _processLoading = true);
    try {
      final result = await HrService().updatePayrollProcess(widget.userId, DateTime.now(), action);
      if (!mounted) return;
      _applyProcess(result);
      setState(() => _stage = nextStage);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _processLoading = false);
    }
  }

  Future<void> _resolveIssue(String issueId) async {
    try {
      final result = await HrService().updatePayrollProcess(
        widget.userId,
        DateTime.now(),
        'resolve',
        issueId: issueId,
      );
      if (!mounted) return;
      _applyProcess(result);
      setState(() {});
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  void _applyProcess(Map<String, dynamic> result) {
    final process = result['process'];
    if (process is Map) {
      final stage = int.tryParse('${process['stage'] ?? 0}') ?? 0;
      _stage = stage >= 4 ? 3 : stage;
      _published = stage >= 4;
      _resolvedIssues
        ..clear()
        ..addAll((process['resolved_issues'] is List ? process['resolved_issues'] as List : const []).map((item) => '$item'));
      final options = process['publishing_options'];
      if (options is Map && options.isNotEmpty) {
        _generatePayslips = options['generate_payslips'] != false;
        _emailEmployees = options['email_employees'] != false;
        _pushNotification = options['push_notification'] != false;
        _bankAdvice = options['create_bank_advice'] != false;
      }
    }
    final validation = result['validation'];
    if (validation is List) {
      _processValidation = validation.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }
  }

  Widget _pageTitle(BuildContext context, String title, {String? badge}) { final c = HrPalette.of(context); return Row(children: [Expanded(child: Text(title, style: TextStyle(color: c.text, fontSize: 19, fontWeight: FontWeight.w900))), if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(border: Border.all(color: c.primary), borderRadius: BorderRadius.circular(12)), child: Text(badge, style: TextStyle(color: c.primary, fontSize: 9, fontWeight: FontWeight.w900)))]); }
  Widget _flowHeader(BuildContext context, String title, String subtitle, VoidCallback back) { final c = HrPalette.of(context); return Row(children: [IconButton(onPressed: back, icon: Icon(Icons.arrow_back_rounded, color: c.text)), Expanded(child: Column(children: [Text(title, style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(color: c.muted, fontSize: 9))])), Icon(Icons.more_vert_rounded, color: c.muted)]); }
  Widget _sectionTitle(BuildContext context, String title, String action) { final c = HrPalette.of(context); return Row(children: [Expanded(child: Text(title, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w900))), Text(action, style: TextStyle(color: c.muted, fontSize: 9))]); }
  Widget _metric(BuildContext context, String label, String value, Color color, IconData icon) { final c = HrPalette.of(context); return HrCard(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: c.muted, fontSize: 9)), const SizedBox(height: 6), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Icon(icon, color: color, size: 18)])); }
  Widget _stepRail(BuildContext context, int active) {
    final c = HrPalette.of(context);
    const labels = ['Inputs', 'Validation', 'Calculation', 'Approval', 'Published'];
    const icons = [
      Icons.description_outlined,
      Icons.verified_user_outlined,
      Icons.calculate_outlined,
      Icons.check_circle_outline,
      Icons.send_outlined,
    ];
    return Row(
      children: List.generate(
        labels.length,
        (i) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: i <= active ? c.primary.withAlpha(40) : c.row,
                child: Icon(
                  i < active ? Icons.check_rounded : icons[i],
                  color: i <= active ? c.primary : c.muted,
                  size: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: TextStyle(
                  color: i == active ? c.text : c.muted,
                  fontSize: 8,
                  fontWeight: i == active ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _attentionCard(BuildContext context, IconData icon, String title, String detail, Color color) { final c = HrPalette.of(context); return Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(9), border: Border.all(color: color.withAlpha(90))), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: c.text, fontSize: 11, fontWeight: FontWeight.w900)), Text(detail, style: TextStyle(color: c.muted, fontSize: 9))])), OutlinedButton(onPressed: () => setState(() => _stage = 1), style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color), visualDensity: VisualDensity.compact), child: const Text('Resolve'))])); }
  Widget _filterTile(BuildContext context, String label, String count, Color color, bool selected) { final c = HrPalette.of(context); return Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: selected ? color.withAlpha(28) : c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? color : c.border)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: TextStyle(color: selected ? c.text : c.muted, fontSize: 10, fontWeight: FontWeight.w800)), const SizedBox(width: 6), Text(count, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900))])); }
  Widget _issueCard(BuildContext context, _PayrollIssue issue) { final c = HrPalette.of(context); final color = issue.colorKey == 'critical' ? c.danger : c.warning; final resolved = _resolvedIssues.contains(issue.id); return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(9), border: Border(left: BorderSide(color: resolved ? c.success : color, width: 4), top: BorderSide(color: c.border), right: BorderSide(color: c.border), bottom: BorderSide(color: c.border))), child: Row(children: [CircleAvatar(radius: 20, backgroundColor: color.withAlpha(24), child: Text(issue.name.isEmpty ? '?' : issue.name[0], style: TextStyle(color: color, fontWeight: FontWeight.w900))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(issue.name, style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w900)), Text(issue.employeeId, style: TextStyle(color: c.primary, fontSize: 9)), const SizedBox(height: 5), Text(resolved ? 'Resolved' : issue.title, style: TextStyle(color: resolved ? c.success : color, fontSize: 10, fontWeight: FontWeight.w900)), Text(issue.detail, style: TextStyle(color: c.muted, fontSize: 9))])), OutlinedButton(onPressed: resolved ? null : () => _resolveIssue(issue.id), style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color), visualDensity: VisualDensity.compact), child: Text(resolved ? 'Done' : 'Resolve'))])); }
  Widget _successCard(BuildContext context, String text) { final c = HrPalette.of(context); return HrCard(child: Row(children: [Icon(Icons.verified_rounded, color: c.success, size: 30), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: c.text, fontSize: 11, fontWeight: FontWeight.w800)))])); }
  Widget _salaryArc(BuildContext context, String label, double amount, Color color) { final c = HrPalette.of(context); return Column(children: [Icon(Icons.donut_large_rounded, color: color, size: 31), const SizedBox(height: 5), Text(label, style: TextStyle(color: c.muted, fontSize: 9)), Text(_money(amount), style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900))]); }
  Widget _salaryComponents(
    BuildContext context,
    String title,
    Color color,
    List<(String, double)> rows,
  ) {
    final c = HrPalette.of(context);
    final total = rows.fold<double>(0, (sum, row) => sum + row.$2);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _money(total),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: color, size: 15),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      row.$1,
                      style: TextStyle(color: c.text, fontSize: 10),
                    ),
                  ),
                  Text(
                    _money(row.$2),
                    style: TextStyle(
                      color: c.text,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Icon(Icons.edit_outlined, color: c.muted, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _publishMetric(BuildContext context, String value, String label) { final c = HrPalette.of(context); return Column(children: [Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.primary, fontSize: 17, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(color: c.muted, fontSize: 9))]); }
  Widget _timeline(BuildContext context, String title, String subtitle, bool done) { final c = HrPalette.of(context); return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [CircleAvatar(radius: 11, backgroundColor: done ? c.success : c.row, child: Icon(done ? Icons.check_rounded : Icons.schedule_rounded, color: done ? Colors.white : c.primary, size: 13)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: c.text, fontSize: 11, fontWeight: FontWeight.w800)), Text(subtitle, style: TextStyle(color: c.muted, fontSize: 8))])), Text(done ? 'Completed' : 'Ready', style: TextStyle(color: done ? c.success : c.primary, fontSize: 8, fontWeight: FontWeight.w900))])); }
  Widget _switchRow(BuildContext context, IconData icon, String title, bool value, ValueChanged<bool> changed) { final c = HrPalette.of(context); return SizedBox(height: 38, child: Row(children: [Icon(icon, color: c.muted, size: 17), const SizedBox(width: 8), Expanded(child: Text(title, style: TextStyle(color: c.text, fontSize: 10))), Switch(value: value, onChanged: changed, activeColor: c.primary)])); }

  List<(String, double)> _componentRows(Object? value) {
    if (value is! Map) return const [];
    return value.entries
        .map((entry) => (entry.key.toString(), double.tryParse('${entry.value}') ?? 0.0))
        .toList();
  }

  String _monthPeriod() { final now = DateTime.now(); final last = DateTime(now.year, now.month + 1, 0).day; return '01 ${_monthShort(now.month)} – $last ${_monthShort(now.month)} ${now.year}'; }
  String _monthShort(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
  String _money(Object? value) { final number = double.tryParse('$value') ?? 0; return '₹${number.toStringAsFixed(0)}'; }
}

class _PayrollIssue {
  final String id;
  final String employeeId;
  final String name;
  final String title;
  final String detail;
  final String colorKey;
  const _PayrollIssue({required this.id, required this.employeeId, required this.name, required this.title, required this.detail, required this.colorKey});
}
