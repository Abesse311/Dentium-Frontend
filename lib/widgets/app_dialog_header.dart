import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme.dart';

class AppDialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onClose;

  const AppDialogHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.iconBgColor = AppColors.primaryLight,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: AppRadius.borderRadiusLg,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            AppSpacing.hGap14,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3,
                  ),
                  if (subtitle != null) ...[
                    AppSpacing.vGap2,
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              tooltip: 'Fermer',
              onPressed: onClose ?? () => Navigator.of(context).pop(),
            ),
          ],
        ),
        AppSpacing.vGap20,
        const Divider(),
        AppSpacing.vGap16,
      ],
    );
  }
}






