import '../core/utils/date_formatter.dart';

class PatientModel {
  final int? id;
  final String fullName;
  final String? phone;
  final String? birthDate; // YYYY-MM-DD
  final String? gender; // 'male' | 'female'
  final String? address;
  final String? medicalHistory;
  final String? notes;
  final String? createdAt;

  const PatientModel({
    this.id,
    required this.fullName,
    this.phone,
    this.birthDate,
    this.gender,
    this.address,
    this.medicalHistory,
    this.notes,
    this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int?,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      medicalHistory: json['medical_history'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'phone': phone,
      'birth_date': birthDate,
      'gender': gender,
      'address': address,
      'medical_history': medicalHistory,
      'notes': notes,
    };
  }

  PatientModel copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? birthDate,
    String? gender,
    String? address,
    String? medicalHistory,
    String? notes,
    String? createdAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // --- Helpers & Getters ---

  bool get hasMedicalAlert =>
      medicalHistory != null && medicalHistory!.trim().isNotEmpty;

  String get initials {
    if (fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  int? get age {
    if (birthDate == null || birthDate!.isEmpty) return null;
    final birth = DateFormatter.fromApiString(birthDate);
    if (birth == null) return null;
    final now = DateTime.now();
    int years = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years--;
    }
    return years > 0 ? years : 0;
  }

  String get formattedAge {
    final a = age;
    if (a == null) return 'Âge non renseigné';
    return '$a ans';
  }

  String get formattedBirthDate {
    if (birthDate == null) return 'Non renseignée';
    final parsed = DateFormatter.fromApiString(birthDate);
    if (parsed == null) return birthDate!;
    return DateFormatter.formatMedium(parsed);
  }
}
