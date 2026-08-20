import '../core/utils/date_formatter.dart';

class ByPaymentMethodModel {
  final double cash;
  final double card;
  final double transfer;
  final double other;

  const ByPaymentMethodModel({
    this.cash = 0.0,
    this.card = 0.0,
    this.transfer = 0.0,
    this.other = 0.0,
  });

  factory ByPaymentMethodModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ByPaymentMethodModel();
    return ByPaymentMethodModel(
      cash: _parseDouble(json['cash']),
      card: _parseDouble(json['card']),
      transfer: _parseDouble(json['transfer']),
      other: _parseDouble(json['other']),
    );
  }

  double get total => cash + card + transfer + other;
}

class InvoicesSummaryModel {
  final int totalCount;
  final int paidCount;
  final int partiallyPaidCount;
  final int unpaidCount;

  const InvoicesSummaryModel({
    this.totalCount = 0,
    this.paidCount = 0,
    this.partiallyPaidCount = 0,
    this.unpaidCount = 0,
  });

  factory InvoicesSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InvoicesSummaryModel();
    return InvoicesSummaryModel(
      totalCount: json['total_count'] as int? ?? 0,
      paidCount: json['paid_count'] as int? ?? 0,
      partiallyPaidCount: json['partially_paid_count'] as int? ?? 0,
      unpaidCount: json['unpaid_count'] as int? ?? 0,
    );
  }
}

class ReportSummaryModel {
  final String period;
  final String startDate;
  final String endDate;
  final double totalIncome;
  final double totalInvoiced;
  final double collectionRate;
  final int paymentCount;
  final ByPaymentMethodModel byPaymentMethod;
  final InvoicesSummaryModel invoicesSummary;

  const ReportSummaryModel({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalInvoiced,
    required this.collectionRate,
    required this.paymentCount,
    required this.byPaymentMethod,
    required this.invoicesSummary,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportSummaryModel(
      period: json['period'] as String? ?? 'this_month',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      totalIncome: _parseDouble(json['total_income']),
      totalInvoiced: _parseDouble(json['total_invoiced']),
      collectionRate: _parseDouble(json['collection_rate']),
      paymentCount: json['payment_count'] as int? ?? 0,
      byPaymentMethod: ByPaymentMethodModel.fromJson(
        json['by_payment_method'] as Map<String, dynamic>?,
      ),
      invoicesSummary: InvoicesSummaryModel.fromJson(
        json['invoices_summary'] as Map<String, dynamic>?,
      ),
    );
  }

  String get formattedTotalIncome => DateFormatter.formatCurrency(totalIncome);
  String get formattedTotalInvoiced => DateFormatter.formatCurrency(totalInvoiced);
  String get formattedCollectionRate => '${collectionRate.toStringAsFixed(1)}%';
}

class TrendPointModel {
  final String date;
  final String label;
  final double income;
  final double invoiced;
  final int paymentCount;

  const TrendPointModel({
    required this.date,
    required this.label,
    required this.income,
    required this.invoiced,
    required this.paymentCount,
  });

  factory TrendPointModel.fromJson(Map<String, dynamic> json) {
    return TrendPointModel(
      date: json['date'] as String? ?? '',
      label: json['label'] as String? ?? '',
      income: _parseDouble(json['income']),
      invoiced: _parseDouble(json['invoiced']),
      paymentCount: json['payment_count'] as int? ?? 0,
    );
  }

  String get formattedIncome => DateFormatter.formatCurrency(income);
  String get formattedInvoiced => DateFormatter.formatCurrency(invoiced);
}

class ReportTrendModel {
  final String period;
  final String startDate;
  final String endDate;
  final String granularity;
  final List<TrendPointModel> points;

  const ReportTrendModel({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.granularity,
    required this.points,
  });

  factory ReportTrendModel.fromJson(Map<String, dynamic> json) {
    final list = json['points'] as List? ?? [];
    return ReportTrendModel(
      period: json['period'] as String? ?? 'this_month',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      granularity: json['granularity'] as String? ?? 'daily',
      points: list
          .map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get maxIncome {
    if (points.isEmpty) return 1000.0;
    double maxVal = 0.0;
    for (final p in points) {
      if (p.income > maxVal) maxVal = p.income;
      if (p.invoiced > maxVal) maxVal = p.invoiced;
    }
    return maxVal > 0 ? maxVal : 1000.0;
  }
}

class DebtorPatientModel {
  final int patientId;
  final String patientName;
  final String? patientPhone;
  final double totalInvoiced;
  final double totalPaid;
  final double totalDebt;
  final int unpaidInvoicesCount;
  final String? latestInvoiceDate;

  const DebtorPatientModel({
    required this.patientId,
    required this.patientName,
    this.patientPhone,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalDebt,
    required this.unpaidInvoicesCount,
    this.latestInvoiceDate,
  });

  factory DebtorPatientModel.fromJson(Map<String, dynamic> json) {
    return DebtorPatientModel(
      patientId: json['patient_id'] as int? ?? 0,
      patientName: json['patient_name'] as String? ?? 'Patient',
      patientPhone: json['patient_phone'] as String?,
      totalInvoiced: _parseDouble(json['total_invoiced']),
      totalPaid: _parseDouble(json['total_paid']),
      totalDebt: _parseDouble(json['total_debt']),
      unpaidInvoicesCount: json['unpaid_invoices_count'] as int? ?? 0,
      latestInvoiceDate: json['latest_invoice_date'] as String?,
    );
  }

  String get initials {
    final parts = patientName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'P';
  }

  String get formattedTotalDebt => DateFormatter.formatCurrency(totalDebt);
  String get formattedTotalInvoiced => DateFormatter.formatCurrency(totalInvoiced);
  String get formattedTotalPaid => DateFormatter.formatCurrency(totalPaid);
}

class ReportDebtsModel {
  final double totalOutstandingDebt;
  final int debtorPatientsCount;
  final int unpaidInvoicesCount;
  final List<DebtorPatientModel> debtors;

  const ReportDebtsModel({
    required this.totalOutstandingDebt,
    required this.debtorPatientsCount,
    required this.unpaidInvoicesCount,
    required this.debtors,
  });

  factory ReportDebtsModel.fromJson(Map<String, dynamic> json) {
    final list = json['debtors'] as List? ?? [];
    return ReportDebtsModel(
      totalOutstandingDebt: _parseDouble(json['total_outstanding_debt']),
      debtorPatientsCount: json['debtor_patients_count'] as int? ?? 0,
      unpaidInvoicesCount: json['unpaid_invoices_count'] as int? ?? 0,
      debtors: list
          .map((e) => DebtorPatientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedTotalDebt =>
      DateFormatter.formatCurrency(totalOutstandingDebt);
}

class TreatmentRevenueItemModel {
  final int? treatmentTypeId;
  final String treatmentTypeName;
  final String? category;
  final double totalAmount;
  final int itemsCount;
  final double percentage;

  const TreatmentRevenueItemModel({
    this.treatmentTypeId,
    required this.treatmentTypeName,
    this.category,
    required this.totalAmount,
    required this.itemsCount,
    required this.percentage,
  });

  factory TreatmentRevenueItemModel.fromJson(Map<String, dynamic> json) {
    return TreatmentRevenueItemModel(
      treatmentTypeId: json['treatment_type_id'] as int?,
      treatmentTypeName: json['treatment_type_name'] as String? ?? 'Acte',
      category: json['category'] as String?,
      totalAmount: _parseDouble(json['total_amount']),
      itemsCount: json['items_count'] as int? ?? 0,
      percentage: _parseDouble(json['percentage']),
    );
  }

  String get formattedTotalAmount => DateFormatter.formatCurrency(totalAmount);
  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';
}

class ReportTreatmentsModel {
  final String period;
  final String startDate;
  final String endDate;
  final double totalRevenue;
  final List<TreatmentRevenueItemModel> items;

  const ReportTreatmentsModel({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.items,
  });

  factory ReportTreatmentsModel.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return ReportTreatmentsModel(
      period: json['period'] as String? ?? 'this_month',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      totalRevenue: _parseDouble(json['total_revenue']),
      items: list
          .map((e) => TreatmentRevenueItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedTotalRevenue =>
      DateFormatter.formatCurrency(totalRevenue);
}

class ReportOverviewModel {
  final ReportSummaryModel summary;
  final ReportTrendModel trend;
  final ReportDebtsModel debts;
  final ReportTreatmentsModel treatments;

  const ReportOverviewModel({
    required this.summary,
    required this.trend,
    required this.debts,
    required this.treatments,
  });

  factory ReportOverviewModel.fromJson(Map<String, dynamic> json) {
    return ReportOverviewModel(
      summary: ReportSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      trend: ReportTrendModel.fromJson(
        json['trend'] as Map<String, dynamic>? ?? {},
      ),
      debts: ReportDebtsModel.fromJson(
        json['debts'] as Map<String, dynamic>? ?? {},
      ),
      treatments: ReportTreatmentsModel.fromJson(
        json['treatments'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
  }
  return 0.0;
}
