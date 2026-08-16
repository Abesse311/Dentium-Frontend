import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../data/patients_api.dart';
import '../data/treatments_api.dart';
import '../models/patient_model.dart';
import '../models/treatment_model.dart';
import '../models/treatment_type_model.dart';
import 'dashboard_controller.dart';

class TreatmentsController extends GetxController {
  static TreatmentsController get to => Get.find();

  final TreatmentsApi _api = TreatmentsApi();
  final PatientsApi _patientsApi = PatientsApi();

  final RxList<PatientModel> patients = <PatientModel>[].obs;
  final Rxn<PatientModel> selectedPatient = Rxn<PatientModel>();
  final RxList<TreatmentTypeModel> treatmentTypes = <TreatmentTypeModel>[].obs;
  final RxList<TreatmentModel> patientTreatments = <TreatmentModel>[].obs;

  // Selected tooth (FDI 11-48, null if none selected)
  final RxnInt selectedToothNumber = RxnInt();

  final RxBool isLoading = false.obs;
  final RxBool isTypesLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isTypesLoading.value = true;
    try {
      final results = await Future.wait([
        _patientsApi.getPatients().catchError((_) => <PatientModel>[]),
        _api.getTreatmentTypes().catchError((_) => <TreatmentTypeModel>[]),
      ]);
      patients.value = results[0] as List<PatientModel>;
      treatmentTypes.value = results[1] as List<TreatmentTypeModel>;

      if (patients.isNotEmpty && selectedPatient.value == null) {
        selectPatient(patients.first);
      }
    } finally {
      isTypesLoading.value = false;
    }
  }

  Future<void> fetchTreatmentTypes() async {
    try {
      final list = await _api.getTreatmentTypes();
      treatmentTypes.value = list;
    } catch (_) {}
  }

  /// Select active patient and reload their dental chart treatments
  Future<void> selectPatient(PatientModel? patient) async {
    selectedPatient.value = patient;
    selectedToothNumber.value = null; // reset tooth selection
    if (patient != null && patient.id != null) {
      await fetchPatientTreatments(patient.id!);
    } else {
      patientTreatments.clear();
    }
  }

  Future<void> fetchPatientTreatments(int patientId) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _api.getPatientTreatments(patientId);
      patientTreatments.value = list;
    } catch (e) {
      errorMessage.value = e.toString();
      patientTreatments.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Select or unselect a tooth in the Odontogram
  void selectTooth(int? toothNumber) {
    if (selectedToothNumber.value == toothNumber) {
      selectedToothNumber.value = null;
    } else {
      selectedToothNumber.value = toothNumber;
    }
  }

  /// Map of toothNumber -> latest treatment status ('completed', 'in_progress', 'planned', 'healthy')
  Map<int, String> get toothStatusMap {
    final Map<int, String> map = {};
    for (final t in patientTreatments) {
      if (t.toothNumber != null) {
        final tooth = t.toothNumber!;
        // Prioritize in_progress > planned > completed if multiple exist
        final current = map[tooth];
        if (current == null) {
          map[tooth] = t.status.toLowerCase();
        } else if (t.status == 'in_progress') {
          map[tooth] = 'in_progress';
        } else if (t.status == 'planned' && current == 'completed') {
          map[tooth] = 'planned';
        }
      }
    }
    return map;
  }

  /// Treatments specific to the currently selected tooth
  List<TreatmentModel> get selectedToothTreatments {
    final tooth = selectedToothNumber.value;
    if (tooth == null) return [];
    return patientTreatments.where((t) => t.toothNumber == tooth).toList();
  }

  /// Treatments not linked to a specific tooth (General treatments)
  List<TreatmentModel> get generalTreatments {
    return patientTreatments.where((t) => t.isGeneral).toList();
  }

  /// Add a new treatment
  Future<bool> createTreatment(TreatmentModel treatment) async {
    isLoading.value = true;
    try {
      final created = await _api.createTreatment(treatment);
      patientTreatments.insert(0, created);

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      Get.snackbar(
        'Soin enregistré',
        'Le traitement a été ajouté au dossier.',
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        icon: const Icon(Icons.error_outline_rounded, color: AppColors.danger),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing treatment
  Future<bool> updateTreatment(int id, TreatmentModel treatment) async {
    isLoading.value = true;
    try {
      final updated = await _api.updateTreatment(id, treatment);
      final index = patientTreatments.indexWhere((t) => t.id == id);
      if (index != -1) {
        patientTreatments[index] = updated;
      }

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      Get.snackbar(
        'Soin mis à jour',
        'Le traitement a été modifié.',
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        icon: const Icon(Icons.error_outline_rounded, color: AppColors.danger),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a treatment
  Future<void> deleteTreatment(int id) async {
    try {
      await _api.deleteTreatment(id);
      patientTreatments.removeWhere((t) => t.id == id);

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      Get.snackbar(
        'Soin supprimé',
        'Le traitement a été retiré du dossier.',
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
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

  /// Quick-update only the status of a treatment (planned → in_progress → completed)
  Future<void> updateTreatmentStatus(TreatmentModel treatment, String newStatus) async {
    if (treatment.id == null) return;
    final updated = treatment.copyWith(status: newStatus);
    await updateTreatment(treatment.id!, updated);
  }
}







