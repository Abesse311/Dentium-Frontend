import '../core/utils/date_formatter.dart';

class TreatmentModel {
  final int? id;
  final int patientId;
  final int? appointmentId;
  final int treatmentTypeId;
  final String? treatmentTypeName;
  final int? toothNumber; // FDI notation (11-48), null for general
  final String status; // 'planned' | 'in_progress' | 'completed'
  final double price;
  final String? treatmentDate; // YYYY-MM-DD
  final String? notes;
  final String? createdAt;

  const TreatmentModel({
    this.id,
    required this.patientId,
    this.appointmentId,
    required this.treatmentTypeId,
    this.treatmentTypeName,
    this.toothNumber,
    this.status = 'planned',
    required this.price,
    this.treatmentDate,
    this.notes,
    this.createdAt,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    String? typeName;
    if (json.containsKey('treatment_type') && json['treatment_type'] is Map) {
      typeName = json['treatment_type']['name'] as String?;
    } else if (json.containsKey('treatment_type_name')) {
      typeName = json['treatment_type_name'] as String?;
    } else if (json.containsKey('name')) {
      typeName = json['name'] as String?;
    }

    return TreatmentModel(
      id: json['id'] as int?,
      patientId: json['patient_id'] as int,
      appointmentId: json['appointment_id'] as int?,
      treatmentTypeId: json['treatment_type_id'] as int? ?? 1,
      treatmentTypeName: typeName,
      toothNumber: json['tooth_number'] as int?,
      status: json['status'] as String? ?? 'planned',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      treatmentDate: json['treatment_date'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'treatment_type_id': treatmentTypeId,
      'tooth_number': toothNumber,
      'status': status,
      'price': price,
      'treatment_date': treatmentDate,
      'notes': notes,
    };
  }

  TreatmentModel copyWith({
    int? id,
    int? patientId,
    int? appointmentId,
    int? treatmentTypeId,
    String? treatmentTypeName,
    int? toothNumber,
    String? status,
    double? price,
    String? treatmentDate,
    String? notes,
    String? createdAt,
  }) {
    return TreatmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      treatmentTypeId: treatmentTypeId ?? this.treatmentTypeId,
      treatmentTypeName: treatmentTypeName ?? this.treatmentTypeName,
      toothNumber: toothNumber ?? this.toothNumber,
      status: status ?? this.status,
      price: price ?? this.price,
      treatmentDate: treatmentDate ?? this.treatmentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isGeneral => toothNumber == null || toothNumber == 0;

  String get displayName => treatmentTypeName ?? 'Traitement #$treatmentTypeId';

  String get toothLabel => isGeneral ? 'Soins Général' : 'Dent $toothNumber';

  String get formattedPrice => DateFormatter.formatCurrency(price);

  String get formattedDate {
    if (treatmentDate == null) return 'Date non définie';
    final parsed = DateFormatter.fromApiString(treatmentDate);
    if (parsed == null) return treatmentDate!;
    return DateFormatter.formatMedium(parsed);
  }
}
