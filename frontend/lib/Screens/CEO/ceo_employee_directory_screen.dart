import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/employee_avatar.dart';

import 'ceo_employee_profile_screen.dart';
import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoEmployeeDirectoryScreen extends StatefulWidget {
  final String firstName;
  final String email;
  final String userId;

  const CeoEmployeeDirectoryScreen({
    super.key,
    required this.firstName,
    required this.email,
    required this.userId,
  });

  @override
  State<CeoEmployeeDirectoryScreen> createState() =>
      _CeoEmployeeDirectoryScreenState();
}

class _CeoEmployeeDirectoryScreenState
    extends State<CeoEmployeeDirectoryScreen> {
  String _search = '';
  String _filterDept = 'All';

  static const List<String> _deptFilters = [
    'All', 'HR', 'WebApp', 'Mobile App', 'Marketing',
    'Digital Marketing', 'Sales',
  ];

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Employee Directory',
      child: CeoFutureBody(
        future: CeoService().fetchEmployees(widget.userId),
        builder: (data) {
          final raw = (data['employees'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          // Filter
          final filtered = raw.where((emp) {
            final name = '${emp['name'] ?? ''}'.toLowerCase();
            final dept = '${emp['department'] ?? ''}';
            final id = '${emp['id'] ?? ''}'.toLowerCase();
            final matchSearch = _search.isEmpty ||
                name.contains(_search.toLowerCase()) ||
                id.contains(_search.toLowerCase());
            final matchDept =
                _filterDept == 'All' || dept == _filterDept;
            return matchSearch && matchDept;
          }).toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: _SearchBar(
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              // Dept filter chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: _deptFilters.map((dept) {
                    final selected = _filterDept == dept;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(dept,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? CeoColors.cyan
                                  : CeoColors.muted,
                            )),
                        selected: selected,
                        selectedColor: CeoColors.cyan.withAlpha(30),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: selected
                              ? CeoColors.cyan.withAlpha(120)
                              : CeoColors.muted.withAlpha(60),
                        ),
                        onSelected: (_) =>
                            setState(() => _filterDept = dept),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              // Count
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                child: Row(children: [
                  muted('${filtered.length} employee${filtered.length == 1 ? '' : 's'}', 11),
                ]),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                color: CeoColors.muted, size: 48),
                            const SizedBox(height: 10),
                            muted('No employees found', 13),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final emp = filtered[i];
                          return _EmployeeCard(
                            employee: emp,
                            onTap: () => Navigator.of(ctx).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CeoEmployeeProfileScreen(employee: emp),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CeoColors.muted.withAlpha(60)),
      ),
      child: Row(children: [
        const Icon(Icons.search_rounded, color: CeoColors.muted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration.collapsed(
              hintText: 'Search by name or ID...',
              hintStyle: TextStyle(color: CeoColors.muted, fontSize: 13),
            ),
          ),
        ),
      ]),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onTap;
  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = '${employee['name'] ?? 'Employee'}';
    final role = '${employee['role'] ?? ''}';
    final dept = '${employee['department'] ?? ''}';
    final id = '${employee['id'] ?? ''}';
    final status = '${employee['status'] ?? 'Active'}';
    final isActive = status == 'Active';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CeoColors.muted.withAlpha(40)),
        ),
        child: Row(children: [
          // Avatar
          EmployeeAvatar(
            name: name,
            photoUrl: '${employee['doc_passport_photo'] ?? ''}',
            radius: 22,
            backgroundColor: CeoColors.cyan.withAlpha(30),
            foregroundColor: CeoColors.cyan,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('$role  ·  $dept',
                  style: const TextStyle(
                      color: CeoColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          // Right side
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(id,
                style: const TextStyle(
                    color: CeoColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isActive ? CeoColors.green : Colors.redAccent)
                    .withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: (isActive ? CeoColors.green : Colors.redAccent)
                        .withAlpha(100)),
              ),
              child: Text(status,
                  style: TextStyle(
                      color: isActive ? CeoColors.green : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        ]),
      ),
    );
  }
}
