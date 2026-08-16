import 'package:get/get.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../core/utils/date_formatter.dart';
import '../data/appointments_api.dart';
import '../data/dashboard_api.dart';
import '../models/appointment_model.dart';
import '../models/dashboard_metrics_model.dart';
import 'appointments_controller.dart';

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();

  final DashboardApi _dashboardApi = DashboardApi();
  final AppointmentsApi _appointmentsApi = AppointmentsApi();

  final Rxn<DashboardMetricsModel> metrics = Rxn<DashboardMetricsModel>();
  final RxList<AppointmentModel> todayAppointments = <AppointmentModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final todayStr = DateFormatter.toApiString(DateTime.now());
      final results = await Future.wait([
        _dashboardApi.getTodayMetrics().catchError(
              (_) => const DashboardMetricsModel(),
            ),
        _appointmentsApi.getAppointmentsForDate(todayStr).catchError(
              (_) => <AppointmentModel>[],
            ),
      ]);

      metrics.value = results[0] as DashboardMetricsModel;
      todayAppointments.value = results[1] as List<AppointmentModel>;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAppointmentCompleted(int id) async {
    try {
      final updated = await _appointmentsApi.updateStatus(id, 'completed');
      final idx = todayAppointments.indexWhere((a) => a.id == id);
      if (idx != -1) {
        todayAppointments[idx] = updated;
      }
      fetchDashboardData(); // Refresh KPI counts
      if (Get.isRegistered<AppointmentsController>()) {
        Get.find<AppointmentsController>().loadData();
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

  Future<void> markAppointmentNoShow(int id) async {
    try {
      final updated = await _appointmentsApi.updateStatus(id, 'no_show');
      final idx = todayAppointments.indexWhere((a) => a.id == id);
      if (idx != -1) {
        todayAppointments[idx] = updated;
      }
      fetchDashboardData();
      if (Get.isRegistered<AppointmentsController>()) {
        Get.find<AppointmentsController>().loadData();
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
}






