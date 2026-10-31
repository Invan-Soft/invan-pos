// Kaftpay to'lov oynasi — `KaftpayCheckout` holatini chizadi.
//
// Natija: pul yechilsa `KaftpayChargeOutcome` (charged), aks holda null.
// Noma'lum natijada oyna "Keyinroq" bilan yopilishi mumkin — to'lov jurnalda
// qoladi (Sozlamalar → Kaftpay → "Holatni tekshirish"), summa chekka
// YOZILMAYDI.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_checkout.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_action_dialog.dart';
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
    KaftpayLang.uz = widget.uz;
    c.addListener(_changed);
    c.start();
  }

  /// To'lov o'tgach natija ekrani shuncha turib, o'zi yopiladi.
  static const Duration successHold = Duration(seconds: 3);
  Timer? _autoClose;

  void _changed() {
    if (!mounted || _closed) return;
    if (c.step == KaftpayCheckoutStep.charged) {
      _autoClose ??= Timer(successHold, () => _close(c.outcome));
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
    _autoClose?.cancel();
    c.removeListener(_changed);
    c.dispose();
    super.dispose();
  }

  String _money(int tiyin) =>
      MoneyFormatter.formatter.format(KaftpayMoney.toSom(tiyin));

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
            KaftpayIconBadge(Icons.back_hand_outlined,
                color: ui.accent, size: 40),
            const SizedBox(width: 12),
            const Expanded(child: Text('Kaftpay')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ui.tint(ui.accent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_money(c.amount)} ${t("so'm", 'сум')}',
                  key: const ValueKey('kaftpay_amount'),
                  style: TextStyle(
                      color: ui.fg, fontSize: 18, fontWeight: FontWeight.w800)),
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

  Widget _status(IconData icon, Color color, {bool progress = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KaftpayIconBadge(icon, color: color, size: 84),
          const SizedBox(height: 16),
          Text(
            c.message,
            key: const ValueKey('kaftpay_message'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
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
  }

  Widget _body() {
    switch (c.step) {
      case KaftpayCheckoutStep.scanning:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _status(Icons.back_hand_outlined, ui.accent, progress: true),
            Text(
              t('Kaftni ochiq va tekis tuting, chiroq yashil bo\'lganda qimirlamang',
                  'Держите ладонь открытой и ровно, при зелёном свете не двигайте'),
              textAlign: TextAlign.center,
              style: TextStyle(color: ui.muted, fontSize: 13),
            ),
          ],
        );
      case KaftpayCheckoutStep.identifying:
        return _status(Icons.manage_search, ui.accent, progress: true);
      case KaftpayCheckoutStep.charging:
        return _status(Icons.credit_score_outlined, ui.accent, progress: true);
      case KaftpayCheckoutStep.charged:
        return _success();
      case KaftpayCheckoutStep.noMatch:
        return _status(Icons.person_search_outlined, ui.warning);
      case KaftpayCheckoutStep.failed:
        return _status(Icons.error_outline, ui.error);
      case KaftpayCheckoutStep.unknown:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _status(Icons.help_outline, ui.warning),
            KaftpayBanner(
              color: ui.error,
              icon: Icons.warning_amber_rounded,
              text: t(
                  'Pul yechilgan bo\'lishi mumkin. Mijozdan boshqa usulda '
                      'to\'lov OLMANG — avval holatni tekshiring.',
                  'Деньги могли быть списаны. НЕ принимайте оплату другим '
                      'способом — сначала проверьте статус.'),
            ),
          ],
        );
      case KaftpayCheckoutStep.choosing:
        return _choosing();
    }
  }

  /// To'lov o'tdi: katta ✓, summa, mijoz, tranzaksiya.
  Widget _success() {
    final o = c.outcome;
    final tx = o?.transactionId;
    final who = c.selected?.displayName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: KaftpayPop(
              child: KaftpayIconBadge(Icons.check_rounded,
                  color: ui.success, size: 96),
            ),
          ),
          const SizedBox(height: 16),
          Text(t('To\'lov o\'tdi', 'Оплата прошла'),
              key: const ValueKey('kaftpay_success'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          KaftpayAmountCard(
            amount: '${_money(o?.amount ?? c.amount)} ${t("so'm", 'сум')}',
            color: ui.success,
            rows: [
              if (who != null) MapEntry(t('Mijoz', 'Клиент'), who),
              if (o?.cardMask != null)
                MapEntry(t('Karta', 'Карта'), o!.cardMask!),
              if (tx != null) MapEntry(t('Tranzaksiya', 'Транзакция'), tx),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choosing() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(c.message,
            key: const ValueKey('kaftpay_message'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        for (final cand in c.candidates)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _candidate(cand),
          ),
        if (c.isExpired)
          KaftpayBanner(
            color: ui.error,
            icon: Icons.timer_off_outlined,
            text: t('Aniqlash muddati tugadi — kaftni qayta skanerlang',
                'Время истекло — отсканируйте ладонь заново'),
          ),
      ],
    );
  }

  Widget _candidate(KaftpayCandidate cand) {
    final selected = cand.consumerGuid == c.selectedGuid;
    final name = cand.displayName;
    return Material(
      color: selected ? ui.tint(ui.accent) : ui.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: selected ? ui.accent : ui.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        key: ValueKey('kaftpay_cand_${cand.consumerGuid}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => c.select(cand.consumerGuid),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: ui.tint(ui.accent), shape: BoxShape.circle),
                child: name == null
                    ? Icon(Icons.person_outline, color: ui.accent)
                    : Text(name.characters.first.toUpperCase(),
                        style: TextStyle(
                            color: ui.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name ?? t('Ism ko\'rsatilmagan', 'Имя не указано'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              if (cand.phoneLast4 != null)
                KaftpayPill('*** ${cand.phoneLast4}',
                    color: ui.fg, icon: Icons.phone_iphone),
              const SizedBox(width: 12),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? ui.accent : ui.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions() {
    final cancel = TextButton(
      key: const ValueKey('kaftpay_cancel'),
      onPressed: () => _close(),
      child: Text(t('Bekor qilish', 'Отмена')),
    );
    final rescan = OutlinedButton.icon(
      key: const ValueKey('kaftpay_rescan'),
      onPressed: () => c.start(),
      icon: const Icon(Icons.refresh, size: 20),
      label: Text(t('Qayta skanerlash', 'Сканировать заново')),
    );
    switch (c.step) {
      case KaftpayCheckoutStep.scanning:
        return [cancel];
      case KaftpayCheckoutStep.identifying:
      case KaftpayCheckoutStep.charging:
        return const [];
      case KaftpayCheckoutStep.charged:
        return [
          FilledButton.icon(
            key: const ValueKey('kaftpay_done'),
            style: ui.primaryButton
                .copyWith(backgroundColor: WidgetStatePropertyAll(ui.success)),
            onPressed: () => _close(c.outcome),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: Text(t('Tayyor', 'Готово')),
          ),
        ];
      case KaftpayCheckoutStep.noMatch:
      case KaftpayCheckoutStep.failed:
        return [cancel, rescan];
      case KaftpayCheckoutStep.choosing:
        return [
          cancel,
          rescan,
          FilledButton.icon(
            key: const ValueKey('kaftpay_pay'),
            onPressed: c.canPay ? () => c.pay() : null,
            icon: const Icon(Icons.check_rounded, size: 20),
            label: Text('${t("To'lash", 'Оплатить')} ${_money(c.amount)}'),
          ),
        ];
      case KaftpayCheckoutStep.unknown:
        return [
          TextButton(
            key: const ValueKey('kaftpay_later'),
            onPressed: () => _close(),
            child: Text(t('Keyinroq tekshirish', 'Проверить позже')),
          ),
          FilledButton.icon(
            key: const ValueKey('kaftpay_check'),
            onPressed: () => c.checkStatus(),
            icon: const Icon(Icons.sync, size: 20),
            label: Text(t('Holatni tekshirish', 'Проверить статус')),
          ),
        ];
    }
  }
}
