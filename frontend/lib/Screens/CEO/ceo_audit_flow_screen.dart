import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoAuditFlowScreen extends StatefulWidget {
  final String userId;

  const CeoAuditFlowScreen({super.key, required this.userId});

  @override
  State<CeoAuditFlowScreen> createState() => _CeoAuditFlowScreenState();
}

class _CeoAuditFlowScreenState extends State<CeoAuditFlowScreen> {
  int _page = 0;
  bool _busy = false;
  String _search = '';
  String _user = 'All';
  String _format = 'pdf';
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  final Set<String> _modules = {'All'};
  final Set<String> _severities = {'All'};
  final Set<String> _include = {
    'Event Summary', 'Timeline', 'User Details', 'Change Details',
    'IP & Location', 'Device Information', 'Notes & Comments',
  };
  Map<String, dynamic>? _selected;
  late Future<Map<String, dynamic>> _future;

  Map<String, dynamic> get _filters => {
    'search': _search,
    'user': _user,
    'date_from': _iso(_range.start),
    'date_to': _iso(_range.end),
    'modules': _modules.toList(),
    'severities': _severities.toList(),
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = CeoService().fetchAuditFlow(widget.userId, _filters);
  }

  void _applyFilters() {
    setState(() {
      _reload();
      _page = 1;
    });
  }

  void _resetFilters() {
    setState(() {
      _search = '';
      _user = 'All';
      _modules..clear()..add('All');
      _severities..clear()..add('All');
      _range = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: const ['Audit Dashboard', 'Activity Timeline', 'Filters', 'Log Details', 'Export Audit Report'][_page],
      onBack: _page == 0 ? null : () => setState(() => _page = _page == 3 ? 1 : _page - 1),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page == 0 ? 0 : 3,
        onDestinationSelected: (index) {
          if (index == 0) setState(() => _page = 0);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'People'),
          NavigationDestination(icon: Icon(Icons.approval_outlined), label: 'Approvals'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CeoColors.cyan));
          }
          if (snapshot.hasError || snapshot.data?['success'] != true) {
            return Center(child: OutlinedButton(
              onPressed: () => setState(_reload),
              child: const Text('Retry audit logs'),
            ));
          }
          final data = snapshot.data!;
          return Stack(children: [
            Positioned.fill(child: switch (_page) {
              1 => _timeline(data),
              2 => _filterView(data),
              3 => _detail(),
              4 => _export(data),
              _ => _dashboard(data),
            }),
            if (_busy) const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99000000),
                child: Center(child: CircularProgressIndicator(color: CeoColors.cyan)),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _dashboard(Map<String, dynamic> data) {
    final summary = _map(data['summary']);
    final modules = _maps(data['module_counts']);
    return ListView(padding: const EdgeInsets.all(14), children: [
      Row(children: [
        Expanded(child: title('Audit Logs', 18)),
        IconButton(onPressed: () => setState(() => _page = 2), icon: const Icon(Icons.filter_alt_outlined)),
      ]),
      CeoMetricGrid(cards: [
        CeoMetric('Total Events', '${summary['total_events'] ?? 0}', 'Selected period', Icons.receipt_long, CeoColors.cyan),
        CeoMetric('Users', '${summary['users'] ?? 0}', 'Active in logs', Icons.people, CeoColors.blue),
        CeoMetric('Modules', '${summary['modules'] ?? 0}', 'With activity', Icons.hub_outlined, CeoColors.green),
        CeoMetric('Critical Events', '${summary['critical_events'] ?? 0}', 'Requires review', Icons.warning_amber, CeoColors.red),
      ]),
      const SizedBox(height: 14),
      title('Top Modules', 14),
      const SizedBox(height: 8),
      CeoCard(child: Column(children: modules.take(8).map((item) => ListTile(
        leading: const Icon(Icons.apps, color: CeoColors.cyan),
        title: Text('${item['module']}'.isEmpty ? 'System' : '${item['module']}'),
        trailing: Text('${item['count']}'),
      )).toList())),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: () => setState(() => _page = 1),
        icon: const Icon(Icons.timeline),
        label: const Text('View Activity Timeline'),
      ),
    ]);
  }

  Widget _timeline(Map<String, dynamic> data) {
    final logs = _maps(data['logs']);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(child: TextField(
            onSubmitted: (value) { _search = value.trim(); _applyFilters(); },
            decoration: InputDecoration(
              hintText: 'Search event, user, module or ID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _page = 2),
                icon: const Icon(Icons.filter_alt_outlined),
              ),
            ),
          )),
          IconButton(onPressed: () => setState(() => _page = 4), icon: const Icon(Icons.ios_share)),
        ]),
      ),
      Expanded(child: logs.isEmpty
        ? Center(child: CeoCard(child: muted('No audit events match the selected filters.', 11)))
        : RefreshIndicator(
            onRefresh: () async { setState(_reload); await _future; },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              itemCount: logs.length,
              itemBuilder: (_, index) {
                final log = logs[index];
                return CeoListTile(
                  icon: _severityIcon('${log['severity']}'),
                  titleText: '${log['title']}',
                  subtitle: '${log['user_name']} • ${log['module']}\n${_date('${log['created_at']}')}',
                  onTap: () => setState(() { _selected = log; _page = 3; }),
                );
              },
            ),
          )),
    ]);
  }

  Widget _filterView(Map<String, dynamic> data) {
    final users = _maps(data['users']);
    final userIds = ['All', ...users.map((item) => '${item['user_id']}')];
    final modules = ['All', ...((data['modules'] as List?) ?? const []).map((x) => '$x')];
    return ListView(padding: const EdgeInsets.all(14), children: [
      Row(children: [Expanded(child: title('User & Module Filters', 16)), TextButton(onPressed: _resetFilters, child: const Text('Reset'))]),
      TextField(
        controller: TextEditingController(text: _search),
        onChanged: (value) => _search = value,
        decoration: const InputDecoration(labelText: 'Search', prefixIcon: Icon(Icons.search)),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: userIds.contains(_user) ? _user : 'All',
        items: userIds.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
        onChanged: (value) => setState(() => _user = value ?? 'All'),
        decoration: const InputDecoration(labelText: 'Select User'),
      ),
      const SizedBox(height: 14),
      title('Modules', 13),
      Wrap(spacing: 7, runSpacing: 5, children: modules.map((value) => FilterChip(
        label: Text(value), selected: _modules.contains(value),
        onSelected: (_) => setState(() => _toggle(_modules, value)),
      )).toList()),
      const SizedBox(height: 14),
      title('Event Severity', 13),
      ...['All', 'info', 'success', 'warning', 'error'].map((value) => CheckboxListTile(
        dense: true, contentPadding: EdgeInsets.zero, title: Text(_label(value)),
        value: _severities.contains(value),
        onChanged: (_) => setState(() => _toggle(_severities, value)),
      )),
      CeoCard(onTap: _pickRange, child: _row('Date Range', '${_iso(_range.start)} – ${_iso(_range.end)}')),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _applyFilters, icon: const Icon(Icons.check), label: const Text('Apply Filters')),
    ]);
  }

  Widget _detail() {
    final log = _selected ?? const <String, dynamic>{};
    return ListView(padding: const EdgeInsets.all(14), children: [
      CeoCard(child: Column(children: [
        ListTile(
          leading: CircleAvatar(child: Icon(_severityIcon('${log['severity']}'))),
          title: Text('${log['title'] ?? 'Audit Event'}'),
          subtitle: Text('${log['event_id'] ?? ''}\n${_date('${log['created_at'] ?? ''}')}'),
        ),
      ])),
      const SizedBox(height: 10),
      title('Event Information', 14),
      CeoCard(child: Column(children: [
        _row('Module', log['module']), _row('Severity', log['severity']),
        _row('Description', log['description']), _row('Record ID', log['reference_id']),
        _row('Read Status', log['is_read'] == true ? 'Read' : 'Unread'),
      ])),
      const SizedBox(height: 10),
      title('User Information', 14),
      CeoCard(child: Column(children: [
        _row('User Name', log['user_name']), _row('User ID', log['user_id']),
        _row('Email', log['user_email']), _row('Role', log['role']),
      ])),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () => setState(() => _page = 4), icon: const Icon(Icons.mail_outline), label: const Text('Export Audit Report')),
    ]);
  }

  Widget _export(Map<String, dynamic> data) {
    final total = _map(data['summary'])['total_events'] ?? 0;
    return ListView(padding: const EdgeInsets.all(14), children: [
      CeoCard(child: Column(children: [
        _row('Report Name', 'Audit Log Report'), _row('Date Range', '${_iso(_range.start)} – ${_iso(_range.end)}'),
        _row('Users', _user), _row('Modules', _modules.join(', ')), _row('Total Events', total),
        _row('Deliver To', data['email']),
      ])),
      const SizedBox(height: 14),
      title('Select Format', 14),
      ...{'pdf': 'PDF', 'excel': 'Excel (XLS)', 'csv': 'CSV', 'json': 'JSON'}.entries.map((entry) => RadioListTile<String>(
        value: entry.key, groupValue: _format, title: Text(entry.value),
        onChanged: (value) => setState(() => _format = value!),
      )),
      title('Include in Report', 14),
      ...['Event Summary', 'Timeline', 'User Details', 'Change Details', 'IP & Location', 'Device Information', 'Notes & Comments'].map((value) => CheckboxListTile(
        dense: true, contentPadding: EdgeInsets.zero, title: Text(value), value: _include.contains(value),
        onChanged: (_) => setState(() => _include.contains(value) ? _include.remove(value) : _include.add(value)),
      )),
      FilledButton.icon(
        onPressed: _busy || _include.isEmpty ? null : _emailReport,
        icon: const Icon(Icons.mark_email_read_outlined),
        label: const Text('Email Audit Report'),
      ),
      Padding(padding: const EdgeInsets.only(top: 8), child: muted('The document will be attached to an email sent to the CEO account.', 10)),
    ]);
  }

  Future<void> _emailReport() async {
    setState(() => _busy = true);
    try {
      final result = await CeoService().emailAuditReport(widget.userId, _filters, _format, _include.toList());
      if (mounted) _message('${result['message'] ?? 'Unable to email audit report.'}');
    } catch (error) {
      if (mounted) _message('Unable to email audit report: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickRange() async {
    final value = await showDateRangePicker(
      context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: _range,
    );
    if (value != null) setState(() => _range = value);
  }

  void _toggle(Set<String> values, String value) {
    if (value == 'All') { values..clear()..add('All'); return; }
    values.remove('All');
    values.contains(value) ? values.remove(value) : values.add(value);
    if (values.isEmpty) values.add('All');
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  Widget _row(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: muted(label, 9)), Expanded(child: Text('${value ?? '-'}')),
    ]),
  );
  static IconData _severityIcon(String value) => switch (value) {
    'error' => Icons.error_outline, 'warning' => Icons.warning_amber, 'success' => Icons.check_circle_outline,
    _ => Icons.info_outline,
  };
  static String _label(String value) => value == 'error' ? 'Critical' : '${value[0].toUpperCase()}${value.substring(1)}';
  static String _date(String value) => value.isEmpty ? '-' : value.replaceFirst('T', ' ').split('.').first;
  static String _iso(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};
  static List<Map<String, dynamic>> _maps(dynamic value) => value is List ? value.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList() : [];
}
