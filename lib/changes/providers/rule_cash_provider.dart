import 'package:flutter/cupertino.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/utils/utils.dart';

class RuleCashProvider extends ChangeNotifier {
  double _money = 0;
  String _note = '';
  bool _isButtonValidd = false;

  /// ************ PROVIDER GETTERS ************ ///

  bool get getIsButtonValid => _isButtonValidd;

  /// ************ PROVIDER METHODS ************ ///

  void pressKirim() {
    final model = RuleCashModel4(
      time: _getDateString(),
      cashierName: Pref.getString(PrefKeys.cashierName, "not initialized"),
      note: _note,
      money: _money,
      isIncome: true,
      cashType: 0,
    );

    ShiftSingleton4.saveRuleCash(model);
    _note = '';
    _checkButtonValidation();
    notifyListeners();
  }

  void pressChiqim() {
    final model = RuleCashModel4(
      time: _getDateString(),
      cashierName: Pref.getString(PrefKeys.cashierName, "not initialized"),
      note: _note,
      money: _money,
      isIncome: false,
      cashType: 1,
    );

    ShiftSingleton4.saveRuleCash(model);
    _note = '';
    _checkButtonValidation();
    notifyListeners();
  }

  void pressInkassatsiya() {
    final model = RuleCashModel4(
      time: _getDateString(),
      cashierName: Pref.getString(PrefKeys.cashierName, "not initialized"),
      note: _note,
      money: _money,
      isIncome: false,
      cashType: 2,
    );

    ShiftSingleton4.saveRuleCash(model);
    _note = '';
    _checkButtonValidation();
    notifyListeners();
  }

  void typeMoney(String text) {
    if (text == '') {
      _money = 0;
    } else {
      _money = double.parse(text);
    }
    _checkButtonValidation();

    notifyListeners();
  }

  void typeNote(String text) {
    _note = text;
    _checkButtonValidation();

    notifyListeners();
  }

  void _checkButtonValidation() {
    if (_money > 0 && _note.isNotEmpty) {
      _isButtonValidd = true;
    } else {
      _isButtonValidd = false;
    }
  }

  String _getDateString() {
    final d = DateTime.now();
    String t = '';
    t += d.day < 10 ? '0${d.day}' : d.day.toString();
    t += '.';
    t += d.month < 10 ? '0${d.month}' : d.month.toString();
    t += '.';
    t += d.year.toString();
    t += ' ';
    t += d.hour < 10 ? '0${d.hour}' : d.hour.toString();
    t += ':';
    t += d.minute < 10 ? '0${d.minute}' : d.minute.toString();
    return t;
  }
}
