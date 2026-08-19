import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/appointments_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/data/patients_api.dart';
import 'package:flutter_application_1/models/patient_model.dart';
import 'package:flutter_application_1/models/appointment_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/app_dialog_header.dart';
import 'package:flutter_application_1/widgets/app_date_picker.dart';
import 'package:flutter_application_1/views/patients/widgets/patient_form_dialog.dart';

class BookAppointmentDialog extends StatefulWidget {
  final DateTime? initialDate;
  final int? initialPatientId;
  final PatientModel? initialPatient;
  final String? initialReason;

  const BookAppointmentDialog({
    super.key,
    this.initialDate,
    this.initialPatientId,
    this.initialPatient,
    this.initialReason,
  });

  static Future<bool?> show(
    BuildContext context, {
    DateTime? initialDate,
    int? initialPatientId,
    PatientModel? initialPatient,
    String? initialReason,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookAppointmentDialog(
        initialDate: initialDate,
        initialPatientId: initialPatientId,
        initialPatient: initialPatient,
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
  AppointmentModel? _existingUpcomingAppointment;
  late DateTime _selectedDate;
  bool _isLoadingPatients = true;
  bool _isSubmitting = false;
  bool _isUpdatingExisting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedPatient = widget.initialPatient;
    if (widget.initialReason != null) {
      _reasonController.text = widget.initialReason!;
    }
    if (_selectedPatient?.id != null) {
      _checkExistingAppointment(_selectedPatient!.id!);
    } else if (widget.initialPatientId != null) {
      _checkExistingAppointment(widget.initialPatientId!);
    }
    _loadPatients();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingAppointment(int patientId) async {
    try {
      final appointmentsController = Get.isRegistered<AppointmentsController>()
          ? Get.find<AppointmentsController>()
          : Get.put(AppointmentsController());
      final app = await appointmentsController.getUpcomingAppointmentForPatient(patientId);
      if (mounted) {
        setState(() {
          _existingUpcomingAppointment = app;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPatients() async {
    try {
      final list = await _patientsApi.getPatients();
      if (mounted) {
        setState(() {
          _allPatients = list;
          if (_selectedPatient == null && widget.initialPatientId != null) {
            _selectedPatient = list.firstWhereOrNull(
              (p) => p.id == widget.initialPatientId,
            );
            if (_selectedPatient?.id != null) {
              _checkExistingAppointment(_selectedPatient!.id!);
            }
          } else if (_selectedPatient != null) {
            final found = list.firstWhereOrNull((p) => p.id == _selectedPatient!.id);
            if (found != null) _selectedPatient = found;
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
        _existingUpcomingAppointment = null;
        _isUpdatingExisting = false;
      });
      if (created.id != null) {
        _checkExistingAppointment(created.id!);
      }
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

    // If booking a new appointment (not updating existing), check duplicate on same date
    if (!_isUpdatingExisting) {
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
    }

    // Capacity Check
    final cap = appointmentsController.weekCapacity.firstWhereOrNull(
      (c) => c.date == dateStr,
    );

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
            'Le ${DateFormatter.formatMedium(_selectedDate)} compte déjà ${cap.bookedCount} patients inscrits (limite conseillée : ${cap.limit}).\n\nSouhaitez-vous continuer et enregistrer ce rendez-vous quand même ?',
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

    bool success;
    if (_isUpdatingExisting && _existingUpcomingAppointment?.id != null) {
      success = await appointmentsController.rescheduleAppointment(
        _existingUpcomingAppointment!.id!,
        _selectedDate,
      );
    } else {
      success = await appointmentsController.bookAppointment(
        patientId: _selectedPatient!.id!,
        date: _selectedDate,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
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
        width: 580,
        padding: AppSpacing.dialogPaddingLarge,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              AppDialogHeader(
                title: _isUpdatingExisting
                    ? 'Reprogrammer le Rendez-vous'
                    : 'Prendre un Rendez-vous',
                subtitle: _isUpdatingExisting
                    ? 'Modifiez la date ou le motif de consultation du patient'
                    : 'Sélectionnez un patient et une date de consultation',
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
                  if (_selectedPatient == null)
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
              else if (_selectedPatient != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
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
                        width: 38,
                        height: 38,
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
                      AppSpacing.hGap12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPatient!.fullName,
                              style: AppTypography.formLabel.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
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
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Changer de patient',
                        color: AppColors.textSecondary,
                        onPressed: () {
                          setState(() {
                            _selectedPatient = null;
                            _existingUpcomingAppointment = null;
                            _isUpdatingExisting = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Alert banner if patient already has an upcoming appointment
                if (_existingUpcomingAppointment != null) ...[
                  AppSpacing.vGap8,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _isUpdatingExisting
                          ? AppColors.primaryLight
                          : AppColors.warningLight.withValues(alpha: 0.7),
                      borderRadius: AppRadius.borderRadiusMd,
                      border: Border.all(
                        color: _isUpdatingExisting
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isUpdatingExisting
                              ? Icons.edit_calendar_rounded
                              : Icons.info_outline_rounded,
                          color: _isUpdatingExisting
                              ? AppColors.primary
                              : AppColors.warningDark,
                          size: 20,
                        ),
                        AppSpacing.hGap10,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isUpdatingExisting
                                    ? 'Modification du rendez-vous existant'
                                    : 'Rendez-vous déjà programmé',
                                style: AppTypography.formLabel.copyWith(
                                  color: _isUpdatingExisting
                                      ? AppColors.primaryDark
                                      : AppColors.warningDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSpacing.vGap2,
                              Text(
                                _isUpdatingExisting
                                    ? 'Choisissez la nouvelle date ci-dessous pour déplacer ce rendez-vous.'
                                    : 'Ce patient a un rendez-vous le ${DateFormatter.formatFull(DateFormatter.fromApiString(_existingUpcomingAppointment!.appointmentDate) ?? DateTime.now())}${_existingUpcomingAppointment!.reason != null ? ' (${_existingUpcomingAppointment!.reason})' : ''}.',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              AppSpacing.vGap6,
                              Row(
                                children: [
                                  if (!_isUpdatingExisting) ...[
                                    InkWell(
                                      onTap: () {
                                        final parsed = DateFormatter.fromApiString(
                                          _existingUpcomingAppointment!.appointmentDate,
                                        );
                                        if (parsed != null) {
                                          setState(() {
                                            _selectedDate = parsed;
                                            if (_existingUpcomingAppointment!.reason != null &&
                                                _reasonController.text.isEmpty) {
                                              _reasonController.text =
                                                  _existingUpcomingAppointment!.reason!;
                                            }
                                            _isUpdatingExisting = true;
                                          });
                                        }
                                      },
                                      borderRadius: AppRadius.borderRadiusSm,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: AppRadius.borderRadiusSm,
                                          border: Border.all(
                                            color: AppColors.warningDark,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.edit_calendar_rounded,
                                              size: 13,
                                              color: AppColors.warningDark,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Déplacer ce RDV',
                                              style: AppTypography.badgeSmall.copyWith(
                                                color: AppColors.warningDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AppSpacing.hGap8,
                                    Text(
                                      'ou continuer pour ajouter un 2ème RDV',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ] else ...[
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isUpdatingExisting = false;
                                        });
                                      },
                                      borderRadius: AppRadius.borderRadiusSm,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: AppRadius.borderRadiusSm,
                                          border: Border.all(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        child: Text(
                                          'Créer plutôt un nouveau RDV',
                                          style: AppTypography.badgeSmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else
                Autocomplete<PatientModel>(
                  displayStringForOption: (p) =>
                      '${p.fullName} (${p.phone ?? 'Sans tél'})',
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
                    setState(() {
                      _selectedPatient = patient;
                    });
                    if (patient.id != null) {
                      _checkExistingAppointment(patient.id!);
                    }
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher par nom ou numéro de téléphone...',
                        prefixIcon:
                            Icon(Icons.search_rounded, size: 20),
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
                    label: Text(
                      _isUpdatingExisting
                          ? 'Enregistrer le déplacement'
                          : 'Confirmer le Rendez-vous',
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
