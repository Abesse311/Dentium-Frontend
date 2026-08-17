import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/treatments_controller.dart';
import '../../models/patient_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'widgets/odontogram_widget.dart';
import 'widgets/tooth_detail_panel.dart';
import 'widgets/treatment_form_dialog.dart';
import 'widgets/pending_treatments_dialog.dart';

class TreatmentsView extends StatelessWidget {
  const TreatmentsView({super.key});

  /// Popup menu: status transitions + delete — shared between general and tooth treatments
  Widget _buildActionMenu(
      BuildContext context, TreatmentsController controller, item) {
    final status = item.status.toLowerCase();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          size: 18, color: AppColors.textMuted),
      tooltip: 'Actions',
      onSelected: (value) async {
        if (value == 'delete') {
          if (item.id != null) controller.deleteTreatment(item.id!);
        } else {
          await controller.updateTreatmentStatus(item, value);
        }
      },
      itemBuilder: (_) => [
        if (status == 'planned') ...
          [
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
            Text('Supprimer',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.danger)),
          ]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TreatmentsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top Toolbar: Patient Selector & Actions ---
            Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.xxl,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: AppSpacing.xxl,
                  runSpacing: AppSpacing.xxl,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Patient Selector
                    Obx(() {
                      final patientsList = controller.patients;
                      final selected = controller.selectedPatient.value;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: AppDecorations.panel,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded,
                                color: AppColors.primary, size: 20),
                            AppSpacing.hGap10,
                            Text(
                              'Patient :',
                              style: AppTypography.formLabel.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            AppSpacing.hGap8,
                            DropdownButtonHideUnderline(
                              child: DropdownButton<PatientModel>(
                                value: selected,
                                hint: Text('Sélectionner un patient', style: AppTypography.bodyMedium),
                                items: patientsList.map((p) {
                                  return DropdownMenuItem<PatientModel>(
                                    value: p,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          p.fullName,
                                          style: AppTypography.formLabel,
                                        ),
                                        if (p.hasMedicalAlert) ...[
                                          AppSpacing.hGap8,
                                          const Icon(Icons.warning_amber_rounded,
                                              size: 16, color: AppColors.warning),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (p) => controller.selectPatient(p),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Selected Patient Medical Alert Reminder (if any)
                    Obx(() {
                      final patient = controller.selectedPatient.value;
                      if (patient != null && patient.hasMedicalAlert) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: AppDecorations.alertTag,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.warning, size: 18),
                              AppSpacing.hGap6,
                              Text(
                                'Alerte : ${patient.medicalHistory}',
                                style: AppTypography.badgeSmall.copyWith(
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),

                // Top Action Buttons
                Obx(() {
                  final count = controller.pendingTreatments.length;
                  return OutlinedButton.icon(
                    onPressed: () => PendingTreatmentsDialog.show(context),
                    style: OutlinedButton.styleFrom(
                      padding: AppSpacing.buttonPaddingLarge,
                      foregroundColor: AppColors.warningDark,
                      side: const BorderSide(color: AppColors.warning),
                    ),
                    icon: const Icon(Icons.pending_actions_rounded,
                        size: 20, color: AppColors.warning),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Soins en attente',
                          style: AppTypography.button.copyWith(
                            color: AppColors.warningDark,
                          ),
                        ),
                        if (count > 0) ...[
                          AppSpacing.hGap8,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: AppRadius.borderRadiusFull,
                            ),
                            child: Text(
                              '$count',
                              style: AppTypography.badgeSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),

            AppSpacing.vGap20,

            // --- Main Interactive Workspace (Odontogram + Inspector) ---
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.patientTreatments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.selectedPatient.value == null) {
                  return const EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'Aucun patient sélectionné',
                    message:
                        'Veuillez créer ou sélectionner un patient pour afficher son schéma dentaire.',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;

                    final mainPanel = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 32-Tooth Interactive Dental Arch
                        const OdontogramWidget(),

                        AppSpacing.vGap20,

                        // General Treatments Section
                        _buildGeneralTreatmentsSection(context, controller),
                      ],
                    );

                    if (isNarrow) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            mainPanel,
                            AppSpacing.vGap20,
                            const ToothDetailPanel(),
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Main Panel: Odontogram + General Treatments
                        Expanded(
                          flex: 7,
                          child: SingleChildScrollView(
                            child: mainPanel,
                          ),
                        ),

                        AppSpacing.hGap20,

                        // Right Inspector Panel: Tooth Detail Inspector
                        const Expanded(
                          flex: 4,
                          child: ToothDetailPanel(),
                        ),
                      ],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTreatmentsSection(
    BuildContext context,
    TreatmentsController controller,
  ) {
    return Obx(() {
      final generalList = controller.generalTreatments;

      return Container(
        padding: AppSpacing.cardPadding,
        decoration: AppDecorations.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.health_and_safety_outlined,
                        color: AppColors.primary, size: 20),
                    AppSpacing.hGap8,
                    Text(
                      'Soins & Traitements Généraux (Non rattachés à une dent)',
                      style: AppTypography.h5,
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    final patient = controller.selectedPatient.value;
                    if (patient != null) {
                      TreatmentFormDialog.show(
                        context,
                        patient: patient,
                        toothNumber: null,
                      );
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Ajouter un soin général',
                      style: AppTypography.buttonSmall),
                ),
              ],
            ),
            AppSpacing.vGap12,
            if (generalList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'Aucun soin général (ex: consultation, détartrage global) enregistré pour ce patient.',
                  style: AppTypography.bodySmall,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: generalList.length,
                separatorBuilder: (_, _) => AppSpacing.vGap8,
                itemBuilder: (context, index) {
                  final item = generalList[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    decoration: AppDecorations.panelBg,
                    child: Row(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            size: 18, color: AppColors.primary),
                        AppSpacing.hGap12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayName,
                                style: AppTypography.formLabel,
                              ),
                              Text(
                                '${item.formattedDate} • ${item.formattedPrice}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge.treatment(item.status),
                        _buildActionMenu(context, controller, item),
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






