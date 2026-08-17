import '../core/utils/date_formatter.dart';

class TreatmentTypeModel {
  final int? id;
  final String category; // 'general' | 'per_tooth'
  final String name;
  final double defaultPrice;
  final String? description;

  const TreatmentTypeModel({
    this.id,
    this.category = 'general',
    required this.name,
    this.defaultPrice = 0.0,
    this.description,
  });

  bool get isGeneral => category == 'general';
  bool get isPerTooth => category == 'per_tooth';
  String get categoryLabel => isGeneral ? 'Soin Général' : 'Acte par Dent';

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
      category: json['category'] as String? ?? 'general',
      name: json['name'] as String? ?? '',
      defaultPrice: _parseDouble(json['default_price']),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'name': name,
      'default_price': defaultPrice,
      'description': description,
    };
  }

  String get formattedPrice => DateFormatter.formatCurrency(defaultPrice);
}






