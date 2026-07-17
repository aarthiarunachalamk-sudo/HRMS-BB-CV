import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:http/http.dart' as http;

abstract class MdDatabaseFlowScreen extends StatefulWidget {
  final String userId;
  final String module;
  final String screenTitle;
  final IconData icon;

  const MdDatabaseFlowScreen({
    super.key,
    required this.userId,
    required this.module,
    required this.screenTitle,
    required this.icon,
  });

  @override
  State<MdDatabaseFlowScreen> createState() => _MdDatabaseFlowScreenState();
}

class _MdDatabaseFlowScreenState extends State<MdDatabaseFlowScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _requiresAction(Map<String, dynamic> item) {
    final value = '${item['title']} ${item['subtitle']} ${item['detail']}'.toLowerCase();
    return ['pending', 'critical', 'at risk', 'overdue', 'required', 'warning', 'failed']
        .any(value.contains);
  }

  Color _accent() {
    const colors = [
      Color(0xFF00C6FF),
      Color(0xFF9F3BFF),
      Color(0xFF00D6A3),
      Color(0xFFFFB52E),
      Color(0xFFFF5263),
    ];
    return colors[widget.module.codeUnits.fold<int>(0, (sum, item) => sum + item) % colors.length];
  }

  String _subtitle() {
    const subtitles = {
      'company-overview': 'Organization Intelligence',
      'financial-insights': 'Financial Analysis Center',
      'department-performance': 'Department Intelligence',
      'project-portfolio': 'Strategic Project Control',
      'approvals-center': 'Management Decision Center',
      'workforce-analytics': 'People & Workforce Intelligence',
      'leadership-team': 'Executive Leadership Directory',
      'critical-alerts': 'Priority Risk Monitoring',
      'executive-reports': 'Executive Reporting Center',
      'meetings': 'Executive Meeting Center',
      'announcements': 'Organization Communications',
      'documents': 'Executive Document Center',
      'settings-preferences': 'Account & Application Controls',
    };
    return subtitles[widget.module] ?? 'Management Intelligence';
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final response = await http.get(
      ApiConfig.uri('/md/modules/${widget.module}/?user_id=${Uri.encodeQueryComponent(widget.userId)}'),
    ).timeout(const Duration(seconds: 60));
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded is! Map || decoded['success'] != true) {
      throw Exception(decoded is Map ? decoded['message'] ?? 'Unable to load ${widget.screenTitle}' : 'Invalid backend response');
    }
    final rawItems = decoded['items'];
    return rawItems is List
        ? rawItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final background = ThemeConfig.getBgStart(context);
    final card = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final text = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        title: Text(widget.screenTitle),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: muted)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          final query = _searchController.text.trim().toLowerCase();
          final actionCount = items.where(_requiresAction).length;
          final filtered = items.where((item) {
            final searchable = '${item['title']} ${item['subtitle']} ${item['detail']}'.toLowerCase();
            final matchesQuery = query.isEmpty || searchable.contains(query);
            final matchesFilter = _filter == 'All' ||
                (_filter == 'Needs Action' ? _requiresAction(item) : !_requiresAction(item));
            return matchesQuery && matchesFilter;
          }).toList();
          final accent = _accent();
          return RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              children: [
                Text(_subtitle(), textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withAlpha(45), card, ThemeConfig.purpleAccent.withAlpha(25)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withAlpha(120)),
                    boxShadow: [BoxShadow(color: accent.withAlpha(25), blurRadius: 24, spreadRadius: 2)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accent, ThemeConfig.purpleAccent]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 38),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Live Database Analysis', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 5),
                            Text('${items.length} records synchronized', style: TextStyle(color: muted, fontSize: 12)),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: items.isEmpty ? 0 : 1,
                                minHeight: 6,
                                color: accent,
                                backgroundColor: border,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(color: accent.withAlpha(25), borderRadius: BorderRadius.circular(10), border: Border.all(color: accent.withAlpha(100))),
                        child: Text('LIVE', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _AnalysisTile(label: 'Total Records', value: '${items.length}', icon: Icons.storage_outlined, color: accent, card: card, border: border, text: text, muted: muted)),
                    const SizedBox(width: 10),
                    Expanded(child: _AnalysisTile(label: 'Needs Action', value: '$actionCount', icon: Icons.notification_important_outlined, color: actionCount > 0 ? const Color(0xFFFF5263) : const Color(0xFF00D6A3), card: card, border: border, text: text, muted: muted)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.screenTitle.toLowerCase()}...',
                    hintStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.search_rounded, color: accent),
                    suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: Icon(Icons.close_rounded, color: muted)),
                    filled: true,
                    fillColor: card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Needs Action', 'Other'].map((label) {
                      final selected = _filter == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = label),
                          selectedColor: accent.withAlpha(50),
                          side: BorderSide(color: selected ? accent : border),
                          labelStyle: TextStyle(color: selected ? accent : muted, fontWeight: FontWeight.w800),
                          backgroundColor: card,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: Text('DATABASE RECORDS', style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w900))),
                    Text('${filtered.length} shown', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                    child: Column(
                      children: [
                        Icon(widget.icon, color: muted, size: 46),
                        const SizedBox(height: 10),
                        Text(items.isEmpty ? 'No database records available' : 'No matching records', style: TextStyle(color: text, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text(items.isEmpty ? 'Records added to the backend will appear here.' : 'Change the search or selected filter.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ...filtered.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final needsAction = _requiresAction(item);
                  return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: needsAction ? const Color(0xFFFF5263).withAlpha(110) : border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: accent.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                        child: Text('${index + 1}', style: TextStyle(color: accent, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item['title'] ?? ''}', style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                            if ('${item['subtitle'] ?? ''}'.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('${item['subtitle']}', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12)),
                            ],
                            if ('${item['detail'] ?? ''}'.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text('${item['detail']}', style: TextStyle(color: needsAction ? const Color(0xFFFF5263) : accent, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: muted),
                    ],
                  ),
                );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;

  const _AnalysisTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(color: text, fontSize: 19, fontWeight: FontWeight.w900)),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );
}

class MdCompanyOverviewScreen extends MdDatabaseFlowScreen { const MdCompanyOverviewScreen({super.key, required super.userId}) : super(module: 'company-overview', screenTitle: 'Company Overview', icon: Icons.apartment_rounded); }
class MdFinancialInsightsScreen extends MdDatabaseFlowScreen { const MdFinancialInsightsScreen({super.key, required super.userId}) : super(module: 'financial-insights', screenTitle: 'Financial Insights', icon: Icons.pie_chart_outline_rounded); }
class MdDepartmentPerformanceScreen extends MdDatabaseFlowScreen { const MdDepartmentPerformanceScreen({super.key, required super.userId}) : super(module: 'department-performance', screenTitle: 'Department Performance', icon: Icons.groups_2_outlined); }
class MdProjectPortfolioScreen extends MdDatabaseFlowScreen { const MdProjectPortfolioScreen({super.key, required super.userId}) : super(module: 'project-portfolio', screenTitle: 'Project Portfolio', icon: Icons.business_center_outlined); }
class MdApprovalsCenterScreen extends MdDatabaseFlowScreen { const MdApprovalsCenterScreen({super.key, required super.userId}) : super(module: 'approvals-center', screenTitle: 'Approvals Center', icon: Icons.fact_check_outlined); }
class MdWorkforceAnalyticsScreen extends MdDatabaseFlowScreen { const MdWorkforceAnalyticsScreen({super.key, required super.userId}) : super(module: 'workforce-analytics', screenTitle: 'Workforce Analytics', icon: Icons.bar_chart_rounded); }
class MdLeadershipTeamScreen extends MdDatabaseFlowScreen { const MdLeadershipTeamScreen({super.key, required super.userId}) : super(module: 'leadership-team', screenTitle: 'Leadership Team', icon: Icons.groups_outlined); }
class MdCriticalAlertsScreen extends MdDatabaseFlowScreen { const MdCriticalAlertsScreen({super.key, required super.userId}) : super(module: 'critical-alerts', screenTitle: 'Critical Alerts', icon: Icons.notifications_active_outlined); }
class MdExecutiveReportsScreen extends MdDatabaseFlowScreen { const MdExecutiveReportsScreen({super.key, required super.userId}) : super(module: 'executive-reports', screenTitle: 'Executive Reports', icon: Icons.insert_chart_outlined_rounded); }
class MdMeetingsDatabaseScreen extends MdDatabaseFlowScreen { const MdMeetingsDatabaseScreen({super.key, required super.userId}) : super(module: 'meetings', screenTitle: 'Meetings', icon: Icons.calendar_month_outlined); }
class MdAnnouncementsScreen extends MdDatabaseFlowScreen { const MdAnnouncementsScreen({super.key, required super.userId}) : super(module: 'announcements', screenTitle: 'Announcements', icon: Icons.campaign_outlined); }
class MdDocumentsScreen extends MdDatabaseFlowScreen { const MdDocumentsScreen({super.key, required super.userId}) : super(module: 'documents', screenTitle: 'Documents', icon: Icons.folder_outlined); }
class MdSettingsPreferencesScreen extends MdDatabaseFlowScreen { const MdSettingsPreferencesScreen({super.key, required super.userId}) : super(module: 'settings-preferences', screenTitle: 'Settings & Preferences', icon: Icons.settings_outlined); }
