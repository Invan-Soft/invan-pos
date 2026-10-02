/*
    "Yangilanish tayyor" tugmasi — ish vaqtida Shorebird patch yuklangach
    (PatchUpdater.readyToRestart) yuqori panelda chiqadi.

    Dastur o'zi qayta yonmaydi: sotuv o'rtasida bu savatni yo'qotadi. Tugma
    faqat 6 ta mijoz savatining HAMMASI bo'sh bo'lganda ko'rinadi — bittasida
    ham mahsulot tursa yashirin, bo'shagan zahoti (OrderingProvider4
    notifyListeners) paydo bo'ladi.
*/

import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/services/patch_updater.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

/// Dastur yangilanish uchun o'zi qayta ochilgandan keyin birinchi ekranda
/// "Dastur yangilandi" xabari — oynaning bir zum yopilib-ochilishi kassirga
/// xato kabi ko'rinmasligi uchun.
///
/// runApp() dan keyin chaqiriladi. Birinchi sahifa chizilguncha bir necha
/// marta urinadi; `mySnackBar` ishlatilmaydi — u SizeConfig'ga bog'liq,
/// ilova endigina ochilganda u hali sozlanmagan bo'lishi mumkin.
void showPatchUpdatedMessage() {
  int attempts = 0;

  void tryShow() {
    attempts++;
    final BuildContext? context = AppNavigation.navigatorKey.currentContext;
    final ScaffoldMessengerState? messenger =
        context == null ? null : ScaffoldMessenger.maybeOf(context);
    if (context == null || messenger == null) {
      if (attempts < 10) {
        Future<void>.delayed(const Duration(seconds: 1), tryShow);
      }
      return;
    }
    final AppLocalizations? loc = AppLocalizations.of(context);
    final bool isUz = loc == null || loc.ha.toLowerCase() == 'ha';
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 420,
      backgroundColor: const Color(0xFF2E7D32),
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isUz ? 'Dastur yangilandi' : 'Программа обновлена',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ));
  }

  // Oyna ko'rinishi va birinchi sahifa chizilishi uchun biroz kutamiz.
  Future<void>.delayed(const Duration(seconds: 2), tryShow);
}

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
