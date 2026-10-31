// To'lov sahifasidan chiqishda: pul yechilgan (Kaftpay / terminal orqali
// Uzcard, Humo), sotuv yakunlanmagan — tasdiq. Chiqilsa bu to'lovlar chekka
// tushmaydi va pulni qaytarish kerak bo'ladi. `true` — baribir chiqish.

import 'package:flutter/material.dart';
import 'package:invan2/changes/domain/payment/charged_on_leave.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_ui.dart';
import 'package:invan2/utils/helpers/money_formatter.dart';

class LeaveChargedDialog extends StatelessWidget {
  const LeaveChargedDialog({super.key, required this.charged, this.uz = true});

  final List<ChargedPayment> charged;
  final bool uz;

  static Future<bool> show(
    BuildContext context, {
    required List<ChargedPayment> charged,
    bool uz = true,
  }) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => LeaveChargedDialog(charged: charged, uz: uz),
      ).then((v) => v == true);

  String t(String u, String r) => uz ? u : r;

  String _name(ChargedKind k) {
    switch (k) {
      case ChargedKind.kaftpay:
        return 'Kaftpay';
      case ChargedKind.uzcard:
        return 'Uzcard';
      case ChargedKind.humo:
        return 'Humo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    final hasKaftpay = charged.any((c) => c.kind == ChargedKind.kaftpay);
    final hasCard = charged.any((c) => c.kind != ChargedKind.kaftpay);
    return ui.wrap(AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Row(
        children: [
          KaftpayIconBadge(Icons.warning_amber_rounded,
              color: ui.warning, size: 48),
          const SizedBox(width: 14),
          Expanded(child: Text(t('Pul yechilgan', 'Деньги списаны'))),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 520, maxWidth: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in charged)
                Container(
                  key: ValueKey('leave_charged_${c.kind.name}'),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: ui.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ui.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_name(c.kind),
                            style: TextStyle(
                                color: ui.fg,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                      ),
                      Text(
                          '${MoneyFormatter.formatter.format(c.amount)} '
                          '${t("so'm", 'сум')}',
                          style: TextStyle(
                              color: ui.fg,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                t(
                    'Chiqsangiz, bu to\'lov chekka tushmaydi — pulni qaytarish '
                        'kerak bo\'ladi.',
                    'Если выйти, оплата не попадёт в чек — деньги придётся '
                        'вернуть.'),
                style: TextStyle(
                    color: ui.fg, fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (hasKaftpay)
                Text(
                    t('Kaftpay: Sozlamalar › Kaftpay › Vozvrat',
                        'Kaftpay: Настройки › Kaftpay › Возврат'),
                    style: TextStyle(color: ui.muted, fontSize: 15)),
              if (hasCard)
                Text(
                    t('Karta: terminalda bekor qilish',
                        'Карта: отмена на терминале'),
                    style: TextStyle(color: ui.muted, fontSize: 15)),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const ValueKey('leave_stay'),
                autofocus: true,
                style: ui.big(ui.primaryButton, height: 72, font: 21),
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: Text(t('Qolish — sotuvni yakunlash',
                    'Остаться — завершить продажу')),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                key: const ValueKey('leave_anyway'),
                style: ui.big(
                    ui.secondaryButton.copyWith(
                      foregroundColor: WidgetStatePropertyAll(ui.error),
                      side: WidgetStatePropertyAll(BorderSide(
                          color: ui.error.withValues(alpha: 0.7), width: 1.5)),
                    ),
                    height: 60,
                    font: 18),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(t('Baribir chiqish', 'Всё равно выйти')),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
