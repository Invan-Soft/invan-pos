// Terminal (Arcus) xato dialogi.
//
// OrderingProvider4 dan ajratildi (2026-08-06) — tana o'zgartirilmadi.
// Bu sof UI: provider holatiga umuman tegmaydi, faqat matnni
// `TerminalReceiptParser` orqali tushunarli xabarga o'giradi.

import 'package:flutter/material.dart';
import 'package:invan2/changes/domain/terminal/terminal_receipt_parser.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

/// Terminaldan xato javob kelganda tushunarli showDialog ko'rsatadi.
/// [log] — Arcus log fayli, [receipt] — cheq.out chek matni.
Future<void> showTerminalErrorDialog(
BuildContext context, {
  required String log,
  required String receipt,
}) {
  final loc = AppLocalizations.of(context)!;
  final bool isUz = loc.ha.toLowerCase() == 'ha';

  final String friendly = TerminalReceiptParser.terminalErrorMessage(log, receipt, isUz);
  final String title = isUz ? "To'lov amalga oshmadi" : "Платёж не выполнен";
  final String message = friendly.isNotEmpty
      ? friendly
      : (isUz
          ? "To'lov amalga oshmadi. Iltimos qayta urinib ko'ring yoki terminalni tekshiring."
          : "Платёж не выполнен. Повторите попытку или проверьте терминал.");

  // Terminalning to'liq javobi: chek matni bo'lsa uni, aks holda logni ko'rsatamiz
  final String rawSource = receipt.trim().isNotEmpty ? receipt : log;
  final String rawDetails = rawSource
      .split('\n')
      .map((e) => e.trimRight())
      .where((e) => e.trim().isNotEmpty)
      .join('\n')
      .trim();

  const Color danger = Color(0xFFF04438);

  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (ctx) {
      final bool isDark = Theme.of(ctx).brightness == Brightness.dark;
      final Color surface = isDark ? const Color(0xFF212D3B) : Colors.white;
      final Color onSurface =
          isDark ? const Color(0xFFECEFF3) : const Color(0xFF101920);
      final Color subtle = onSurface.withOpacity(0.62);
      final Color fillSubtle = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.035);

      return Dialog(
        backgroundColor: surface,
        elevation: 16,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sarlavha: ikonka + matn ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: danger.withOpacity(0.13),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.priority_high_rounded,
                        color: danger,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Asosiy xabar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.4,
                    color: subtle,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // ── Batafsil (terminal javobi) ──
              if (rawDetails.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: fillSubtle,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(ctx)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        iconColor: subtle,
                        collapsedIconColor: subtle,
                        leading: Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: subtle,
                        ),
                        title: Text(
                          isUz
                              ? "Batafsil (terminal javobi)"
                              : "Подробнее (ответ терминала)",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: onSurface.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.22)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: onSurface.withOpacity(0.10),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                rawDetails,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.45,
                                  color: subtle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // ── Amal tugmasi ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(isUz ? "Yopish" : "Закрыть"),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
