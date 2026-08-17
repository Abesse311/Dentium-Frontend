import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/invoices_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/data/patients_api.dart';
import 'package:flutter_application_1/models/patient_model.dart';
import 'package:flutter_application_1/models/patient_treatment_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/app_dialog_header.dart';

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

  bool _isLoadingPatients = true;
  bool _isLoadingTreatments = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
    return sum;
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

    if (_selectedTreatmentIds.isEmpty) {
      Get.snackbar(
        'Prestations requises',
        'Veuillez sélectionner au moins un acte dentaire à facturer.',
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
                initialValue: _selectedPatient,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                hint: Text('Choisir le patient à facturer',
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis),
                items: _allPatients.map((p) {
                  return DropdownMenuItem<PatientModel>(
                    value: p,
                    child: Text(
                      '${p.fullName} (${p.phone ?? 'Sans téléphone'})',
                      overflow: TextOverflow.ellipsis,
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
                              separatorBuilder: (_, _) => AppSpacing.vGap6,
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
