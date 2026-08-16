import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/constants.dart';
import '../models/dashboard_metrics_model.dart';

class DashboardApi {
  final ApiClient _client = ApiClient.instance;

  /// Fetch fast-loading today's clinic metrics
  Future<DashboardMetricsModel> getTodayMetrics() async {
    try {
      final response = await _client.dio.get(AppConstants.endpointDashboardToday);
      return DashboardMetricsModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}






