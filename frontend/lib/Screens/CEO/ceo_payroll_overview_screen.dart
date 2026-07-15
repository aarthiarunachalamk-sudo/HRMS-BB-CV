import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoPayrollOverviewScreen extends StatefulWidget {
  final String userId;
  const CeoPayrollOverviewScreen({super.key, required this.userId});

  @override
  State<CeoPayrollOverviewScreen> createState() => _CeoPayrollOverviewScreenState();
}

class _CeoPayrollOverviewScreenState extends State<CeoPayrollOverviewScreen> {
  static const _filesChannel = MethodChannel('hrms/files');
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);
  int _page = 0;
  bool _busy = false;
  bool _declaration = false;
  bool _authorization = false;
  bool _showDeductions = false;
  bool _showPaymentHistory = false;
  String _query = '';
  Map<String, dynamic>? _selectedPayslip;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = CeoService().fetchPayrollOverview(
      widget.userId,
      year: _period.year,
      month: _period.month,
    );
  }

  Future<void> _changePeriod() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _period,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Select payroll month',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _period = DateTime(selected.year, selected.month);
      _selectedPayslip = null;
      _declaration = false;
      _authorization = false;
      _load();
    });
  }

  Future<void> _action(String action, {bool declaration = false}) async {
    if (_busy) return;
    final destructive = action == 'calculate' || action == 'publish';
    if (destructive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(action == 'publish' ? 'Publish Payroll' : 'Calculate Payroll'),
          content: Text(
            action == 'publish'
                ? 'Publish ${_monthName(_period)} payroll for all calculated employees?'
                : 'Calculate payslips from current salary, attendance, leave, and deduction data?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy = true);
    final result = await CeoService().updatePayrollOverview(
      widget.userId,
      year: _period.year,
      month: _period.month,
      action: action,
      declaration: declaration,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result['success'] == true) _load();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result['message'] ?? (result['success'] == true ? 'Payroll updated.' : 'Unable to update payroll.')}'),
        backgroundColor: result['success'] == true ? CeoColors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CeoShell(
    title: _titles[_page],
    onBack: _page == 0
        ? null
        : () => setState(() => _page--),
    trailing: _headerAction(),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: CeoColors.cyan));
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            muted('Unable to load payroll data', 12),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ]));
        }
        final data = snapshot.data!;
        return Stack(children: [
            Positioned.fill(child: _body(data)),
            if (_busy) const Positioned.fill(child: ColoredBox(
              color: Color(0x77000000),
              child: Center(child: CircularProgressIndicator(color: CeoColors.cyan)),
            )),
          ]);
      },
    ),
  );

  Widget? _headerAction() {
    if (_page == 0) {
      return IconButton(onPressed: _changePeriod, icon: const Icon(Icons.calendar_month, color: CeoColors.cyan));
    }
    if (_page == 1) {
      return IconButton(onPressed: () => _message('Processing stages use live employee validation and payroll records.'), icon: const Icon(Icons.help_outline, color: CeoColors.cyan));
    }
    if (_page == 2) {
      return IconButton(onPressed: () => setState(() => _showDeductions = !_showDeductions), icon: const Icon(Icons.filter_alt_outlined, color: CeoColors.cyan));
    }
    if (_page == 3) {
      return IconButton(onPressed: _selectedPayslip == null ? null : () => _openPayslip(_selectedPayslip!), icon: const Icon(Icons.file_download_outlined, color: CeoColors.cyan));
    }
    return null;
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _openPayslip(Map<String, dynamic> payslip) async {
    final url = '${payslip['download_url'] ?? ''}'.trim();
    if (url.isEmpty) {
      _message('No saved PDF is available for this payslip.');
      return;
    }
    try {
      final opened = await _filesChannel.invokeMethod<bool>('openUrl', {'url': url});
      if (opened != true && mounted) _message('Unable to open the payslip PDF.');
    } on PlatformException catch (error) {
      if (mounted) _message(error.message ?? 'Unable to open the payslip PDF.');
    }
  }

  Widget _body(Map<String, dynamic> data) => switch (_page) {
    1 => _processing(data),
    2 => _breakdown(data),
    3 => _review(data),
    4 => _publish(data),
    _ => _dashboard(data),
  };

  void _goReview(Map<String, dynamic> data) {
    final payslips = _maps(data['payslips']);
    setState(() {
      _selectedPayslip = payslips.isEmpty ? null : payslips.first;
      _showPaymentHistory = false;
      _page = 3;
    });
  }

  Widget _periodCard(Map<String, dynamic> data) => CeoCard(
    onTap: _changePeriod,
    child: Row(children: [
      const Icon(Icons.calendar_month, color: CeoColors.cyan),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [muted('Pay Period', 9), title('${data['period']}', 14)])),
      const Icon(Icons.expand_more, color: CeoColors.muted),
    ]),
  );

  Widget _dashboard(Map<String, dynamic> data) {
    final totals = _map(data['totals']);
    final employees = _map(data['employees']);
    final departments = _maps(data['departments']);
    final maxDepartment = departments.fold<double>(1, (max, item) => _num(item['amount']) > max ? _num(item['amount']) : max);
    return ListView(padding: const EdgeInsets.all(14), children: [
      _periodCard(data),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: CeoCard(onTap: () => setState(() => _page = 2), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          muted('Total Payroll Cost', 10),
          const SizedBox(height: 12),
          title(_money(totals['net']), 19),
          const SizedBox(height: 8),
          muted('${data['period']} • Monthly', 9),
        ]))),
        const SizedBox(width: 10),
        Expanded(child: CeoCard(onTap: () => _goReview(data), child: Row(children: [
          SizedBox(width: 58, height: 58, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: _num(employees['active']) == 0 ? 0 : _num(employees['processed']) / _num(employees['active']),
              strokeWidth: 8,
              color: CeoColors.cyan,
              backgroundColor: CeoColors.gold,
            ),
            Text('${employees['active'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w900)),
          ])),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            muted('Employees', 10),
            const SizedBox(height: 5),
            muted('Processed ${employees['processed'] ?? 0}', 8),
            muted('Pending ${employees['pending'] ?? 0}', 8),
          ])),
        ]))),
      ]),
      const SizedBox(height: 5),
      title('Payroll Summary', 14),
      const SizedBox(height: 8),
      CeoMetricGrid(cards: [
        CeoMetric('Gross Pay', _money(totals['gross']), '', Icons.account_balance_wallet, CeoColors.purple, onTap: () => setState(() => _page = 2)),
        CeoMetric('Deductions', _money(totals['deductions']), '', Icons.trending_down, CeoColors.gold, onTap: () { setState(() { _showDeductions = true; _page = 2; }); }),
        CeoMetric('Net Pay', _money(totals['net']), '', Icons.payments, CeoColors.green, onTap: () => setState(() => _page = 2)),
        CeoMetric('Processed', '${employees['processed'] ?? 0}', '', Icons.task_alt, CeoColors.cyan, onTap: () => _goReview(data)),
      ]),
      const SizedBox(height: 12),
      title('Top Departments by Payroll Cost', 14),
      const SizedBox(height: 8),
      CeoCard(child: Column(children: departments.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(children: [
          Row(children: [Expanded(child: title('${item['name']}', 11)), muted(_money(item['amount']), 10)]),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: _num(item['amount']) / maxDepartment, color: CeoColors.cyan, backgroundColor: CeoColors.border),
        ]),
      )).toList())),
      FilledButton.icon(
        onPressed: () => setState(() => _page = 1),
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Open Salary Processing'),
      ),
    ]);
  }

  Widget _processing(Map<String, dynamic> data) {
    final process = _map(data['process']);
    final validation = _maps(data['validation']);
    final stage = int.tryParse('${process['stage']}') ?? 0;
    final unresolved = int.tryParse('${data['unresolved_issues']}') ?? 0;
    final steps = ['Employee Data Sync', 'Validation', 'Salary Calculation', 'CEO Approval', 'Published'];
    return ListView(padding: const EdgeInsets.all(14), children: [
      _periodCard(data),
      CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title('Processing Steps', 14),
        const SizedBox(height: 10),
        ...steps.asMap().entries.map((entry) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: entry.key <= stage ? CeoColors.green : CeoColors.cardAlt,
            child: entry.key < stage ? const Icon(Icons.check, color: Colors.white) : Text('${entry.key + 1}'),
          ),
          title: title(entry.value, 12),
          subtitle: muted(entry.key < stage ? 'Completed' : entry.key == stage ? 'Current stage' : 'Pending', 9),
        )),
      ])),
      CeoMetricGrid(cards: [
        CeoMetric('Employees', '${_map(data['employees'])['active'] ?? 0}', '', Icons.groups, CeoColors.cyan),
        CeoMetric('Ready', '${validation.where((item) => item['ready'] == true).length}', '', Icons.verified, CeoColors.green),
        CeoMetric('Issues', '$unresolved', '', Icons.warning_amber, unresolved == 0 ? CeoColors.green : Colors.redAccent),
        CeoMetric('Processed', '${_map(data['employees'])['processed'] ?? 0}', '', Icons.task_alt, CeoColors.purple),
      ]),
      const SizedBox(height: 12),
      if (stage == 0) FilledButton(onPressed: () => _action('start'), child: const Text('Start Salary Processing')),
      if (stage == 1) FilledButton(onPressed: unresolved == 0 ? () => _action('validate') : null, child: Text(unresolved == 0 ? 'Complete Validation' : 'Resolve $unresolved Issues First')),
      if (stage == 2) FilledButton(onPressed: () => _action('calculate'), child: const Text('Calculate Payroll')),
      if (stage >= 3) FilledButton(onPressed: () => _goReview(data), child: const Text('Review Payslips')),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: () => _showValidation(validation), child: const Text('View Processing Details')),
    ]);
  }

  Widget _breakdown(Map<String, dynamic> data) {
    final totals = _map(data['totals']);
    final earnings = _maps(data['earnings']);
    final deductions = _maps(data['deductions']);
    return ListView(padding: const EdgeInsets.all(14), children: [
      SegmentedButton<bool>(
        segments: const [ButtonSegment(value: false, label: Text('Earnings')), ButtonSegment(value: true, label: Text('Deductions'))],
        selected: {_showDeductions},
        onSelectionChanged: (value) => setState(() => _showDeductions = value.first),
      ),
      const SizedBox(height: 12),
      CeoMetricGrid(cards: [
        CeoMetric('Total Earnings', _money(totals['earnings']), '', Icons.add_card, CeoColors.green),
        CeoMetric('Deductions', _money(totals['deductions']), '', Icons.remove_circle_outline, Colors.redAccent),
        CeoMetric('Gross Pay', _money(totals['gross']), '', Icons.account_balance_wallet, CeoColors.cyan),
        CeoMetric('Net Pay', _money(totals['net']), '', Icons.payments, CeoColors.purple),
      ]),
      const SizedBox(height: 12),
      title('Earnings Breakdown', 14),
      const SizedBox(height: 8),
      ...earnings.map((item) => _breakdownRow(item, totals['earnings'], false)),
      const SizedBox(height: 6),
      title('Deductions Breakdown', 14),
      const SizedBox(height: 8),
      ...deductions.map((item) => _breakdownRow(item, totals['deductions'], true)),
      FilledButton(onPressed: () => _goReview(data), child: const Text('Review Employee Payslips')),
    ]);
  }

  Widget _review(Map<String, dynamic> data) {
    final payslips = _maps(data['payslips']).where((item) => '${item['employee_name']} ${item['employee_id']}'.toLowerCase().contains(_query.toLowerCase())).toList();
    final selected = _selectedPayslip ?? (payslips.isEmpty ? null : payslips.first);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(14), child: TextField(
        onChanged: (value) => setState(() => _query = value),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search employee payslip'),
      )),
      if (selected != null) Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: [
        DropdownButtonFormField<Map<String, dynamic>>(
          value: payslips.contains(selected) ? selected : payslips.first,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Employee'),
          items: payslips.map((item) => DropdownMenuItem(value: item, child: Text('${item['employee_name']} • ${item['employee_id']}'))).toList(),
          onChanged: (value) => setState(() => _selectedPayslip = value),
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Payslip')),
            ButtonSegment(value: true, label: Text('Payment History')),
          ],
          selected: {_showPaymentHistory},
          onSelectionChanged: (value) => setState(() => _showPaymentHistory = value.first),
        ),
        const SizedBox(height: 10),
        if (_showPaymentHistory) _paymentHistoryCard(selected) else _payslipCard(selected),
        FilledButton(onPressed: () => setState(() => _page = 4), child: const Text('Next: Approve & Publish')),
      ])) else Expanded(child: Center(child: muted('No calculated payslips for this period', 12))),
    ]);
  }

  Widget _payslipCard(Map<String, dynamic> payslip) => CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    title('${payslip['employee_name']} • ${payslip['employee_id']}', 14),
    muted('${payslip['designation']} • ${payslip['department']}', 10),
    const Divider(color: CeoColors.border),
    title('Earnings', 12),
    ..._map(payslip['earnings']).entries.map((entry) => _amountRow(entry.key, entry.value, CeoColors.green)),
    _amountRow('Total Earnings', payslip['total_earnings'], CeoColors.cyan),
    const Divider(color: CeoColors.border),
    title('Deductions', 12),
    ..._map(payslip['deductions']).entries.map((entry) => _amountRow(entry.key, entry.value, Colors.redAccent)),
    _amountRow('Total Deductions', payslip['total_deductions'], Colors.redAccent),
    const Divider(color: CeoColors.border),
    _amountRow('Net Pay', payslip['net_salary'], CeoColors.green, bold: true),
  ]));

  Widget _publish(Map<String, dynamic> data) {
    final process = _map(data['process']);
    final employees = _map(data['employees']);
    final published = '${process['status']}' == 'published';
    return ListView(padding: const EdgeInsets.all(14), children: [
      _periodCard(data),
      CeoMetricGrid(cards: [
        CeoMetric('Employees', '${employees['processed'] ?? 0}', '', Icons.groups, CeoColors.cyan),
        CeoMetric('Net Payroll', _money(_map(data['totals'])['net']), '', Icons.payments, CeoColors.green),
      ]),
      const SizedBox(height: 12),
      CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title('Approval Workflow', 14),
        const SizedBox(height: 10),
        _workflowRow('Prepared', '${process['prepared_by'] ?? '-'}', '${process['status']}' != 'inputs'),
        _workflowRow('Validated', '${process['validated_at'] ?? '-'}', _hasValue(process['validated_at'])),
        _workflowRow('Calculated', '${process['calculated_at'] ?? '-'}', _hasValue(process['calculated_at'])),
        _workflowRow('Approved & Published', '${process['published_at'] ?? 'Pending'}', published),
      ])),
      CheckboxListTile(
        value: _declaration || published,
        onChanged: published ? null : (value) => setState(() => _declaration = value ?? false),
        title: const Text('I confirm that this payroll has been reviewed and verified.'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        value: _authorization || published,
        onChanged: published ? null : (value) => setState(() => _authorization = value ?? false),
        title: const Text('I authorize publication and payment initiation for this payroll period.'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      FilledButton.icon(
        onPressed: published || !_declaration || !_authorization ? null : () => _action('publish', declaration: true),
        icon: Icon(published ? Icons.check_circle : Icons.send),
        label: Text(published ? 'Payroll Published' : 'Approve & Publish Payroll'),
      ),
    ]);
  }

  void _showValidation(List<Map<String, dynamic>> items) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        children: [title('Payroll Validation', 16), const SizedBox(height: 12), ...items.map((item) => ListTile(
          leading: Icon(item['ready'] == true ? Icons.check_circle : Icons.warning, color: item['ready'] == true ? CeoColors.green : Colors.redAccent),
          title: Text('${item['employee_name']} • ${item['employee_id']}'),
          subtitle: Text(item['ready'] == true ? 'Ready for payroll' : [if (item['bank_missing'] == true) 'Bank details missing', if (item['attendance_conflict'] == true) 'Attendance incomplete', if (item['salary_configured'] != true) 'Salary not configured'].join(' • ')),
        ))],
      ),
    ),
  );

  Widget _breakdownRow(Map<String, dynamic> item, dynamic totalValue, bool deduction) {
    final total = _num(totalValue);
    return CeoCard(child: Row(children: [
      Icon(deduction ? Icons.remove_circle_outline : Icons.account_balance_wallet_outlined, color: deduction ? Colors.redAccent : CeoColors.cyan),
      const SizedBox(width: 10),
      Expanded(child: title('${item['name']}', 11)),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        title(_money(item['amount']), 11),
        muted('${total == 0 ? '0.0' : (_num(item['amount']) / total * 100).toStringAsFixed(1)}%', 9),
      ]),
    ]));
  }

  Widget _paymentHistoryCard(Map<String, dynamic> payslip) => CeoCard(
    child: Column(children: [
      _detailRow('Payroll Status', payslip['status']),
      _detailRow('Generated At', payslip['generated_at']),
      _detailRow('Paid Date', payslip['paid_date']),
      _amountRow('Net Amount', payslip['net_salary'], CeoColors.green, bold: true),
    ]),
  );

  Widget _detailRow(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Expanded(child: muted(label, 10)),
      Text('${value ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _workflowRow(String label, String detail, bool complete) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(backgroundColor: complete ? CeoColors.green : CeoColors.cardAlt, child: Icon(complete ? Icons.check : Icons.schedule, color: Colors.white)),
    title: title(label, 12),
    subtitle: muted(detail, 9),
  );

  Widget _amountRow(String label, dynamic amount, Color color, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500))), Text(_money(amount), style: TextStyle(color: color, fontWeight: FontWeight.w900))]),
  );

  static Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};
  static List<Map<String, dynamic>> _maps(dynamic value) => value is List ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : [];
  static double _num(dynamic value) => double.tryParse('$value') ?? 0;
  static bool _hasValue(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isNotEmpty && text != 'null';
  }
  static String _money(dynamic value) {
    final amount = _num(value).round().toString();
    final chars = amount.split('').reversed.toList();
    final groups = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) groups.add(',');
      groups.add(chars[i]);
    }
    return '\u20B9${groups.reversed.join()}';
  }
  static String _monthName(DateTime date) => '${_months[date.month - 1]} ${date.year}';
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _titles = ['Payroll Dashboard', 'Salary Processing', 'Earnings & Deductions', 'Payslip Review', 'Approve & Publish'];
}
