/*
    @author Ayyubxon Ahmajonov, 11/11/2024, 4:06 PM
*/

import '../../api/api_provider.dart';

/// Notification/socket manzillari API muhitidan (ApiProvider) keltirib
/// chiqariladi — ilgari ikkita alohida qo'lda o'zgartiriladigan konstanta
/// edi va API DEV'da, notification PRO'da qolib ketardi (DEV token PRO
/// notification serveriga ketar, sinxron jimgina ishlamasdi).
class Urls {
  static const String socketUrlPro = 'wss://ws.notification.7i.uz/';
  static const String socketUrlDev = 'wss://dev-ws.notification.7i.uz/';
  static const String notificationUrlPro = 'https://ws.notification.7i.uz/';
  static const String notificationUrlDev = 'https://dev-ws.notification.7i.uz/';

  static bool get _isPro => ApiProvider.currentEnv == ApiProvider.envPro;

  static String get baseSocketUrl => _isPro ? socketUrlPro : socketUrlDev;

  static String get baseNotificationUrl =>
      _isPro ? notificationUrlPro : notificationUrlDev;
}
