import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoices_controller.dart';
import '../../models/invoice_model.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../widgets/app_date_picker.dart';
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

  Future<void> _pickSingleDate(BuildContext context, InvoicesController controller) async {
    final now = DateTime.now();
    final initial = controller.filterDate.value ?? now;
    final picked = await showAppDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Filtrer par date précise',
    );
    if (picked != null) {
      controller.setSingleDate(picked);
    }
  }

  Future<void> _pickDateRange(BuildContext context, InvoicesController controller) async {
    final now = DateTime.now();
    final initialStart = controller.filterDateFrom.value ?? now.subtract(const Duration(days: 7));
    final initialEnd = controller.filterDateTo.value ?? now;
    final picked = await showAppDateRangePicker(
      context: context,
      initialDates: [initialStart, initialEnd],
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Filtrer par période',
    );
    if (picked != null && picked.isNotEmpty) {
      final start = picked.first;
      final end = picked.length > 1 ? picked.last : picked.first;
      controller.setDateRange(start, end);
    }
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
            width: isNarrow ? null : 420,
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
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Obx(() {
                        final count = controller.filteredInvoices.length;
                        final total = controller.invoices.length;
                        final isFiltered = controller.hasActiveFilters;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Factures & Règlements',
                              style: AppTypography.h4,
                            ),
                            Text(
                              isFiltered
                                  ? '$count / $total facture${total > 1 ? 's' : ''}'
                                  : '$total facture${total > 1 ? 's' : ''} émise${total > 1 ? 's' : ''}',
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

                AppSpacing.vGap10,

                // 3. Quick Date Presets Row (Toutes, Aujourd'hui, Semaine, Mois)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Obx(() {
                    final current = controller.datePreset.value;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildPresetChip('Toutes', 'all', current, () {
                            controller.setDatePreset('all');
                          }),
                        ),
                        AppSpacing.hGap6,
                        Expanded(
                          child: _buildPresetChip('Aujourd\'hui', 'today', current, () {
                            controller.setDatePreset('today');
                          }),
                        ),
                        AppSpacing.hGap6,
                        Expanded(
                          child: _buildPresetChip('Semaine', 'week', current, () {
                            controller.setDatePreset('week');
                          }),
                        ),
                        AppSpacing.hGap6,
                        Expanded(
                          child: _buildPresetChip('Mois', 'month', current, () {
                            controller.setDatePreset('month');
                          }),
                        ),
                      ],
                    );
                  }),
                ),

                AppSpacing.vGap8,

                // 4. Custom Date & Period Selector Button Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Obx(() {
                    final hasCustomDate = controller.hasActiveDateFilter;
                    final isCustomSingle = controller.datePreset.value == 'custom_single';
                    final isCustomRange = controller.datePreset.value == 'custom_range';

                    return Container(
                      decoration: BoxDecoration(
                        color: hasCustomDate
                            ? AppColors.primaryLight.withValues(alpha: 0.5)
                            : AppColors.background,
                        borderRadius: AppRadius.borderRadiusMd,
                        border: Border.all(
                          color: hasCustomDate
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Left: Custom Picker Launcher
                          Expanded(
                            child: PopupMenuButton<String>(
                              tooltip: 'Choisir une date ou période',
                              position: PopupMenuPosition.under,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderRadiusLg,
                              ),
                              onSelected: (choice) {
                                if (choice == 'single') {
                                  _pickSingleDate(context, controller);
                                } else if (choice == 'range') {
                                  _pickDateRange(context, controller);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'single',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 18, color: AppColors.primary),
                                      AppSpacing.hGap10,
                                      Text('Date précise (un jour)',
                                          style: AppTypography.bodyMedium),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'range',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.date_range_rounded,
                                          size: 18, color: AppColors.info),
                                      AppSpacing.hGap10,
                                      Text('Période (Du ... au ...)',
                                          style: AppTypography.bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCustomRange
                                          ? Icons.date_range_rounded
                                          : Icons.calendar_month_rounded,
                                      size: 16,
                                      color: hasCustomDate
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                    AppSpacing.hGap8,
                                    Expanded(
                                      child: Text(
                                        hasCustomDate
                                            ? controller.dateFilterSummary
                                            : 'Date précise ou Période...',
                                        style: AppTypography.badgeSmall.copyWith(
                                          fontWeight: hasCustomDate
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: hasCustomDate
                                              ? AppColors.primaryDark
                                              : AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Quick Calendar Shortcut Icons
                          IconButton(
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            tooltip: 'Date précise',
                            color: isCustomSingle ? AppColors.primary : AppColors.textSecondary,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => _pickSingleDate(context, controller),
                          ),
                          IconButton(
                            icon: const Icon(Icons.date_range_rounded, size: 16),
                            tooltip: 'Période',
                            color: isCustomRange ? AppColors.primary : AppColors.textSecondary,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => _pickDateRange(context, controller),
                          ),

                          // Clear button if date is filtered
                          if (hasCustomDate)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              tooltip: 'Effacer le filtre date',
                              color: AppColors.danger,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () => controller.clearDateFilter(),
                            ),
                        ],
                      ),
                    );
                  }),
                ),

                AppSpacing.vGap10,

                // 5. Status Filters Bar (Tous statuts, Non payées, Partielles, Payées)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Obx(() {
                    final current = controller.statusFilter.value;
                    return Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip('Tous', 'all', current, controller),
                        ),
                        AppSpacing.hGap6,
                        Expanded(
                          child: _buildFilterChip('Non payées', 'unpaid', current, controller),
                        ),
                        AppSpacing.hGap6,
                        Expanded(
                          child: _buildFilterChip('Partielles', 'partially_paid', current, controller),
                        ),
                        AppSpacing.hGap6,
                        Expanded(
                          child: _buildFilterChip('Payées', 'paid', current, controller),
                        ),
                      ],
                    );
                  }),
                ),

                AppSpacing.vGap8,
                const Divider(height: 1),

                // 6. Invoices List
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
                        message: controller.hasActiveFilters
                            ? 'Aucune facture ne correspond aux filtres sélectionnés.'
                            : 'Cliquez sur "Facturer" pour créer votre première facture.',
                        action: controller.hasActiveFilters
                            ? OutlinedButton.icon(
                                onPressed: () => controller.resetAllFilters(),
                                icon: const Icon(Icons.clear_all_rounded, size: 16),
                                label: Text('Réinitialiser les filtres',
                                    style: AppTypography.buttonSmall),
                              )
                            : null,
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

  Widget _buildPresetChip(
    String label,
    String value,
    String current,
    VoidCallback onTap,
  ) {
    final isSelected = current == value;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderRadiusMd,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.badgeSmall.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.badgeSmall.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
            fontSize: 11,
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
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Invoice Number & Status Badge
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

              // Row 2: Patient Name & Total Amount
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
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
                    style: AppTypography.formLabel.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              AppSpacing.vGap4,

              // Row 3: Invoice Date & Paid Amount / Remaining
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      AppSpacing.hGap4,
                      Text(
                        invoice.formattedDate,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Payé : ${invoice.formattedPaid}',
                        style: AppTypography.caption.copyWith(
                          color: invoice.isPaid
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight:
                              invoice.isPaid ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (!invoice.isPaid) ...[
                        AppSpacing.hGap8,
                        Text(
                          'Reste : ${invoice.formattedRemaining}',
                          style: AppTypography.badgeSmall.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
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
