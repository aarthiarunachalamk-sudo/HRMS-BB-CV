import 'package:flutter/material.dart';

import 'hr_employee_detail_screen.dart';
import 'hr_shared.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';

class HrEmployeeDirectoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> employees;

  const HrEmployeeDirectoryScreen({super.key, required this.employees});

  @override
  State<HrEmployeeDirectoryScreen> createState() =>
      _HrEmployeeDirectoryScreenState();
}

class _HrEmployeeDirectoryScreenState extends State<HrEmployeeDirectoryScreen> {
  String _search = '';
  String _filterDept = 'All';

  static const List<String> _deptFilters = [
    'All',
    'HR',
    'WebApp',
    'Mobile App',
    'Marketing',
    'Digital Marketing',
    'Sales',
  ];

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);

    final filtered = widget.employees.where((emp) {
      final name = '${emp['name'] ?? ''}'.toLowerCase();
      final dept = '${emp['department'] ?? ''}';
      final id = '${emp['trailing'] ?? emp['id'] ?? ''}'.toLowerCase();
      final matchSearch =
          _search.isEmpty ||
          name.contains(_search.toLowerCase()) ||
          id.contains(_search.toLowerCase());
      final matchDept = _filterDept == 'All' || dept == _filterDept;
      return matchSearch && matchDept;
    }).toList();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppBarLogoTitle(title: 'Employee Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: c.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: c.muted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: TextStyle(color: c.text, fontSize: 13),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Search by name or ID...',
                        hintStyle: TextStyle(color: c.muted, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dept filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: _deptFilters.map((dept) {
                final selected = _filterDept == dept;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      dept,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? c.primary : c.muted,
                      ),
                    ),
                    selected: selected,
                    selectedColor: c.primary.withAlpha(30),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: selected ? c.primary.withAlpha(120) : c.border,
                    ),
                    onSelected: (_) => setState(() => _filterDept = dept),
                  ),
                );
              }).toList(),
            ),
          ),

          // Count label
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} employee${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Employee list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: c.muted,
                          size: 48,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No employees found',
                          style: TextStyle(
                            color: c.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final emp = filtered[i];
                      return _EmployeeCard(
                        employee: emp,
                        palette: c,
                        onTap: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                HrEmployeeDetailScreen(employee: emp),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final HrPalette palette;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.employee,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = palette;
    final name = '${employee['name'] ?? 'Employee'}';
    final role = '${employee['role'] ?? employee['subtitle'] ?? ''}';
    final dept = '${employee['department'] ?? ''}';
    final id = '${employee['trailing'] ?? employee['id'] ?? ''}';
    final status = '${employee['status'] ?? 'Active'}';
    final isActive = status == 'Active';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // subtitle may be "Associate · WebApp" already, extract dept if needed
    final displaySubtitle = dept.isNotEmpty ? '$role  ·  $dept' : role;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: c.primary.withAlpha(30),
              child: Text(
                initial,
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displaySubtitle,
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  id,
                  style: TextStyle(
                    color: c.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isActive ? c.success : c.danger).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isActive ? c.success : c.danger).withAlpha(100),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isActive ? c.success : c.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
