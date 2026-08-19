import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/treatments_controller.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'tooth_widget.dart';

class OdontogramWidget extends StatelessWidget {
  const OdontogramWidget({super.key});

  static const List<int> upperRight = [18, 17, 16, 15, 14, 13, 12, 11];
  static const List<int> upperLeft = [21, 22, 23, 24, 25, 26, 27, 28];
  static const List<int> lowerRight = [48, 47, 46, 45, 44, 43, 42, 41];
  static const List<int> lowerLeft = [31, 32, 33, 34, 35, 36, 37, 38];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TreatmentsController>();

    return Container(
      padding: AppSpacing.screenPadding,
      decoration: AppDecorations.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mode Switch Bar & Top Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildArchLabel('DROITE (Patient)'),

              // Mode Toggle Button (Single vs Multi-Selection)
              Obx(() {
                final isMulti = controller.isMultiSelectMode.value;
                final count = controller.selectedToothNumbers.length;

                return InkWell(
                  onTap: () => controller.toggleMultiSelectMode(),
                  borderRadius: AppRadius.borderRadiusFull,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isMulti ? AppColors.primary : AppColors.background,
                      borderRadius: AppRadius.borderRadiusFull,
                      border: Border.all(
                        color: isMulti ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                      boxShadow: isMulti
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMulti ? Icons.checklist_rtl_rounded : Icons.touch_app_rounded,
                          size: 16,
                          color: isMulti ? Colors.white : AppColors.textSecondary,
                        ),
                        AppSpacing.hGap8,
                        Text(
                          isMulti
                              ? 'Mode Multi-Dents ($count sélectionnée${count > 1 ? 's' : ''})'
                              : 'Mode Multi-Dents',
                          style: AppTypography.badgeSmall.copyWith(
                            color: isMulti ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.hGap6,
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isMulti ? AppColors.success : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              _buildArchLabel('GAUCHE (Patient)'),
            ],
          ),

          // Quick Selection Shortcuts Banner (visible in multi-select mode)
          Obx(() {
            if (!controller.isMultiSelectMode.value) {
              return const SizedBox(height: AppSpacing.md);
            }

            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius: AppRadius.borderRadiusLg,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 16, color: AppColors.primary),
                    AppSpacing.hGap6,
                    Text(
                      'Sélection rapide :',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    AppSpacing.hGap8,
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickChip(
                              label: 'Maxillaire (Haut)',
                              isSelected: controller.isUpperArchSelected(),
                              onTap: () => controller.toggleUpperArch(),
                            ),
                            AppSpacing.hGap6,
                            _buildQuickChip(
                              label: 'Mandibule (Bas)',
                              isSelected: controller.isLowerArchSelected(),
                              onTap: () => controller.toggleLowerArch(),
                            ),
                            AppSpacing.hGap6,
                            _buildQuickChip(
                              label: 'Sagesses',
                              isSelected: controller.isWisdomTeethSelected(),
                              onTap: () => controller.toggleWisdomTeeth(),
                            ),
                            AppSpacing.hGap6,
                            _buildQuickChip(
                              label: 'Q1 (H.D)',
                              isSelected: controller.isQuadrantSelected(1),
                              onTap: () => controller.toggleQuadrant(1),
                            ),
                            AppSpacing.hGap4,
                            _buildQuickChip(
                              label: 'Q2 (H.G)',
                              isSelected: controller.isQuadrantSelected(2),
                              onTap: () => controller.toggleQuadrant(2),
                            ),
                            AppSpacing.hGap4,
                            _buildQuickChip(
                              label: 'Q3 (B.G)',
                              isSelected: controller.isQuadrantSelected(3),
                              onTap: () => controller.toggleQuadrant(3),
                            ),
                            AppSpacing.hGap4,
                            _buildQuickChip(
                              label: 'Q4 (B.D)',
                              isSelected: controller.isQuadrantSelected(4),
                              onTap: () => controller.toggleQuadrant(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          AppSpacing.vGap12,

          // Upper Arch Title
          Text(
            'MAXILLAIRE (HAUT)',
            style: AppTypography.kpiLabel.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.0,
            ),
          ),

          AppSpacing.vGap10,

          // Upper Arch (Maxillaire: Q1 & Q2)
          Obx(() {
            final statusMap = controller.toothStatusMap;
            final isMulti = controller.isMultiSelectMode.value;
            final singleSelected = controller.selectedToothNumber.value;
            final multiSelectedSet = controller.selectedToothNumbers;

            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Quadrant 1 (18..11)
                  Row(
                    children: upperRight.map((t) {
                      final isSelected = isMulti
                          ? multiSelectedSet.contains(t)
                          : singleSelected == t;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ToothWidget(
                          toothNumber: t,
                          status: statusMap[t] ?? 'healthy',
                          isSelected: isSelected,
                          isUpperArch: true,
                          onTap: () => controller.selectTooth(t),
                        ),
                      );
                    }).toList(),
                  ),

                  // Midline Separator
                  Container(
                    width: 2,
                    height: 90,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),

                  // Quadrant 2 (21..28)
                  Row(
                    children: upperLeft.map((t) {
                      final isSelected = isMulti
                          ? multiSelectedSet.contains(t)
                          : singleSelected == t;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ToothWidget(
                          toothNumber: t,
                          status: statusMap[t] ?? 'healthy',
                          isSelected: isSelected,
                          isUpperArch: true,
                          onTap: () => controller.selectTooth(t),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),

          AppSpacing.vGap12,

          // Occlusal Horizontal Midline
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1.5,
                  color: AppColors.border,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                decoration: AppDecorations.panelBg,
                child: Text(
                  'Ligne d\'occlusion',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1.5,
                  color: AppColors.border,
                ),
              ),
            ],
          ),

          AppSpacing.vGap12,

          // Lower Arch (Mandibule: Q4 & Q3)
          Obx(() {
            final statusMap = controller.toothStatusMap;
            final isMulti = controller.isMultiSelectMode.value;
            final singleSelected = controller.selectedToothNumber.value;
            final multiSelectedSet = controller.selectedToothNumbers;

            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Quadrant 4 (48..41)
                  Row(
                    children: lowerRight.map((t) {
                      final isSelected = isMulti
                          ? multiSelectedSet.contains(t)
                          : singleSelected == t;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ToothWidget(
                          toothNumber: t,
                          status: statusMap[t] ?? 'healthy',
                          isSelected: isSelected,
                          isUpperArch: false,
                          onTap: () => controller.selectTooth(t),
                        ),
                      );
                    }).toList(),
                  ),

                  // Midline Separator
                  Container(
                    width: 2,
                    height: 90,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),

                  // Quadrant 3 (31..38)
                  Row(
                    children: lowerLeft.map((t) {
                      final isSelected = isMulti
                          ? multiSelectedSet.contains(t)
                          : singleSelected == t;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ToothWidget(
                          toothNumber: t,
                          status: statusMap[t] ?? 'healthy',
                          isSelected: isSelected,
                          isUpperArch: false,
                          onTap: () => controller.selectTooth(t),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),

          AppSpacing.vGap14,

          // Footer Label (Mandibule)
          Text(
            'MANDIBULE (BAS)',
            style: AppTypography.kpiLabel.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.0,
            ),
          ),

          AppSpacing.vGap18,
          const Divider(),
          AppSpacing.vGap12,

          // Legend Bar
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderRadiusSm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.borderRadiusSm,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDecorations.panelBg,
      child: Text(
        text,
        style: AppTypography.badgeSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.sm,
      children: [
        _buildLegendItem(Colors.white, AppColors.border, 'Sain / Neutre'),
        _buildLegendItem(AppColors.infoLight, AppColors.info, 'Planifié'),
        _buildLegendItem(AppColors.warningLight, AppColors.warning, 'En cours'),
        _buildLegendItem(AppColors.successLight, AppColors.success, 'Réalisé'),
      ],
    );
  }

  Widget _buildLegendItem(Color fill, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.borderRadiusSm,
            border: Border.all(color: border, width: 1.5),
          ),
        ),
        AppSpacing.hGap6,
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
