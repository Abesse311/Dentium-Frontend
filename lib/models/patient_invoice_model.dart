import '../core/utils/date_formatter.dart';

class PatientInvoiceModel {
  final int id;
  final int patientId;
  final String invoiceNumber;
  final String? invoiceDate;
  final double totalAmount;
  final double paidAmount;
  final String status; // unpaid | partially_paid | paid
  final String? createdAt;

  const PatientInvoiceModel({
    required this.id,
    required this.patientId,
    required this.invoiceNumber,
    this.invoiceDate,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.status = 'unpaid',
    this.createdAt,
  });

  factory PatientInvoiceModel.fromJson(Map<String, dynamic> json) {
    return PatientInvoiceModel(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      invoiceNumber: json['invoice_number'] as String? ?? 'FAC-${json['id']}',
      invoiceDate: json['invoice_date'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'unpaid',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': status,
    };
  }

  double get remainingAmount {
    final diff = totalAmount - paidAmount;
    return diff > 0 ? diff : 0.0;
  }

  String get formattedDate {
    if (invoiceDate == null) return 'Date non définie';
    final parsed = DateFormatter.fromApiString(invoiceDate);
    if (parsed == null) return invoiceDate!;
    return DateFormatter.formatMedium(parsed);
  }
}
