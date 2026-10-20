import 'package:flutter/material.dart';
import 'client_visit_models.dart';

class VisitMemberHistoryItem {
  final String visitId;
  final String clientName;
  final String date;
  final String service;
  final String status;
  final String outcome;

  const VisitMemberHistoryItem({
    required this.visitId,
    required this.clientName,
    required this.date,
    required this.service,
    required this.status,
    required this.outcome,
  });
}

class VisitTeamMember {
  final String id;
  final String name;
  final String role;
  final String team;
  final String phone;
  final String email;
  final int pastVisitsCount;
  final List<VisitMemberHistoryItem> history;

  const VisitTeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.team,
    required this.phone,
    required this.email,
    required this.pastVisitsCount,
    required this.history,
  });
}

final List<VisitTeamMember> kMarketingMembers = [
  const VisitTeamMember(
    id: 'BB-MKT-001',
    name: 'Karthik M',
    role: 'Marketing Lead',
    team: 'marketing',
    phone: '+91 98450 12345',
    email: 'karthik.m@bitbyte.com',
    pastVisitsCount: 14,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-089',
        clientName: 'Tata Motors Dealership',
        date: '10 Oct 2026',
        service: 'Creative Studio & Ad Creatives',
        status: 'Completed',
        outcome: 'Brand kit approved, annual contract signed',
      ),
      VisitMemberHistoryItem(
        visitId: 'CV-2026-074',
        clientName: 'Apex Tech Solutions',
        date: '28 Sep 2026',
        service: 'Meta Ads & Branding',
        status: 'Completed',
        outcome: 'Lead gen campaign launched successfully',
      ),
      VisitMemberHistoryItem(
        visitId: 'CV-2026-061',
        clientName: 'Zenith Retail Hub',
        date: '15 Sep 2026',
        service: 'Social Media Marketing',
        status: 'Completed',
        outcome: 'Reels and brochure catalog finalized',
      ),
    ],
  ),
  const VisitTeamMember(
    id: 'BB-MKT-002',
    name: 'Priya Sundar',
    role: 'Senior Performance Marketer',
    team: 'marketing',
    phone: '+91 98450 12346',
    email: 'priya.s@bitbyte.com',
    pastVisitsCount: 9,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-085',
        clientName: 'Greenfield Organics',
        date: '05 Oct 2026',
        service: 'Paid Advertising & Google Ads',
        status: 'Completed',
        outcome: 'E-commerce conversion tracking set up',
      ),
      VisitMemberHistoryItem(
        visitId: 'CV-2026-068',
        clientName: 'Skyline Real Estate',
        date: '20 Sep 2026',
        service: 'Meta Ads & Lead Gen',
        status: 'Completed',
        outcome: 'Lead cost reduced by 28%',
      ),
    ],
  ),
  const VisitTeamMember(
    id: 'BB-MKT-003',
    name: 'Rahul Sharma',
    role: 'Creative & Video Designer',
    team: 'marketing',
    phone: '+91 98450 12347',
    email: 'rahul.s@bitbyte.com',
    pastVisitsCount: 11,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-092',
        clientName: 'Velan Silks & Sarees',
        date: '08 Oct 2026',
        service: 'Photo & Video Production',
        status: 'Completed',
        outcome: 'Festival shoot completed on premise',
      ),
      VisitMemberHistoryItem(
        visitId: 'CV-2026-077',
        clientName: 'Kaveri Hospital',
        date: '25 Sep 2026',
        service: 'Brand Identity Kit & Logo',
        status: 'Completed',
        outcome: 'Hospital wing branding delivered',
      ),
    ],
  ),
  const VisitTeamMember(
    id: 'BB-MKT-004',
    name: 'Ananya Rao',
    role: 'SEO & Content Strategist',
    team: 'marketing',
    phone: '+91 98450 12348',
    email: 'ananya.r@bitbyte.com',
    pastVisitsCount: 7,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-081',
        clientName: 'Sri Krishna Sweets',
        date: '02 Oct 2026',
        service: 'Local SEO & Content Writing',
        status: 'Completed',
        outcome: 'Google Maps rank improved to #1 locally',
      ),
      VisitMemberHistoryItem(
        visitId: 'CV-2026-059',
        clientName: 'MedPlus Pharmacy',
        date: '12 Sep 2026',
        service: 'Enterprise SEO Audit',
        status: 'Completed',
        outcome: 'Audit report and backlink sheet presented',
      ),
    ],
  ),
  const VisitTeamMember(
    id: 'BB-MKT-005',
    name: 'Vignesh K',
    role: 'Client Relationship Executive',
    team: 'marketing',
    phone: '+91 98450 12349',
    email: 'vignesh.k@bitbyte.com',
    pastVisitsCount: 12,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-095',
        clientName: 'Apollo Tyre Distributors',
        date: '11 Oct 2026',
        service: 'WhatsApp Automation & CRM',
        status: 'Completed',
        outcome: 'Chatbot flow demo & order automation set up',
      ),
      VisitMemberHistoryItem(
        visitId: 'CV-2026-071',
        clientName: 'Heritage Foods',
        date: '22 Sep 2026',
        service: 'Brand Outreach & Campaign',
        status: 'Completed',
        outcome: 'Quarterly review completed successfully',
      ),
    ],
  ),
];

final List<VisitTeamMember> kDevelopmentMembers = [
  const VisitTeamMember(
    id: 'BB-DEV-001',
    name: 'Suresh Kumar',
    role: 'TL (Team Lead)',
    team: 'development',
    phone: '+91 98450 22341',
    email: 'suresh.k@bitbyte.com',
    pastVisitsCount: 16,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-090',
        clientName: 'Apex Financial Services',
        date: '09 Oct 2026',
        service: 'Dynamic Web App Architecture',
        status: 'Completed',
        outcome: 'Cloud migration plan signed off',
      ),
    ],
  ),
  const VisitTeamMember(
    id: 'BB-DEV-002',
    name: 'Meena R',
    role: 'Employee (Senior Developer)',
    team: 'development',
    phone: '+91 98450 22342',
    email: 'meena.r@bitbyte.com',
    pastVisitsCount: 10,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-078',
        clientName: 'Skyline ERP Solutions',
        date: '27 Sep 2026',
        service: 'E-Commerce Website Development',
        status: 'Completed',
        outcome: 'Payment gateway integration delivered',
      ),
    ],
  ),
  const VisitTeamMember(
    id: 'BB-DEV-003',
    name: 'Divya P',
    role: 'HR (Human Resources)',
    team: 'development',
    phone: '+91 98450 22343',
    email: 'divya.p@bitbyte.com',
    pastVisitsCount: 8,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-065',
        clientName: 'Prime Logistics',
        date: '18 Sep 2026',
        service: 'Staffing & HR Requirements',
        status: 'Completed',
        outcome: 'Campus recruitment drive finalized',
      ),
    ],
  ),
  const VisitTeamMember(
    id: 'BB-DEV-004',
    name: 'Vikram S',
    role: 'CEO (Chief Executive Officer)',
    team: 'development',
    phone: '+91 98450 22344',
    email: 'vikram.s@bitbyte.com',
    pastVisitsCount: 14,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-083',
        clientName: 'Velan Silks E-Shop',
        date: '04 Oct 2026',
        service: 'Strategic Technology Partnership',
        status: 'Completed',
        outcome: 'Enterprise development contract signed',
      ),
    ],
  ),
];

final List<VisitTeamMember> kManagementMembers = [
  const VisitTeamMember(
    id: 'BB-MGT-001',
    name: 'Rajesh Ramanathan',
    role: 'MD (Managing Director)',
    team: 'management',
    phone: '+91 98450 33301',
    email: 'rajesh.r@bitbyte.com',
    pastVisitsCount: 25,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-094',
        clientName: 'Tata Motors Dealership',
        date: '10 Oct 2026',
        service: 'Executive Partnership Meeting',
        status: 'Completed',
        outcome: 'Enterprise MSA executed',
      ),
    ],
  ),
  const VisitTeamMember(
    id: 'BB-MGT-002',
    name: 'Kavin Adhithya K C',
    role: 'ED (Executive Director)',
    team: 'management',
    phone: '+91 98450 33302',
    email: 'kavin.kc@bitbyte.com',
    pastVisitsCount: 21,
    history: [
      VisitMemberHistoryItem(
        visitId: 'CV-2026-082',
        clientName: 'Apex Group Corp',
        date: '03 Oct 2026',
        service: 'Quarterly Executive Review',
        status: 'Completed',
        outcome: 'Strategic alliance approved',
      ),
    ],
  ),
];

List<VisitTeamMember> getTeamMembersFor(String team) {
  if (team == 'marketing') return kMarketingMembers;
  if (team == 'development') return kDevelopmentMembers;
  return kManagementMembers;
}

/// Bottom sheet displaying an individual member's past client visit history
void showVisitMemberHistorySheet(BuildContext context, VisitTeamMember member) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
      final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      final muted = isDark ? Colors.white60 : Colors.black54;

      return Container(
        height: MediaQuery.of(ctx).size.height * 0.78,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF006CE5).withValues(alpha: 0.18),
                    child: Text(
                      member.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF00E5FF)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${member.role} • ${member.id}',
                          style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${member.pastVisitsCount} Past Visits',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF00E5FF)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatMini(label: 'Total Visits', value: '${member.pastVisitsCount}'),
                        Container(width: 1, height: 32, color: borderColor),
                        const _StatMini(label: 'Success Rate', value: '100%'),
                        Container(width: 1, height: 32, color: borderColor),
                        _StatMini(label: 'Contact', value: member.phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Client Visit History Table',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (member.history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text('No historical visits on record.', style: TextStyle(color: muted)),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(
                            isDark ? const Color(0xFF0B132B) : const Color(0xFFEEF2F6),
                          ),
                          columnSpacing: 16,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Visit ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Client Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Service', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Outcome / Result', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: member.history.map((h) {
                            return DataRow(
                              cells: [
                                DataCell(Text(h.visitId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF00E5FF)))),
                                DataCell(Text(h.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataCell(Text(h.date, style: TextStyle(fontSize: 11, color: muted))),
                                DataCell(Text(h.service, style: const TextStyle(fontSize: 11))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      h.status,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.green.shade400),
                                    ),
                                  ),
                                ),
                                DataCell(Text(h.outcome, style: const TextStyle(fontSize: 11))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  const _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

/// Success dialog showing the table of persons going on the client visit,
/// the whole team members table, and individual history details.
Future<void> showVisitSuccessTableDialog({
  required BuildContext context,
  required ClientVisit visit,
  required List<VisitTeamMember> assignedMembers,
  required List<VisitTeamMember> wholeTeam,
  required String scheduledDateStr,
  required String scheduledTimeStr,
  required bool isSelfApproving,
  required bool isDraft,
}) async {
  int activeTab = 0; // 0: Persons Going to Visit, 1: Whole Team, 2: Member History
  String? selectedHistoryMemberId = assignedMembers.isNotEmpty
      ? assignedMembers.first.id
      : (wholeTeam.isNotEmpty ? wholeTeam.first.id : null);
  final Set<String> checkedMemberIds = assignedMembers.map((m) => m.id).toSet();

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        final mutedColor = isDark ? Colors.white60 : Colors.black54;

        final selectedHistoryMember = wholeTeam.firstWhere(
          (m) => m.id == selectedHistoryMemberId,
          orElse: () => wholeTeam.isNotEmpty ? wholeTeam.first : assignedMembers.first,
        );

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Header
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green.shade400, width: 1.5),
                        ),
                        child: Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDraft
                                  ? 'Draft Saved Successfully'
                                  : (isSelfApproving
                                      ? 'Client Visit Created Successfully'
                                      : 'Visit Request Submitted Successfully'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${visit.clientName} • $scheduledDateStr at $scheduledTimeStr',
                              style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (visit.visitId.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006CE5).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF006CE5)),
                          ),
                          child: Text(
                            visit.visitId,
                            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Segmented Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            title: 'Going (${assignedMembers.length})',
                            isSelected: activeTab == 0,
                            icon: Icons.directions_walk_rounded,
                            onTap: () => setDialogState(() => activeTab = 0),
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            title: 'Whole Team (${wholeTeam.length})',
                            isSelected: activeTab == 1,
                            icon: Icons.groups_rounded,
                            onTap: () => setDialogState(() => activeTab = 1),
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            title: 'Member History',
                            isSelected: activeTab == 2,
                            icon: Icons.history_rounded,
                            onTap: () => setDialogState(() => activeTab = 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tab Views
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: activeTab == 0
                          ? _buildAssignedMembersTable(
                              assignedMembers: assignedMembers,
                              isDark: isDark,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                              onViewHistory: (member) {
                                setDialogState(() {
                                  selectedHistoryMemberId = member.id;
                                  activeTab = 2;
                                });
                              },
                            )
                          : activeTab == 1
                              ? _buildWholeTeamTable(
                                  wholeTeam: wholeTeam,
                                  checkedIds: checkedMemberIds,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  mutedColor: mutedColor,
                                  onToggle: (id) {
                                    setDialogState(() {
                                      if (checkedMemberIds.contains(id)) {
                                        checkedMemberIds.remove(id);
                                      } else {
                                        checkedMemberIds.add(id);
                                      }
                                    });
                                  },
                                  onViewHistory: (member) {
                                    setDialogState(() {
                                      selectedHistoryMemberId = member.id;
                                      activeTab = 2;
                                    });
                                  },
                                )
                              : _buildMemberHistoryTable(
                                  wholeTeam: wholeTeam,
                                  selectedMember: selectedHistoryMember,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  mutedColor: mutedColor,
                                  onSelectMember: (id) {
                                    setDialogState(() => selectedHistoryMemberId = id);
                                  },
                                ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Bottom Action
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('OK • Done', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF00E5FF)
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildAssignedMembersTable({
  required List<VisitTeamMember> assignedMembers,
  required bool isDark,
  required Color borderColor,
  required Color mutedColor,
  required ValueChanged<VisitTeamMember> onViewHistory,
}) {
  if (assignedMembers.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No members assigned to this visit.', style: TextStyle(color: mutedColor)),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B132B) : const Color(0xFFEEF2F6),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            const Icon(Icons.badge_rounded, size: 16, color: Color(0xFF00E5FF)),
            const SizedBox(width: 8),
            const Text(
              'Persons Going for Client Visit',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${assignedMembers.length} Person(s)',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF00E5FF)),
            ),
          ],
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Person Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Emp ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Designation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Past History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              ],
              rows: assignedMembers.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final m = entry.value;
                return DataRow(
                  cells: [
                    DataCell(Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF006CE5).withValues(alpha: 0.2),
                            child: Text(
                              m.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                    DataCell(Text(m.id, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: mutedColor))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006CE5).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(m.role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF00B0FF))),
                      ),
                    ),
                    DataCell(Text(m.phone, style: const TextStyle(fontSize: 11))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade400, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 11, color: Colors.green.shade400),
                            const SizedBox(width: 4),
                            Text('Assigned', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade400)),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                        ),
                        onPressed: () => onViewHistory(m),
                        icon: const Icon(Icons.history_rounded, size: 12, color: Color(0xFF00E5FF)),
                        label: Text('${m.pastVisitsCount} visits', style: const TextStyle(fontSize: 10, color: Color(0xFF00E5FF))),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildWholeTeamTable({
  required List<VisitTeamMember> wholeTeam,
  required Set<String> checkedIds,
  required bool isDark,
  required Color borderColor,
  required Color mutedColor,
  required ValueChanged<String> onToggle,
  required ValueChanged<VisitTeamMember> onViewHistory,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B132B) : const Color(0xFFEEF2F6),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF00E5FF)),
            const SizedBox(width: 8),
            const Text(
              'Team Members Overview (Checkbox Selection)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${checkedIds.length} of ${wholeTeam.length} Selected',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF00E5FF)),
            ),
          ],
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('Select', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Member Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Emp ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Contact Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Visit Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              ],
              rows: wholeTeam.map((m) {
                final isChecked = checkedIds.contains(m.id);
                return DataRow(
                  selected: isChecked,
                  cells: [
                    DataCell(
                      Checkbox(
                        value: isChecked,
                        onChanged: (_) => onToggle(m.id),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: (isChecked ? const Color(0xFF006CE5) : Colors.grey).withValues(alpha: 0.2),
                            child: Text(
                              m.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isChecked ? const Color(0xFF00E5FF) : mutedColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                    DataCell(Text(m.id, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: mutedColor))),
                    DataCell(Text(m.role, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(m.phone, style: const TextStyle(fontSize: 11))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isChecked ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isChecked ? 'Going on Visit' : 'Available',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isChecked ? Colors.green.shade400 : mutedColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => onViewHistory(m),
                        icon: const Icon(Icons.history_rounded, size: 12),
                        label: Text('${m.pastVisitsCount} visits', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildMemberHistoryTable({
  required List<VisitTeamMember> wholeTeam,
  required VisitTeamMember selectedMember,
  required bool isDark,
  required Color borderColor,
  required Color mutedColor,
  required ValueChanged<String> onSelectMember,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Horizontal Member Selector Chips
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B132B) : const Color(0xFFEEF2F6),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: wholeTeam.map((m) {
              final isCurrent = m.id == selectedMember.id;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text('${m.name} (${m.pastVisitsCount})', style: const TextStyle(fontSize: 11)),
                  selected: isCurrent,
                  onSelected: (_) => onSelectMember(m.id),
                  selectedColor: const Color(0xFF006CE5).withValues(alpha: 0.25),
                  checkmarkColor: const Color(0xFF00E5FF),
                ),
              );
            }).toList(),
          ),
        ),
      ),

      // Profile banner of selected member
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF142036) : const Color(0xFFF1F5F9),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF006CE5).withValues(alpha: 0.2),
              child: Text(
                selectedMember.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF00E5FF)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedMember.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text('${selectedMember.role} • ${selectedMember.id} • ${selectedMember.phone}',
                      style: TextStyle(fontSize: 11, color: mutedColor)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${selectedMember.history.length} Past Visits',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
              ),
            ),
          ],
        ),
      ),

      // History Table
      Expanded(
        child: selectedMember.history.isEmpty
            ? Center(child: Text('No historical visits found for this member.', style: TextStyle(color: mutedColor)))
            : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    columns: const [
                      DataColumn(label: Text('Visit ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text('Client Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text('Services Handled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text('Outcome / Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                    rows: selectedMember.history.map((h) {
                      return DataRow(
                        cells: [
                          DataCell(Text(h.visitId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF00E5FF)))),
                          DataCell(Text(h.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                          DataCell(Text(h.date, style: TextStyle(fontSize: 11, color: mutedColor))),
                          DataCell(Text(h.service, style: const TextStyle(fontSize: 11))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(h.status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.green.shade400)),
                            ),
                          ),
                          DataCell(Text(h.outcome, style: const TextStyle(fontSize: 11))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
    ],
  );
}
