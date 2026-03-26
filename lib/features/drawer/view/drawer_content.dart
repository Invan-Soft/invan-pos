import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'drawer_list_tile.dart';

class DrawerContent extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const DrawerContent({required this.scaffoldKey, super.key});

  @override
  Widget build(BuildContext context) {
    final list = DrawerItem.drawerList(context);

    return Expanded(
      child: ListView.builder(
        itemCount: list.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) => DrawerListTile(item: list[index]),
      ),
    );
  }
}
