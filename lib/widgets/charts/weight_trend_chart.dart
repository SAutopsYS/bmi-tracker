import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/utils/date_utils.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:bmi_tracker/models/enums.dart';
import 'package:bmi_tracker/models/weight_history_model.dart';

/// 7-day weight trend line chart with tooltips.
class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({
    super.key,
    required this.history,
    required this.weightUnit,
    this.height = 220,
  });

  final List<WeightHistoryModel> history;
  final WeightUnit weightUnit;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = AppDateUtils.lastNDays(7);
    final byDay = <DateTime, double>{};

    for (final day in days) {
      final matches = history
          .where((e) => AppDateUtils.isSameDay(e.recordedAt, day))
          .toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      if (matches.isNotEmpty) {
        byDay[day] = matches.first.weightKg;
      }
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final kg = byDay[days[i]];
      if (kg != null) {
        final display = UnitConverter.fromKg(kg: kg, toLbs: weightUnit.isLbs);
        spots.add(FlSpot(i.toDouble(), display));
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight trend (7 days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (spots.length < 2)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  spots.isEmpty
                      ? 'Not enough data yet. Log weights on different days to see your trend.'
                      : 'Only one day logged this week. Add another weigh-in to reveal the trend.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                ),
              )
            else
              SizedBox(
                height: height,
                child: Semantics(
                  label: 'Seven day weight trend chart',
                  child: _Chart(
                    days: days,
                    spots: spots,
                    weightUnit: weightUnit,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.days,
    required this.spots,
    required this.weightUnit,
  });

  final List<DateTime> days;
  final List<FlSpot> spots;
  final WeightUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ys = spots.map((s) => s.y).toList();
    final minY = (ys.reduce((a, b) => a < b ? a : b) - 2).clamp(0, 1000);
    final maxY = ys.reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: minY.toDouble(),
        maxY: maxY.toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppDateUtils.formatChartDay(days[i]),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (touched) {
              return touched.map((spot) {
                final i = spot.x.round().clamp(0, days.length - 1);
                return LineTooltipItem(
                  '${AppDateUtils.formatShortDate(days[i])}\n'
                  '${spot.y.toStringAsFixed(1)} ${weightUnit.label}',
                  TextStyle(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: scheme.primary,
                  strokeWidth: 2,
                  strokeColor: scheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
