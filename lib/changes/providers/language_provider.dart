import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider(int languageInt) : _language = languageInt;

  int _language;

  int get getLanguage => _language;

  /// {@macro change_language}
  Future<void> changeLanguage(int language) async {
    if (language == 0 || language == 1) {
      if (_language != language) {
        await Pref.setInt(PrefKeys.language, language);
        _language = language;
        notifyListeners();
      }
    }
  }
}
