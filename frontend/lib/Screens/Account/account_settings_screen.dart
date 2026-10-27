import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Account/account_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Account/delete_account_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/Change_Password.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_client.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String userId;
  final String? email;
  final String? role;
  final bool loadOnInit;

  const AccountSettingsScreen({
    super.key,
    required this.userId,
    this.email,
    this.role,
    this.loadOnInit = true,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final AccountService _accountService = AccountService();
  late bool _isLoading;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _activeDeletionRequest;

  @override
  void initState() {
    super.initState();
    if (widget.loadOnInit) {
      _isLoading = true;
      _loadAccountData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadAccountData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user profile
      try {
        final profileUri = ApiConfig.uri('/profile/').replace(
          queryParameters: {'user_id': widget.userId},
        );
        final res = await ApiClient.get(profileUri);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final data = jsonDecode(res.body);
          if (data is Map && data['profile'] is Map) {
            _userProfile = Map<String, dynamic>.from(data['profile']);
          }
        }
      } catch (_) {}

      // Load active deletion request if any
      try {
        final res = await _accountService.fetchActiveDeletionRequest(widget.userId);
        if (res['has_active_request'] == true && res['request'] is Map) {
          _activeDeletionRequest = Map<String, dynamic>.from(res['request']);
        } else {
          _activeDeletionRequest = null;
        }
      } catch (_) {}
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    final resolvedEmail = widget.email ??
        _userProfile?['personal_email'] ??
        _userProfile?['email'] ??
        '';
    final resolvedName = _userProfile?['full_name'] ??
        _userProfile?['employee_name'] ??
        widget.userId;
    final resolvedRole = widget.role ?? _userProfile?['role'] ?? 'Employee';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAccountData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Account Header Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          child: Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resolvedName.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'ID: ${widget.userId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (resolvedEmail.toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  resolvedEmail.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            resolvedRole.toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Deletion Request Banner (if any)
                  if (_activeDeletionRequest != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFEEBA)),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.hourglass_top_rounded,
                                color: Color(0xFF856404),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Account Deletion Requested',
                                style: TextStyle(
                                  color: Color(0xFF856404),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF856404),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_activeDeletionRequest!['status']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Request ID: ${_activeDeletionRequest!['request_id'] ?? ''}\nYour request is being processed by the administration team.',
                            style: const TextStyle(
                              color: Color(0xFF533F03),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DeleteAccountScreen(
                                      userId: widget.userId,
                                      initialRequest: _activeDeletionRequest,
                                    ),
                                  ),
                                );
                                _loadAccountData();
                              },
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  color: Color(0xFF856404),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'SECURITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  // Change Password Tile
                  _buildMenuCard(
                    context,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF0072FF),
                        title: 'Change Password',
                        subtitle: 'Update your login credentials',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChangePasswordScreen(
                                employeeId: widget.userId,
                                otc: '',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'ACCOUNT MANAGEMENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: ThemeConfig.getTextSecondary(context),
                      ),
                    ),
                  ),

                  // Delete Account Tile (with non-aggressive warning icon)
                  _buildMenuCard(
                    context,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.delete_outline_rounded,
                        iconColor: const Color(0xFFE53935),
                        title: 'Delete Account',
                        subtitle: 'Request permanent deletion of your account and eligible data',
                        showWarningBadge: _activeDeletionRequest != null,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DeleteAccountScreen(
                                userId: widget.userId,
                                initialRequest: _activeDeletionRequest,
                              ),
                            ),
                          );
                          _loadAccountData();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Account deletion requests are processed in compliance with organization retention policies and Google Play user data safety guidelines.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required List<Widget> children}) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showWarningBadge = false,
  }) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        if (showWarningBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFFEEBA)),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                color: Color(0xFF856404),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary.withOpacity(0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
