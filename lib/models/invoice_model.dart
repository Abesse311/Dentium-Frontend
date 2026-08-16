import '../core/utils/date_formatter.dart';
import 'invoice_item_model.dart';
import 'payment_model.dart';

class InvoiceModel {
  final int? id;
  final int patientId;
  final String? patientName;
  final String invoiceNumber;
  final String invoiceDate; // YYYY-MM-DD
  final double totalAmount;
  final double paidAmount;
  final String status; // 'unpaid' | 'partially_paid' | 'paid'
  final List<InvoiceItemModel> items;
  final List<PaymentModel> payments;
  final String? createdAt;

  const InvoiceModel({
    this.id,
    required this.patientId,
    this.patientName,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.status = 'unpaid',
    this.items = const [],
    this.payments = const [],
    this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    String? pName = json['patient_name'] as String?;
    if (json.containsKey('patient') && json['patient'] is Map) {
      final p = json['patient'] as Map<String, dynamic>;
      pName ??= p['full_name'] as String?;
    }

    final itemsList = (json['items'] as List?)
            ?.map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final paymentsList = (json['payments'] as List?)
            ?.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return InvoiceModel(
      id: json['id'] as int?,
      patientId: json['patient_id'] as int,
      patientName: pName,
      invoiceNumber: json['invoice_number'] as String? ?? 'FAC-${json['id']}',
      invoiceDate: json['invoice_date'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'unpaid',
      items: itemsList,
      payments: paymentsList,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': status,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  InvoiceModel copyWith({
    int? id,
    int? patientId,
    String? patientName,
    String? invoiceNumber,
    String? invoiceDate,
    double? totalAmount,
    double? paidAmount,
    String? status,
    List<InvoiceItemModel>? items,
    List<PaymentModel>? payments,
    String? createdAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get remainingAmount {
    final rem = totalAmount - paidAmount;
    return rem > 0 ? rem : 0.0;
  }

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isPartiallyPaid => status.toLowerCase() == 'partially_paid';
  bool get isUnpaid => status.toLowerCase() == 'unpaid';

  String get displayPatientName => patientName ?? 'Patient #$patientId';

  String get formattedTotal => DateFormatter.formatCurrency(totalAmount);
  String get formattedPaid => DateFormatter.formatCurrency(paidAmount);
  String get formattedRemaining => DateFormatter.formatCurrency(remainingAmount);

  String get formattedDate {
    final parsed = DateFormatter.fromApiString(invoiceDate);
    if (parsed == null) return invoiceDate;
    return DateFormatter.formatMedium(parsed);
  }
}
