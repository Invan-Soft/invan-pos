import 'package:flutter/material.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/features.dart';
class AddItemToLocalCategoryDialogProvider extends ChangeNotifier {
  AddItemToLocalCategoryDialogProvider({
    required this.categoryList,
    required this.productList,
  }) : _productsForSearch = productList;

  final List<CategoryData> categoryList;
  final List<ItemModel> productList;

  bool _searchState = false;
  bool _thereProducts = true;

  List<ItemModel> _productsForSearch;


  bool get getSearchState => _searchState;

  bool get getThereProducts => _thereProducts;

  List<ItemModel> get getProductsForSearch => _productsForSearch;

  void setThereProducts(bool thereProducts) {
    if (_thereProducts != thereProducts) {
      _thereProducts = thereProducts;
      notifyListeners();
    }
  }

  void pressSearchIconButton() {
    _searchState = !_searchState;
    if (!_searchState) typeWordForSearch('');
    notifyListeners();
  }

  void typeWordForSearch(String searchWord) {
    if (searchWord == '') {
      _productsForSearch = productList;
    } else {
      _productsForSearch = productList
          .where((element) =>
              element.name!.toLowerCase().contains(searchWord.toLowerCase()))
          .toList();
    }

    notifyListeners();
  }
}
