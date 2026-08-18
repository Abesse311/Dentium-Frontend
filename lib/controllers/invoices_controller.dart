import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../core/utils/date_formatter.dart';
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
  final RxString datePreset = 'all'.obs; // 'all' | 'today' | 'week' | 'month' | 'custom_single' | 'custom_range'
  final Rxn<DateTime> filterDate = Rxn<DateTime>(); // Exact single date
  final Rxn<DateTime> filterDateFrom = Rxn<DateTime>(); // Range start date
  final Rxn<DateTime> filterDateTo = Rxn<DateTime>(); // Range end date

  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDetailLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  Future<void> fetchInvoices({int? patientId}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      String? dateParam;
      String? dateFromParam;
      String? dateToParam;

      if (filterDate.value != null) {
        dateParam = DateFormatter.toApiString(filterDate.value!);
      } else {
        if (filterDateFrom.value != null) {
          dateFromParam = DateFormatter.toApiString(filterDateFrom.value!);
        }
        if (filterDateTo.value != null) {
          dateToParam = DateFormatter.toApiString(filterDateTo.value!);
        }
      }

      final list = await _api.getInvoices(
        patientId: patientId,
        status: statusFilter.value != 'all' ? statusFilter.value : null,
        date: dateParam,
        dateFrom: dateFromParam,
        dateTo: dateToParam,
      );
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
      } else if (list.isEmpty) {
        selectedInvoice.value = null;
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
    fetchInvoices();
  }

  void setDatePreset(String preset) {
    final now = DateTime.now();
    datePreset.value = preset;

    if (preset == 'all') {
      filterDate.value = null;
      filterDateFrom.value = null;
      filterDateTo.value = null;
    } else if (preset == 'today') {
      filterDate.value = DateTime(now.year, now.month, now.day);
      filterDateFrom.value = null;
      filterDateTo.value = null;
    } else if (preset == 'week') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      filterDate.value = null;
      filterDateFrom.value = DateTime(monday.year, monday.month, monday.day);
      filterDateTo.value = DateTime(sunday.year, sunday.month, sunday.day);
    } else if (preset == 'month') {
      final firstDay = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final lastDay = nextMonth.subtract(const Duration(days: 1));
      filterDate.value = null;
      filterDateFrom.value = firstDay;
      filterDateTo.value = DateTime(lastDay.year, lastDay.month, lastDay.day);
    }
    fetchInvoices();
  }

  void setSingleDate(DateTime date) {
    datePreset.value = 'custom_single';
    filterDate.value = DateTime(date.year, date.month, date.day);
    filterDateFrom.value = null;
    filterDateTo.value = null;
    fetchInvoices();
  }

  void setDateRange(DateTime from, DateTime to) {
    datePreset.value = 'custom_range';
    filterDate.value = null;
    filterDateFrom.value = DateTime(from.year, from.month, from.day);
    filterDateTo.value = DateTime(to.year, to.month, to.day);
    fetchInvoices();
  }

  void clearDateFilter() {
    datePreset.value = 'all';
    filterDate.value = null;
    filterDateFrom.value = null;
    filterDateTo.value = null;
    fetchInvoices();
  }

  void resetAllFilters() {
    statusFilter.value = 'all';
    datePreset.value = 'all';
    filterDate.value = null;
    filterDateFrom.value = null;
    filterDateTo.value = null;
    searchQuery.value = '';
    fetchInvoices();
  }

  bool get hasActiveDateFilter {
    return datePreset.value != 'all' ||
        filterDate.value != null ||
        filterDateFrom.value != null ||
        filterDateTo.value != null;
  }

  bool get hasActiveFilters {
    return statusFilter.value != 'all' ||
        hasActiveDateFilter ||
        searchQuery.value.isNotEmpty;
  }

  String get dateFilterSummary {
    if (datePreset.value == 'today') return "Aujourd'hui";
    if (datePreset.value == 'week') return 'Cette semaine';
    if (datePreset.value == 'month') return 'Ce mois-ci';
    if (filterDate.value != null) {
      return DateFormatter.formatShort(filterDate.value!);
    }
    if (filterDateFrom.value != null && filterDateTo.value != null) {
      return '${DateFormatter.formatShort(filterDateFrom.value!)} — ${DateFormatter.formatShort(filterDateTo.value!)}';
    }
    if (filterDateFrom.value != null) {
      return 'À partir du ${DateFormatter.formatShort(filterDateFrom.value!)}';
    }
    if (filterDateTo.value != null) {
      return "Jusqu'au ${DateFormatter.formatShort(filterDateTo.value!)}";
    }
    return 'Toutes les dates';
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






