import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/analytics_models.dart';

class IncomeTrendChartCard extends StatelessWidget {
  final ReportTrendModel trend;

  const IncomeTrendChartCard({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    final points = trend.points;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Évolution des Revenus & Facturation',
                    style: AppTypography.h3,
                  ),
                  AppSpacing.vGap2,
                  Text(
                    'Suivi chronologique des encaissements et des montants facturés',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),

              // Legend items
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendPill(
                    color: AppColors.success,
                    label: 'Encaissé',
                    isLine: true,
                  ),
                  AppSpacing.hGap16,
                  _buildLegendPill(
                    color: AppColors.primary,
                    label: 'Facturé',
                    isLine: false,
                  ),
                ],
              ),
            ],
          ),

          AppSpacing.vGap28,

          // Chart Canvas
          if (points.isEmpty)
            Container(
              height: 280,
              alignment: Alignment.center,
              child: Text(
                'Aucune donnée disponible pour cette période.',
                style: AppTypography.bodyMedium,
              ),
            )
          else
            SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.only(right: 18, left: 6, top: 12),
                child: LineChart(
                  _buildChartData(points),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<TrendPointModel> points) {
    final double maxY = trend.maxIncome * 1.15;

    final incomeSpots = <FlSpot>[];
    final invoicedSpots = <FlSpot>[];

    for (int i = 0; i < points.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), points[i].income));
      invoicedSpots.add(FlSpot(i.toDouble(), points[i].invoiced));
    }

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble().clamp(0.0, double.infinity),
      minY: 0,
      maxY: maxY > 0 ? maxY : 1000.0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? (maxY / 4) : 250,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.border.withValues(alpha: 0.7),
            strokeWidth: 1,
            dashArray: [4, 4],
          );
        },
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 64,
            interval: maxY > 0 ? (maxY / 4) : 250,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox.shrink();
              String text;
              if (value >= 1000000) {
                text = '${(value / 1000000).toStringAsFixed(1)}M DA';
              } else if (value >= 1000) {
                text = '${(value / 1000).toInt()}k DA';
              } else {
                text = '${value.toInt()} DA';
              }
              return Text(
                text,
                style: AppTypography.badgeSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _calculateBottomInterval(points.length),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  points[index].label,
                  style: AppTypography.badgeSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isIncome = spot.barIndex == 0;
              final label = isIncome ? 'Encaissé' : 'Facturé';
              final color = isIncome ? AppColors.success : AppColors.primary;
              final pointIndex = spot.x.toInt();
              final pointDate = (pointIndex >= 0 && pointIndex < points.length)
                  ? points[pointIndex].date
                  : '';

              return LineTooltipItem(
                '$label: ${DateFormatter.formatCurrency(spot.y)}\n$pointDate',
                AppTypography.badgeSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        // 1. Income Curve (Green)
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppColors.success,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: points.length <= 15,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: AppColors.success,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.success.withValues(alpha: 0.25),
                AppColors.success.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 2. Invoiced Curve (Primary Blue, dashed)
        LineChartBarData(
          spots: invoicedSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppColors.primary.withValues(alpha: 0.8),
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [5, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  double _calculateBottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 15) return 2;
    if (count <= 31) return 4;
    return (count / 6).ceilToDouble();
  }

  Widget _buildLegendPill({
    required Color color,
    required String label,
    required bool isLine,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLine ? 16 : 10,
          height: isLine ? 3.5 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        AppSpacing.hGap6,
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
