import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/analytics_controller.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';

class PeriodSelectorBar extends StatelessWidget {
  const PeriodSelectorBar({super.key});

  Future<void> _pickCustomDateRange(
      BuildContext context, AnalyticsController controller) async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: controller.customStartDate.value ??
          DateTime(now.year, now.month, 1),
      end: controller.customEndDate.value ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AnalyticsController>();

    final periods = [
      {'key': 'today', 'label': "Aujourd'hui"},
      {'key': 'this_week', 'label': 'Cette semaine'},
      {'key': 'this_month', 'label': 'Ce mois'},
      {'key': 'this_year', 'label': 'Cette année'},
      {'key': 'custom', 'label': 'Période personnalisée'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // --- Period Segmented Tabs ---
          Obx(() {
            final activeKey = controller.selectedPeriod.value;

            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: periods.map((p) {
                final isSelected = activeKey == p['key'];
                final isCustom = p['key'] == 'custom';

                return InkWell(
                  onTap: () {
                    if (isCustom) {
                      _pickCustomDateRange(context, controller);
                    } else {
                      controller.setPeriod(p['key']!);
                    }
                  },
                  borderRadius: AppRadius.borderRadiusLg,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: AppRadius.borderRadiusLg,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCustom) ...[
                          Icon(
                            Icons.date_range_rounded,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          AppSpacing.hGap6,
                        ],
                        Text(
                          isCustom &&
                                  isSelected &&
                                  controller.customStartDate.value != null &&
                                  controller.customEndDate.value != null
                              ? '${DateFormatter.formatShort(controller.customStartDate.value!)} - ${DateFormatter.formatShort(controller.customEndDate.value!)}'
                              : p['label']!,
                          style: AppTypography.buttonSmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),

          // --- Right Actions (Granularity & Refresh) ---
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Granularity Switcher
              Obx(() {
                final currentG = controller.granularity.value;
                return Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.borderRadiusMd,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGranularityBtn(
                        label: 'Quotidien',
                        isActive: currentG == 'daily',
                        onTap: () => controller.setGranularity('daily'),
                      ),
                      _buildGranularityBtn(
                        label: 'Mensuel',
                        isActive: currentG == 'monthly',
                        onTap: () => controller.setGranularity('monthly'),
                      ),
                    ],
                  ),
                );
              }),

              AppSpacing.hGap12,

              // Refresh Button
              Obx(() {
                final loading = controller.isLoading.value;
                return IconButton(
                  onPressed: loading ? null : () => controller.fetchAnalytics(),
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Actualiser les données',
                  color: AppColors.primary,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGranularityBtn({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderRadiusSm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.borderRadiusSm,
        ),
        child: Text(
          label,
          style: AppTypography.badgeSmall.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
