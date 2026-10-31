// Kaftpay: mijozni ro'yxatdan o'tkazish (kaftni kartasiga bog'lash).
//
// 1. Mijoz Kaftpay ilovasida QR ko'rsatadi (`PPENROLL:<uuid>`, ~120 s).
// 2. Kassir uni ODDIY barcode skaner bilan o'qiydi (HID — maydonga yozadi va
//    Enter bosadi; foydalanuvchi qarori 2026-10-30) yoki qo'lda kiritadi.
// 3. Kassir qo'lni tanlaydi (chap / o'ng — majburiy, server `UNSPECIFIED` da
//    adashtiruvchi `1104` beradi).
// 4. Mijoz kaftini VP930 ga qo'yadi → `/enroll`.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_ui.dart';

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
  late KaftpayUi ui;

  String t(String uz, String ru) => widget.uz ? uz : ru;

  @override
  void initState() {
    super.initState();
    KaftpayLang.uz = widget.uz;
  }

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
    if (kDebugMode) debugPrint('[Kaftpay enroll] ${s.name}: $m');
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
    ui = KaftpayUi.of(context);
    return ui.wrap(PopScope(
      canPop: false,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Row(
          children: [
            KaftpayIconBadge(Icons.person_add_alt_1_outlined,
                color: ui.accent, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t(
                      'Mijozni ro\'yxatdan o\'tkazish', 'Регистрация клиента')),
                  Text(
                      t('Kaftni Kaftpay kartasiga bog\'lash',
                          'Привязка ладони к карте Kaftpay'),
                      style: TextStyle(
                          color: ui.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 460, maxWidth: 540),
          child: SingleChildScrollView(child: _body()),
        ),
        actions: _actions(),
      ),
    ));
  }

  Widget _stepTitle(int n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: ui.accent, shape: BoxShape.circle),
              child: Text('$n',
                  style: TextStyle(
                      color: ui.onAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _state(IconData icon, Color color, {bool progress = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KaftpayIconBadge(icon, color: color, size: 84),
            const SizedBox(height: 16),
            Text(_message,
                key: const ValueKey('kaftpay_enroll_message'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (progress) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(minHeight: 6),
              ),
            ],
          ],
        ),
      );

  Widget _body() {
    switch (_step) {
      case _EnrollStep.qr:
        final qrOk = KaftpayEnrollDialog.looksLikeQr(_qr.text);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepTitle(
                1,
                t('Mijoz ilovadagi QR\'ni ko\'rsatadi — barcode skaner bilan o\'qing',
                    'Клиент показывает QR из приложения — считайте сканером')),
            TextField(
              key: const ValueKey('kaftpay_enroll_qr'),
              controller: _qr,
              focusNode: _qrFocus,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'PPENROLL:…',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                suffixIcon:
                    qrOk ? Icon(Icons.check_circle, color: ui.success) : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t('QR ~2 daqiqa amal qiladi — muddati o\'tsa, mijoz yangisini ochsin.',
                  'QR действует ~2 минуты — если истёк, клиент открывает новый.'),
              style: TextStyle(color: ui.faint, fontSize: 12),
            ),
            const SizedBox(height: 20),
            _stepTitle(2, t('Qaysi qo\'l?', 'Какая рука?')),
            Row(
              children: [
                Expanded(
                  child: KaftpayChoiceCard(
                    key: const ValueKey('kaftpay_enroll_LEFT'),
                    icon: Icons.back_hand_outlined,
                    mirrorIcon: true,
                    title: t('Chap qo\'l', 'Левая'),
                    selected: _hand == KaftpayHand.left,
                    onTap: () => setState(() => _hand = KaftpayHand.left),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KaftpayChoiceCard(
                    key: const ValueKey('kaftpay_enroll_RIGHT'),
                    icon: Icons.back_hand_outlined,
                    title: t('O\'ng qo\'l', 'Правая'),
                    selected: _hand == KaftpayHand.right,
                    onTap: () => setState(() => _hand = KaftpayHand.right),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _stepTitle(
                3,
                t('Kaftni skanerga yaqinlashtiring — chiroq yashil bo\'lganda qimirlamang',
                    'Поднесите ладонь — когда свет станет зелёным, не двигайте')),
          ],
        );
      case _EnrollStep.scanning:
        return _state(Icons.back_hand_outlined, ui.accent, progress: true);
      case _EnrollStep.sending:
        return _state(Icons.cloud_upload_outlined, ui.accent, progress: true);
      case _EnrollStep.done:
        return _state(Icons.check_rounded, ui.success);
      case _EnrollStep.failed:
        return _state(Icons.error_outline, ui.error);
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
          FilledButton.icon(
            key: const ValueKey('kaftpay_enroll_start'),
            onPressed: _canStart ? _start : null,
            icon: const Icon(Icons.back_hand_outlined, size: 20),
            label: Text(t('Kaftni skanerlash', 'Сканировать ладонь')),
          ),
        ];
      case _EnrollStep.scanning:
        return [close];
      case _EnrollStep.sending:
        return const [];
      case _EnrollStep.done:
        return [
          OutlinedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
            label: Text(t('Yana bir mijoz', 'Ещё клиент')),
          ),
          FilledButton(
            onPressed: _close,
            child: Text(t('Tayyor', 'Готово')),
          ),
        ];
      case _EnrollStep.failed:
        return [
          close,
          FilledButton.icon(
            key: const ValueKey('kaftpay_enroll_retry'),
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(t('Qaytadan', 'Заново')),
          ),
        ];
    }
  }
}
