import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';

/// Consistent module AppBar branding.
///
/// Regular role modules keep the logo on the left of the title. CEO screens
/// can use [centered] to make the logo the visual center of the AppBar.
class AppBarLogoTitle extends StatelessWidget {
  final String title;
  final bool centered;

  const AppBarLogoTitle({
    super.key,
    required this.title,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    if (centered) {
      return const Center(child: BitByteLogo(compact: true));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BitByteLogo(compact: true),
        const SizedBox(width: 10),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
