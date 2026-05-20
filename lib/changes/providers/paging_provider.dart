import 'package:flutter/material.dart';
import '../../features/drawer/model/model.dart';

class PagingProvider extends ChangeNotifier {
  DrawerItemId _currentPageId = DrawerItemId.home;

  /* //////////////////////// PROVIDER GETTERS //////////////////////// */

  DrawerItemId get getCurrentPageId => _currentPageId;

  /* //////////////////////// PROVIDER METHODS //////////////////////// */

  void setCurrentPageId(DrawerItemId pageId) {
    _currentPageId = pageId;
    notifyListeners();
  }
}
