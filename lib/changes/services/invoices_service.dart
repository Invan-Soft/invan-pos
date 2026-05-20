import 'dart:ffi';

import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/app_constants.dart';

class InvoicesService {
  static Future<HttpResult> getInvoiceById(String invoiceId) async {
    final response = ApiProvider.getResponse(
        path: "api/v1/invoice/$invoiceId", headers: AppConstants.getHeaders());
    return response;
  }

  static Future<HttpResult> getInvoiceProducts(String barcode) async {
    final response = ApiProvider.getResponse(
        path: "api/v1/invoice_for_pos/$barcode",
        headers: AppConstants.getHeaders());
    return response;
  }
}
