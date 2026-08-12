import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/components/logo_widget.dart';

import '../../../app_navigation.dart';
import '../../../changes/services/sync/catch_up_sync.dart';
import '../../../utils/utils.dart';
import '../../features.dart';
import '../bloc/home_bloc/home_bloc.dart';

class SyncButtonHome extends StatefulWidget {
  const SyncButtonHome({
    super.key,
  });

  @override
  State<SyncButtonHome> createState() => _SyncButtonHomeState();
}

class _SyncButtonHomeState extends State<SyncButtonHome> {
  void startPeriodicRequest() async {
    AppLocalizations loc = AppLocalizations.of(context)!;
    final homeBloc = context.read<HomeBloc>();

    showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          content: Text(
            loc.ha == 'Ha'
                ? 'Oxirgi o\'zgarishlarni olish.'
                : 'Получите последние изменения.',
            style: MyThemes.txtStyle(
                fontSize: 2.2, color: MyThemes.textWhiteColor),
          ),
          actions: [
            CupertinoButton(
              child: Text(
                loc.yopish,
                style: MyThemes.txtStyle(
                    fontSize: 2, color: MyThemes.textWhiteColor),
              ),
              onPressed: () => AppNavigation.pop(),
            ),
            CupertinoButton(
              child: Text(
                loc.yangilash,
                style: MyThemes.txtStyle(
                    fontSize: 2, color: MyThemes.textWhiteColor),
              ),
              onPressed: () async {
                AppNavigation.pop();
                _showLoadingDialog(loc);
                if (mounted) {
                  // Oyna hisobi CatchUpSync ichida — kursordan hozirgacha
                  // bo'lgan hamma narsa olinadi.
                  await CatchUpSync.run(context, mounted,
                      reason: 'manual', force: true);

                  AppNavigation.pop();
                  homeBloc.add(HomeSyncEvent());
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog(AppLocalizations loc) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          content: Column(
            children: [
              const CupertinoActivityIndicator(radius: 15),
              const SizedBox(height: 10),
              Text(
                loc.ha == 'Ha' ? 'Yuklanmoqda...' : 'Загрузка...',
                style: MyThemes.txtStyle(
                    fontSize: 2.2, color: MyThemes.textWhiteColor),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: FocusNode(skipTraversal: true),
      onTap: () => startPeriodicRequest(),
      child: LogoInvanWidget(
        width: SizeConfig.h * 9.74,
      ),
    );
  }
}
