// Kaftpay'ga kirish PIN'i — oyna (2026-11-02, foydalanuvchi: alohida sahifa
// emas). Qoida Sozlamalardagi to'lov bo'limlari bilan bir xil
// (`SettingsBloc.pinAllowed`: smena ochish huquqi bor xodim). `true` — PIN
// to'g'ri.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_ui.dart';
import 'package:invan2/features/settings/bloc/settings_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class KaftpayPinDialog extends StatefulWidget {
  const KaftpayPinDialog({super.key, this.uz = true, this.check});

  final bool uz;

  /// Testda; sukut — `SettingsBloc.pinAllowed`.
  final bool Function(String pin)? check;

  static Future<bool> show(BuildContext context,
          {bool uz = true, bool Function(String pin)? check}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => KaftpayPinDialog(uz: uz, check: check),
      ).then((v) => v == true);

  @override
  State<KaftpayPinDialog> createState() => _KaftpayPinDialogState();
}

class _KaftpayPinDialogState extends State<KaftpayPinDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _wrong = false;

  String t(String uz, String ru) => widget.uz ? uz : ru;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _completed(String pin) {
    final ok = (widget.check ?? SettingsBloc.pinAllowed)(pin);
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _wrong = true);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    return ui.wrap(AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Row(
        children: [
          KaftpayIconBadge(Icons.lock_outline, color: ui.accent, size: 48),
          const SizedBox(width: 14),
          const Expanded(child: Text('Kaftpay')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _wrong
                  ? t('Noto\'g\'ri PIN — qayta kiriting',
                      'Неверный PIN — введите снова')
                  : t('PIN kodni kiriting', 'Введите PIN-код'),
              key: const ValueKey('kaftpay_pin_label'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _wrong ? ui.error : ui.fg,
                  fontSize: 19,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            Center(
              child: SizedBox(
                width: 280,
                child: PinCodeTextField(
                  key: const ValueKey('kaftpay_pin_field'),
                  appContext: context,
                  length: 4,
                  controller: _controller,
                  focusNode: _focus,
                  autoFocus: true,
                  autoDisposeControllers: false,
                  obscureText: true,
                  obscuringCharacter: '*',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  cursorColor: Colors.transparent,
                  textStyle: TextStyle(
                      color: ui.fg, fontSize: 22, fontWeight: FontWeight.w700),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 60,
                    fieldWidth: 56,
                    borderWidth: 2,
                    activeColor: _wrong ? ui.error : ui.accent,
                    selectedColor: ui.accent,
                    inactiveColor: _wrong ? ui.error : ui.border,
                  ),
                  // Xato yozuvi yangi raqam terilganda ketadi (maydonni
                  // tozalashning o'zi uni o'chirmasin).
                  onChanged: (v) {
                    if (_wrong && v.isNotEmpty) setState(() => _wrong = false);
                  },
                  onCompleted: _completed,
                ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              key: const ValueKey('kaftpay_pin_cancel'),
              style: ui.big(ui.secondaryButton, height: 56, font: 18),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t('Bekor qilish', 'Отмена')),
            ),
          ],
        ),
      ),
    ));
  }
}
