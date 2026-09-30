/*
    "Yangilanish tayyor" tugmasi — ish vaqtida Shorebird patch yuklangach
    (PatchUpdater.readyToRestart) yuqori panelda chiqadi.

    Dastur o'zi qayta yonmaydi: sotuv o'rtasida bu savatni yo'qotadi. Tugma
    faqat 6 ta mijoz savatining HAMMASI bo'sh bo'lganda ko'rinadi — bittasida
    ham mahsulot tursa yashirin, bo'shagan zahoti (OrderingProvider4
    notifyListeners) paydo bo'ladi.
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

        return Consumer<OrderingProvider4>(
          builder: (context, ordering, _) {
            final bool allCartsEmpty =
                ordering.getCurrentClient.orderedProducts.isEmpty &&
                    ordering.getSixClient4List
                        .every((c) => c.orderedProducts.isEmpty);
            if (!allCartsEmpty) return const SizedBox.shrink();

            final AppLocalizations? loc = AppLocalizations.of(context);
            final bool isUz = loc == null || loc.ha.toLowerCase() == 'ha';
            const Color green = Color(0xFF2E7D32);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 0.6),
              child: OutlinedButton.icon(
                focusNode: FocusNode(skipTraversal: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: green,
                  side: const BorderSide(color: green),
                  backgroundColor: const Color(0xFFE8F5E9),
                ),
                onPressed: PatchUpdater.restartNow,
                icon: Icon(Icons.system_update_alt,
                    size: SizeConfig.v * 2.4, color: green),
                label: Text(
                  isUz
                      ? 'Yangilanish tayyor — qayta ishga tushirish'
                      : 'Обновление готово — перезапустить',
                  style: MyThemes.txtStyle(fontSize: 1.8, color: green),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
