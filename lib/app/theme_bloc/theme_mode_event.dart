part of 'theme_mode_bloc.dart';

abstract class ThemeModeEvent  {}

class ThemeChangedEvent extends ThemeModeEvent {
  final bool isDark;
   ThemeChangedEvent(this.isDark);
}
