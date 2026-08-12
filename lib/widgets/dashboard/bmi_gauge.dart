import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/constants/bmi_thresholds.dart';
import 'package:bmi_tracker/core/theme/app_colors.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';

/// Semi-circular BMI gauge with category color and accessible value.
class BmiGauge extends StatelessWidget {
  const BmiGauge({
    super.key,
    required this.bmi,
    required this.category,
    this.size = 180,
  });

  final double bmi;
  final BMICategory category;
  final double size;

  double get _progress {
    // Map BMI 12..40 onto 0..1 for visual span.
    const minBmi = 12.0;
    const maxBmi = 40.0;
    final clamped = bmi.clamp(minBmi, maxBmi);
    return (clamped - minBmi) / (maxBmi - minBmi);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.colorForCategory(category);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'BMI ${bmi.toStringAsFixed(1)}, category ${category.label}',
      child: SizedBox(
        width: size,
        height: size * 0.62,
        child: CustomPaint(
          painter: _BmiGaugePainter(
            progress: _progress,
            activeColor: color,
            trackColor: scheme.outline.withValues(alpha: 0.18),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bmi.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppColors.iconForCategory(category),
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BmiGaugePainter extends CustomPainter {
  _BmiGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      (size.width - stroke),
    );
    const start = math.pi;
    const sweep = math.pi;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final active = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweep, false, track);
    canvas.drawArc(rect, start, sweep * progress.clamp(0, 1), false, active);
  }

  @override
  bool shouldRepaint(covariant _BmiGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
