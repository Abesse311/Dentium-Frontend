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
          // Header Labels (Droite / Gauche)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildArchLabel('DROITE (Patient)'),
              Text(
                'MAXILLAIRE (HAUT)',
                style: AppTypography.kpiLabel.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              _buildArchLabel('GAUCHE (Patient)'),
            ],
          ),

          AppSpacing.vGap14,

          // Upper Arch (Maxillaire: Q1 & Q2)
          Obx(() {
            final statusMap = controller.toothStatusMap;
            final selected = controller.selectedToothNumber.value;

            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Quadrant 1 (18..11)
                  Row(
                    children: upperRight.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ToothWidget(
                          toothNumber: t,
                          status: statusMap[t] ?? 'healthy',
                          isSelected: selected == t,
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ToothWidget(
                          toothNumber: t,
                          status: statusMap[t] ?? 'healthy',
                          isSelected: selected == t,
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
            final selected = controller.selectedToothNumber.value;

            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Quadrant 4 (48..41)
                  Row(
                    children: lowerRight.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ToothWidget(
                          toothNumber: t,
                          status: statusMap[t] ?? 'healthy',
                          isSelected: selected == t,
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ToothWidget(
                          toothNumber: t,
                          status: statusMap[t] ?? 'healthy',
                          isSelected: selected == t,
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
