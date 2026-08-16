import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme.dart';

/// Shows a CalendarDatePicker2 dialog matching the project theme.
/// Returns the selected [DateTime], or null if cancelled.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
}) async {
  final now = DateTime.now();
  final first = firstDate ?? DateTime(1900);
  final last = lastDate ?? now.add(const Duration(days: 3650));

  DateTime? result = initialDate;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusXxl),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: AppDecorations.iconBadge(
                      AppColors.primary,
                      radius: AppRadius.md,
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  AppSpacing.hGap12,
                  Expanded(
                    child: Text(
                      helpText ?? 'Sélectionner une date',
                      style: AppTypography.h4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textMuted,
                    onPressed: () {
                      result = null;
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),

              AppSpacing.vGap16,

              // Calendar picker
              CalendarDatePicker2(
                config: CalendarDatePicker2Config(
                  calendarType: CalendarDatePicker2Type.single,
                  firstDate: first,
                  lastDate: last,
                  selectedDayHighlightColor: AppColors.primary,
                  weekdayLabels: const [
                    'Dim',
                    'Lun',
                    'Mar',
                    'Mer',
                    'Jeu',
                    'Ven',
                    'Sam',
                  ],
                  weekdayLabelTextStyle: AppTypography.kpiLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  controlsTextStyle: AppTypography.h4,
                  dayTextStyle: AppTypography.bodyMedium,
                  selectedDayTextStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  todayTextStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  disabledDayTextStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                value: [initialDate],
                onValueChanged: (dates) {
                  if (dates.isNotEmpty) {
                    result = dates.first;
                  }
                },
              ),

              AppSpacing.vGap8,
              const Divider(),
              AppSpacing.vGap8,

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      result = null;
                      Navigator.of(ctx).pop();
                    },
                    child: Text('Annuler', style: AppTypography.button),
                  ),
                  AppSpacing.hGap12,
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Confirmer', style: AppTypography.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result;
}
