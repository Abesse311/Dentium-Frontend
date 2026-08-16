import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../data/settings_api.dart';
import '../models/clinic_settings_model.dart';
import '../models/treatment_type_model.dart';

class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  final SettingsApi _api = SettingsApi();

  final Rxn<ClinicSettingsModel> settings = Rxn<ClinicSettingsModel>();
  final RxList<TreatmentTypeModel> treatmentTypes = <TreatmentTypeModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.getSettings().catchError(
              (_) => const ClinicSettingsModel(clinicName: 'Cabinet Dentaire'),
            ),
        _api.getTreatmentTypes().catchError((_) => <TreatmentTypeModel>[]),
      ]);

      settings.value = results[0] as ClinicSettingsModel;
      treatmentTypes.value = results[1] as List<TreatmentTypeModel>;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update clinic contact info & advisory limit
  Future<bool> saveClinicSettings(ClinicSettingsModel newSettings) async {
    isSaving.value = true;
    try {
      final updated = await _api.updateSettings(newSettings);
      settings.value = updated;
      Get.snackbar(
        'Paramètres enregistrés',
        'Les informations du cabinet ont été mises à jour.',
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
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Save or update a treatment type
  Future<bool> saveTreatmentType(TreatmentTypeModel type) async {
    isSaving.value = true;
    try {
      if (type.id != null) {
        final updated = await _api.updateTreatmentType(type.id!, type);
        final idx = treatmentTypes.indexWhere((t) => t.id == type.id);
        if (idx != -1) treatmentTypes[idx] = updated;
      } else {
        final created = await _api.createTreatmentType(type);
        treatmentTypes.add(created);
      }
      Get.snackbar(
        'Catalogue mis à jour',
        'L\'acte "${type.name}" a été enregistré.',
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
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Delete a treatment type
  Future<void> deleteTreatmentType(int id) async {
    try {
      await _api.deleteTreatmentType(id);
      treatmentTypes.removeWhere((t) => t.id == id);
      Get.snackbar(
        'Acte supprimé',
        'L\'acte a été retiré du catalogue.',
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
}
