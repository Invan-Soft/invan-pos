import 'package:flutter/material.dart';
import 'package:invan2/features/drawer/view/drawer.bottom.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'view/drawer_top.dart';
import 'view/drawer_content.dart';
import '../../changes/providers/drawer_provider.dart';
export '../../changes/providers/paging_provider.dart';
export 'model/model.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  bool switchh = false;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => DrawerProvider(),
      child: SizedBox(
        width: SizeConfig.h * 35,
        child: Drawer(
          backgroundColor: Theme.of(context).colorScheme.background,
          child: Column(
            children: [
              const DrawerTop(),
              DrawerContent(
                scaffoldKey: widget.scaffoldKey,
              ),
              const DrawerBottom(),
            ],
          ),
        ),
      ),
    );
  }
}
