import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/dashboard_metrics_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'package:flutter_application_1/views/appointments/widgets/book_appointment_dialog.dart';
import 'package:flutter_application_1/views/invoices/widgets/create_invoice_dialog.dart';
import 'package:flutter_application_1/views/patients/widgets/patient_form_dialog.dart';
import 'widgets/metric_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final navController = Get.find<NavigationController>();

    final todayStr = DateFormatter.formatFull(DateTime.now());

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: () => controller.fetchDashboardData(),
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Welcome Header & Quick Actions ---
              Wrap(
                spacing: AppSpacing.xxl,
                runSpacing: AppSpacing.xxl,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bonjour, Docteur 👋',
                        style: AppTypography.h1,
                      ),
                      AppSpacing.vGap4,
                      Text(
                        'Voici le récapitulatif de votre journée du $todayStr',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      // Quick Action Buttons
                      ElevatedButton.icon(
                        onPressed: () async {
                          final booked = await BookAppointmentDialog.show(
                            context,
                            initialDate: DateTime.now(),
                          );
                          if (booked == true) {
                            controller.fetchDashboardData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: AppSpacing.buttonPadding,
                        ),
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text('Rendez-vous', style: AppTypography.button),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final created = await PatientFormDialog.show(context);
                          if (created != null) {
                            controller.fetchDashboardData();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: AppSpacing.buttonPadding,
                        ),
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: Text('Nouveau Patient', style: AppTypography.button),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final invoiced = await CreateInvoiceDialog.show(context);
                          if (invoiced == true) {
                            controller.fetchDashboardData();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: AppSpacing.buttonPadding,
                        ),
                        icon: const Icon(Icons.receipt_long_rounded, size: 18),
                        label: Text('Facturer', style: AppTypography.button),
                      ),
                    ],
                  ),
                ],
              ),

              AppSpacing.vGap24,

              // --- 2. Live KPI Metric Cards Row ---
              Obx(() {
                final m = controller.metrics.value ??
                    const DashboardMetricsModel();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;

                    if (isNarrow) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Patients du jour',
                                  value: '${m.totalPatientsToday}',
                                  subtitle:
                                      '${m.completedToday} vus • ${m.bookedToday} en attente',
                                  icon: Icons.people_alt_rounded,
                                  accentColor: AppColors.primary,
                                ),
                              ),
                              AppSpacing.hGap16,
                              Expanded(
                                child: MetricCard(
                                  title: 'Taux de réalisation',
                                  value: '${(m.completionRate * 100).round()}%',
                                  subtitle:
                                      '${m.completedToday} sur ${m.totalPatientsToday}',
                                  icon: Icons.check_circle_outline_rounded,
                                  accentColor: AppColors.success,
                                  trailing: ClipRRect(
                                    borderRadius: AppRadius.borderRadiusXs,
                                    child: LinearProgressIndicator(
                                      value: m.completionRate,
                                      minHeight: 6,
                                      backgroundColor: AppColors.border,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.success),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vGap16,
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Recettes',
                                  value: m.formattedIncome,
                                  subtitle: 'Aujourd\'hui',
                                  icon: Icons.payments_rounded,
                                  accentColor: AppColors.teal,
                                ),
                              ),
                              AppSpacing.hGap16,
                              Expanded(
                                child: MetricCard(
                                  title: 'Soins en attente',
                                  value: '${m.pendingTreatmentsCount}',
                                  subtitle: 'Actes dentaires',
                                  icon: Icons.pending_actions_rounded,
                                  accentColor: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        // Card 1: Today's Booked Patients
                        Expanded(
                          child: MetricCard(
                            title: 'Patients du jour',
                            value: '${m.totalPatientsToday}',
                            subtitle:
                                '${m.completedToday} vus • ${m.bookedToday} en attente • ${m.noShowToday} absents',
                            icon: Icons.people_alt_rounded,
                            accentColor: AppColors.primary,
                          ),
                        ),
                        AppSpacing.hGap16,

                        // Card 2: Completion Rate
                        Expanded(
                          child: MetricCard(
                            title: 'Taux de réalisation',
                            value: '${(m.completionRate * 100).round()}%',
                            subtitle:
                                '${m.completedToday} sur ${m.totalPatientsToday} consultations',
                            icon: Icons.check_circle_outline_rounded,
                            accentColor: AppColors.success,
                            trailing: ClipRRect(
                              borderRadius: AppRadius.borderRadiusXs,
                              child: LinearProgressIndicator(
                                value: m.completionRate,
                                minHeight: 6,
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.success),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.hGap16,

                        // Card 3: Today's Income
                        Expanded(
                          child: MetricCard(
                            title: 'Recettes encaissées',
                            value: m.formattedIncome,
                            subtitle: 'Règlements reçus aujourd\'hui',
                            icon: Icons.payments_rounded,
                            accentColor: AppColors.teal,
                          ),
                        ),
                        AppSpacing.hGap16,

                        // Card 4: Pending Treatments
                        Expanded(
                          child: MetricCard(
                            title: 'Soins planifiés en attente',
                            value: '${m.pendingTreatmentsCount}',
                            subtitle: 'Actes dentaires à programmer',
                            icon: Icons.pending_actions_rounded,
                            accentColor: AppColors.warning,
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),

              AppSpacing.vGap28,

              // --- 3. Bottom Grid: Today's Appointments & Quick Links ---
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;

                  final schedulePanel = Container(
                    padding: AppSpacing.cardPadding,
                    decoration: AppDecorations.panel,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    color: AppColors.primary, size: 20),
                                AppSpacing.hGap8,
                                Text(
                                  'Consultations prévues aujourd\'hui',
                                  style: AppTypography.h4,
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => navController.changeIndex(2),
                              child: Text('Voir planning complet →',
                                  style: AppTypography.buttonSmall),
                            ),
                          ],
                        ),
                        AppSpacing.vGap14,
                        const Divider(height: 1),
                        AppSpacing.vGap12,

                        Obx(() {
                          if (controller.isLoading.value &&
                              controller.todayAppointments.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: AppSpacing.dialogPadding,
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final list = controller.todayAppointments;

                          if (list.isEmpty) {
                            return const Padding(
                              padding: AppSpacing.dialogPadding,
                              child: EmptyState(
                                icon: Icons.event_available_rounded,
                                title: 'Aucun patient prévu aujourd\'hui',
                                message:
                                    'Votre planning pour cette journée est libre.',
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => AppSpacing.vGap8,
                            itemBuilder: (context, index) {
                              final appt = list[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                  vertical: AppSpacing.lg,
                                ),
                                decoration: AppDecorations.panelBg,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: AppRadius.borderRadiusMd,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.person_rounded,
                                          color: AppColors.primary,
                                          size: 20),
                                    ),
                                    AppSpacing.hGap12,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appt.displayName,
                                            style: AppTypography.h5,
                                          ),
                                          Text(
                                            appt.reason ?? 'Consultation',
                                            style: AppTypography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge.appointment(appt.status),
                                    AppSpacing.hGap12,

                                    // Quick Actions
                                    if (appt.status != 'completed')
                                      IconButton(
                                        icon: const Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: AppColors.success,
                                            size: 22),
                                        tooltip: 'Marquer comme terminé',
                                        onPressed: () {
                                          if (appt.id != null) {
                                            controller.markAppointmentCompleted(
                                                appt.id!);
                                          }
                                        },
                                      ),
                                    if (appt.status != 'no_show')
                                      IconButton(
                                        icon: const Icon(
                                            Icons.person_off_outlined,
                                            color: AppColors.danger,
                                            size: 20),
                                        tooltip: 'Marquer comme absent',
                                        onPressed: () {
                                          if (appt.id != null) {
                                            controller.markAppointmentNoShow(
                                                appt.id!);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  );

                  final quickNavPanel = Container(
                    padding: AppSpacing.cardPadding,
                    decoration: AppDecorations.panel,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accès Rapides',
                          style: AppTypography.h4,
                        ),
                        AppSpacing.vGap14,
                        _buildQuickNavCard(
                          'Schéma Dentaire (Odontogramme)',
                          'Consulter les dossiers et soins dentaires',
                          Icons.medical_services_rounded,
                          AppColors.primary,
                          () => navController.changeIndex(3),
                        ),
                        AppSpacing.vGap10,
                        _buildQuickNavCard(
                          'Répertoire des Patients',
                          'Fiches médicales, antécédents et contacts',
                          Icons.people_rounded,
                          AppColors.accent,
                          () => navController.changeIndex(1),
                        ),
                        AppSpacing.vGap10,
                        _buildQuickNavCard(
                          'Factures & Paiements',
                          'Règlements, impayés et encaissements',
                          Icons.receipt_long_rounded,
                          AppColors.teal,
                          () => navController.changeIndex(4),
                        ),
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        schedulePanel,
                        AppSpacing.vGap20,
                        quickNavPanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: schedulePanel),
                      AppSpacing.hGap20,
                      Expanded(flex: 4, child: quickNavPanel),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderRadiusLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: AppDecorations.panelBg,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppDecorations.iconBadge(color, radius: AppRadius.md),
              child: Icon(icon, color: color, size: 20),
            ),
            AppSpacing.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.formLabel,
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}






