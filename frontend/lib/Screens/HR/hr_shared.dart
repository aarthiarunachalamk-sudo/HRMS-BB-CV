import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

class HrPalette {
  final bool isDark;
  final Color bg;
  final Color bgAlt;
  final Color surface;
  final Color row;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color success;
  final Color danger;
  final Color warning;
  final Color purple;
  final Color teal;

  const HrPalette({
    required this.isDark,
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.row,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.purple,
    required this.teal,
  });

  factory HrPalette.of(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    if (isDark) {
      return const HrPalette(
        isDark: true,
        bg: Color(0xFF061625),
        bgAlt: Color(0xFF071D30),
        surface: Color(0xFF0C2438),
        row: Color(0xFF102D44),
        border: Color(0xFF1C405A),
        text: Color(0xFFF8FAFC),
        muted: Color(0xFF93A9BC),
        primary: Color(0xFF00C6FF),
        success: Color(0xFF22C55E),
        danger: Color(0xFFEF4444),
        warning: Color(0xFFF59E0B),
        purple: Color(0xFFA855F7),
        teal: Color(0xFF14B8A6),
      );
    }
    return const HrPalette(
      isDark: false,
      bg: Color(0xFFF7FAFF),
      bgAlt: Color(0xFFEFF6FF),
      surface: Colors.white,
      row: Color(0xFFF8FBFF),
      border: Color(0xFFE1E8F3),
      text: Color(0xFF0F172A),
      muted: Color(0xFF64748B),
      primary: Color(0xFF0072FF),
      success: Color(0xFF16A34A),
      danger: Color(0xFFDC2626),
      warning: Color(0xFFF59E0B),
      purple: Color(0xFF7C3AED),
      teal: Color(0xFF0D9488),
    );
  }
}

class HrCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HrCard({super.key, required this.child, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(c.isDark ? 45 : 10), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class HrMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const HrMetricCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: HrCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: color, size: 22),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded, color: color.withAlpha(120), size: 11),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ],
        ),
      ),
    );
  }
}

class HrListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color? color;
  final VoidCallback? onTap;

  const HrListTile({super.key, required this.icon, required this.title, required this.subtitle, this.trailing, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final accent = color ?? c.primary;
    final tile = HrCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: accent.withAlpha(24), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: accent, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
          if (trailing != null) Text(trailing!, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900)),
          Icon(Icons.chevron_right_rounded, color: c.muted, size: 18),
        ],
      ),
    );
    if (onTap == null) return tile;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: tile);
  }
}

String hrText(Map<String, dynamic> data, String key) => '${data[key] ?? ''}';

List<Map<String, dynamic>> hrList(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! List) return [];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}
