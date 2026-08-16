class ClinicSettingsModel {
  final int id;
  final String clinicName;
  final String? doctorName;
  final String? phone;
  final String? address;
  final String? logoPath;
  final int dailyPatientLimit;

  const ClinicSettingsModel({
    this.id = 1,
    required this.clinicName,
    this.doctorName,
    this.phone,
    this.address,
    this.logoPath,
    this.dailyPatientLimit = 30,
  });

  factory ClinicSettingsModel.fromJson(Map<String, dynamic> json) {
    return ClinicSettingsModel(
      id: json['id'] as int? ?? 1,
      clinicName: json['clinic_name'] as String? ?? 'Cabinet Dentaire',
      doctorName: json['doctor_name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      logoPath: json['logo_path'] as String?,
      dailyPatientLimit: (json['daily_patient_limit'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_name': clinicName,
      'doctor_name': doctorName,
      'phone': phone,
      'address': address,
      'logo_path': logoPath,
      'daily_patient_limit': dailyPatientLimit,
    };
  }

  ClinicSettingsModel copyWith({
    int? id,
    String? clinicName,
    String? doctorName,
    String? phone,
    String? address,
    String? logoPath,
    int? dailyPatientLimit,
  }) {
    return ClinicSettingsModel(
      id: id ?? this.id,
      clinicName: clinicName ?? this.clinicName,
      doctorName: doctorName ?? this.doctorName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
      dailyPatientLimit: dailyPatientLimit ?? this.dailyPatientLimit,
    );
  }
}
