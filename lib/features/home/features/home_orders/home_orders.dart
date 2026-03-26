import 'package:flutter/material.dart';
import 'order_list/order_list.dart';
import 'calculation_part/calculation_part.dart';

class HomeOrders extends StatefulWidget {
  const HomeOrders({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<HomeOrders> createState() => _HomeOrdersState();
}

class _HomeOrdersState extends State<HomeOrders> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
      ),
      child: Column(
        children: [
          const OrderList(),
          CalculationPart(scaffoldKey: widget.scaffoldKey),
        ],
      ),
    );
  }
}
