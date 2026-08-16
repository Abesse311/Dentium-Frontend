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

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricsModel(
      bookedToday: (json['booked_today'] as num?)?.toInt() ?? 0,
      completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      noShowToday: (json['no_show_today'] as num?)?.toInt() ?? 0,
      incomeToday: (json['income_today'] as num?)?.toDouble() ?? 0.0,
      pendingTreatmentsCount:
          (json['pending_treatments_count'] as num?)?.toInt() ?? 0,
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
