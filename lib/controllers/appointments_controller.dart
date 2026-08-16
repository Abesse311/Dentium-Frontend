import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../core/utils/date_formatter.dart';
import '../data/appointments_api.dart';
import '../models/appointment_model.dart';
import '../models/day_capacity_model.dart';
import 'dashboard_controller.dart';

class AppointmentsController extends GetxController {
  static AppointmentsController get to => Get.find();

  final AppointmentsApi _api = AppointmentsApi();

  // Selected active day
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Monday of the currently viewed week
  late final Rx<DateTime> weekStartDate;

  // Capacity indicators for the 7 days of the viewed week
  final RxList<DayCapacityModel> weekCapacity = <DayCapacityModel>[].obs;

  // Appointments for the selected day
  final RxList<AppointmentModel> dayAppointments = <AppointmentModel>[].obs;
  final RxList<AppointmentModel> filteredAppointments = <AppointmentModel>[].obs;

  final RxString statusFilter = 'all'.obs; // 'all' | 'booked' | 'completed' | 'no_show'
  final RxBool isLoadingAppointments = false.obs;
  final RxBool isLoadingCapacity = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    weekStartDate = DateTime(monday.year, monday.month, monday.day).obs;

    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([
      fetchWeekCapacity(),
      fetchDayAppointments(),
    ]);
  }

  /// Select a date and reload its appointments
  void selectDate(DateTime date) {
    selectedDate.value = DateTime(date.year, date.month, date.day);

    // If selected date is outside current week range, shift week
    final monday = selectedDate.value.subtract(
      Duration(days: selectedDate.value.weekday - 1),
    );
    final normalizedMonday = DateTime(monday.year, monday.month, monday.day);

    if (normalizedMonday != weekStartDate.value) {
      weekStartDate.value = normalizedMonday;
      fetchWeekCapacity();
    }

    fetchDayAppointments();
  }

  /// Shift week forward by 7 days
  void nextWeek() {
    weekStartDate.value = weekStartDate.value.add(const Duration(days: 7));
    // If selectedDate is not in the new week, pick the Monday of the new week
    if (selectedDate.value.isBefore(weekStartDate.value) ||
        selectedDate.value.isAfter(weekStartDate.value.add(const Duration(days: 6)))) {
      selectedDate.value = weekStartDate.value;
    }
    loadData();
  }

  /// Shift week backward by 7 days
  void previousWeek() {
    weekStartDate.value = weekStartDate.value.subtract(const Duration(days: 7));
    if (selectedDate.value.isBefore(weekStartDate.value) ||
        selectedDate.value.isAfter(weekStartDate.value.add(const Duration(days: 6)))) {
      selectedDate.value = weekStartDate.value;
    }
    loadData();
  }

  /// Jump back to today
  void goToToday() {
    final now = DateTime.now();
    selectDate(DateTime(now.year, now.month, now.day));
  }

  /// Fetch capacity for current week from API
  Future<void> fetchWeekCapacity() async {
    isLoadingCapacity.value = true;
    try {
      final startStr = DateFormatter.toApiString(weekStartDate.value);
      final list = await _api.getWeekCapacity(startStr, days: 7);
      weekCapacity.value = list;
    } catch (_) {
      // If capacity endpoint fails, generate default fallback cards
      final fallback = List.generate(7, (i) {
        final d = weekStartDate.value.add(Duration(days: i));
        return DayCapacityModel(
          date: DateFormatter.toApiString(d),
          bookedCount: 0,
          limit: 30,
        );
      });
      weekCapacity.value = fallback;
    } finally {
      isLoadingCapacity.value = false;
    }
  }

  /// Fetch appointments for selected day
  Future<void> fetchDayAppointments() async {
    isLoadingAppointments.value = true;
    errorMessage.value = '';
    try {
      final dateStr = DateFormatter.toApiString(selectedDate.value);
      final list = await _api.getAppointmentsForDate(dateStr);
      dayAppointments.value = list;
      _applyFilter();
    } catch (e) {
      errorMessage.value = e.toString();
      dayAppointments.clear();
      filteredAppointments.clear();
    } finally {
      isLoadingAppointments.value = false;
    }
  }

  /// Filter appointments by status tab
  void setFilter(String filter) {
    statusFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    if (statusFilter.value == 'all') {
      filteredAppointments.value = List.from(dayAppointments);
    } else {
      filteredAppointments.value = dayAppointments.where((a) {
        return a.status.toLowerCase() == statusFilter.value.toLowerCase();
      }).toList();
    }
  }

  /// Quick action: Mark appointment as Completed
  Future<void> markCompleted(int appointmentId) async {
    await _updateAppointmentStatus(appointmentId, 'completed', 'Rendez-vous marqué comme terminé.');
  }

  /// Quick action: Mark appointment as No-show
  Future<void> markNoShow(int appointmentId) async {
    await _updateAppointmentStatus(appointmentId, 'no_show', 'Patient marqué comme absent.');
  }

  /// Quick action: Mark appointment as Booked
  Future<void> markBooked(int appointmentId) async {
    await _updateAppointmentStatus(appointmentId, 'booked', 'Rendez-vous réinitialisé à réservé.');
  }

  /// Fetch appointments for a specific date
  Future<List<AppointmentModel>> getAppointmentsForDate(String dateStr) async {
    try {
      return await _api.getAppointmentsForDate(dateStr);
    } catch (_) {
      return [];
    }
  }

  Future<void> _updateAppointmentStatus(
    int appointmentId,
    String newStatus,
    String successMsg,
  ) async {
    try {
      final updated = await _api.updateStatus(appointmentId, newStatus);
      final index = dayAppointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        dayAppointments[index] = updated;
        _applyFilter();
      }
      Get.snackbar(
        'Statut mis à jour',
        successMsg,
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      fetchWeekCapacity(); // refresh capacity count
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Cancel and delete appointment
  Future<void> cancelAppointment(int appointmentId) async {
    try {
      await _api.deleteAppointment(appointmentId);
      dayAppointments.removeWhere((a) => a.id == appointmentId);
      _applyFilter();
      Get.snackbar(
        'Rendez-vous annulé',
        'Le rendez-vous a été supprimé du planning.',
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
      fetchWeekCapacity();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Create a new booking
  Future<bool> bookAppointment({
    required int patientId,
    required DateTime date,
    String? reason,
    String? notes,
  }) async {
    try {
      final dateStr = DateFormatter.toApiString(date);
      final appointment = AppointmentModel(
        patientId: patientId,
        appointmentDate: dateStr,
        status: 'booked',
        reason: reason,
        notes: notes,
      );
      final created = await _api.createAppointment(appointment);

      // If booked for the currently selected date, add to list
      if (DateFormatter.toApiString(selectedDate.value) == dateStr) {
        dayAppointments.add(created);
        _applyFilter();
      }

      fetchWeekCapacity();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      Get.snackbar(
        'Rendez-vous confirmé',
        'Réservation enregistrée pour le ${DateFormatter.formatMedium(date)}.',
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      final msg = e.toString();
      final isDuplicate = msg.contains('409') ||
          msg.toLowerCase().contains('déjà') ||
          msg.toLowerCase().contains('already') ||
          msg.toLowerCase().contains('conflict');
      Get.snackbar(
        isDuplicate ? 'Rendez-vous existant' : 'Erreur de réservation',
        isDuplicate
            ? 'Ce patient a déjà un rendez-vous prévu pour cette date.'
            : msg,
        backgroundColor: isDuplicate ? AppColors.warningLight : AppColors.dangerLight,
        colorText: isDuplicate ? AppColors.warningDark : AppColors.danger,
        icon: Icon(
          isDuplicate ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
          color: isDuplicate ? AppColors.warning : AppColors.danger,
        ),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }
}






