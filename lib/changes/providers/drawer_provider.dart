// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/aditional_pages/report_page.dart';
import 'package:invan2/changes/dialogs/about/about_dialog.dart';
import 'package:invan2/changes/dialogs/upd/upd_dialog.dart';
import 'package:invan2/features/checks/checks_page.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/settings_page.dart';
import '../../features/drawer/features/features.dart';
import 'package:provider/provider.dart';
import '../../features/hive_repository/hive_boxes.dart';

class DrawerProvider extends ChangeNotifier {
  void pressDrawerItem(
    BuildContext context,
    DrawerItem item,
  ) async {
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
          if (employeeAccess?.stock ?? false) {
            if (currentPageId == DrawerItemId.home) {
              AppNavigation.push(const SettingsPage());
            } else {
              AppNavigation.pushReplacement(const SettingsPage());
            }
            pagingProvider.setCurrentPageId(DrawerItemId.settings);
          }
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
          blBloc.add(BlStatusChangedEvent(
              status: BLStatus.other,
              where: "lib/changes/providers/drawer_provider.dart   feedback"));
          await showDialog(
            context: context,
            builder: (_) => FeedBackDialogWidget(),
          );
          blBloc.add(BlStatusChangedEvent(
              status: BLStatus.home,
              where: "lib/changes/providers/drawer_provider.dart   feedback"));
          break;
        }
      case DrawerItemId.update:
        {
          blBloc.add(BlStatusChangedEvent(
              status: BLStatus.other,
              where: "lib/changes/providers/drawer_provider.dart   update"));
          await showCupertinoDialog(
            context: context,
            builder: (context) {
              return Theme(
                data: ThemeData.dark(),
                child: const UpdDialog(),
              );
            },
          );

          blBloc.add(BlStatusChangedEvent(
              status: BLStatus.home,
              where: "lib/changes/providers/drawer_provider.dart   update"));
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

      default:
        {
          ExitDialog.showMyDialog(context);
          break;
        }
    }
  }
}
