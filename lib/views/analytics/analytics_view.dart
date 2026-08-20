import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/analytics_controller.dart';
import '../../core/theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import 'widgets/debts_ranking_card.dart';
import 'widgets/financial_kpi_cards.dart';
import 'widgets/income_trend_chart_card.dart';
import 'widgets/payment_methods_card.dart';
import 'widgets/period_selector_bar.dart';
import 'widgets/treatment_breakdown_card.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AnalyticsController>();
    final todayStr = DateFormatter.formatFull(DateTime.now());

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: () => controller.fetchAnalytics(),
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Page Header ---
              Wrap(
                spacing: AppSpacing.xxl,
                runSpacing: AppSpacing.md,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Analyses & Revenus',
                        style: AppTypography.h1,
                      ),
                      AppSpacing.vGap4,
                      Text(
                        'Indicateurs financiers, tendances de chiffre d\'affaires et suivi des créances au $todayStr',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),

                  // Quick Export / Print Info Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.borderRadiusLg,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        AppSpacing.hGap8,
                        Text(
                          'Rapports Financiers en Temps Réel',
                          style: AppTypography.badgeSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              AppSpacing.vGap24,

              // --- 2. Period Filter Selector Bar ---
              const PeriodSelectorBar(),

              AppSpacing.vGap24,

              // --- 3. Reactive Content Area ---
              Obx(() {
                if (controller.isLoading.value &&
                    controller.overview.value == null) {
                  return Container(
                    height: 400,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des analyses financières...'),
                      ],
                    ),
                  );
                }

                if (controller.errorMessage.isNotEmpty &&
                    controller.overview.value == null) {
                  return EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Impossible de charger les analyses',
                    message: controller.errorMessage.value,
                    action: ElevatedButton.icon(
                      onPressed: () => controller.fetchAnalytics(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text('Réessayer', style: AppTypography.button),
                    ),
                  );
                }

                final overview = controller.overview.value;
                if (overview == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards Row
                    FinancialKpiCards(overview: overview),

                    AppSpacing.vGap24,

                    // Income Evolution Chart
                    IncomeTrendChartCard(trend: overview.trend),

                    AppSpacing.vGap24,

                    // Two-Column Grid: Treatment Breakdown & Payment Methods
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 950;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Treatment Revenue Breakdown
                              Expanded(
                                flex: 6,
                                child: TreatmentBreakdownCard(
                                  treatments: overview.treatments,
                                ),
                              ),
                              AppSpacing.hGap24,
                              // Right: Payment Methods
                              Expanded(
                                flex: 4,
                                child: PaymentMethodsCard(
                                  methods: overview.summary.byPaymentMethod,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              TreatmentBreakdownCard(
                                treatments: overview.treatments,
                              ),
                              AppSpacing.vGap24,
                              PaymentMethodsCard(
                                methods: overview.summary.byPaymentMethod,
                              ),
                            ],
                          );
                        }
                      },
                    ),

                    AppSpacing.vGap24,

                    // Debts & Debtor Ranking
                    DebtsRankingCard(debts: overview.debts),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
