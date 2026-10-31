// Kaftpay to'lovi ustidagi amallar — holatni tekshirish va vozvrat.
// Sozlamalar → Kaftpay tarixi va "chek chiqmagan to'lov" ogohlantirishi
// (KaftpayUnboundNotice) bir xil oynani ishlatadi.

import 'package:flutter/material.dart';
import 'package:invan2/changes/models/organization_model.dart' show Payment;
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_action_dialog.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/money_formatter.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class KaftpayEntryActions {
  const KaftpayEntryActions._();

  static String t(String uz, String ru) => KaftpayLang.t(uz, ru);

  /// Testda soxta server ulanadi.
  @visibleForTesting
  static KaftpayApi Function(KaftpayConfig config) apiFor = _api;

  static KaftpayApi _api(KaftpayConfig config) => KaftpayApi(config: config);

  /// Adminkadagi Kaftpay to'lov turi (kalitlar shu yerda bo'lishi mumkin).
  static Payment? get payment {
    final id = Pref.getString(PrefKeys.kaftpayId, '');
    if (id.isEmpty) return null;
    for (final p in otherPaymentsGlobal) {
      if (p.id == id) return p;
    }
    return null;
  }

  static KaftpayConfig? get config => KaftpaySettings.config(payment: payment);

  static String money(int tiyin) =>
      '${MoneyFormatter.formatter.format(KaftpayMoney.toSom(tiyin))} '
      '${t("so'm", 'сум')}';

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String time(DateTime d) =>
      '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';

  static KaftpayAmountCard details(KaftpayJournalEntry e, {Color? color}) {
    final tx = e.transactionId;
    return KaftpayAmountCard(
      amount: money(e.amount),
      color: color,
      rows: [
        MapEntry(t('Mijoz', 'Клиент'), e.consumerName ?? '—'),
        MapEntry(t('Vaqt', 'Время'), time(e.createdAt)),
        if (tx != null) MapEntry(t('Tranzaksiya', 'Транзакция'), tx),
      ],
    );
  }

  /// Holatni Kaftpay'dan so'raydi (pul yechilmaydi) va jurnalni yangilaydi.
  static Future<KaftpayActionResult?> check(
    BuildContext context,
    KaftpayJournalEntry e, {
    required KaftpayConfig config,
    required KaftpayJournal journal,
  }) =>
      KaftpayActionDialog.show(
        context,
        icon: Icons.sync,
        title: t('To\'lov holati', 'Статус оплаты'),
        subtitle: t('Kaftpay\'dan so\'raladi — pul yechilmaydi',
            'Запрос в Kaftpay — деньги не списываются'),
        details: details(e),
        runningText: t('Holat tekshirilmoqda...', 'Проверяем статус...'),
        run: () async {
          final o = await KaftpayPaymentFlow(apiFor(config)).resolve(
            e.key,
            expected: KaftpayPayRequest(
              requestId: e.requestId,
              consumerGuid: e.consumerGuid,
              amount: e.amount,
              cashierId: KaftpaySettings.cashierId,
              cashierName: KaftpaySettings.cashierName,
            ),
          );
          await journal.put(e.copyWith(
            status: o.isCharged
                ? KaftpayJournalStatus.charged
                : o.isUnknown
                    ? KaftpayJournalStatus.unknown
                    : KaftpayJournalStatus.notCharged,
            transactionId: o.transactionId,
            note: o.isCharged ? null : o.message,
          ));
          if (o.isCharged) {
            return KaftpayActionResult(
              tone: KaftpayActionTone.success,
              title: t('Pul yechilgan', 'Деньги списаны'),
              message: t(
                  'Bu to\'lov chekka tushmagan bo\'lsa — vozvrat qiling.',
                  'Если этой оплаты нет в чеке — сделайте возврат.'),
            );
          }
          if (o.isUnknown) {
            return KaftpayActionResult(
              tone: KaftpayActionTone.warning,
              title: t('Natija hali noma\'lum', 'Результат пока неизвестен'),
              message: o.message,
            );
          }
          return KaftpayActionResult(
            tone: KaftpayActionTone.info,
            title: t('Pul yechilmagan', 'Деньги не списаны'),
            message: t('Mijozdan to\'lovni boshqa usulda olish mumkin.',
                'Можно принять оплату другим способом.'),
          );
        },
      );

  /// To'liq vozvrat (Kaftpay qisman vozvratni qo'llamaydi).
  static Future<KaftpayActionResult?> refund(
    BuildContext context,
    KaftpayJournalEntry e, {
    required KaftpayConfig config,
    required KaftpayJournal journal,
  }) =>
      KaftpayActionDialog.show(
        context,
        icon: Icons.undo_rounded,
        title: t('Vozvrat', 'Возврат'),
        subtitle: t('Pul mijozning kartasiga qaytariladi',
            'Деньги вернутся на карту клиента'),
        details: details(e),
        warning: t(
            'Faqat TO\'LIQ qaytariladi — Kaftpay qisman vozvratni qo\'llamaydi.',
            'Возврат только ПОЛНЫЙ — частичный возврат Kaftpay не поддерживает.'),
        confirmLabel: t('Qaytarish', 'Вернуть'),
        confirmIcon: Icons.undo_rounded,
        destructive: true,
        runningText: t('Qaytarilmoqda...', 'Возвращаем...'),
        run: () async {
          final o = await KaftpayPaymentFlow(apiFor(config)).refund(
            transactionId: e.transactionId!,
            cashierId: KaftpaySettings.cashierId,
            cashierName: KaftpaySettings.cashierName,
            paymentIdempotencyKey: e.key,
          );
          await journal.put(e.copyWith(
            status: o.isRefunded
                ? KaftpayJournalStatus.refunded
                : o.state == KaftpayRefundState.unknown
                    ? KaftpayJournalStatus.refundUnknown
                    : KaftpayJournalStatus.charged,
            note: o.isRefunded ? null : o.error?.message,
          ));
          if (o.isRefunded) {
            return KaftpayActionResult(
              tone: KaftpayActionTone.success,
              title: t('Qaytarildi', 'Возвращено'),
              message: t('Pul mijozning kartasiga qaytdi.',
                  'Деньги вернулись на карту клиента.'),
            );
          }
          if (o.state == KaftpayRefundState.unknown) {
            return KaftpayActionResult(
              tone: KaftpayActionTone.warning,
              title: t('Vozvrat natijasi noma\'lum',
                  'Результат возврата неизвестен'),
              message: o.retryAllowed
                  ? (o.error?.message ?? '')
                  : t('Qayta YUBORMANG — Kaftpay bilan tekshiring. ${o.error?.message ?? ''}',
                      'НЕ отправляйте повторно — уточните в Kaftpay. ${o.error?.message ?? ''}'),
            );
          }
          return KaftpayActionResult(
            tone: KaftpayActionTone.error,
            title: t('Qaytarilmadi', 'Не возвращено'),
            message: o.error?.message,
          );
        },
      );
}
