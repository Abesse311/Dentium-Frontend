import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/invoices_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/data/patients_api.dart';
import 'package:flutter_application_1/data/treatments_api.dart';
import 'package:flutter_application_1/models/patient_model.dart';
import 'package:flutter_application_1/models/patient_treatment_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/core/utils/invoice_item_grouper.dart';
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
  final TreatmentsApi _treatmentsApi = TreatmentsApi();
  final TextEditingController _totalPriceController = TextEditingController();

  List<PatientModel> _allPatients = [];
  final Map<int, int> _patientUnbilledCount = {};
  PatientModel? _selectedPatient;

  List<PatientTreatmentModel> _patientTreatments = [];
  final Set<int> _selectedTreatmentIds = {};

  bool _isLoadingPatients = true;
  bool _isLoadingTreatments = false;
  bool _isSubmitting = false;
  bool _isCustomPrice = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final list = await _patientsApi.getPatients();

      // Look up completed treatments across patients ready to be invoiced
      try {
        final completed = await _treatmentsApi.getTreatments(status: 'completed');
        for (final t in completed) {
          _patientUnbilledCount[t.patientId] = (_patientUnbilledCount[t.patientId] ?? 0) + 1;
        }
      } catch (_) {}

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

  String _formatNumber(double val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  void _syncTotalPrice({bool force = false}) {
    if (!_isCustomPrice || force) {
      _totalPriceController.text = _formatNumber(_computedTotal);
      _isCustomPrice = false;
    }
  }

  Future<void> _onPatientSelected(PatientModel? patient) async {
    setState(() {
      _selectedPatient = patient;
      _selectedTreatmentIds.clear();
      _patientTreatments.clear();
      _isCustomPrice = false;
      _totalPriceController.text = '0';
    });

    if (patient?.id != null) {
      setState(() => _isLoadingTreatments = true);
      try {
        final list = await _patientsApi.getPatientTreatments(patient!.id!);
        // Only completed (réalisés) treatments are eligible for invoicing
        final billable = list.where((t) => t.status == 'completed').toList();
        if (mounted) {
          setState(() {
            _patientTreatments = billable;
            // Pre-select all completed treatments by default
            _selectedTreatmentIds.addAll(billable.map((t) => t.id));
            _isLoadingTreatments = false;
            _syncTotalPrice(force: true);
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

  double get _currentEnteredTotal {
    final parsed = double.tryParse(
      _totalPriceController.text.replaceAll(' ', '').replaceAll(',', '.'),
    );
    return parsed ?? _computedTotal;
  }

  double get _currentDiscount {
    return _computedTotal - _currentEnteredTotal;
  }

  void _applyPercentageDiscount(double percent) {
    setState(() {
      _isCustomPrice = true;
      final discounted = _computedTotal * (1 - (percent / 100));
      _totalPriceController.text = _formatNumber(discounted > 0 ? discounted : 0);
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

    final double? parsedCustomTotal = double.tryParse(
      _totalPriceController.text.replaceAll(' ', '').replaceAll(',', '.'),
    );
    final double finalTotal = parsedCustomTotal ?? _computedTotal;

    if (finalTotal < 0) {
      Get.snackbar(
        'Montant invalide',
        'Le montant total de la facture ne peut pas être négatif.',
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final controller = Get.find<InvoicesController>();
    setState(() => _isSubmitting = true);

    bool success;

    if (!_isCustomPrice || (finalTotal - _computedTotal).abs() < 0.01) {
      // Standard creation using treatment IDs
      success = await controller.createInvoice(
        patientId: _selectedPatient!.id!,
        treatmentIds: _selectedTreatmentIds.toList(),
      );
    } else {
      // Custom total with proportional reduction/adjustment
      final List<PatientTreatmentModel> selectedTreatments = _patientTreatments
          .where((t) => _selectedTreatmentIds.contains(t.id))
          .toList();

      final double baseSum = _computedTotal > 0 ? _computedTotal : 1.0;
      final double ratio = finalTotal / baseSum;

      double currentSum = 0.0;
      final List<Map<String, dynamic>> customItems = [];

      for (int i = 0; i < selectedTreatments.length; i++) {
        final t = selectedTreatments[i];
        double adjustedPrice;
        if (i == selectedTreatments.length - 1) {
          adjustedPrice = finalTotal - currentSum;
          if (adjustedPrice < 0) adjustedPrice = 0.0;
        } else {
          adjustedPrice = double.parse((t.price * ratio).toStringAsFixed(2));
          currentSum += adjustedPrice;
        }

        customItems.add({
          'description': '${t.displayName} (${t.toothLabel})',
          'amount': adjustedPrice,
          'treatment_id': t.id,
        });
      }

      success = await controller.createInvoice(
        patientId: _selectedPatient!.id!,
        treatmentIds: [],
        customItems: customItems,
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusXxl),
      child: Container(
        width: 720,
        padding: AppSpacing.dialogPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const AppDialogHeader(
              title: 'Établir une Nouvelle Facture',
              subtitle: 'Sélectionnez les actes réalisés et ajustez le montant si besoin',
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
            else if (_selectedPatient != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.borderRadiusLg,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.borderRadiusMd,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _selectedPatient!.initials,
                        style: AppTypography.buttonSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                                _selectedPatient!.fullName,
                                style: AppTypography.formLabel.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (_patientTreatments.isNotEmpty) ...[
                                AppSpacing.hGap8,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: AppRadius.borderRadiusSm,
                                  ),
                                  child: Text(
                                    '${_patientTreatments.length} acte${_patientTreatments.length > 1 ? 's' : ''} chargé${_patientTreatments.length > 1 ? 's' : ''}',
                                    style: AppTypography.badgeSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          AppSpacing.vGap2,
                          Text(
                            _selectedPatient!.phone != null &&
                                    _selectedPatient!.phone!.isNotEmpty
                                ? 'Tél : ${_selectedPatient!.phone}'
                                : 'Sans numéro de téléphone',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Changer de patient',
                      color: AppColors.textSecondary,
                      onPressed: () => _onPatientSelected(null),
                    ),
                  ],
                ),
              )
            else
              Autocomplete<PatientModel>(
                displayStringForOption: (p) =>
                    '${p.fullName} (${p.phone ?? 'Sans tél'})',
                optionsBuilder: (textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();

                  // Sort patients: those with unbilled treatments come first
                  final sorted = List<PatientModel>.from(_allPatients);
                  sorted.sort((a, b) {
                    final aCount = _patientUnbilledCount[a.id] ?? 0;
                    final bCount = _patientUnbilledCount[b.id] ?? 0;
                    if (aCount > 0 && bCount == 0) return -1;
                    if (aCount == 0 && bCount > 0) return 1;
                    if (aCount != bCount) return bCount.compareTo(aCount);
                    return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
                  });

                  if (query.isEmpty) {
                    return sorted;
                  }

                  return sorted.where((p) {
                    final matchName = p.fullName.toLowerCase().contains(query);
                    final matchPhone = (p.phone ?? '').toLowerCase().contains(query);
                    return matchName || matchPhone;
                  });
                },
                onSelected: _onPatientSelected,
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText:
                          'Rechercher par nom ou numéro de téléphone (400+ patients)...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_drop_down_rounded, size: 24),
                        onPressed: () {
                          if (!focusNode.hasFocus) {
                            focusNode.requestFocus();
                          }
                        },
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: AppRadius.borderRadiusLg,
                      child: Container(
                        width: 660,
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.borderRadiusLg,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            final unbilledCount =
                                _patientUnbilledCount[option.id] ?? 0;

                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: unbilledCount > 0
                                            ? AppColors.warningLight
                                            : AppColors.primaryLight,
                                        borderRadius: AppRadius.borderRadiusMd,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        option.initials,
                                        style: AppTypography.caption.copyWith(
                                          color: unbilledCount > 0
                                              ? AppColors.warningDark
                                              : AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    AppSpacing.hGap12,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.fullName,
                                            style:
                                                AppTypography.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            option.phone != null &&
                                                    option.phone!.isNotEmpty
                                                ? option.phone!
                                                : 'Sans téléphone',
                                            style:
                                                AppTypography.caption.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (unbilledCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.warningLight,
                                          borderRadius: AppRadius.borderRadiusSm,
                                          border: Border.all(
                                            color: AppColors.warning
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Text(
                                          '$unbilledCount acte${unbilledCount > 1 ? 's' : ''} réalisé${unbilledCount > 1 ? 's' : ''}',
                                          style: AppTypography.badgeSmall
                                              .copyWith(
                                            color: AppColors.warningDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.textMuted,
                                    size: 26,
                                  ),
                                  AppSpacing.vGap6,
                                  Text(
                                    'Aucun acte réalisé (terminé) à facturer.',
                                    style: AppTypography.formLabel.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  AppSpacing.vGap2,
                                  Text(
                                    'Les actes planifiés ou en cours doivent d\'abord être marqués comme "Réalisé".',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Builder(
                          builder: (context) {
                            final grouped = InvoiceItemGrouper.groupPatientTreatments(_patientTreatments);

                            return ListView.separated(
                              itemCount: grouped.length,
                              separatorBuilder: (_, _) => AppSpacing.vGap6,
                              itemBuilder: (context, index) {
                                final group = grouped[index];
                                final allSelected = group.treatmentIds
                                    .every((id) => _selectedTreatmentIds.contains(id));
                                final anySelected = group.treatmentIds
                                    .any((id) => _selectedTreatmentIds.contains(id));
                                final bool? checkVal =
                                    allSelected ? true : (anySelected ? null : false);

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: AppDecorations.panel,
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: checkVal,
                                        tristate: true,
                                        activeColor: AppColors.primary,
                                        onChanged: (val) {
                                          setState(() {
                                            if (allSelected) {
                                              _selectedTreatmentIds
                                                  .removeAll(group.treatmentIds);
                                            } else {
                                              _selectedTreatmentIds
                                                  .addAll(group.treatmentIds);
                                            }
                                            _syncTotalPrice();
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
                                              group.title,
                                              style: AppTypography.formLabel.copyWith(
                                                fontWeight: group.treatmentIds.length > 1
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              group.subtitle,
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        group.formattedTotal,
                                        style: AppTypography.formLabel.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),

            AppSpacing.vGap16,

            // Total Summary Banner (Editable with reduction support)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.borderRadiusLg,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppRadius.borderRadiusMd,
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          AppSpacing.hGap10,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL DE LA FACTURE :',
                                style: AppTypography.formLabel.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Modifiable pour appliquer une réduction',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Interactive Price Input
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 170,
                            height: 42,
                            child: TextFormField(
                              controller: _totalPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              style: AppTypography.h3.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                suffixText: 'DA',
                                suffixStyle: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.borderRadiusMd,
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.borderRadiusMd,
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.borderRadiusMd,
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _isCustomPrice = true;
                                });
                              },
                            ),
                          ),
                          if (_isCustomPrice) ...[
                            AppSpacing.hGap6,
                            IconButton(
                              icon: const Icon(Icons.restart_alt_rounded, size: 20),
                              tooltip: 'Rétablir le montant calculé',
                              color: AppColors.textSecondary,
                              onPressed: () {
                                setState(() {
                                  _syncTotalPrice(force: true);
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // Quick Discount Buttons + Reduction summary
                  AppSpacing.vGap10,
                  const Divider(height: 1),
                  AppSpacing.vGap10,

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Preset discount chips
                      Row(
                        children: [
                          Text(
                            'Remise rapide :',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          AppSpacing.hGap8,
                          _buildDiscountChip(5),
                          AppSpacing.hGap6,
                          _buildDiscountChip(10),
                          AppSpacing.hGap6,
                          _buildDiscountChip(15),
                          AppSpacing.hGap6,
                          _buildDiscountChip(20),
                        ],
                      ),

                      // Difference badge
                      if (_isCustomPrice && _currentDiscount.abs() >= 0.01)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _currentDiscount > 0
                                ? AppColors.successLight
                                : AppColors.warningLight,
                            borderRadius: AppRadius.borderRadiusFull,
                          ),
                          child: Text(
                            _currentDiscount > 0
                                ? 'Réduction : -${DateFormatter.formatCurrency(_currentDiscount)} (-${((_currentDiscount / (_computedTotal > 0 ? _computedTotal : 1)) * 100).toStringAsFixed(1)}%)'
                                : 'Majoration : +${DateFormatter.formatCurrency(-_currentDiscount)}',
                            style: AppTypography.badgeSmall.copyWith(
                              color: _currentDiscount > 0
                                  ? AppColors.success
                                  : AppColors.warningDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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

  Widget _buildDiscountChip(double percent) {
    return InkWell(
      onTap: _computedTotal > 0 ? () => _applyPercentageDiscount(percent) : null,
      borderRadius: AppRadius.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.borderRadiusSm,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '-${percent.toInt()}%',
          style: AppTypography.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
