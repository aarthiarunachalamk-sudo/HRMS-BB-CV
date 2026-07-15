import 'package:flutter/material.dart';
import 'admin_palette.dart';
import 'admin_widgets.dart';

class AdminSuccessScreen extends StatelessWidget {
  final String message;
  final String subMessage;
  final String actionLabel;
  final VoidCallback onAction;

  const AdminSuccessScreen({
    super.key,
    required this.message,
    required this.subMessage,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Success',
      showBack: false,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.green.withOpacity(0.12),
                border: Border.all(color: c.green.withOpacity(0.4), width: 2),
              ),
              child: Icon(Icons.check_rounded, color: c.green, size: 58),
            ),
            const SizedBox(height: 28),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.text, fontSize: 22, fontWeight: FontWeight.w800, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 38),
            AdminPrimaryButton(label: actionLabel, onTap: onAction),
          ],
        ),
      ),
    );
  }
}
