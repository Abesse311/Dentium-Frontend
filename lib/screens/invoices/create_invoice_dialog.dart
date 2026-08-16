import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoices_controller.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/patients_api.dart';
import '../../models/patient_model.dart';
import '../../models/patient_treatment_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_dialog_header.dart';

class CreateInvoiceDialog extends StatefulWidget {
  final int? initialPatientId;

  const CreateInvoiceDialog({super.key, this.initialPatientId});

  static Future<bool?> show(BuildContext context, {int? patientId}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateInvoiceDialog(initialPatientId: patientId),
    );
  }

  @override
  State<CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<CreateInvoiceDialog> {
  final PatientsApi _patientsApi = PatientsApi();

  List<PatientModel> _allPatients = [];
  PatientModel? _selectedPatient;

  List<PatientTreatmentModel> _patientTreatments = [];
  final Set<int> _selectedTreatmentIds = {};

  final List<Map<String, dynamic>> _customItems = [];
  final TextEditingController _customDescController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();

  bool _isLoadingPatients = true;
  bool _isLoadingTreatments = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _customDescController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final list = await _patientsApi.getPatients();
      if (mounted) {
        setState(() {
          _allPatients = list;
          _isLoadingPatients = false;
          if (widget.initialPatientId != null) {
            final p = list.firstWhereOrNull((p) => p.id == widget.initialPatientId);
            if (p != null) {
              _onPatientSelected(p);
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  Future<void> _onPatientSelected(PatientModel? patient) async {
    setState(() {
      _selectedPatient = patient;
      _selectedTreatmentIds.clear();
      _patientTreatments.clear();
    });

    if (patient?.id != null) {
      setState(() => _isLoadingTreatments = true);
      try {
        final list = await _patientsApi.getPatientTreatments(patient!.id!);
        if (mounted) {
          setState(() {
            _patientTreatments = list;
            // Pre-select all treatments by default
            _selectedTreatmentIds.addAll(list.map((t) => t.id));
            _isLoadingTreatments = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingTreatments = false);
      }
    }
  }

  double get _computedTotal {
    double sum = 0.0;
    for (final t in _patientTreatments) {
      if (_selectedTreatmentIds.contains(t.id)) {
        sum += t.price;
      }
    }
    for (final item in _customItems) {
      sum += (item['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return sum;
  }

  void _addCustomItem() {
    final desc = _customDescController.text.trim();
    final amt = double.tryParse(_customAmountController.text.trim());

    if (desc.isEmpty || amt == null || amt <= 0) {
      Get.snackbar(
        'Ligne personnalisée',
        'Veuillez renseigner une description et un montant valide.',
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _customItems.add({
        'description': desc,
        'amount': amt,
      });
      _customDescController.clear();
      _customAmountController.clear();
    });
  }

  Future<void> _submit() async {
    if (_selectedPatient == null) {
      Get.snackbar(
        'Patient requis',
        'Veuillez sélectionner un patient pour générer la facture.',
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedTreatmentIds.isEmpty && _customItems.isEmpty) {
      Get.snackbar(
        'Prestations requises',
        'Veuillez sélectionner au moins un acte dentaire ou ajouter une ligne de facturation.',
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final controller = Get.find<InvoicesController>();
    setState(() => _isSubmitting = true);

    final success = await controller.createInvoice(
      patientId: _selectedPatient!.id!,
      treatmentIds: _selectedTreatmentIds.toList(),
      customItems: _customItems.isNotEmpty ? _customItems : null,
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusXxl),
      child: Container(
        width: 680,
        padding: AppSpacing.dialogPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const AppDialogHeader(
              title: 'Établir une Nouvelle Facture',
              subtitle: 'Sélectionnez les actes réalisés à inclure dans la facture',
              icon: Icons.receipt_long_rounded,
            ),

            // Patient Selector
            Text(
              'Patient *',
              style: AppTypography.formLabel,
            ),
            AppSpacing.vGap6,
            if (_isLoadingPatients)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<PatientModel>(
                value: _selectedPatient,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                hint: Text('Choisir le patient à facturer', style: AppTypography.bodyMedium),
                items: _allPatients.map((p) {
                  return DropdownMenuItem<PatientModel>(
                    value: p,
                    child: Text(
                      '${p.fullName} (${p.phone ?? 'Sans téléphone'})',
                    ),
                  );
                }).toList(),
                onChanged: _onPatientSelected,
              ),

            AppSpacing.vGap16,

            // Treatments Selection List
            Text(
              'Actes & Traitements à facturer',
              style: AppTypography.formLabel,
            ),
            AppSpacing.vGap6,

            Container(
              height: 180,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: AppDecorations.panelBg,
              child: _isLoadingTreatments
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedPatient == null
                      ? Center(
                          child: Text(
                            'Veuillez sélectionner un patient pour charger ses soins.',
                            style: AppTypography.bodySmall,
                          ),
                        )
                      : _patientTreatments.isEmpty
                          ? Center(
                              child: Text(
                                'Aucun acte enregistré dans le dossier de ce patient.',
                                style: AppTypography.bodySmall,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _patientTreatments.length,
                              separatorBuilder: (_, __) => AppSpacing.vGap6,
                              itemBuilder: (context, index) {
                                final t = _patientTreatments[index];
                                final isChecked =
                                    _selectedTreatmentIds.contains(t.id);

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: AppDecorations.panel,
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isChecked,
                                        activeColor: AppColors.primary,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedTreatmentIds.add(t.id);
                                            } else {
                                              _selectedTreatmentIds.remove(t.id);
                                            }
                                          });
                                        },
                                      ),
                                      AppSpacing.hGap8,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.displayName,
                                              style: AppTypography.formLabel,
                                            ),
                                            Text(
                                              '${t.toothLabel} • ${t.formattedDate}',
                                              style: AppTypography.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        DateFormatter.formatCurrency(t.price),
                                        style: AppTypography.formLabel,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),

            AppSpacing.vGap16,

            // Total Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.borderRadiusLg,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL DE LA FACTURE :',
                    style: AppTypography.formLabel.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    DateFormatter.formatCurrency(_computedTotal),
                    style: AppTypography.h3.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),

            AppSpacing.vGap20,
            const Divider(),
            AppSpacing.vGap14,

            // Actions
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
                      : const Icon(Icons.receipt_rounded, size: 18),
                  label: Text('Générer la Facture', style: AppTypography.button),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
