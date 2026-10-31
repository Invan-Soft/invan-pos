// Kaftpay: mijozni ro'yxatdan o'tkazish (kaftni kartasiga bog'lash).
//
// 1. Mijoz Kaftpay ilovasida QR ko'rsatadi (`PPENROLL:<uuid>`, ~120 s).
// 2. Kassir uni ODDIY barcode skaner bilan o'qiydi (HID — maydonga yozadi va
//    Enter bosadi; foydalanuvchi qarori 2026-10-30) yoki qo'lda kiritadi.
//    Oyna ochiq turganda global skaner tinglovchisi (`BlBloc`) o'chiriladi —
//    aks holda QR mahsulot deb qidirilib "mahsulot topilmadi" chiqardi.
// 3. Kassir qo'lni tanlaydi (chap / o'ng — majburiy, server `UNSPECIFIED` da
//    adashtiruvchi `1104` beradi). QR'da qo'l YO'Q — qo'l faqat shu tanlovdan.
// 4. Mijoz kaftini VP930 ga qo'yadi → `/enroll`.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/domain/barcode/keyboard_layout.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
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

  /// Skaner yozgan matn: Windows klaviaturasi ruscha bo'lsa HID skaner
  /// `PPENROLL:` o'rniga `ЗЗУТКЩДД` yozadi — mahsulot skani kabi tuzatiladi.
  static String normalizeQr(String v) => KeyboardLayout.ruLettersToEn(v.trim());

  /// QR matni: bo'sh joysiz; `PPENROLL:` bilan yoki faqat UUID (server
  /// prefiksni o'zi olib tashlaydi).
  static bool looksLikeQr(String v) {
    final s = normalizeQr(v);
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
  BlBloc? _bl;
  BLStatus? _blBefore;

  String t(String uz, String ru) => widget.uz ? uz : ru;

  @override
  void initState() {
    super.initState();
    KaftpayLang.uz = widget.uz;
    _muteBarcodeListener();
  }

  /// QR skani faqat shu maydonga tushsin (vozvratdagi KM skan oynasi kabi);
  /// yopilganda oldingi holat qaytariladi.
  void _muteBarcodeListener() {
    try {
      _bl = BlocProvider.of<BlBloc>(context, listen: false);
    } catch (_) {
      return; // testlar / sozlamalar BlBloc'siz
    }
    _blBefore = _bl!.status;
    _bl!.add(BlStatusChangedEvent(
        status: BLStatus.other, where: 'kaftpay_enroll_dialog initState'));
  }

  bool get _canStart =>
      KaftpayEnrollDialog.looksLikeQr(_qr.text) && _hand != null;

  @override
  void dispose() {
    if (_step == _EnrollStep.scanning) widget.scanner.cancel();
    if (_bl != null && _blBefore != null) {
      _bl!.add(BlStatusChangedEvent(
          status: _blBefore!, where: 'kaftpay_enroll_dialog dispose'));
    }
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
    _set(_EnrollStep.scanning,
        t('Kaftni skanerga qo\'ying', 'Приложите ладонь к сканеру'));
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
    final res = await widget.api.enroll(
        qrSessionId: KaftpayEnrollDialog.normalizeQr(_qr.text), scan: scan);
    final data = res.data;
    if (data != null) {
      _set(_EnrollStep.done,
          t('Kaft ro\'yxatdan o\'tdi', 'Ладонь зарегистрирована'));
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
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Row(
          children: [
            KaftpayIconBadge(Icons.person_add_alt_1_outlined,
                color: ui.accent, size: 48),
            const SizedBox(width: 14),
            Expanded(
                child: Text(t(
                    'Mijozni ro\'yxatdan o\'tkazish', 'Регистрация клиента'))),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 580, maxWidth: 680),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _body(),
                const SizedBox(height: 22),
                _buttons(),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _stepTitle(int n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: ui.accent, shape: BoxShape.circle),
              child: Text('$n',
                  style: TextStyle(
                      color: ui.onAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _state(IconData icon, Color color,
          {bool progress = false, String? hint}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KaftpayIconBadge(icon, color: color, size: 96),
            const SizedBox(height: 18),
            Text(_message,
                key: const ValueKey('kaftpay_enroll_message'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ui.muted, fontSize: 16)),
            ],
            if (progress) ...[
              const SizedBox(height: 20),
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
            _stepTitle(1, t('QR\'ni skanerlang', 'Отсканируйте QR')),
            TextField(
              key: const ValueKey('kaftpay_enroll_qr'),
              controller: _qr,
              focusNode: _qrFocus,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'PPENROLL:…',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                prefixIcon: const Icon(Icons.qr_code_scanner, size: 26),
                suffixIcon: qrOk
                    ? Icon(Icons.check_circle, color: ui.success, size: 28)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            _stepTitle(2, t('Qaysi qo\'l?', 'Какая рука?')),
            Row(
              children: [
                Expanded(
                  child: KaftpayChoiceCard(
                    key: const ValueKey('kaftpay_enroll_LEFT'),
                    icon: Icons.back_hand_outlined,
                    mirrorIcon: true,
                    large: true,
                    title: t('Chap', 'Левая'),
                    selected: _hand == KaftpayHand.left,
                    onTap: () => setState(() => _hand = KaftpayHand.left),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: KaftpayChoiceCard(
                    key: const ValueKey('kaftpay_enroll_RIGHT'),
                    icon: Icons.back_hand_outlined,
                    large: true,
                    title: t('O\'ng', 'Правая'),
                    selected: _hand == KaftpayHand.right,
                    onTap: () => setState(() => _hand = KaftpayHand.right),
                  ),
                ),
              ],
            ),
          ],
        );
      case _EnrollStep.scanning:
        return _state(Icons.back_hand_outlined, ui.accent,
            progress: true,
            hint: t('Chiroq yashil bo\'lsa — qimirlamang',
                'Свет зелёный — не двигайте'));
      case _EnrollStep.sending:
        return _state(Icons.cloud_upload_outlined, ui.accent, progress: true);
      case _EnrollStep.done:
        return _state(Icons.check_rounded, ui.success,
            hint: t('Mijoz endi kaft bilan to\'lay oladi',
                'Клиент может платить ладонью'));
      case _EnrollStep.failed:
        return _state(Icons.error_outline, ui.error);
    }
  }

  Widget _buttons() {
    const gap = SizedBox(height: 18);
    final cancel = OutlinedButton.icon(
      key: const ValueKey('kaftpay_enroll_close'),
      style: ui.big(
          ui.secondaryButton.copyWith(
            foregroundColor: WidgetStatePropertyAll(ui.error),
            side: WidgetStatePropertyAll(
                BorderSide(color: ui.error.withValues(alpha: 0.7), width: 1.5)),
          ),
          height: 64,
          font: 19),
      onPressed: _close,
      icon: const Icon(Icons.close_rounded),
      label: Text(t('Bekor qilish', 'Отмена')),
    );
    switch (_step) {
      case _EnrollStep.qr:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const ValueKey('kaftpay_enroll_start'),
              style: ui.big(ui.primaryButton, height: 76, font: 22),
              onPressed: _canStart ? _start : null,
              icon: const Icon(Icons.back_hand_outlined),
              label: Text(t('Kaftni skanerlash', 'Сканировать ладонь')),
            ),
            gap,
            cancel,
          ],
        );
      case _EnrollStep.scanning:
        return cancel;
      case _EnrollStep.sending:
        return const SizedBox.shrink();
      case _EnrollStep.done:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('kaftpay_enroll_next'),
                style: ui.big(ui.secondaryButton, height: 68, font: 19),
                onPressed: _retry,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(t('Yana mijoz', 'Ещё клиент')),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('kaftpay_enroll_done'),
                style: ui.big(
                    ui.primaryButton.copyWith(
                        backgroundColor: WidgetStatePropertyAll(ui.success)),
                    height: 68,
                    font: 19),
                onPressed: _close,
                icon: const Icon(Icons.check_rounded),
                label: Text(t('Tayyor', 'Готово')),
              ),
            ),
          ],
        );
      case _EnrollStep.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const ValueKey('kaftpay_enroll_retry'),
              style: ui.big(ui.primaryButton, height: 72, font: 21),
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t('Qaytadan', 'Заново')),
            ),
            gap,
            cancel,
          ],
        );
    }
  }
}
