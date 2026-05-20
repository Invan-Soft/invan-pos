import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/aditional_pages/report_page.dart';
import 'package:invan2/changes/dialogs/about/about_dialog.dart';
import 'package:invan2/changes/dialogs/upd/upd_dialog.dart';
import 'package:invan2/features/checks/checks_page.dart';
import 'package:invan2/features/drawer/features/features.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:invan2/utils/utils.dart';

import '../../../utils/upgrade/update_checker.dart';

class DrawerListTile extends StatelessWidget {
  final DrawerItem item;

  const DrawerListTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: Colors.grey.shade600,
        size: SizeConfig.v * 3,
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: SizeConfig.v,
        horizontal: SizeConfig.h * 2,
      ),
      title: Text(
        item.text,
        style: MyThemes.txtStyle(
          color: Theme.of(context).canvasColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () async {
        AppNavigation.pop();

        BlBloc blBloc = BlocProvider.of(context, listen: false);
        EmployeeAccess? employeeAccess = HiveBoxes.getCurrentEmployee?.access;
        final PagingProvider pagingProvider =
            Provider.of<PagingProvider>(context, listen: false);
        final currentPageId = pagingProvider.getCurrentPageId;

        switch (item.id) {
          case DrawerItemId.home:
            {
              if (currentPageId != DrawerItemId.home) {
                pagingProvider.setCurrentPageId(DrawerItemId.home);
                AppNavigation.pop();
              }
              break;
            }
          case DrawerItemId.settings:
            {
              if (currentPageId == DrawerItemId.home) {
                AppNavigation.push(const SettingsPage());
              } else {
                AppNavigation.pushReplacement(const SettingsPage());
              }
              pagingProvider.setCurrentPageId(DrawerItemId.settings);
              break;
            }
          case DrawerItemId.report:
            {
              if (currentPageId == DrawerItemId.home) {
                AppNavigation.push(const ReportPage(isZet: true));
              } else if (currentPageId != DrawerItemId.report) {
                AppNavigation.pushReplacement(const ReportPage(isZet: true));
              }
              pagingProvider.setCurrentPageId(DrawerItemId.report);
              break;
            }
          case DrawerItemId.checks:
            {
              if (employeeAccess?.receiptHistory ?? false) {
                if (currentPageId == DrawerItemId.home) {
                  AppNavigation.push(const ChecksPage());
                } else if (currentPageId != DrawerItemId.checks) {
                  AppNavigation.pushReplacement(const ChecksPage());
                  pagingProvider.setCurrentPageId(DrawerItemId.checks);
                }
              }
              break;
            }
          case DrawerItemId.feedback:
            {
              blBloc.add(
                BlStatusChangedEvent(
                  status: BLStatus.other,
                  where: "lib/changes/providers/drawer_provider.dart feedback",
                ),
              );
              await showDialog(
                context: context,
                builder: (_) => FeedBackDialogWidget(),
              );
              blBloc.add(
                BlStatusChangedEvent(
                  status: BLStatus.home,
                  where: "lib/changes/providers/drawer_provider.dart feedback",
                ),
              );
              break;
            }
          case DrawerItemId.update:
            {
              blBloc.add(
                BlStatusChangedEvent(
                  status: BLStatus.other,
                  where: "lib/changes/providers/drawer_provider.dart update",
                ),
              );
              await showCupertinoDialog(
                context: context,
                builder: (context) {
                  return Theme(
                    data: ThemeData.dark(),
                    child: const UpdDialog(),
                  );
                },
              );

              blBloc.add(
                BlStatusChangedEvent(
                  status: BLStatus.home,
                  where: "lib/changes/providers/drawer_provider.dart update",
                ),
              );
              break;
            }

          /*case DrawerItemId.log:
            AppNavigation.push(const LogsScreen());
            break;*/
          case DrawerItemId.about:
            {
              await showDialog(
                context: context,
                builder: (_) => AboutAppDialog(),
              );
              break;
            }

          case DrawerItemId.version:
            {
              blBloc.add(
                BlStatusChangedEvent(
                  status: BLStatus.other,
                  where: "lib/changes/providers/drawer_provider.dart update",
                ),
              );

              await UpdateChecker().checkForUpdate(AppNavigation.navigatorKey.currentContext!);

              blBloc.add(
                BlStatusChangedEvent(
                  status: BLStatus.home,
                  where: "lib/changes/providers/drawer_provider.dart update",
                ),
              );
              break;
            }

          default:
            {
              ExitDialog.showMyDialog(context);
              break;
            }
        }
      },
    );
  }
}
