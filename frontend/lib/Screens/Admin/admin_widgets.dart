import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'admin_palette.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';

// ─────────────────────────────────────────────────────────────
//  Shell  (top bar + gradient background, matches CEO pattern)
// ─────────────────────────────────────────────────────────────
class AdminShell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;
  final Widget? trailing;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AdminShell({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
    this.trailing,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(gradient: c.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _AdminTopBar(
                c: c,
                title: title,
                showBack: showBack,
                trailing: trailing,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final AdminPalette c;
  final String title;
  final bool showBack;
  final Widget? trailing;

  const _AdminTopBar({
    required this.c,
    required this.title,
    required this.showBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.headerPadding,
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: showBack
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: c.text,
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : Builder(
                    builder: (ctx) => IconButton(
                      constraints: const BoxConstraints.tightFor(
                        width: 42,
                        height: 42,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Menu',
                      icon: Icon(Icons.menu_rounded, color: c.text, size: 26),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
          ),
          if (!showBack) ...[
            const SizedBox(width: 4),
            const BitByteLogo(compact: true),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              textAlign: showBack ? TextAlign.center : TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: AppLayout.iconTouchTarget,
            height: AppLayout.iconTouchTarget,
            child: Center(
              child:
                  trailing ??
                  IconButton(
                    constraints: const BoxConstraints.tightFor(
                      width: 42,
                      height: 42,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: c.isDark ? 'Light theme' : 'Dark theme',
                    icon: Icon(
                      c.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: c.primary,
                      size: 20,
                    ),
                    onPressed: AdminPalette.toggleTheme,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Card
// ─────────────────────────────────────────────────────────────
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppLayout.cardPadding),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
        boxShadow: c.shadow,
      ),
      child: child,
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppLayout.itemGap),
        child: card,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.itemGap),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  List tile
// ─────────────────────────────────────────────────────────────
class AdminListTile extends StatelessWidget {
  final IconData icon;
  final String titleText;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AdminListTile({
    super.key,
    required this.icon,
    required this.titleText,
    required this.subtitle,
    this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    final col = color ?? c.primary;
    return AdminCard(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Container(
              width: AppLayout.iconTouchTarget,
              height: AppLayout.iconTouchTarget,
              decoration: BoxDecoration(
                color: col.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: col, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  adminTitle(titleText, 14, c),
                  const SizedBox(height: 3),
                  adminMuted(subtitle, 11, c),
                ],
              ),
            ),
            const SizedBox(width: AppLayout.compactGap),
            SizedBox(
              width: AppLayout.iconTouchTarget,
              child: Align(
                alignment: Alignment.centerRight,
                child:
                    trailing ??
                    Icon(Icons.chevron_right_rounded, color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Metric grid
// ─────────────────────────────────────────────────────────────
class AdminMetricGrid extends StatelessWidget {
  final List<AdminMetric> cards;
  const AdminMetricGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) {
        final card = cards[i];
        final c = AdminPalette.of(context);
        return AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(card.icon, color: card.color, size: 20),
                  const Spacer(),
                  if (card.trend.isNotEmpty)
                    Text(
                      card.trend,
                      style: TextStyle(
                        color: c.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  adminMuted(card.label, 11, c),
                  const SizedBox(height: 4),
                  adminTitle(card.value, 20, c),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminMetric {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
  const AdminMetric(this.label, this.value, this.trend, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────
//  Mini bar chart card
// ─────────────────────────────────────────────────────────────
class AdminChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trend;
  final List<double> bars;
  final Color? color;

  const AdminChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trend,
    required this.bars,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    final col = color ?? c.primary;
    return AdminCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) adminMuted(subtitle!, 11, c),
          Row(
            children: [
              Expanded(child: adminTitle(title, 16, c)),
              if (trend != null)
                Text(
                  trend!,
                  style: TextStyle(
                    color: c.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [col.withOpacity(0.35), col],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Section title helper
// ─────────────────────────────────────────────────────────────
class AdminSectionTitle extends StatelessWidget {
  final String text;
  const AdminSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: c.text,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Info row (label / value pair inside a card)
// ─────────────────────────────────────────────────────────────
class AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const AdminInfoRow(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(flex: 2, child: adminMuted(label, 12, c)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? c.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Search box
// ─────────────────────────────────────────────────────────────
class AdminSearchBox extends StatelessWidget {
  final String hint;
  const AdminSearchBox({super.key, this.hint = 'Search...'});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: c.muted),
          const SizedBox(width: 10),
          adminMuted(hint, 12, c),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Gradient primary button
// ─────────────────────────────────────────────────────────────
class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: c.primaryGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Status badge
// ─────────────────────────────────────────────────────────────
class AdminBadge extends StatelessWidget {
  final String text;
  final Color color;
  const AdminBadge(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Page list helper
// ─────────────────────────────────────────────────────────────
Widget adminPageList(List<Widget> children) =>
    ListView(padding: AppLayout.pagePadding, children: children);

// ─────────────────────────────────────────────────────────────
//  Text helpers
// ─────────────────────────────────────────────────────────────
Widget adminTitle(String t, double size, AdminPalette c) => Text(
  t,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(color: c.text, fontSize: size, fontWeight: FontWeight.w800),
);

Widget adminMuted(String t, double size, AdminPalette c) => Text(
  t,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(color: c.muted, fontSize: size, fontWeight: FontWeight.w500),
);

Widget adminSmall(String t, Color color) => Text(
  t,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
);

// ─────────────────────────────────────────────────────────────
//  Divider with label
// ─────────────────────────────────────────────────────────────
class AdminDividerLabel extends StatelessWidget {
  final String text;
  const AdminDividerLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: c.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: adminMuted(text, 11, c),
          ),
          Expanded(child: Divider(color: c.border)),
        ],
      ),
    );
  }
}
