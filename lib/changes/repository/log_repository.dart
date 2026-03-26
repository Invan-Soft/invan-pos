import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/services/api_state.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/changes/services/log_service.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/utils.dart';

import '../data/security.dart';

class
LogRepository {
  static final Box<LogModel> _errorBox = HiveBoxes.getTelegramLogs();
  static final String _deviceInfo =
      Pref.getString(PrefKeys.deviceInfo, "not initialized");
  static final String _version = AppConstants.version;
  static final Employee? _currentEmployee = HiveBoxes.getCurrentEmployee;
  static bool successToTelegram = false;

  static Future addLog(
    String message, {
    required String where,
    String file = '',
    bool success = false,
    String? method,
    String? path,
    int? statusCode,
    String? url,
    String? createdDate,
    String? checkNo,
  }) async {
    successToTelegram = Pref.getBool(PrefKeys.successToTelegram, false);
    if (message.toLowerCase().contains('socketexception') ||
        message.toLowerCase().contains('connection timed out') ||
        message.toLowerCase().contains('failed host lookup') ||
        message.toLowerCase().contains('connection refused') ||
        message.toLowerCase().contains('no route to host') ||
        message.toLowerCase().contains('network is unreachable') ||
        message.toLowerCase().contains('connection reset by peer')) {
      return;
    }
    LogModel log = LogModel(
      version: _version,
      userName: _currentEmployee?.user?.firstName ?? "null",
      url: url,
      statusCode: statusCode,
      phoneModel: "-",
      phone: _deviceInfo,
      path: path,
      method: method,
      message: message,
      file: file,
      type: success,
      isSent: false,
      dateTime: DateTime.now(),
      createdDate: createdDate,
      checkNo: checkNo,
    );
    Box box = HiveBoxes.getLogs();
    bool isSend = false;
    if (statusCode == null) {
      isSend = true;
    } else if (statusCode == 409) {
      isSend = false;
    } else if (statusCode < 200 || statusCode > 300) {
      isSend = true;
    } else {
      isSend = false;
    }
    if (isSend && Pref.getBool(PrefKeys.isSendToTelegram, true)) {
      await box.add(log);
      if (box.values.length > 1000) {
        for (; !(box.length == 1000);) {
          await box.deleteAt(0);
        }
      }
      if (success && !successToTelegram) return;
      telegramLogInProgress = true;
      ApiState state = await LogService.sendToTelegramm(
          log,
          kReleaseMode
              ? SecureKeys.TELEGRAM_BOT_LINK
              : SecureKeys.TELEGRAM_BOT_LINK_DEBUG);
      telegramLogInProgress = false;
      if (state is Failure) {
        await _addError(_logToTelegramLog(log));
      }
      sendUnsentLogs();
    }
    return;
  }

  static bool telegramLogInProgress = false;

  static Future<void> sendUnsentLogs() async {
    Box box = HiveBoxes.getTelegramLogs();
    if (!telegramLogInProgress && box.isNotEmpty) {
      telegramLogInProgress = true;
      for (; box.isNotEmpty;) {
        LogModel log = box.values.cast<LogModel>().toList()[0];
        late ApiState state;

        state = await LogService.sendToTelegramm(
            log,
            kReleaseMode
                ? SecureKeys.TELEGRAM_BOT_LINK
                : SecureKeys.TELEGRAM_BOT_LINK_DEBUG);

        if (state is Success) {
          await box.deleteAt(0);
          telegramLogInProgress = true;
        } else {
          telegramLogInProgress = false;
          break;
        }
      }
    } else {
      return;
    }
  }

  static LogModel _logToTelegramLog(LogModel log) {
    LogModel tgLog = LogModel();
    tgLog
      ..dateTime = log.dateTime
      ..isSent = log.isSent
      ..message = log.message
      ..type = log.type
      ..file = log.file
      ..method = log.method
      ..path = log.path
      ..phone = log.phone
      ..phoneModel = log.phoneModel
      ..statusCode = log.statusCode
      ..url = log.url
      ..userName = log.userName
      ..version = log.version;
    return tgLog;
  }

  static Future _addError(LogModel log) async {
    await _errorBox.add(log);
  }

  static List<LogModel> getTelegramLogss() => _errorBox.values.toList();

  static Future requestSend(
    String message, {
    required String where,
    String file = '',
    bool success = false,
    String? method,
    String? path,
    int? statusCode,
    String? url,
    String? body,
    String? createdDate,
    String? checkNo,
  }) async {
    successToTelegram = Pref.getBool(PrefKeys.successToTelegram, false);
    if (message.toLowerCase().contains('socketexception') ||
        message.toLowerCase().contains('connection timed out') ||
        message.toLowerCase().contains('failed host lookup') ||
        message.toLowerCase().contains('connection refused') ||
        message.toLowerCase().contains('no route to host') ||
        message.toLowerCase().contains('network is unreachable') ||
        message.toLowerCase().contains('connection reset by peer')) {
      return;
    }
    LogModel log = LogModel(
        version: _version,
        userName: _currentEmployee?.user?.firstName ?? "null",
        url: url,
        statusCode: statusCode,
        phoneModel: "-",
        phone: _deviceInfo,
        path: path,
        method: method,
        message: message,
        file: file,
        type: success,
        isSent: false,
        dateTime: DateTime.now(),
        body: body,
        createdDate: createdDate,
        checkNo: checkNo);
    Box box = HiveBoxes.getLogs();
    bool isSend = false;
    if (statusCode == null) {
      isSend = true;
    } else if (statusCode == 409) {
      isSend = false;
    } else if (statusCode < 200 || statusCode > 300) {
      isSend = true;
    } else {
      isSend = false;
    }
    if (isSend && Pref.getBool(PrefKeys.isSendToTelegram, true)) {
      await box.add(log);
      if (box.values.length > 1000) {
        for (; !(box.length == 1000);) {
          await box.deleteAt(0);
        }
      }
      if (success && !successToTelegram) return;
      telegramLogInProgress = true;
      ApiState state = await LogService.sendToTelegramm(
          log,
          kReleaseMode
              ? SecureKeys.TELEGRAM_BOT_LINK_FOR_BODY
              : SecureKeys.TELEGRAM_BOT_LINK_FOR_BODY_DEBUG,
          withBody: true);
      telegramLogInProgress = false;
      if (state is Failure) {
        await _addError(_logToTelegramLog(log));
      }
      // sendUnsentLogs();
    }
    return;
  }
}
