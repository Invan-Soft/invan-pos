import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/constants/pref_keys.dart';
import '../../utils/helpers/prefs.dart';

part 'theme_mode_event.dart';
part 'theme_mode_state.dart';

class ThemeModeBloc extends Bloc<ThemeModeEvent, ThemeModeState> {
  ThemeModeBloc()
      : super(ThemeModeInitial(Pref.getBool(PrefKeys.isDarkMode, true))) {
    on<ThemeChangedEvent>(_modeChanged);
  }
  _modeChanged(ThemeChangedEvent event, Emitter<ThemeModeState> emit) async {
    emit(ThemeModeInitial(event.isDark));
  }
}
