import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class SixClientModel4 {
  int clientNumber;
  int lastAddedIndex;
  List<ReceiptModelSoldItem4> orderedProducts;
  String? clientPhone;
  ClientModel? selectedClient;
  double? discountAmount;
  double? discountAmountFromNewClient;
  double? discountPercent;

  SixClientModel4({
    this.discountAmount,
    this.clientPhone,
    required this.discountAmountFromNewClient,
    required this.clientNumber,
    required this.lastAddedIndex,
    required this.orderedProducts,
    this.discountPercent,
    this.selectedClient,
  });
}
