class PaymentResult {
  bool success;
  Object? mxikError;
  String? errorMessage;
  PaymentResult({required this.mxikError, required this.success, this.errorMessage});
}
