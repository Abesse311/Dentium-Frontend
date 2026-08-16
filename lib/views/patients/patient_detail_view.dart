import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patients_controller.dart';
import 'package:flutter_application_1/core/constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/patient_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'widgets/patient_form_dialog.dart';

class PatientDetailView extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailView({super.key, required this.patient});

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editPatient(BuildContext context) async {
    final controller = Get.find<PatientsController>();
    final updated = await PatientFormDialog.show(context, patient: widget.patient);
    if (updated != null && widget.patient.id != null) {
      await controller.updatePatient(widget.patient.id!, updated);
    }
  }

  Future<void> _deletePatient(BuildContext context) async {
    final controller = Get.find<PatientsController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression', style: AppTypography.h3),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement le dossier de ${widget.patient.fullName} ? Cette action est irréversible.',
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

    if (confirm == true && widget.patient.id != null) {
      await controller.deletePatient(widget.patient.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final controller = Get.find<PatientsController>();

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Patient Banner & Actions ---
          _buildHeader(context, patient),

          const Divider(height: 1),

          // --- Scrollable Details Body ---
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Prominent Medical History & Allergies Card (Critical Priority)
                  _buildMedicalAlertCard(patient),

                  AppSpacing.vGap24,

                  // 2. Personal & Contact Information Grid
                  _buildInfoGrid(patient),

                  AppSpacing.vGap28,

                  // 3. Tabbed History (Treatments & Invoices)
                  _buildHistoryTabs(controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PatientModel patient) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.giant,
        vertical: AppSpacing.xxxl,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  patient.gender == 'female'
                      ? const Color(0xFFEC4899)
                      : AppColors.primary,
                  AppColors.accent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.borderRadiusXxl,
            ),
            alignment: Alignment.center,
            child: Text(
              patient.initials,
              style: AppTypography.h2.copyWith(color: Colors.white),
            ),
          ),
          AppSpacing.hGap18,

          // Patient Name & Quick Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patient.fullName,
                      style: AppTypography.h2,
                    ),
                    AppSpacing.hGap10,
                    if (patient.gender != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: AppDecorations.panelBg,
                        child: Text(
                          StatusLabels.gender(patient.gender),
                          style: AppTypography.badgeSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.vGap4,
                Row(
                  children: [
                    if (patient.phone != null) ...[
                      const Icon(Icons.phone_rounded,
                          size: 14, color: AppColors.textSecondary),
                      AppSpacing.hGap4,
                      Text(
                        patient.phone!,
                        style: AppTypography.bodyMedium,
                      ),
                      AppSpacing.hGap16,
                    ],
                    const Icon(Icons.cake_rounded,
                        size: 14, color: AppColors.textSecondary),
                    AppSpacing.hGap4,
                    Text(
                      patient.formattedAge,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          OutlinedButton.icon(
            onPressed: () => _editPatient(context),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text('Modifier', style: AppTypography.button),
          ),
          AppSpacing.hGap12,
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger, size: 20),
            tooltip: 'Supprimer ce patient',
            onPressed: () => _deletePatient(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalAlertCard(PatientModel patient) {
    final hasAlert = patient.hasMedicalAlert;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: hasAlert ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
        borderRadius: AppRadius.borderRadiusXl,
        border: Border.all(
          color: hasAlert ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: hasAlert
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.success.withValues(alpha: 0.15),
              borderRadius: AppRadius.borderRadiusLg,
            ),
            child: Icon(
              hasAlert
                  ? Icons.warning_amber_rounded
                  : Icons.health_and_safety_rounded,
              color: hasAlert ? AppColors.warning : AppColors.success,
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
                      hasAlert
                          ? 'Alerte Médicale & Antécédents'
                          : 'Antécédents Médicaux',
                      style: AppTypography.h4.copyWith(
                        color: hasAlert
                            ? AppColors.warningDark
                            : AppColors.successDark,
                      ),
                    ),
                    if (hasAlert) ...[
                      AppSpacing.hGap8,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: AppRadius.borderRadiusLg,
                        ),
                        child: Text(
                          'ATTENTION',
                          style: AppTypography.badgeSmall.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.vGap6,
                Text(
                  hasAlert
                      ? patient.medicalHistory!
                      : 'Aucun antécédent médical critique ni allergie signalée pour ce patient.',
                  style: AppTypography.bodyMedium.copyWith(
                    height: 1.4,
                    color: hasAlert
                        ? AppColors.warningDark
                        : AppColors.successDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(PatientModel patient) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Info Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: AppDecorations.panelBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded,
                        color: AppColors.primary, size: 18),
                    AppSpacing.hGap8,
                    Text(
                      'Coordonnées & Naissance',
                      style: AppTypography.h5,
                    ),
                  ],
                ),
                AppSpacing.vGap14,
                _buildInfoRow('Date de naissance', patient.formattedBirthDate),
                AppSpacing.vGap8,
                _buildInfoRow('Téléphone', patient.phone ?? 'Non renseigné'),
                AppSpacing.vGap8,
                _buildInfoRow('Adresse', patient.address ?? 'Non renseignée'),
              ],
            ),
          ),
        ),

        AppSpacing.hGap16,

        // Practitioner Notes Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: AppDecorations.panelBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note_alt_outlined,
                        color: AppColors.primary, size: 18),
                    AppSpacing.hGap8,
                    Text(
                      'Notes & Remarques',
                      style: AppTypography.h5,
                    ),
                  ],
                ),
                AppSpacing.vGap14,
                Text(
                  patient.notes != null && patient.notes!.trim().isNotEmpty
                       ? patient.notes!
                      : 'Aucune remarque particulière enregistrée.',
                  style: AppTypography.bodyMedium.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTabs(PatientsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Bar Header
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTypography.button,
            unselectedLabelStyle: AppTypography.button.copyWith(fontWeight: FontWeight.normal),
            tabs: [
              Tab(
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 18),
                    AppSpacing.hGap8,
                    const Text('Traitements Réalisés'),
                    AppSpacing.hGap8,
                    Obx(() => _buildCountBadge(
                        controller.patientTreatments.length)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 18),
                    AppSpacing.hGap8,
                    const Text('Factures & Règlements'),
                    AppSpacing.hGap8,
                    Obx(() =>
                        _buildCountBadge(controller.patientInvoices.length)),
                  ],
                ),
              ),
            ],
          ),
        ),

        AppSpacing.vGap16,

        // Tab Bar Views
        SizedBox(
          height: 320,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Treatments History Tab
              Obx(() {
                if (controller.isHistoryLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final treatments = controller.patientTreatments;
                if (treatments.isEmpty) {
                  return const EmptyState(
                    icon: Icons.healing_outlined,
                    title: 'Aucun traitement enregistré',
                    message:
                        'Les actes et soins dentaires pour ce patient apparaîtront ici.',
                  );
                }
                return ListView.separated(
                  itemCount: treatments.length,
                  separatorBuilder: (_, _) => AppSpacing.vGap8,
                  itemBuilder: (context, index) {
                    final item = treatments[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xl,
                      ),
                      decoration: AppDecorations.panelBg,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: AppRadius.borderRadiusMd,
                            ),
                            child: Text(
                              item.toothLabel,
                              style: AppTypography.badgeSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          AppSpacing.hGap14,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayName,
                                  style: AppTypography.formLabel,
                                ),
                                Text(
                                  item.formattedDate,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge.treatment(item.status),
                          AppSpacing.hGap16,
                          Text(
                            DateFormatter.formatCurrency(item.price),
                            style: AppTypography.formLabel,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),

              // Invoices History Tab
              Obx(() {
                if (controller.isHistoryLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final invoices = controller.patientInvoices;
                if (invoices.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_outlined,
                    title: 'Aucune facture enregistrée',
                    message:
                        'L\'historique des factures et règlements de ce patient apparaîtra ici.',
                  );
                }
                return ListView.separated(
                  itemCount: invoices.length,
                  separatorBuilder: (_, _) => AppSpacing.vGap8,
                  itemBuilder: (context, index) {
                    final item = invoices[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xl,
                      ),
                      decoration: AppDecorations.panelBg,
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_rounded,
                              color: AppColors.primary, size: 20),
                          AppSpacing.hGap14,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.invoiceNumber,
                                  style: AppTypography.formLabel,
                                ),
                                Text(
                                  item.formattedDate,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge.invoice(item.status),
                          AppSpacing.hGap20,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total : ${DateFormatter.formatCurrency(item.totalAmount)}',
                                style: AppTypography.formLabel,
                              ),
                              if (item.status != 'paid')
                                Text(
                                  'Reste : ${DateFormatter.formatCurrency(item.remainingAmount)}',
                                  style: AppTypography.badgeSmall.copyWith(
                                    color: AppColors.danger,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.borderRadiusLg,
      ),
      child: Text(
        '$count',
        style: AppTypography.badgeSmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}


