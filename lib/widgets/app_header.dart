import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/connectivity_controller.dart';
import '../controllers/navigation_controller.dart';
import '../core/utils/date_formatter.dart';
import 'package:flutter_application_1/core/theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<NavigationController>();
    final connController = Get.find<ConnectivityController>();

    final todayStr = DateFormatter.formatFull(DateTime.now());

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(color: AppColors.border, width: 1),
            ),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
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
                            boxShadow: isConnected
                                ? [
                                    BoxShadow(
                                      color: AppColors.success.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      AppSpacing.hGap8,
                      Text(
                        isConnected ? 'Serveur actif' : 'Serveur déconnecté',
                        style: AppTypography.badgeSmall.copyWith(
                          color: isConnected ? AppColors.successDark : AppColors.dangerDark,
                          fontWeight: FontWeight.bold,
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
