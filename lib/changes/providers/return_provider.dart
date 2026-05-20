import 'package:flutter/material.dart';

class ReturnProvider extends ChangeNotifier {
  bool _isReturningState = false;

  /* //////////////////////// PROVIDER GETTERS //////////////////////// */

  bool get isReturningState => _isReturningState;

  /* //////////////////////// PROVIDER METHODS //////////////////////// */

  void setReturningState() {
    _isReturningState = !_isReturningState;

    notifyListeners();
  }

  void setReturningStateToFalse() {
    _isReturningState = false;

    notifyListeners();
  }
}
