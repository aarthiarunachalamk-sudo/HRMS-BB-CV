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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _fetch();
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
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: muted, size: 52),
                    const SizedBox(height: 12),
                    Text('No database records available', style: TextStyle(color: text, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text('Records added to the backend will appear here.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_load),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: ThemeConfig.blueAccent, size: 28),
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
                              Text('${item['detail']}', style: TextStyle(color: ThemeConfig.blueAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
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
