import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class DrawerTop extends StatefulWidget {
  const DrawerTop({
    Key? key,
  }) : super(key: key);

  @override
  State<DrawerTop> createState() => _DrawerTopState();
}

class _DrawerTopState extends State<DrawerTop> {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.h * 2,
        vertical: SizeConfig.v,
      ),
      color: Theme.of(context).dialogBackgroundColor,
      height: SizeConfig.v * 22,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Pref.getString(PrefKeys.cashierName, "not initialized"),
            style: MyThemes.txtStyle(
              fontSize: 5,
              color: Theme.of(context).canvasColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            Pref.getString(PrefKeys.storeName, "not initialized"),
            style: MyThemes.txtStyle(
              fontSize: 2,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            Pref.getString(PrefKeys.posName, "not initialized"),
            style: MyThemes.txtStyle(
              fontSize: 2,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          
        ],
      ),
    );
  }
}
