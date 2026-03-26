import 'package:flutter/cupertino.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_text.dart';
import 'package:invan2/features/features.dart';

class UpdAllDoneWidget extends StatelessWidget {
  const UpdAllDoneWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return CupertinoAlertDialog(
      title: UpdText(loc.yuklanishlar_muvaffaqiyatli_yakunlandi),
      actions: [
        CupertinoButton(
          child: UpdText(
            "Ok",
          ),
          onPressed: () => AppNavigation.pop(),
        ),
      ],
    );
  }
}
