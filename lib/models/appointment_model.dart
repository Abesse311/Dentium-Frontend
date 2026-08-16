import '../core/utils/date_formatter.dart';

class AppointmentModel {
  final int? id;
  final int patientId;
  final String? patientName;
  final String? patientPhone;
  final String appointmentDate; // YYYY-MM-DD
  final String status; // 'booked' | 'completed' | 'no_show'
  final String? reason;
  final String? notes;
  final String? createdAt;

  const AppointmentModel({
    this.id,
    required this.patientId,
    this.patientName,
    this.patientPhone,
    required this.appointmentDate,
    this.status = 'booked',
    this.reason,
    this.notes,
    this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    String? pName = json['patient_name'] as String?;
    String? pPhone = json['patient_phone'] as String?;

    if (json.containsKey('patient') && json['patient'] is Map) {
      final p = json['patient'] as Map<String, dynamic>;
      pName ??= p['full_name'] as String?;
      pPhone ??= p['phone'] as String?;
    }

    return AppointmentModel(
      id: json['id'] as int?,
      patientId: json['patient_id'] as int,
      patientName: pName,
      patientPhone: pPhone,
      appointmentDate: json['appointment_date'] as String? ?? '',
      status: json['status'] as String? ?? 'booked',
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'appointment_date': appointmentDate,
      'status': status,
      'reason': reason,
      'notes': notes,
    };
  }

  AppointmentModel copyWith({
    int? id,
    int? patientId,
    String? patientName,
    String? patientPhone,
    String? appointmentDate,
    String? status,
    String? reason,
    String? notes,
    String? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isBooked => status.toLowerCase() == 'booked';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isNoShow => status.toLowerCase() == 'no_show';

  String get displayName => patientName ?? 'Patient #$patientId';

  String get formattedDate {
    final parsed = DateFormatter.fromApiString(appointmentDate);
    if (parsed == null) return appointmentDate;
    return DateFormatter.formatFull(parsed);
  }
}






