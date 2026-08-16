import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/connectivity_controller.dart';
import '../controllers/navigation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import 'appointments/appointments_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'invoices/invoices_screen.dart';
import 'patients/patients_screen.dart';
import 'settings/settings_screen.dart';
import 'treatments/treatments_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are registered
    final navController = Get.put(NavigationController(), permanent: true);
    Get.put(ConnectivityController(), permanent: true);

    final List<Widget> screens = const [
      DashboardScreen(),
      PatientsScreen(),
      AppointmentsScreen(),
      TreatmentsScreen(),
      InvoicesScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Desktop Left Sidebar
          const AppSidebar(),

          // Main Viewport
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar
                const AppHeader(),

                // Active Tab Content
                Expanded(
                  child: Obx(() {
                    final index = navController.selectedIndex.value;
                    return screens[index];
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
