import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoices_controller.dart';
import '../../models/invoice_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_input.dart';
import '../../widgets/status_badge.dart';
import 'widgets/create_invoice_dialog.dart';
import 'invoice_detail_view.dart';

class InvoicesView extends StatelessWidget {
  const InvoicesView({super.key});

  Future<void> _openCreateInvoiceDialog(BuildContext context) async {
    await CreateInvoiceDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvoicesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 850;

          final listPanel = Container(
            width: isNarrow ? null : 400,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // 1. Panel Header & Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      Obx(() {
                        final total = controller.invoices.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Factures & Règlements',
                              style: AppTypography.h4,
                            ),
                            Text(
                              '$total facture${total > 1 ? 's' : ''} émise${total > 1 ? 's' : ''}',
                              style: AppTypography.caption,
                            ),
                          ],
                        );
                      }),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _openCreateInvoiceDialog(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text('Facturer', style: AppTypography.buttonSmall),
                      ),
                    ],
                  ),
                ),

                // 2. Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: SearchInput(
                    hintText: 'Rechercher facture, patient...',
                    onChanged: (val) => controller.search(val),
                  ),
                ),

                AppSpacing.vGap12,

                // 3. Status Filters Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Obx(() {
                    final current = controller.statusFilter.value;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Toutes', 'all', current, controller),
                          AppSpacing.hGap6,
                          _buildFilterChip(
                              'Non payées', 'unpaid', current, controller),
                          AppSpacing.hGap6,
                          _buildFilterChip(
                              'Partielles', 'partially_paid', current, controller),
                          AppSpacing.hGap6,
                          _buildFilterChip('Payées', 'paid', current, controller),
                        ],
                      ),
                    );
                  }),
                ),

                AppSpacing.vGap12,
                const Divider(height: 1),

                // 4. Invoices List
                Expanded(
                  child: Obx(() {
                    final selectedId = controller.selectedInvoice.value?.id;

                    if (controller.isLoading.value &&
                        controller.invoices.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.errorMessage.isNotEmpty &&
                        controller.invoices.isEmpty) {
                      return EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Connexion indisponible',
                        message: controller.errorMessage.value,
                        action: OutlinedButton.icon(
                          onPressed: () => controller.fetchInvoices(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text('Réessayer', style: AppTypography.buttonSmall),
                        ),
                      );
                    }

                    final list = controller.filteredInvoices;

                    if (list.isEmpty) {
                      return EmptyState(
                        icon: Icons.receipt_outlined,
                        title: 'Aucune facture trouvée',
                        message: controller.searchQuery.isEmpty
                            ? 'Cliquez sur "Facturer" pour créer votre première facture.'
                            : 'Aucun résultat pour "${controller.searchQuery.value}".',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => controller.fetchInvoices(),
                      child: ListView.separated(
                        padding: AppSpacing.listItemPadding,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => AppSpacing.vGap6,
                        itemBuilder: (context, index) {
                          final invoice = list[index];
                          final isSelected = selectedId == invoice.id;

                          return _InvoiceListItem(
                            invoice: invoice,
                            isSelected: isSelected,
                            onTap: () => controller.selectInvoice(invoice),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              isNarrow ? Expanded(flex: 4, child: listPanel) : listPanel,

              // --- Right Detail Panel ---
              Expanded(
                flex: isNarrow ? 6 : 1,
                child: Obx(() {
                  final selected = controller.selectedInvoice.value;
                  if (selected == null) {
                    return const EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'Sélectionnez une facture',
                      message:
                          'Cliquez sur une facture dans la liste de gauche pour consulter son détail et ses encaissements.',
                    );
                  }

                  return InvoiceDetailView(
                    key: ValueKey(selected.id),
                    invoice: selected,
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String current,
    InvoicesController controller,
  ) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => controller.setFilter(value),
      borderRadius: AppRadius.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.badgeSmall.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _InvoiceListItem extends StatefulWidget {
  final InvoiceModel invoice;
  final bool isSelected;
  final VoidCallback onTap;

  const _InvoiceListItem({
    required this.invoice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InvoiceListItem> createState() => _InvoiceListItemState();
}

class _InvoiceListItemState extends State<_InvoiceListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;

    Color bgColor = Colors.transparent;
    Color borderColor = Colors.transparent;

    if (widget.isSelected) {
      bgColor = AppColors.primaryLight;
      borderColor = AppColors.primary.withValues(alpha: 0.4);
    } else if (_isHovered) {
      bgColor = AppColors.background;
      borderColor = AppColors.border;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: AppTypography.h5.copyWith(
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge.invoice(invoice.status),
                ],
              ),
              AppSpacing.vGap6,
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 13, color: AppColors.textSecondary),
                  AppSpacing.hGap4,
                  Expanded(
                    child: Text(
                      invoice.displayPatientName,
                      style: AppTypography.formLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    invoice.formattedTotal,
                    style: AppTypography.formLabel,
                  ),
                ],
              ),
              AppSpacing.vGap4,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.formattedDate,
                    style: AppTypography.caption,
                  ),
                  if (!invoice.isPaid)
                    Text(
                      'Reste : ${invoice.formattedRemaining}',
                      style: AppTypography.badgeSmall.copyWith(
                        color: AppColors.danger,
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






