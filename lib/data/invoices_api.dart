import '../core/api/api_client.dart';
import '../core/constants/app_constants.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';

class InvoicesApi {
  final ApiClient _client = ApiClient.instance;

  /// Fetch all invoices
  Future<List<InvoiceModel>> getInvoices({int? patientId}) async {
    try {
      final endpoint = patientId != null
          ? '${AppConstants.endpointPatients}/$patientId/invoices'
          : AppConstants.endpointInvoices;

      final response = await _client.dio.get(endpoint);
      final List data = response.data as List;
      return data
          .map((json) => InvoiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Get single invoice detail with items and payments
  Future<InvoiceModel> getInvoice(int id) async {
    try {
      final response = await _client.dio.get('${AppConstants.endpointInvoices}/$id');
      return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Create a new invoice from completed treatments and/or custom line items
  Future<InvoiceModel> createInvoice({
    required int patientId,
    required List<int> treatmentIds,
    List<Map<String, dynamic>>? customItems,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'patient_id': patientId,
        'treatment_ids': treatmentIds,
        if (customItems != null && customItems.isNotEmpty)
          'items': customItems,
      };

      final response = await _client.dio.post(
        AppConstants.endpointInvoices,
        data: payload,
      );
      return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Register a payment against an invoice
  Future<PaymentModel> addPayment(int invoiceId, PaymentModel payment) async {
    try {
      final response = await _client.dio.post(
        '${AppConstants.endpointInvoices}/$invoiceId/payments',
        data: payment.toJson(),
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Delete an invoice
  Future<void> deleteInvoice(int id) async {
    try {
      await _client.dio.delete('${AppConstants.endpointInvoices}/$id');
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}
