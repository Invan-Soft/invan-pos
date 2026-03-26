/*
    @author Suxrob Sattorov, 10/14/2025, 3:40 PM
*/

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

  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      if (context.mounted) {
        _showProgressDialog(context);
      }

      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Server javobi: ${response.statusCode}');
      }

      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();

      if (context.mounted) Navigator.pop(context);
      debugPrint('✅ Fayl yuklab olindi: ${file.path}');

      if (!await file.exists()) {
        throw Exception('Fayl topilmadi!');
      }

      debugPrint('🚀 Yangi versiya o‘rnatilmoqda...');

      await Process.start(
        'cmd',
        ['/c', 'start', '', file.path],
        mode: ProcessStartMode.detached,
      );

      debugPrint('✅ Installer ishga tushirildi (CMD orqali)');

      Future.delayed(const Duration(seconds: 10), () async {
        if (await file.exists()) {
          try {
            await file.delete();
            debugPrint('🗑️ Installer fayl o‘chirildi: ${file.path}');
          } catch (e) {
            debugPrint('⚠️ Faylni o‘chirib bo‘lmadi: $e');
          }
        }
      });

      await Future.delayed(const Duration(seconds: 2));
      exit(0);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('❌ Yuklab olish yoki o‘rnatishda xatolik: $e');
      _showErrorDialog(context, '❌ Xatolik: $e');
    }
  }

  void _showProgressDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: SizeConfig.h * 30,
          padding: EdgeInsets.all(SizeConfig.h),
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
                loc.ha.toLowerCase() != 'ha'
                    ? 'Обновление...'
                    : "Yangilanmoqda...",
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 2.5,
                ),
              ),
              SizedBox(height: SizeConfig.v * 2.5),
              CircularProgressIndicator(
                color: Theme.of(context).canvasColor,
              ),
              SizedBox(height: SizeConfig.v * 2.5),
              Text(
                loc.ha.toLowerCase() != 'ha'
                    ? 'Пожалуйста, подождите, идет загрузка новой версии...'
                    : "Iltimos kuting, yangi versiya yuklanmoqda...",
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: SizeConfig.h * 30,
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
                loc.ha.toLowerCase() != 'ha' ? 'Ошибка' : "Xatolik",
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 2.5,
                ),
              ),
              SizedBox(height: SizeConfig.v * 2),
              Text(
                message,
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                ),
              ),
              SizedBox(height: SizeConfig.v * 4),
              Align(
                alignment: Alignment.centerRight,
                child: _dialogButton(
                  context,
                  label: "OK",
                  color: Theme.of(context).primaryColor,
                  onTap: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogButton(BuildContext context,
      {required String label,
      required Color color,
      required VoidCallback onTap}) {
    return SizedBox(
      width: SizeConfig.h * 13,
      height: SizeConfig.v * 5.5,
      child: MaterialButton(
        onPressed: onTap,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
        ),
        child: Text(
          label,
          style: MyThemes.txtStyle(color: Colors.white),
        ),
      ),
    );
  }
}
