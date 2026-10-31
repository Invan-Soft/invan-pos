// Kaftpay to'lov oynasi — `KaftpayCheckout` holatini chizadi.
//
// Natija: pul yechilsa `KaftpayChargeOutcome` (charged), aks holda null.
// Noma'lum natijada oyna "Keyinroq" bilan yopilishi mumkin — to'lov jurnalda
// qoladi (Sozlamalar → Kaftpay → "Holatni tekshirish"), summa chekka
// YOZILMAYDI.

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_checkout.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_ui.dart';
import 'package:invan2/utils/helpers/money_formatter.dart';

class KaftpayPayDialog extends StatefulWidget {
  const KaftpayPayDialog({super.key, required this.checkout, this.uz = true});

  final KaftpayCheckout checkout;

  /// Statik matnlar tili (o'zbek / rus). Server va xato matnlari o'zbekcha.
  final bool uz;

  static Future<KaftpayChargeOutcome?> show(
    BuildContext context, {
    required KaftpayCheckout checkout,
    bool uz = true,
  }) =>
      showDialog<KaftpayChargeOutcome>(
        context: context,
        barrierDismissible: false,
        builder: (_) => KaftpayPayDialog(checkout: checkout, uz: uz),
      );

  @override
  State<KaftpayPayDialog> createState() => _KaftpayPayDialogState();
}

class _KaftpayPayDialogState extends State<KaftpayPayDialog> {
  KaftpayCheckout get c => widget.checkout;
  bool _closed = false;
  late KaftpayUi ui;

  String t(String uz, String ru) => widget.uz ? uz : ru;

  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
    c.start();
  }

  void _changed() {
    if (!mounted || _closed) return;
    if (c.step == KaftpayCheckoutStep.charged) {
      _close(c.outcome);
      return;
    }
    setState(() {});
  }

  void _close([KaftpayChargeOutcome? result]) {
    if (_closed) return;
    _closed = true;
    c.cancel();
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    c.dispose();
    super.dispose();
  }

  String _money(int tiyin) =>
      MoneyFormatter.formatter.format(KaftpayMoney.toSom(tiyin));

  @override
  Widget build(BuildContext context) {
    ui = KaftpayUi.of(context);
    final theme = ui.theme;
    return ui.wrap(PopScope(
      canPop: false,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Icon(Icons.back_hand_outlined, color: ui.accent),
            const SizedBox(width: 10),
            const Expanded(child: Text('Kaftpay')),
            Text('${_money(c.amount)} ${t("so'm", 'сум')}',
                key: const ValueKey('kaftpay_amount'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 420, maxWidth: 520),
          child: SingleChildScrollView(child: _body(theme)),
        ),
        actions: _actions(),
      ),
    ));
  }

  Widget _status(IconData? icon, Color color, {bool spinner = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (spinner)
          const SizedBox(
              width: 56, height: 56, child: CircularProgressIndicator())
        else
          Icon(icon, size: 64, color: color),
        const SizedBox(height: 16),
        Text(
          c.message,
          key: const ValueKey('kaftpay_message'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _body(ThemeData theme) {
    switch (c.step) {
      case KaftpayCheckoutStep.scanning:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _status(Icons.back_hand_outlined, ui.accent),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        );
      case KaftpayCheckoutStep.identifying:
      case KaftpayCheckoutStep.charging:
      case KaftpayCheckoutStep.charged:
        return _status(null, ui.accent, spinner: true);
      case KaftpayCheckoutStep.noMatch:
        return _status(Icons.person_search_outlined, ui.warning);
      case KaftpayCheckoutStep.failed:
        return _status(Icons.error_outline, ui.error);
      case KaftpayCheckoutStep.unknown:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _status(Icons.help_outline, ui.warning),
            const SizedBox(height: 12),
            Text(
              t(
                  'Pul yechilgan bo\'lishi mumkin. Mijozdan boshqa usulda '
                      'to\'lov OLMANG — avval holatni tekshiring.',
                  'Деньги могли быть списаны. НЕ принимайте оплату другим '
                      'способом — сначала проверьте статус.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: ui.error),
            ),
          ],
        );
      case KaftpayCheckoutStep.choosing:
        return _choosing(theme);
    }
  }

  Widget _choosing(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(c.message,
            key: const ValueKey('kaftpay_message'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final cand in c.candidates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: cand.consumerGuid == c.selectedGuid
                  ? ui.accent.withValues(alpha: 0.12)
                  : ui.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: cand.consumerGuid == c.selectedGuid
                      ? ui.accent
                      : ui.fg.withValues(alpha: 0.3),
                  width: cand.consumerGuid == c.selectedGuid ? 2 : 1,
                ),
              ),
              child: InkWell(
                key: ValueKey('kaftpay_cand_${cand.consumerGuid}'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => c.select(cand.consumerGuid),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        cand.consumerGuid == c.selectedGuid
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: ui.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cand.displayName ??
                              t('Ism ko\'rsatilmagan', 'Имя не указано'),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (cand.phoneLast4 != null)
                        Text('*** ${cand.phoneLast4}',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (c.isExpired)
          Text(
            t('Aniqlash muddati tugadi — kaftni qayta skanerlang',
                'Время истекло — отсканируйте ладонь заново'),
            style: TextStyle(color: ui.error),
          ),
      ],
    );
  }

  List<Widget> _actions() {
    final cancel = TextButton(
      key: const ValueKey('kaftpay_cancel'),
      onPressed: () => _close(),
      child: Text(t('Bekor qilish', 'Отмена')),
    );
    final rescan = TextButton(
      key: const ValueKey('kaftpay_rescan'),
      onPressed: () => c.start(),
      child: Text(t('Qayta skanerlash', 'Сканировать заново')),
    );
    switch (c.step) {
      case KaftpayCheckoutStep.scanning:
        return [cancel];
      case KaftpayCheckoutStep.identifying:
      case KaftpayCheckoutStep.charging:
      case KaftpayCheckoutStep.charged:
        return const [];
      case KaftpayCheckoutStep.noMatch:
      case KaftpayCheckoutStep.failed:
        return [cancel, rescan];
      case KaftpayCheckoutStep.choosing:
        return [
          cancel,
          rescan,
          ElevatedButton(
            key: const ValueKey('kaftpay_pay'),
            onPressed: c.canPay ? () => c.pay() : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text('${t("To'lash", 'Оплатить')} ${_money(c.amount)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ];
      case KaftpayCheckoutStep.unknown:
        return [
          TextButton(
            key: const ValueKey('kaftpay_later'),
            onPressed: () => _close(),
            child: Text(t('Keyinroq tekshirish', 'Проверить позже')),
          ),
          ElevatedButton(
            key: const ValueKey('kaftpay_check'),
            onPressed: () => c.checkStatus(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(t('Holatni tekshirish', 'Проверить статус'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ];
    }
  }
}
