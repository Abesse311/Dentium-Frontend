import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/connectivity_controller.dart';
import '../controllers/navigation_controller.dart';
import '../core/utils/date_formatter.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<NavigationController>();
    final connController = Get.find<ConnectivityController>();

    final todayStr = DateFormatter.formatFull(DateTime.now());

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // If sidebar is collapsed, show expand button
          Obx(() {
            if (!navController.isSidebarExpanded.value) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                  tooltip: 'Déplier le menu',
                  onPressed: navController.toggleSidebar,
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // --- Active Screen Title ---
          Expanded(
            child: Obx(() {
              return Text(
                navController.currentTitle,
                style: AppTypography.h2,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }),
          ),

          AppSpacing.hGap16,

          // --- Current Date Chip ---
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: AppDecorations.panelBg,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    AppSpacing.hGap8,
                    Text(
                      todayStr,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          AppSpacing.hGap12,

          // --- Backend Connection Health Indicator ---
          Obx(() {
            final isConnected = connController.isConnected.value;
            final isChecking = connController.isChecking.value;

            return Tooltip(
              message: isConnected
                  ? 'FastAPI Backend actif sur 127.0.0.1:8000'
                  : 'Backend injoignable sur 127.0.0.1:8000. Cliquez pour réessayer.',
              child: InkWell(
                borderRadius: AppRadius.borderRadiusLg,
                onTap: () => connController.checkConnection(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected ? AppColors.successLight : AppColors.dangerLight,
                    borderRadius: AppRadius.borderRadiusLg,
                    border: Border.all(
                      color: isConnected
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.danger.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isChecking)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected ? AppColors.success : AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      AppSpacing.hGap8,
                      Text(
                        isConnected ? 'Serveur actif' : 'Serveur déconnecté',
                        style: AppTypography.badgeSmall.copyWith(
                          color: isConnected ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      if (!isConnected) ...[
                        AppSpacing.hGap6,
                        const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.danger,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
