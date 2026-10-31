// "Chek chiqmagan Kaftpay to'lovi" ogohlantirishi.
//
// Pul Kaftpay'dan yechilgan, lekin sotuv chekka yozilmagan (kassir sotuvni
// yakunlamay chiqib ketdi, fiskal xato, dastur yopildi). Sotuv ekrani
// ochilganda (HomePage) ko'rsatiladi: har to'lov uchun "Vozvrat" —
// pul mijozning kartasiga qaytadi. "Keyinroq" — [snooze] ga jim turadi;
// ilova qayta ochilsa yana chiqadi.
//
// Faqat yangi yozuvlar kuzatiladi (`KaftpayJournalEntry.receipt`): eski
// to'lovlar ogohlantirishga tushmaydi.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_entry_actions.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_ui.dart';
import 'package:invan2/idle_service.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

class KaftpayUnboundNotice {
  KaftpayUnboundNotice._();

  static const Duration snooze = Duration(minutes: 30);

  static bool _showing = false;
  static DateTime? _snoozedUntil;

  @visibleForTesting
  static void resetForTest() {
    _showing = false;
    _snoozedUntil = null;
  }

  /// Kontekstsiz shartlar (testda tekshiriladi).
  static bool shouldShow({KaftpayJournal? journal, DateTime? now}) {
    if (_showing) return false;
    if (Pref.getString(PrefKeys.kaftpayId, '').isEmpty) return false;
    final token = Pref.getString(PrefKeys.token, '');
    if (token.isEmpty || token == 'not initialized') return false;
    if (IdleService().isOnLockPage || IdleService().isOnCriticalAuthPage) {
      return false;
    }
    final until = _snoozedUntil;
    if (until != null && (now ?? DateTime.now()).isBefore(until)) return false;
    return (journal ?? KaftpayJournal()).unbound().isNotEmpty;
  }

  static Future<void> maybeShow() async {
    if (!shouldShow()) return;
    final context = AppNavigation.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    _showing = true;
    try {
      final loc = AppLocalizations.of(context);
      KaftpayLang.uz = loc == null || loc.ha == 'Ha';
      final later = await KaftpayUnboundDialog.show(context);
      if (later) _snoozedUntil = DateTime.now().add(snooze);
    } finally {
      _showing = false;
    }
  }
}

class KaftpayUnboundDialog extends StatefulWidget {
  const KaftpayUnboundDialog({super.key, this.journal});

  final KaftpayJournal? journal;

  /// `true` — "Keyinroq" (hal qilinmagan to'lovlar qoldi).
  static Future<bool> show(BuildContext context, {KaftpayJournal? journal}) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => KaftpayUnboundDialog(journal: journal),
      ).then((v) => v ?? true);

  @override
  State<KaftpayUnboundDialog> createState() => _KaftpayUnboundDialogState();
}

class _KaftpayUnboundDialogState extends State<KaftpayUnboundDialog> {
  late final KaftpayJournal _journal = widget.journal ?? KaftpayJournal();

  String t(String uz, String ru) => KaftpayLang.t(uz, ru);

  Future<void> _refund(KaftpayJournalEntry e) async {
    final config = KaftpayEntryActions.config;
    if (config == null) return;
    await KaftpayEntryActions.refund(context, e,
        config: config, journal: _journal);
    if (!mounted) return;
    if (_journal.unbound().isEmpty) {
      Navigator.of(context).pop(false);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    final entries = _journal.unbound();
    final config = KaftpayEntryActions.config;
    return ui.wrap(PopScope(
      canPop: false,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Row(
          children: [
            KaftpayIconBadge(Icons.receipt_long_outlined,
                color: ui.warning, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('Kaftpay: chek chiqmagan', 'Kaftpay: чек не выбит')),
                  Text(
                      t('Pul yechilgan, sotuv yakunlanmagan',
                          'Деньги списаны, продажа не завершена'),
                      style: TextStyle(
                          color: ui.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 580, maxWidth: 680),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in entries) ...[
                  _row(ui, e, canRefund: config != null && e.canRefund),
                  const SizedBox(height: 12),
                ],
                if (config == null)
                  KaftpayBanner(
                      color: ui.error,
                      icon: Icons.key_off_outlined,
                      text: t('Kaftpay kalitlari kiritilmagan',
                          'Ключи Kaftpay не заданы')),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const ValueKey('kaftpay_unbound_later'),
                  style: ui.big(ui.secondaryButton, height: 64, font: 19),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(t('Keyinroq', 'Позже')),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _row(KaftpayUi ui, KaftpayJournalEntry e, {required bool canRefund}) {
    return Container(
      key: ValueKey('kaftpay_unbound_row_${e.key}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ui.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(KaftpayEntryActions.money(e.amount),
                    style: TextStyle(
                        color: ui.fg,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    '${e.consumerName ?? '—'} · '
                    '${KaftpayEntryActions.time(e.createdAt)}',
                    style: TextStyle(color: ui.muted, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // `ui.big` butun enni egallaydi — qatorda aniq en kerak.
          SizedBox(
            width: 190,
            child: FilledButton.icon(
              key: ValueKey('kaftpay_unbound_refund_${e.key}'),
              style: ui.big(
                  ui.primaryButton.copyWith(
                      backgroundColor: WidgetStatePropertyAll(ui.error)),
                  height: 60,
                  font: 19),
              onPressed: canRefund ? () => _refund(e) : null,
              icon: const Icon(Icons.undo_rounded),
              label: Text(t('Vozvrat', 'Возврат')),
            ),
          ),
        ],
      ),
    );
  }
}
