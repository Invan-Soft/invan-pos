import 'package:flutter/material.dart';
import 'package:invan2/changes/services/log_helper.dart';

/// Har bir sahifa o'tishini (push/pop/replace) log fayliga yozadi.
/// MaterialApp'ning navigatorObservers ro'yxatiga qo'shiladi.
class LogNavigatorObserver extends NavigatorObserver {
  String _name(Route<dynamic>? route) {
    if (route == null) return '-';
    final settings = route.settings;
    if (settings.name != null && settings.name!.isNotEmpty) {
      return settings.name!;
    }
    // Nomsiz route'lar uchun widget tipini beramiz.
    return route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    LogHelper.activity('NAV_PUSH',
        {'to': _name(route), 'from': _name(previousRoute)});
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    LogHelper.activity('NAV_POP',
        {'from': _name(route), 'to': _name(previousRoute)});
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    LogHelper.activity('NAV_REPLACE',
        {'to': _name(newRoute), 'from': _name(oldRoute)});
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    LogHelper.activity('NAV_REMOVE',
        {'removed': _name(route), 'current': _name(previousRoute)});
  }
}
