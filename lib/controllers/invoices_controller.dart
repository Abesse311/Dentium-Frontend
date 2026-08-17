import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../data/invoices_api.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import 'dashboard_controller.dart';
import 'patients_controller.dart';

class InvoicesController extends GetxController {
  static InvoicesController get to => Get.find();

  final InvoicesApi _api = InvoicesApi();

  final RxList<InvoiceModel> invoices = <InvoiceModel>[].obs;
  final RxList<InvoiceModel> filteredInvoices = <InvoiceModel>[].obs;
  final Rxn<InvoiceModel> selectedInvoice = Rxn<InvoiceModel>();

  final RxString statusFilter = 'all'.obs; // 'all' | 'unpaid' | 'partially_paid' | 'paid'
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDetailLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _api.getInvoices();
      invoices.value = list;
      _applyFilters();

      if (selectedInvoice.value != null) {
        final found = list.firstWhereOrNull(
          (inv) => inv.id == selectedInvoice.value?.id,
        );
        if (found != null) {
          selectInvoice(found);
        } else if (list.isNotEmpty) {
          selectInvoice(list.first);
        } else {
          selectedInvoice.value = null;
        }
      } else if (list.isNotEmpty && selectedInvoice.value == null) {
        selectInvoice(list.first);
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void selectInvoice(InvoiceModel? invoice, {bool refreshDetail = true}) {
    selectedInvoice.value = invoice;
    if (invoice != null && invoice.id != null && refreshDetail) {
      fetchInvoiceDetail(invoice.id!);
    }
  }

  Future<void> fetchInvoiceDetail(int id) async {
    isDetailLoading.value = true;
    try {
      final detail = await _api.getInvoice(id);
      selectedInvoice.value = detail;

      // Update in main list as well
      final idx = invoices.indexWhere((inv) => inv.id == id);
      if (idx != -1) {
        invoices[idx] = detail;
        _applyFilters();
      }
    } catch (_) {
      // Keep existing invoice data
    } finally {
      isDetailLoading.value = false;
    }
  }

  void setFilter(String filter) {
    statusFilter.value = filter;
    _applyFilters();
  }

  void search(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void _applyFilters() {
    final q = searchQuery.value.trim().toLowerCase();
    final filter = statusFilter.value.toLowerCase();

    filteredInvoices.value = invoices.where((inv) {
      final matchesStatus = filter == 'all' || inv.status.toLowerCase() == filter;
      final matchesSearch = q.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(q) ||
          inv.displayPatientName.toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  /// Create a new invoice
  Future<bool> createInvoice({
    required int patientId,
    required List<int> treatmentIds,
    List<Map<String, dynamic>>? customItems,
  }) async {
    isLoading.value = true;
    try {
      final created = await _api.createInvoice(
        patientId: patientId,
        treatmentIds: treatmentIds,
        customItems: customItems,
      );
      invoices.insert(0, created);
      _applyFilters();
      selectInvoice(created);

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      if (Get.isRegistered<PatientsController>()) {
        final patientsCtrl = Get.find<PatientsController>();
        if (patientsCtrl.selectedPatient.value?.id == patientId) {
          patientsCtrl.fetchPatientHistory(patientId);
        }
      }

      Get.snackbar(
        'Facture créée',
        'Facture ${created.invoiceNumber} générée avec succès.',
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur de facturation',
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

  /// Add a payment
  Future<bool> addPayment(int invoiceId, PaymentModel payment) async {
    isLoading.value = true;
    try {
      await _api.addPayment(invoiceId, payment);
      await fetchInvoiceDetail(invoiceId);

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      if (Get.isRegistered<PatientsController>()) {
        final patientsCtrl = Get.find<PatientsController>();
        final patientId = selectedInvoice.value?.patientId;
        if (patientId != null && patientsCtrl.selectedPatient.value?.id == patientId) {
          patientsCtrl.fetchPatientHistory(patientId);
        }
      }

      Get.snackbar(
        'Paiement enregistré',
        'Le règlement de ${payment.formattedAmount} a été comptabilisé.',
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur de paiement',
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

  /// Delete an invoice
  Future<void> deleteInvoice(int invoiceId) async {
    try {
      final removed = invoices.firstWhereOrNull((i) => i.id == invoiceId);
      await _api.deleteInvoice(invoiceId);
      invoices.removeWhere((i) => i.id == invoiceId);
      _applyFilters();
      if (selectedInvoice.value?.id == invoiceId) {
        selectedInvoice.value =
            filteredInvoices.isNotEmpty ? filteredInvoices.first : null;
      }
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboardData();
      }

      if (Get.isRegistered<PatientsController>()) {
        final patientsCtrl = Get.find<PatientsController>();
        final patientId = removed?.patientId ?? selectedInvoice.value?.patientId;
        if (patientId != null && patientsCtrl.selectedPatient.value?.id == patientId) {
          patientsCtrl.fetchPatientHistory(patientId);
        }
      }
      Get.snackbar(
        'Facture supprimée',
        'La facture a été supprimée.',
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






