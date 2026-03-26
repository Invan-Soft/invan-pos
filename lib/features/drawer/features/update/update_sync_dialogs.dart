import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/drawer/features/update/sync/bloc/sync_bloc.dart';
import 'package:invan2/features/drawer/features/update/sync/components/sync_widgets.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

import '../../../../utils/l10n/app_localizations.dart';

class UpdateDialog {
  static showSyncDialogBloc(GlobalKey<ScaffoldState> scaffoldKey) async {
    AppLocalizations loc = AppLocalizations.of(scaffoldKey.currentContext!)!;

    await showCupertinoDialog(
      barrierDismissible: true,
      context: scaffoldKey.currentContext!,
      builder: (_) => Theme(
        data: ThemeData.dark(),
        child: BlocConsumer<SyncBloc, SyncState>(
          listener: (context, state) async {
          },
          builder: (context, state) {
            if (state is SyncLoadingState) {
              return CupertinoAlertDialog(
                content: Padding(
                  padding: EdgeInsets.all(SizeConfig.v * 5),
                  child: CupertinoActivityIndicator(
                    radius: SizeConfig.v * 2,
                  ),
                ),
              );
            }
            if (state is SyncDoneState) {
              if (state.updated.result) {
                if (state.updated.items.isEmpty) {
                  return SyncInfoWidget(loc.yangilangan_tovarlar_mavjud_emas);
                }

                return SyncInfoWidget(
                    "${state.updated.items.length} ${loc.ta_tovar_yangilandi}");
              }
              return SyncInfoWidget(loc.yangilanish_amalga_oshirilmadi);
            }

            if (state is SyncNoInternetState) {
              return SyncInfoWidget(loc.internet_yoq);
            }
            if (state is SyncInitialState) {
              return const SyncInitialWidget();
            }
            if (state is SyncFailedState) {
              return SyncInfoWidget("0 ${loc.ta_tovar_yangilandi}");
            }
            return const SizedBox();
          },
        ),
      ),
    );
    return;
  }
}
