import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/appointments_controller.dart';
import '../../core/utils/date_formatter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'appointment_card.dart';
import 'book_appointment_dialog.dart';
import 'week_capacity_strip.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  Future<void> _openBookingDialog(BuildContext context) async {
    final controller = Get.find<AppointmentsController>();
    await BookAppointmentDialog.show(
      context,
      initialDate: controller.selectedDate.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppointmentsController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Top Controls (Week Switcher & Action) ---
            Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.xxl,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Week Switcher Controls
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: AppDecorations.panel,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 22),
                        tooltip: 'Semaine précédente',
                        onPressed: controller.previousWeek,
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                        ),
                        onPressed: controller.goToToday,
                        child: Text('Aujourd\'hui',
                            style: AppTypography.button),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 22),
                        tooltip: 'Semaine suivante',
                        onPressed: controller.nextWeek,
                      ),
                    ],
                  ),
                ),

                // Month / Year Label
                Obx(() {
                  final weekStart = controller.weekStartDate.value;
                  final monthYear = DateFormatter.formatMedium(weekStart);
                  return Text(
                    'Semaine du $monthYear',
                    style: AppTypography.h3,
                  );
                }),

                // New Booking Button
                ElevatedButton.icon(
                  onPressed: () => _openBookingDialog(context),
                  style: ElevatedButton.styleFrom(
                    padding: AppSpacing.buttonPaddingLarge,
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text('Nouveau Rendez-vous',
                      style: AppTypography.button),
                ),
              ],
            ),

            AppSpacing.vGap18,

            // --- 2. Interactive Week Capacity Strip ---
            const WeekCapacityStrip(),

            AppSpacing.vGap24,

            // --- 3. Selected Day Header & Filter Pills ---
            Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.xxl,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Obx(() {
                  final date = controller.selectedDate.value;
                  final total = controller.dayAppointments.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.formatFull(date),
                        style: AppTypography.h3,
                      ),
                      AppSpacing.vGap2,
                      Text(
                        '$total patient${total > 1 ? 's' : ''} prévu${total > 1 ? 's' : ''} ce jour',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  );
                }),

                // Filter Buttons
                Obx(() {
                  final currentFilter = controller.statusFilter.value;
                  return Container(
                    decoration: AppDecorations.panel,
                    padding: const EdgeInsets.all(3),
                    child: Wrap(
                      children: [
                        _buildFilterButton('Tous', 'all', currentFilter, controller),
                        _buildFilterButton('Réservés', 'booked', currentFilter, controller),
                        _buildFilterButton('Terminés', 'completed', currentFilter, controller),
                        _buildFilterButton('Absents', 'no_show', currentFilter, controller),
                      ],
                    ),
                  );
                }),
              ],
            ),

            AppSpacing.vGap16,

            // --- 4. Day Appointments List ---
            Expanded(
              child: Obx(() {
                if (controller.isLoadingAppointments.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.isNotEmpty &&
                    controller.dayAppointments.isEmpty) {
                  return EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Erreur de chargement',
                    message: controller.errorMessage.value,
                    action: OutlinedButton.icon(
                      onPressed: () => controller.fetchDayAppointments(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text('Réessayer', style: AppTypography.buttonSmall),
                    ),
                  );
                }

                final list = controller.filteredAppointments;

                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'Aucun rendez-vous pour ce jour',
                    message:
                        'Cliquez sur "Nouveau Rendez-vous" pour ajouter une consultation.',
                    action: ElevatedButton.icon(
                      onPressed: () => _openBookingDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('Prendre un rendez-vous',
                          style: AppTypography.button),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => controller.fetchDayAppointments(),
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => AppSpacing.vGap10,
                    itemBuilder: (context, index) {
                      final appt = list[index];
                      return AppointmentCard(appointment: appt);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    String filterValue,
    String currentFilter,
    AppointmentsController controller,
  ) {
    final isSelected = currentFilter == filterValue;
    return InkWell(
      onTap: () => controller.setFilter(filterValue),
      borderRadius: AppRadius.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: Text(
          label,
          style: AppTypography.badgeSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
