import 'package:get/get.dart';
import '../controllers/appointments_controller.dart';
import '../controllers/connectivity_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/invoices_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/patients_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/treatments_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core infrastructure controllers
    Get.put<NavigationController>(NavigationController(), permanent: true);
    Get.put<ConnectivityController>(ConnectivityController(), permanent: true);

    // Module controllers for Desktop Master-Detail Shell
    Get.put<DashboardController>(DashboardController(), permanent: true);
    Get.put<PatientsController>(PatientsController(), permanent: true);
    Get.put<AppointmentsController>(AppointmentsController(), permanent: true);
    Get.put<TreatmentsController>(TreatmentsController(), permanent: true);
    Get.put<InvoicesController>(InvoicesController(), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);
  }
}
