
import 'package:flutter/material.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

class GetCategoriesProvider extends ChangeNotifier {
  bool _isDownloading = false;


  bool get getIsDownloading => _isDownloading;


  Future<void> startFindCategories() async {
    _isDownloading = true;
    notifyListeners();

    HttpResult httpResult = await CategoriesApi.categoryFind();

    if (httpResult.isSuccess) {
      final box = HiveBoxes.getCategories();
      await box.clear();
   

      
      Category category = Category.fromJson(httpResult.result);
      if (category.data!.isNotEmpty) await box.addAll(category.data!);

      _isDownloading = false;
      notifyListeners();
    }
  }
}
