import 'package:device_info_plus/device_info_plus.dart';

class SettingsSingleton {
  const SettingsSingleton._();
  // Faqat shaxsni aniqlash uchun zarur minimal maydonlar yuboriladi
  // (computerName/name + hostName). Qolgan tafsilotlar (CPU, xotira,
  // versiya, GUID va h.k.) Telegram log'ni keraksiz to'ldirgani uchun olib tashlandi.
  static Map<String, dynamic> readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return <String, dynamic>{
      'computerName': data.name,
    };
  }

  static Map<String, dynamic> readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return <String, dynamic>{
      'computerName': data.computerName,
    };
  }

  static Map<String, dynamic> readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return <String, dynamic>{
      'computerName': data.computerName,
      'hostName': data.hostName,
    };
  }

  static Map<String, dynamic> readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'computerName': data.name,
    };
  }

  static Map<String, dynamic> readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'computerName': build.model,
    };
  }

  static Map<String, dynamic> readWebBrowserInfo(WebBrowserInfo data) {
    return <String, dynamic>{
      'computerName': data.browserName.name,
    };
  }
}
