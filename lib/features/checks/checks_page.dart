// ignore_for_file: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/checks/features/checks_app_bar/view/checks_app_bar.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';
import '../../utils/utils.dart';
import 'features/features.dart';
import 'package:invan2/features/features.dart';

class ChecksPage extends StatefulWidget {
  const ChecksPage({super.key});

  static CupertinoPageRoute route() =>
      CupertinoPageRoute(builder: (_) => const ChecksPage());

  @override
  ChecksPageState createState() => ChecksPageState();
}

class ChecksPageState extends State<ChecksPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final AccessBloc lockBlocc = BlocProvider.of(context, listen: false);
    final BlBloc blBloc = BlocProvider.of(context);
    final CheckFBloc checkFBloc = BlocProvider.of(context);
    blBloc.add(BlStatusChangedEvent(
        status: BLStatus.other,
        where: "lib/features/checks/checks_page.dart build"));
    return WillPopScope(
      onWillPop: () async {
        blBloc.add(BlStatusChangedEvent(
            status: BLStatus.home,
            where: "lib/features/checks/checks_page.dart willpopscope"));
        return Future.value(true);
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Pref.getBool(PrefKeys.isDevAlice, false) && kDebugMode
            ? FloatingActionButton(
                heroTag: null,
                backgroundColor: Theme.of(context).primaryColor,
                onPressed: () {
                  AppNavigation.showAliceInspector();
                },
                child: const Icon(
                  Icons.http_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              )
            : const SizedBox(),
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          shadowColor: Colors.black,
          elevation: 4,
          toolbarHeight: SizeConfig.v * 9.5,
          actions: [
            ChecksAppBarr(
              pressLockButton: () {
                lockBlocc.add(AccessSwitchToAccessEvent());
                AppNavigation.pushAndRemoveUntil(const AccessLevelPage());
              },
            ),
          ],
        ),
        key: _scaffoldKey,
        endDrawer: MyDrawer(scaffoldKey: _scaffoldKey),
        body: Container(
          color: Theme.of(context).colorScheme.background,
          child: Row(
            children: [
              Builder(
                builder: (context) {
                  checkFBloc.add(CheckFCallInitialEvent());
                  return const Expanded(
                    flex: 4,
                    child: ChecksListt(),
                  );
                },
              ),
              const Expanded(
                flex: 9,
                child: CheckView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
