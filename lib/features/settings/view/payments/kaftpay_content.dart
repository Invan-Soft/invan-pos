// Sozlamalar → Kaftpay (PIN bilan): kalitlar, SDK papkasi, aloqa va skaner
// tekshiruvi, mijozni ro'yxatdan o'tkazish, to'lovlar jurnali (holatni
// tekshirish / vozvrat).

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
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

  /// Skaner tekshiruvi natijasi: null — jarayonda, true/false — natija.
  bool? _scanOk;

  /// Aloqa tekshiruvi: true — muvaffaqiyatli (test bo'lsa ham).
  bool? _pingOk;
  bool? _isTest;

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
        _pingOk = false;
        _pingWarn = true;
        _pingText = r.error!.message;
        return;
      }
      _pingOk = d.isActive == true;
      _isTest = d.isTest;
      final lines = <String>[
        '${t('Aloqa bor', 'Связь есть')}: ${d.clientId ?? config.clientId} · '
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
      _scanOk = null;
      _scanText = t('Kaftni skanerga qo\'ying...', 'Приложите ладонь...');
    });
    try {
      final scan = await scanner.capture(onStage: (_, m) {
        if (mounted) setState(() => _scanText = m);
      });
      if (!mounted) return;
      setState(() {
        _scanOk = true;
        _scanText = '${t('Kaft o\'qildi', 'Ладонь считана')} (SDK: '
            '${scan.hand.wire}, RGB: '
            '${scan.hasUsableRgb ? t('bor', 'есть') : t('yo\'q', 'нет')})';
      });
    } on KaftpayScannerException catch (e) {
      if (mounted) {
        setState(() {
          _scanOk = false;
          _scanText = e.message;
        });
      }
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

  Color _statusColor(KaftpayUi ui, KaftpayJournalStatus st) {
    switch (st) {
      case KaftpayJournalStatus.charged:
        return ui.success;
      case KaftpayJournalStatus.refunded:
        return ui.accent;
      case KaftpayJournalStatus.notCharged:
        return ui.muted;
      case KaftpayJournalStatus.pending:
      case KaftpayJournalStatus.unknown:
        return ui.warning;
      case KaftpayJournalStatus.refundUnknown:
        return ui.error;
    }
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    KaftpayLang.uz = uz;
    final ui = KaftpayUi.of(context);
    final payment = _payment;
    final scanner = KaftpayScanner.shared(sdkDir: KaftpaySettings.sdkDir);
    final scannerReason = scanner.unavailableReason;
    final synthetic = scanner is KaftpaySyntheticScanner;
    final entries = _journal.all();
    final adminKeys = (payment?.merchantId ?? '').trim().isNotEmpty &&
        (payment?.secretKey ?? '').trim().isNotEmpty;
    final config = _config;

    Widget section({
      required String title,
      IconData? icon,
      String? subtitle,
      Widget? trailing,
      required List<Widget> children,
    }) =>
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: ui.muted),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          if (subtitle != null)
                            Text(subtitle,
                                style:
                                    TextStyle(color: ui.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        );

    final paymentOk = payment?.isAdded == true;
    final header = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            KaftpayIconBadge(Icons.back_hand_outlined,
                color: ui.accent, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kaftpay',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                      t('Kaft bilan to\'lov · VP930 skaneri',
                          'Оплата ладонью · сканер VP930'),
                      style: TextStyle(color: ui.muted, fontSize: 13)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      KaftpayPill(
                        payment == null
                            ? t('To\'lov turi yo\'q', 'Нет типа оплаты')
                            : paymentOk
                                ? t('To\'lov turi yoqilgan',
                                    'Тип оплаты включён')
                                : t('To\'lov turi o\'chiq',
                                    'Тип оплаты выключен'),
                        color: paymentOk ? ui.success : ui.warning,
                      ),
                      KaftpayPill(
                        scannerReason != null
                            ? t('Skaner tayyor emas', 'Сканер не готов')
                            : synthetic
                                ? t('Sinov skaneri', 'Тестовый сканер')
                                : t('Skaner dasturi bor', 'ПО сканера есть'),
                        color: scannerReason != null
                            ? ui.error
                            : synthetic
                                ? ui.warning
                                : ui.success,
                      ),
                      KaftpayPill(
                        config == null
                            ? t('Kalitlar yo\'q', 'Нет ключей')
                            : adminKeys
                                ? t('Kalitlar adminkadan', 'Ключи из админки')
                                : t('Kalitlar kiritilgan', 'Ключи заданы'),
                        color: config == null ? ui.error : ui.success,
                      ),
                      if (_pingOk != null)
                        KaftpayPill(
                          _pingOk!
                              ? (_isTest == true
                                  ? t('TEST terminali', 'ТЕСТ терминал')
                                  : t('Terminal faol', 'Терминал активен'))
                              : t('Aloqa yo\'q', 'Нет связи'),
                          color: !_pingOk!
                              ? ui.error
                              : _isTest == true
                                  ? ui.warning
                                  : ui.success,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final hints = <Widget>[
      if (payment == null || !paymentOk)
        KaftpayBanner(
          color: ui.warning,
          icon: Icons.info_outline,
          text: payment == null
              ? t('Adminkada "Kaftpay" to\'lov turini qo\'shing va "Ma\'lumotlarni yangilash" qiling — to\'lov ekranida tugma chiqadi.',
                  'Добавьте тип оплаты «Kaftpay» в админке и обновите данные — на экране оплаты появится кнопка.')
              : t('"Kaftpay" to\'lov turi adminkaning "Apps" bo\'limida o\'chiq — yoqing.',
                  'Тип оплаты «Kaftpay» выключен в «Apps» админки — включите.'),
        ),
      if (scannerReason != null)
        KaftpayBanner(
            color: ui.error, icon: Icons.usb_off, text: scannerReason),
      if (synthetic)
        KaftpayBanner(
          color: ui.warning,
          icon: Icons.science_outlined,
          text: t(
              'SINOV rejimi: haqiqiy skaner o\'rniga sun\'iy kaft (faqat debug, Windows emas).',
              'ТЕСТ: вместо сканера — синтетическая ладонь (только debug, не Windows).'),
        ),
    ];

    Widget actionTile({
      required Key key,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) =>
        SizedBox(
          width: 270,
          height: 84,
          child: KaftpayChoiceCard(
            key: key,
            icon: icon,
            title: title,
            subtitle: subtitle,
            onTap: _busy ? null : onTap,
          ),
        );

    final actions = section(
      title:
          t('Tekshirish va ro\'yxatdan o\'tkazish', 'Проверка и регистрация'),
      icon: Icons.bolt_outlined,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            actionTile(
              key: const ValueKey('kaftpay_ping'),
              icon: Icons.wifi_tethering,
              title: t('Aloqani tekshirish', 'Проверить связь'),
              subtitle: t('Server va kalitlar', 'Сервер и ключи'),
              onTap: _ping,
            ),
            actionTile(
              key: const ValueKey('kaftpay_scan_test'),
              icon: Icons.back_hand_outlined,
              title: t('Skanerni tekshirish', 'Проверить сканер'),
              subtitle: t('Kaftni o\'qib ko\'rish', 'Пробное чтение ладони'),
              onTap: _testScanner,
            ),
            actionTile(
              key: const ValueKey('kaftpay_enroll'),
              icon: Icons.person_add_alt_1_outlined,
              title: t('Ro\'yxatdan o\'tkazish', 'Регистрация клиента'),
              subtitle: t('Mijoz: QR + kaft', 'Клиент: QR + ладонь'),
              onTap: _enroll,
            ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(minHeight: 4),
          ),
        ],
        if (_pingText != null) ...[
          const SizedBox(height: 16),
          KaftpayBanner(
            key: const ValueKey('kaftpay_ping_result'),
            color: _pingOk != true
                ? ui.error
                : _pingWarn
                    ? ui.warning
                    : ui.success,
            icon: _pingOk == true ? Icons.wifi_tethering : Icons.wifi_off,
            text: _pingText!,
          ),
        ],
        if (_scanText != null) ...[
          const SizedBox(height: 12),
          KaftpayBanner(
            key: const ValueKey('kaftpay_scan_result'),
            color: _scanOk == null
                ? ui.accent
                : _scanOk!
                    ? ui.success
                    : ui.error,
            icon: _scanOk == false
                ? Icons.error_outline
                : Icons.back_hand_outlined,
            text: _scanText!,
          ),
        ],
      ],
    );

    final keys = section(
      title: t('Terminal kalitlari', 'Ключи терминала'),
      icon: Icons.key_outlined,
      subtitle: adminKeys
          ? t('Adminkadagi kalitlar ishlatiladi — bular faqat ular bo\'lmasa.',
              'Используются ключи из админки — эти только если их нет.')
          : t('Kaftpay bergan terminal kalitlari',
              'Ключи терминала от Kaftpay'),
      children: [
        TextField(
          key: const ValueKey('kaftpay_client_id'),
          controller: _clientId,
          decoration: const InputDecoration(
            labelText: 'Client ID',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('kaftpay_secret'),
          controller: _secret,
          obscureText: !_showSecret,
          decoration: InputDecoration(
            labelText: 'Secret',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showSecret
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _showSecret = !_showSecret),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('kaftpay_sdk_dir'),
          controller: _sdkDir,
          decoration: InputDecoration(
            labelText: t('Skaner dasturi papkasi', 'Папка ПО сканера'),
            hintText: KaftpaySettings.defaultSdkDir,
            prefixIcon: const Icon(Icons.folder_outlined),
            helperText: t('Bo\'sh — sukut: ${KaftpaySettings.defaultSdkDir}',
                'Пусто — по умолчанию: ${KaftpaySettings.defaultSdkDir}'),
            helperStyle: TextStyle(color: ui.faint),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const ValueKey('kaftpay_save'),
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 20),
            label: Text(t('Saqlash', 'Сохранить')),
          ),
        ),
      ],
    );

    final journal = section(
      title: t('To\'lovlar jurnali', 'Журнал оплат'),
      icon: Icons.receipt_long_outlined,
      trailing: entries.isEmpty
          ? null
          : KaftpayPill('${entries.length}', color: ui.muted, dense: true),
      children: [
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: ui.faint),
                const SizedBox(height: 8),
                Text(t('Hali to\'lov yo\'q', 'Оплат пока нет'),
                    style: TextStyle(color: ui.muted)),
              ],
            ),
          ),
        for (var i = 0; i < entries.length && i < 50; i++) ...[
          if (i > 0) const Divider(height: 1),
          _journalRow(ui, entries[i]),
        ],
      ],
    );

    return ui.wrap(AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: _constrained([
          header,
          for (final h in hints) ...[const SizedBox(height: 12), h],
          const SizedBox(height: 16),
          actions,
          const SizedBox(height: 16),
          keys,
          const SizedBox(height: 16),
          journal,
        ]),
      ),
    ));
  }

  /// Keng ekranda kontent eni cheklanadi (maydonlar juda cho'zilmasin).
  static List<Widget> _constrained(List<Widget> children) => [
        for (final c in children)
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: c,
            ),
          ),
      ];

  Widget _journalRow(KaftpayUi ui, KaftpayJournalEntry e) {
    final d = e.createdAt;
    final when =
        '${_two(d.day)}.${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';
    final tx = e.transactionId;
    return Padding(
      key: ValueKey('kaftpay_journal_${e.key}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${_money(e.amount)} ${t("so'm", 'сум')}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(e.consumerName ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: ui.muted)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    when,
                    if (tx != null)
                      'tx ${tx.length > 8 ? '${tx.substring(0, 8)}…' : tx}',
                    if (e.note != null) e.note!,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ui.faint, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          KaftpayPill(_statusText(e.status),
              color: _statusColor(ui, e.status), dense: true),
          if (e.needsStatusCheck || e.canRefund) ...[
            const SizedBox(width: 12),
            e.needsStatusCheck
                ? FilledButton.icon(
                    onPressed: () => _check(e),
                    icon: const Icon(Icons.sync, size: 18),
                    label: Text(t('Tekshirish', 'Проверить')),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _refund(e),
                    icon: const Icon(Icons.undo, size: 18),
                    label: Text(t('Vozvrat', 'Возврат')),
                  ),
          ],
        ],
      ),
    );
  }
}
