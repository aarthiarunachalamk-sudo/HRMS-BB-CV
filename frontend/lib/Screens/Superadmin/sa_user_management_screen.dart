import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaUserManagementScreen extends StatefulWidget {
  final VoidCallback? onCreateUser;

  const SaUserManagementScreen({super.key, this.onCreateUser});

  @override
  State<SaUserManagementScreen> createState() => _SaUserManagementScreenState();
}

class _SaUserManagementScreenState extends State<SaUserManagementScreen> {
  final _search = TextEditingController();
  String _roleFilter = 'All';
  String _statusFilter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: SaService().fetchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SaScreen(
            title: 'User Management',
            child: saList([
              SaCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: saMuted(context, 'Backend data unavailable', 13),
                  ),
                ),
              ),
            ]),
          );
        }
        if (!snapshot.hasData) {
          return SaScreen(
            title: 'User Management',
            child: Center(child: CircularProgressIndicator(color: c.primary)),
          );
        }

        final allUsers = _usersFrom(snapshot.data!['users']);
        final roles = _options(allUsers.map((user) => user.role));
        final statuses = _options(allUsers.map((user) => user.status));
        final query = _search.text.trim().toLowerCase();
        final users = allUsers.where((user) {
          final matchesQuery = query.isEmpty ||
              '${user.name} ${user.subtitle} ${user.detail}'
                  .toLowerCase()
                  .contains(query);
          final matchesRole = _roleFilter == 'All' || user.role == _roleFilter;
          final matchesStatus =
              _statusFilter == 'All' || user.status == _statusFilter;
          return matchesQuery && matchesRole && matchesStatus;
        }).toList();

        return SaScreen(
          title: 'User Management',
          trailing: IconButton(
            tooltip: 'Filter users',
            icon: Icon(Icons.filter_list_rounded, color: c.text),
            onPressed: () => _showUserFilters(roles, statuses),
          ),
          child: saList([
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: c.text, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: c.muted),
                prefixIcon: Icon(Icons.search_rounded, color: c.muted),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: c.input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showUserFilters(roles, statuses),
                  child: SaCard(
                    color: c.input,
                    padding: const EdgeInsets.all(11),
                    child: saTitle(context, 'Role: $_roleFilter', 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _showUserFilters(roles, statuses),
                  child: SaCard(
                    color: c.input,
                    padding: const EdgeInsets.all(11),
                    child: saTitle(context, 'Status: $_statusFilter', 12),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (users.isEmpty)
              SaCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: saMuted(context, 'No users found', 13)),
                ),
              )
            else
              ...users.map(
                (u) => SaInfoTile(
                  icon: Icons.person_rounded,
                  title: u.name.isEmpty ? 'User' : u.name,
                  subtitle: '${u.subtitle}  ${u.detail}'.trim(),
                  trailing: u.status,
                  color: u.status.toLowerCase() == 'active'
                      ? c.success
                      : c.danger,
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: widget.onCreateUser,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Create User',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  List<_UserRow> _usersFrom(dynamic rawUsers) {
    if (rawUsers is! List) return <_UserRow>[];
    return rawUsers.map((item) {
      final u = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      return _UserRow(
        name: '${u['name'] ?? ''}',
        subtitle: '${u['subtitle'] ?? ''}  ${u['trailing'] ?? ''}',
        detail: '${u['detail'] ?? ''}',
        status: '${u['status'] ?? 'Active'}',
      );
    }).toList();
  }

  List<String> _options(Iterable<String> values) => <String>{
        'All',
        ...values.map((value) => value.trim()).where((value) => value.isNotEmpty),
      }.toList();

  Future<void> _showUserFilters(List<String> roles, List<String> statuses) {
    var role = roles.contains(_roleFilter) ? _roleFilter : 'All';
    var status = statuses.contains(_statusFilter) ? _statusFilter : 'All';
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              const Text(
                'Filter Users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: role,
                items: roles
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setSheetState(() => role = value ?? 'All'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                items: statuses
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => status = value ?? 'All'),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _roleFilter = 'All';
                          _statusFilter = 'All';
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _roleFilter = role;
                          _statusFilter = status;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserRow {
  final String name;
  final String subtitle;
  final String detail;
  final String status;

  const _UserRow({
    required this.name,
    required this.subtitle,
    required this.detail,
    required this.status,
  });

  String get role => subtitle.split(RegExp(r'\s+')).first.trim();
}
