import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';
import 'patients_controller.dart';
import 'appointments_controller.dart';
import 'treatments_controller.dart';
import 'invoices_controller.dart';
import 'analytics_controller.dart';
import 'settings_controller.dart';

class NavItem {
  final String titleFr;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const NavItem({
    required this.titleFr,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

class NavigationController extends GetxController {
  static NavigationController get to => Get.find();

  final RxInt selectedIndex = 0.obs;
  final RxBool isSidebarExpanded = true.obs;

  final List<NavItem> navItems = const [
    NavItem(
      titleFr: 'Tableau de bord',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      route: '/dashboard',
    ),
    NavItem(
      titleFr: 'Patients',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      route: '/patients',
    ),
    NavItem(
      titleFr: 'Rendez-vous',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      route: '/appointments',
    ),
    NavItem(
      titleFr: 'Traitements',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services_rounded,
      route: '/treatments',
    ),
    NavItem(
      titleFr: 'Factures & Paiements',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      route: '/invoices',
    ),
    NavItem(
      titleFr: 'Analyses & Revenus',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
      route: '/analytics',
    ),
    NavItem(
      titleFr: 'Paramètres',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      route: '/settings',
    ),
  ];

  void changeIndex(int index) {
    if (index >= 0 && index < navItems.length) {
      selectedIndex.value = index;

      // Auto-refresh data when switching to the selected tab
      switch (index) {
        case 0:
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().fetchDashboardData();
          }
          break;
        case 1:
          if (Get.isRegistered<PatientsController>()) {
            Get.find<PatientsController>().fetchPatients();
          }
          break;
        case 2:
          if (Get.isRegistered<AppointmentsController>()) {
            Get.find<AppointmentsController>().loadData();
          }
          break;
        case 3:
          if (Get.isRegistered<TreatmentsController>()) {
            Get.find<TreatmentsController>().loadInitialData();
          }
          break;
        case 4:
          if (Get.isRegistered<InvoicesController>()) {
            Get.find<InvoicesController>().fetchInvoices();
          }
          break;
        case 5:
          if (Get.isRegistered<AnalyticsController>()) {
            Get.find<AnalyticsController>().fetchAnalytics();
          }
          break;
        case 6:
          if (Get.isRegistered<SettingsController>()) {
            Get.find<SettingsController>().fetchSettings();
          }
          break;
      }
    }
  }

  void toggleSidebar() {
    isSidebarExpanded.value = !isSidebarExpanded.value;
  }

  String get currentTitle => navItems[selectedIndex.value].titleFr;
}






