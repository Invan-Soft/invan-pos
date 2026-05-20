import 'dart:async' show Future;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

class Pref {
  static final Box<dynamic> _box = HiveBoxes.prefBox();

  // call this method from iniState() function of mainApp().
  // static Future<void> init() async {
  //   _box
  //   return;
  // }

  static Future<void> setObject(String key, dynamic value) async {
    await _box.put(key, value);
  }

  static getObject(String key) => _box.get(key);

  static String getString(String key, String defValue) {
    return _box.get(key) ?? defValue;
  }

  static Future<void> setString(String key, String value) async {
    await _box.put(key, value);
  }

  static int getInt(String key, int defValue) {
    return _box.get(key) ?? defValue;
  }

  static Future<void> setInt(String key, int value) async {
    return await _box.put(key, value);
  }

  static double getDouble(String key, double defValue) {
    return _box.get(key) ?? defValue;
  }

  static Future<void> setDouble(String key, double value) async {
    return await _box.put(key, value);
  }

  static bool getBool(String key, bool defValue) {
    return _box.get(key) ?? defValue;
  }

  static Future<void> setBool(String key, bool value) async {
    return await _box.put(key, value);
  }

  static Future<void> setDeleteItem(String key, bool value) async {
    return await _box.put(key, value);
  }

//////
  static Future<void> setDonate(String key, bool value) async {
    return await _box.put(key, value);
  }

  static bool getDonate(String key, bool defValue) {
    return _box.get(key) ?? defValue;
  }

  ///
  static bool getDeleteItem(String key) => _box.get(key) ?? true;
  static Future removeWithKey(String removedKey) => _box.delete(removedKey);
}
