import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/upd/bloc/upd_bloc.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_text.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/upper_case_string_extention.dart';

import '../../../../utils/utils.dart';

class UpdInitialWidget extends StatelessWidget {
  const UpdInitialWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    UpdBloc updBloc = BlocProvider.of(context);
    final AppLocalizations loc = AppLocalizations.of(context)!;

    return CupertinoAlertDialog(
      title: UpdText(loc.sync_warning),
      actions: [
        CupertinoButton(
          child: UpdText(loc.yopish),
          onPressed: () => AppNavigation.pop(),
        ),
        CupertinoButton(
          child: UpdText(loc.yangilash),
          onPressed: () {
            updBloc.add(UpdStartEvent(false, statuss));
          },
        ),
      ],
    );
  }
}
