import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';

class CeoColors {
  static const bgTop = Color(0xFF020916);
  static const bgBottom = Color(0xFF061D34);
  static const card = Color(0xFF071A2D);
  static const cardAlt = Color(0xFF0A2238);
  static const border = Color(0xFF123A5C);
  static const cyan = Color(0xFF0072FF); // Login-button blue
  static const green = Color(0xFF13D989);
  static const purple = Color(0xFF8B5CFF);
  static const gold = Color(0xFFD7932E);
  static const pink = Color(0xFFFF3D8F);
  static const muted = Color(0xFF9DAEC1);
}

class CeoShell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;
  final Widget? trailing;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final VoidCallback? onBack;

  const CeoShell({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
    this.trailing,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bgTop = ThemeConfig.getBgStart(context);
    final bgBottom = ThemeConfig.getBgEnd(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    return Scaffold(
      backgroundColor: bgTop,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rightWidth = trailing == null
                        ? 48.0
                        : (constraints.maxWidth < 360 ? 88.0 : 96.0);
                    return Row(
                      children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: showBack
                              ? IconButton(
                                  constraints: const BoxConstraints.tightFor(
                                    width: 42,
                                    height: 42,
                                  ),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: textPrimary,
                                    size: 18,
                                  ),
                                  onPressed:
                                      onBack ??
                                      () => Navigator.of(context).pop(),
                                )
                              : Builder(
                                  builder: (ctx) => IconButton(
                                    constraints: const BoxConstraints.tightFor(
                                      width: 42,
                                      height: 42,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Menu',
                                    icon: Icon(
                                      Icons.menu_rounded,
                                      color: textPrimary,
                                      size: 26,
                                    ),
                                    onPressed: () =>
                                        Scaffold.of(ctx).openDrawer(),
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Semantics(
                            label: title,
                            header: true,
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: BitByteLogo(compact: true),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: rightWidth,
                          height: 42,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const _CeoThemeToggleButton(),
                              if (trailing != null)
                                SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: trailing,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _CeoThemeToggleButton extends StatelessWidget {
  const _CeoThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          constraints: const BoxConstraints.tightFor(width: 40, height: 42),
          padding: EdgeInsets.zero,
          tooltip: isDark ? 'Light theme' : 'Dark theme',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: ThemeConfig.getTextPrimary(context),
            size: 20,
          ),
          onPressed: () {
            MyApp.themeNotifier.value = isDark
                ? ThemeMode.light
                : ThemeMode.dark;
          },
        );
      },
    );
  }
}

class CeoFutureBody extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final Widget Function(Map<String, dynamic> data) builder;

  const CeoFutureBody({super.key, required this.future, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: muted('Unable to load data. Please try again.', 12),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: CeoColors.cyan),
          );
        }
        return builder(snapshot.data!);
      },
    );
  }
}

class CeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const CeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              ThemeConfig.isDark(context) ? 0.32 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null)
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: card);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

class CeoMetricGrid extends StatelessWidget {
  final List<CeoMetric> cards;

  const CeoMetricGrid({super.key, required this.cards});

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
      itemBuilder: (context, index) {
        final card = cards[index];
        return CeoCard(
          onTap: card.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(card.icon, color: card.color, size: 20),
                  const Spacer(),
                  if (card.trend.isNotEmpty)
                    small(card.trend, color: CeoColors.green),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  muted(card.title, 11),
                  const SizedBox(height: 4),
                  title(card.value, 20),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class CeoListTile extends StatelessWidget {
  final IconData icon;
  final String titleText;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const CeoListTile({
    super.key,
    required this.icon,
    required this.titleText,
    required this.subtitle,
    this.color = CeoColors.cyan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CeoCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(titleText, 14),
                const SizedBox(height: 3),
                muted(subtitle, 11),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: CeoColors.muted),
        ],
      ),
    );
  }
}

class CeoMetric {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const CeoMetric(
    this.title,
    this.value,
    this.trend,
    this.icon,
    this.color, {
    this.onTap,
  });
}

Widget chartCard(
  String titleText,
  List<dynamic> bars, {
  String? subtitle,
  String? trend,
  Color color = CeoColors.cyan,
  VoidCallback? onTap,
}) {
  final values = bars.map((item) => double.tryParse('$item') ?? 36).toList();
  return CeoCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null) muted(subtitle, 11),
        Row(
          children: [
            Expanded(child: title(titleText, 18)),
            if (trend != null) small(trend, color: CeoColors.green),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 88,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values
                .map(
                  (h) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.35), color],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
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

Widget pageList(List<Widget> children) {
  return ListView(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
    children: children,
  );
}

Widget title(String text, double size) {
  return Builder(
    builder: (context) => Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: ThemeConfig.getTextPrimary(context),
        fontSize: size,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

Widget muted(String text, double size) {
  return Builder(
    builder: (context) => Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: ThemeConfig.getTextSecondary(context),
        fontSize: size,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget small(String text, {Color color = CeoColors.cyan}) {
  return Text(
    text,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
  );
}
