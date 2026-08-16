import 'package:flutter/material.dart';
import '../core/constants/status_labels.dart';
import '../theme/app_theme.dart';

enum StatusBadgeType {
  appointment,
  treatment,
  invoice,
  custom,
}

class StatusBadge extends StatelessWidget {
  final String status;
  final StatusBadgeType type;
  final String? customLabel;
  final Color? customColor;
  final Color? customBgColor;

  const StatusBadge({
    super.key,
    required this.status,
    this.type = StatusBadgeType.custom,
    this.customLabel,
    this.customColor,
    this.customBgColor,
  });

  factory StatusBadge.appointment(String status) {
    return StatusBadge(
      status: status,
      type: StatusBadgeType.appointment,
    );
  }

  factory StatusBadge.treatment(String status) {
    return StatusBadge(
      status: status,
      type: StatusBadgeType.treatment,
    );
  }

  factory StatusBadge.invoice(String status) {
    return StatusBadge(
      status: status,
      type: StatusBadgeType.invoice,
    );
  }

  @override
  Widget build(BuildContext context) {
    String label;
    Color textColor;
    Color bgColor;

    switch (type) {
      case StatusBadgeType.appointment:
        label = StatusLabels.appointmentStatus(status);
        textColor = StatusLabels.appointmentStatusColor(status);
        bgColor = StatusLabels.appointmentStatusBgColor(status);
        break;
      case StatusBadgeType.treatment:
        label = StatusLabels.treatmentStatus(status);
        textColor = StatusLabels.treatmentStatusColor(status);
        bgColor = StatusLabels.treatmentStatusBgColor(status);
        break;
      case StatusBadgeType.invoice:
        label = StatusLabels.invoiceStatus(status);
        textColor = StatusLabels.invoiceStatusColor(status);
        bgColor = StatusLabels.invoiceStatusBgColor(status);
        break;
      case StatusBadgeType.custom:
        label = customLabel ?? status;
        textColor = customColor ?? AppColors.textPrimary;
        bgColor = customBgColor ?? AppColors.divider;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDecorations.statusBadge(textColor, bgColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.hGap6,
          Text(
            label,
            style: AppTypography.badgeSmall.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
