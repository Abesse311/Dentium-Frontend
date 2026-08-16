import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patients_controller.dart';
import '../../models/patient_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_input.dart';
import 'patient_detail_view.dart';
import 'widgets/patient_form_dialog.dart';

class PatientsView extends StatelessWidget {
  const PatientsView({super.key});

  Future<void> _openAddPatientDialog(BuildContext context) async {
    final controller = Get.find<PatientsController>();
    final newPatient = await PatientFormDialog.show(context);
    if (newPatient != null) {
      await controller.createPatient(newPatient);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PatientsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 850;

          final listPanel = Container(
            width: isNarrow ? null : 380,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // 1. Panel Header & Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      Obx(() {
                        final total = controller.patients.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Répertoire Patients',
                              style: AppTypography.h4,
                            ),
                            Text(
                              '$total dossier${total > 1 ? 's' : ''} au total',
                              style: AppTypography.caption,
                            ),
                          ],
                        );
                      }),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _openAddPatientDialog(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text('Nouveau', style: AppTypography.buttonSmall),
                      ),
                    ],
                  ),
                ),

                // 2. Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: SearchInput(
                    hintText: 'Rechercher par nom, téléphone...',
                    onChanged: (val) => controller.search(val),
                  ),
                ),

                AppSpacing.vGap12,
                const Divider(height: 1),

                // 3. Reactive Patients List
                Expanded(
                  child: Obx(() {
                    final selectedId = controller.selectedPatient.value?.id;

                    if (controller.isLoading.value && controller.patients.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.errorMessage.isNotEmpty && controller.patients.isEmpty) {
                      return EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Connexion indisponible',
                        message: controller.errorMessage.value,
                        action: OutlinedButton.icon(
                          onPressed: () => controller.fetchPatients(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text('Réessayer', style: AppTypography.buttonSmall),
                        ),
                      );
                    }

                    final list = controller.filteredPatients;
                    if (list.isEmpty) {
                      return EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'Aucun patient trouvé',
                        message: controller.searchQuery.isEmpty
                            ? 'Créez votre premier dossier patient en cliquant sur "Nouveau".'
                            : 'Aucun résultat pour "${controller.searchQuery.value}".',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => controller.fetchPatients(),
                      child: ListView.separated(
                        padding: AppSpacing.listItemPadding,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => AppSpacing.vGap6,
                        itemBuilder: (context, index) {
                          final patient = list[index];
                          final isSelected = selectedId == patient.id;

                          return _PatientListItem(
                            patient: patient,
                            isSelected: isSelected,
                            onTap: () => controller.selectPatient(patient),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              isNarrow ? Expanded(flex: 4, child: listPanel) : listPanel,

              // --- Right Detail Panel ---
              Expanded(
                flex: isNarrow ? 6 : 1,
                child: Obx(() {
                  final selected = controller.selectedPatient.value;
                  if (selected == null) {
                    return const EmptyState(
                      icon: Icons.folder_shared_outlined,
                      title: 'Sélectionnez un patient',
                      message:
                          'Cliquez sur un patient dans la liste de gauche pour consulter son dossier complet.',
                    );
                  }

                  return PatientDetailView(
                    key: ValueKey(selected.id),
                    patient: selected,
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PatientListItem extends StatefulWidget {
  final PatientModel patient;
  final bool isSelected;
  final VoidCallback onTap;

  const _PatientListItem({
    required this.patient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PatientListItem> createState() => _PatientListItemState();
}

class _PatientListItemState extends State<_PatientListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    Color bgColor = Colors.transparent;
    Color borderColor = Colors.transparent;

    if (widget.isSelected) {
      bgColor = AppColors.primaryLight;
      borderColor = AppColors.primary.withValues(alpha: 0.4);
    } else if (_isHovered) {
      bgColor = AppColors.background;
      borderColor = AppColors.border;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              // Avatar with Initials
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.primaryLight,
                  borderRadius: AppRadius.borderRadiusXl,
                ),
                alignment: Alignment.center,
                child: Text(
                  patient.initials,
                  style: AppTypography.h5.copyWith(
                    color: widget.isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.hGap12,

              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.fullName,
                            style: AppTypography.h5.copyWith(
                              fontWeight: widget.isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (patient.hasMedicalAlert) ...[
                          AppSpacing.hGap6,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: AppDecorations.alertTag,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 11, color: AppColors.warning),
                                AppSpacing.hGap2,
                                Text(
                                  'Alerte',
                                  style: AppTypography.badgeSmall.copyWith(
                                    color: AppColors.warningDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (patient.phone != null) ...[
                          Text(
                            patient.phone!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.hGap8,
                          Text('•',
                              style: AppTypography.caption.copyWith(fontSize: 10)),
                          AppSpacing.hGap8,
                        ],
                        Text(
                          patient.formattedAge,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              AppSpacing.hGap4,
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


