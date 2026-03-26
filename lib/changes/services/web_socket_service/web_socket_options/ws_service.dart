// ignore_for_file: use_build_context_synchronously

/*
    @author Suxrob Sattorov, 11/11/2024, 4:12 PM
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../../../features/features.dart';
import '../../../../features/get_discounts/get_discounts.dart';
import '../../../../features/get_products/singletons/items_singleton.dart';
import '../../../../features/lock/access_level/view/access_level_page.dart';
import '../../../../utils/utils.dart';
import '../../../models/product/item_model.dart';
import '../category/categories_ws_service.dart';
import '../discount/discount_ws_service.dart';
import '../product/model/product_price_edit_response.dart';
import '../product/products_ws_service.dart';
import '../urls/urls.dart';

class WsService {
  static const Duration baseRetryInterval = Duration(seconds: 5);
  static const int maxRetries = 15;
  static IOWebSocketChannel? channel;
  static bool isConnecting = false;
  static bool isConnected = false;
  static StreamSubscription? _connectivitySubscription;
  static Timer? _pingTimer;

  static String startTime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc());
  static String endTime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc());

  /// WebSocket ulanishini boshlash
  static Future<void> connectWebSocket(
    bool mounted,
    BuildContext context, {
    int retryCount = 0,
  }) async {
    if (retryCount >= maxRetries) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Internet aloqasini tekshiring")),
        );
      }
      if (kDebugMode) {
        print("⚠️ Maksimal qayta urinishlar soniga yetildi.");
      }
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (kDebugMode) {
        print("⚠️ Internet aloqasi yo‘q, qayta urinish kechiktirildi.");
      }
      _scheduleRetry(mounted, context, retryCount);
      return;
    }

    isConnecting = true;
    try {
      await connectToInvan(mounted, context);
      isConnected = true;
      // _startPingPong();
      _listenConnectivityChanges(mounted, context);
    } catch (e) {
      if (kDebugMode) {
        print("❌ WebSocket ulanish xatosi: $e");
      }
      isConnected = false;
      _scheduleRetry(mounted, context, retryCount);
    } finally {
      isConnecting = false;
    }
  }

  /// Serverga ulanish
  static Future<void> connectToInvan(bool mounted, BuildContext context) async {
    String token = Pref.getString(PrefKeys.token, "not initialized");

    if (token.isEmpty || token == "not initialized") {
      if (kDebugMode) {
        print("⚠️ Token mavjud emas, ulanish bekor qilindi.");
      }
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      String posId = Pref.getString(PrefKeys.activatedPosId, '');
      if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        deviceId = info.deviceId.replaceAll(RegExp(r'[{}]'), '');
      }

      channel = IOWebSocketChannel.connect(
        "${Urls.baseSocketUrl}ws_device?Authorization=$token&deviceID=$deviceId-$posId",
        connectTimeout: const Duration(seconds: 10),
      );
      if (channel != null) {
        endTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc());

        if (kDebugMode) {
          print("✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅ - WebSocket Success - ✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅");
          print("Start time --> $startTime");
          print("End time --> $endTime");
        }

        await CategoriesWsService.getReceivedWS(
            mounted, context, startTime, endTime);
        await ProductsWsService.getReceivedWS(
            mounted, context, startTime, endTime);
        await DiscountWsService.getReceivedWS(
            mounted, context, startTime, endTime);

        if (kDebugMode) {
          print("✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅ - WebSocket Success - ✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅");
        }

        channel!.stream.listen(
          (message) async {
            if (kDebugMode) {
              print('📩 SERVERDAN KELGAN: $message');
            }

            var decoded = json.decode(message);
            int type = decoded['type'];

            if (decoded['id'] != null) {
              switch (type) {
                case 0:
                  await ProductsWsService.import(context);
                  break;
                case 13:
                  await ItemsSingleton.editItem(
                      ProductPriceEdit.fromJson(decoded));
                  await ItemsSingleton.storeProducts();
                  CategorySingleton.init();
                  break;
                case 2:
                  ItemModel item =
                      ItemModel.fromWebSocketJsonUpdate(decoded['data']);
                  if ((decoded['data']['category_ids'] as List<dynamic>)
                      .isNotEmpty) {
                    item.categories ??= ProductsWsService.getCategories(
                        decoded['data']['category_ids'][0]);
                  }
                  await ItemsSingleton.putItems([item]);
                  await ItemsSingleton.storeProducts();
                  CategorySingleton.init();
                  break;
                case 1:
                  ItemModel item = ItemModel.fromWebSocketJson(decoded['data']);
                  if ((decoded['data']['category_ids'] as List<dynamic>)
                      .isNotEmpty) {
                    item.categories ??= ProductsWsService.getCategories(
                        decoded['data']['category_ids'][0]);
                  }
                  await ItemsSingleton.putItems([item]);
                  await ItemsSingleton.storeProducts();
                  CategorySingleton.init();
                  break;
                case 3:
                  await ItemsSingleton.deleteProduct(
                      decoded['data']['ids'].cast<String>());
                  await ItemsSingleton.storeProducts();
                  CategorySingleton.init();
                  break;
                case 10:
                  CategoryData categoryData =
                      CategoryData.fromJson(decoded['data']);
                  await CategorySingleton.putCategories([categoryData]);
                  await ItemsSingleton.storeProducts();
                  CategorySingleton.init();
                  break;
                case 11:
                  CategoryData? categoryData =
                      CategoryData.fromJson(decoded['data']);
                  await CategorySingleton.editCategory(categoryData);
                  await ItemsSingleton.storeProducts();
                  CategorySingleton.init();
                  break;
                case 12:
                  await CategorySingleton.deleteCategories(
                      decoded['data']['id']);
                  await ItemsSingleton.storeProducts();
                  CategorySingleton.init();
                  break;
                case 15:
                  DiscountItem discountItem =
                      DiscountItem.fromJson(decoded['data']);
                  DiscountService.createDiscount(discountItem);
                  break;
                case 16:
                  DiscountItem discountItem =
                      DiscountItem.fromJson(decoded['data']);
                  DiscountService.updateDiscount(discountItem);
                  break;
                case 17:
                  DiscountService.deleteDiscount(decoded['data']['id']);
                  break;
              }
            }
          },
          onDone: () async {
            if (kDebugMode) {
              print(
                  "🔴 WebSocket aloqa uzildi. Yopilish kodi: ${channel?.closeCode}, Sabab: ${channel?.closeReason}");
            }
            isConnected = false;
            startTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(DateTime.now().toUtc().subtract(Duration(minutes: 2)));
            await disconnect(context);
            if (kDebugMode) {
              print('isConnected --> $isConnected');
              print('isConnecting --> $isConnecting');
            }
            if (mounted && !isConnecting) {
              await connectWebSocket(mounted, context);
            }
          },
          onError: (error) async {
            if (kDebugMode) {
              print('❌ WebSocket xatosi: $error');
            }
            isConnected = false;
            await disconnect(context);
            if (mounted && !isConnecting) {
              await connectWebSocket(mounted, context);
            }
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ WebSocketga ulanishda xatolik: $e");
      }
      isConnected = false;
      rethrow;
    }
  }

  /// Qayta ulanishni rejalashtirish (exponential backoff)
  static void _scheduleRetry(
      bool mounted, BuildContext context, int retryCount) {
    Duration retryDelay = baseRetryInterval * (retryCount + 1);
    Future.delayed(retryDelay, () async {
      if (mounted && !isConnected && !isConnecting) {
        await connectWebSocket(mounted, context, retryCount: retryCount + 1);
      }
    });
  }

  /// Ping-pong mexanizmini boshlash
  // static void _startPingPong() {
  //   _pingTimer?.cancel();
  //   _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
  //     if (isConnected && channel != null) {
  //       try {
  //         channel!.sink.add(json.encode({'type': 'ping'}));
  //         if (kDebugMode) {
  //           print("📡 Ping yuborildi.");
  //         }
  //       } catch (e) {
  //         if (kDebugMode) {
  //           print("❌ Ping yuborishda xato: $e");
  //         }
  //         timer.cancel();
  //       }
  //     } else {
  //       timer.cancel();
  //     }
  //   });
  // }

  /// Tarmoq holatini tinglash
  static void _listenConnectivityChanges(bool mounted, BuildContext context) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) {
        if (kDebugMode) {
          print("⚠️ Tarmoq yo‘q, ulanish to‘xtatildi.");
        }
        await disconnect(context);
      } else if (!isConnected && !isConnecting) {
        if (kDebugMode) {
          print("🔄 Tarmoq tiklandi, qayta ulanmoqda...");
        }
        await connectWebSocket(mounted, context);
      }
    });
  }

  /// WebSocket ulanishini yopish
  static Future<void> disconnect(BuildContext context) async {
    _pingTimer?.cancel();
    _connectivitySubscription?.cancel();
    if (channel != null) {
      try {
        await channel!.sink.close(status.normalClosure);
        if (kDebugMode) {
          print("🔴 WebSocket ulanish yopildi.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ WebSocket yopishda xato: $e");
        }
      } finally {
        channel = null;
        isConnected = false;
        isWebSocketConnected = false;
      }
    }
  }
}

/*import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../../../features/features.dart';
import '../../../../features/get_discounts/get_discounts.dart';
import '../../../../features/get_products/singletons/items_singleton.dart';
import '../../../../utils/utils.dart';
import '../../../models/product/item_model.dart';
import '../product/model/product_price_edit_response.dart';
import '../product/products_ws_service.dart';
import '../urls/urls.dart';

class WsService {
  static const Duration retryInterval = Duration(seconds: 5);
  static IOWebSocketChannel? channel;

  static Future<void> connectWebSocket(
      bool mounted, BuildContext context) async {
    await connectToInvan(true, context);

    channel?.sink.done.then((_) {
      if (kDebugMode) {
        print("🔴 WebSocket aloqa uzildi. Qayta ulanmoqda...");
      }
      Future.delayed(retryInterval, () async {
        await connectWebSocket(mounted, context);
      });
    });
  }

  static Future<void> connectToInvan(bool mounted, BuildContext context) async {
    String token = Pref.getString(PrefKeys.token, "not initialized");

    if (token.isEmpty || token == 'not initialized') {
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();

      String deviceId = '';
      String posId = Pref.getString(PrefKeys.activatedPosId, '');
      if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        deviceId = info.deviceId.substring(1, info.deviceId.length - 1);
      }

      channel = IOWebSocketChannel.connect(
          "${Urls.baseSocketUrl}ws_device?Authorization=$token&deviceID=${'$deviceId-$posId'}");
      if (channel != null) {
        if (kDebugMode) {
          print("✅ WebSocket Success");
        }

        channel!.stream.listen((message) async {
          if (kDebugMode) {
            print('SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS');
            print(message);
          }

          var decoded = json.decode(message);
          int type = decoded['type'];

          if (decoded['id'] != null) {
            if (type == 0) {
              await ProductsWsService.import(context);
            } else if (type == 13) {
              await ItemsSingleton.editItem(
                  ProductPriceEdit.fromJson(decoded(message)));
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
            } else if (type == 2) {
              ItemModel item =
                  ItemModel.fromWebSocketJsonUpdate(decoded['data']);
              if ((decoded['data']['category_ids'] as List<dynamic>)
                  .isNotEmpty) {
                item.categories ??= ProductsWsService.getCategories(
                    decoded['data']['category_ids'][0]);
              }
              await ItemsSingleton.putItems([item]);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
            } else if (type == 1) {
              ItemModel item = ItemModel.fromWebSocketJson(decoded['data']);
              if ((decoded['data']['category_ids'] as List<dynamic>)
                  .isNotEmpty) {
                item.categories ??= ProductsWsService.getCategories(
                    decoded['data']['category_ids'][0]);
              }
              await ItemsSingleton.putItems([item]);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
            } else if (type == 3) {
              await ItemsSingleton.deleteProduct(
                  decoded['data']['ids'].cast<String>());
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
            }
            if (type == 10) {
              CategoryData categoryData =
                  CategoryData.fromJson(decoded['data']);
              await CategorySingleton.putCategories([categoryData]);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
            } else if (type == 11) {
              CategoryData? categoryData =
                  CategoryData.fromJson(decoded['data']);
              await CategorySingleton.editCategory(categoryData);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
            } else if (type == 12) {
              await CategorySingleton.deleteCategories(decoded['data']['id']);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
            } else if (type == 15) {
              DiscountItem discountItem =
                  DiscountItem.fromJson(decoded['data']);
              DiscountService.createDiscount(discountItem);
            } else if (type == 16) {
              DiscountItem discountItem =
                  DiscountItem.fromJson(decoded['data']);
              DiscountService.updateDiscount(discountItem);
            } else if (type == 17) {
              DiscountService.deleteDiscount(decoded['data']['id']);
            }
          }
        }, onDone: () async {
          if (kDebugMode) {
            print("🔴 WebSocket aloqa uzildi.");
          }
          var connectivityResult = await (Connectivity().checkConnectivity());
          if (connectivityResult != ConnectivityResult.none) {
            await disconnect(context);
            await connectWebSocket(mounted, context);
          }
        }, onError: (error) {
          if (kDebugMode) {
            print('❌ WebSocket xatosi: $error');
          }
        });
      } else {}
    } catch (e) {
      if (kDebugMode) {
        print("❌ WebSocketga ulanishda xatolik: $e");
      }
      rethrow;
    }
  }

  static Future<void> disconnect(BuildContext context) async {
    if (channel != null) {
      try {
        await channel!.sink.close(status.normalClosure);
        if (kDebugMode) {
          print("🔴 WebSocket ulanish yopildi.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ WebSocket yopishda xato: $e");
        }
      } finally {
        channel = null;
      }
    }
  }
}*/

/* static Future<void> connectToInvan(bool mounted, BuildContext context,
      {void Function()? onDisconnect, void Function()? onInitial}) async {
    String token = Pref.getString(PrefKeys.token, "not initialized");
    if (token.isEmpty || token == 'not initialized') {
      return;
    }
    try {
      channel = IOWebSocketChannel.connect(
          "${Urls.baseSocketUrl}ws?Authorization=$token&clientType=terminal");
      if (channel != null) {
        if (kDebugMode) {
          print("WebSocket Success");
        }
        // startPing();
        channel!.stream.listen(
          (message) async {
            print('📩 SERVERDAN KELGAN: $message');
            var decoded = json.decode(message);
            if (message.toLowerCase() == "pong") {
              print("✅ PONG qabul qilindi, aloqa aktiv.");
              return;
            }
          },
          onDone: () {
            print("🔴 WebSocket aloqa uzildi.");
            // Future.delayed(retryInterval, () => connectWebSocket(context));
          },
          onError: (error) {
            print('❌ WebSocket xatosi: $error');
          },
        );
      }
    } catch (e) {
      print("❌ WebSocketga ulanishda xatolik: $e");
    }
  }*/
