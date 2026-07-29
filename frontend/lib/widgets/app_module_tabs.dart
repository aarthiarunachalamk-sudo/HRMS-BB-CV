import 'package:flutter/material.dart';

import '../Screens/StartUp-Screens/theme_config.dart';

/// The single visual treatment for in-page module/status tabs.
class AppModuleTabs<T> extends StatelessWidget {
  final List<AppModuleTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  const AppModuleTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final border = ThemeConfig.getCardBorder(context);
    final muted = ThemeConfig.getTextSecondary(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ThemeConfig.getCardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: tabs.map((tab) {
          final active = tab.value == selected;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: tab == tabs.last ? 0 : 4),
              child: InkWell(
                onTap: () => onSelected(tab.value),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: active ? ThemeConfig.blueGradient : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? Colors.white : muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AppModuleTab<T> {
  final T value;
  final String label;

  const AppModuleTab(this.value, this.label);
}
