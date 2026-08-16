import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/treatments_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/models/patient_model.dart';
import 'package:flutter_application_1/models/treatment_model.dart';
import 'package:flutter_application_1/models/treatment_type_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/app_dialog_header.dart';
import 'package:flutter_application_1/widgets/app_date_picker.dart';

class TreatmentFormDialog extends StatefulWidget {
  final PatientModel patient;
  final int? initialToothNumber;
  final TreatmentModel? initialTreatment;

  const TreatmentFormDialog({
    super.key,
    required this.patient,
    this.initialToothNumber,
    this.initialTreatment,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PatientModel patient,
    int? toothNumber,
    TreatmentModel? treatment,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TreatmentFormDialog(
        patient: patient,
        initialToothNumber: toothNumber,
        initialTreatment: treatment,
      ),
    );
  }

  @override
  State<TreatmentFormDialog> createState() => _TreatmentFormDialogState();
}

class _TreatmentFormDialogState extends State<TreatmentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  TreatmentTypeModel? _selectedType;
  int? _selectedToothNumber;
  String _selectedStatus = 'completed';
  late DateTime _selectedDate;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;

  static const List<int> allTeethNumbers = [
    18, 17, 16, 15, 14, 13, 12, 11,
    21, 22, 23, 24, 25, 26, 27, 28,
    48, 47, 46, 45, 44, 43, 42, 41,
    31, 32, 33, 34, 35, 36, 37, 38,
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTreatment;
    final controller = Get.find<TreatmentsController>();

    _selectedToothNumber = t?.toothNumber ?? widget.initialToothNumber;
    _selectedStatus = t?.status ?? 'completed';
    _selectedDate = t?.treatmentDate != null
        ? DateFormatter.fromApiString(t!.treatmentDate) ?? DateTime.now()
        : DateTime.now();

    _priceController = TextEditingController(
      text: t != null ? '${t.price}' : '',
    );
    _notesController = TextEditingController(text: t?.notes ?? '');

    // Select initial treatment type
    if (t != null) {
      _selectedType = controller.treatmentTypes.firstWhereOrNull(
        (type) => type.id == t.treatmentTypeId,
      );
    } else if (controller.treatmentTypes.isNotEmpty) {
      _selectedType = controller.treatmentTypes.first;
      _priceController.text = '${_selectedType!.defaultPrice}';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TreatmentTypeModel? type) {
    setState(() {
      _selectedType = type;
      if (type != null && widget.initialTreatment == null) {
        _priceController.text = '${type.defaultPrice}';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Date de l\'acte dentaire',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null || _selectedType!.id == null) {
      Get.snackbar(
        'Type obligatoire',
        'Veuillez sélectionner un type de traitement.',
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? _selectedType!.defaultPrice;
    final controller = Get.find<TreatmentsController>();
    final isEditing = widget.initialTreatment != null;

    setState(() => _isSubmitting = true);

    bool success = false;
    if (isEditing) {
      success = await controller.updateTreatment(
        widget.initialTreatment!.id!,
        TreatmentModel(
          id: widget.initialTreatment!.id,
          patientId: widget.patient.id!,
          treatmentTypeId: _selectedType!.id!,
          toothNumber: _selectedToothNumber,
          status: _selectedStatus,
          price: price,
          treatmentDate: DateFormatter.toApiString(_selectedDate),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
      );
    } else {
      success = await controller.createTreatment(
        TreatmentModel(
          patientId: widget.patient.id!,
          treatmentTypeId: _selectedType!.id!,
          toothNumber: _selectedToothNumber,
          status: _selectedStatus,
          price: price,
          treatmentDate: DateFormatter.toApiString(_selectedDate),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TreatmentsController>();
    final isEditing = widget.initialTreatment != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusXxl),
      child: Container(
        width: 560,
        padding: AppSpacing.dialogPaddingLarge,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Dialog Header ---
              AppDialogHeader(
                title: isEditing
                    ? 'Modifier le Soin'
                    : 'Nouvel Acte / Traitement Dentaire',
                subtitle: 'Patient : ${widget.patient.fullName}',
                icon: Icons.medical_services_rounded,
              ),

              // --- Form Fields ---
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tooth Number & Treatment Type Row
                      Row(
                        children: [
                          // Tooth Selection
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dent ciblée (FDI)',
                                  style: AppTypography.formLabel,
                                ),
                                AppSpacing.vGap6,
                                DropdownButtonFormField<int?>(
                                  initialValue: _selectedToothNumber,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                  ),
                                  hint: Text('Général / Sans dent', style: AppTypography.bodyMedium),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Général (Sans dent)'),
                                    ),
                                    ...allTeethNumbers.map((t) {
                                      return DropdownMenuItem<int?>(
                                        value: t,
                                        child: Text('Dent $t'),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _selectedToothNumber = val),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.hGap16,

                          // Treatment Type Dropdown
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Acte / Type de soin *',
                                  style: AppTypography.formLabel,
                                ),
                                AppSpacing.vGap6,
                                DropdownButtonFormField<TreatmentTypeModel>(
                                  initialValue: _selectedType,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                  ),
                                  hint: Text('Sélectionner l\'acte', style: AppTypography.bodyMedium),
                                  items: controller.treatmentTypes.map((type) {
                                    return DropdownMenuItem<TreatmentTypeModel>(
                                      value: type,
                                      child: Text(
                                        '${type.name} (${type.formattedPrice})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _onTypeChanged,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      AppSpacing.vGap16,

                      // Status & Price Row
                      Row(
                        children: [
                          // Status Selector
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Statut du soin',
                                  style: AppTypography.formLabel,
                                ),
                                AppSpacing.vGap6,
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedStatus,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'completed',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: AppColors.success, size: 16),
                                          SizedBox(width: 8),
                                          Text('Réalisé / Terminé'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'in_progress',
                                      child: Row(
                                        children: [
                                          Icon(Icons.timelapse_rounded,
                                              color: AppColors.warning, size: 16),
                                          SizedBox(width: 8),
                                          Text('En cours'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'planned',
                                      child: Row(
                                        children: [
                                          Icon(Icons.event_outlined,
                                              color: AppColors.info, size: 16),
                                          SizedBox(width: 8),
                                          Text('Planifié (À faire)'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedStatus = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.hGap16,

                          // Price input
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tarif (DA) *',
                                  style: AppTypography.formLabel,
                                ),
                                AppSpacing.vGap6,
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: 2500',
                                    suffixText: 'DA',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Prix requis';
                                    }
                                    if (double.tryParse(val.trim()) == null) {
                                      return 'Nombre invalide';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      AppSpacing.vGap16,

                      // Date picker
                      Text(
                        'Date de l\'intervention',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: AppRadius.borderRadiusLg,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          decoration: AppDecorations.panel,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: AppColors.primary, size: 18),
                              AppSpacing.hGap10,
                              Text(
                                DateFormatter.formatFull(_selectedDate),
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down_rounded,
                                  color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),

                      AppSpacing.vGap16,

                      // Clinical notes
                      Text(
                        'Notes cliniques & observations',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Détails de l\'intervention, anesthésie, matériaux utilisés...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.vGap24,
              const Divider(),
              AppSpacing.vGap16,

              // --- Actions Footer ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Annuler', style: AppTypography.button),
                  ),
                  AppSpacing.hGap12,
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      isEditing ? 'Mettre à jour' : 'Enregistrer le soin',
                      style: AppTypography.button,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
