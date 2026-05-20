import 'package:invan2/features/file_crud/operations/file_printer_image.dart';
import 'package:invan2/features/get_service/model/service_get_response.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class ServiceSingleton {
  const ServiceSingleton._();
  static Future<void> setPrefs(ServiceGetResponseData v) async {
    bool storeName = false;
    bool storeAddress = false;
    bool phoneNumber = false;
    bool date = false;
    bool cashier = false;
    bool customer = false;
    bool transaction = false;

    Blocks blocks = Blocks();
    v.blocks?.forEach((element) {
      if (element.name == "information block") {
        blocks = element;
        blocks.fields?.forEach((field) {
          if (field.name == "store name") {
            storeName = field.isAdded ?? false;
          }
          if (field.name == "store address") {
            storeAddress = field.isAdded ?? false;
          }
          if (field.name == "phone number") {
            phoneNumber = field.isAdded ?? false;
          }
          if (field.name == "date") {
            date = field.isAdded ?? false;
          }
          if (field.name == "cashier") {
            cashier = field.isAdded ?? false;
          }
          if (field.name == "customer") {
            customer = field.isAdded ?? false;
          }
          if (field.name == "transaction") {
            transaction = field.isAdded ?? false;
          }
        });
      }
    });
    String thanks = "";
    thanks = v.message ?? "";
    await Pref.setString(PrefKeys.thanks, thanks);
    await Pref.setBool(PrefKeys.storeNameRD, storeName);
    await Pref.setBool(PrefKeys.storeAddressRD, storeAddress);
    await Pref.setBool(PrefKeys.phoneNumberRD, phoneNumber);
    await Pref.setBool(PrefKeys.dateRD, date);
    await Pref.setBool(PrefKeys.cashierRD, cashier);
    await Pref.setBool(PrefKeys.customerRD, customer);
    await Pref.setBool(PrefKeys.transactionRD, transaction);
    if (v.logo != null) {
      final imageUrl = v.logo?.image ?? "";
      if (imageUrl.isNotEmpty) {
        try {
          await FilePrinterImage.downloadPrinterImage(imageUrl);
        } catch (e) {
          return;
        }
      }
    } else {
      try {
        await FilePrinterImage.deletePrinterImage();
      } catch (e) {
        return;
      }
    }
  }
}
