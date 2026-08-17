import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme.dart';

class MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.bgColor = AppColors.surface,
    this.trailing,
    this.onTap,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;

    return MouseRegion(
      cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (isInteractive) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isInteractive) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: AppRadius.borderRadiusXxl,
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : AppColors.border,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    const BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ]
                : AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title.toUpperCase(),
                            style: AppTypography.kpiLabel.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isInteractive) ...[
                          AppSpacing.hGap6,
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: _isHovered ? widget.accentColor : AppColors.textMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.hGap8,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderRadiusXl,
                    ),
                    child: Icon(widget.icon, color: widget.accentColor, size: 22),
                  ),
                ],
              ),
              AppSpacing.vGap12,
              Text(
                widget.value,
                style: AppTypography.kpiValue.copyWith(
                  color: widget.accentColor == AppColors.primary
                      ? AppColors.textPrimary
                      : widget.accentColor,
                ),
              ),
              if (widget.subtitle != null) ...[
                AppSpacing.vGap6,
                Text(
                  widget.subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (widget.trailing != null) ...[
                AppSpacing.vGap10,
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
