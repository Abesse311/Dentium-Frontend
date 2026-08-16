import '../core/utils/date_formatter.dart';

class TreatmentTypeModel {
  final int? id;
  final String name;
  final double defaultPrice;
  final String? description;

  const TreatmentTypeModel({
    this.id,
    required this.name,
    this.defaultPrice = 0.0,
    this.description,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  factory TreatmentTypeModel.fromJson(Map<String, dynamic> json) {
    return TreatmentTypeModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      defaultPrice: _parseDouble(json['default_price']),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'default_price': defaultPrice,
      'description': description,
    };
  }

  String get formattedPrice => DateFormatter.formatCurrency(defaultPrice);
}






