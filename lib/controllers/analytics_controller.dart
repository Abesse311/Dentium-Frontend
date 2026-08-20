import 'package:get/get.dart';
import '../core/utils/date_formatter.dart';
import '../data/analytics_api.dart';
import '../models/analytics_models.dart';
import 'navigation_controller.dart';
import 'patients_controller.dart';

class AnalyticsController extends GetxController {
  static AnalyticsController get to => Get.find();

  final AnalyticsApi _api = AnalyticsApi();

  // Observable state
  final RxString selectedPeriod = 'this_month'.obs; // 'today' | 'this_week' | 'this_month' | 'this_year' | 'custom'
  final Rxn<DateTime> customStartDate = Rxn<DateTime>();
  final Rxn<DateTime> customEndDate = Rxn<DateTime>();
  final RxString granularity = 'daily'.obs; // 'daily' | 'monthly'

  final Rxn<ReportOverviewModel> overview = Rxn<ReportOverviewModel>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  /// Fetch consolidated analytics dataset
  Future<void> fetchAnalytics() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      String? startStr;
      String? endStr;

      if (selectedPeriod.value == 'custom') {
        if (customStartDate.value != null) {
          startStr = DateFormatter.toApiString(customStartDate.value!);
        }
        if (customEndDate.value != null) {
          endStr = DateFormatter.toApiString(customEndDate.value!);
        }
      }

      final data = await _api.getOverview(
        period: selectedPeriod.value,
        startDate: startStr,
        endDate: endStr,
        granularity: granularity.value,
        debtsLimit: 50,
      );

      overview.value = data;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  /// Change active period preset
  void setPeriod(String period) {
    if (selectedPeriod.value == period && period != 'custom') return;
    selectedPeriod.value = period;
    if (period != 'custom') {
      customStartDate.value = null;
      customEndDate.value = null;
    }
    // Auto-adjust default granularity
    if (period == 'this_year') {
      granularity.value = 'monthly';
    } else {
      granularity.value = 'daily';
    }
    fetchAnalytics();
  }

  /// Set custom date range
  void setCustomRange(DateTime start, DateTime end) {
    selectedPeriod.value = 'custom';
    customStartDate.value = start;
    customEndDate.value = end;
    // If range is longer than 60 days, default to monthly
    if (end.difference(start).inDays > 60) {
      granularity.value = 'monthly';
    } else {
      granularity.value = 'daily';
    }
    fetchAnalytics();
  }

  /// Toggle chart granularity between daily and monthly
  void setGranularity(String newGranularity) {
    if (granularity.value == newGranularity) return;
    granularity.value = newGranularity;
    fetchAnalytics();
  }

  /// Navigate to a debtor patient's record in the Patients view
  void navigateToPatient(int patientId) {
    if (Get.isRegistered<NavigationController>()) {
      // Index 1 corresponds to Patients view
      Get.find<NavigationController>().changeIndex(1);
    }

    if (Get.isRegistered<PatientsController>()) {
      final patientsCtrl = Get.find<PatientsController>();
      final patient = patientsCtrl.patients.firstWhereOrNull((p) => p.id == patientId);
      if (patient != null) {
        patientsCtrl.selectPatient(patient, refreshHistory: true);
      } else {
        patientsCtrl.fetchPatientHistory(patientId);
      }
    }
  }

  String get periodDisplayLabel {
    switch (selectedPeriod.value) {
      case 'today':
        return "Aujourd'hui";
      case 'this_week':
        return 'Cette semaine';
      case 'this_month':
        return 'Ce mois';
      case 'this_year':
        return 'Cette année';
      case 'custom':
        if (customStartDate.value != null && customEndDate.value != null) {
          return '${DateFormatter.formatShort(customStartDate.value!)} - ${DateFormatter.formatShort(customEndDate.value!)}';
        }
        return 'Période personnalisée';
      default:
        return 'Ce mois';
    }
  }
}
