import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
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

class OrdersService {
  // ─── Cancel support ───────────────────────────────────────────────
  static http.Client? _activeClient;

  static void cancelRequests() {
    _activeClient?.close();
    _activeClient = null;
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
    HttpResult httpResult =
    await ApiProvider.postResponse(path: url, headers: headers);

    if (httpResult.isSuccess) {
      String downloadUrl = httpResult.result['id'].toString();
      String fileName = downloadUrl.split('/').last;

      File downloadedFile = await downloadFile(downloadUrl, fileName);

      final bytes = await downloadedFile.readAsBytes();
      final decoded = GZipCodec().decode(bytes);
      final jsonContent = utf8.decode(decoded);
      try {
        final jsonList = jsonDecode(jsonContent) as List;

      } catch (e) {
        print('print error: $e');
      }
      await downloadedFile.delete();

      return HttpResult(
        statusCode: 200,
        isSuccess: true,
        result: jsonContent,
        reBytes: '',
      );
    }
    return HttpResult(
      statusCode: httpResult.statusCode,
      isSuccess: httpResult.isSuccess,
      result: httpResult.result,
      reBytes: '',
    );
  }

  static Future<File> downloadFile(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    final sink = file.openWrite();

    await response.forEach((chunk) {
      sink.add(chunk);
    });

    await sink.close();
    return file;
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