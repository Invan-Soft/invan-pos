// Kaftpay amal oynasi: tasdiqlash → jarayon → natija (vozvrat, holatni
// tekshirish). Amalning o'zi [KaftpayActionDialog.run] da; oyna natijani
// ko'rsatadi va yopilganda qaytaradi.

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_ui.dart';

enum KaftpayActionTone { success, warning, error, info }

class KaftpayActionResult {
  const KaftpayActionResult({
    required this.tone,
    required this.title,
    this.message,
  });

  final KaftpayActionTone tone;
  final String title;
  final String? message;
}

class KaftpayActionDialog extends StatefulWidget {
  const KaftpayActionDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.run,
    this.subtitle,
    this.details,
    this.warning,
    this.confirmLabel,
    this.confirmIcon,
    this.destructive = false,
    this.runningText,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Summa / mijoz / tranzaksiya kartasi.
  final Widget? details;

  /// Tasdiqlashdan oldingi ogohlantirish.
  final String? warning;

  /// null — tasdiqlashsiz, oyna ochilishi bilan bajariladi.
  final String? confirmLabel;
  final IconData? confirmIcon;

  /// Tasdiqlash tugmasi qizil (vozvrat).
  final bool destructive;
  final String? runningText;
  final Future<KaftpayActionResult> Function() run;

  static Future<KaftpayActionResult?> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Future<KaftpayActionResult> Function() run,
    String? subtitle,
    Widget? details,
    String? warning,
    String? confirmLabel,
    IconData? confirmIcon,
    bool destructive = false,
    String? runningText,
  }) =>
      showDialog<KaftpayActionResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => KaftpayActionDialog(
          icon: icon,
          title: title,
          subtitle: subtitle,
          details: details,
          warning: warning,
          confirmLabel: confirmLabel,
          confirmIcon: confirmIcon,
          destructive: destructive,
          runningText: runningText,
          run: run,
        ),
      );

  @override
  State<KaftpayActionDialog> createState() => _KaftpayActionDialogState();
}

enum _Phase { confirm, running, done }

class _KaftpayActionDialogState extends State<KaftpayActionDialog> {
  _Phase _phase = _Phase.confirm;
  KaftpayActionResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.confirmLabel == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go());
    }
  }

  Future<void> _go() async {
    if (_phase != _Phase.confirm) return;
    setState(() => _phase = _Phase.running);
    KaftpayActionResult r;
    try {
      r = await widget.run();
    } catch (e) {
      r = KaftpayActionResult(
          tone: KaftpayActionTone.error,
          title: KaftpayLang.t('Xato', 'Ошибка'),
          message: '$e');
    }
    if (!mounted) return;
    setState(() {
      _result = r;
      _phase = _Phase.done;
    });
  }

  Color _toneColor(KaftpayUi ui, KaftpayActionTone t) {
    switch (t) {
      case KaftpayActionTone.success:
        return ui.success;
      case KaftpayActionTone.warning:
        return ui.warning;
      case KaftpayActionTone.error:
        return ui.error;
      case KaftpayActionTone.info:
        return ui.accent;
    }
  }

  IconData _toneIcon(KaftpayActionTone t) {
    switch (t) {
      case KaftpayActionTone.success:
        return Icons.check_rounded;
      case KaftpayActionTone.warning:
        return Icons.help_outline;
      case KaftpayActionTone.error:
        return Icons.error_outline;
      case KaftpayActionTone.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    final t = KaftpayLang.t;
    final r = _result;
    final head = widget.destructive ? ui.error : ui.accent;

    Widget body;
    List<Widget> actions;
    switch (_phase) {
      case _Phase.confirm:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.details != null) widget.details!,
            if (widget.warning != null) ...[
              const SizedBox(height: 14),
              KaftpayBanner(
                  color: ui.warning,
                  icon: Icons.warning_amber_rounded,
                  text: widget.warning!),
            ],
          ],
        );
        actions = [
          TextButton(
            key: const ValueKey('kaftpay_action_cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t('Bekor qilish', 'Отмена')),
          ),
          FilledButton.icon(
            key: const ValueKey('kaftpay_action_confirm'),
            style: widget.destructive
                ? ui.primaryButton
                    .copyWith(backgroundColor: WidgetStatePropertyAll(ui.error))
                : null,
            onPressed: _go,
            icon: Icon(widget.confirmIcon ?? Icons.check_rounded, size: 20),
            label: Text(widget.confirmLabel ?? 'OK'),
          ),
        ];
        break;
      case _Phase.running:
        body = Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KaftpayIconBadge(widget.icon, color: head, size: 84),
              const SizedBox(height: 16),
              Text(widget.runningText ?? t('Bajarilmoqda...', 'Выполняется...'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(minHeight: 6),
              ),
            ],
          ),
        );
        actions = const [];
        break;
      case _Phase.done:
        final c = _toneColor(ui, r!.tone);
        body = Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KaftpayPop(
                  child:
                      KaftpayIconBadge(_toneIcon(r.tone), color: c, size: 84)),
              const SizedBox(height: 16),
              Text(r.title,
                  key: const ValueKey('kaftpay_action_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800)),
              if (r.message != null) ...[
                const SizedBox(height: 8),
                Text(r.message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ui.muted, fontSize: 14)),
              ],
              if (widget.details != null) ...[
                const SizedBox(height: 16),
                widget.details!,
              ],
            ],
          ),
        );
        actions = [
          FilledButton(
            key: const ValueKey('kaftpay_action_close'),
            onPressed: () => Navigator.of(context).pop(r),
            child: Text(t('Yopish', 'Закрыть')),
          ),
        ];
        break;
    }

    return ui.wrap(PopScope(
      canPop: false,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Row(
          children: [
            KaftpayIconBadge(widget.icon, color: head, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title),
                  if (widget.subtitle != null)
                    Text(widget.subtitle!,
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
          constraints: const BoxConstraints(minWidth: 420, maxWidth: 500),
          child: SingleChildScrollView(child: body),
        ),
        actions: actions,
      ),
    ));
  }
}

/// To'lov / vozvrat tafsilotlari kartasi: katta summa va qatorlar.
class KaftpayAmountCard extends StatelessWidget {
  const KaftpayAmountCard({
    super.key,
    required this.amount,
    this.rows = const [],
    this.color,
  });

  /// Formatlangan summa (`20,000 so'm`).
  final String amount;

  /// (nom, qiymat) juftlari.
  final List<MapEntry<String, String>> rows;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ui = KaftpayUi.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ui.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(amount,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color ?? ui.fg,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          if (rows.isNotEmpty) const SizedBox(height: 12),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(r.key, style: TextStyle(color: ui.muted, fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(r.value,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Natija ikonkasi uchun qisqa "pop" animatsiyasi.
class KaftpayPop extends StatelessWidget {
  const KaftpayPop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Transform.scale(scale: v, child: c),
      child: child,
    );
  }
}
