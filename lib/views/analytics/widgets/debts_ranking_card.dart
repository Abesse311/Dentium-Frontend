import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/analytics_controller.dart';
import '../../../core/theme.dart';
import '../../../models/analytics_models.dart';

class DebtsRankingCard extends StatelessWidget {
  final ReportDebtsModel debts;

  const DebtsRankingCard({super.key, required this.debts});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AnalyticsController>();
    final debtors = debts.debtors;

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suivi des Créances & Débiteurs',
                    style: AppTypography.h3,
                  ),
                  AppSpacing.vGap2,
                  Text(
                    'Classement des patients avec un solde impayé par ordre d\'importance',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: debts.totalOutstandingDebt > 0
                      ? AppColors.dangerLight
                      : AppColors.successLight,
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Text(
                  'Total créances: ${debts.formattedTotalDebt}',
                  style: AppTypography.badgeSmall.copyWith(
                    color: debts.totalOutstandingDebt > 0
                        ? AppColors.danger
                        : AppColors.successDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          AppSpacing.vGap20,

          if (debtors.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: AppRadius.borderRadiusXl,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                  AppSpacing.vGap12,
                  Text(
                    'Aucune créance en cours',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.successDark,
                    ),
                  ),
                  AppSpacing.vGap4,
                  Text(
                    'Tous les patients sont à jour de leurs règlements.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            )
          else ...[
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('#', style: AppTypography.caption),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Patient', style: AppTypography.caption),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Facturé',
                        style: AppTypography.caption,
                        textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Réglé',
                        style: AppTypography.caption,
                        textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Reste Dû',
                        style: AppTypography.caption,
                        textAlign: TextAlign.right),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
            ),

            AppSpacing.vGap8,

            // Debtor Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: debtors.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final debtor = debtors[index];

                return InkWell(
                  onTap: () => controller.navigateToPatient(debtor.patientId),
                  borderRadius: AppRadius.borderRadiusMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: index < 3
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),

                        // Patient Info
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: AppRadius.borderRadiusMd,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  debtor.initials,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              AppSpacing.hGap12,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      debtor.patientName,
                                      style: AppTypography.formLabel.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      debtor.patientPhone ?? 'Sans téléphone',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Total Invoiced
                        Expanded(
                          flex: 2,
                          child: Text(
                            debtor.formattedTotalInvoiced,
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.right,
                          ),
                        ),

                        // Total Paid
                        Expanded(
                          flex: 2,
                          child: Text(
                            debtor.formattedTotalPaid,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.successDark,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),

                        // Total Debt Badge
                        Expanded(
                          flex: 2,
                          child: Container(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.dangerLight,
                                borderRadius: AppRadius.borderRadiusSm,
                                border: Border.all(
                                  color: AppColors.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                debtor.formattedTotalDebt,
                                style: AppTypography.badgeSmall.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        AppSpacing.hGap12,

                        // Action button
                        SizedBox(
                          width: 80,
                          child: OutlinedButton(
                            onPressed: () =>
                                controller.navigateToPatient(debtor.patientId),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              'Dossier',
                              style: AppTypography.badgeSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
