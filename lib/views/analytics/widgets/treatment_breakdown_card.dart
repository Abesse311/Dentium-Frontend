import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/analytics_models.dart';

class TreatmentBreakdownCard extends StatefulWidget {
  final ReportTreatmentsModel treatments;

  const TreatmentBreakdownCard({super.key, required this.treatments});

  @override
  State<TreatmentBreakdownCard> createState() => _TreatmentBreakdownCardState();
}

class _TreatmentBreakdownCardState extends State<TreatmentBreakdownCard> {
  int _touchedIndex = -1;

  static const List<Color> _palette = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
    Color(0xFF84CC16), // Lime
  ];

  @override
  Widget build(BuildContext context) {
    final items = widget.treatments.items;

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
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenus par Type de Traitement',
                    style: AppTypography.h3,
                  ),
                  AppSpacing.vGap2,
                  Text(
                    'Contribution de chaque acte au chiffre d\'affaires total',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Text(
                  'Total: ${widget.treatments.formattedTotalRevenue}',
                  style: AppTypography.badgeSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          AppSpacing.vGap24,

          if (items.isEmpty)
            Container(
              height: 220,
              alignment: Alignment.center,
              child: Text(
                'Aucun acte facturé pour cette période.',
                style: AppTypography.bodyMedium,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;

                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Donut Chart
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: PieChart(
                              _buildPieChartData(items),
                              duration: const Duration(milliseconds: 300),
                            ),
                          ),

                          AppSpacing.hGap32,

                          // Ranked List with Progress Bars
                          Expanded(
                            child: _buildRankedList(items),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              _buildPieChartData(items),
                              duration: const Duration(milliseconds: 300),
                            ),
                          ),
                          AppSpacing.vGap20,
                          _buildRankedList(items),
                        ],
                      );
              },
            ),
        ],
      ),
    );
  }

  PieChartData _buildPieChartData(List<TreatmentRevenueItemModel> items) {
    return PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (event, pieTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              _touchedIndex = -1;
              return;
            }
            _touchedIndex =
                pieTouchResponse.touchedSection!.touchedSectionIndex;
          });
        },
      ),
      borderData: FlBorderData(show: false),
      sectionsSpace: 3,
      centerSpaceRadius: 52,
      sections: List.generate(items.length, (i) {
        final item = items[i];
        final isTouched = i == _touchedIndex;
        final color = _palette[i % _palette.length];
        final radius = isTouched ? 48.0 : 40.0;

        return PieChartSectionData(
          color: color,
          value: item.totalAmount > 0 ? item.totalAmount : 1,
          title: item.percentage >= 8.0 ? '${item.percentage.toInt()}%' : '',
          radius: radius,
          titleStyle: AppTypography.badgeSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isTouched ? 12 : 10,
          ),
        );
      }),
    );
  }

  Widget _buildRankedList(List<TreatmentRevenueItemModel> items) {
    // Show top 6 treatments
    final displayItems = items.take(6).toList();

    return Column(
      children: displayItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final color = _palette[index % _palette.length];
        final isTouched = index == _touchedIndex;

        return MouseRegion(
          onEnter: (_) => setState(() => _touchedIndex = index),
          onExit: (_) => setState(() => _touchedIndex = -1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: isTouched
                  ? color.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.hGap10,
                    Expanded(
                      child: Text(
                        item.treatmentTypeName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight:
                              isTouched ? FontWeight.bold : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.hGap8,
                    Text(
                      '${item.itemsCount} acte${item.itemsCount > 1 ? 's' : ''}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    AppSpacing.hGap14,
                    Text(
                      item.formattedTotalAmount,
                      style: AppTypography.formLabel.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.hGap10,
                    SizedBox(
                      width: 48,
                      child: Text(
                        item.formattedPercentage,
                        textAlign: TextAlign.right,
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGap4,
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (item.percentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
