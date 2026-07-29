import 'package:flutter/material.dart';

/// Shared geometry for consistent alignment across role-based modules.
abstract final class AppLayout {
  static const double screenGutter = 16;
  static const double sectionGap = 16;
  static const double itemGap = 12;
  static const double compactGap = 8;
  static const double controlHeight = 48;
  static const double iconTouchTarget = 48;
  static const double cardPadding = 16;
  static const double maxContentWidth = 720;
  static const double actionBreakpoint = 380;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    screenGutter,
    compactGap,
    screenGutter,
    24,
  );

  static const EdgeInsets headerPadding = EdgeInsets.all(compactGap);
}

/// Keeps module content aligned on phones and centred on wider devices.
class AppAlignedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final Future<void> Function()? onRefresh;

  const AppAlignedListView({
    super.key,
    required this.children,
    this.controller,
    this.physics,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget list = ListView(
      controller: controller,
      physics: onRefresh == null
          ? physics
          : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: Padding(
              padding: AppLayout.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
    if (onRefresh != null) {
      list = RefreshIndicator(onRefresh: onRefresh!, child: list);
    }
    return list;
  }
}

/// A responsive row for two or more actions. Narrow phones stack the buttons.
class AppActionRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const AppActionRow({
    super.key,
    required this.children,
    this.gap = AppLayout.itemGap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppLayout.actionBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                SizedBox(width: double.infinity, child: children[index]),
                if (index != children.length - 1) SizedBox(height: gap),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}
