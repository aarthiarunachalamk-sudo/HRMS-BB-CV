import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Account/account_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_palette.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_widgets.dart';

class AdminDeletionRequestsScreen extends StatefulWidget {
  final String userId;

  const AdminDeletionRequestsScreen({super.key, required this.userId});

  @override
  State<AdminDeletionRequestsScreen> createState() =>
      _AdminDeletionRequestsScreenState();
}

class _AdminDeletionRequestsScreenState extends State<AdminDeletionRequestsScreen> {
  final AccountService _accountService = AccountService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatusFilter = 'ALL';

  List<Map<String, dynamic>> _requests = [];
  Map<String, dynamic> _counts = {
    'total': 0,
    'pending': 0,
    'under_review': 0,
    'approved': 0,
    'completed': 0,
    'rejected': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _accountService.fetchAdminDeletionRequests(
        status: _selectedStatusFilter == 'ALL' ? null : _selectedStatusFilter,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _requests = (res['requests'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (res['counts'] is Map) {
            _counts = Map<String, dynamic>.from(res['counts'] as Map);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAction(Map<String, dynamic> req, String action) async {
    final reqId = req['id'];
    final reqCode = req['request_id'] ?? '#$reqId';
    final empName = req['employee_name'] ?? req['user_id'] ?? 'Employee';

    // If 'complete' or 'reject', prompt for confirmation / remarks
    String? remarks;
    if (action == 'complete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final c = AdminPalette.of(context);
          return AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: c.border),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_rounded, color: c.red, size: 24),
                const SizedBox(width: 10),
                const Text('Complete Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Text(
              'Are you sure you want to mark request $reqCode for $empName as COMPLETED?\n\n'
              '• Normal login and mobile access will be deactivated.\n'
              '• Audit, attendance, payroll, and statutory records will be safely retained in accordance with company policy.',
              style: TextStyle(color: c.text, fontSize: 13, height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: TextStyle(color: c.muted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Complete & Deactivate', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    } else if (action == 'reject') {
      final remarksController = TextEditingController();
      final submittedRemarks = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final c = AdminPalette.of(context);
          return AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: c.border),
            ),
            title: const Text('Reject Deletion Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Provide a reason for rejecting request $reqCode:', style: TextStyle(color: c.muted, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Admin rejection remarks...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text('Cancel', style: TextStyle(color: c.muted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(ctx).pop(remarksController.text.trim()),
                child: const Text('Reject Request', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
      if (submittedRemarks == null) return;
      remarks = submittedRemarks;
    }

    try {
      final res = await _accountService.updateAdminDeletionRequest(
        id: reqId is int ? reqId : int.parse(reqId.toString()),
        action: action,
        remarks: remarks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Status updated successfully.'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    }
  }

  void _showRequestDetailsModal(Map<String, dynamic> req) {
    final c = AdminPalette.of(context);
    final status = req['status'] ?? 'PENDING';
    final isFinal = status == 'COMPLETED' || status == 'REJECTED' || status == 'CANCELLED';

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Request Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.text,
                        ),
                      ),
                    ),
                    _statusBadge(status, c),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow('Request ID', req['request_id'] ?? '', c),
                _detailRow('Employee Name', req['employee_name'] ?? 'N/A', c),
                _detailRow('Employee ID', req['employee_id'] ?? req['user_id'] ?? 'N/A', c),
                _detailRow('Email', req['email'] ?? 'N/A', c),
                _detailRow('Mobile', req['mobile_number'] ?? 'N/A', c),
                _detailRow('Requested At', (req['requested_at'] ?? '').toString().split('T')[0], c),
                _detailRow('Reason', req['reason'] ?? 'Not specified', c),
                if ((req['details'] ?? '').toString().isNotEmpty)
                  _detailRow('Details', req['details'] ?? '', c),
                if ((req['admin_remarks'] ?? '').toString().isNotEmpty)
                  _detailRow('Admin Remarks', req['admin_remarks'] ?? '', c),
                const SizedBox(height: 20),
                if (!isFinal) ...[
                  Text(
                    'ACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: c.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (status != 'UNDER_REVIEW')
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _handleAction(req, 'under_review');
                          },
                          icon: const Icon(Icons.rate_review_outlined, size: 16),
                          label: const Text('Mark Under Review'),
                        ),
                      if (status != 'APPROVED')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _handleAction(req, 'approve');
                          },
                          icon: const Icon(Icons.check, size: 16, color: Colors.white),
                          label: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: c.red),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _handleAction(req, 'reject');
                        },
                        icon: Icon(Icons.close, size: 16, color: c.red),
                        label: Text('Reject', style: TextStyle(color: c.red)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.red,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _handleAction(req, 'complete');
                        },
                        icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
                        label: const Text('Complete Deletion', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, AdminPalette c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, AdminPalette c) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'PENDING':
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF856404);
        break;
      case 'UNDER_REVIEW':
        bg = const Color(0xFFCCE5FF);
        fg = const Color(0xFF004085);
        break;
      case 'APPROVED':
        bg = const Color(0xFFD4EDDA);
        fg = const Color(0xFF155724);
        break;
      case 'REJECTED':
        bg = const Color(0xFFF8D7DA);
        fg = const Color(0xFF721C24);
        break;
      case 'COMPLETED':
        bg = const Color(0xFFE2E3E5);
        fg = const Color(0xFF383D41);
        break;
      case 'CANCELLED':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        break;
      default:
        bg = c.cardBg;
        fg = c.text;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);

    return AdminShell(
      title: 'Deletion Requests',
      child: RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Search Box
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadRequests(),
              decoration: InputDecoration(
                hintText: 'Search by employee name, ID, or email...',
                hintStyle: TextStyle(color: c.hint, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: c.muted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadRequests();
                        },
                      )
                    : null,
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('ALL', 'All (${_counts['total'] ?? 0})', c),
                  const SizedBox(width: 6),
                  _filterChip('PENDING', 'Pending (${_counts['pending'] ?? 0})', c),
                  const SizedBox(width: 6),
                  _filterChip('UNDER_REVIEW', 'Under Review (${_counts['under_review'] ?? 0})', c),
                  const SizedBox(width: 6),
                  _filterChip('APPROVED', 'Approved (${_counts['approved'] ?? 0})', c),
                  const SizedBox(width: 6),
                  _filterChip('COMPLETED', 'Completed (${_counts['completed'] ?? 0})', c),
                  const SizedBox(width: 6),
                  _filterChip('REJECTED', 'Rejected (${_counts['rejected'] ?? 0})', c),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Requests List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              AdminCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: c.red, size: 36),
                      const SizedBox(height: 10),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: c.text)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadRequests,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_requests.isEmpty)
              AdminCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: c.muted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No account deletion requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'There are no requests matching the selected filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._requests.map((req) => _buildRequestCard(req, c)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label, AdminPalette c) {
    final isSelected = _selectedStatusFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatusFilter = key);
        _loadRequests();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? c.primary : c.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : c.text,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, AdminPalette c) {
    final status = req['status'] ?? 'PENDING';
    final empName = req['employee_name'] ?? req['user_id'] ?? 'Employee';
    final empId = req['employee_id'] ?? req['user_id'] ?? '';
    final email = req['email'] ?? '';
    final mobile = req['mobile_number'] ?? '';
    final rawDate = req['requested_at'] ?? '';
    final reqDate = rawDate.isNotEmpty ? rawDate.split('T')[0] : '';
    final reason = req['reason'] ?? 'Not specified';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showRequestDetailsModal(req),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: c.primary.withOpacity(0.12),
                      child: Icon(Icons.person_outline_rounded, color: c.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            empName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: c.text,
                            ),
                          ),
                          Text(
                            'ID: $empId • $reqDate',
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(status, c),
                  ],
                ),
                const SizedBox(height: 10),
                if (email.isNotEmpty || mobile.isNotEmpty) ...[
                  Row(
                    children: [
                      if (email.isNotEmpty) ...[
                        Icon(Icons.email_outlined, size: 14, color: c.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(fontSize: 12, color: c.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (mobile.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.phone_outlined, size: 14, color: c.muted),
                        const SizedBox(width: 4),
                        Text(
                          mobile,
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reason: $reason',
                    style: TextStyle(fontSize: 12, color: c.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
