import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/settings_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/models/treatment_type_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/empty_state.dart';

class TreatmentTypesManager extends StatelessWidget {
  const TreatmentTypesManager({super.key});

  Future<void> _openTypeDialog(BuildContext context, {TreatmentTypeModel? type}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: type?.name ?? '');
    final priceController = TextEditingController(
      text: type != null ? '${type.defaultPrice}' : '',
    );
    final descController = TextEditingController(text: type?.description ?? '');

    final result = await showDialog<TreatmentTypeModel>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusXxl),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: const Icon(Icons.medical_services_rounded,
                  color: AppColors.primary, size: 20),
            ),
            AppSpacing.hGap12,
            Text(
              type != null ? 'Modifier l\'acte' : 'Nouvel Acte au Catalogue',
              style: AppTypography.h3,
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Intitulé de l\'acte dentaire *',
                  style: AppTypography.formLabel,
                ),
                AppSpacing.vGap6,
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Détartrage et polissage, Extraction...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Le nom de l\'acte est obligatoire';
                    }
                    return null;
                  },
                ),
                AppSpacing.vGap16,
                Text(
                  'Tarif indicatif par défaut (DA) *',
                  style: AppTypography.formLabel,
                ),
                AppSpacing.vGap6,
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 2500',
                    suffixText: 'DA',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Le prix est obligatoire';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal < 0) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
                AppSpacing.vGap16,
                Text(
                  'Description ou protocole (Optionnel)',
                  style: AppTypography.formLabel,
                ),
                AppSpacing.vGap6,
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Précisions sur les matériaux, étapes...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler', style: AppTypography.button),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final model = TreatmentTypeModel(
                  id: type?.id,
                  name: nameController.text.trim(),
                  defaultPrice: double.parse(priceController.text.trim()),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                );
                Navigator.of(context).pop(model);
              }
            },
            child: Text('Enregistrer', style: AppTypography.button),
          ),
        ],
      ),
    );

    if (result != null) {
      final controller = Get.find<SettingsController>();
      await controller.saveTreatmentType(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, TreatmentTypeModel type) async {
    final controller = Get.find<SettingsController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer cet acte', style: AppTypography.h3),
        content: Text(
          'Voulez-vous supprimer "${type.name}" du catalogue des actes ?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: AppTypography.button),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: AppTypography.button),
          ),
        ],
      ),
    );

    if (confirm == true && type.id != null) {
      await controller.deleteTreatmentType(type.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Container(
      padding: AppSpacing.screenPadding,
      decoration: AppDecorations.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Button
          Row(
            children: [
              const Icon(Icons.list_alt_rounded,
                  color: AppColors.primary, size: 22),
              AppSpacing.hGap10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catalogue des Types de Soins & Tarifs',
                      style: AppTypography.h4,
                    ),
                    Text(
                      'Gérez la liste des actes proposés et leurs tarifs indicatifs par défaut',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openTypeDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Ajouter un acte', style: AppTypography.buttonSmall),
              ),
            ],
          ),

          AppSpacing.vGap16,
          const Divider(height: 1),
          AppSpacing.vGap12,

          // Types Table / List
          Obx(() {
            final list = controller.treatmentTypes;

            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.massive),
                child: EmptyState(
                  icon: Icons.medical_information_outlined,
                  title: 'Catalogue vide',
                  message:
                      'Cliquez sur "Ajouter un acte" pour configurer vos prestations dentaires.',
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => AppSpacing.vGap8,
              itemBuilder: (context, index) {
                final type = list[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: AppDecorations.panelBg,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: AppRadius.borderRadiusMd,
                        ),
                        child: const Icon(Icons.healing_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                      AppSpacing.hGap14,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              style: AppTypography.formLabel,
                            ),
                            if (type.description != null &&
                                type.description!.trim().isNotEmpty)
                              Text(
                                type.description!,
                                style: AppTypography.caption,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormatter.formatCurrency(type.defaultPrice),
                        style: AppTypography.h5.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      AppSpacing.hGap14,
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.textSecondary),
                        tooltip: 'Modifier',
                        onPressed: () =>
                            _openTypeDialog(context, type: type),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.danger),
                        tooltip: 'Supprimer',
                        onPressed: () => _confirmDelete(context, type),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}






