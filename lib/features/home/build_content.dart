import 'package:flutter/material.dart';
import 'package:invan2/features/home/features/home_orders/home_orders.dart';
import 'package:invan2/features/home/features/home_products/home_products.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/bottom_layer_of_home_page.dart';

class BuildContentOfHomePage extends StatelessWidget {
  final int leftFlex;
  final int rightFlex;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const BuildContentOfHomePage({
    required this.leftFlex,
    required this.rightFlex,
    required this.scaffoldKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: leftFlex,
                child: HomeOrders(scaffoldKey: scaffoldKey),
              ),
              const VerticalDivider(
                color: Colors.black38,
                width: 2,
              ),
              Expanded(
                flex: rightFlex,
                child: HomeProducts(scaffoldKey: scaffoldKey),
              ),
            ],
          ),
        ),
        const BottomLayerOfHomePage(),
      ],
    );
  }
}
