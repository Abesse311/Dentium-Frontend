import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../models/clinic_settings_model.dart';
import '../../theme/app_theme.dart';

class ClinicInfoForm extends StatefulWidget {
  const ClinicInfoForm({super.key});

  @override
  State<ClinicInfoForm> createState() => _ClinicInfoFormState();
}

class _ClinicInfoFormState extends State<ClinicInfoForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _clinicNameController;
  late final TextEditingController _doctorNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _dailyLimitController;

  @override
  void initState() {
    super.initState();
    final settings = Get.find<SettingsController>().settings.value;
    _clinicNameController =
        TextEditingController(text: settings?.clinicName ?? 'Cabinet Dentaire');
    _doctorNameController =
        TextEditingController(text: settings?.doctorName ?? '');
    _phoneController = TextEditingController(text: settings?.phone ?? '');
    _addressController = TextEditingController(text: settings?.address ?? '');
    _dailyLimitController = TextEditingController(
      text: '${settings?.dailyPatientLimit ?? 30}',
    );
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _doctorNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dailyLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<SettingsController>();
    final current = controller.settings.value;
    final limit = int.tryParse(_dailyLimitController.text.trim()) ?? 30;

    final updated = ClinicSettingsModel(
      id: current?.id ?? 1,
      clinicName: _clinicNameController.text.trim(),
      doctorName: _doctorNameController.text.trim().isEmpty
          ? null
          : _doctorNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      dailyPatientLimit: limit > 0 ? limit : 30,
    );

    await controller.saveClinicSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Container(
      padding: AppSpacing.screenPadding,
      decoration: AppDecorations.panel,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business_rounded, color: AppColors.primary, size: 22),
                AppSpacing.hGap10,
                Text(
                  'Coordonnées du Cabinet & Praticien',
                  style: AppTypography.h4,
                ),
              ],
            ),
            AppSpacing.vGap16,
            const Divider(height: 1),
            AppSpacing.vGap16,

            // Clinic Name
            Text(
              'Nom de la structure / Cabinet *',
              style: AppTypography.formLabel,
            ),
            AppSpacing.vGap6,
            TextFormField(
              controller: _clinicNameController,
              decoration: const InputDecoration(
                hintText: 'Ex: Cabinet Dentaire SmilePro',
                prefixIcon: Icon(Icons.apartment_rounded, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Le nom du cabinet est obligatoire';
                }
                return null;
              },
            ),
            AppSpacing.vGap16,

            // Doctor Name & Phone Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nom du Praticien (Dentiste)',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      TextFormField(
                        controller: _doctorNameController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Dr. Karim Benali',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGap16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Téléphone professionnel',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Ex: 0550 12 34 56',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGap16,

            // Address
            Text(
              'Adresse du cabinet',
              style: AppTypography.formLabel,
            ),
            AppSpacing.vGap6,
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Ex: 12 Rue Didouche Mourad, Alger',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
            ),
            AppSpacing.vGap24,

            // --- Advisory Daily Patient Limit (Section 6.6) ---
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: AppRadius.borderRadiusXl,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                      AppSpacing.hGap8,
                      Text(
                        'Capacité Journalière Conseillée (Seuil indicatif)',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGap6,
                  Text(
                    'Nombre maximum conseillé de consultations par jour. Cette valeur alimente le code couleur de remplissage (Vert / Orange / Rouge) dans le planning hebdomadaire. Elle est purement consultative et ne bloque aucun rendez-vous supplémentaire.',
                    style: AppTypography.bodySmall.copyWith(height: 1.4),
                  ),
                  AppSpacing.vGap12,
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _dailyLimitController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '30',
                            suffixText: 'patients',
                            fillColor: Colors.white,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Valeur requise';
                            }
                            final n = int.tryParse(val.trim());
                            if (n == null || n <= 0) {
                              return 'Nombre > 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      AppSpacing.hGap16,
                      Expanded(
                        child: Text(
                          'Par défaut : 30 patients / jour',
                          style: AppTypography.caption.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            AppSpacing.vGap24,
            const Divider(height: 1),
            AppSpacing.vGap16,

            // Save Button
            Align(
              alignment: Alignment.centerRight,
              child: Obx(() {
                final isSaving = controller.isSaving.value;
                return ElevatedButton.icon(
                  onPressed: isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                      vertical: AppSpacing.xl,
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text('Enregistrer les paramètres',
                      style: AppTypography.button),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
