import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusLabels {
  // --- Appointments Status ---
  static const Map<String, String> appointmentStatusMap = {
    'booked': 'Réservé',
    'completed': 'Terminé',
    'no_show': 'Absent',
  };

  static String appointmentStatus(String? status) {
    if (status == null) return 'Inconnu';
    return appointmentStatusMap[status.toLowerCase()] ?? status;
  }

  static Color appointmentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'no_show':
        return AppColors.danger;
      case 'booked':
      default:
        return AppColors.info;
    }
  }

  static Color appointmentStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.successLight;
      case 'no_show':
        return AppColors.dangerLight;
      case 'booked':
      default:
        return AppColors.infoLight;
    }
  }

  // --- Treatments Status ---
  static const Map<String, String> treatmentStatusMap = {
    'planned': 'Planifié',
    'in_progress': 'En cours',
    'completed': 'Réalisé',
  };

  static String treatmentStatus(String? status) {
    if (status == null) return 'Inconnu';
    return treatmentStatusMap[status.toLowerCase()] ?? status;
  }

  static Color treatmentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.warning;
      case 'planned':
      default:
        return AppColors.info;
    }
  }

  static Color treatmentStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.successLight;
      case 'in_progress':
        return AppColors.warningLight;
      case 'planned':
      default:
        return AppColors.infoLight;
    }
  }

  // --- Invoices Status ---
  static const Map<String, String> invoiceStatusMap = {
    'unpaid': 'Non payée',
    'partially_paid': 'Partiellement payée',
    'paid': 'Payée',
  };

  static String invoiceStatus(String? status) {
    if (status == null) return 'Inconnu';
    return invoiceStatusMap[status.toLowerCase()] ?? status;
  }

  static Color invoiceStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'partially_paid':
        return AppColors.warning;
      case 'unpaid':
      default:
        return AppColors.danger;
    }
  }

  static Color invoiceStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return AppColors.successLight;
      case 'partially_paid':
        return AppColors.warningLight;
      case 'unpaid':
      default:
        return AppColors.dangerLight;
    }
  }

  // --- Payment Methods ---
  static const Map<String, String> paymentMethodMap = {
    'cash': 'Espèces',
    'card': 'Carte bancaire',
    'transfer': 'Virement',
    'other': 'Autre',
  };

  static String paymentMethod(String? method) {
    if (method == null) return 'Autre';
    return paymentMethodMap[method.toLowerCase()] ?? method;
  }

  // --- Gender ---
  static const Map<String, String> genderMap = {
    'male': 'Homme',
    'female': 'Femme',
  };

  static String gender(String? g) {
    if (g == null) return 'Non spécifié';
    return genderMap[g.toLowerCase()] ?? g;
  }
}
