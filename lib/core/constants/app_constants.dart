class AppConstants {
  // Base API configuration
  static const String apiBaseUrl = 'http://127.0.0.1:8000';
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);

  // App Metadata
  static const String appName = 'Cabinet Dentaire';
  static const String appTagline = 'Gestion de Cabinet';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String endpointSettings = '/settings';
  static const String endpointPatients = '/patients';
  static const String endpointAppointments = '/appointments';
  static const String endpointAppointmentsCapacity = '/appointments/capacity';
  static const String endpointAppointmentsWeek = '/appointments/week';
  static const String endpointTreatments = '/treatments';
  static const String endpointTreatmentTypes = '/treatment-types';
  static const String endpointInvoices = '/invoices';
  static const String endpointDashboardToday = '/dashboard/today';
}






