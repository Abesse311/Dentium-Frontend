import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'widgets/clinic_info_form.dart';
import 'widgets/treatment_types_manager.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

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






