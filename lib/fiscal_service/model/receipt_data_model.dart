import 'location/location.dart';
class ReceiptDataModel {
  final String terminalID;
  final String factoryID;
  final Location? location;
  ReceiptDataModel({
    required this.factoryID,
    required this.terminalID,
    this.location,
  });
}
