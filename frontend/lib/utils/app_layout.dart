import 'package:flutter/widgets.dart';

/// Shared geometry for consistent alignment across role-based modules.
abstract final class AppLayout {
  static const double screenGutter = 16;
  static const double sectionGap = 16;
  static const double itemGap = 12;
  static const double compactGap = 8;
  static const double controlHeight = 48;
  static const double iconTouchTarget = 48;
  static const double cardPadding = 16;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    screenGutter,
    compactGap,
    screenGutter,
    24,
  );

  static const EdgeInsets headerPadding = EdgeInsets.all(compactGap);
}
