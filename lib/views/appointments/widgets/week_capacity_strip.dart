import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/appointments_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/models/day_capacity_model.dart';
import 'package:flutter_application_1/core/theme.dart';

class WeekCapacityStrip extends StatelessWidget {
  const WeekCapacityStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppointmentsController>();

    return Obx(() {
      final weekStart = controller.weekStartDate.value;
      final selected = controller.selectedDate.value;
      final capacityList = controller.weekCapacity;

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
        decoration: AppDecorations.panel,
        child: Row(
          children: List.generate(7, (index) {
            final dayDate = weekStart.add(Duration(days: index));
            final dateStr = DateFormatter.toApiString(dayDate);
            final isSelected = dayDate.year == selected.year &&
                dayDate.month == selected.month &&
                dayDate.day == selected.day;
            final isToday = dayDate.year == DateTime.now().year &&
                dayDate.month == DateTime.now().month &&
                dayDate.day == DateTime.now().day;

            final capacity = capacityList.firstWhereOrNull(
                  (c) => c.date == dateStr,
                ) ??
                DayCapacityModel(date: dateStr, bookedCount: 0, limit: 30);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 6 ? AppSpacing.xl : 0),
                child: _DayCapacityCard(
                  date: dayDate,
                  capacity: capacity,
                  isSelected: isSelected,
                  isToday: isToday,
                  onTap: () => controller.selectDate(dayDate),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}

class _DayCapacityCard extends StatefulWidget {
  final DateTime date;
  final DayCapacityModel capacity;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCapacityCard({
    required this.date,
    required this.capacity,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  State<_DayCapacityCard> createState() => _DayCapacityCardState();
}

class _DayCapacityCardState extends State<_DayCapacityCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cap = widget.capacity;
    final color = cap.capacityColor;
    final bgColor = widget.isSelected
        ? AppColors.primaryLight
        : _isHovered
            ? AppColors.background
            : Colors.transparent;

    final borderColor = widget.isSelected
        ? AppColors.primary
        : widget.isToday
            ? AppColors.accent
            : AppColors.border;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.borderRadiusXl,
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || widget.isToday ? 2 : 1,
            ),
            boxShadow: widget.isSelected ? AppShadows.primaryGlow : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day name (LUN, MAR...)
              Text(
                DateFormatter.formatShortDayOfWeek(widget.date),
                style: AppTypography.kpiLabel.copyWith(
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              AppSpacing.vGap4,

              // Day Number (16, 17...)
              Text(
                '${widget.date.day}',
                style: AppTypography.h2.copyWith(
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              AppSpacing.vGap8,

              // Capacity Pill with color-coding
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: cap.capacityBgColor,
                  borderRadius: AppRadius.borderRadiusXl,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.hGap4,
                    Text(
                      '${cap.bookedCount}/${cap.limit}',
                      style: AppTypography.badgeSmall.copyWith(color: color),
                    ),
                  ],
                ),
              ),

              AppSpacing.vGap8,

              // Mini Progress Bar
              ClipRRect(
                borderRadius: AppRadius.borderRadiusXs,
                child: LinearProgressIndicator(
                  value: cap.fillRatio.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              if (widget.isToday) ...[
                AppSpacing.vGap6,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadius.borderRadiusXs,
                  ),
                  child: Text(
                    "AUJ.",
                    style: AppTypography.badgeSmall.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}







