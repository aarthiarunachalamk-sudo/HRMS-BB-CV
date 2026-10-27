import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Account/account_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

class DeleteAccountScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialRequest;
  final bool checkStatusOnInit;

  const DeleteAccountScreen({
    super.key,
    required this.userId,
    this.initialRequest,
    this.checkStatusOnInit = true,
  });

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final AccountService _accountService = AccountService();

  bool _isLoading = false;
  late bool _isCheckingStatus;
  bool _confirmedCheckbox = false;

  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Map<String, dynamic>? _activeRequest;
  Map<String, dynamic>? _submittedRequest;

  static const List<String> _reasonOptions = [
    'I no longer use this account',
    'I left the organization',
    'Privacy concerns',
    'Duplicate account',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialRequest != null) {
      _activeRequest = widget.initialRequest;
      _isCheckingStatus = false;
    } else if (widget.checkStatusOnInit) {
      _isCheckingStatus = true;
      _checkExistingRequest();
    } else {
      _isCheckingStatus = false;
    }
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    setState(() => _isCheckingStatus = true);
    try {
      final res = await _accountService.fetchActiveDeletionRequest(widget.userId);
      if (mounted) {
        setState(() {
          if (res['has_active_request'] == true && res['request'] is Map) {
            _activeRequest = Map<String, dynamic>.from(res['request']);
          } else {
            _activeRequest = null;
          }
        });
      }
    } catch (_) {
      // Continue even if network check fails
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _onInitiateDeletion() async {
    if (!_confirmedCheckbox) return;

    // Show confirmation dialog: Title "Confirm Account Deletion", Message "Are you sure you want to request deletion of your account?"
    final confirmed = await _showFinalConfirmationDialog();
    if (confirmed != true) {
      return;
    }

    // Call Backend API
    await _submitDeletionRequest();
  }

  Future<String?> _showPasswordVerificationDialog() async {
    _passwordController.clear();
    bool obscure = true;
    String? dialogError;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeConfig.isDark(context);
            return AlertDialog(
              backgroundColor: ThemeConfig.getCardBg(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: ThemeConfig.getCardBorder(context)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Security Verification',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To verify your identity, please enter your current account password before requesting deletion.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ThemeConfig.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: ThemeConfig.getTextSecondary(context)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final pwd = _passwordController.text;
                    if (pwd.trim().isEmpty) {
                      setDialogState(() {
                        dialogError = 'Password is required to verify identity.';
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(pwd);
                  },
                  child: const Text('Verify', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showFinalConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ThemeConfig.getCardBg(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: ThemeConfig.getCardBorder(context)),
          ),
          title: const Text(
            'Confirm Account Deletion',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Are you sure you want to request deletion of your account?',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            // Cancel is default, non-destructive
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(color: ThemeConfig.getCardBorder(context)),
              ),
              autofocus: true,
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeConfig.getTextPrimary(context),
                ),
              ),
            ),
            // Confirm Deletion is destructive
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Confirm Deletion',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitDeletionRequest([String? password]) async {
    setState(() => _isLoading = true);

    try {
      final reason = _selectedReason;
      final details = _selectedReason == 'Other'
          ? _otherReasonController.text.trim()
          : (_otherReasonController.text.trim().isNotEmpty
              ? _otherReasonController.text.trim()
              : null);

      final response = await _accountService.requestAccountDeletion(
        userId: widget.userId,
        password: password,
        reason: reason,
        details: details,
      );

      if (mounted) {
        setState(() {
          _submittedRequest = (response['request'] is Map)
              ? Map<String, dynamic>.from(response['request'])
              : {
                  'request_id': 'DEL-${DateTime.now().millisecondsSinceEpoch}',
                  'requested_at': DateTime.now().toIso8601String(),
                  'status': 'PENDING',
                };
        });
      }
    } on AccountServiceException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelActiveRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConfig.getCardBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ThemeConfig.getCardBorder(context)),
        ),
        title: const Text('Cancel Deletion Request'),
        content: const Text(
          'Are you sure you want to cancel your account deletion request? Your account will remain active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep Request'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _accountService.cancelDeletionRequest(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deletion request has been cancelled.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        setState(() {
          _activeRequest = null;
        });
      }
    } on AccountServiceException catch (e) {
      if (mounted) _showErrorSnackBar(e.message);
    } catch (e) {
      if (mounted) _showErrorSnackBar('Unable to cancel request. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: _isCheckingStatus
          ? const Center(child: CircularProgressIndicator())
          : _submittedRequest != null
              ? _buildSuccessView()
              : _activeRequest != null
                  ? _buildActiveRequestView()
                  : _buildRequestFormView(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. Success Screen (After Submission)
  // ─────────────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    final reqId = _submittedRequest!['request_id'] ?? 'Pending';
    final rawDate = _submittedRequest!['requested_at'] ?? '';
    final formattedDate = rawDate.isNotEmpty
        ? rawDate.split('T')[0]
        : DateTime.now().toString().split(' ')[0];
    final status = _submittedRequest!['status'] ?? 'PENDING';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Account deletion request submitted',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your account deletion request has been submitted successfully. The HR/Admin team will review your request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _infoRow('Request ID', reqId),
                  const Divider(height: 20),
                  _infoRow('Request Date', formattedDate),
                  const Divider(height: 20),
                  _infoRow('Status', 'Pending', isStatusBadge: true),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Active Request Status View
  // ─────────────────────────────────────────────────────────────
  Widget _buildActiveRequestView() {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    final reqId = _activeRequest!['request_id'] ?? '';
    final rawDate = _activeRequest!['requested_at'] ?? '';
    final formattedDate = rawDate.isNotEmpty
        ? rawDate.split('T')[0]
        : '';
    final status = _activeRequest!['status'] ?? 'PENDING';
    final reason = _activeRequest!['reason'] ?? 'Not specified';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFFF57F17),
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Deletion Request Under Review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You already have an active account deletion request. While this is pending review, your normal account access continues until final action is taken by HR/Admin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6D4C41),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              _infoRow('Request ID', reqId),
              const Divider(height: 20),
              _infoRow('Requested On', formattedDate),
              const Divider(height: 20),
              _infoRow('Reason', reason),
              const Divider(height: 20),
              _infoRow('Current Status', status, isStatusBadge: true),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE53935)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _cancelActiveRequest,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined, color: Color(0xFFE53935)),
            label: Text(
              _isLoading ? 'Cancelling...' : 'Cancel Deletion Request',
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Cancelling will withdraw your request and keep your HRMS account fully active.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Main Account Deletion Request Form
  // ─────────────────────────────────────────────────────────────
  Widget _buildRequestFormView() {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main Warning Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFEEBA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF856404),
                size: 26,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Deleting your account will remove your HRMS account and eligible associated personal data. Certain HR, payroll, attendance, tax, statutory, employment, or audit records may be retained where required by law or company policy.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF533F03),
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Data that may be deleted
        _buildInfoCard(
          context,
          icon: Icons.delete_sweep_outlined,
          iconColor: const Color(0xFFE53935),
          title: 'Data that may be deleted',
          items: const [
            'User profile information',
            'Personal account information',
            'Contact information',
            'Profile photo',
            'User preferences',
            'App-specific user data that is not legally required to be retained',
          ],
        ),
        const SizedBox(height: 16),

        // Section: Data that may be retained if required
        _buildInfoCard(
          context,
          icon: Icons.shield_outlined,
          iconColor: const Color(0xFF1976D2),
          title: 'Data that may be retained if required',
          items: const [
            'Attendance records',
            'Payroll records',
            'Salary records',
            'Tax-related records',
            'Statutory records',
            'Audit logs',
            'Employment records required by the organization',
            'Records required by applicable law or company policy',
          ],
          footerNotice:
              'Retained records will no longer be used for normal app access after account deletion.',
        ),
        const SizedBox(height: 20),

        // Optional Reason Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Reason for deleting account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(Optional)',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                isExpanded: true,
                dropdownColor: cardBg,
                decoration: InputDecoration(
                  hintText: 'Select a reason',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _reasonOptions.map((r) {
                  return DropdownMenuItem<String>(
                    value: r,
                    child: Text(r, style: TextStyle(color: textPrimary, fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedReason = val);
                },
              ),
              if (_selectedReason == 'Other' || _selectedReason != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _otherReasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: _selectedReason == 'Other'
                        ? 'Please specify your reason...'
                        : 'Additional details (optional)...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Confirmation Checkbox
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _confirmedCheckbox
                  ? const Color(0xFFE53935).withOpacity(0.5)
                  : cardBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _confirmedCheckbox,
                  activeColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) {
                    setState(() => _confirmedCheckbox = val ?? false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _confirmedCheckbox = !_confirmedCheckbox);
                  },
                  child: Text(
                    'I understand that requesting account deletion may permanently remove my account and eligible associated data.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Primary Action Button (Disabled until checkbox is selected)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              disabledBackgroundColor: isDark ? const Color(0xFF332024) : const Color(0xFFFFCDD2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: _confirmedCheckbox ? 2 : 0,
            ),
            onPressed: (_confirmedCheckbox && !_isLoading) ? _onInitiateDeletion : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Request Account Deletion',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _confirmedCheckbox
                          ? Colors.white
                          : (isDark ? Colors.white38 : Colors.white70),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Your request will be submitted to the organization for review.',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
    String? footerNotice,
  }) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (footerNotice != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1976D2)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      footerNotice,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isStatusBadge = false}) {
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
        ),
        if (isStatusBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFEEBA)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF856404),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
      ],
    );
  }
}
