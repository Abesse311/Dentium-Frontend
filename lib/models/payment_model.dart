import '../core/constants/status_labels.dart';
import '../core/utils/date_formatter.dart';

class PaymentModel {
  final int? id;
  final int invoiceId;
  final double amount;
  final String paymentDate; // YYYY-MM-DD
  final String paymentMethod; // 'cash' | 'card' | 'transfer' | 'other'
  final String? notes;

  const PaymentModel({
    this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod = 'cash',
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int?,
      invoiceId: json['invoice_id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['payment_date'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }

  String get methodLabelFr => StatusLabels.paymentMethod(paymentMethod);

  String get formattedAmount => DateFormatter.formatCurrency(amount);

  String get formattedDate {
    final parsed = DateFormatter.fromApiString(paymentDate);
    if (parsed == null) return paymentDate;
    return DateFormatter.formatMedium(parsed);
  }
}
