/// BUILD NOTES
/// --  change the version
/// --  make ofd, incom or simple
/// --  check the localhost is properly selected
/////////////////////////////////////////////////////
/// It's a class that contains static variables and methods

import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class AppConstants {
  // static const localhost = 'http://integration.epos.uz:8347/uzpos';
  static const localhost = 'http://localhost:8080/invan';

  // static const localhost = 'http://localhost:8347/uzpos';

  static String version = Pref.getString(PrefKeys.version, '');

  static String get acceptVersion => '1.0.0';

  static Map<String, String> getHeaders() {
    final token = Pref.getString(PrefKeys.token, 'not initialized');
    final posId = Pref.getString(PrefKeys.activatedPosId, 'not initialized');
    final acceptService =
        Pref.getString(PrefKeys.acceptService, 'not initialized');
    return <String, String>{
      'Accept-Version': '1.0.0',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': "Bearer $token",
      'Accept-Id': posId,
      'Accept-User': 'employee',
      'Accept-Service': acceptService,
      'Accept-EmptyShow': '0',
      'timezone': '-300',
    };
  }
}
