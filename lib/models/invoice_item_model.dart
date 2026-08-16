import '../core/utils/date_formatter.dart';

class InvoiceItemModel {
  final int? id;
  final int? invoiceId;
  final int? treatmentId;
  final String description;
  final double amount;

  const InvoiceItemModel({
    this.id,
    this.invoiceId,
    this.treatmentId,
    required this.description,
    required this.amount,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] as int?,
      invoiceId: json['invoice_id'] as int?,
      treatmentId: json['treatment_id'] as int?,
      description: json['description'] as String? ?? 'Prestation dentaire',
      amount: _parseDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (treatmentId != null) 'treatment_id': treatmentId,
      'description': description,
      'amount': amount,
    };
  }

  String get formattedAmount => DateFormatter.formatCurrency(amount);
}






