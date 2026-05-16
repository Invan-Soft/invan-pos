import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:invan2/changes/singletons/settings_singleton.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class SettingsInnerSingleton {
  static Map<String, dynamic> deviceData = SettingsProvider._deviceData;
  intiDeviceData() async {
    Map<String, dynamic> deviceInfo =
        await SettingsProvider().initPlatformState();
    await Pref.setString(PrefKeys.deviceInfo, deviceInfo.toString());
  }
}

class SettingsProvider extends ChangeNotifier {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  static Map<String, dynamic> _deviceData = <String, dynamic>{};

  bool _showInvoiceButton = Pref.getBool('showInvoiceButton', false);
  bool get showInvoiceButton => _showInvoiceButton;

  void setShowInvoiceButton(bool value) {
    Pref.setBool('showInvoiceButton', value);
    _showInvoiceButton = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {
      if (kIsWeb) {
        deviceData = SettingsSingleton.readWebBrowserInfo(
            await deviceInfoPlugin.webBrowserInfo);
      } else {
        if (Platform.isAndroid) {
          deviceData = SettingsSingleton.readAndroidBuildData(
              await deviceInfoPlugin.androidInfo);
        } else if (Platform.isIOS) {
          deviceData = SettingsSingleton.readIosDeviceInfo(
              await deviceInfoPlugin.iosInfo);
        } else if (Platform.isLinux) {
          deviceData = SettingsSingleton.readLinuxDeviceInfo(
              await deviceInfoPlugin.linuxInfo);
        } else if (Platform.isMacOS) {
          deviceData = SettingsSingleton.readMacOsDeviceInfo(
              await deviceInfoPlugin.macOsInfo);
        } else if (Platform.isWindows) {
          deviceData = SettingsSingleton.readWindowsDeviceInfo(
              await deviceInfoPlugin.windowsInfo);
        }
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }
    SettingsInnerSingleton.deviceData = deviceData;
    _deviceData = deviceData;
    notifyListeners();
    return deviceData;
  }
}
