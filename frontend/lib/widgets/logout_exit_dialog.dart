import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

Future<void> showLogoutConfirmation({
  required BuildContext context,
  required VoidCallback onLogout,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ThemeConfig.getCardBg(dialogContext),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.logout_rounded, color: Colors.orangeAccent, size: 42),
      title: Text('Logout?', textAlign: TextAlign.center, style: TextStyle(color: ThemeConfig.getTextPrimary(dialogContext), fontWeight: FontWeight.w900)),
      content: Text('Are you sure you want to logout from this session?', textAlign: TextAlign.center, style: TextStyle(color: ThemeConfig.getTextSecondary(dialogContext))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton.icon(onPressed: () => Navigator.pop(dialogContext, true), icon: const Icon(Icons.logout_rounded), label: const Text('Logout')),
      ],
    ),
  );
  if (confirmed == true && context.mounted) onLogout();
}

Future<void> showLogoutExitConfirmation({
  required BuildContext context,
  required VoidCallback onLogout,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: ThemeConfig.getCardBg(dialogContext),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.orangeAccent,
          size: 42,
        ),
        title: Text(
          'Log Out & Exit?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ThemeConfig.getTextPrimary(dialogContext),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'Do you want to log out and close the HRMS app?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ThemeConfig.getTextSecondary(dialogContext),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay Logged In'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out & Exit'),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  onLogout();
  await Future<void>.delayed(const Duration(milliseconds: 120));
  await SystemNavigator.pop();
}
