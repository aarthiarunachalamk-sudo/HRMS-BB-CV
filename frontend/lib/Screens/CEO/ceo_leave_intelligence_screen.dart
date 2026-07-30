import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/separated_date_picker.dart';

import 'ceo_leave_request_screen.dart';
import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoLeaveIntelligenceScreen extends StatefulWidget {
  final String userId;

  const CeoLeaveIntelligenceScreen({super.key, required this.userId});

  @override
  State<CeoLeaveIntelligenceScreen> createState() =>
      _CeoLeaveIntelligenceScreenState();
}

class _CeoLeaveIntelligenceScreenState
    extends State<CeoLeaveIntelligenceScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  int _page = 0;
  String _status = 'all';
  String _query = '';
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = CeoService().fetchLeaveIntelligence(
      widget.userId,
      year: _month.year,
      month: _month.month,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDate = _month;
      _load();
    });
  }

  void _displayedMonthChanged(DateTime displayedMonth) {
    if (displayedMonth.year == _month.year &&
        displayedMonth.month == _month.month) {
      return;
    }
    setState(() {
      _month = DateTime(displayedMonth.year, displayedMonth.month);
      _selectedDate = _month;
      _load();
    });
  }

  Future<void> _openRequest(Map<String, dynamic> request) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CeoLeaveRequestScreen(
          approvalId: '${request['id'] ?? ''}',
          userId: widget.userId,
        ),
      ),
    );
    if (!mounted) return;
    setState(_load);
  }

  Future<void> _announceCompanyLeave() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    DateTimeRange range = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Announce Company Leave'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Example: Company Foundation Day',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Company leave dates'),
                  subtitle: Text(
                    '${_isoDate(range.start)} to ${_isoDate(range.end)}',
                  ),
                  trailing: const Icon(Icons.date_range_rounded),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      initialDateRange: range,
                    );
                    if (picked != null) setDialogState(() => range = picked);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Announcement message',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, true);
                }
              },
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Announce'),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && mounted) {
      try {
        final result = await CeoService().announceCompanyLeave(
          widget.userId,
          title: titleController.text.trim(),
          fromDate: range.start,
          toDate: range.end,
          message: messageController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result['message'] ?? 'Company leave announced'}',
              ),
            ),
          );
          setState(_load);
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
    }
    titleController.dispose();
    messageController.dispose();
  }

  String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => CeoShell(
    title: _titles[_page],
    trailing: PopupMenuButton<int>(
      icon: const Icon(Icons.more_horiz_rounded, color: CeoColors.cyan),
      onSelected: (value) {
        if (value == 99) {
          setState(_load);
        } else {
          setState(() => _page = value);
        }
      },
      itemBuilder: (_) => [
        ...List.generate(
          _titles.length,
          (index) => PopupMenuItem(value: index, child: Text(_titles[index])),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 99,
          child: Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Refresh data'),
            ],
          ),
        ),
      ],
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: CeoColors.cyan),
          );
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                muted('Unable to load live leave data', 12),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => setState(_load),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        return Column(
          children: [
            _FlowTabs(
              selected: _page,
              onSelected: (i) => setState(() => _page = i),
            ),
            Expanded(child: _body(data)),
          ],
        );
      },
    ),
  );

  Widget _body(Map<String, dynamic> data) {
    if (_page == 1) return _requests(data);
    if (_page == 2) return _calendar(data);
    if (_page == 3) return _requests(data, pendingOnly: true);
    if (_page == 4) return _analytics(data);
    return _dashboard(data);
  }

  Widget _dashboard(Map<String, dynamic> data) {
    final summary = _map(data['summary']);
    final requests = _maps(data['requests']);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        CeoMetricGrid(
          cards: [
            CeoMetric(
              'Total Requests',
              '${summary['total'] ?? 0}',
              '',
              Icons.event_note,
              CeoColors.cyan,
              onTap: () => setState(() {
                _status = 'all';
                _page = 1;
              }),
            ),
            CeoMetric(
              'Pending',
              '${summary['pending'] ?? 0}',
              '',
              Icons.pending_actions,
              CeoColors.gold,
              onTap: () => setState(() => _page = 3),
            ),
            CeoMetric(
              'Approved',
              '${summary['approved'] ?? 0}',
              '',
              Icons.event_available,
              CeoColors.green,
              onTap: () => setState(() {
                _status = 'approved';
                _page = 1;
              }),
            ),
            CeoMetric(
              'Rejected',
              '${summary['rejected'] ?? 0}',
              '',
              Icons.event_busy,
              Colors.redAccent,
              onTap: () => setState(() {
                _status = 'rejected';
                _page = 1;
              }),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _announceCompanyLeave,
          icon: const Icon(Icons.campaign_rounded),
          label: const Text('Announce Company Leave'),
        ),
        const SizedBox(height: 14),
        _heading(
          'Recent Leave Requests',
          action: 'View all',
          onTap: () => setState(() => _page = 1),
        ),
        ...requests.take(5).map(_requestCard),
        const SizedBox(height: 8),
        _navButton('Open Calendar & Balance', Icons.calendar_month, 2),
        _navButton('View Leave Analytics', Icons.analytics_outlined, 4),
      ],
    );
  }

  Widget _requests(Map<String, dynamic> data, {bool pendingOnly = false}) {
    final requests = _maps(data['requests']).where((item) {
      final status = '${item['overall_status'] ?? item['status']}'
          .toLowerCase();
      final effectiveStatus = pendingOnly ? 'pending' : _status;
      final matchesStatus =
          effectiveStatus == 'all' || status.contains(effectiveStatus);
      final haystack =
          '${item['name']} ${item['employee_id']} ${item['leave_type']}'
              .toLowerCase();
      return matchesStatus && haystack.contains(_query.toLowerCase());
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search requests',
            ),
          ),
        ),
        if (!pendingOnly)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: ['all', 'pending', 'approved', 'rejected']
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          status[0].toUpperCase() + status.substring(1),
                        ),
                        selected: _status == status,
                        onSelected: (_) => setState(() => _status = status),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: requests.isEmpty
              ? Center(child: muted('No matching leave requests', 12))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: requests.map(_requestCard).toList(),
                ),
        ),
      ],
    );
  }

  Widget _calendar(Map<String, dynamic> data) {
    final calendarItems = [
      ..._maps(data['calendar']),
      ..._maps(
        data['company_leaves'],
      ).map((item) => {...item, 'company_leave': true}),
    ];
    final selected = calendarItems.where((item) {
      final from = DateTime.tryParse('${item['from_date']}');
      final to = DateTime.tryParse('${item['to_date']}');
      if (from == null || to == null) return false;
      final day = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      return !day.isBefore(from) && !day.isAfter(to);
    }).toList();
    final balances = _maps(data['balances']);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: title('${_months[_month.month - 1]} ${_month.year}', 15),
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        CeoCard(
          child: SeparatedCalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            onDateChanged: (date) => setState(() => _selectedDate = date),
            onDisplayedMonthChanged: _displayedMonthChanged,
          ),
        ),
        _heading(
          'Leave on ${_selectedDate.day} ${_months[_selectedDate.month - 1]}',
        ),
        if (selected.isEmpty)
          CeoCard(child: Center(child: muted('No leave on selected date', 11))),
        ...selected.map((item) {
          final isCompanyLeave = item['company_leave'] == true;
          return CeoListTile(
            icon: isCompanyLeave ? Icons.business_rounded : Icons.beach_access,
            titleText: isCompanyLeave ? '${item['title']}' : '${item['name']}',
            subtitle: isCompanyLeave
                ? 'Company Leave - ${item['message'] ?? ''}'
                : '${item['leave_type']} - ${item['status']}',
            color: isCompanyLeave
                ? CeoColors.cyan
                : _statusColor('${item['status']}'),
            onTap: isCompanyLeave ? null : () => _openRequest(item),
          );
        }),
        const SizedBox(height: 8),
        _heading('Organization Leave Balance'),
        ...balances.map(
          (item) => CeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: title('${item['type']}', 12)),
                    muted(
                      '${item['available']} / ${item['entitlement']} days',
                      10,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _ratio(item['available'], item['entitlement']),
                  color: CeoColors.cyan,
                  backgroundColor: CeoColors.border,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _analytics(Map<String, dynamic> data) {
    final summary = _map(data['summary']);
    final types = _maps(data['types']);
    final trend = _maps(data['trend']);
    final maxTrend = trend.fold<double>(1, (max, item) {
      final total =
          _number(item['approved']) +
          _number(item['pending']) +
          _number(item['rejected']);
      return total > max ? total : max;
    });
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        CeoMetricGrid(
          cards: [
            CeoMetric(
              'Total Leaves',
              '${summary['total'] ?? 0}',
              '',
              Icons.event_note,
              CeoColors.cyan,
            ),
            CeoMetric(
              'Approved',
              '${summary['approved'] ?? 0}',
              '',
              Icons.check_circle,
              CeoColors.green,
            ),
            CeoMetric(
              'Pending',
              '${summary['pending'] ?? 0}',
              '',
              Icons.schedule,
              CeoColors.gold,
            ),
            CeoMetric(
              'Rejected',
              '${summary['rejected'] ?? 0}',
              '',
              Icons.cancel,
              Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _heading('Monthly Leave Trend'),
        CeoCard(
          child: Column(
            children: trend.map((item) {
              final total =
                  _number(item['approved']) +
                  _number(item['pending']) +
                  _number(item['rejected']);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(width: 32, child: muted('${item['month']}', 9)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: total / maxTrend,
                        color: CeoColors.green,
                        backgroundColor: CeoColors.border,
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text('${total.toInt()}', textAlign: TextAlign.end),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        _heading('Leave by Type'),
        ...types.map(
          (item) => CeoListTile(
            icon: Icons.donut_large,
            titleText: '${item['type']}',
            subtitle: '${item['count']} requests • ${item['days']} days',
            color: CeoColors.cyan,
          ),
        ),
      ],
    );
  }

  Widget _requestCard(Map<String, dynamic> item) => CeoListTile(
    icon: Icons.person_outline,
    titleText: '${item['name'] ?? 'Employee'}',
    subtitle:
        '${item['leave_type'] ?? 'Leave'} • ${item['from_date']} • ${item['status']}',
    color: _statusColor('${item['overall_status'] ?? item['status']}'),
    onTap: () => _openRequest(item),
  );

  Widget _heading(String text, {String? action, VoidCallback? onTap}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          children: [
            Expanded(child: title(text, 14)),
            if (action != null)
              TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      );

  Widget _navButton(String label, IconData icon, int page) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: OutlinedButton.icon(
      onPressed: () => setState(() => _page = page),
      icon: Icon(icon),
      label: Text(label),
    ),
  );

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
  static double _number(dynamic value) => double.tryParse('$value') ?? 0;
  static double _ratio(dynamic value, dynamic total) => _number(total) <= 0
      ? 0
      : (_number(value) / _number(total)).clamp(0, 1).toDouble();
  static Color _statusColor(String value) {
    final status = value.toLowerCase();
    if (status.contains('approved')) return CeoColors.green;
    if (status.contains('rejected')) return Colors.redAccent;
    return CeoColors.gold;
  }

  static const _titles = [
    'Leave Intelligence',
    'Leave Requests',
    'Calendar & Balance',
    'Approve / Reject',
    'Leave Analytics',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}

class _FlowTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  const _FlowTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      scrollDirection: Axis.horizontal,
      itemCount: _CeoLeaveIntelligenceScreenState._titles.length,
      separatorBuilder: (_, __) => const SizedBox(width: 7),
      itemBuilder: (_, index) => ChoiceChip(
        label: Text(
          '${index + 1}. ${_CeoLeaveIntelligenceScreenState._titles[index]}',
        ),
        selected: selected == index,
        onSelected: (_) => onSelected(index),
      ),
    ),
  );
}
