import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/date_formatter.dart';

class DayCapacityModel {
  final String date; // YYYY-MM-DD
  final int bookedCount;
  final int limit;

  const DayCapacityModel({
    required this.date,
    required this.bookedCount,
    required this.limit,
  });

  factory DayCapacityModel.fromJson(Map<String, dynamic> json) {
    return DayCapacityModel(
      date: json['date'] as String? ?? '',
      bookedCount: (json['booked_count'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'booked_count': bookedCount,
      'limit': limit,
    };
  }

  DateTime? get dateTime => DateFormatter.fromApiString(date);

  double get fillRatio {
    if (limit <= 0) return 0.0;
    return (bookedCount / limit).clamp(0.0, 1.5);
  }

  int get fillPercentage => (fillRatio * 100).round();

  bool get isOverLimit => bookedCount >= limit;

  /// Capacity color-coding per frontend requirements:
  /// - Green: < 50%
  /// - Yellow/Orange: 50–80%
  /// - Red: 80%+
  Color get capacityColor {
    if (fillRatio >= 0.80) {
      return AppColors.capacityHigh;
    } else if (fillRatio >= 0.50) {
      return AppColors.capacityMedium;
    } else {
      return AppColors.capacityLow;
    }
  }

  Color get capacityBgColor {
    if (fillRatio >= 0.80) {
      return AppColors.dangerLight;
    } else if (fillRatio >= 0.50) {
      return AppColors.warningLight;
    } else {
      return AppColors.successLight;
    }
  }

  String get dayNameFr {
    final dt = dateTime;
    if (dt == null) return '';
    return DateFormatter.formatShortDayOfWeek(dt);
  }

  String get dayNumber {
    final dt = dateTime;
    if (dt == null) return '';
    return '${dt.day}';
  }

  String get capacityLabel => '$bookedCount / $limit patients';
}
