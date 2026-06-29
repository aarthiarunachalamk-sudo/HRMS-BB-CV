import 'package:flutter/material.dart';

class CeoColors {
  static const bgTop = Color(0xFF020916);
  static const bgBottom = Color(0xFF061D34);
  static const card = Color(0xFF071A2D);
  static const cardAlt = Color(0xFF0A2238);
  static const border = Color(0xFF123A5C);
  static const cyan = Color(0xFF00D3FF);
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

  const CeoShell({
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
    return Scaffold(
      backgroundColor: CeoColors.bgTop,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [CeoColors.bgTop, CeoColors.bgBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: showBack
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          : Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                    SizedBox(width: 42, height: 42, child: Center(child: trailing ?? const SizedBox.shrink())),
                  ],
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
          return Center(child: muted('Backend data unavailable', 12));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: CeoColors.cyan));
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

  const CeoCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CeoColors.card.withOpacity(0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CeoColors.border),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: child,
    );
    if (onTap == null) return Padding(padding: const EdgeInsets.only(bottom: 10), child: card);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap, child: card)),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.55),
      itemBuilder: (context, index) {
        final card = cards[index];
        return CeoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(card.icon, color: card.color, size: 20), const Spacer(), if (card.trend.isNotEmpty) small(card.trend, color: CeoColors.green)]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [muted(card.title, 11), const SizedBox(height: 4), title(card.value, 20)]),
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

  const CeoListTile({super.key, required this.icon, required this.titleText, required this.subtitle, this.color = CeoColors.cyan, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CeoCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title(titleText, 14), const SizedBox(height: 3), muted(subtitle, 11)])),
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

  const CeoMetric(this.title, this.value, this.trend, this.icon, this.color);
}

Widget chartCard(String titleText, List<dynamic> bars, {String? subtitle, String? trend, Color color = CeoColors.cyan}) {
  final values = bars.map((item) => double.tryParse('$item') ?? 36).toList();
  return CeoCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null) muted(subtitle, 11),
        Row(children: [Expanded(child: title(titleText, 18)), if (trend != null) small(trend, color: CeoColors.green)]),
        const SizedBox(height: 14),
        SizedBox(
          height: 88,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values
                .map((h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color.withOpacity(0.35), color], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    ),
  );
}

Widget pageList(List<Widget> children) {
  return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 18), children: children);
}

Widget title(String text, double size) {
  return Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: size, fontWeight: FontWeight.w800));
}

Widget muted(String text, double size) {
  return Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: CeoColors.muted, fontSize: size, fontWeight: FontWeight.w500));
}

Widget small(String text, {Color color = CeoColors.cyan}) {
  return Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800));
}
