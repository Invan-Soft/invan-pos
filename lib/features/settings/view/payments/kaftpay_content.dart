// Sozlamalar → Kaftpay (PIN bilan): kalitlar, SDK papkasi, aloqa va skaner
// tekshiruvi, mijozni ro'yxatdan o'tkazish, to'lovlar jurnali (holatni
// tekshirish / vozvrat).

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';
import 'package:invan2/changes/models/organization_model.dart' show Payment;
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_enroll_dialog.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_ui.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/money_formatter.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class KaftpayContent extends StatefulWidget {
  const KaftpayContent({super.key});

  @override
  State<KaftpayContent> createState() => _KaftpayContentState();
}

class _KaftpayContentState extends State<KaftpayContent> {
  final _clientId = TextEditingController(text: KaftpaySettings.localClientId);
  final _secret = TextEditingController(text: KaftpaySettings.localSecret);
  final _sdkDir =
      TextEditingController(text: Pref.getString(PrefKeys.kaftpaySdkDir, ''));
  final _journal = KaftpayJournal();
  bool _showSecret = false;
  bool _busy = false;
  String? _pingText;
  bool _pingWarn = false;
  String? _scanText;

  bool get uz => AppLocalizations.of(context)!.ha == 'Ha';
  String t(String u, String r) => uz ? u : r;

  @override
  void dispose() {
    _clientId.dispose();
    _secret.dispose();
    _sdkDir.dispose();
    super.dispose();
  }

  Payment? get _payment {
    final id = Pref.getString(PrefKeys.kaftpayId, '');
    for (final p in otherPaymentsGlobal) {
      if (id.isNotEmpty && p.id == id) return p;
    }
    return null;
  }

  KaftpayConfig? get _config => KaftpaySettings.config(payment: _payment);

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 4)));

  Future<void> _save() async {
    await Pref.setString(PrefKeys.kaftpayClientId, _clientId.text.trim());
    await Pref.setString(PrefKeys.kaftpaySecret, _secret.text.trim());
    await Pref.setString(PrefKeys.kaftpaySdkDir, _sdkDir.text.trim());
    if (!mounted) return;
    _snack(t('Saqlandi', 'Сохранено'));
    setState(() {});
  }

  Future<void> _ping() async {
    final config = _config;
    if (config == null) {
      _snack(t('Avval Client ID va Secret kiriting',
          'Сначала введите Client ID и Secret'));
      return;
    }
    setState(() => _busy = true);
    final api = KaftpayApi(config: config);
    final r = await api.ping();
    if (!mounted) return;
    final d = r.data;
    setState(() {
      _busy = false;
      if (d == null) {
        _pingWarn = true;
        _pingText = '✗ ${r.error!.message}';
        return;
      }
      final lines = <String>[
        '✓ ${t('Aloqa bor', 'Связь есть')}: ${d.clientId ?? config.clientId} · '
            '${d.status ?? '?'}',
        if (d.isTest == true)
          t('TEST terminali — pul yechilmaydi',
              'ТЕСТОВЫЙ терминал — деньги не списываются'),
        if (d.ofdEnabled == true)
          t('DIQQAT: terminalda Kaftpay fiskalizatsiyasi YOQILGAN — chek ikki marta chiqadi. Kaftpay\'dan o\'chirishni so\'rang.',
              'ВНИМАНИЕ: у терминала включена фискализация Kaftpay — чек будет дважды. Попросите отключить.'),
        if (api.clockOffset.inSeconds.abs() >= 120)
          t('Kompyuter soati ${api.clockOffset.inSeconds} s farq qiladi — vaqtni sinxronlang',
              'Часы компьютера расходятся на ${api.clockOffset.inSeconds} с — включите синхронизацию'),
      ];
      _pingWarn =
          d.isTest == true || d.ofdEnabled == true || d.isActive != true;
      _pingText = lines.join('\n');
    });
  }

  Future<void> _testScanner() async {
    final scanner = KaftpayScanner.shared(sdkDir: KaftpaySettings.sdkDir);
    setState(() {
      _busy = true;
      _scanText = t('Kaftni skanerga qo\'ying...', 'Приложите ладонь...');
    });
    try {
      final scan = await scanner.capture(onStage: (_, m) {
        if (mounted) setState(() => _scanText = m);
      });
      if (!mounted) return;
      setState(() => _scanText =
          '✓ ${t('Kaft o\'qildi', 'Ладонь считана')} (SDK: ${scan.hand.wire}, '
              'RGB: ${scan.hasUsableRgb ? t('bor', 'есть') : t('yo\'q', 'нет')})');
    } on KaftpayScannerException catch (e) {
      if (mounted) setState(() => _scanText = '✗ ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enroll() async {
    final config = _config;
    if (config == null) {
      _snack(t('Avval Client ID va Secret kiriting',
          'Сначала введите Client ID и Secret'));
      return;
    }
    await KaftpayEnrollDialog.show(
      context,
      api: KaftpayApi(config: config),
      scanner: KaftpayScanner.shared(sdkDir: KaftpaySettings.sdkDir),
      uz: uz,
    );
  }

  Future<void> _check(KaftpayJournalEntry e) async {
    final config = _config;
    if (config == null) return;
    setState(() => _busy = true);
    final o = await KaftpayPaymentFlow(KaftpayApi(config: config)).resolve(
      e.key,
      expected: KaftpayPayRequest(
        requestId: e.requestId,
        consumerGuid: e.consumerGuid,
        amount: e.amount,
        cashierId: KaftpaySettings.cashierId,
        cashierName: KaftpaySettings.cashierName,
      ),
    );
    await _journal.put(e.copyWith(
      status: o.isCharged
          ? KaftpayJournalStatus.charged
          : o.isUnknown
              ? KaftpayJournalStatus.unknown
              : KaftpayJournalStatus.notCharged,
      transactionId: o.transactionId,
      note: o.isCharged ? null : o.message,
    ));
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(o.isCharged
        ? t('Pul yechilgan (tx ${o.transactionId}). Chekda yo\'q bo\'lsa — vozvrat qiling.',
            'Деньги списаны (tx ${o.transactionId}). Если нет в чеке — сделайте возврат.')
        : o.message);
  }

  Future<void> _refund(KaftpayJournalEntry e) async {
    final config = _config;
    if (config == null || !e.canRefund) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(t(
            '${_money(e.amount)} so\'m ${e.consumerName ?? ''} kartasiga to\'liq qaytarilsinmi?',
            'Вернуть ${_money(e.amount)} сум полностью на карту ${e.consumerName ?? ''}?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(t('Yo\'q', 'Нет'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(t('Qaytarish', 'Вернуть'))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final o = await KaftpayPaymentFlow(KaftpayApi(config: config)).refund(
      transactionId: e.transactionId!,
      cashierId: KaftpaySettings.cashierId,
      cashierName: KaftpaySettings.cashierName,
      paymentIdempotencyKey: e.key,
    );
    await _journal.put(e.copyWith(
      status: o.isRefunded
          ? KaftpayJournalStatus.refunded
          : o.state == KaftpayRefundState.unknown
              ? KaftpayJournalStatus.refundUnknown
              : KaftpayJournalStatus.charged,
      note: o.isRefunded ? null : o.error?.message,
    ));
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(o.isRefunded
        ? t('Qaytarildi', 'Возвращено')
        : (o.error?.message ?? t('Qaytarilmadi', 'Не возвращено')));
  }

  String _money(int tiyin) =>
      MoneyFormatter.formatter.format(KaftpayMoney.toSom(tiyin));

  String _statusText(KaftpayJournalStatus s) {
    switch (s) {
      case KaftpayJournalStatus.pending:
        return t('Javob yo\'q', 'Нет ответа');
      case KaftpayJournalStatus.charged:
        return t('Yechildi', 'Списано');
      case KaftpayJournalStatus.notCharged:
        return t('Yechilmadi', 'Не списано');
      case KaftpayJournalStatus.unknown:
        return t('Noma\'lum', 'Неизвестно');
      case KaftpayJournalStatus.refunded:
        return t('Qaytarildi', 'Возвращено');
      case KaftpayJournalStatus.refundUnknown:
        return t('Vozvrat noma\'lum', 'Возврат неизвестен');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    final theme = ui.theme;
    final payment = _payment;
    final scanner = KaftpayScanner.shared(sdkDir: KaftpaySettings.sdkDir);
    final scannerReason = scanner.unavailableReason;
    final synthetic = scanner is KaftpaySyntheticScanner;
    final entries = _journal.all();
    final adminKeys = (payment?.merchantId ?? '').trim().isNotEmpty &&
        (payment?.secretKey ?? '').trim().isNotEmpty;

    Widget section(String title, List<Widget> children) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        );

    return ui.wrap(AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section(t('Holat', 'Состояние'), [
            _line(
              payment == null
                  ? t('Adminkada "Kaftpay" to\'lov turi yo\'q — qo\'shib, "Ma\'lumotlarni yangilash" qiling',
                      'В админке нет типа оплаты «Kaftpay» — добавьте и обновите данные')
                  : payment.isAdded == true
                      ? t('To\'lov turi: bor, yoqilgan',
                          'Тип оплаты: есть, включён')
                      : t('To\'lov turi: bor, lekin "Apps" da o\'chiq',
                          'Тип оплаты: есть, но выключен в «Apps»'),
              ok: payment?.isAdded == true,
            ),
            _line(
              scannerReason ??
                  (synthetic
                      ? t('SINOV rejimi: haqiqiy skaner o\'rniga sun\'iy kaft (faqat debug, Windows emas)',
                          'ТЕСТ: вместо сканера — синтетическая ладонь (только debug, не Windows)')
                      : '${t('Skaner dasturi', 'ПО сканера')}: ${KaftpaySettings.sdkDir}'),
              ok: scannerReason == null,
            ),
            _line(
              adminKeys
                  ? t('Kalitlar: adminkadan', 'Ключи: из админки')
                  : _config != null
                      ? t('Kalitlar: shu kassa sozlamasidan',
                          'Ключи: из настроек кассы')
                      : t('Kalitlar kiritilmagan', 'Ключи не заданы'),
              ok: _config != null,
            ),
          ]),
          section(t('Terminal kalitlari', 'Ключи терминала'), [
            if (adminKeys)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t(
                    'Adminkadagi kalitlar ishlatiladi — quyidagilar faqat ular bo\'lmasa.',
                    'Используются ключи из админки — эти только если их нет.')),
              ),
            TextField(
              key: const ValueKey('kaftpay_client_id'),
              controller: _clientId,
              decoration: const InputDecoration(
                  labelText: 'Client ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('kaftpay_secret'),
              controller: _secret,
              obscureText: !_showSecret,
              decoration: InputDecoration(
                labelText: 'Secret',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _showSecret ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showSecret = !_showSecret),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('kaftpay_sdk_dir'),
              controller: _sdkDir,
              decoration: InputDecoration(
                labelText: t('Skaner dasturi papkasi', 'Папка ПО сканера'),
                hintText: KaftpaySettings.defaultSdkDir,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  key: const ValueKey('kaftpay_save'),
                  onPressed: _save,
                  child: Text(t('Saqlash', 'Сохранить')),
                ),
                OutlinedButton(
                  key: const ValueKey('kaftpay_ping'),
                  onPressed: _ping,
                  child: Text(t('Aloqani tekshirish', 'Проверить связь')),
                ),
                OutlinedButton(
                  key: const ValueKey('kaftpay_scan_test'),
                  onPressed: _testScanner,
                  child: Text(t('Skanerni tekshirish', 'Проверить сканер')),
                ),
                OutlinedButton(
                  key: const ValueKey('kaftpay_enroll'),
                  onPressed: _enroll,
                  child: Text(t('Mijozni ro\'yxatdan o\'tkazish',
                      'Зарегистрировать клиента')),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_pingText != null) ...[
              const SizedBox(height: 12),
              Text(_pingText!,
                  key: const ValueKey('kaftpay_ping_result'),
                  style: TextStyle(
                      color: _pingWarn ? ui.warning : ui.success,
                      fontWeight: FontWeight.w600)),
            ],
            if (_scanText != null) ...[
              const SizedBox(height: 8),
              Text(_scanText!, key: const ValueKey('kaftpay_scan_result')),
            ],
          ]),
          section(t('To\'lovlar jurnali', 'Журнал оплат'), [
            if (entries.isEmpty)
              Text(t('Hali to\'lov yo\'q', 'Оплат пока нет')),
            for (final e in entries.take(50))
              ListTile(
                key: ValueKey('kaftpay_journal_${e.key}'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                    '${_money(e.amount)} · ${e.consumerName ?? '—'} · ${_statusText(e.status)}'),
                subtitle: Text([
                  '${e.createdAt.day.toString().padLeft(2, '0')}.${e.createdAt.month.toString().padLeft(2, '0')} '
                      '${e.createdAt.hour.toString().padLeft(2, '0')}:${e.createdAt.minute.toString().padLeft(2, '0')}',
                  if (e.transactionId != null) 'tx ${e.transactionId}',
                  if (e.note != null) e.note!,
                ].join(' · ')),
                trailing: e.needsStatusCheck
                    ? OutlinedButton(
                        onPressed: () => _check(e),
                        child: Text(t('Tekshirish', 'Проверить')))
                    : e.canRefund
                        ? OutlinedButton(
                            onPressed: () => _refund(e),
                            child: Text(t('Vozvrat', 'Возврат')))
                        : null,
              ),
          ]),
        ],
      ),
    ));
  }

  Widget _line(String text, {required bool ok}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 20,
                color: ok
                    ? KaftpayUi.of(context).success
                    : KaftpayUi.of(context).warning),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
