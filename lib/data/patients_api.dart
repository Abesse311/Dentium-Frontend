import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/constants.dart';
import '../models/patient_invoice_model.dart';
import '../models/patient_model.dart';
import '../models/patient_treatment_model.dart';

class PatientsApi {
  final ApiClient _client = ApiClient.instance;

  /// Fetch all patients with optional search query (name/phone)
  Future<List<PatientModel>> getPatients({String? search}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _client.dio.get(
        AppConstants.endpointPatients,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List data = response.data as List;
      return data.map((json) => PatientModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Get single patient by ID
  Future<PatientModel> getPatient(int id) async {
    try {
      final response = await _client.dio.get('${AppConstants.endpointPatients}/$id');
      return PatientModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Create a new patient
  Future<PatientModel> createPatient(PatientModel patient) async {
    try {
      final response = await _client.dio.post(
        AppConstants.endpointPatients,
        data: patient.toJson(),
      );
      return PatientModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Update existing patient
  Future<PatientModel> updatePatient(int id, PatientModel patient) async {
    try {
      final response = await _client.dio.put(
        '${AppConstants.endpointPatients}/$id',
        data: patient.toJson(),
      );
      return PatientModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Delete patient by ID
  Future<void> deletePatient(int id) async {
    try {
      await _client.dio.delete('${AppConstants.endpointPatients}/$id');
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Get treatment history for a specific patient
  Future<List<PatientTreatmentModel>> getPatientTreatments(int patientId) async {
    try {
      final response = await _client.dio.get(
        '${AppConstants.endpointPatients}/$patientId/treatments',
      );
      final List data = response.data as List;
      return data
          .map((json) => PatientTreatmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Get invoice history for a specific patient
  Future<List<PatientInvoiceModel>> getPatientInvoices(int patientId) async {
    try {
      final response = await _client.dio.get(
        '${AppConstants.endpointPatients}/$patientId/invoices',
      );
      final List data = response.data as List;
      return data
          .map((json) => PatientInvoiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}






