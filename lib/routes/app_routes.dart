import 'package:get/get.dart';
import '../bindings/initial_binding.dart';
import '../bindings/appointments_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../bindings/invoices_binding.dart';
import '../bindings/patients_binding.dart';
import '../bindings/settings_binding.dart';
import '../bindings/treatments_binding.dart';
import '../views/appointments/appointments_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/invoices/invoices_view.dart';
import '../views/patients/patients_view.dart';
import '../views/settings/settings_view.dart';
import '../views/shell/shell_view.dart';
import '../views/treatments/treatments_view.dart';

class AppRoutes {
  static const String shell = '/';
  static const String dashboard = '/dashboard';
  static const String patients = '/patients';
  static const String appointments = '/appointments';
  static const String treatments = '/treatments';
  static const String invoices = '/invoices';
  static const String settings = '/settings';

  static final List<GetPage> pages = [
    GetPage(
      name: shell,
      page: () => const ShellView(),
      binding: InitialBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: patients,
      page: () => const PatientsView(),
      binding: PatientsBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: appointments,
      page: () => const AppointmentsView(),
      binding: AppointmentsBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: treatments,
      page: () => const TreatmentsView(),
      binding: TreatmentsBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: invoices,
      page: () => const InvoicesView(),
      binding: InvoicesBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}
