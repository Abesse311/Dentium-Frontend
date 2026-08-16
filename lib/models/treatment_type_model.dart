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

  factory TreatmentTypeModel.fromJson(Map<String, dynamic> json) {
    return TreatmentTypeModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      defaultPrice: (json['default_price'] as num?)?.toDouble() ?? 0.0,
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
