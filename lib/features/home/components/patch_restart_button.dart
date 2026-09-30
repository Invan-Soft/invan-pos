/*
    "Yangilanish tayyor" tugmasi — ish vaqtida Shorebird patch yuklangach
    (PatchUpdater.readyToRestart) yuqori panelda chiqadi.

    Dastur o'zi qayta yonmaydi: sotuv o'rtasida bu savatni yo'qotadi. Tugma
    faqat BARCHA mijoz savatlari bo'sh bo'lganda ishlaydi.
*/

import 'package:flutter/material.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/services/patch_updater.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

class PatchRestartButton extends StatelessWidget {
  const PatchRestartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PatchUpdater.readyToRestart,
      builder: (context, ready, _) {
        if (!ready) return const SizedBox.shrink();

        final AppLocalizations? loc = AppLocalizations.of(context);
        final bool isUz = loc == null || loc.ha.toLowerCase() == 'ha';

        return Consumer<OrderingProvider4>(
          builder: (context, ordering, _) {
            final bool cartEmpty =
                ordering.getCurrentClient.orderedProducts.isEmpty &&
                    ordering.getSixClient4List
                        .every((c) => c.orderedProducts.isEmpty);
            const Color green = Color(0xFF2E7D32);
            final Color color = cartEmpty ? green : Colors.grey;

            return Tooltip(
              message: cartEmpty
                  ? (isUz
                      ? 'Yangi versiya yuklandi. Bosing — dastur bir necha '
                          'soniyada qayta ochiladi.'
                      : 'Обновление загружено. Нажмите — программа '
                          'перезапустится за несколько секунд.')
                  : (isUz
                      ? 'Avval savatdagi sotuvni yakunlang.'
                      : 'Сначала завершите продажу в корзине.'),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 0.6),
                child: OutlinedButton.icon(
                  focusNode: FocusNode(skipTraversal: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    backgroundColor: cartEmpty
                        ? const Color(0xFFE8F5E9)
                        : Colors.transparent,
                  ),
                  onPressed: cartEmpty ? PatchUpdater.restartNow : null,
                  icon: Icon(Icons.system_update_alt,
                      size: SizeConfig.v * 2.4, color: color),
                  label: Text(
                    isUz
                        ? 'Yangilanish tayyor — qayta ishga tushirish'
                        : 'Обновление готово — перезапустить',
                    style: MyThemes.txtStyle(fontSize: 1.8, color: color),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
