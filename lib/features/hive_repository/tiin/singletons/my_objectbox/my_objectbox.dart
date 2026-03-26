import 'package:invan2/objectbox.g.dart';

// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

class MyObjectbox {
  static late Store storee;
  static late Store saleStore;

  static Future<void> init() async {
    final dir = await path_provider.getApplicationSupportDirectory();

    // final objectBoxDir = Directory('${dir.path}/invan_pos_objectbox_db');
    // final objectBoxDir2 = Directory('${dir.path}/sale_objectbox_db');
    //
    // if (await objectBoxDir.exists()) {
    //   await objectBoxDir.delete(recursive: true);
    // }
    // if (await objectBoxDir2.exists()) {
    //   await objectBoxDir2.delete(recursive: true);
    // }

    storee = Store(
      getObjectBoxModel(),
      directory: path.join(dir.path, "invan_pos_objectbox_db"),
    );
    saleStore = Store(
      getObjectBoxModel(),
      directory: path.join(dir.path, "sale_objectbox_db"),
    );
  }
}
