import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../data/patients_api.dart';
import '../data/treatments_api.dart';
import '../models/appointment_model.dart';
import '../models/patient_model.dart';
import '../models/treatment_model.dart';
import '../models/treatment_type_model.dart';
import 'appointments_controller.dart';
import 'dashboard_controller.dart';
import 'navigation_controller.dart';
import 'patients_controller.dart';

class TreatmentsController extends GetxController {
  static TreatmentsController get to => Get.find();

  final TreatmentsApi _api = TreatmentsApi();
  final PatientsApi _patientsApi = PatientsApi();

  final RxList<PatientModel> patients = <PatientModel>[].obs;
  final Rxn<PatientModel> selectedPatient = Rxn<PatientModel>();
  
  // Upcoming appointment for the currently selected patient (if any)
  final Rx<AppointmentModel?> patientUpcomingAppointment = Rx<AppointmentModel?>(null);

  final RxList<TreatmentTypeModel> treatmentTypes = <TreatmentTypeModel>[].obs;
  final RxList<TreatmentModel> patientTreatments = <TreatmentModel>[].obs;
  final RxList<TreatmentModel> pendingTreatments = <TreatmentModel>[].obs;

  // Selected tooth (FDI 11-48, null if none selected)
  final RxnInt selectedToothNumber = RxnInt();

  // Multi-Tooth Selection Mode
  final RxBool isMultiSelectMode = false.obs;
  final RxSet<int> selectedToothNumbers = <int>{}.obs;

  /// Named groups currently active (e.g. 'Maxillaire (Haut)', 'Sagesses').
  /// Each entry maps a display label to its teeth list.
  final RxList<ToothSelectionGroup> activeGroups = <ToothSelectionGroup>[].obs;

  static const List<int> upperRightTeeth = [18, 17, 16, 15, 14, 13, 12, 11];
  static const List<int> upperLeftTeeth = [21, 22, 23, 24, 25, 26, 27, 28];
  static const List<int> lowerLeftTeeth = [31, 32, 33, 34, 35, 36, 37, 38];
  static const List<int> lowerRightTeeth = [48, 47, 46, 45, 44, 43, 42, 41];
  static const List<int> wisdomTeeth = [18, 28, 38, 48];

  final RxBool isLoading = false.obs;
  final RxBool isPendingLoading = false.obs;
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

      if (patients.isNotEmpty) {
        if (selectedPatient.value == null) {
          selectPatient(patients.first);
        } else {
          final found = patients.firstWhereOrNull((p) => p.id == selectedPatient.value?.id);
          if (found != null) {
            selectPatient(found);
          } else {
            selectPatient(patients.first);
          }
        }
      }
      fetchPendingTreatments();
    } finally {
      isTypesLoading.value = false;
    }
  }

  /// Fetch all pending (planned + in_progress) treatments across patients
  Future<void> fetchPendingTreatments() async {
    isPendingLoading.value = true;
    try {
      final results = await Future.wait([
        _api.getTreatments(status: 'planned').catchError((_) => <TreatmentModel>[]),
        _api.getTreatments(status: 'in_progress').catchError((_) => <TreatmentModel>[]),
      ]);
      final List<TreatmentModel> combined = [
        ...results[0],
        ...results[1],
      ];

      // Enrich with patient name/phone from local patient list if needed
      final enriched = combined.map((t) {
        if (t.patientName != null && t.patientName!.isNotEmpty) return t;
        final p = patients.firstWhereOrNull((pat) => pat.id == t.patientId);
        if (p != null) {
          return t.copyWith(patientName: p.fullName, patientPhone: p.phone);
        }
        return t;
      }).toList();

      pendingTreatments.value = enriched;
    } catch (_) {
      pendingTreatments.clear();
    } finally {
      isPendingLoading.value = false;
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
    selectedToothNumber.value = null; // reset single tooth selection
    selectedToothNumbers.clear(); // reset multi selection
    activeGroups.clear();
    if (patient != null && patient.id != null) {
      await Future.wait([
        fetchPatientTreatments(patient.id!),
        fetchPatientUpcomingAppointment(patient.id!),
      ]);
    } else {
      patientTreatments.clear();
      patientUpcomingAppointment.value = null;
    }
  }

  Future<void> fetchPatientUpcomingAppointment(int patientId) async {
    try {
      final appCtrl = Get.isRegistered<AppointmentsController>()
          ? Get.find<AppointmentsController>()
          : Get.put(AppointmentsController());
      final upcoming = await appCtrl.getUpcomingAppointmentForPatient(patientId);
      patientUpcomingAppointment.value = upcoming;
    } catch (_) {
      patientUpcomingAppointment.value = null;
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

  /// Toggle multi-selection mode on/off
  void toggleMultiSelectMode({bool? enable}) {
    isMultiSelectMode.value = enable ?? !isMultiSelectMode.value;
    if (isMultiSelectMode.value) {
      if (selectedToothNumber.value != null) {
        selectedToothNumbers.add(selectedToothNumber.value!);
      }
      selectedToothNumber.value = null;
    } else {
      selectedToothNumbers.clear();
      activeGroups.clear();
    }
  }

  /// Toggle a tooth in multi-selection mode (individual, not via a named group)
  void toggleToothMultiSelect(int toothNumber) {
    if (selectedToothNumbers.contains(toothNumber)) {
      selectedToothNumbers.remove(toothNumber);
      // If this tooth was part of an active group, explode that group into
      // individual teeth minus the removed one.
      final groupsContaining = activeGroups
          .where((g) => g.teeth.contains(toothNumber))
          .toList();
      for (final g in groupsContaining) {
        activeGroups.remove(g);
        // Re-add remaining teeth of that group as individual (they stay in
        // selectedToothNumbers; we just remove the group label).
      }
    } else {
      selectedToothNumbers.add(toothNumber);
    }
  }

  List<int> get allUpperTeeth => [...upperRightTeeth, ...upperLeftTeeth];
  List<int> get allLowerTeeth => [...lowerRightTeeth, ...lowerLeftTeeth];

  bool isUpperArchSelected() {
    return allUpperTeeth.every((t) => selectedToothNumbers.contains(t));
  }

  bool isLowerArchSelected() {
    return allLowerTeeth.every((t) => selectedToothNumbers.contains(t));
  }

  bool isWisdomTeethSelected() {
    return wisdomTeeth.every((t) => selectedToothNumbers.contains(t));
  }

  bool isQuadrantSelected(int quadrant) {
    final list = _getQuadrantTeeth(quadrant);
    return list.isNotEmpty && list.every((t) => selectedToothNumbers.contains(t));
  }

  List<int> _getQuadrantTeeth(int quadrant) {
    switch (quadrant) {
      case 1:
        return upperRightTeeth;
      case 2:
        return upperLeftTeeth;
      case 3:
        return lowerLeftTeeth;
      case 4:
        return lowerRightTeeth;
      default:
        return [];
    }
  }

  void _addOrRemoveGroup(ToothSelectionGroup group) {
    final isOn = group.teeth.every((t) => selectedToothNumbers.contains(t));
    if (isOn) {
      // Deactivate: remove teeth + remove group label
      selectedToothNumbers.removeAll(group.teeth);
      activeGroups.removeWhere((g) => g.label == group.label);
    } else {
      // Activate: add teeth + add group label (remove any sub-groups that overlap)
      selectedToothNumbers.addAll(group.teeth);
      // Remove any existing groups fully contained within the new group's teeth
      activeGroups.removeWhere(
        (g) => g.teeth.every((t) => group.teeth.contains(t)),
      );
      if (!activeGroups.any((g) => g.label == group.label)) {
        activeGroups.add(group);
      }
    }
  }

  void toggleUpperArch() {
    _addOrRemoveGroup(ToothSelectionGroup(
      label: 'Maxillaire (Haut)',
      teeth: allUpperTeeth,
    ));
  }

  void toggleLowerArch() {
    _addOrRemoveGroup(ToothSelectionGroup(
      label: 'Mandibule (Bas)',
      teeth: allLowerTeeth,
    ));
  }

  void toggleWisdomTeeth() {
    _addOrRemoveGroup(ToothSelectionGroup(
      label: 'Dents de sagesse',
      teeth: wisdomTeeth,
    ));
  }

  void toggleQuadrant(int quadrant) {
    final labels = {1: 'Q1 (H.D)', 2: 'Q2 (H.G)', 3: 'Q3 (B.G)', 4: 'Q4 (B.D)'};
    _addOrRemoveGroup(ToothSelectionGroup(
      label: labels[quadrant] ?? 'Q$quadrant',
      teeth: _getQuadrantTeeth(quadrant),
    ));
  }

  void clearMultiSelection() {
    selectedToothNumbers.clear();
    activeGroups.clear();
  }

  /// Remove a named group chip and deselect all its teeth
  void removeGroup(ToothSelectionGroup group) {
    selectedToothNumbers.removeAll(group.teeth);
    activeGroups.removeWhere((g) => g.label == group.label);
  }

  /// Compute chips to show in the multi-panel:
  /// – one chip per active named group (covering all its teeth)
  /// – one chip per individual tooth not already covered by a named group
  List<SelectionChip> get selectionChips {
    final coveredByGroup = <int>{};
    for (final g in activeGroups) {
      coveredByGroup.addAll(g.teeth);
    }
    final groupChips = activeGroups.map((g) => SelectionChip.group(g)).toList();
    final individualChips = selectedToothNumbers
        .where((t) => !coveredByGroup.contains(t))
        .toList()
      ..sort();
    return [
      ...groupChips,
      ...individualChips.map((t) => SelectionChip.tooth(t)),
    ];
  }

  /// Select or unselect a single tooth in the Odontogram
  void selectTooth(int? toothNumber) {
    if (isMultiSelectMode.value) {
      if (toothNumber != null) toggleToothMultiSelect(toothNumber);
      return;
    }
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

  /// General care types catalog (not tied to a specific tooth)
  List<TreatmentTypeModel> get generalTreatmentTypes {
    return treatmentTypes.where((t) => t.isGeneral).toList();
  }

  /// Per-tooth care types catalog (tied to a specific FDI tooth)
  List<TreatmentTypeModel> get perToothTreatmentTypes {
    return treatmentTypes.where((t) => t.isPerTooth).toList();
  }

  /// Add a new treatment
  Future<bool> createTreatment(TreatmentModel treatment) async {
    isLoading.value = true;
    try {
      final created = await _api.createTreatment(treatment);
      patientTreatments.insert(0, created);
      fetchPendingTreatments();

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      if (Get.isRegistered<PatientsController>()) {
        final patientsCtrl = Get.find<PatientsController>();
        if (patientsCtrl.selectedPatient.value?.id == treatment.patientId) {
          patientsCtrl.fetchPatientHistory(treatment.patientId);
        }
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

  /// Add multiple treatments in bulk across multiple teeth
  Future<bool> createTreatmentsBulk({
    required int patientId,
    required int treatmentTypeId,
    required List<int> toothNumbers,
    String status = 'completed',
    double? price,
    String? treatmentDate,
    String? notes,
    int? appointmentId,
  }) async {
    if (toothNumbers.isEmpty) return false;
    isLoading.value = true;
    try {
      final createdList = await _api.createTreatmentsBulk(
        patientId: patientId,
        treatmentTypeId: treatmentTypeId,
        toothNumbers: toothNumbers,
        status: status,
        price: price,
        treatmentDate: treatmentDate,
        notes: notes,
        appointmentId: appointmentId,
      );

      for (final created in createdList.reversed) {
        patientTreatments.insert(0, created);
      }
      fetchPendingTreatments();

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      if (Get.isRegistered<PatientsController>()) {
        final patientsCtrl = Get.find<PatientsController>();
        if (patientsCtrl.selectedPatient.value?.id == patientId) {
          patientsCtrl.fetchPatientHistory(patientId);
        }
      }

      selectedToothNumbers.clear();

      Get.snackbar(
        'Actes groupés enregistrés',
        '${createdList.length} actes enregistrés avec succès.',
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
      fetchPendingTreatments();

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      if (Get.isRegistered<PatientsController>()) {
        final patientsCtrl = Get.find<PatientsController>();
        if (patientsCtrl.selectedPatient.value?.id == treatment.patientId) {
          patientsCtrl.fetchPatientHistory(treatment.patientId);
        }
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
      final removed = patientTreatments.firstWhereOrNull((t) => t.id == id);
      await _api.deleteTreatment(id);
      patientTreatments.removeWhere((t) => t.id == id);
      fetchPendingTreatments();

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      if (Get.isRegistered<PatientsController>()) {
        final patientsCtrl = Get.find<PatientsController>();
        final patientId = removed?.patientId ?? selectedPatient.value?.id;
        if (patientId != null && patientsCtrl.selectedPatient.value?.id == patientId) {
          patientsCtrl.fetchPatientHistory(patientId);
        }
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

  /// Delete multiple treatments at once
  Future<void> deleteTreatments(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      for (final id in ids) {
        await _api.deleteTreatment(id);
        patientTreatments.removeWhere((t) => t.id == id);
      }
      fetchPendingTreatments();

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      if (Get.isRegistered<PatientsController>()) {
        final patientsCtrl = Get.find<PatientsController>();
        final patientId = selectedPatient.value?.id;
        if (patientId != null && patientsCtrl.selectedPatient.value?.id == patientId) {
          patientsCtrl.fetchPatientHistory(patientId);
        }
      }

      Get.snackbar(
        'Actes supprimés',
        '${ids.length} acte${ids.length > 1 ? 's ont été retirés' : ' a été retiré'} du dossier.',
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
    fetchPendingTreatments();
  }

  /// Quick-update status of multiple treatments
  Future<void> updateMultipleTreatmentsStatus(
    List<TreatmentModel> treatments,
    String newStatus,
  ) async {
    for (final t in treatments) {
      if (t.id != null) {
        final updated = t.copyWith(status: newStatus);
        await _api.updateTreatment(t.id!, updated);
        final index = patientTreatments.indexWhere((item) => item.id == t.id);
        if (index != -1) {
          patientTreatments[index] = updated;
        }
      }
    }
    fetchPendingTreatments();

    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().fetchDashboardData();
    }

    if (Get.isRegistered<PatientsController>()) {
      final patientsCtrl = Get.find<PatientsController>();
      final patientId = selectedPatient.value?.id;
      if (patientId != null && patientsCtrl.selectedPatient.value?.id == patientId) {
        patientsCtrl.fetchPatientHistory(patientId);
      }
    }

    Get.snackbar(
      'Statut mis à jour',
      'Le statut de ${treatments.length} acte${treatments.length > 1 ? 's' : ''} a été modifié.',
      backgroundColor: AppColors.successLight,
      colorText: AppColors.success,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Navigate directly from anywhere in the app to a patient's odontogram
  Future<void> openPatientInOdontogram(int patientId, {int? toothNumber}) async {
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().selectedIndex.value = 3;
    }

    PatientModel? patient = patients.firstWhereOrNull((p) => p.id == patientId);
    if (patient == null) {
      try {
        final list = await _patientsApi.getPatients();
        patients.value = list;
        patient = list.firstWhereOrNull((p) => p.id == patientId);
      } catch (_) {}
    }

    if (patient != null) {
      await selectPatient(patient);
      if (toothNumber != null) {
        selectedToothNumber.value = toothNumber;
      }
    }
  }
}

/// A named group of teeth (e.g. "Maxillaire (Haut)" covering teeth 11-18, 21-28).
class ToothSelectionGroup {
  final String label;
  final List<int> teeth;

  const ToothSelectionGroup({required this.label, required this.teeth});
}

/// A chip to render in the multi-tooth panel – either a named group or a single tooth.
class SelectionChip {
  final String label;
  final bool isGroup;
  final ToothSelectionGroup? group;
  final int? tooth;

  const SelectionChip._({
    required this.label,
    required this.isGroup,
    this.group,
    this.tooth,
  });

  factory SelectionChip.group(ToothSelectionGroup g) => SelectionChip._(
        label: g.label,
        isGroup: true,
        group: g,
      );

  factory SelectionChip.tooth(int t) => SelectionChip._(
        label: 'Dent $t',
        isGroup: false,
        tooth: t,
      );
}



