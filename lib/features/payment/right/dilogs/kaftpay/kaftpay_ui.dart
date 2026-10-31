// Kaftpay oynalari va sozlama sahifasi uchun dizayn tizimi: ranglar, mavzu,
// tugma uslublari va kichik komponentlar.
//
// Ilova temasida (`lib/utils/themes.dart`) matn rangi `textTheme` da qora,
// `colorScheme` ning hamma ranglari esa #101920 — tungi temada standart
// Material vidjetlari fon bilan qo'shilib ko'rinmay qoladi. Boshqa sahifalar
// matnga `canvasColor` ni qo'lda beradi (tungi — och, kunduzgi — to'q); bu
// yerda shu rang asosida bitta mavzu.

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

  static const double radius = 12;

  Color get muted => fg.withValues(alpha: 0.62);
  Color get faint => fg.withValues(alpha: 0.38);
  Color get bg => dark ? const Color(0xff1B2632) : Colors.white;
  Color get card => dark ? const Color(0xff17212B) : const Color(0xffF6F8FA);
  Color get border => fg.withValues(alpha: dark ? 0.12 : 0.14);
  Color get accent => dark ? const Color(0xff5B9CF6) : const Color(0xff2563EB);
  Color get onAccent => Colors.white;
  Color get success => dark ? const Color(0xff4ADE80) : const Color(0xff16A34A);
  Color get warning => dark ? const Color(0xffFBBF24) : const Color(0xffD97706);
  Color get error => dark ? const Color(0xffF87171) : const Color(0xffDC2626);

  /// Rangli fon (pill, banner, ikonka doirasi).
  Color tint(Color c) => c.withValues(alpha: dark ? 0.16 : 0.12);

  static const EdgeInsets _buttonPadding =
      EdgeInsets.symmetric(horizontal: 18, vertical: 14);
  static final RoundedRectangleBorder _buttonShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

  /// Temadagi shrift (Inter) bilan — `TextStyle` ning o'zi berilsa tugma
  /// matni shriftni meros olmaydi.
  TextStyle get _buttonText => (base.textTheme.labelLarge ?? const TextStyle())
      .copyWith(fontSize: 15, fontWeight: FontWeight.w600);

  /// Asosiy amal (to'lash, saqlash, skanerlash).
  ButtonStyle get primaryButton => FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        disabledBackgroundColor: fg.withValues(alpha: 0.10),
        disabledForegroundColor: faint,
        padding: _buttonPadding,
        shape: _buttonShape,
        textStyle: _buttonText,
        elevation: 0,
      );

  /// Ikkinchi darajali amal (qayta skan, tekshirish).
  ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
        foregroundColor: fg,
        disabledForegroundColor: faint,
        side: BorderSide(color: fg.withValues(alpha: 0.28)),
        padding: _buttonPadding,
        shape: _buttonShape,
        textStyle: _buttonText,
      );

  /// Bekor qilish / yopish.
  ButtonStyle get quietButton => TextButton.styleFrom(
        foregroundColor: muted,
        padding: _buttonPadding,
        shape: _buttonShape,
        textStyle: _buttonText,
      );

  /// Kassir uchun katta tugma (sensorli ekran, tez bosish): balandlik
  /// [height], yirik yozuv.
  ButtonStyle big(ButtonStyle base, {double height = 58, double font = 18}) =>
      base.copyWith(
        minimumSize: WidgetStatePropertyAll(Size.fromHeight(height)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        textStyle: WidgetStatePropertyAll(
            _buttonText.copyWith(fontSize: font, fontWeight: FontWeight.w700)),
        iconSize: WidgetStatePropertyAll(font + 6),
      );

  ThemeData get theme {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: fg.withValues(alpha: 0.22)),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: fg, displayColor: fg),
      colorScheme: base.colorScheme.copyWith(
        onSurface: fg,
        onSurfaceVariant: muted,
      ),
      iconTheme: base.iconTheme.copyWith(color: fg),
      cardTheme: base.cardTheme.copyWith(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(textColor: fg, iconColor: fg),
      dividerTheme: base.dividerTheme.copyWith(color: border, thickness: 1),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: (base.textTheme.titleLarge ?? const TextStyle())
            .copyWith(color: fg, fontSize: 20, fontWeight: FontWeight.w700),
        contentTextStyle: (base.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: fg, fontSize: 15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fg.withValues(alpha: 0.04),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(color: accent),
        hintStyle: TextStyle(color: faint),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: accent, width: 2)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: fg,
        selectionColor: accent.withValues(alpha: 0.35),
        selectionHandleColor: accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: fg.withValues(alpha: 0.10),
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButton),
      textButtonTheme: TextButtonThemeData(style: quietButton),
    );
  }

  /// [child] ni shu mavzu bilan o'raydi.
  Widget wrap(Widget child) => Theme(
        data: theme,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: IconTheme.merge(data: IconThemeData(color: fg), child: child),
        ),
      );
}

/// Kichik holat belgisi: `● Matn`.
class KaftpayPill extends StatelessWidget {
  const KaftpayPill(this.text,
      {super.key, required this.color, this.icon, this.dense = false});

  final String text;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: ui.tint(color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: dense ? 13 : 15, color: color)
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          SizedBox(width: dense ? 5 : 6),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color,
                    fontSize: dense ? 12 : 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Rangli doira ichidagi ikonka.
class KaftpayIconBadge extends StatelessWidget {
  const KaftpayIconBadge(this.icon,
      {super.key, required this.color, this.size = 44, this.mirror = false});

  final IconData icon;
  final Color color;
  final double size;

  /// Chap qo'l uchun (ikonka o'ng qo'l).
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    Widget i = Icon(icon, size: size * 0.52, color: color);
    if (mirror) {
      i = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1, 1, 1),
        child: i,
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: ui.tint(color), shape: BoxShape.circle),
      child: i,
    );
  }
}

/// Natija / ogohlantirish bloki.
class KaftpayBanner extends StatelessWidget {
  const KaftpayBanner(
      {super.key, required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: ui.tint(color),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: ui.fg, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// Katta tanlov kartasi (chap / o'ng qo'l, amal plitkasi).
class KaftpayChoiceCard extends StatelessWidget {
  const KaftpayChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.mirrorIcon = false,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool mirrorIcon;
  final VoidCallback? onTap;

  /// Ikonka rangi (sukut — accent).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    final c = color ?? ui.accent;
    return Material(
      color: selected ? ui.tint(ui.accent) : ui.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? ui.accent : ui.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              KaftpayIconBadge(icon, color: c, mirror: mirrorIcon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: ui.fg,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: TextStyle(color: ui.muted, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: ui.accent, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
