import 'package:flutter/material.dart';

/// App-wide anchored dropdown menu.
///
/// Unlike Flutter's stock DropdownButton, the menu is anchored below the
/// field instead of centering the selected item over it. This keeps headers
/// and nearby fields visible while long lists scroll inside a bounded panel.
Future<T?> _showAppDropdownMenu<T>({
  required BuildContext context,
  required BuildContext anchorContext,
  required List<DropdownMenuItem<T>> items,
  required T? value,
  required Color? dropdownColor,
  required double? itemHeight,
  required double? menuMaxHeight,
}) {
  final anchor = anchorContext.findRenderObject() as RenderBox;
  final overlay = Navigator.of(context).overlay!.context.findRenderObject()
      as RenderBox;
  final origin = anchor.localToGlobal(
    Offset(0, anchor.size.height + 6),
    ancestor: overlay,
  );
  final rect = Rect.fromLTWH(origin.dx, origin.dy, anchor.size.width, 0);
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  final menuColor = dropdownColor ??
      (dark ? const Color(0xFF00263A) : theme.colorScheme.surface);
  final borderColor = dark
      ? const Color(0xFF075777)
      : theme.colorScheme.outlineVariant;

  return showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
    color: menuColor,
    surfaceTintColor: Colors.transparent,
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: borderColor),
    ),
    constraints: BoxConstraints(
      minWidth: anchor.size.width,
      maxWidth: anchor.size.width,
      maxHeight: menuMaxHeight ?? 320,
    ),
    items: items.map((item) {
      final selected = item.value == value;
      return PopupMenuItem<T>(
        value: item.value,
        enabled: item.enabled,
        height: itemHeight ?? 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                child: item.child,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 10),
              Icon(
                Icons.check_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ],
          ],
        ),
      );
    }).toList(),
  );
}

Widget _selectedChild<T>({
  required BuildContext context,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required List<Widget> Function(BuildContext)? selectedItemBuilder,
  required Widget? hint,
  required Widget? disabledHint,
  required bool enabled,
}) {
  final index = items.indexWhere((item) => item.value == value);
  if (index >= 0) {
    final selectedItems = selectedItemBuilder?.call(context);
    if (selectedItems != null && index < selectedItems.length) {
      return selectedItems[index];
    }
    return items[index].child;
  }
  if (!enabled && disabledHint != null) return disabledHint;
  return hint ?? const SizedBox.shrink();
}

class AppDropdownButton<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final Widget? disabledHint;
  final Widget? icon;
  final TextStyle? style;
  final Color? dropdownColor;
  final double? itemHeight;
  final double? menuMaxHeight;
  final bool isExpanded;
  final bool isDense;
  final AlignmentGeometry alignment;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final VoidCallback? onTap;

  const AppDropdownButton({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.disabledHint,
    this.icon,
    this.style,
    this.dropdownColor,
    this.itemHeight,
    this.menuMaxHeight,
    this.isExpanded = false,
    this.isDense = false,
    this.alignment = AlignmentDirectional.centerStart,
    this.selectedItemBuilder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = items ?? <DropdownMenuItem<T>>[];
    final enabled = onChanged != null && menuItems.isNotEmpty;
    final effectiveStyle = style ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            );
    final selected = _selectedChild<T>(
      context: context,
      value: value,
      items: menuItems,
      selectedItemBuilder: selectedItemBuilder,
      hint: hint,
      disabledHint: disabledHint,
      enabled: enabled,
    );

    return Builder(
      builder: (anchorContext) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: !enabled
            ? null
            : () async {
                onTap?.call();
                final next = await _showAppDropdownMenu<T>(
                  context: context,
                  anchorContext: anchorContext,
                  items: menuItems,
                  value: value,
                  dropdownColor: dropdownColor,
                  itemHeight: itemHeight,
                  menuMaxHeight: menuMaxHeight,
                );
                if (next != null) onChanged?.call(next);
              },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: isDense ? 36 : 44),
          child: Row(
            mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isExpanded)
                Expanded(
                  child: Align(
                    alignment: alignment,
                    child: DefaultTextStyle.merge(
                      style: effectiveStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: selected,
                    ),
                  ),
                )
              else
                Align(
                  alignment: alignment,
                  child: DefaultTextStyle.merge(
                    style: effectiveStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: selected,
                  ),
                ),
              const SizedBox(width: 8),
              icon ??
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDropdownButtonFormField<T> extends StatelessWidget {
  final T? value;
  final T? initialValue;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final Widget? disabledHint;
  final Widget? icon;
  final TextStyle? style;
  final Color? dropdownColor;
  final double? itemHeight;
  final double? menuMaxHeight;
  final bool isExpanded;
  final bool isDense;
  final AlignmentGeometry alignment;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final InputDecoration decoration;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final VoidCallback? onTap;

  const AppDropdownButtonFormField({
    super.key,
    required this.items,
    this.value,
    this.initialValue,
    this.onChanged,
    this.hint,
    this.disabledHint,
    this.icon,
    this.style,
    this.dropdownColor,
    this.itemHeight,
    this.menuMaxHeight,
    this.isExpanded = false,
    this.isDense = false,
    this.alignment = AlignmentDirectional.centerStart,
    this.selectedItemBuilder,
    this.decoration = const InputDecoration(),
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = items ?? <DropdownMenuItem<T>>[];
    final currentValue = value ?? initialValue;
    final effectiveStyle = style ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            );
    return FormField<T>(
      key: ValueKey<Object?>('app-dropdown-$currentValue-${menuItems.length}'),
      initialValue: currentValue,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        final enabled = onChanged != null && menuItems.isNotEmpty;
        final selected = _selectedChild<T>(
          context: context,
          value: currentValue,
          items: menuItems,
          selectedItemBuilder: selectedItemBuilder,
          hint: hint,
          disabledHint: disabledHint,
          enabled: enabled,
        );
        return Builder(
          builder: (anchorContext) => InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: !enabled
                ? null
                : () async {
                    onTap?.call();
                    final next = await _showAppDropdownMenu<T>(
                      context: context,
                      anchorContext: anchorContext,
                      items: menuItems,
                      value: currentValue,
                      dropdownColor: dropdownColor,
                      itemHeight: itemHeight,
                      menuMaxHeight: menuMaxHeight,
                    );
                    if (next != null) {
                      field.didChange(next);
                      onChanged?.call(next);
                    }
                  },
            child: InputDecorator(
              isEmpty: currentValue == null,
              isFocused: false,
              decoration: decoration.copyWith(errorText: field.errorText),
              child: Row(
                mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (isExpanded)
                    Expanded(
                      child: Align(
                        alignment: alignment,
                        child: DefaultTextStyle.merge(
                          style: effectiveStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: selected,
                        ),
                      ),
                    )
                  else
                    Align(
                      alignment: alignment,
                      child: DefaultTextStyle.merge(
                        style: effectiveStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: selected,
                      ),
                    ),
                  const SizedBox(width: 8),
                  icon ??
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
