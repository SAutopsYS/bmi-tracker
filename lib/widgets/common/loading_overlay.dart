import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';

/// Dimmed overlay with spinner for blocking async work.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message,
  });

  final bool visible;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.28),
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    label: message ?? 'Loading',
                    child: Material(
                      elevation: 2,
                      borderRadius: AppSpacing.borderRadiusLg,
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.xl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            if (message != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                message!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
