part of 'theme_mode_bloc.dart';

abstract class ThemeModeState {
  final bool isDark;
  const ThemeModeState(this.isDark);
}

class ThemeModeInitial extends ThemeModeState {
  const ThemeModeInitial(bool isDark) : super(isDark);
}
