import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/aditional_pages/shift_opened_page.dart';
import 'package:invan2/changes/bloc/network/network_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/bottom_layer_of_home_page.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';
import 'package:invan2/features/report/features/report_app_bar/report_app_bar.dart';
import 'package:invan2/features/report/features/shifts_closed/shifts_closed.dart';
import 'package:provider/provider.dart';

import '../../utils/utils.dart';
import '../../widgets/alice_pincode.dart';

class ReportPage extends StatefulWidget {
  final bool isZet;

  const ReportPage({required this.isZet, super.key});

  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late NetworkBloc networkBloc;

  @override
  void initState() {
    networkBloc = BlocProvider.of(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AccessBloc lockBloc = BlocProvider.of(context, listen: false);
    final openShiftProvider = Provider.of<OpenShiftProvider>(context);
    final isShiftOpened = openShiftProvider.getIsShiftOpened;
    AppLocalizations loc = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Pref.getBool(PrefKeys.isDevAlice, false)
            ? FloatingActionButton(
                heroTag: null,
                backgroundColor: Theme.of(context).primaryColor,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlicePincodePage(),
                  );
                },
                child: const Icon(
                  Icons.http_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              )
            : const SizedBox(),
        backgroundColor: Theme.of(context).colorScheme.background,
        key: _scaffoldKey,
        endDrawer: MyDrawer(scaffoldKey: _scaffoldKey),
        body: Column(
          children: [
            ReportAppBarr(
              scaffoldKey: _scaffoldKey,
              pressLockButton: () {
                lockBloc.add(AccessSwitchToAccessEvent());
                AppNavigation.pushAndRemoveUntil(const AccessLevelPage());
              },
              pressPrinterButton: () async {
                final shift = ShiftSingleton4.getCurrentHiveShift();
                if (shift != null) {
                  PrintingMethods.printSmena(
                    shift: shift,
                    loc: loc,
                    isZ: widget.isZet,
                  );
                }
              },
              isPrinter: !isShiftOpened ? false : true,
            ),
            BlocListener<NetworkBloc, NetworkState>(
              listener: (context, state) async {
                if (state is NetworkFailure) {
                  await Future.delayed(const Duration(seconds: 1));
                  networkBloc.add(NetworkNoEvent());
                }
              },
              child: Expanded(
                child: isShiftOpened
                    ? ShiftsOpenedPage(isZet: widget.isZet)
                    : const ShiftsClosed(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(
                      -1,
                      -2,
                    ),
                    blurRadius: .1,
                    color: Theme.of(context).colorScheme.background,
                  ),
                ],
              ),
              child: const BottomLayerOfHomePage(),
            ),
          ],
        ),
      ),
    );
  }
}
