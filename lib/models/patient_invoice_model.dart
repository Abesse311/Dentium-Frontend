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

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  factory PatientInvoiceModel.fromJson(Map<String, dynamic> json) {
    return PatientInvoiceModel(
      id: json['id'] as int,
      patientId: json['patient_id'] as int? ?? 0,
      invoiceNumber: json['invoice_number'] as String? ?? 'FAC-${json['id']}',
      invoiceDate: json['invoice_date'] as String?,
      totalAmount: _parseDouble(json['total_amount']),
      paidAmount: _parseDouble(json['paid_amount']),
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






