import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/appointments_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/data/patients_api.dart';
import 'package:flutter_application_1/models/patient_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/app_dialog_header.dart';
import 'package:flutter_application_1/widgets/app_date_picker.dart';
import 'package:flutter_application_1/views/patients/widgets/patient_form_dialog.dart';

class BookAppointmentDialog extends StatefulWidget {
  final DateTime? initialDate;
  final int? initialPatientId;
  final String? initialReason;

  const BookAppointmentDialog({
    super.key,
    this.initialDate,
    this.initialPatientId,
    this.initialReason,
  });

  static Future<bool?> show(
    BuildContext context, {
    DateTime? initialDate,
    int? initialPatientId,
    String? initialReason,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookAppointmentDialog(
        initialDate: initialDate,
        initialPatientId: initialPatientId,
        initialReason: initialReason,
      ),
    );
  }

  @override
  State<BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends State<BookAppointmentDialog> {
  final PatientsApi _patientsApi = PatientsApi();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<PatientModel> _allPatients = [];
  PatientModel? _selectedPatient;
  late DateTime _selectedDate;
  bool _isLoadingPatients = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (widget.initialReason != null) {
      _reasonController.text = widget.initialReason!;
    }
    _loadPatients();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      final list = await _patientsApi.getPatients();
      if (mounted) {
        setState(() {
          _allPatients = list;
          if (widget.initialPatientId != null) {
            _selectedPatient = list.firstWhereOrNull(
              (p) => p.id == widget.initialPatientId,
            );
          }
          _isLoadingPatients = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Date du rendez-vous',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addNewPatientShortcut() async {
    final created = await PatientFormDialog.show(context);
    if (created != null) {
      setState(() {
        _allPatients.insert(0, created);
        _selectedPatient = created;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedPatient == null) {
      Get.snackbar(
        'Sélection obligatoire',
        'Veuillez sélectionner un patient.',
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final appointmentsController = Get.find<AppointmentsController>();
    final dateStr = DateFormatter.toApiString(_selectedDate);

    // 1. Check if patient already has an active appointment on this date
    final existingAppointments = await appointmentsController.getAppointmentsForDate(dateStr);
    final hasDuplicate = existingAppointments.any(
      (a) => a.patientId == _selectedPatient!.id && a.status != 'cancelled',
    );
    if (hasDuplicate) {
      Get.snackbar(
        'Rendez-vous existant',
        'Ce patient a déjà un rendez-vous prévu le ${DateFormatter.formatMedium(_selectedDate)}.',
        backgroundColor: AppColors.warningLight,
        colorText: AppColors.warningDark,
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // 2. Check capacity for the target day
    final cap = appointmentsController.weekCapacity.firstWhereOrNull(
      (c) => c.date == dateStr,
    );

    // Non-blocking warning dialog if day is over limit
    if (cap != null && cap.isOverLimit) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              AppSpacing.hGap8,
              Text('Capacité conseillée atteinte', style: AppTypography.h3),
            ],
          ),
          content: Text(
            'Le ${DateFormatter.formatMedium(_selectedDate)} compte déjà ${cap.bookedCount} patients inscrits (limite conseillée : ${cap.limit}).\n\nSouhaitez-vous continuer et ajouter ce rendez-vous quand même ?',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Choisir une autre date', style: AppTypography.button),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirmer quand même', style: AppTypography.button),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() => _isSubmitting = true);

    final success = await appointmentsController.bookAppointment(
      patientId: _selectedPatient!.id!,
      date: _selectedDate,
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
        width: 580,
        padding: AppSpacing.dialogPaddingLarge,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              const AppDialogHeader(
                title: 'Prendre un Rendez-vous',
                subtitle: 'Sélectionnez un patient et une date de consultation',
                icon: Icons.calendar_today_rounded,
              ),

              // --- Patient Selector ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Patient *',
                    style: AppTypography.formLabel,
                  ),
                  TextButton.icon(
                    onPressed: _addNewPatientShortcut,
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: Text('Nouveau patient', style: AppTypography.buttonSmall),
                  ),
                ],
              ),
              AppSpacing.vGap6,

              if (_isLoadingPatients)
                const LinearProgressIndicator()
              else
                Autocomplete<PatientModel>(
                  displayStringForOption: (p) => p.fullName,
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _allPatients;
                    }
                    final q = textEditingValue.text.toLowerCase();
                    return _allPatients.where((p) {
                      return p.fullName.toLowerCase().contains(q) ||
                          (p.phone?.toLowerCase().contains(q) ?? false);
                    });
                  },
                  onSelected: (patient) {
                    setState(() => _selectedPatient = patient);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom ou numéro de téléphone...',
                        prefixIcon:
                            const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _selectedPatient != null
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 20)
                            : null,
                      ),
                    );
                  },
                ),

              AppSpacing.vGap16,

              // --- Date Selector ---
              Text(
                'Date de consultation *',
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
                      const Icon(Icons.event_rounded,
                          color: AppColors.primary, size: 20),
                      AppSpacing.hGap10,
                      Text(
                        DateFormatter.formatFull(_selectedDate),
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
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

              // --- Reason / Motif ---
              Text(
                'Motif de la visite',
                style: AppTypography.formLabel,
              ),
              AppSpacing.vGap6,
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Consultation de routine, Douleur molaire, Détartrage...',
                  prefixIcon: Icon(Icons.medical_information_outlined, size: 20),
                ),
              ),

              AppSpacing.vGap16,

              // --- Notes ---
              Text(
                'Notes complémentaires',
                style: AppTypography.formLabel,
              ),
              AppSpacing.vGap6,
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Remarques éventuelles sur la visite...',
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
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text('Confirmer le Rendez-vous', style: AppTypography.button),
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
