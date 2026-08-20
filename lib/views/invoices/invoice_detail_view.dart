import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoices_controller.dart';
import '../../models/invoice_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../core/utils/invoice_item_grouper.dart';
import 'widgets/add_payment_dialog.dart';

class InvoiceDetailView extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailView({super.key, required this.invoice});

  Future<void> _openAddPaymentDialog(BuildContext context) async {
    final controller = Get.find<InvoicesController>();
    final payment = await AddPaymentDialog.show(context, invoice: invoice);
    if (payment != null && invoice.id != null) {
      await controller.addPayment(invoice.id!, payment);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = Get.find<InvoicesController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la facture', style: AppTypography.h3),
        content: Text(
          'Voulez-vous supprimer définitivement la facture ${invoice.invoiceNumber} ?',
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

    if (confirm == true && invoice.id != null) {
      await controller.deleteInvoice(invoice.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Header ---
          _buildHeader(context),

          const Divider(height: 1),

          // --- Scrollable Details Body ---
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Financial Summary Metrics Row
                  _buildFinancialSummary(),

                  AppSpacing.vGap28,

                  // 2. Line Items Table
                  _buildLineItemsSection(),

                  AppSpacing.vGap28,

                  // 3. Payment Transactions History
                  _buildPaymentsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.giant,
        vertical: AppSpacing.xxxl,
      ),
      child: Row(
        children: [
          // Icon Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.borderRadiusXl,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          AppSpacing.hGap16,

          // Title & Patient
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: AppTypography.h2,
                    ),
                    AppSpacing.hGap12,
                    StatusBadge.invoice(invoice.status),
                  ],
                ),
                AppSpacing.vGap4,
                Text(
                  'Patient : ${invoice.displayPatientName} • Émise le ${invoice.formattedDate}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),

          // Action: Add Payment
          if (!invoice.isPaid) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _openAddPaymentDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Encaisser un règlement', style: AppTypography.button),
            ),
            AppSpacing.hGap12,
          ],

          // Action: PDF Export
          Obx(() {
            final controller = Get.find<InvoicesController>();
            final isExporting = controller.isPdfExporting.value;

            return OutlinedButton.icon(
              onPressed: isExporting
                  ? null
                  : () => controller.exportInvoicePdf(invoice),
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: Text(
                isExporting ? 'Exportation...' : 'Exporter PDF',
                style: AppTypography.button,
              ),
            );
          }),

          AppSpacing.hGap10,

          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textMuted, size: 20),
            tooltip: 'Supprimer la facture',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Row(
      children: [
        // Total Amount
        Expanded(
          child: _buildMetricCard(
            'TOTAL FACTURÉ',
            invoice.formattedTotal,
            AppColors.primary,
            AppColors.primaryLight,
            Icons.receipt_rounded,
          ),
        ),
        AppSpacing.hGap16,

        // Paid Amount
        Expanded(
          child: _buildMetricCard(
            'TOTAL RÉGLÉ',
            invoice.formattedPaid,
            AppColors.success,
            AppColors.successLight,
            Icons.check_circle_outline_rounded,
          ),
        ),
        AppSpacing.hGap16,

        // Remaining Balance
        Expanded(
          child: _buildMetricCard(
            'RESTE À PAYER',
            invoice.formattedRemaining,
            invoice.isPaid ? AppColors.textMuted : AppColors.danger,
            invoice.isPaid ? AppColors.background : AppColors.dangerLight,
            Icons.pending_actions_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String amount,
    Color color,
    Color bgColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderRadiusXl,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderRadiusLg,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          AppSpacing.hGap14,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.kpiLabel.copyWith(color: color),
                ),
                AppSpacing.vGap4,
                Text(
                  amount,
                  style: AppTypography.h3.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsSection() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: AppDecorations.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détail des Prestations & Actes Inclus',
            style: AppTypography.h4,
          ),
          AppSpacing.vGap14,
          const Divider(height: 1),
          AppSpacing.vGap10,

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text('#', style: AppTypography.caption),
                ),
                Expanded(
                  child: Text('Description de la prestation',
                      style: AppTypography.caption),
                ),
                Text('Montant', style: AppTypography.caption),
              ],
            ),
          ),
          const Divider(height: 1),

          Builder(
            builder: (context) {
              if (invoice.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                  child: Center(
                    child: Text(
                      'Aucune prestation détaillée enregistrée.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                );
              }

              final groupedItems = InvoiceItemGrouper.groupInvoiceItems(invoice.items);

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedItems.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = groupedItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTypography.formLabel.copyWith(
                                  fontWeight: item.count > 1
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                              if (item.subtitle != null) ...[
                                AppSpacing.vGap2,
                                Text(
                                  item.subtitle!,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          item.formattedTotal,
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

          const Divider(height: 1),
          AppSpacing.vGap12,

          // Total line
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Net :',
                  style: AppTypography.h4,
                ),
                Text(
                  invoice.formattedTotal,
                  style: AppTypography.h3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: AppDecorations.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique des Règlements Encaissés',
                style: AppTypography.h4,
              ),
              if (!invoice.isPaid)
                TextButton.icon(
                  onPressed: () => _openAddPaymentDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Ajouter un paiement',
                      style: AppTypography.buttonSmall),
                ),
            ],
          ),
          AppSpacing.vGap14,

          if (invoice.payments.isEmpty)
            const EmptyState(
              icon: Icons.payments_outlined,
              title: 'Aucun paiement enregistré',
              message:
                  'Cette facture n\'a encore fait l\'objet d\'aucun encaissement.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoice.payments.length,
              separatorBuilder: (_, _) => AppSpacing.vGap8,
              itemBuilder: (context, index) {
                final pay = invoice.payments[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.xl,
                  ),
                  decoration: AppDecorations.panelBg,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: AppRadius.borderRadiusMd,
                        ),
                        child: const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 18),
                      ),
                      AppSpacing.hGap14,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pay.formattedAmount,
                                  style: AppTypography.formLabel,
                                ),
                                AppSpacing.hGap10,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: AppDecorations.panel,
                                  child: Text(
                                    pay.methodLabelFr,
                                    style: AppTypography.badgeSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.vGap2,
                            Text(
                              'Date : ${pay.formattedDate}',
                              style: AppTypography.bodySmall,
                            ),
                            if (pay.notes != null &&
                                pay.notes!.trim().isNotEmpty) ...[
                              AppSpacing.vGap2,
                              Text(
                                pay.notes!,
                                style: AppTypography.caption.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}






