import 'package:flutter/material.dart';
import 'alice_service.dart';

class AppNavigation {
  static final _navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState get navigator => _navigatorKey.currentState!;

  static Future<dynamic> pushNamed(String routeName, {Object? args}) {
    return _navigatorKey.currentState!.pushNamed(routeName, arguments: args);
  }

  static Future<dynamic> pushReplacementNamed(
    String routeName, {
    Object? args,
  }) {
    return navigator.pushReplacementNamed(
      routeName,
      arguments: args,
    );
  }

  static Future<dynamic> pushNamedAndRemoveUntil(String routeName) {
    return navigator.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  static Future<dynamic> pushAndRemoveUntil(Widget page) {
    return navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page), (route) => false);
  }

  static Future<dynamic> push(Widget page) => navigator.push(
        MaterialPageRoute(builder: (_) => page),
      );

  static Future<dynamic> pushReplacement(Widget page) =>
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );

  static void pop({Object? v}) {
    if (navigator.canPop()) {
      navigator.pop(v);
    }
  }

  static void showAliceInspector() {
    alice.setNavigatorKey(navigatorKey);
    alice.showInspector();
  }

  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}
