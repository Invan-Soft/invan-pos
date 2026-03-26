import 'package:flutter/widgets.dart'
    show BuildContext, MediaQuery, MediaQueryData;

class SizeConfig {
  static SizeConfig? _instance;
  SizeConfig._() {
    _instance = this;
  }

  factory SizeConfig() => _instance ?? SizeConfig._();

  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double h;
  static late double v;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;

    screenHeight = _mediaQueryData.size.height;
    h = screenWidth / 100;
    v = screenHeight / 100;

    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }
}
