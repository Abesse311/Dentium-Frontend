import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/constants.dart';
import '../models/treatment_model.dart';
import '../models/treatment_type_model.dart';

class TreatmentsApi {
  final ApiClient _client = ApiClient.instance;

  /// Fetch all treatment types catalog
  Future<List<TreatmentTypeModel>> getTreatmentTypes() async {
    try {
      final response = await _client.dio.get(AppConstants.endpointTreatmentTypes);
      final List data = response.data as List;
      return data
          .map((json) => TreatmentTypeModel.fromJson(json as Map<String, dynamic>))
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

  /// Delete treatment
  Future<void> deleteTreatment(int id) async {
    try {
      await _client.dio.delete('${AppConstants.endpointTreatments}/$id');
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}






