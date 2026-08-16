import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../data/patients_api.dart';
import '../models/patient_invoice_model.dart';
import '../models/patient_model.dart';
import '../models/patient_treatment_model.dart';

class PatientsController extends GetxController {
  static PatientsController get to => Get.find();

  final PatientsApi _api = PatientsApi();

  // Observable state
  final RxList<PatientModel> patients = <PatientModel>[].obs;
  final RxList<PatientModel> filteredPatients = <PatientModel>[].obs;
  final Rxn<PatientModel> selectedPatient = Rxn<PatientModel>();
  final RxList<PatientTreatmentModel> patientTreatments =
      <PatientTreatmentModel>[].obs;
  final RxList<PatientInvoiceModel> patientInvoices =
      <PatientInvoiceModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isHistoryLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPatients();
  }

  /// Load all patients
  Future<void> fetchPatients() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _api.getPatients();
      patients.value = list;
      _applySearch();

      // If a patient was previously selected, refresh selection
      if (selectedPatient.value != null) {
        final found = list.firstWhereOrNull(
          (p) => p.id == selectedPatient.value?.id,
        );
        if (found != null) {
          selectPatient(found, refreshHistory: false);
        } else if (list.isNotEmpty) {
          selectPatient(list.first);
        } else {
          selectedPatient.value = null;
        }
      } else if (list.isNotEmpty && selectedPatient.value == null) {
        selectPatient(list.first);
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Live search filter by name or phone
  void search(String query) {
    searchQuery.value = query;
    _applySearch();
  }

  void _applySearch() {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      filteredPatients.value = List.from(patients);
    } else {
      filteredPatients.value = patients.where((p) {
        final nameMatch = p.fullName.toLowerCase().contains(q);
        final phoneMatch = p.phone?.toLowerCase().contains(q) ?? false;
        return nameMatch || phoneMatch;
      }).toList();
    }
  }

  /// Select patient to view details and load their history
  void selectPatient(PatientModel? patient, {bool refreshHistory = true}) {
    selectedPatient.value = patient;
    if (patient != null && patient.id != null && refreshHistory) {
      fetchPatientHistory(patient.id!);
    } else if (patient == null) {
      patientTreatments.clear();
      patientInvoices.clear();
    }
  }

  /// Fetch treatments and invoices history for the selected patient
  Future<void> fetchPatientHistory(int patientId) async {
    isHistoryLoading.value = true;
    try {
      final results = await Future.wait([
        _api.getPatientTreatments(patientId).catchError((_) => <PatientTreatmentModel>[]),
        _api.getPatientInvoices(patientId).catchError((_) => <PatientInvoiceModel>[]),
      ]);
      patientTreatments.value = results[0] as List<PatientTreatmentModel>;
      patientInvoices.value = results[1] as List<PatientInvoiceModel>;
    } catch (_) {
      patientTreatments.clear();
      patientInvoices.clear();
    } finally {
      isHistoryLoading.value = false;
    }
  }

  /// Create new patient
  Future<bool> createPatient(PatientModel patient) async {
    isLoading.value = true;
    try {
      final created = await _api.createPatient(patient);
      patients.insert(0, created);
      _applySearch();
      selectPatient(created);
      Get.snackbar(
        'Succès',
        'Patient ${created.fullName} ajouté avec succès.',
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

  /// Update existing patient
  Future<bool> updatePatient(int id, PatientModel patient) async {
    isLoading.value = true;
    try {
      final updated = await _api.updatePatient(id, patient);
      final index = patients.indexWhere((p) => p.id == id);
      if (index != -1) {
        patients[index] = updated;
      }
      _applySearch();
      if (selectedPatient.value?.id == id) {
        selectedPatient.value = updated;
      }
      Get.snackbar(
        'Succès',
        'Informations de ${updated.fullName} mises à jour.',
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

  /// Delete patient
  Future<bool> deletePatient(int id) async {
    isLoading.value = true;
    try {
      await _api.deletePatient(id);
      final deleted = patients.firstWhereOrNull((p) => p.id == id);
      patients.removeWhere((p) => p.id == id);
      _applySearch();
      if (selectedPatient.value?.id == id) {
        selectedPatient.value = filteredPatients.isNotEmpty
            ? filteredPatients.first
            : null;
      }
      Get.snackbar(
        'Suppression',
        'Le dossier patient a été supprimé.',
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
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
}
