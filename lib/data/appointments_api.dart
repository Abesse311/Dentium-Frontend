import '../core/api/api_client.dart';
import '../core/constants/app_constants.dart';
import '../models/appointment_model.dart';
import '../models/day_capacity_model.dart';

class AppointmentsApi {
  final ApiClient _client = ApiClient.instance;

  /// Fetch all appointments for a specific date (YYYY-MM-DD)
  Future<List<AppointmentModel>> getAppointmentsForDate(String date) async {
    try {
      final response = await _client.dio.get(
        AppConstants.endpointAppointments,
        queryParameters: {'date': date},
      );
      final List data = response.data as List;
      return data
          .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Fetch capacity counts and fill ratios for a date range (defaults to 7 days)
  Future<List<DayCapacityModel>> getWeekCapacity(
    String startDate, {
    int days = 7,
  }) async {
    try {
      final response = await _client.dio.get(
        AppConstants.endpointAppointmentsCapacity,
        queryParameters: {
          'start': startDate,
          'days': days,
        },
      );
      final List data = response.data as List;
      return data
          .map((json) => DayCapacityModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Create a new booking
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    try {
      final response = await _client.dio.post(
        AppConstants.endpointAppointments,
        data: appointment.toJson(),
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Update appointment status ('completed', 'no_show', 'booked')
  Future<AppointmentModel> updateStatus(int id, String status) async {
    try {
      final response = await _client.dio.patch(
        '${AppConstants.endpointAppointments}/$id',
        data: {'status': status},
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Reschedule an appointment to a new date
  Future<AppointmentModel> rescheduleAppointment(int id, String newDate) async {
    try {
      final response = await _client.dio.patch(
        '${AppConstants.endpointAppointments}/$id',
        data: {'appointment_date': newDate},
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Cancel and delete an appointment
  Future<void> deleteAppointment(int id) async {
    try {
      await _client.dio.delete('${AppConstants.endpointAppointments}/$id');
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}
