// Kaftpay: mijozni ro'yxatdan o'tkazish (kaftni kartasiga bog'lash).
//
// 1. Mijoz Kaftpay ilovasida QR ko'rsatadi (`PPENROLL:<uuid>`, ~120 s).
// 2. Kassir uni ODDIY barcode skaner bilan o'qiydi (HID — maydonga yozadi va
//    Enter bosadi; foydalanuvchi qarori 2026-10-30) yoki qo'lda kiritadi.
// 3. Kassir qo'lni tanlaydi (chap / o'ng — majburiy, server `UNSPECIFIED` da
//    adashtiruvchi `1104` beradi).
// 4. Mijoz kaftini VP930 ga qo'yadi → `/enroll`.

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';

enum _EnrollStep { qr, scanning, sending, done, failed }

class KaftpayEnrollDialog extends StatefulWidget {
  const KaftpayEnrollDialog({
    super.key,
    required this.api,
    required this.scanner,
    this.uz = true,
  });

  final KaftpayApi api;
  final KaftpayScanner scanner;
  final bool uz;

  static Future<void> show(
    BuildContext context, {
    required KaftpayApi api,
    required KaftpayScanner scanner,
    bool uz = true,
  }) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => KaftpayEnrollDialog(api: api, scanner: scanner, uz: uz),
      );

  /// QR matni: bo'sh joysiz; `PPENROLL:` bilan yoki faqat UUID (server
  /// prefiksni o'zi olib tashlaydi).
  static bool looksLikeQr(String v) {
    final s = v.trim();
    final id = s.toUpperCase().startsWith('PPENROLL:') ? s.substring(9) : s;
    return RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(id);
  }

  @override
  State<KaftpayEnrollDialog> createState() => _KaftpayEnrollDialogState();
}

class _KaftpayEnrollDialogState extends State<KaftpayEnrollDialog> {
  final _qr = TextEditingController();
  final _qrFocus = FocusNode();
  KaftpayHand? _hand;
  _EnrollStep _step = _EnrollStep.qr;
  String _message = '';
  bool _closed = false;

  String t(String uz, String ru) => widget.uz ? uz : ru;

  bool get _canStart =>
      KaftpayEnrollDialog.looksLikeQr(_qr.text) && _hand != null;

  @override
  void dispose() {
    if (_step == _EnrollStep.scanning) widget.scanner.cancel();
    _qr.dispose();
    _qrFocus.dispose();
    super.dispose();
  }

  void _set(_EnrollStep s, String m) {
    if (!mounted || _closed) return;
    setState(() {
      _step = s;
      _message = m;
    });
  }

  Future<void> _start() async {
    if (!_canStart) return;
    _set(
        _EnrollStep.scanning,
        t('Mijoz kaftini skanerga qo\'ysin',
            'Клиент прикладывает ладонь к сканеру'));
    final KaftpayPalmScan raw;
    try {
      raw = await widget.scanner.capture(onStage: (_, m) {
        if (_step == _EnrollStep.scanning) _set(_step, m);
      });
    } on KaftpayScannerException catch (e) {
      if (e.cancelled) return;
      _set(_EnrollStep.failed, e.message);
      return;
    }
    if (!mounted || _closed) return;
    _set(_EnrollStep.sending, t('Yuborilmoqda...', 'Отправка...'));
    // Qo'l — kassir tanlagani (SDK `palm_type` emas: kodlanishi tasdiqlanmagan).
    final scan = KaftpayPalmScan(ir: raw.ir, rgb: raw.rgb, hand: _hand!);
    final res = await widget.api.enroll(qrSessionId: _qr.text, scan: scan);
    final data = res.data;
    if (data != null) {
      _set(
          _EnrollStep.done,
          t('Kaft ro\'yxatdan o\'tdi. Endi mijoz kaft bilan to\'lay oladi.',
              'Ладонь зарегистрирована. Клиент может платить ладонью.'));
    } else {
      _set(_EnrollStep.failed, res.error!.message);
    }
  }

  void _retry() {
    _qr.clear();
    _set(_EnrollStep.qr, '');
    _qrFocus.requestFocus();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    if (_step == _EnrollStep.scanning) widget.scanner.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(t('Kaftpay: mijozni ro\'yxatdan o\'tkazish',
            'Kaftpay: регистрация клиента')),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 420, maxWidth: 520),
          child: SingleChildScrollView(child: _body(theme)),
        ),
        actions: _actions(),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    switch (_step) {
      case _EnrollStep.qr:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t(
                '1. Mijoz Kaftpay ilovasida QR kodni ochsin va uni barcode '
                    'skaner bilan o\'qing (yoki kodni kiriting).',
                '1. Клиент открывает QR в приложении Kaftpay — отсканируйте '
                    'его сканером штрихкодов (или введите код).')),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('kaftpay_enroll_qr'),
              controller: _qr,
              focusNode: _qrFocus,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => setState(() {}),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'PPENROLL:...',
                suffixIcon: KaftpayEnrollDialog.looksLikeQr(_qr.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(t('2. Qaysi qo\'l?', '2. Какая рука?')),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final h in const [KaftpayHand.left, KaftpayHand.right])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        key: ValueKey('kaftpay_enroll_${h.wire}'),
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            h == KaftpayHand.left
                                ? t('Chap qo\'l', 'Левая')
                                : t('O\'ng qo\'l', 'Правая'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        selected: _hand == h,
                        onSelected: (_) => setState(() => _hand = h),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t('QR ~2 daqiqa amal qiladi — muddati o\'tsa, mijoz yangisini ochsin.',
                  'QR действует ~2 минуты — если истёк, клиент открывает новый.'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      case _EnrollStep.scanning:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.back_hand_outlined, size: 64, color: theme.primaryColor),
            const SizedBox(height: 12),
            Text(_message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        );
      case _EnrollStep.sending:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(_message),
          ],
        );
      case _EnrollStep.done:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text(_message,
                key: const ValueKey('kaftpay_enroll_message'),
                textAlign: TextAlign.center),
          ],
        );
      case _EnrollStep.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(_message,
                key: const ValueKey('kaftpay_enroll_message'),
                textAlign: TextAlign.center),
          ],
        );
    }
  }

  List<Widget> _actions() {
    final close = TextButton(
      key: const ValueKey('kaftpay_enroll_close'),
      onPressed: _close,
      child: Text(_step == _EnrollStep.done
          ? t('Yopish', 'Закрыть')
          : t('Bekor qilish', 'Отмена')),
    );
    switch (_step) {
      case _EnrollStep.qr:
        return [
          close,
          ElevatedButton(
            key: const ValueKey('kaftpay_enroll_start'),
            onPressed: _canStart ? _start : null,
            child: Text(t('Kaftni skanerlash', 'Сканировать ладонь')),
          ),
        ];
      case _EnrollStep.scanning:
        return [close];
      case _EnrollStep.sending:
        return const [];
      case _EnrollStep.done:
        return [
          TextButton(
            onPressed: _retry,
            child: Text(t('Yana bir mijoz / qo\'l', 'Ещё клиент / рука')),
          ),
          close,
        ];
      case _EnrollStep.failed:
        return [
          close,
          ElevatedButton(
            key: const ValueKey('kaftpay_enroll_retry'),
            onPressed: _retry,
            child: Text(t('Qaytadan', 'Заново')),
          ),
        ];
    }
  }
}
