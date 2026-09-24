import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:path_provider/path_provider.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:windows1251/windows1251.dart';

import '../../features/get_products/singletons/items_singleton.dart';
import '../../features/hive_repository/hive_boxes.dart';
import '../models/product/item_model.dart';
import '../models/product/soliq_mxik_model.dart';
import 'startup_progress.dart';

class OrdersService {
  // ─── Cancel support ───────────────────────────────────────────────
  static http.Client? _activeClient;
  static HttpClient? _activeDownloadClient;

  static void cancelRequests() {
    _activeClient?.close();
    _activeClient = null;
  }

  /// 43 MB katalog yuklanishini majburan to'xtatadi.
  ///
  /// `Future.timeout()` (StreamSyncRunner'da to'liq yuklash uchun) faqat
  /// KUTISHNI to'xtatadi — asl `HttpClient` chaqiruvi o'zi to'xtamasdan
  /// fonda davom etardi (yarim soatgacha, agar link juda sekin bo'lsa-yu
  /// 90 s sukut chegarasiga urilmasa) va keyin qulfsiz Hive'ga yozardi.
  /// Runner timeout'ni ushlaganda shu metodni chaqiradi — ulanish darhol
  /// yopiladi, `downloadFile` ichidagi kutish `SocketException`/xato bilan
  /// tugaydi.
  static void cancelCatalogDownload() {
    _activeDownloadClient?.close(force: true);
    _activeDownloadClient = null;
  }
  // ──────────────────────────────────────────────────────────────────

  static Future<void> _saveSoliqMxikItemsToLocal(
      List<SoliqMxikModel> items) async {
    final box = HiveBoxes.markingProductsBox();
    await box.clear();
    final Map<String, SoliqMxikModel> entries = {
      for (final item in items) item.mxik: item,
    };
    await box.putAll(entries);
  }

  static Future<Set<String>> _loadSoliqMxikSetFromLocal() async {
    final box = HiveBoxes.markingProductsBox();
    return box.keys.cast<String>().toSet();
  }

  static Future<HttpResult> getItems() async {
    String token = Pref.getString(PrefKeys.token, "not initialized");
    var headers = {
      'Accept-Encoding': 'gzip',
      'Accept-user': 'employeee',
      'Authorization': "Bearer $token",
      "timezone": "-300"
    };
    String url = 'api/v1/products_json_gzip';
    // Server arxivni tayyorlayotgan bosqich — bu vaqt ichida siljish
    // haqida ma'lumot yo'q, shuning uchun shkala shu bosqich boshida turadi.
    StartupProgress.set(StartupPhase.productsRequest);
    HttpResult httpResult =
    await ApiProvider.postResponse(path: url, headers: headers);

    if (httpResult.isSuccess) {
      String downloadUrl = httpResult.result['id'].toString();
      String fileName = downloadUrl.split('/').last;

      // Yuklash/ochish xatosi (timeout, tarmoq uzilishi, buzuq arxiv)
      // istisno bo'lib chiqmaydi — chaqiruvchilar (startup, UpdBloc,
      // CatchUpSync) natijani `isSuccess` bilan tekshiradi.
      try {
        File downloadedFile = await downloadFile(
          downloadUrl,
          fileName,
          onProgress: StartupProgress.download,
        );

        // Yuklab olish tugadi — endi arxivni ochib, lokalga yozish bosqichi.
        StartupProgress.saving(0);

        // Arxivni ochish + JSON parse alohida isolate'da: 43 MB ni asosiy
        // isolate'da ochish UI'ni bir necha soniya qotirardi (skaner
        // kiritishi bo'linib ketardi). Natija `Isolate.exit` bilan
        // nusxalanmasdan qaytadi.
        final String path = downloadedFile.path;
        final List<dynamic> decoded =
            await Isolate.run(() => decodeCatalogFile(path));
        try {
          await downloadedFile.delete();
        } catch (_) {
          // Windows'da antivirus/indekslovchi faylni ushlab turishi mumkin —
          // vaqtinchalik fayl qolib ketgani muvaffaqiyatni bekor qilmaydi.
        }

        return HttpResult(
          statusCode: 200,
          isSuccess: true,
          // E'tibor: endi satr emas, tayyor ro'yxat. Chaqiruvchilar
          // `result is String ? json.decode(...) : result` bilan o'qiydi.
          result: decoded,
          reBytes: '',
        );
      } catch (e) {
        return HttpResult(
          statusCode: -1,
          isSuccess: false,
          result: 'Katalogni yuklab bo\'lmadi: $e',
          reBytes: '',
        );
      }
    }
    return HttpResult(
      statusCode: httpResult.statusCode,
      isSuccess: httpResult.isSuccess,
      result: httpResult.result,
      reBytes: '',
    );
  }

  /// gzip → utf8 → JSON. Alohida isolate'da ishlaydi (Hive/Pref ishlatmaydi).
  static List<dynamic> decodeCatalogFile(String path) {
    final List<int> bytes = File(path).readAsBytesSync();
    final List<int> unzipped = GZipCodec().decode(bytes);
    final dynamic json = jsonDecode(utf8.decode(unzipped));
    if (json is! List) {
      throw const FormatException('Katalog javobi ro\'yxat emas');
    }
    return json;
  }

  /// Ulanish va sarlavha kutish chegarasi.
  static const Duration downloadConnectTimeout = Duration(seconds: 30);

  /// Ketma-ket ikki bo'lak orasidagi maksimal sukut. Bu UMUMIY chegara
  /// emas (43 MB sekin internetda uzoq yuklanishi mumkin) — faqat oqim
  /// butunlay to'xtab qolganini aniqlaydi.
  static const Duration downloadIdleTimeout = Duration(seconds: 90);

  /// [onProgress] — `(olingan bayt, jami bayt)`. Server `Content-Length`
  /// bermasa `jami` manfiy bo'ladi va chaqiruvchi foiz ko'rsatmasligi kerak.
  ///
  /// Ilgari bu yerda hech qanday timeout yo'q edi: yuklash o'rtada osilsa
  /// `await response.forEach` abadiy kutar, `CatchUpSync` qulfi bo'shamas
  /// va har daqiqalik sinxron restartgacha jimgina o'chib qolardi.
  static Future<File> downloadFile(
    String url,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    final HttpClient client = HttpClient()
      ..connectionTimeout = downloadConnectTimeout;
    _activeDownloadClient = client;
    try {
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(downloadConnectTimeout);
      final response = await request.close().timeout(downloadConnectTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Yuklash javobi: ${response.statusCode}',
            uri: Uri.parse(url));
      }

      final sink = file.openWrite();
      final int total = response.contentLength;
      int received = 0;

      try {
        await response
            .timeout(downloadIdleTimeout, onTimeout: (EventSink<List<int>> s) {
          s.addError(TimeoutException(
              'Yuklash to\'xtab qoldi (${downloadIdleTimeout.inSeconds} s)',
              downloadIdleTimeout));
          s.close();
        }).forEach((chunk) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        });
      } finally {
        await sink.close();
      }
      return file;
    } finally {
      client.close(force: true);
      if (identical(_activeDownloadClient, client)) _activeDownloadClient = null;
    }
  }

  static Future<HttpResult> getAllMxikItemsWithHistory() async {
    const String baseUrl = 'https://tasnif.soliq.uz';
    const String endpoint =
        '/api/cl-api/integration-mxik/get/all/history/time-json';
    final uri = Uri.parse('$baseUrl$endpoint');

    final headers = {
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate',
    };
    
    try {
      _activeClient = http.Client();
      final response = await _activeClient!.get(uri, headers: headers);

      _activeClient = null;

      if (response.statusCode != 200) {
        return HttpResult(
          statusCode: response.statusCode,
          isSuccess: false,
          result: response.body,
          reBytes: '',
        );
      }

      final String decodedString = windows1251.decode(response.bodyBytes);
      final List<dynamic> rawList = jsonDecode(decodedString);

      final List<SoliqMxikModel> cleanList = rawList
          .whereType<Map<String, dynamic>>()
          .where((e) => e['label'] == 1)
          .map((item) => SoliqMxikModel.fromMap(item))
          .where((model) => model.mxik.isNotEmpty)
          .toList();

      await _saveSoliqMxikItemsToLocal(cleanList);

      return HttpResult(
        statusCode: 200,
        isSuccess: true,
        result: cleanList,
        reBytes: '',
      );
    } catch (e) {
      _activeClient = null;
      // client.close() chaqirilganda ClientException keladi — bu bekor qilish signali
      final msg = e.toString();
      if (msg.contains('ClientException') ||
          msg.contains('Connection closed') ||
          msg.contains('Software caused connection abort')) {
        return HttpResult(
          statusCode: 0,
          isSuccess: false,
          result: 'cancelled',
          reBytes: null,
        );
      }
      return HttpResult(
        statusCode: 0,
        isSuccess: false,
        result: 'Xato: $e',
        reBytes: null,
      );
    }
  }

  Future<void> updateMarkingStatusFromSoliq({
    bool fromLocal = false,
  }) async {
    try {
      Set<String> markingMxikSet;

      if (fromLocal) {
        markingMxikSet = await _loadSoliqMxikSetFromLocal();
        if (markingMxikSet.isEmpty) return;
      } else {
        final soliqResult = await getAllMxikItemsWithHistory();
        if (!soliqResult.isSuccess || soliqResult.result == null) return;
        markingMxikSet = (soliqResult.result as List<SoliqMxikModel>)
            .map((m) => m.mxik)
            .toSet();
      }

      final box = HiveBoxes.getProducts();
      if (box.isEmpty) return;

      final products = box.values.toList(growable: false);

      final uniqueMxiks = products
          .map((p) => (p.mxikCode ?? '').trim())
          .where((m) => m.isNotEmpty)
          .toSet();

      final Map<dynamic, ItemModel> updates = {};

      for (final p in products) {
        final mxik = (p.mxikCode ?? '').trim();
        if (mxik.isEmpty) continue;

        final bool currentMarking = p.isMarking ?? false;
        if (markingMxikSet.contains(mxik) && !currentMarking) {
          updates[p.key] = p.copyWith(isMarking: true);
        }
      }


      if (updates.isNotEmpty) {
        await box.putAll(updates);
      }

      await ItemsSingleton.storeProducts();
    } catch (e, stack) {
      print('Xato: $e\n$stack');
      rethrow;
    }
  }

}