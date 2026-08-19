import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/constants.dart';
import '../models/treatment_model.dart';
import '../models/treatment_type_model.dart';

class TreatmentsApi {
  final ApiClient _client = ApiClient.instance;

  /// Fetch all treatment types catalog (optionally filtered by category: 'general' | 'per_tooth')
  Future<List<TreatmentTypeModel>> getTreatmentTypes({String? category}) async {
    try {
      final response = await _client.dio.get(
        AppConstants.endpointTreatmentTypes,
        queryParameters: category != null ? {'category': category} : null,
      );
      final List data = response.data as List;
      return data
          .map((json) => TreatmentTypeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// List and filter treatments across all patients (e.g. status: 'planned', 'in_progress')
  Future<List<TreatmentModel>> getTreatments({
    String? status,
    int? patientId,
    int? toothNumber,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;
      if (patientId != null) queryParams['patient_id'] = patientId;
      if (toothNumber != null) queryParams['tooth_number'] = toothNumber;

      final response = await _client.dio.get(
        AppConstants.endpointTreatments,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List data = response.data as List;
      return data
          .map((json) => TreatmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Fetch full treatment history for a patient
  Future<List<TreatmentModel>> getPatientTreatments(int patientId) async {
    try {
      final response = await _client.dio.get(
        '${AppConstants.endpointPatients}/$patientId/treatments',
      );
      final List data = response.data as List;
      return data
          .map((json) => TreatmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Create a new treatment
  Future<TreatmentModel> createTreatment(TreatmentModel treatment) async {
    try {
      final response = await _client.dio.post(
        AppConstants.endpointTreatments,
        data: treatment.toJson(),
      );
      return TreatmentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Update existing treatment
  Future<TreatmentModel> updateTreatment(int id, TreatmentModel treatment) async {
    try {
      final response = await _client.dio.put(
        '${AppConstants.endpointTreatments}/$id',
        data: treatment.toJson(),
      );
      return TreatmentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Create multiple treatments in bulk across multiple teeth
  Future<List<TreatmentModel>> createTreatmentsBulk({
    required int patientId,
    required int treatmentTypeId,
    required List<int> toothNumbers,
    String status = 'planned',
    double? price,
    String? treatmentDate,
    String? notes,
    int? appointmentId,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'patient_id': patientId,
        'treatment_type_id': treatmentTypeId,
        'tooth_numbers': toothNumbers,
        'status': status,
        'price': ?price,
        'treatment_date': ?treatmentDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'appointment_id': ?appointmentId,
      };

      final response = await _client.dio.post(
        '${AppConstants.endpointTreatments}/bulk',
        data: payload,
      );
      final List data = response.data as List;
      return data
          .map((json) => TreatmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Delete treatment
  Future<void> deleteTreatment(int id) async {
    try {
      await _client.dio.delete('${AppConstants.endpointTreatments}/$id');
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}






