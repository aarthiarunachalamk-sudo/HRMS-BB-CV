import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/utils/privacy_utils.dart';

class TeamMemberAllocationScreen extends StatefulWidget {
  final String userRole; // 'pm' or 'ceo'
  final String userName;
  final String userEmail;

  const TeamMemberAllocationScreen({
    super.key,
    required this.userRole,
    this.userName = '',
    this.userEmail = '',
  });

  @override
  State<TeamMemberAllocationScreen> createState() =>
      _TeamMemberAllocationScreenState();
}

class _TeamMemberAllocationScreenState
    extends State<TeamMemberAllocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _pendingCandidates = [];
  List<dynamic> _allocatedMembers = [];
  List<dynamic> _availableTls = [];

  static const Color _brandColor = Color(0xFF0BA360);
  static const Color _cyanAccent = Color(0xFF00C6FF);
  static const Color _blueAccent = Color(0xFF4FACFE);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchAllocationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAllocationData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        ApiConfig.uri('/team/allocation-candidates/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _pendingCandidates = data['pending_allocation'] ?? [];
            _allocatedMembers = data['allocated'] ?? [];
            _availableTls = data['available_tls'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredPending {
    if (_searchQuery.isEmpty) return _pendingCandidates;
    final q = _searchQuery.toLowerCase();
    return _pendingCandidates.where((item) {
      final name =
          '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.toLowerCase();
      final email = '${item['email'] ?? ''}'.toLowerCase();
      final dept = '${item['department'] ?? ''}'.toLowerCase();
      final desig = '${item['designation'] ?? ''}'.toLowerCase();
      return name.contains(q) ||
          email.contains(q) ||
          dept.contains(q) ||
          desig.contains(q);
    }).toList();
  }

  List<dynamic> get _filteredAllocated {
    if (_searchQuery.isEmpty) return _allocatedMembers;
    final q = _searchQuery.toLowerCase();
    return _allocatedMembers.where((item) {
      final name =
          '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.toLowerCase();
      final email = '${item['email'] ?? ''}'.toLowerCase();
      final dept = '${item['department'] ?? ''}'.toLowerCase();
      final tl = '${item['reporting_tl'] ?? ''}'.toLowerCase();
      final id = '${item['employee_id'] ?? ''}'.toLowerCase();
      return name.contains(q) ||
          email.contains(q) ||
          dept.contains(q) ||
          tl.contains(q) ||
          id.contains(q);
    }).toList();
  }

  void _openAllocationSheet(Map<String, dynamic> candidate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllocationBottomSheet(
        candidate: candidate,
        availableTls: _availableTls,
        userRole: widget.userRole,
        onAllocated: () {
          _fetchAllocationData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);

    final isCeo = widget.userRole.toLowerCase() == 'ceo';
    final roleTitle = isCeo ? 'CEO Portal' : 'PM Portal';
    final roleColor = isCeo ? const Color(0xFFF7971E) : _brandColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF030712) : const Color(0xFFF8FAFC),
      body: ConstellationBackground(
        accentColor: roleColor,
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Team & TL Allocation',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: roleColor.withAlpha(90)),
                                ),
                                child: Text(
                                  roleTitle,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Assign Reporting TL and Team for new members',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _fetchAllocationData,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                color: roleColor,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, department...',
                      hintStyle: TextStyle(
                        color: textSecondary.withAlpha(120),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: isCeo
                          ? const LinearGradient(
                              colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
                            )
                          : const LinearGradient(
                              colors: [_brandColor, _cyanAccent],
                            ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Pending Allocation'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_pendingCandidates.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Allocated Members'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_allocatedMembers.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Views
              Expanded(
                child: RefreshIndicator(
                  color: roleColor,
                  onRefresh: _fetchAllocationData,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPendingList(
                              isDark,
                              cardBg,
                              cardBorder,
                              textPrimary,
                              textSecondary,
                              roleColor,
                            ),
                            _buildAllocatedList(
                              isDark,
                              cardBg,
                              cardBorder,
                              textPrimary,
                              textSecondary,
                              roleColor,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingList(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final list = _filteredPending;
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.how_to_reg_rounded,
                  size: 64,
                  color: textSecondary.withAlpha(60),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No Candidates Pending Allocation'
                      : 'No Matching Candidates',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _searchQuery.isEmpty
                      ? 'Candidates approved by HR for joining will appear here.'
                      : 'Try adjusting your search criteria.',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final item = Map<String, dynamic>.from(list[idx]);
        final name = '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
        final email = item['email'] ?? '';
        final dept = (item['department'] ?? 'General').toString().toUpperCase();
        final desig = (item['designation'] ?? 'Member').toString().toUpperCase();
        final doj = item['date_of_joining'] ?? '-';
        final mobile = item['mobile'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'New Employee' : name,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                        if (mobile.toString().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            maskMobileNumber(mobile),
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _blueAccent.withAlpha(22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _blueAccent.withAlpha(80)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: _blueAccent,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'HR READY',
                          style: TextStyle(
                            color: _blueAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: cardBorder.withAlpha(80), height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(Icons.domain_rounded, dept, textSecondary),
                  const SizedBox(width: 8),
                  _infoChip(Icons.badge_rounded, desig, textSecondary),
                  const Spacer(),
                  Text(
                    'DOJ: $doj',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _openAllocationSheet(item),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text(
                    'Assign Team & Reporting TL',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllocatedList(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final list = _filteredAllocated;
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.group_rounded,
                  size: 64,
                  color: textSecondary.withAlpha(60),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No Allocated Members Yet'
                      : 'No Matching Members',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _searchQuery.isEmpty
                      ? 'Members allocated with Reporting TLs will appear here.'
                      : 'Try adjusting your search criteria.',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final item = Map<String, dynamic>.from(list[idx]);
        final name = '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
        final email = item['email'] ?? '';
        final dept = (item['department'] ?? 'General').toString().toUpperCase();
        final tl = item['reporting_tl'] ?? 'Not Assigned';
        final doj = item['date_of_joining'] ?? '-';
        final empId = item['employee_id'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name.isEmpty ? 'Team Member' : name,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (empId.toString().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBorder.withAlpha(50),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  empId,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _brandColor.withAlpha(22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _brandColor.withAlpha(80)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: _brandColor,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: _brandColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reporting TL Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.supervisor_account_rounded,
                      color: _cyanAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reporting Team Leader',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            tl,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _infoChip(Icons.domain_rounded, dept, textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Joined: $doj',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  GestureDetector(
                    onTap: () => _openAllocationSheet(item),
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Reassign TL',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildAvatar(Map<String, dynamic> item) {
    final photoUrl = '${item['doc_passport_photo'] ?? ''}'.trim();
    final initials =
        '${item['first_name']?[0] ?? '?'}${item['last_name']?[0] ?? ''}'
            .toUpperCase();

    if (photoUrl.isNotEmpty && photoUrl != 'null') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          photoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _initialsAvatar(initials),
        ),
      );
    }
    return _initialsAvatar(initials);
  }

  Widget _initialsAvatar(String initials) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _cyanAccent.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyanAccent.withAlpha(80)),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: _cyanAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationBottomSheet extends StatefulWidget {
  final Map<String, dynamic> candidate;
  final List<dynamic> availableTls;
  final String userRole;
  final VoidCallback onAllocated;

  const _AllocationBottomSheet({
    required this.candidate,
    required this.availableTls,
    required this.userRole,
    required this.onAllocated,
  });

  @override
  State<_AllocationBottomSheet> createState() => _AllocationBottomSheetState();
}

class _AllocationBottomSheetState extends State<_AllocationBottomSheet> {
  late String _selectedDepartment;
  String? _selectedReportingTL;
  bool _isSubmitting = false;

  final List<Map<String, String>> _departments = [
    {'value': 'webapp', 'label': 'WebApp'},
    {'value': 'mobile_app', 'label': 'Mobile App'},
    {'value': 'marketing', 'label': 'Marketing'},
    {'value': 'digital_marketing', 'label': 'Digital Marketing'},
    {'value': 'sales', 'label': 'Sales'},
    {'value': 'hr', 'label': 'HR'},
  ];

  @override
  void initState() {
    super.initState();
    final rawDept = '${widget.candidate['department'] ?? 'webapp'}'.toLowerCase();
    _selectedDepartment = _departments.any((d) => d['value'] == rawDept)
        ? rawDept
        : 'webapp';

    final currentTL = widget.candidate['reporting_tl']?.toString();
    if (currentTL != null && currentTL.isNotEmpty) {
      _selectedReportingTL = currentTL;
    }
  }

  List<dynamic> get _filteredTls {
    final matching = widget.availableTls.where((tl) {
      final dept = '${tl['department'] ?? ''}'.toLowerCase();
      return dept == _selectedDepartment;
    }).toList();
    return matching.isNotEmpty ? matching : widget.availableTls;
  }

  Future<void> _submitAllocation() async {
    if (_selectedReportingTL == null || _selectedReportingTL!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Reporting TL for this team member.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final candidateId = widget.candidate['id'];

    try {
      final response = await http.post(
        ApiConfig.uri('/team/allocate-member/$candidateId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reporting_tl': _selectedReportingTL!.trim(),
          'department': _selectedDepartment,
          'role': widget.userRole,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context); // Close bottom sheet
        widget.onAllocated();

        // Show celebration dialog
        final candidateName =
            '${widget.candidate['first_name'] ?? ''} ${widget.candidate['last_name'] ?? ''}'
                .trim();
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: ThemeConfig.getCardBg(dialogCtx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFF43E97B),
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Member Allocated!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$candidateName has been successfully allocated to $_selectedReportingTL in the ${_selectedDepartment.toUpperCase()} team.',
                  style: TextStyle(
                    color: ThemeConfig.getTextPrimary(dialogCtx),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Employee account is active and welcome credentials with OTC have been dispatched to their email.',
                  style: TextStyle(
                    color: ThemeConfig.getTextSecondary(dialogCtx),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Color(0xFF4FACFE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to allocate team member.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Allocation error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);

    final candidateName =
        '${widget.candidate['first_name'] ?? ''} ${widget.candidate['last_name'] ?? ''}'
            .trim();
    final email = widget.candidate['email'] ?? '';

    final isCeo = widget.userRole.toLowerCase() == 'ceo';
    final roleAccent = isCeo ? const Color(0xFFF7971E) : const Color(0xFF0BA360);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocate Team Member & TL',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Assign department pod and reporting leader',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Candidate Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2541) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded, color: roleAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidateName.isEmpty ? 'Candidate' : candidateName,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: roleAccent.withAlpha(80)),
                  ),
                  child: Text(
                    isCeo ? 'CEO Allocation' : 'PM Allocation',
                    style: TextStyle(
                      color: roleAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Department selector
          Text(
            'Target Department Pod',
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: AppDropdownButton<String>(
                value: _selectedDepartment,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                style: TextStyle(color: textPrimary, fontSize: 13),
                items: _departments
                    .map(
                      (d) => DropdownMenuItem(
                        value: d['value'],
                        child: Text(d['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedDepartment = v;
                      _selectedReportingTL = null;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reporting TL selector
          Text(
            'Assign Reporting Team Leader (TL) *',
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: AppDropdownButton<String>(
                value: _selectedReportingTL,
                hint: Text(
                  _filteredTls.isEmpty
                      ? 'No TLs available in this department'
                      : 'Select Reporting Team Leader',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                style: TextStyle(color: textPrimary, fontSize: 13),
                items: _filteredTls.map((tl) {
                  final display = tl['display'] ?? tl['name'] ?? '';
                  final name = tl['name'] ?? '';
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(
                      display,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textPrimary, fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => _selectedReportingTL = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAllocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: roleAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirm Allocation & Activate Member',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
