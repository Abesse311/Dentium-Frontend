import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/settings_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/models/treatment_type_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/empty_state.dart';

class TreatmentTypesManager extends StatefulWidget {
  const TreatmentTypesManager({super.key});

  @override
  State<TreatmentTypesManager> createState() => _TreatmentTypesManagerState();
}

class _TreatmentTypesManagerState extends State<TreatmentTypesManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openTypeDialog(
    BuildContext context, {
    TreatmentTypeModel? type,
    String? defaultCategory,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: type?.name ?? '');
    final priceController = TextEditingController(
      text: type != null ? '${type.defaultPrice}' : '',
    );
    final descController = TextEditingController(text: type?.description ?? '');
    String selectedCategory = type?.category ?? defaultCategory ?? 'general';

    final result = await showDialog<TreatmentTypeModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusXxl,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: Icon(
                    selectedCategory == 'general'
                        ? Icons.medical_services_rounded
                        : Icons.healing_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                AppSpacing.hGap12,
                Text(
                  type != null ? 'Modifier l\'acte' : 'Nouvel Acte au Catalogue',
                  style: AppTypography.h3,
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Selector
                      Text(
                        'Catégorie de l\'acte *',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'general',
                            label: Text('Soin Général'),
                            icon: Icon(Icons.medical_services_outlined, size: 16),
                          ),
                          ButtonSegment<String>(
                            value: 'per_tooth',
                            label: Text('Acte par Dent'),
                            icon: Icon(Icons.healing_outlined, size: 16),
                          ),
                        ],
                        selected: {selectedCategory},
                        onSelectionChanged: (Set<String> newSelection) {
                          setDialogState(() {
                            selectedCategory = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: AppRadius.borderRadiusLg,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.vGap4,
                      Text(
                        selectedCategory == 'general'
                            ? 'Soin non rattaché à une dent (ex: consultation, détartrage global, radio...)'
                            : 'Soin technique réalisé sur une dent spécifique (ex: carie, extraction, couronne...)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.vGap16,

                      // Name
                      Text(
                        'Intitulé de l\'acte dentaire *',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: selectedCategory == 'general'
                              ? 'Ex: Consultation de contrôle, Blanchiment...'
                              : 'Ex: Obturation composite, Extraction...',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Le nom de l\'acte est obligatoire';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.vGap16,

                      // Default Price
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

                      // Description
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
                      category: selectedCategory,
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
          );
        },
      ),
    );

    if (result != null) {
      final controller = Get.find<SettingsController>();
      await controller.saveTreatmentType(result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TreatmentTypeModel type,
  ) async {
    final controller = Get.find<SettingsController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer cet acte', style: AppTypography.h3),
        content: Text(
          'Voulez-vous supprimer "${type.name}" du catalogue des actes (${type.categoryLabel}) ?',
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
          // Header & Add Buttons
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
                      'Gérez la nomenclature des actes répartie en soins généraux et soins par dent',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final activeCategory = _tabController.index == 0 ? 'general' : 'per_tooth';
                  _openTypeDialog(context, defaultCategory: activeCategory);
                },
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

          // Two-Category Tab Bar
          Obx(() {
            final allTypes = controller.treatmentTypes;
            final generalCount = allTypes.where((t) => t.isGeneral).length;
            final perToothCount = allTypes.where((t) => t.isPerTooth).length;

            return Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTypography.button,
                unselectedLabelStyle:
                    AppTypography.button.copyWith(fontWeight: FontWeight.normal),
                tabs: [
                  Tab(
                    child: Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 18),
                        AppSpacing.hGap8,
                        const Text('Soins Généraux'),
                        AppSpacing.hGap8,
                        _buildCountBadge(generalCount),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        const Icon(Icons.healing_outlined, size: 18),
                        AppSpacing.hGap8,
                        const Text('Actes par Dent'),
                        AppSpacing.hGap8,
                        _buildCountBadge(perToothCount),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          AppSpacing.vGap16,

          // Tab Content
          Obx(() {
            final allTypes = controller.treatmentTypes;
            final generalTypes = allTypes.where((t) => t.isGeneral).toList();
            final perToothTypes = allTypes.where((t) => t.isPerTooth).toList();

            return SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Soins Généraux
                  _buildTypesList(
                    context: context,
                    types: generalTypes,
                    category: 'general',
                    emptyTitle: 'Aucun soin général',
                    emptyMessage:
                        'Les soins non rattachés à une dent (consultation, radio, blanchiment...) apparaîtront ici.',
                  ),

                  // Tab 2: Actes par Dent
                  _buildTypesList(
                    context: context,
                    types: perToothTypes,
                    category: 'per_tooth',
                    emptyTitle: 'Aucun acte par dent',
                    emptyMessage:
                        'Les soins rattachés aux dents (obturation, extraction, couronne, implant...) apparaîtront ici.',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypesList({
    required BuildContext context,
    required List<TreatmentTypeModel> types,
    required String category,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (types.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.massive),
        child: EmptyState(
          icon: category == 'general'
              ? Icons.medical_information_outlined
              : Icons.healing_outlined,
          title: emptyTitle,
          message: emptyMessage,
          action: ElevatedButton.icon(
            onPressed: () => _openTypeDialog(context, defaultCategory: category),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              category == 'general'
                  ? 'Ajouter un soin général'
                  : 'Ajouter un acte par dent',
              style: AppTypography.buttonSmall,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: types.length,
      separatorBuilder: (_, _) => AppSpacing.vGap8,
      itemBuilder: (context, index) {
        final type = types[index];
        final isGeneral = type.isGeneral;

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
                  color: isGeneral
                      ? AppColors.primaryLight
                      : AppColors.infoLight,
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Icon(
                  isGeneral
                      ? Icons.medical_services_rounded
                      : Icons.healing_rounded,
                  color: isGeneral ? AppColors.primary : AppColors.info,
                  size: 18,
                ),
              ),
              AppSpacing.hGap14,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type.name,
                          style: AppTypography.formLabel,
                        ),
                        AppSpacing.hGap8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: isGeneral
                                ? AppColors.primaryLight
                                : AppColors.infoLight,
                            borderRadius: AppRadius.borderRadiusSm,
                          ),
                          child: Text(
                            type.categoryLabel,
                            style: AppTypography.caption.copyWith(
                              color: isGeneral
                                  ? AppColors.primary
                                  : AppColors.infoDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (type.description != null &&
                        type.description!.trim().isNotEmpty) ...[
                      AppSpacing.vGap2,
                      Text(
                        type.description!,
                        style: AppTypography.caption,
                      ),
                    ],
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
                onPressed: () => _openTypeDialog(context, type: type),
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
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.borderRadiusLg,
      ),
      child: Text(
        '$count',
        style: AppTypography.badgeSmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}
