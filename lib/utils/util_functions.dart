/*
    @author Suxrob Sattorov, 3/17/2025, 10:00 AM
*/

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:invan2/utils/helpers/file_helpers.dart';

import '../changes/models/product/item_model.dart';
import '../changes/models/scales/scales.dart';
import '../changes/services/api/api_provider.dart';
import '../changes/services/api/result_http_model.dart';
import '../changes/services/get_items_service.dart';
import '../features/features.dart';
import '../features/get_products/singletons/items_singleton.dart';
import '../features/get_products/soliq/tasnif_service.dart';
import '../features/hive_repository/hive_boxes.dart';
import '../main.dart';
import 'constants/constants.dart';
import 'helpers/helpers.dart';

class UtilFunctions {
  static double roundToNearest(double value) {
    return value % 1 >= 0.5 ? value.ceilToDouble() : value.floorToDouble();
  }

  static Future<String?> fullUpdateEmployee() async {
    String? error;

    HttpResult httpResult = await EmployeesApi.findEmployees();
    if (!httpResult.isSuccess) {
      return httpResult.getError;
    }

    final box = HiveBoxes.getEmployees();
    await box.clear();

    final employeeList = List<Employee>.from(
      httpResult.result['employees'].map((e) => Employee.fromJson(e)),
    );

    if (employeeList.isNotEmpty) {
      for (var e in employeeList) {
        await box.put(e.key, e);
      }
    }

    HttpResult empRoleResult = await EmployeesApi.getRoleWithPermissions();
    if (!empRoleResult.isSuccess) return empRoleResult.getError;

    List<RoleWithPermission>? roleList =
        RoleWithPermissions.fromJson(empRoleResult.result).data;
    if (roleList == null) return null;

    final rolePermissionMap = <String, Map<String, bool>>{};
    for (var rl in roleList) {
      final salePerms = <String>[];

      for (var module in rl.modules ?? []) {
        if (module.name?.toLowerCase().contains("sale") ?? false) {
          for (var section in module.sections ?? []) {
            for (var perm in section.permissions ?? []) {
              salePerms.add("${perm.name}: ${perm.isAdded}");
            }
          }
        }
      }

      final permissions = <String, bool>{};
      for (var module in rl.modules ?? <Modules>[]) {
        for (var section in module.sections ?? <Sections>[]) {
          for (var permission in section.permissions ?? <Permissions>[]) {
            permissions[permission.id ?? ""] = permission.isAdded ?? false;
          }
        }
      }
      rolePermissionMap[rl.id ?? ""] = permissions;
    }

    for (var employee in box.values) {
      final perms = rolePermissionMap[employee.role?.id] ?? {};

      final access = EmployeeAccess(
        creatNewSale: perms["53c360f9-a10b-4f4b-8b52-670c3b8f87ca"] ?? false,
        viewOnlyNewSale: perms["d45d234a-e2eb-4861-b825-37217f821142"] ?? false,
        applyManualDiscountsNewSale:
            perms["888fde2d-812c-4e5e-9e51-601e367eecbf"] ?? false,
        refund: perms["e84a7e7d-2c6e-441f-82b7-1eeaf3a361fe"] ?? false,
        saleAsDebt: perms["f89ca40a-f2f9-4745-bebc-9cf293521c95"] ?? false,
        stock: perms["49f674fc-efbf-42fc-bb7c-2904c9c15a07"] ?? false,
        viewOnlyAllSale: perms["8f5f5316-becc-44b9-9c50-ed91ef430733"] ?? false,
        printReports: perms["4d8c05a0-fa2b-468a-9c87-f5adc07cee23"] ?? false,
        deleteS: perms["25ae23a7-d395-4f99-afb4-4fcec02ed1b6"] ?? false,
        receiptHistory: perms["d24b0e6c-cc77-4e5b-935b-25a65a98f720"] ?? false,
        creatNewCustomer:
            perms["6f79f732-777c-4c76-98d9-d519ebf7ec78"] ?? false,
        openShift: perms["1a9b575b-31f5-47b7-9056-8875889921cd"] ?? false,
        xreport: perms["e7ffe144-757b-420e-b57d-4f04095b97e9"] ?? false,
        zreport: perms["2b641aa6-26b1-4d5b-9fc4-f5538338aec2"] ?? false,
        editPrice: perms["615e159d-4a69-489f-87d5-abb32489fdd5"] ?? false,
        deletePrice: perms["02766f7d-49e9-4353-aef6-e5a5d53f3e88"] ?? false,
      );

      await box.put(
        employee.user?.id,
        employee.copyWith(access: access),
      );
    }

    return error;
  }

  // static Future<String?> fullUpdateProduct({bool apd = false}) async {
  //   DateTime time = DateTime.now();
  //   List<ItemModel> allProducts = [];
  //   String getError = '';
  //   await TasnifService.setPackageCode();

  //   HttpResult httpResult = await OrdersService.getItems();

  //   if (httpResult.isSuccess) {
  //     try {
  //       var decodedJson = json.decode(httpResult.result);

  //       if (decodedJson is List) {
  //         final i = <ItemModel>[];
  //         for (final e in decodedJson) {
  //           i.add(ItemModel.fromJson(e));
  //         }

  //         allProducts = ItemsSingleton.addPackageCodeAndMxikCode(
  //           i,
  //           Pref.getString(PrefKeys.mxikCode, ''),
  //           Pref.getString(PrefKeys.packageCode, ''),
  //         );
  //       } else {
  //         getError = "Ma'lumotlar formati noto'g'ri.";
  //       }
  //     } catch (e) {
  //       getError = "Ma'lumotlar o'qishda xatolik: $e";
  //     }
  //   } else {
  //     getError = httpResult.getError;
  //   }

  //   if (kDebugMode) {
  //     print('----- = =    LENGTH    = = -----');
  //     print(allProducts.length);
  //     print('----- = =    LENGTH    = = -----');
  //   }

  //   await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
  //   if (allProducts.isNotEmpty) {
  //     await ItemsSingleton.clearAndPutItems(allProducts);
  //     if (apd) {
  //       await hiveOpen().then((value) async {
  //         await Pref.setBool(PrefKeys.authenticationBool, true);
  //       });
  //     }
  //     await ItemsSingleton.storeProducts();
  //     CategorySingleton.init();
  //     await Pref.setInt(
  //       PrefKeys.lastSyncTime,
  //       DateTime.now()
  //           .subtract(const Duration(seconds: 3))
  //           .millisecondsSinceEpoch,
  //     );
  //     allProducts = [];
  //     return null;
  //   }
  //   return getError;
  // }
static Future<String?> fullUpdateProduct({bool apd = false}) async {
  DateTime time = DateTime.now();
  List<ItemModel> allProducts = [];
  String getError = '';

  print('🔄 fullUpdateProduct chaqirildi - ${DateTime.now()}');

  await TasnifService.setPackageCode();

  HttpResult httpResult = await OrdersService.getItems();

  if (httpResult.isSuccess) {
    try {
      var decodedJson = json.decode(httpResult.result);

      // ==================== BARCODE BO‘YICHA IZLASH (XOM JSON) ====================
      const String targetBarcode = "4780136570023";
      bool found = false;

      print("🔍 API dan kelgan xom JSON ichidan qidirilmoqda: $targetBarcode");

      if (decodedJson is List) {
        for (final e in decodedJson) {
          if (e is Map<String, dynamic>) {
            final barcodeField = e['barcode'];

            bool hasTargetBarcode = false;

            if (barcodeField is String) {
              hasTargetBarcode = barcodeField == targetBarcode;
            } else if (barcodeField is List) {
              hasTargetBarcode = barcodeField.any((b) => b.toString() == targetBarcode);
            }

            if (hasTargetBarcode) {
              found = true;
              print("✅ MAHSULOT TOPILDI (XOM JSON):");
              print("   Nomi          : ${e['name'] ?? 'NOMA\'LUM'}");
              print("   MXIK Code     : ${e['mxikCode'] ?? e['mxik'] ?? e['mxikCode'] ?? 'MXIK yo\'q'}");
              print("   Barcode       : $targetBarcode");
              print("   Package Code  : ${e['packageCode'] ?? 'yo\'q'}");
              print("   O'lchov       : ${e['measurementUnit'] ?? 'yo\'q'}");
              print("   Narx turi     : ${e['shopPrices'] != null ? 'Bor' : 'Yo\'q'}");
              print("   --------------------------------------------------");
            }
          }
        }

        if (!found) {
          print("❌ Bu barcode bilan mahsulot API javobida topilmadi: $targetBarcode");
        }
      } else {
        print("⚠️ decodedJson List emas, balki ${decodedJson.runtimeType} turida keldi");
      }
      // =====================================================================

      // Oddiy mahsulotlar ro'yxatini yaratish
      if (decodedJson is List) {
        final i = <ItemModel>[];
        for (final e in decodedJson) {
          i.add(ItemModel.fromJson(e));
        }

        allProducts = ItemsSingleton.addPackageCodeAndMxikCode(
          i,
          Pref.getString(PrefKeys.mxikCode, ''),
          Pref.getString(PrefKeys.packageCode, ''),
        );

        print('📦 Jami mahsulotlar soni: ${allProducts.length}');
      } else {
        getError = "Ma'lumotlar formati noto'g'ri.";
      }
    } catch (e, stack) {
      getError = "Ma'lumotlar o'qishda xatolik: $e";
      print('❌ JSON parse xatosi: $e');
      print('Stack: $stack');
    }
  } else {
    getError = httpResult.getError ?? "API xatosi";
    print('❌ API xatosi: $getError');
  }

  // Vaqtni saqlash
  await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);

  if (allProducts.isNotEmpty) {
    print('💾 Mahsulotlar localga saqlanmoqda...');
    
    await ItemsSingleton.clearAndPutItems(allProducts);
    
    if (apd) {
      await hiveOpen().then((value) async {
        await Pref.setBool(PrefKeys.authenticationBool, true);
      });
    }

    await ItemsSingleton.storeProducts();
    CategorySingleton.init();

    await Pref.setInt(
      PrefKeys.lastSyncTime,
      DateTime.now().subtract(const Duration(seconds: 3)).millisecondsSinceEpoch,
    );

    print('✅ Mahsulotlar muvaffaqiyatli yangilandi!');
    allProducts = [];
    return null;
  } else {
    print('⚠️ Mahsulotlar bo‘sh keldi yoki xatolik yuz berdi.');
    return getError;
  }
}
  static Future<bool> downloadShtrixM() async {
    String token = Pref.getString(PrefKeys.token, "not initialized");
    String shopId = Pref.getString(PrefKeys.storeId, "not initialized");

    var headers = {
      'Accept-Encoding': 'gzip',
      'Accept-user': 'employeee',
      'Authorization': "Bearer $token",
      "timezone": "-300"
    };

    HttpResult httpResult = await ApiProvider.getResponse(
        path: 'api/v1/scales-template', headers: headers);

    if (httpResult.isSuccess) {
      Scales scales = Scales.fromJson(httpResult.result);

      String shtrixMId = '';

      for (ScalesTemplates s in scales.scalesTemplates ?? []) {
        if (s.name == 'Shtrix_M') {
          shtrixMId = s.id ?? '';
        }
      }

      HttpResult result = await ApiProvider.getResponse(
        path: 'api/v1/scales-template/$shtrixMId'
            '?shop_id=$shopId'
            '&is_active=active',
        headers: headers,
      );

      if (result.isSuccess) {
        String url = result.result['url'];
        return await FileHelpers.saveFileFromUrl(
          url: url,
          dirPath: r'C:\shtrix_m\shtrix_m',
          fileName: 'shtrix_m',
        );
      }

      return false;
    }

    return false;
  }
}
