import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

import 'ceo_leave_request_screen.dart';
import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoApprovalCategoryScreen extends StatefulWidget {
  final String category;
  final String title;
  final String userId;

  const CeoApprovalCategoryScreen({
    super.key,
    required this.category,
    required this.title,
    required this.userId,
  });

  @override
  State<CeoApprovalCategoryScreen> createState() =>
      _CeoApprovalCategoryScreenState();
}

class _CeoApprovalCategoryScreenState extends State<CeoApprovalCategoryScreen> {
  bool _history = false;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = CeoService().fetchApprovalCategory(
      widget.category,
      widget.userId,
      history: _history,
    );
  }

  void _selectHistory(bool history) {
    if (_history == history) return;
    setState(() {
      _history = history;
      _load();
    });
  }

  Future<void> _openItem(Map<String, dynamic> item) async {
    if (widget.category == 'leave') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CeoLeaveRequestScreen(
            approvalId: '${item['id'] ?? ''}',
            userId: widget.userId,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CeoApprovalDetailScreen(categoryTitle: widget.title, item: item),
        ),
      );
    }
    if (!mounted) return;
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: widget.title,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    label: 'Pending',
                    selected: !_history,
                    onTap: () => _selectHistory(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterButton(
                    label: 'History',
                    selected: _history,
                    onTap: () => _selectHistory(true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
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
                    child: muted('Unable to load approval data', 12),
                  );
                }
                final rawItems = snapshot.data?['items'];
                final items = rawItems is List
                    ? rawItems
                          .whereType<Map>()
                          .map((item) => Map<String, dynamic>.from(item))
                          .toList()
                    : <Map<String, dynamic>>[];
                if (items.isEmpty) {
                  return pageList([
                    CeoCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: muted(
                            _history
                                ? 'No ${widget.title.toLowerCase()} history'
                                : 'No pending ${widget.title.toLowerCase()} records from backend',
                            12,
                          ),
                        ),
                      ),
                    ),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return CeoListTile(
                      icon: _categoryIcon(widget.category),
                      titleText: _text(item['title'], fallback: widget.title),
                      subtitle: _text(
                        item['subtitle'],
                        fallback: _text(item['status'], fallback: 'Pending'),
                      ),
                      color: _history ? CeoColors.muted : CeoColors.purple,
                      onTap: () => _openItem(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CeoApprovalDetailScreen extends StatelessWidget {
  final String categoryTitle;
  final Map<String, dynamic> item;

  const CeoApprovalDetailScreen({
    super.key,
    required this.categoryTitle,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final rawDetails = item['details'];
    final details = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : <String, dynamic>{};
    return CeoShell(
      title: '$categoryTitle Details',
      child: pageList([
        CeoListTile(
          icon: Icons.approval_rounded,
          titleText: _text(item['title'], fallback: categoryTitle),
          subtitle: _text(item['subtitle'], fallback: 'Approval details'),
          color: CeoColors.purple,
        ),
        CeoCard(
          child: details.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: muted('No detail data from backend', 12),
                  ),
                )
              : Column(
                  children: details.entries.map((entry) {
                    return Column(
                      children: [
                        _DetailRow(
                          entry.key,
                          _text(entry.value, fallback: '-'),
                        ),
                        if (entry.key != details.keys.last)
                          const Divider(color: CeoColors.border, height: 1),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ]),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? CeoColors.cyan : CeoColors.muted,
        backgroundColor: selected
            ? CeoColors.cyan.withValues(alpha: 0.10)
            : Colors.transparent,
        side: BorderSide(color: selected ? CeoColors.cyan : CeoColors.border),
      ),
      child: Text(label),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: muted(label, 12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: ThemeConfig.getTextPrimary(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'leave':
      return Icons.event_available_rounded;
    case 'claim':
      return Icons.receipt_long_rounded;
    case 'salary':
      return Icons.payments_rounded;
    case 'hiring':
      return Icons.person_add_alt_1_rounded;
    case 'budget':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.approval_rounded;
  }
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value == null ? '' : '$value'.trim();
  return text.isEmpty || text == 'null' ? fallback : text;
}
