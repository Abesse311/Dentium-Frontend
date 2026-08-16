import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/treatments_controller.dart';
import '../../models/treatment_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'treatment_form_dialog.dart';

class ToothDetailPanel extends StatelessWidget {
  const ToothDetailPanel({super.key});

  static String getToothAnatomicalName(int tooth) {
    final quadrant = tooth ~/ 10;
    final pos = tooth % 10;

    String quadName = '';
    switch (quadrant) {
      case 1:
        quadName = 'Supérieure Droite';
        break;
      case 2:
        quadName = 'Supérieure Gauche';
        break;
      case 3:
        quadName = 'Inférieure Gauche';
        break;
      case 4:
        quadName = 'Inférieure Droite';
        break;
    }

    String typeName = '';
    switch (pos) {
      case 1:
        typeName = 'Incisive Centrale';
        break;
      case 2:
        typeName = 'Incisive Latérale';
        break;
      case 3:
        typeName = 'Canine';
        break;
      case 4:
        typeName = '1ère Prémolaire';
        break;
      case 5:
        typeName = '2ème Prémolaire';
        break;
      case 6:
        typeName = '1ère Molaire (6 ans)';
        break;
      case 7:
        typeName = '2ème Molaire (12 ans)';
        break;
      case 8:
        typeName = '3ème Molaire (Sagesse)';
        break;
      default:
        typeName = 'Dent';
    }

    return '$typeName $quadName';
  }

  Future<void> _addTreatmentForTooth(BuildContext context, int toothNumber) async {
    final controller = Get.find<TreatmentsController>();
    final patient = controller.selectedPatient.value;
    if (patient == null) return;

    await TreatmentFormDialog.show(
      context,
      patient: patient,
      toothNumber: toothNumber,
    );
  }

  Future<void> _deleteTreatment(BuildContext context, TreatmentModel treatment) async {
    final controller = Get.find<TreatmentsController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ce soin', style: AppTypography.h3),
        content: Text(
          'Voulez-vous supprimer l\'acte "${treatment.displayName}" enregistré le ${treatment.formattedDate} ?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: AppTypography.button),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: AppTypography.button),
          ),
        ],
      ),
    );

    if (confirm == true && treatment.id != null) {
      await controller.deleteTreatment(treatment.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TreatmentsController>();

    return Obx(() {
      final selectedTooth = controller.selectedToothNumber.value;

      if (selectedTooth == null) {
        return Container(
          padding: AppSpacing.screenPadding,
          decoration: AppDecorations.panel,
          child: const EmptyState(
            icon: Icons.touch_app_outlined,
            title: 'Sélectionnez une dent',
            message:
                'Cliquez sur une dent dans l\'odontogramme pour voir son historique détaillé ou y enregistrer un soin.',
          ),
        );
      }

      final toothTreatments = controller.selectedToothTreatments;
      final statusMap = controller.toothStatusMap;
      final toothStatus = statusMap[selectedTooth] ?? 'healthy';
      final anatomicalName = getToothAnatomicalName(selectedTooth);

      return Container(
        padding: AppSpacing.screenPadding,
        decoration: AppDecorations.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Inspector Header ---
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.borderRadiusXl,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$selectedTooth',
                    style: AppTypography.h3.copyWith(color: AppColors.primary),
                  ),
                ),
                AppSpacing.hGap14,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dent $selectedTooth',
                        style: AppTypography.h3,
                      ),
                      Text(
                        anatomicalName,
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StatusBadge.treatment(toothStatus),
              ],
            ),

            AppSpacing.vGap16,
            const Divider(),
            AppSpacing.vGap14,

            // --- Add Treatment on this tooth button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addTreatmentForTooth(context, selectedTooth),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Ajouter un acte sur la dent $selectedTooth',
                  style: AppTypography.buttonSmall,
                ),
              ),
            ),

            AppSpacing.vGap18,

            // --- Historical Timeline ---
            Text(
              'Historique des interventions sur cette dent',
              style: AppTypography.formLabel,
            ),
            AppSpacing.vGap10,

            toothTreatments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Dent saine / Aucun acte',
                      message:
                          'Aucune intervention enregistrée sur cette dent pour le moment.',
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: toothTreatments.length,
                    separatorBuilder: (_, __) => AppSpacing.vGap8,
                    itemBuilder: (context, index) {
                      final item = toothTreatments[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: AppDecorations.panelBg,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayName,
                                    style: AppTypography.formLabel,
                                  ),
                                  AppSpacing.vGap2,
                                  Text(
                                    '${item.formattedDate} • ${item.formattedPrice}',
                                    style: AppTypography.caption,
                                  ),
                                  if (item.notes != null &&
                                      item.notes!.trim().isNotEmpty) ...[
                                    AppSpacing.vGap2,
                                    Text(
                                      item.notes!,
                                      style: AppTypography.caption.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            StatusBadge.treatment(item.status),
                            AppSpacing.hGap8,
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: AppColors.textMuted),
                              tooltip: 'Supprimer ce soin',
                              onPressed: () => _deleteTreatment(context, item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      );
    });
  }
}
