import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/treatments_controller.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/core/utils/invoice_item_grouper.dart';
import 'package:flutter_application_1/widgets/empty_state.dart';
import 'package:flutter_application_1/widgets/status_badge.dart';
import 'bulk_treatment_dialog.dart';

class MultiToothPanel extends StatelessWidget {
  const MultiToothPanel({super.key});

  Future<void> _openBulkDialog(
    BuildContext context,
    TreatmentsController controller,
    List<int> sortedTeeth,
  ) async {
    final patient = controller.selectedPatient.value;
    if (patient == null) {
      Get.snackbar(
        'Sélectionner un patient',
        'Veuillez d\'abord sélectionner un patient.',
        backgroundColor: AppColors.warningLight,
        colorText: AppColors.warning,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (sortedTeeth.isEmpty) return;

    await BulkTreatmentDialog.show(
      context,
      patient: patient,
      toothNumbers: sortedTeeth,
    );
  }

  Widget _buildGroupedActionMenu(
    BuildContext context,
    TreatmentsController controller,
    GroupedTreatmentModel item,
  ) {
    final status = item.status.toLowerCase();
    final isGroup = item.count > 1;

    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: AppColors.textMuted,
      ),
      tooltip: 'Actions',
      onSelected: (value) async {
        if (value == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                isGroup ? 'Supprimer les soins groupés' : 'Supprimer ce soin',
                style: AppTypography.h3,
              ),
              content: Text(
                isGroup
                    ? 'Voulez-vous supprimer les ${item.count} actes "${item.procedureName}" (${item.archLabel}) enregistrés le ${item.dateLabel} ?'
                    : 'Voulez-vous supprimer l\'acte "${item.procedureName}" sur la ${item.archLabel} ?',
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

          if (confirm == true) {
            final ids = item.rawTreatments
                .map((t) => t.id)
                .whereType<int>()
                .toList();
            await controller.deleteTreatments(ids);
          }
        } else {
          await controller.updateMultipleTreatmentsStatus(
            item.rawTreatments,
            value,
          );
        }
      },
      itemBuilder: (_) => [
        if (status == 'planned') ...[
          PopupMenuItem(
            value: 'in_progress',
            child: Row(children: [
              const Icon(Icons.play_circle_outline_rounded,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Text('Marquer En cours', style: AppTypography.bodySmall),
            ]),
          ),
          PopupMenuItem(
            value: 'completed',
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Marquer Terminé', style: AppTypography.bodySmall),
            ]),
          ),
        ],
        if (status == 'in_progress')
          PopupMenuItem(
            value: 'completed',
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Marquer Terminé', style: AppTypography.bodySmall),
            ]),
          ),
        if (status == 'completed')
          PopupMenuItem(
            value: 'planned',
            child: Row(children: [
              const Icon(Icons.restart_alt_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Remettre En attente', style: AppTypography.bodySmall),
            ]),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(
              isGroup ? 'Supprimer les ${item.count} actes' : 'Supprimer',
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
            ),
          ]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TreatmentsController>();

    return Obx(() {
      final selectedSet = controller.selectedToothNumbers;
      final sortedTeeth = selectedSet.toList()..sort();
      final count = sortedTeeth.length;

      // Filter treatments that belong to any of the currently selected teeth
      final selectedTreatments = controller.patientTreatments
          .where((t) => t.toothNumber != null && selectedSet.contains(t.toothNumber!))
          .toList();
      final groupedTreatments =
          InvoiceItemGrouperTreatments.groupTreatments(selectedTreatments);

      return Container(
        padding: AppSpacing.screenPadding,
        decoration: AppDecorations.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Header & Mode Exit ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: AppDecorations.iconBadge(
                    AppColors.primary,
                    radius: AppRadius.md,
                  ),
                  child: const Icon(
                    Icons.checklist_rtl_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                AppSpacing.hGap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Multi-Dents',
                        style: AppTypography.h4,
                      ),
                      Text(
                        count == 0
                            ? 'Aucune dent sélectionnée'
                            : '$count dent${count > 1 ? 's' : ''} sélectionnée${count > 1 ? 's' : ''}',
                        style: AppTypography.caption.copyWith(
                          color: count > 0 ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Quitter le mode multi-sélection',
                  color: AppColors.textSecondary,
                  onPressed: () => controller.toggleMultiSelectMode(enable: false),
                ),
              ],
            ),

            AppSpacing.vGap16,
            const Divider(),
            AppSpacing.vGap14,

            // --- Primary Action Button (Config and Apply) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: count == 0
                    ? null
                    : () => _openBulkDialog(context, controller, sortedTeeth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.buttonPaddingLarge,
                  disabledBackgroundColor: AppColors.border,
                ),
                icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
                label: Text(
                  count == 0
                      ? 'Sélectionnez des dents'
                      : 'Appliquer un acte groupé ($count)',
                  style: AppTypography.button,
                ),
              ),
            ),

            AppSpacing.vGap16,

            // --- Selected Teeth Chip List ---
            if (count > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dents sélectionnées ($count) :',
                    style: AppTypography.formLabel,
                  ),
                  TextButton.icon(
                    onPressed: () => controller.clearMultiSelection(),
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: Text(
                      'Tout désélectionner',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGap10,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: controller.selectionChips.map((chip) {
                  return InputChip(
                    avatar: chip.isGroup
                        ? const Icon(
                            Icons.layers_rounded,
                            size: 14,
                            color: AppColors.primaryDark,
                          )
                        : null,
                    label: Text(
                      chip.label,
                      style: AppTypography.badgeSmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: chip.isGroup
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primaryLight,
                    deleteIconColor: AppColors.primaryDark,
                    onDeleted: () {
                      if (chip.isGroup && chip.group != null) {
                        controller.removeGroup(chip.group!);
                      } else if (chip.tooth != null) {
                        controller.toggleToothMultiSelect(chip.tooth!);
                      }
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),

              // --- Historical Timeline on Selected Teeth ---
              AppSpacing.vGap18,
              const Divider(),
              AppSpacing.vGap14,

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historique des interventions',
                    style: AppTypography.formLabel,
                  ),
                  if (selectedTreatments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: AppRadius.borderRadiusFull,
                      ),
                      child: Text(
                        '${selectedTreatments.length}',
                        style: AppTypography.badgeSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              AppSpacing.vGap10,

              if (selectedTreatments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Aucune intervention',
                    message:
                        'Aucun acte enregistré sur les dents sélectionnées.',
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groupedTreatments.length,
                  separatorBuilder: (_, _) => AppSpacing.vGap8,
                  itemBuilder: (context, index) {
                    final item = groupedTreatments[index];
                    final isGroup = item.count > 1;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: AppDecorations.panelBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Procedure Title + Status Badge + Actions Menu
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.procedureName,
                                  style: AppTypography.formLabel.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AppSpacing.hGap8,
                              StatusBadge.treatment(item.status),
                              _buildGroupedActionMenu(
                                context,
                                controller,
                                item,
                              ),
                            ],
                          ),
                          AppSpacing.vGap6,

                          // Row 2: Arch / Tooth Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isGroup
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.primaryLight,
                              borderRadius: AppRadius.borderRadiusSm,
                              border: isGroup
                                  ? Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isGroup) ...[
                                  const Icon(
                                    Icons.layers_rounded,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    item.archLabel,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: isGroup
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vGap6,

                          // Row 3: Subtitle (count/unit price • date) & Total Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.subtitle,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AppSpacing.hGap8,
                              Text(
                                item.formattedTotal,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: EmptyState(
                  icon: Icons.touch_app_outlined,
                  title: 'Sélectionnez des dents',
                  message:
                      'Cliquez sur les dents dans le schéma ou utilisez les boutons de sélection rapide en haut du schéma.',
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
