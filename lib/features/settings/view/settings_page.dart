import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/home/home_page.dart';
import 'package:invan2/features/settings/bloc/settings_bloc.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:invan2/features/features.dart';
import 'settings_content.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static CupertinoPageRoute route() =>
      CupertinoPageRoute(builder: (_) => const SettingsPage());

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 3,
        backgroundColor: Theme.of(context).colorScheme.background,
        leadingWidth: SizeConfig.h * 5,
        toolbarHeight: SizeConfig.v * 9.5,
        leading: Padding(
          padding: EdgeInsets.all(SizeConfig.v),
          child: TextButton(
            focusNode: FocusNode(skipTraversal: true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.background,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_outlined,
                  size: SizeConfig.v * 4,
                  color: Theme.of(context).canvasColor,
                ),
              ],
            ),
            onPressed: () {
              Provider.of<PagingProvider>(context, listen: false)
                  .setCurrentPageId(DrawerItemId.home);
              AppNavigation.pop();
            },
          ),
        ),
        title: SizedBox(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.only(left: SizeConfig.h * 2),
                child: Text(
                  loc.sozlamalar,
                  style: MyThemes.txtStyle(
                    color: Theme.of(context).canvasColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 3.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocProvider(
        create: (context) => SettingsBloc(0),
        child: const SettingsContent(),
      ),
    );
  }
}
