import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';
import '../../changes/aditional_pages/report_page.dart';
import '../../changes/providers/rule_cash_provider.dart';
import 'package:invan2/utils/utils.dart';
import 'left/left.dart';
import 'right/right.dart';

// ignore: must_be_immutable
class RuleCashPage extends StatelessWidget {
  final bool isZet;
  RuleCashPage({required this.isZet, super.key});

  static CupertinoPageRoute route({required bool isZet}) => CupertinoPageRoute(
      builder: (_) => RuleCashPage(
            isZet: isZet,
          ));
  late BuildContext con;
  @override
  Widget build(BuildContext context) {
    con = context;
    AppLocalizations loc = AppLocalizations.of(context)!;
    return ChangeNotifierProvider(
      create: (BuildContext context) => RuleCashProvider(),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: _appBar(context, loc),
          backgroundColor: Theme.of(context).colorScheme.background,
          body: Row(
            children: [
              Expanded(
                flex: 4,
                child: buildCard(const Left()),
              ),
              Expanded(
                flex: 5,
                child: buildCard(const Right()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context, AppLocalizations loc) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.background,
      automaticallyImplyLeading: false,
      toolbarHeight: SizeConfig.v * 9.5,
      leading: MaterialButton(
        focusNode: FocusNode(skipTraversal: true),
        height: double.infinity,
        minWidth: SizeConfig.v * 9.5,
        color: Theme.of(context).colorScheme.background,
        onPressed: () {
          AppNavigation.pushReplacement(ReportPage(isZet: isZet));
        },
        elevation: 0,
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_outlined,
            size: SizeConfig.v * 4,
            color: Theme.of(context).canvasColor,
          ),
        ),
      ),
      title: Text(
        loc.naqdPulniBoshqarish,
        style: MyThemes.txtStyle(
          color: Theme.of(context).canvasColor,
          fontSize: 3,
        ),
      ),
    );
  }

  Widget buildCard(Widget child) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.v * 4),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(con).bottomAppBarTheme.color,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(con).canvasColor,
              blurRadius: 3.0,
              offset: const Offset(1.0, 1.0),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
