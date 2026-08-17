import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/patients_controller.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/models/patient_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/app_dialog_header.dart';
import 'package:flutter_application_1/widgets/app_date_picker.dart';

class PatientFormDialog extends StatefulWidget {
  final PatientModel? initialPatient;

  const PatientFormDialog({super.key, this.initialPatient});

  static Future<PatientModel?> show(BuildContext context, {PatientModel? patient}) {
    return showDialog<PatientModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PatientFormDialog(initialPatient: patient),
    );
  }

  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _medicalHistoryController;
  late final TextEditingController _notesController;

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPatient;
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _medicalHistoryController = TextEditingController(text: p?.medicalHistory ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    if (p?.birthDate != null) {
      _selectedBirthDate = DateFormatter.fromApiString(p!.birthDate);
    }
    _selectedGender = p?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _cleanErrorMessage(dynamic error) {
    String msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring('Exception: '.length);
    }
    if (msg.contains('status code of 409') ||
        msg.toLowerCase().contains('already exists') ||
        msg.toLowerCase().contains('existe déjà')) {
      return 'Un patient avec ces coordonnées ou ce numéro de téléphone existe déjà.';
    }
    if (msg.contains('status code of 422') ||
        msg.toLowerCase().contains('unprocessable')) {
      return 'Certaines informations saisies ne sont pas valides. Veuillez vérifier les champs.';
    }
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('connectTimeout')) {
      return 'Impossible de contacter le serveur. Veuillez vérifier votre connexion.';
    }
    return msg;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 30);
    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final patient = PatientModel(
      id: widget.initialPatient?.id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      birthDate: _selectedBirthDate != null
          ? DateFormatter.toApiString(_selectedBirthDate!)
          : null,
      gender: _selectedGender,
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim().isEmpty
          ? null
          : _medicalHistoryController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      final controller = Get.isRegistered<PatientsController>()
          ? Get.find<PatientsController>()
          : Get.put(PatientsController());

      PatientModel? result;
      if (widget.initialPatient != null && widget.initialPatient!.id != null) {
        result = await controller.updatePatient(widget.initialPatient!.id!, patient);
      } else {
        result = await controller.createPatient(patient);
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result != null) {
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = _cleanErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPatient != null;

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
              // --- Header ---
              AppDialogHeader(
                title: isEditing ? 'Modifier le Patient' : 'Nouveau Dossier Patient',
                subtitle: isEditing
                    ? 'Mettre à jour les informations du patient'
                    : 'Renseignez les coordonnées et antécédents médicaux',
                icon: isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
              ),

              // --- In-Dialog Error Alert Banner ---
              if (_errorMessage != null) ...[
                AppSpacing.vGap12,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: AppRadius.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      AppSpacing.hGap10,
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.dangerDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _errorMessage = null),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              AppSpacing.vGap16,

              // --- Scrollable Form Content ---
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name (Required)
                      Text(
                        'Nom et Prénom *',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Karim Benali',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Le nom du patient est obligatoire.';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.vGap16,

                      // Phone & Gender Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Numéro de Téléphone',
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
                          AppSpacing.hGap16,
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sexe',
                                  style: AppTypography.formLabel,
                                ),
                                AppSpacing.vGap6,
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedGender,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  hint: Text('Sélectionner',
                                      style: AppTypography.bodyMedium,
                                      overflow: TextOverflow.ellipsis),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Text(
                                        'Homme',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Text(
                                        'Femme',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) => setState(() => _selectedGender = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGap16,

                      // Birth Date & Address Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date de Naissance',
                                  style: AppTypography.formLabel,
                                ),
                                AppSpacing.vGap6,
                                InkWell(
                                  onTap: _pickBirthDate,
                                  borderRadius: AppRadius.borderRadiusLg,
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                                    decoration: AppDecorations.panel,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.cake_outlined,
                                          color: AppColors.textSecondary,
                                          size: 20,
                                        ),
                                        AppSpacing.hGap10,
                                        Text(
                                          _selectedBirthDate != null
                                              ? DateFormatter.formatMedium(_selectedBirthDate!)
                                              : 'Sélectionner la date',
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: _selectedBirthDate != null
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (_selectedBirthDate != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear, size: 16),
                                            onPressed: () =>
                                                setState(() => _selectedBirthDate = null),
                                          ),
                                      ],
                                    ),
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
                        'Adresse de résidence',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Cité 500 Logements, Bâtiment B, Alger',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        ),
                      ),
                      AppSpacing.vGap16,

                      // Medical History & Allergies (Highlighted Alert Box)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: AppDecorations.warningBanner,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.warning, size: 20),
                                AppSpacing.hGap8,
                                Text(
                                  'Antécédents Médicaux & Allergies',
                                  style: AppTypography.h5,
                                ),
                              ],
                            ),
                            AppSpacing.vGap4,
                            Text(
                              'Informations critiques : diabète, hypertension, allergies pénicilline/anesthésie, etc.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            AppSpacing.vGap8,
                            TextFormField(
                              controller: _medicalHistoryController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText:
                                    'Ex: Allergique à la pénicilline, sujet à hypertension artérielle...',
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.borderRadiusMd,
                                  borderSide: BorderSide(
                                    color: AppColors.warning.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vGap16,

                      // Notes
                      Text(
                        'Notes & Remarques du praticien',
                        style: AppTypography.formLabel,
                      ),
                      AppSpacing.vGap6,
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Notes diverses sur les préférences ou le suivi du patient...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.vGap20,
              const Divider(),
              AppSpacing.vGap16,

              // --- Actions Footer ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                      _isSubmitting
                          ? 'Enregistrement...'
                          : (isEditing ? 'Enregistrer les modifications' : 'Créer le dossier'),
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
