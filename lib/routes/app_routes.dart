
import 'package:flutter/material.dart';
import 'package:invan2/app/wrapper/wrapper.dart';
import 'package:invan2/features/home/home_page.dart';
import 'package:invan2/routes/app_rout_names.dart';

class AppRoutes {
  static Route? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouteNames.HOME:
        return _route(const HomePage());

      case AppRouteNames.WRAPPER:
        return _route(const Wrapper());

      // case AppRouteNames.LOGS:
      //   return _route(const LogsScreen());

      // case AppRouteNames.UNSENT_RECEIPTS:
      //   return _route(const UnsentReceipts());

      // case AppRouteNames.UNSENT_ERRORS:
      //   return _route(const UnsentErrors());
    }
    return null;
  }

  static MaterialPageRoute _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
