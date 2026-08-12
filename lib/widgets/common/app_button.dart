import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';

enum AppButtonVariant { filled, outlined, text, tonal }

/// Accessible primary action button with 48dp minimum height.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.foregroundColor,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: foregroundColor ??
                  (variant == AppButtonVariant.filled
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      foregroundColor: foregroundColor != null
          ? WidgetStatePropertyAll(foregroundColor)
          : null,
      backgroundColor: backgroundColor != null
          ? WidgetStatePropertyAll(backgroundColor)
          : null,
    );

    Widget button;
    switch (variant) {
      case AppButtonVariant.filled:
        button = FilledButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        );
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        );
      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        );
    }

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
