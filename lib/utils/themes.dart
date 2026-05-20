import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invan2/utils/utils.dart';

class MyThemes {
  static ThemeData lightThemeData(BuildContext context) {
    return ThemeData(
      disabledColor: const Color(0xff7D8FA3),
      primaryColorDark: const Color(0xff101920),
      dividerColor: const Color(0xff17212B),
      primaryColor: const Color(0xff0133C6),
      highlightColor: const Color(0xffBFBFBF),

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xffF4F4F4),
        onPrimary: Color(0xffF4F4F4),
        secondary: Color(0xffF4F4F4),
        onSecondary: Color(0xffF4F4F4),
        error: Color(0xffF4F4F4),
        onError: Color(0xffF4F4F4),
        background: Color(0xffF4F4F4),
        onBackground: Color(0xffF4F4F4),
        surface: Color(0xffF4F4F4),
        onSurface: Color(0xffF4F4F4),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Color(0xffEBECEC),
      ),
      // bottomAppBarColor: const Color(0xffEBECEC),
      canvasColor: const Color(0xff101920),
      dialogBackgroundColor: const Color(0xff17212B).withOpacity(0.07),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xff0133C6)),

      //////////////////////////////////////////////
      scaffoldBackgroundColor: const Color(0xFFf5f5f8),
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
          .apply(bodyColor: Colors.black),
      appBarTheme: const AppBarTheme(
        elevation: 0,
      ),

      ////////////////////////Button Colors/////////////////////
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
        ),
      ),
      //////////////////////////////////////////////////////////
    );
  }

  static ThemeData darkThemeData(BuildContext context) {
    return ThemeData.dark().copyWith(
      disabledColor: const Color(0xff7D8FA3),
      highlightColor: const Color(0xff2B5278),
      dividerColor: const Color(0xff708499),
      primaryColor: const Color(0xff2B5278),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xff101920),
        onPrimary: Color(0xff101920),
        secondary: Color(0xff101920),
        onSecondary: Color(0xff101920),
        error: Color(0xff101920),
        onError: Color(0xff101920),
        background: Colors.green,
        onBackground: Color(0xff101920),
        surface: Colors.green,
        onSurface: Color(0xff101920),
      ),
      // bottomAppBarColor: const Color(0xff7D8FA3),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Color(0xff7D8FA3),
      ),
      canvasColor: const Color(0xffCFCFCF),
      //textWhiteColor
      dialogBackgroundColor: const Color(0xff212D3B),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xff2B5278)),
      ///////////////////////////////////////////////
      buttonTheme: const ButtonThemeData(
        disabledColor: Color.fromARGB(255, 139, 129, 199),
        minWidth: double.infinity,
      ),
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
          .apply(bodyColor: Colors.black),

      ////////////////////////Button Colors/////////////////////
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
        ),
      ),
      //////////////////////////////////////////////////////////
    );
  }

  static TextStyle txtStyle(
      {double fontSize = 2.5,
      TextDecoration? textDecoration = TextDecoration.none,
      FontWeight fontWeight = FontWeight.normal,
      Color color = Colors.black,
      FontStyle fontStyle = FontStyle.normal,
      Color bgColor = Colors.transparent}) {
    fontSize *= SizeConfig.v * .9;
    return TextStyle(
      decoration: textDecoration,
      backgroundColor: bgColor,
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
      fontStyle: fontStyle,
    );
    // return GoogleFonts.aBeeZee(
    //   fontWeight: fontWeight,
    //   fontSize: fontSize,
    //   color: color,
    //   fontStyle: fontStyle,
    // );
  }

  static TextStyle txtStyleWhite(
      {double fontSize = 2.5,
      FontWeight fontWeight = FontWeight.normal,
      Color color = const Color(0xffCFCFCF),
      FontStyle fontStyle = FontStyle.normal,
      Color bgColor = Colors.transparent}) {
    fontSize *= SizeConfig.v * .9;
    return TextStyle(
      backgroundColor: bgColor,
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
      fontStyle: fontStyle,
    );
    // return GoogleFonts.aBeeZee(
    //   fontWeight: fontWeight,
    //   fontSize: fontSize,
    //   color: color,
    //   fontStyle: fontStyle,
    // );
  }

  static Color get textWhiteColor => const Color(0xffCFCFCF);

  static Color get textBlackColor => const Color(0xff101920);

  static Color get darkBgColor => const Color(0xff101920);
  static Color lightGreyColorr = const Color(0xffF5F5F5);
  static Color darkPrimaryColor = const Color(0xff2B5278);
  static Color lightPrimaryColor = const Color(0xff2B5278);
  static Color lightBackgroundColor = const Color(0xffF4F4F4);
  static Color darkBackgroundColor = const Color(0xff101920);
}
