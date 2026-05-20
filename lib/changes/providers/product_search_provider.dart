import 'package:flutter/material.dart';

enum SearchTypeEnum { option, byBarcode, bySKU, byProductName }

class ProductSearchProvider extends ChangeNotifier {
  bool _searchState = false;
  SearchTypeEnum searchTypeEnum = SearchTypeEnum.byProductName;

  /* //////////////////////// PROVIDER GETTERS //////////////////////// */

  bool get getSearchState => _searchState;

  SearchTypeEnum get getSearchTypeEnum => searchTypeEnum;

  /* //////////////////////// PROVIDER METHODS //////////////////////// */

  // void pressSearchByBarcode() {
  //   _searchState = true;
  //   _searchTypeEnum = SearchTypeEnum.byBarcode;
  //
  //   notifyListeners();
  // }
  //
  // void pressSearchBySKU() {
  //   _searchState = true;
  //   _searchTypeEnum = SearchTypeEnum.bySKU;
  //
  //   notifyListeners();
  // }
  //
  // void pressSearchByProductName() {
  //   _searchState = true;
  //   _searchTypeEnum = SearchTypeEnum.byProductName;
  //
  //   notifyListeners();
  // }
  //
  void pressCloseSearchFieldButton() {
    _searchState = false;
    notifyListeners();
  }
}
