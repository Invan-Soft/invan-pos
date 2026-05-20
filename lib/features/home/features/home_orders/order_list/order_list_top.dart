import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/features/home_orders/order_list/text_widget.dart';
import 'package:invan2/utils/utils.dart';

// ignore: must_be_immutable
class OrderListTop extends StatelessWidget {
  OrderListTop({Key? key}) : super(key: key);
  late TextStyle stl;
  late BuildContext con;
  @override
  Widget build(BuildContext context) {
    con = context;
    stl = MyThemes.txtStyle(
      fontSize: 1.6,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).canvasColor,
    );
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      height: SizeConfig.v * 5.17,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          boxShadow: [
            BoxShadow(blurRadius: 4, color: Theme.of(context).highlightColor)
          ]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: Flexes.order,
              child: Text("№", textAlign: TextAlign.center, style: stl)),
          _verticalDivider(),
          SoldItemWidget(
              flex: Flexes.name, title: loc.nomi,),
          _verticalDivider(),
          SoldItemWidget(
              flex: Flexes.price, title: loc.narxi, ),
          _verticalDivider(),
          SoldItemWidget(
              flex: Flexes.number, title: loc.miqdor),
          _verticalDivider(),
          SoldItemWidget(
              flex: 3,
              title: loc.chegirma,
             ),
          _verticalDivider(),
          SoldItemWidget(
              flex: 5, title: loc.summa, )
        ],
      ),
    );
  }

  _verticalDivider() => VerticalDivider(
        width: 3,
        thickness: 2,
        color: Theme.of(con).dialogBackgroundColor,
      );
}

class Flexes {
  static int get order => 2;
  static int get name => 15;
  static int get price => 5;
  static int get number => 4;
  static int get discount => 3;
  static int get summ => 6;
}
