import 'package:invan2/fiscal_service/fiscal.dart';
import '../changes/services/api_state.dart';
import 'model/fiscal_receipt_model.dart';
import 'model/item/fiscal_item_model.dart';
import 'model/location/location.dart';

class StorageService {
  const StorageService._();
  static Future<String> getFactoryID() async {
    ApiState state = await BaseService.getFactoryId();
    if (state is Success) {
      var decoded = state.decodeResult();
      return decoded['FactoryID'][0];
    }
    return '';
  }

  /// Z-report ni ochib, hechnarsa sotilmaganda, sotuv amalga oshirish uchun
  /// static mahsulot paket
  static Future<FiscalReceiptModel> getStaticReceipt() async {
    return FiscalReceiptModel(
      id: 123,
      jsonrpc: '2.0',
      method: ApiMethods.saleSendReceipt,
      params: FiscalParams(
        factoryID: await getFactoryID(),
        receipt: FiscalReceipt(
          receivedCash: 10000,
          receivedCard: 0,
          time: AppFormatter.formatTime(DateTime.now()),
          location: Location(latitude: 41.33227434, longitude: 69.302394),
          items: [
            FiscalItemModel(
              amount: 1000,
              discount: 0,
              units: 0,
              other: 0,
              barcode: '1234556',
              classCode: '123',
              spic: '06305001002000000',
              vat: 3000,
              vatPercent: 15,
              name: 'Paket',
              label: '',
              price: 20000,
            ),
          ],
        ),
      ),
    );
  }
}
