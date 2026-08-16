import '../core/utils/date_formatter.dart';

class PatientTreatmentModel {
  final int id;
  final int patientId;
  final int? appointmentId;
  final int treatmentTypeId;
  final String? treatmentTypeName;
  final int? toothNumber; // 11-48 FDI
  final String status; // planned | in_progress | completed
  final double price;
  final String? treatmentDate;
  final String? notes;
  final String? createdAt;

  const PatientTreatmentModel({
    required this.id,
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

  factory PatientTreatmentModel.fromJson(Map<String, dynamic> json) {
    // Sometimes backend returns treatment_type nested object or treatment_type_name
    String? typeName;
    if (json.containsKey('treatment_type') && json['treatment_type'] is Map) {
      typeName = json['treatment_type']['name'] as String?;
    } else if (json.containsKey('treatment_type_name')) {
      typeName = json['treatment_type_name'] as String?;
    } else if (json.containsKey('name')) {
      typeName = json['name'] as String?;
    }

    return PatientTreatmentModel(
      id: json['id'] as int,
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
      'id': id,
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

  String get displayName =>
      treatmentTypeName ?? 'Traitement #$treatmentTypeId';

  String get toothLabel =>
      toothNumber != null ? 'Dent $toothNumber' : 'Général';

  String get formattedDate {
    if (treatmentDate == null) return 'Date non définie';
    final parsed = DateFormatter.fromApiString(treatmentDate);
    if (parsed == null) return treatmentDate!;
    return DateFormatter.formatMedium(parsed);
  }
}
