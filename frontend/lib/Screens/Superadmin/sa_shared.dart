import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';

class SaPalette {
  final bool isDark;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color row;
  final Color input;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color success;
  final Color danger;
  final Color warning;
  final Color teal;
  final Color blue;
  final Color purple;
  final List<BoxShadow> shadow;

  const SaPalette({
    required this.isDark,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.row,
    required this.input,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.teal,
    required this.blue,
    required this.purple,
    required this.shadow,
  });

  factory SaPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const SaPalette(
        isDark: true,
        background: Color(0xFF001525),
        backgroundAlt: Color(0xFF05243A),
        surface: Color(0xFF052035),
        row: Color(0xFF07263D),
        input: Color(0xFF031A2C),
        border: Color(0xFF17405A),
        text: Color(0xFFF8FAFC),
        muted: Color(0xFF8DA1B7),
        primary: Color(0xFF0072FF),
        success: Color(0xFF22C55E),
        danger: Color(0xFFEF4444),
        warning: Color(0xFFF59E0B),
        teal: Color(0xFF14B8A6),
        blue: Color(0xFF3B82F6),
        purple: Color(0xFF8B5CF6),
        shadow: [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 10))],
      );
    }
    return SaPalette(
      isDark: false,
      background: const Color(0xFFF6F9FF),
      backgroundAlt: const Color(0xFFEFF5FF),
      surface: Colors.white,
      row: Colors.white,
      input: const Color(0xFFF8FBFF),
      border: const Color(0xFFE1E8F3),
      text: const Color(0xFF0F172A),
      muted: const Color(0xFF64748B),
      primary: const Color(0xFF0072FF),
      success: const Color(0xFF16A34A),
      danger: const Color(0xFFEF4444),
      warning: const Color(0xFFF59E0B),
      teal: const Color(0xFF14B8A6),
      blue: const Color(0xFF3B82F6),
      purple: const Color(0xFF8B5CF6),
      shadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, 8))],
    );
  }
}

class SaScreen extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? floatingActionButton;
  final int? activeIndex;

  const SaScreen({super.key, required this.title, required this.child, this.trailing, this.floatingActionButton, this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [c.background, c.backgroundAlt], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: AppLayout.headerPadding,
                child: Row(
                  children: [
                    SizedBox(width: AppLayout.iconTouchTarget, height: AppLayout.iconTouchTarget, child: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.text, size: 18), onPressed: () => Navigator.maybePop(context))),
                    Expanded(child: Text(title, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w900))),
                    SizedBox(width: AppLayout.iconTouchTarget, height: AppLayout.iconTouchTarget, child: Center(child: trailing ?? const SizedBox.shrink())),
                  ],
                ),
              ),
              Expanded(child: child),
              SaBottomNav(colors: c, selectedIndex: activeIndex ?? _activeIndexForTitle(title)),
            ],
          ),
        ),
      ),
    );
  }

  int _activeIndexForTitle(String title) {
    if (title.contains('User') || title.contains('Role') || title.contains('Department')) return 1;
    if (title.contains('Attendance') || title.contains('Leave') || title.contains('Task') || title.contains('Meeting')) return 2;
    if (title.contains('Payroll') || title.contains('Reports')) return 3;
    if (title.contains('Notification') || title.contains('Settings') || title.contains('Profile') || title.contains('Logout')) return 4;
    return 0;
  }
}

class SaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const SaCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppLayout.cardPadding), this.color});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color ?? c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border), boxShadow: c.shadow),
      child: child,
    );
  }
}

class SaInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color? color;

  const SaInfoTile({super.key, required this.icon, required this.title, required this.subtitle, this.trailing, this.color});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    final accent = color ?? c.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.itemGap),
      child: SaCard(
        color: c.row,
        child: Row(
          children: [
            SaIconBox(icon: icon, color: accent),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [saTitle(context, title, 13), const SizedBox(height: 3), saMuted(context, subtitle, 11)])),
            if (trailing != null) Text(trailing!, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: c.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class SaMetricGrid extends StatelessWidget {
  final List<SaMetric> metrics;

  const SaMetricGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: metrics.map((metric) => SaMetricCard(metric: metric)).toList(),
    );
  }
}

class SaMetricCard extends StatelessWidget {
  final SaMetric metric;

  const SaMetricCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [SaIconBox(icon: metric.icon, color: metric.color), const Spacer(), Icon(Icons.trending_up_rounded, color: c.success, size: 14)]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [saTitle(context, metric.value, 20), const SizedBox(height: 2), saMuted(context, metric.title, 11)]),
        ],
      ),
    );
  }
}

class SaIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const SaIconBox({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color.withAlpha(c.isDark ? 40 : 22), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class SaBottomNav extends StatelessWidget {
  final SaPalette colors;
  final int selectedIndex;

  const SaBottomNav({super.key, required this.colors, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    const items = [
      _SaNavItem(Icons.dashboard_outlined, 'Dashboard'),
      _SaNavItem(Icons.group_outlined, 'Users'),
      _SaNavItem(Icons.account_tree_outlined, 'Workflow'),
      _SaNavItem(Icons.insert_chart_outlined_rounded, 'Reports'),
      _SaNavItem(Icons.settings_outlined, 'Settings'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = index == selectedIndex;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: active
                      ? Theme.of(context).colorScheme.secondary
                      : colors.muted,
                  size: 19,
                ),
                const SizedBox(height: 3),
                FittedBox(child: Text(item.label, style: TextStyle(color: active ? colors.primary : colors.muted, fontSize: 10, fontWeight: FontWeight.w800))),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SaNavItem {
  final IconData icon;
  final String label;

  const _SaNavItem(this.icon, this.label);
}

class SaMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SaMetric(this.title, this.value, this.icon, this.color);
}

Widget saList(List<Widget> children) => ListView(padding: AppLayout.pagePadding, children: children);

Widget saTitle(BuildContext context, String text, double size) {
  final c = SaPalette.of(context);
  return Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: size, fontWeight: FontWeight.w900));
}

Widget saMuted(BuildContext context, String text, double size) {
  final c = SaPalette.of(context);
  return Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: size, fontWeight: FontWeight.w600));
}

Widget saSearch(BuildContext context, String hint) {
  final c = SaPalette.of(context);
  return SaCard(
    color: c.input,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    child: Row(children: [Icon(Icons.search_rounded, color: c.muted, size: 18), const SizedBox(width: 8), saMuted(context, hint, 12)]),
  );
}
