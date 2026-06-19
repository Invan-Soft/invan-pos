/*
    @author Suxrob Sattorov, 10/14/2025, 3:40 PM
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../alice_service.dart';
import '../../changes/services/api/api_provider.dart';
import '../../changes/services/log_helper.dart';
import '../constants/pref_keys.dart';
import '../helpers/prefs.dart';
import '../helpers/size_config.dart';
import '../l10n/app_localizations.dart';
import '../themes.dart';

class UpdateChecker {
  final String apiUrl = "${ApiProvider.baseUrlINVAN2}file";

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await http.get(Uri.parse(apiUrl));
      await LogHelper.logRequest(method: "Get", path: apiUrl, statusCode: response.statusCode,response: response.body);

      alice.onHttpResponse(response);

      if (response.statusCode != 200) {
        debugPrint('❌ Versiyani olishda xatolik: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body);
      final latestVersionRaw = (data['version'] ?? '').toString().trim();
      final downloadUrl = (data['name'] ?? '').toString();
      final changeLog = (data['change_log'] ?? '').toString();

      final cleaned = latestVersionRaw
          .replaceAll('+', ' ')
          .replaceAll('(', ' ')
          .replaceAll(')', ' ')
          .trim();

      final parts = cleaned
          .split(RegExp(r'\s+'))
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();

      final latestVersion = parts.isNotEmpty ? parts[0] : '0.0.0';
      int latestBuild = 0;

      if (parts.length > 1) {
        final buildStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        latestBuild = int.tryParse(buildStr) ?? 0;
      }

      if (_isNewVersion(
          currentVersion, latestVersion, currentBuild, latestBuild)) {
        _showUpdateDialog(context, latestVersionRaw, downloadUrl, changeLog);
      } else {
        _showNoUpdateDialog(context);
        debugPrint('✅ Dastur eng so‘nggi versiyada.');
      }
    } catch (e) {
      debugPrint('❌ Update tekshirishda xatolik: $e');
    }
  }

  /// 🔸 Versiyani solishtirish
  bool _isNewVersion(
    String currentVersion,
    String latestVersion,
    int currentBuild,
    int latestBuild,
  ) {
    try {
      final currentParts =
          currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latestParts =
          latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = latestParts.length > currentParts.length
          ? latestParts.length
          : currentParts.length;

      for (int i = 0; i < maxLength; i++) {
        final current = i < currentParts.length ? currentParts[i] : 0;
        final latest = i < latestParts.length ? latestParts[i] : 0;

        if (latest > current) {
          debugPrint('✅ Yangi versiya topildi');
          return true;
        } else if (latest < current) {
          debugPrint('❌ Serverdagi versiya eskiroq');
          return false;
        }
      }

      if (latestBuild > currentBuild) {
        debugPrint('✅ Versiya teng, lekin build yuqoriroq');
        return true;
      }

      debugPrint('❌ Versiya va build teng, yangilanish kerak emas');
      return false;
    } catch (e) {
      debugPrint('⚠️  Taqqoslashda xatolik: $e');
      return currentVersion != latestVersion || latestBuild > currentBuild;
    }
  }

  void _showUpdateDialog(
      BuildContext context, String version, String url, String log) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: SizeConfig.h * 33,
          padding: EdgeInsets.all(SizeConfig.h),
          decoration: BoxDecoration(
            color: Pref.getBool(PrefKeys.isDarkMode, true)
                ? Theme.of(context).dialogBackgroundColor
                : MyThemes.lightGreyColorr,
            borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.ha.toLowerCase() != 'ha'
                    ? '🆕 Доступна новая версия!'
                    : "🆕 Yangi versiya mavjud!",
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 3,
                ),
              ),
              SizedBox(height: SizeConfig.v * 3),
              Text(
                loc.ha.toLowerCase() != 'ha'
                    ? "Версия: $version"
                    : "Versiya: $version",
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                ),
              ),
              SizedBox(height: SizeConfig.v * 2),
              Text(
                loc.ha.toLowerCase() != 'ha'
                    ? "Изменения: $log"
                    : "O‘zgarishlar: $log",
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                ),
              ),
              SizedBox(height: SizeConfig.v * 5.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: SizeConfig.h * 15,
                    height: SizeConfig.v * 6.18,
                    child: MaterialButton(
                      onPressed: () => Navigator.pop(ctx),
                      color: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
                      ),
                      child: Text(
                        loc.bekor_qilish,
                        style: MyThemes.txtStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: SizeConfig.h * 15,
                    height: SizeConfig.v * 6.18,
                    child: MaterialButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _downloadAndInstall(context, url);
                      },
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
                      ),
                      child: Text(
                        loc.ha.toLowerCase() != 'ha'
                            ? "Обновлять"
                            : "Yangilash",
                        style: MyThemes.txtStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoUpdateDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: SizeConfig.h * 33,
          padding: EdgeInsets.all(SizeConfig.h),
          decoration: BoxDecoration(
            color: Pref.getBool(PrefKeys.isDarkMode, true)
                ? Theme.of(context).dialogBackgroundColor
                : MyThemes.lightGreyColorr,
            borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.ha.toLowerCase() != 'ha'
                    ? '✅ У вас последняя версия!'
                    : '✅ Sizda eng so‘nggi versiya o‘rnatilgan!',
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 3,
                ),
              ),
              SizedBox(height: SizeConfig.v * 3),
              Text(
                loc.ha.toLowerCase() != 'ha'
                    ? 'Обновление не требуется.'
                    : 'Yangilanish talab qilinmaydi.',
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                ),
              ),
              SizedBox(height: SizeConfig.v * 5.5),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: SizeConfig.h * 30,
                  height: SizeConfig.v * 6.18,
                  child: MaterialButton(
                    onPressed: () => Navigator.pop(ctx),
                    color: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
                    ),
                    child: Text(
                      loc.ha.toLowerCase() != 'ha' ? "Закрыть" : "Yopish",
                      style: MyThemes.txtStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Yuklab olish + o'rnatish: progress %, bekor qilish va xato inline ko'rsatiladi.
  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDownloadDialog(url: url),
    );
  }
}

/// Yangi versiyani yuklab olib o'rnatadi.
/// - Progress foizi + yuklab olingan MB ko'rsatadi
/// - Yuklash jarayonida "Bekor qilish" tugmasi (so'rovni uzadi, faylni o'chiradi)
/// - Xato bo'lsa shu dialog ichida ko'rsatiladi (alohida qora-fon dialog emas)
class UpdateDownloadDialog extends StatefulWidget {
  final String url;
  const UpdateDownloadDialog({super.key, required this.url});

  @override
  State<UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<UpdateDownloadDialog> {
  HttpClient? _client;
  StreamSubscription<List<int>>? _sub;
  IOSink? _sink;
  File? _file;

  bool _canceled = false;
  bool _error = false;
  String _errorMsg = '';
  int _received = 0;
  int _total = 0;

  double get _progress =>
      _total > 0 ? (_received / _total).clamp(0.0, 1.0) : 0.0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    try {
      _client?.close(force: true);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.url.split('/').last;
      _file = File('${tempDir.path}/$fileName');
      _client = HttpClient();
      final request = await _client!.getUrl(Uri.parse(widget.url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Server javobi: ${response.statusCode}');
      }
      _total = response.contentLength;
      _sink = _file!.openWrite();
      _sub = response.listen(
        (chunk) {
          _sink!.add(chunk);
          _received += chunk.length;
          if (mounted) setState(() {});
        },
        onDone: () async {
          try {
            await _sink!.flush();
            await _sink!.close();
          } catch (_) {}
          try {
            _client!.close();
          } catch (_) {}
          if (_canceled) return;
          await _install();
        },
        onError: (e) async {
          try {
            await _sink?.close();
          } catch (_) {}
          if (_canceled) return;
          _fail('$e');
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (_canceled) return;
      _fail('$e');
    }
  }

  void _fail(String msg) {
    debugPrint('❌ Update download/install xatosi: $msg');
    if (mounted) {
      setState(() {
        _error = true;
        _errorMsg = msg;
      });
    }
  }

  Future<void> _install() async {
    if (_file == null || !await _file!.exists()) {
      _fail('Fayl topilmadi');
      return;
    }
    debugPrint('🚀 O‘rnatilmoqda: ${_file!.path}');
    try {
      await Process.start(
        'cmd',
        ['/c', 'start', '', _file!.path],
        mode: ProcessStartMode.detached,
      );
    } catch (e) {
      _fail('O‘rnatib bo‘lmadi: $e');
      return;
    }
    await Future.delayed(const Duration(seconds: 2));
    exit(0);
  }

  Future<void> _cancel() async {
    _canceled = true;
    await _sub?.cancel();
    try {
      await _sink?.close();
    } catch (_) {}
    try {
      _client?.close(force: true);
    } catch (_) {}
    try {
      if (_file != null && await _file!.exists()) await _file!.delete();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  String _mb(int b) => (b / 1024 / 1024).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool isUz = loc.ha.toLowerCase() == 'ha';
    final String percent = (_progress * 100).toStringAsFixed(0);

    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: SizeConfig.h * 32,
        padding: EdgeInsets.all(SizeConfig.h * 1.2),
        decoration: BoxDecoration(
          color: Pref.getBool(PrefKeys.isDarkMode, true)
              ? Theme.of(context).dialogBackgroundColor
              : MyThemes.lightGreyColorr,
          borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error
                  ? (isUz ? 'Xatolik' : 'Ошибка')
                  : (isUz ? 'Yangilanmoqda...' : 'Обновление...'),
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
                fontSize: 2.6,
              ),
            ),
            SizedBox(height: SizeConfig.v * 2.5),
            if (_error)
              Text(
                _errorMsg,
                textAlign: TextAlign.center,
                style: MyThemes.txtStyle(color: Colors.red, fontSize: 1.9),
              )
            else if (_total > 0) ...[
              Text(
                '$percent%',
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 3.5,
                ),
              ),
              SizedBox(height: SizeConfig.v * 1.5),
              ClipRRect(
                borderRadius: BorderRadius.circular(SizeConfig.v),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: SizeConfig.v * 1.2,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: SizeConfig.v * 1.2),
              Text(
                '${_mb(_received)} / ${_mb(_total)} MB',
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 1.8,
                ),
              ),
            ] else ...[
              CircularProgressIndicator(color: Theme.of(context).canvasColor),
              SizedBox(height: SizeConfig.v * 1.5),
              Text(
                '${_mb(_received)} MB',
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 1.8,
                ),
              ),
            ],
            SizedBox(height: SizeConfig.v * 3),
            SizedBox(
              width: double.infinity,
              height: SizeConfig.v * 6,
              child: MaterialButton(
                onPressed: _error ? () => Navigator.of(context).pop() : _cancel,
                color: _error ? Theme.of(context).primaryColor : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
                ),
                child: Text(
                  _error
                      ? (isUz ? 'Yopish' : 'Закрыть')
                      : (isUz ? 'Bekor qilish' : 'Отмена'),
                  style: MyThemes.txtStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
