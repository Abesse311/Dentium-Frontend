import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/treatments_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/models/patient_model.dart';
import 'package:flutter_application_1/models/treatment_type_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/app_dialog_header.dart';
import 'package:flutter_application_1/widgets/app_date_picker.dart';

class BulkTreatmentDialog extends StatefulWidget {
  final PatientModel patient;
  final List<int> toothNumbers;

  const BulkTreatmentDialog({
    super.key,
    required this.patient,
    required this.toothNumbers,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PatientModel patient,
    required List<int> toothNumbers,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BulkTreatmentDialog(
        patient: patient,
        toothNumbers: toothNumbers,
      ),
    );
  }

  @override
  State<BulkTreatmentDialog> createState() => _BulkTreatmentDialogState();
}

class _BulkTreatmentDialogState extends State<BulkTreatmentDialog> {
  final _formKey = GlobalKey<FormState>();

  TreatmentTypeModel? _selectedType;
  String _selectedStatus = 'completed';
  late DateTime _selectedDate;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;

  List<TreatmentTypeModel> get availableTypes {
    final controller = Get.find<TreatmentsController>();
    return controller.perToothTreatmentTypes;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _notesController = TextEditingController();

    final types = availableTypes;
    if (types.isNotEmpty) {
      _selectedType = types.first;
      final defaultTotal = _selectedType!.defaultPrice * widget.toothNumbers.length;
      _totalPriceController = TextEditingController(
        text: defaultTotal > 0 ? '$defaultTotal' : '0',
      );
    } else {
      _totalPriceController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TreatmentTypeModel? type) {
    setState(() {
      _selectedType = type;
      if (type != null) {
        final total = type.defaultPrice * widget.toothNumbers.length;
        _totalPriceController.text = total > 0 ? '$total' : '0';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Date de l\'acte groupé',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  double get _currentUnitPrice {
    final total = double.tryParse(_totalPriceController.text.trim()) ?? 0.0;
    final count = widget.toothNumbers.length;
    if (count == 0) return 0.0;
    return total / count;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null || _selectedType!.id == null) {
      Get.snackbar(
        'Type obligatoire',
        'Veuillez sélectionner un acte dentaire pour le traitement groupé.',
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final unitPrice = _currentUnitPrice;
    final controller = Get.find<TreatmentsController>();

    setState(() => _isSubmitting = true);

    final success = await controller.createTreatmentsBulk(
      patientId: widget.patient.id!,
      treatmentTypeId: _selectedType!.id!,
      toothNumbers: widget.toothNumbers,
      status: _selectedStatus,
      price: unitPrice,
      treatmentDate: DateFormatter.toApiString(_selectedDate),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedTeeth = [...widget.toothNumbers]..sort();
    final count = sortedTeeth.length;
    final typesList = availableTypes;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusXxl),
      child: Container(
        width: 620,
        padding: AppSpacing.dialogPaddingLarge,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              AppDialogHeader(
                title: 'Acte Groupé Multi-Dents ($count dents)',
                subtitle: 'Patient : ${widget.patient.fullName}',
                icon: Icons.checklist_rtl_rounded,
              ),

              // Form fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target Teeth Summary Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          borderRadius: AppRadius.borderRadiusLg,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hub_rounded,
                                    size: 16, color: AppColors.primary),
                                AppSpacing.hGap8,
                                Text(
                                  '$count dents sélectionnées pour cet acte :',
                                  style: AppTypography.formLabel.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.vGap8,
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: sortedTeeth.map((tooth) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: AppRadius.borderRadiusSm,
                                  ),
                                  child: Text(
                                    'Dent $tooth',
                                    style: AppTypography.badgeSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      AppSpacing.vGap16,

                      // Treatment Type Dropdown
                      Text(
                        'Acte dentaire à appliquer *',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      DropdownButtonFormField<TreatmentTypeModel>(
                        initialValue: _selectedType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          prefixIcon: Icon(Icons.healing_rounded, size: 20),
                        ),
                        hint: Text(
                          'Sélectionner l\'acte par dent',
                          style: AppTypography.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        items: typesList.map((type) {
                          return DropdownMenuItem<TreatmentTypeModel>(
                            value: type,
                            child: Text(
                              '${type.name} (${type.formattedPrice} / dent)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _onTypeChanged,
                        validator: (val) {
                          if (val == null) {
                            return 'Veuillez sélectionner un acte';
                          }
                          return null;
                        },
                      ),

                      AppSpacing.vGap16,

                      // Price and Status Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Price
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tarif total pour les $count dents (DA) *',
                                  style: AppTypography.formLabel,
                                ),
                                AppSpacing.vGap6,
                                TextFormField(
                                  controller: _totalPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: 10000',
                                    suffixText: 'DA',
                                    helperText:
                                        'Soit ${DateFormatter.formatCurrency(_currentUnitPrice)} / dent',
                                    helperStyle: AppTypography.caption.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Prix total requis';
                                    }
                                    if (double.tryParse(val.trim()) == null) {
                                      return 'Montant invalide';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.hGap16,

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
                                  isExpanded: true,
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
                                          Flexible(
                                            child: Text(
                                              'Réalisé / Terminé',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
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
                                          Flexible(
                                            child: Text(
                                              'En cours',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
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
                                          Flexible(
                                            child: Text(
                                              'Planifié (À faire)',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
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
                        ],
                      ),

                      AppSpacing.vGap16,

                      // Intervention Date
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
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

                      // Clinical Notes
                      Text(
                        'Notes cliniques (communes à toutes les dents sélectionnées)',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'Ex: Avulsion groupée sous anesthésie locale, suites opératoires...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.vGap24,
              const Divider(),
              AppSpacing.vGap16,

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text('Annuler', style: AppTypography.button),
                  ),
                  AppSpacing.hGap12,
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: AppSpacing.buttonPaddingLarge,
                    ),
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
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isSubmitting
                          ? 'Enregistrement...'
                          : 'Valider et appliquer aux $count dents',
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
