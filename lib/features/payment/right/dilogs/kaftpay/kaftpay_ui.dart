// Kaftpay oynalari va sozlama sahifasi uchun ranglar.
//
// Ilova temasida (`lib/utils/themes.dart`) matn rangi `textTheme` da qora,
// `colorScheme` ning hamma ranglari esa #101920 — tungi temada standart
// Material vidjetlari (TextField, sarlavha, indikator, xato rangi) fon bilan
// qo'shilib ko'rinmay qoladi. Boshqa sahifalar matnga `canvasColor` ni qo'lda
// beradi (tungi — och, kunduzgi — to'q); bu yerda shu rang bitta joyda
// mavzuga aylantiriladi.

import 'package:flutter/material.dart';

class KaftpayUi {
  KaftpayUi._(this.base, this.fg, this.dark);

  factory KaftpayUi.of(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.canvasColor;
    return KaftpayUi._(theme, fg, fg.computeLuminance() > 0.5);
  }

  final ThemeData base;

  /// Asosiy matn rangi (ilovadagi `canvasColor`).
  final Color fg;

  /// Tungi tema.
  final bool dark;

  Color get muted => fg.withValues(alpha: 0.7);
  Color get bg => dark ? const Color(0xff212D3B) : Colors.white;
  Color get card => dark ? const Color(0xff1A2430) : const Color(0xffF4F6F8);
  Color get accent => dark ? const Color(0xff64B5F6) : const Color(0xff0133C6);
  Color get success => dark ? const Color(0xff81C784) : const Color(0xff2E7D32);
  Color get warning => dark ? const Color(0xffFFB74D) : const Color(0xffE65100);
  Color get error => dark ? const Color(0xffEF9A9A) : const Color(0xffC62828);

  ThemeData get theme {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: fg.withValues(alpha: 0.35)),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: fg, displayColor: fg),
      colorScheme: base.colorScheme.copyWith(
        onSurface: fg,
        onSurfaceVariant: muted,
      ),
      iconTheme: base.iconTheme.copyWith(color: fg),
      cardTheme: base.cardTheme.copyWith(color: card),
      listTileTheme: base.listTileTheme.copyWith(
        textColor: fg,
        iconColor: fg,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: bg,
        titleTextStyle:
            TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w700),
        contentTextStyle: TextStyle(color: fg, fontSize: 15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(color: accent),
        hintStyle: TextStyle(color: fg.withValues(alpha: 0.4)),
        border: border,
        enabledBorder: border,
        focusedBorder:
            border.copyWith(borderSide: BorderSide(color: accent, width: 2)),
        suffixIconColor: muted,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: fg,
        selectionColor: accent.withValues(alpha: 0.35),
        selectionHandleColor: accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: fg.withValues(alpha: 0.12),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: fg.withValues(alpha: 0.06),
        selectedColor: accent.withValues(alpha: 0.35),
        labelStyle: TextStyle(color: fg),
        secondaryLabelStyle: TextStyle(color: fg),
        checkmarkColor: fg,
        side: BorderSide(color: fg.withValues(alpha: 0.3)),
      ),
    );
  }

  /// [child] ni shu ranglar bilan o'raydi.
  Widget wrap(Widget child) => Theme(
        data: theme,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: IconTheme.merge(data: IconThemeData(color: fg), child: child),
        ),
      );
}
