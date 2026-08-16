import '../core/utils/date_formatter.dart';

class DashboardMetricsModel {
  final int bookedToday;
  final int completedToday;
  final int noShowToday;
  final double incomeToday;
  final int pendingTreatmentsCount;

  const DashboardMetricsModel({
    this.bookedToday = 0,
    this.completedToday = 0,
    this.noShowToday = 0,
    this.incomeToday = 0.0,
    this.pendingTreatmentsCount = 0,
  });

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val.trim()) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    final booked = json['booked_today'] ?? json['patients_booked_today'];
    final completed = json['completed_today'] ?? json['patients_completed_today'];
    final noShow = json['no_show_today'] ?? json['patients_no_show_today'];
    final income = json['income_today'] ?? json['today_income'];
    final pending = json['pending_treatments_count'];

    return DashboardMetricsModel(
      bookedToday: _parseInt(booked),
      completedToday: _parseInt(completed),
      noShowToday: _parseInt(noShow),
      incomeToday: _parseDouble(income),
      pendingTreatmentsCount: _parseInt(pending),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booked_today': bookedToday,
      'completed_today': completedToday,
      'no_show_today': noShowToday,
      'income_today': incomeToday,
      'pending_treatments_count': pendingTreatmentsCount,
    };
  }

  int get totalPatientsToday => bookedToday + completedToday + noShowToday;

  double get completionRate {
    if (totalPatientsToday == 0) return 0.0;
    return completedToday / totalPatientsToday;
  }

  String get formattedIncome => DateFormatter.formatCurrency(incomeToday);
}






