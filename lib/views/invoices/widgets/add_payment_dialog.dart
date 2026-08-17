import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/models/invoice_model.dart';
import 'package:flutter_application_1/models/payment_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_application_1/widgets/app_dialog_header.dart';
import 'package:flutter_application_1/widgets/app_date_picker.dart';

class AddPaymentDialog extends StatefulWidget {
  final InvoiceModel invoice;

  const AddPaymentDialog({super.key, required this.invoice});

  static Future<PaymentModel?> show(BuildContext context, {required InvoiceModel invoice}) {
    return showDialog<PaymentModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddPaymentDialog(invoice: invoice),
    );
  }

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();

  String _selectedMethod = 'cash';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: '${widget.invoice.remainingAmount}',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Date du règlement',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final payment = PaymentModel(
      invoiceId: widget.invoice.id!,
      amount: amount,
      paymentDate: DateFormatter.toApiString(_selectedDate),
      paymentMethod: _selectedMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    Navigator.of(context).pop(payment);
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              AppDialogHeader(
                title: 'Enregistrer un Règlement',
                subtitle: 'Facture : ${widget.invoice.invoiceNumber} (${widget.invoice.displayPatientName})',
                icon: Icons.payments_rounded,
                iconColor: AppColors.success,
                iconBgColor: AppColors.successLight,
              ),

              // Remaining Balance Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xl,
                ),
                decoration: AppDecorations.warningBanner,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reste à payer sur cette facture :',
                      style: AppTypography.formLabel,
                    ),
                    Text(
                      widget.invoice.formattedRemaining,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.warningDark,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.vGap16,

              // Amount & Payment Method Row
              Row(
                children: [
                  // Amount Field
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Montant versé (DA) *',
                          style: AppTypography.formLabel,
                        ),
                        AppSpacing.vGap6,
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Ex: 5000',
                            suffixText: 'DA',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Montant obligatoire';
                            }
                            final numVal = double.tryParse(val.trim());
                            if (numVal == null || numVal <= 0) {
                              return 'Montant invalide (>0)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hGap16,

                  // Payment Method
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode de règlement',
                          style: AppTypography.formLabel,
                        ),
                        AppSpacing.vGap6,
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMethod,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'cash',
                              child: Row(
                                children: [
                                  Icon(Icons.money_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Espèces',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'card',
                              child: Row(
                                children: [
                                  Icon(Icons.credit_card_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Carte bancaire',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'transfer',
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Virement',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Row(
                                children: [
                                  Icon(Icons.more_horiz_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Autre',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMethod = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              AppSpacing.vGap16,

              // Date Picker
              Text(
                'Date du paiement',
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

              // Notes
              Text(
                'Notes & Références (Optionnel)',
                style: AppTypography.formLabel,
              ),
              AppSpacing.vGap6,
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Acompte sur couronne, reçu n°...',
                ),
              ),

              AppSpacing.vGap24,
              const Divider(),
              AppSpacing.vGap16,

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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('Valider le Règlement', style: AppTypography.button),
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
