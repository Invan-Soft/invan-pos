import 'package:flutter/material.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/discount_percent.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/summa.dart';

import 'package:invan2/utils/helpers/size_config.dart';

class OperationCentr extends StatefulWidget {
  const OperationCentr({Key? key}) : super(key: key);

  @override
  OperationCentrState createState() => OperationCentrState();
}

class OperationCentrState extends State<OperationCentr> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 1.95),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiscountPercent(border: _border()),
              SummaInputOfOperationOnTotalPriceDialog(_border()),
            ],
          ),
        ),
      ),
    );
  }

  UnderlineInputBorder _border() {
    return UnderlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).canvasColor,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
