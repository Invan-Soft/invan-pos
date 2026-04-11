import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:provider/provider.dart';

import 'ordering_provider_4.dart';

class LocalCategoryProvider extends ChangeNotifier {
  List<LocalCategoryModel> _localCategoryList =
      HiveBoxes.getLocalCategories().values.toList().cast<LocalCategoryModel>();
  int _currentSelectedCategoryButton = -1;
  int _tappedPositionToAddProduct = 0;
  String _mainPathName = '';
  bool _isLocalCategoryEditing = false;


  List<LocalCategoryModel> get getLocalCategoryList => _localCategoryList;

  int get getCurrentSelectedCategoryButton => _currentSelectedCategoryButton;

  String get getMainPathName => _mainPathName;

  bool get getIsLocalCategoryEditing => _isLocalCategoryEditing;


  void pressBarchasiButton({required BuildContext context}) {
    _currentSelectedCategoryButton = -1;

    Provider.of<OrderingProvider4>(context, listen: false)
        .changeGridviewItems(null);

    notifyListeners();
  }

  void pressCategoryButton({
    required BuildContext context,
    required int index,
  }) {
    _currentSelectedCategoryButton = index;
    _mainPathName = _localCategoryList[index].name;

    Provider.of<OrderingProvider4>(context, listen: false)
        .changeGridviewItems(_localCategoryList[index].list);
    Provider.of<OrderingProvider4>(context, listen: false).clearPathList();
    notifyListeners();
  }

  void pressBarchasiButtonWhenCategorySelected(BuildContext context) {
    Provider.of<OrderingProvider4>(context, listen: false).changeGridviewItems(
        _localCategoryList[_currentSelectedCategoryButton].list);

    notifyListeners();
  }

  void pressAddCategoryButton(BuildContext context, String categoryName) {
    if (!_localCategoryList.any((element) =>
            element.name.toLowerCase() == categoryName.toLowerCase()) &&
        categoryName.toLowerCase() != 'barchasi' &&
        categoryName.toLowerCase() != 'все') {
      _isLocalCategoryEditing = true;

      final localCategoryModel = LocalCategoryModel(
        name: categoryName,
        list: <LocalCategoryItemModel?>[
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ],
      );

      _localCategoryList.add(localCategoryModel);
      _currentSelectedCategoryButton = _localCategoryList.length - 1;
      _mainPathName = _localCategoryList[_currentSelectedCategoryButton].name;

      Provider.of<OrderingProvider4>(context, listen: false)
          .changeGridviewItems(
              _localCategoryList[_currentSelectedCategoryButton].list);
      notifyListeners();
    }
  }

  void setLocalCategoryEditing() {
    _isLocalCategoryEditing = true;
    notifyListeners();
  }

  Future<void> pressDoneButton() async {
    _currentSelectedCategoryButton = -1;
    _isLocalCategoryEditing = false;

    // remove all empty local categories
    final newList = <LocalCategoryModel>[];
    for (var element in _localCategoryList) {
      bool isNotNull = false;
      for (var innerElement in element.list) {
        if (innerElement != null) isNotNull = true;
      }
      if (isNotNull) newList.add(element);
    }

    final box = HiveBoxes.getLocalCategories();
    await box.clear();
    await box.addAll(newList);
    _localCategoryList = box.values.toList().cast<LocalCategoryModel>();
    notifyListeners();
  }

  void addItemToLocalCategoryList(
      LocalCategoryItemModel item, BuildContext context) {
    _localCategoryList[_currentSelectedCategoryButton]
        .list[_tappedPositionToAddProduct] = item;
    Provider.of<OrderingProvider4>(context, listen: false).changeGridviewItems(
        _localCategoryList[_currentSelectedCategoryButton].list);
    notifyListeners();
  }

  void removeItemFromLocalCategoryList(int position, BuildContext context) {
    _localCategoryList[_currentSelectedCategoryButton].list[position] = null;
    Provider.of<OrderingProvider4>(context, listen: false).changeGridviewItems(
        _localCategoryList[_currentSelectedCategoryButton].list);
    notifyListeners();
  }

  void pressCategoryProductPosition(int position) {
    _tappedPositionToAddProduct = position;
    notifyListeners();
  }
}
