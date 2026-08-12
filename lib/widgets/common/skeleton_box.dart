import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';

/// Shimmer-like skeleton placeholder for loading states.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusMd,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: [
                base.withValues(alpha: 0.55),
                base.withValues(alpha: 0.9),
                base.withValues(alpha: 0.55),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Stack of skeleton rows for dashboard loading.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 180, height: 28),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: 160, borderRadius: AppSpacing.radiusLg),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 88)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 88)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 88)),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: 200, borderRadius: AppSpacing.radiusLg),
        ],
      ),
    );
  }
}
