import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/treatments_controller.dart';
import '../../../models/treatment_model.dart';
import '../../../core/theme.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/search_input.dart';
import '../../appointments/widgets/book_appointment_dialog.dart';
import 'tooth_detail_panel.dart';

class PendingTreatmentsDialog extends StatefulWidget {
  const PendingTreatmentsDialog({super.key});

  static Future<void> show(BuildContext context) {
    // Refresh pending treatments when opening
    if (Get.isRegistered<TreatmentsController>()) {
      Get.find<TreatmentsController>().fetchPendingTreatments();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PendingTreatmentsDialog(),
    );
  }

  @override
  State<PendingTreatmentsDialog> createState() => _PendingTreatmentsDialogState();
}

class _PendingTreatmentsDialogState extends State<PendingTreatmentsDialog> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all' | 'planned' | 'in_progress'

  Future<void> _bookAppointmentForTreatment(
    BuildContext context,
    TreatmentModel treatment,
  ) async {
    Navigator.of(context).pop(); // Close dialog

    final reason = treatment.isGeneral
        ? 'Soin : ${treatment.displayName}'
        : 'Soin Dent ${treatment.toothNumber} : ${treatment.displayName}';

    await BookAppointmentDialog.show(
      context,
      initialPatientId: treatment.patientId,
      initialReason: reason,
    );
  }

  Future<void> _openOdontogram(
    BuildContext context,
    TreatmentModel treatment,
  ) async {
    Navigator.of(context).pop(); // Close dialog
    final controller = Get.find<TreatmentsController>();
    await controller.openPatientInOdontogram(
      treatment.patientId,
      toothNumber: treatment.toothNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TreatmentsController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 900,
        height: 750,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderRadiusXxl,
          boxShadow: AppShadows.dialog,
        ),
        child: Column(
          children: [
            // --- 1. Dialog Header ---
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: AppDecorations.iconBadge(
                      AppColors.warning,
                      radius: AppRadius.xl,
                    ),
                    child: const Icon(
                      Icons.pending_actions_rounded,
                      color: AppColors.warning,
                      size: 24,
                    ),
                  ),
                  AppSpacing.hGap16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Soins planifiés en attente',
                              style: AppTypography.h3,
                            ),
                            AppSpacing.hGap10,
                            Obx(() {
                              final count = controller.pendingTreatments.length;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warningLight,
                                  borderRadius: AppRadius.borderRadiusFull,
                                ),
                                child: Text(
                                  '$count soin${count > 1 ? 's' : ''}',
                                  style: AppTypography.badgeSmall.copyWith(
                                    color: AppColors.warningDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        AppSpacing.vGap4,
                        Text(
                          'Actes dentaires prescrits en attente de réalisation ou à planifier en rendez-vous.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // --- 2. Filter & Search Toolbar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
              child: Row(
                children: [
                  // Search Box
                  Expanded(
                    child: SearchInput(
                      hintText:
                          'Rechercher par patient, acte ou numéro de dent...',
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  AppSpacing.hGap16,

                  // Filter Chips (Tous / Planifiés / En cours)
                  Obx(() {
                    final all = controller.pendingTreatments;
                    final plannedCount =
                        all.where((t) => t.status == 'planned').length;
                    final inProgressCount =
                        all.where((t) => t.status == 'in_progress').length;

                    return Container(
                      decoration: AppDecorations.panelBg,
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterChip('all', 'Tous (${all.length})'),
                          AppSpacing.hGap4,
                          _buildFilterChip('planned', 'Planifiés ($plannedCount)'),
                          AppSpacing.hGap4,
                          _buildFilterChip(
                              'in_progress', 'En cours ($inProgressCount)'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const Divider(height: 1),

            // --- 3. Treatments List ---
            Expanded(
              child: Obx(() {
                if (controller.isPendingLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final rawList = controller.pendingTreatments;
                final filtered = rawList.where((t) {
                  // Status filter
                  if (_filterStatus != 'all' && t.status != _filterStatus) {
                    return false;
                  }

                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final matchPatient =
                        (t.patientName ?? '').toLowerCase().contains(_searchQuery);
                    final matchPhone =
                        (t.patientPhone ?? '').toLowerCase().contains(_searchQuery);
                    final matchType =
                        t.displayName.toLowerCase().contains(_searchQuery);
                    final matchTooth = t.toothNumber != null &&
                        '${t.toothNumber}'.contains(_searchQuery);
                    final matchNotes =
                        (t.notes ?? '').toLowerCase().contains(_searchQuery);

                    return matchPatient ||
                        matchPhone ||
                        matchType ||
                        matchTooth ||
                        matchNotes;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: _searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.check_circle_outline_rounded,
                    title: _searchQuery.isNotEmpty
                        ? 'Aucun résultat trouvé'
                        : 'Aucun soin en attente',
                    message: _searchQuery.isNotEmpty
                        ? 'Aucun acte ne correspond à "$_searchQuery".'
                        : 'Tous les actes dentaires prescrits ont été complétés !',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(28),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => AppSpacing.vGap12,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildTreatmentCard(context, controller, item);
                  },
                );
              }),
            ),

            // --- 4. Footer Bar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💡 Cliquez sur "Schéma dentaire" pour ouvrir l\'odontogramme du patient ou "Prendre RDV" pour planifier.',
                    style: AppTypography.caption,
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: AppSpacing.buttonPadding,
                    ),
                    child: Text('Fermer', style: AppTypography.buttonSmall),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = key;
        });
      },
      borderRadius: AppRadius.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: AppRadius.borderRadiusMd,
          boxShadow: isSelected ? AppShadows.subtle : null,
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentCard(
    BuildContext context,
    TreatmentsController controller,
    TreatmentModel item,
  ) {
    final patientName = item.patientName ?? 'Patient #${item.patientId}';
    final toothName = item.toothNumber != null
        ? ToothDetailPanel.getToothAnatomicalName(item.toothNumber!)
        : 'Soin Général';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusXl,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Patient Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              patientName.isNotEmpty
                  ? patientName.substring(0, 1).toUpperCase()
                  : 'P',
              style: AppTypography.h4.copyWith(color: AppColors.primary),
            ),
          ),
          AppSpacing.hGap16,

          // 2. Patient & Treatment Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patientName,
                      style: AppTypography.formLabel.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.patientPhone != null &&
                        item.patientPhone!.isNotEmpty) ...[
                      AppSpacing.hGap8,
                      Text(
                        '(${item.patientPhone})',
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
                AppSpacing.vGap4,
                Row(
                  children: [
                    // Tooth indicator badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.isGeneral
                            ? AppColors.tealLight
                            : AppColors.primaryLight,
                        borderRadius: AppRadius.borderRadiusSm,
                      ),
                      child: Text(
                        item.toothLabel,
                        style: AppTypography.badgeSmall.copyWith(
                          color: item.isGeneral
                              ? AppColors.teal
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AppSpacing.hGap8,
                    Expanded(
                      child: Text(
                        '${item.displayName} • $toothName',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                  AppSpacing.vGap4,
                  Text(
                    'Note : ${item.notes}',
                    style: AppTypography.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                AppSpacing.vGap4,
                Text(
                  '${item.formattedDate} • ${item.formattedPrice}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),

          AppSpacing.hGap16,

          // 3. Status Badge
          StatusBadge.treatment(item.status),

          AppSpacing.hGap16,

          // 4. Quick Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pre-fill Appointment Booking
              ElevatedButton.icon(
                onPressed: () => _bookAppointmentForTreatment(context, item),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                ),
                icon: const Icon(Icons.calendar_today_rounded, size: 15),
                label: Text('Prendre RDV', style: AppTypography.buttonSmall),
              ),
              AppSpacing.hGap8,

              // Jump to Odontogram
              OutlinedButton.icon(
                onPressed: () => _openOdontogram(context, item),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.medical_services_outlined, size: 15),
                label: Text('Schéma', style: AppTypography.buttonSmall),
              ),
              AppSpacing.hGap4,

              // Status Change Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 18, color: AppColors.textMuted),
                tooltip: 'Statut / Actions',
                onSelected: (val) async {
                  if (val == 'delete') {
                    if (item.id != null) {
                      await controller.deleteTreatment(item.id!);
                    }
                  } else {
                    await controller.updateTreatmentStatus(item, val);
                  }
                },
                itemBuilder: (_) => [
                  if (item.status == 'planned')
                    PopupMenuItem(
                      value: 'in_progress',
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_outline_rounded,
                              size: 18, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text('Marquer En cours',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'completed',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text('Marquer Terminé',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Text('Supprimer',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
