import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Widget? trailing;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.bgColor = AppColors.surface,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderRadiusXxl,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTypography.kpiLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.hGap8,
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecorations.iconBadge(accentColor, radius: AppRadius.xl),
                child: Icon(icon, color: accentColor, size: 22),
              ),
            ],
          ),
          AppSpacing.vGap12,
          Text(
            value,
            style: AppTypography.kpiValue.copyWith(
              color: accentColor == AppColors.primary
                  ? AppColors.textPrimary
                  : accentColor,
            ),
          ),
          if (subtitle != null) ...[
            AppSpacing.vGap6,
            Text(
              subtitle!,
              style: AppTypography.bodySmall,
            ),
          ],
          if (trailing != null) ...[
            AppSpacing.vGap10,
            trailing!,
          ],
        ],
      ),
    );
  }
}






