// ignore_for_file: constant_identifier_names

class ApiMethods {
  const ApiMethods._();
  // Z Report
  static const String getZReportStats =
      'Api.GetZReportsStats'; // ZReportService
  static const String closeZReport = 'Api.CloseZReport';
  static const String openZReport = 'Api.OpenZReport';
  static const String sendZReportByNo =
      'Api.SendZReportByNumber'; // DataService
  static const String caclReportBalance = 'Api.GetZReportInfoByNumber';
  static const String getZReportByNo = 'Api.GetZReportInfoByNumber';
  static const String sendZReport = 'Api.SendZReport';
  static const String zReportCount = "Api.GetZReportCount";

  // Receipt
  static const String saleSendReceipt = 'Api.SendSaleReceipt';
  static const String refundSaleReceipt = 'Api.SendRefundReceipt';
  static const String creditReceipt = 'Api.SendCreditReceipt';
  static const String advanceReceipt = 'Api.SendAdvanceReceipt';
  static const String getLastReceipt =
      'Api.GetLastRegisteredReceipt'; // ReceiptService

  static const String sendReceipt = 'Api.SendReceipt'; // ReceiptService
  static const String reScanReceipts = 'Api.RescanReceipts';
  static const String getReceiptCount = 'Api.GetReceiptCount';
  static const String getUnsentCount = 'Api.GetUnsentCount';

  static const String listFiscalDrives = 'Api.ListFiscalDrives';
}
