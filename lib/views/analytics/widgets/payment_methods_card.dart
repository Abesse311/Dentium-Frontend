import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/analytics_models.dart';

class PaymentMethodsCard extends StatelessWidget {
  final ByPaymentMethodModel methods;

  const PaymentMethodsCard({super.key, required this.methods});

  @override
  Widget build(BuildContext context) {
    final total = methods.total > 0 ? methods.total : 1.0;

    final cashPct = (methods.cash / total) * 100;
    final cardPct = (methods.card / total) * 100;
    final transferPct = (methods.transfer / total) * 100;
    final otherPct = (methods.other / total) * 100;

    final items = [
      {
        'label': 'Espèces',
        'amount': methods.cash,
        'pct': cashPct,
        'color': const Color(0xFF10B981), // Emerald
        'icon': Icons.payments_rounded,
      },
      {
        'label': 'Carte Bancaire',
        'amount': methods.card,
        'pct': cardPct,
        'color': const Color(0xFF3B82F6), // Blue
        'icon': Icons.credit_card_rounded,
      },
      {
        'label': 'Virement',
        'amount': methods.transfer,
        'pct': transferPct,
        'color': const Color(0xFF8B5CF6), // Purple
        'icon': Icons.account_balance_rounded,
      },
      {
        'label': 'Autre',
        'amount': methods.other,
        'pct': otherPct,
        'color': const Color(0xFF6B7280), // Gray
        'icon': Icons.more_horiz_rounded,
      },
    ];

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
          Text(
            'Modes de Paiement Utilisés',
            style: AppTypography.h3,
          ),
          AppSpacing.vGap2,
          Text(
            'Répartition des encaissements par canal de règlement',
            style: AppTypography.bodySmall,
          ),
          AppSpacing.vGap20,

          // Multi-color stacked distribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: items.map((it) {
                  final pct = (it['pct'] as double).clamp(0.0, 100.0);
                  if (pct <= 0) return const SizedBox.shrink();
                  return Expanded(
                    flex: (pct * 10).toInt().clamp(1, 1000),
                    child: Container(color: it['color'] as Color),
                  );
                }).toList(),
              ),
            ),
          ),

          AppSpacing.vGap20,

          // Tiles Grid
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: items.map((it) {
              final color = it['color'] as Color;
              final amount = it['amount'] as double;
              final pct = it['pct'] as double;

              return Container(
                width: 170,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.borderRadiusLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderRadiusMd,
                      ),
                      child: Icon(it['icon'] as IconData,
                          color: color, size: 18),
                    ),
                    AppSpacing.hGap10,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it['label'] as String,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppSpacing.vGap2,
                          Text(
                            DateFormatter.formatCurrency(amount),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: AppTypography.caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
