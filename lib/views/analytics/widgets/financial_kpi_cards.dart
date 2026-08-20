import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/analytics_models.dart';

class FinancialKpiCards extends StatelessWidget {
  final ReportOverviewModel overview;

  const FinancialKpiCards({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final summary = overview.summary;
    final debts = overview.debts;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute responsive card layout
        final isCompact = constraints.maxWidth < 900;
        final cardWidth = isCompact
            ? (constraints.maxWidth - AppSpacing.lg) / 2
            : (constraints.maxWidth - (AppSpacing.lg * 3)) / 4;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            // 1. Chiffre d'Affaires Encaissé
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'REVENUS ENCAISSÉS',
                value: summary.formattedTotalIncome,
                subtitle:
                    '${summary.paymentCount} règlement${summary.paymentCount > 1 ? 's' : ''} perçu${summary.paymentCount > 1 ? 's' : ''}',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: AppColors.success,
                bgColor: AppColors.successLight,
                extraBadge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Text(
                    'Encaissé',
                    style: AppTypography.badgeSmall.copyWith(
                      color: AppColors.successDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Taux de Recouvrement (Gauge / Progress Ring)
            SizedBox(
              width: cardWidth,
              child: _buildCollectionRateCard(summary),
            ),

            // 3. Créances Globales (Debts)
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'CRÉANCES GLOBALES',
                value: debts.formattedTotalDebt,
                subtitle:
                    '${debts.debtorPatientsCount} patient${debts.debtorPatientsCount > 1 ? 's' : ''} débiteur${debts.debtorPatientsCount > 1 ? 's' : ''} (${debts.unpaidInvoicesCount} impayée${debts.unpaidInvoicesCount > 1 ? 's' : ''})',
                icon: Icons.warning_amber_rounded,
                accentColor: debts.totalOutstandingDebt > 0
                    ? AppColors.danger
                    : AppColors.success,
                bgColor: debts.totalOutstandingDebt > 0
                    ? AppColors.dangerLight
                    : AppColors.successLight,
                extraBadge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (debts.totalOutstandingDebt > 0
                            ? AppColors.danger
                            : AppColors.success)
                        .withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Text(
                    debts.totalOutstandingDebt > 0 ? 'Reste à percevoir' : 'À jour',
                    style: AppTypography.badgeSmall.copyWith(
                      color: debts.totalOutstandingDebt > 0
                          ? AppColors.danger
                          : AppColors.successDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // 4. Montant Total Facturé
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'TOTAL FACTURÉ',
                value: summary.formattedTotalInvoiced,
                subtitle:
                    '${summary.invoicesSummary.totalCount} facture${summary.invoicesSummary.totalCount > 1 ? 's' : ''} (${summary.invoicesSummary.paidCount} payée${summary.invoicesSummary.paidCount > 1 ? 's' : ''})',
                icon: Icons.receipt_long_rounded,
                accentColor: AppColors.primary,
                bgColor: AppColors.primaryLight,
                extraBadge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Text(
                    'Facturé',
                    style: AppTypography.badgeSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    Widget? extraBadge,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppRadius.borderRadiusLg,
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              if (extraBadge != null) ...[extraBadge],
            ],
          ),
          AppSpacing.vGap16,
          Text(
            title,
            style: AppTypography.caption.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGap4,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.h1.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          AppSpacing.vGap6,
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionRateCard(ReportSummaryModel summary) {
    final rate = summary.collectionRate.clamp(0.0, 100.0);
    final isGood = rate >= 70.0;
    final isMedium = rate >= 40.0 && rate < 70.0;
    final color = isGood
        ? AppColors.success
        : (isMedium ? AppColors.warning : AppColors.danger);
    final bgColor = isGood
        ? AppColors.successLight
        : (isMedium ? AppColors.warningLight : AppColors.dangerLight);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circular progress gauge
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: rate / 100.0,
                      backgroundColor: AppColors.border,
                      color: color,
                      strokeWidth: 4.5,
                      strokeCap: StrokeCap.round,
                    ),
                    Icon(
                      Icons.percent_rounded,
                      size: 16,
                      color: color,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: Text(
                  isGood ? 'Optimal' : (isMedium ? 'Moyen' : 'Critique'),
                  style: AppTypography.badgeSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGap16,
          Text(
            'TAUX DE RECOUVREMENT',
            style: AppTypography.caption.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGap4,
          Text(
            summary.formattedCollectionRate,
            style: AppTypography.h1.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          AppSpacing.vGap6,
          Text(
            'Recouvrement sur le facturé',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
