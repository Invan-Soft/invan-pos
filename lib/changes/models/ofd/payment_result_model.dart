class PaymentResult {
  bool success;
  Object? mxikError;
  String? errorMessage;

  /// Sotuv haqiqatan ishlov berilmasdan to'xtatilganda true bo'ladi
  /// (masalan: items bo'sh — double-trigger natijasida). Bu holatda
  /// kassirga "to'lov amalga oshmadi" qizil xatosi KO'RSATILMAYDI.
  bool skipped;

  PaymentResult({
    required this.mxikError,
    required this.success,
    this.errorMessage,
    this.skipped = false,
  });
}
