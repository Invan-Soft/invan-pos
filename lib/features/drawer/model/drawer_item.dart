import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

import '../../../utils/l10n/app_localizations.dart';

enum DrawerItemId {
  home,
  settings,
  feedback,
  exit,
  checks,
  report,
  update,
  log,
  about,
  version
}

class DrawerItem {
  final DrawerItemId id;
  final String text;
  final IconData icon;

  const DrawerItem({
    required this.id,
    required this.text,
    required this.icon,
  });

  static List<DrawerItem> drawerList(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      DrawerItem(
        id: DrawerItemId.settings,
        text: loc.sozlamalar,
        icon: Icons.settings,
      ),
      DrawerItem(
        id: DrawerItemId.feedback,
        text: loc.izohJonatish,
        icon: Icons.chat,
      ),
      DrawerItem(
        id: DrawerItemId.update,
        text: loc.yangilash,
        icon: Icons.sync,
      ),
      /*const DrawerItem(
        id: DrawerItemId.log,
        text: 'Logs',
        icon: Icons.error,
      ),*/
      // if (openShift)
      //   DrawerItem(
      //     id: DrawerItemId.checks,
      //     text: loc.cheklar,
      //     icon: Icons.insert_drive_file,
      //   ),
      DrawerItem(
        id: DrawerItemId.exit,
        text: loc.chiqish,
        icon: Icons.exit_to_app,
      ),
      DrawerItem(
        id: DrawerItemId.about,
        text: loc.dastur_haqida,
        icon: Icons.info_outlined,
      ),
      DrawerItem(
        id: DrawerItemId.version,
        text: loc.ha.toLowerCase() == 'ha' ? 'Yangilanish' : 'Обновление',
        icon: Icons.new_releases,
      ),
    ];
  }
}
