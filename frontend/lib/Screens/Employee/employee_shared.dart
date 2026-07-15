import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

class EmployeeColors {
  static const blue = Color(0xFF4FACFE);
  static const green = Color(0xFF00D46A);
  static const purple = Color(0xFF8B5CFF);
  static const gold = Color(0xFFFF9F1C);
  static const red = Color(0xFFFF3B3B);
  static const pink = Color(0xFFFF3D8F);
}

class EmployeePage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? action;

  const EmployeePage({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const EmployeeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: ThemeConfig.getCardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ThemeConfig.getCardBorder(context)),
      ),
      child: child,
    );
  }
}

class EmployeeInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const EmployeeInfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;
  final VoidCallback? onTap;

  const EmployeeListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F3654);
    final textSecondary = isDark
        ? const Color(0xFF9AA8BA)
        : const Color(0xFF607086);
    return EmployeeCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              trailing,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color employeeStatusColor(String status) {
  final value = status.toLowerCase();
  if (value.contains('approved') ||
      value.contains('success') ||
      value.contains('completed') ||
      value.contains('present') ||
      value.contains('full day')) {
    return EmployeeColors.green;
  }
  if (value.contains('reject') || value.contains('error')) {
    return EmployeeColors.red;
  }
  if (value.contains('pending') ||
      value.contains('warning') ||
      value.contains('half') ||
      value.contains('late')) {
    return EmployeeColors.gold;
  }
  return EmployeeColors.blue;
}
