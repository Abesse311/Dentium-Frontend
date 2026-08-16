import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.massive),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Icon(
                icon,
                color: AppColors.textMuted,
                size: 40,
              ),
            ),
            AppSpacing.vGap16,
            Text(
              title,
              style: AppTypography.h4,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.vGap6,
              Text(
                message!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              AppSpacing.vGap18,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}






