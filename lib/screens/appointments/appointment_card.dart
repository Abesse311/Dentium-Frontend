import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/appointments_controller.dart';
import '../../models/appointment_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentCard({super.key, required this.appointment});

  Future<void> _confirmCancel(BuildContext context) async {
    final controller = Get.find<AppointmentsController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler ce rendez-vous', style: AppTypography.h3),
        content: Text(
          'Voulez-vous vraiment annuler le rendez-vous de ${appointment.displayName} ?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Non', style: AppTypography.button),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Annuler le rendez-vous', style: AppTypography.button),
          ),
        ],
      ),
    );

    if (confirm == true && appointment.id != null) {
      await controller.cancelAppointment(appointment.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppointmentsController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusXl,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.borderRadiusXl,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          AppSpacing.hGap16,

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      appointment.displayName,
                      style: AppTypography.h4,
                    ),
                    AppSpacing.hGap12,
                    StatusBadge.appointment(appointment.status),
                  ],
                ),
                AppSpacing.vGap4,
                Row(
                  children: [
                    if (appointment.patientPhone != null) ...[
                      const Icon(Icons.phone_rounded,
                          size: 13, color: AppColors.textSecondary),
                      AppSpacing.hGap4,
                      Text(
                        appointment.patientPhone!,
                        style: AppTypography.bodySmall,
                      ),
                      AppSpacing.hGap16,
                    ],
                    if (appointment.reason != null &&
                        appointment.reason!.trim().isNotEmpty) ...[
                      const Icon(Icons.medical_information_outlined,
                          size: 13, color: AppColors.textSecondary),
                      AppSpacing.hGap4,
                      Text(
                        'Motif : ${appointment.reason}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
                if (appointment.notes != null &&
                    appointment.notes!.trim().isNotEmpty) ...[
                  AppSpacing.vGap4,
                  Text(
                    'Notes : ${appointment.notes}',
                    style: AppTypography.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quick Action Buttons
          AppSpacing.hGap16,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mark Completed Button
              if (appointment.status != 'completed')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: AppSpacing.buttonPaddingSmall,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text('Terminé', style: AppTypography.buttonSmall),
                  onPressed: () {
                    if (appointment.id != null) {
                      controller.markCompleted(appointment.id!);
                    }
                  },
                ),

              AppSpacing.hGap8,

              // Mark No-Show Button
              if (appointment.status != 'no_show')
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.2),
                    padding: AppSpacing.buttonPaddingSmall,
                  ),
                  icon: const Icon(Icons.person_off_outlined, size: 16),
                  label: Text('Absent', style: AppTypography.buttonSmall),
                  onPressed: () {
                    if (appointment.id != null) {
                      controller.markNoShow(appointment.id!);
                    }
                  },
                ),

              // Reset to Booked if already finished
              if (appointment.status == 'completed' ||
                  appointment.status == 'no_show')
                TextButton.icon(
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: Text('Rétablir', style: AppTypography.buttonSmall),
                  onPressed: () {
                    if (appointment.id != null) {
                      controller.markBooked(appointment.id!);
                    }
                  },
                ),

              AppSpacing.hGap6,

              // Cancel Booking Button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textMuted, size: 18),
                tooltip: 'Annuler ce rendez-vous',
                onPressed: () => _confirmCancel(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
