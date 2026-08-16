import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/navigation_controller.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_sidebar.dart';
import 'package:flutter_application_1/views/appointments/appointments_view.dart';
import 'package:flutter_application_1/views/dashboard/dashboard_view.dart';
import 'package:flutter_application_1/views/invoices/invoices_view.dart';
import 'package:flutter_application_1/views/patients/patients_view.dart';
import 'package:flutter_application_1/views/settings/settings_view.dart';
import 'package:flutter_application_1/views/treatments/treatments_view.dart';

class ShellView extends StatelessWidget {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<NavigationController>();

    final List<Widget> screens = const [
      DashboardView(),
      PatientsView(),
      AppointmentsView(),
      TreatmentsView(),
      InvoicesView(),
      SettingsView(),
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






