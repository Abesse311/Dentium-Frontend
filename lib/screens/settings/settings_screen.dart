import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../theme/app_theme.dart';
import 'clinic_info_form.dart';
import 'treatment_types_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value && controller.settings.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchSettings(),
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Clinic Information & Advisory Limit
                const ClinicInfoForm(),

                AppSpacing.vGap28,

                // Section 2: Treatment Types Catalog Management
                const TreatmentTypesManager(),
              ],
            ),
          ),
        );
      }),
    );
  }
}
