import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/constants.dart';
import '../models/clinic_settings_model.dart';
import '../models/treatment_type_model.dart';

class SettingsApi {
  final ApiClient _client = ApiClient.instance;

  /// Fetch clinic settings
  Future<ClinicSettingsModel> getSettings() async {
    try {
      final response = await _client.dio.get(AppConstants.endpointSettings);
      return ClinicSettingsModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Update clinic settings
  Future<ClinicSettingsModel> updateSettings(ClinicSettingsModel settings) async {
    try {
      final response = await _client.dio.put(
        AppConstants.endpointSettings,
        data: settings.toJson(),
      );
      return ClinicSettingsModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Fetch treatment types catalog
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

  /// Create new treatment type
  Future<TreatmentTypeModel> createTreatmentType(TreatmentTypeModel type) async {
    try {
      final response = await _client.dio.post(
        AppConstants.endpointTreatmentTypes,
        data: type.toJson(),
      );
      return TreatmentTypeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Update treatment type
  Future<TreatmentTypeModel> updateTreatmentType(int id, TreatmentTypeModel type) async {
    try {
      final response = await _client.dio.put(
        '${AppConstants.endpointTreatmentTypes}/$id',
        data: type.toJson(),
      );
      return TreatmentTypeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Delete treatment type
  Future<void> deleteTreatmentType(int id) async {
    try {
      await _client.dio.delete('${AppConstants.endpointTreatmentTypes}/$id');
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}






