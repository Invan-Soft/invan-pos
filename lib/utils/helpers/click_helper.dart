import 'package:hive/hive.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

class ClickHelper {
  const ClickHelper._();
  static final Box _box = HiveBoxes.prefBox();

  static Future<void> putClickData(Map<String, dynamic> clickData) async {
    List<Map<String, dynamic>> list = clickList;
    list.add(clickData);
    await _box.put('click_data', list);
  }

  static List<Map<String, dynamic>> get clickList =>
      _box.get('click_data') ?? [];

  static Future<void> deleteItem(String paymentId) async {
    List<Map<String, dynamic>> list = clickList;
    for (var i = 0; i < list.length; i++) {
      bool isEquals = list[i]['payment_id'].toString() == paymentId.toString();
      if (isEquals) {
        list.removeAt(i);
      }
    }
    await _box.put('click_data', list);
  }
}
