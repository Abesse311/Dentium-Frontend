import 'package:flutter_application_1/core/api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsApi {
  final ApiClient _client = ApiClient.instance;

  static const String endpointReports = '/api/reports';

  /// Get comprehensive financial overview in one request
  Future<ReportOverviewModel> getOverview({
    String? period,
    String? startDate,
    String? endDate,
    String? granularity,
    int debtsLimit = 50,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'debts_limit': debtsLimit,
      };

      if (period != null && period.isNotEmpty) {
        queryParams['period'] = period;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      if (granularity != null && granularity.isNotEmpty) {
        queryParams['granularity'] = granularity;
      }

      final response = await _client.dio.get(
        '$endpointReports/overview',
        queryParameters: queryParams,
      );

      return ReportOverviewModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Get financial summary metrics
  Future<ReportSummaryModel> getSummary({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (period != null && period.isNotEmpty) queryParams['period'] = period;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

      final response = await _client.dio.get(
        '$endpointReports/summary',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return ReportSummaryModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Get income trend time-series
  Future<ReportTrendModel> getTrend({
    String? period,
    String? startDate,
    String? endDate,
    String? granularity,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (period != null && period.isNotEmpty) queryParams['period'] = period;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
      if (granularity != null && granularity.isNotEmpty) queryParams['granularity'] = granularity;

      final response = await _client.dio.get(
        '$endpointReports/trend',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return ReportTrendModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Get outstanding debts and debtor ranking
  Future<ReportDebtsModel> getDebts({int limit = 50}) async {
    try {
      final response = await _client.dio.get(
        '$endpointReports/debts',
        queryParameters: {'limit': limit},
      );

      return ReportDebtsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Get revenue breakdown by treatment type
  Future<ReportTreatmentsModel> getTreatments({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (period != null && period.isNotEmpty) queryParams['period'] = period;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

      final response = await _client.dio.get(
        '$endpointReports/treatments',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return ReportTreatmentsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}
