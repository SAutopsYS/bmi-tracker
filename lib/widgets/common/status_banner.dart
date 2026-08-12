import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/firebase_options.dart';

/// Subtle connection / mode banner.
///
/// Distinguishes local demo (Firebase not ready), device offline, and
/// never claims cloud sync when Firebase is not configured.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.isOnline,
    this.pendingSyncCount = 0,
  });

  final bool isOnline;
  final int pendingSyncCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!isFirebaseReady) {
      return _Banner(
        icon: Icons.storage_outlined,
        color: scheme.secondaryContainer,
        onColor: scheme.onSecondaryContainer,
        message: 'Local Demo Mode. Data stays on this device.',
      );
    }

    if (!isOnline) {
      return _Banner(
        icon: Icons.cloud_off_outlined,
        color: scheme.tertiaryContainer,
        onColor: scheme.onTertiaryContainer,
        message: pendingSyncCount > 0
            ? 'Offline mode. $pendingSyncCount change(s) will sync when you reconnect.'
            : 'Offline mode. Showing cached data.',
      );
    }

    if (pendingSyncCount > 0) {
      return _Banner(
        icon: Icons.sync_outlined,
        color: scheme.primaryContainer,
        onColor: scheme.onPrimaryContainer,
        message: 'Syncing $pendingSyncCount pending change(s)...',
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.onColor,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color onColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Material(
        color: color,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, color: onColor, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: onColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
