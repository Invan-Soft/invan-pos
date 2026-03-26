import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/drawer/features/update/sync/bloc/sync_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

import '../../../../../../utils/l10n/app_localizations.dart';

class SyncInfoWidget extends StatelessWidget {
  final String info;
  const SyncInfoWidget(this.info, {super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      content: Padding(
        padding: EdgeInsets.all(SizeConfig.v * 2),
        child: Text(
          info,
        ),
      ),
      actions: [
        CupertinoButton(
          child: const Text("OK",
            style: TextStyle(
              color: Colors.white,
            ),),
          onPressed: () => AppNavigation.pop(),
        ),
      ],
    );
  }
}

class SyncInitialWidget extends StatelessWidget {
  const SyncInitialWidget({super.key});

  @override
  Widget build(BuildContext context) {
    SyncBloc syncBloc = BlocProvider.of(context, listen: false);
    AppLocalizations loc = AppLocalizations.of(context)!;
    return CupertinoAlertDialog(
      content: Text(loc.sync_warning),
      actions: [
        CupertinoButton(
          child: Text(
            loc.yopish,
            style:
                MyThemes.txtStyle(fontSize: 2, color: MyThemes.textWhiteColor),
          ),
          onPressed: () => AppNavigation.pop(),
        ),
        CupertinoButton(
            child: Text(
              loc.yangilash,
              style: MyThemes.txtStyle(
                  fontSize: 2, color: MyThemes.textWhiteColor),
            ),
            onPressed: () {
              syncBloc.add(SyncSyncEvent());
            }),
      ],
    );
  }
}
