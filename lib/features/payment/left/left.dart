import 'package:flutter/material.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';

import '../../../changes/models/organization_model.dart';
import '../../../changes/singletons/organization_singleton.dart';

class Left extends StatelessWidget {
  const Left({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final OrderingProvider4 orderingProcider4 =
        context.watch<OrderingProvider4>();
    final totalPrice = ItemsSingleton.getTotalPrice(
        orderingProcider4.getCurrentClient.orderedProducts);
    final mustPay = orderingProcider4.getMustPay;
    final payments = orderingProcider4.paymentsMap;
    final discountAmount = ItemsSingleton.getBaseTotalPrice(
            orderingProcider4.getCurrentClient.orderedProducts, false) -
        totalPrice;

    num cash = 0;
    num card = 0;
    num cardAmount = 0;
    payments.forEach(
      (key, value) {
        if (key == Pref.getString(PrefKeys.cashId, '')) {
          cash += value.value ?? 0;
        } else if (key == Pref.getString(PrefKeys.cardId, '')) {
          card += value.value ?? 0;
        } else if (key == Pref.getString(PrefKeys.cardId, '') ||
            key.replaceFirst('@', '') == Pref.getString(PrefKeys.cardId, '') ||
            key == Pref.getString(PrefKeys.clickId, '') ||
            key == Pref.getString(PrefKeys.uzumId, '')) {
          cardAmount += value.value ?? 0;
        }
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(SizeConfig.v),
        boxShadow: [
          BoxShadow(
            color: MyThemes.darkBgColor.withOpacity(.3),
            blurRadius: 3,
          ),
        ],
      ),
      child: Container(
        height: SizeConfig.v * 88,
        width: SizeConfig.h * 53.5,
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(SizeConfig.v),
        ),
        child: Column(
          children: [
            _top(loc, mustPay, context,
                context.watch<OrderingProvider4>().getCurrentClientIsNotNULL),
            _secondLayer(loc, card + cash, totalPrice, cardAmount,
                discountAmount, context),
            _headOfPaymentList(loc, context),
            _paymentList(payments, loc, context),
            const Spacer(flex: 1),
            _bottomButtons(context)
          ],
        ),
      ),
    );
  }

  _paymentList(Map<String, Payment> paymentMap, AppLocalizations loc,
      BuildContext context) {
    return paymentMap.isEmpty
        ? const SizedBox()
        : Expanded(
            flex: 9,
            child: ListView.builder(
              itemCount: paymentMap.length,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (_, index) {
                return TextButton(
                  focusNode: FocusNode(skipTraversal: true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(0.0),
                    elevation: 0,
                  ),
                  onPressed: () => context
                      .read<OrderingProvider4>()
                      .selectPaymentIndex(index),
                  child: _payment(
                      rangeNumber: "${index + 1}",
                      text1: getPaymentName(paymentMap.keys.toList()[index],
                          loc, paymentMap.values.toList()[index].type ?? 0),
                      text2: MoneyFormatter.inputMoneyFormatter.format(
                          double.parse(
                              (paymentMap.values.toList()[index].value ?? 0)
                                  .toStringAsFixed(2))),
                      selected: context
                              .watch<OrderingProvider4>()
                              .selectedPaymentIndex ==
                          index,
                      con: context),
                );
              },
            ),
          );
  }

  Container _bottomButtons(BuildContext context) {
    bool empty = context.watch<OrderingProvider4>().paymentsMap.isEmpty;
    return Container(
      height: SizeConfig.v * 9,
      decoration: BoxDecoration(
          border: Border(
              top:
                  BorderSide(color: Theme.of(context).canvasColor, width: .5))),
      child: Row(
        children: [
          Expanded(
            flex: 84,
            child: MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              minWidth: double.infinity,
              height: double.infinity,
              onPressed: empty
                  ? null
                  : () =>
                      context.read<OrderingProvider4>().removeFromPaymentList(),
              child: Icon(
                Icons.clear,
                color: empty
                    ? Colors.grey.shade700
                    : Theme.of(context).canvasColor,
                size: SizeConfig.v * 3.6,
              ),
            ),
          ),
          _vertDivider(context),
          const Spacer(
            flex: 245,
          ),
          _vertDivider(context),
          Expanded(
            flex: 92,
            child: MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              minWidth: double.infinity,
              height: double.infinity,
              onPressed: empty
                  ? null
                  : () => context
                      .read<OrderingProvider4>()
                      .changeTheSelectedPaymentIndex(false),
              child: Icon(
                Icons.expand_more,
                color: empty
                    ? Colors.grey.shade700
                    : Theme.of(context).canvasColor,
                size: SizeConfig.v * 4.6,
              ),
            ),
          ),
          _vertDivider(context),
          Expanded(
            flex: 92,
            child: MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              minWidth: double.infinity,
              height: double.infinity,
              onPressed: empty
                  ? null
                  : () => context
                      .read<OrderingProvider4>()
                      .changeTheSelectedPaymentIndex(true),
              child: Icon(
                Icons.expand_less,
                color: empty
                    ? Colors.grey.shade700
                    : Theme.of(context).canvasColor,
                size: SizeConfig.v * 4.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SizedBox _secondLayer(AppLocalizations loc, paid, num totalPrice,
      num cardAmount, num discountAmount, BuildContext context) {
    return SizedBox(
      height: SizeConfig.v * 9,
      child: Row(
        children: [
          _secondLayerExpanded(
              127,
              loc.karta,
              MoneyFormatter.inputMoneyFormatter
                  .format(double.parse(cardAmount.toStringAsFixed(0))),
              context),
          _vertDivider(context),
          _secondLayerExpanded(
              127, loc.jami, paid == 0 ? "_" : paid.toString(), context),
          _vertDivider(context),
          _secondLayerExpanded(
              127,
              loc.chegirma,
              discountAmount > 0 ? discountAmount.toStringAsFixed(2) : "0",
              context),
          _vertDivider(context),
          _secondLayerExpanded(
              127, loc.tolash, totalPrice.toStringAsFixed(2), context),
        ],
      ),
    );
  }

  VerticalDivider _vertDivider(BuildContext con) =>
      VerticalDivider(color: Theme.of(con).canvasColor, thickness: .5);

  Expanded _secondLayerExpanded(
      int flex, String title, String subtitle, BuildContext con) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.only(
            left: SizeConfig.v, top: SizeConfig.v, bottom: SizeConfig.v * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: MyThemes.txtStyle(
                color: Theme.of(con).canvasColor,
                fontSize: 1.82,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              subtitle,
              style: MyThemes.txtStyle(
                color: Theme.of(con).canvasColor,
                fontSize: 1.82,
                fontWeight: FontWeight.w400,
              ),
            )
          ],
        ),
      ),
    );
  }

  Container _top(AppLocalizations loc, double mustPay, BuildContext context,
      bool clientSelected) {
    bool isChangeToCashback =
        context.watch<OrderingProvider4>().isChangeToCashback;
    return Container(
      height: SizeConfig.v * 11.45,
      decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: Theme.of(context).canvasColor, width: .5))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 1.75),
              child: TextButton(
                focusNode: FocusNode(skipTraversal: true),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(0.0),
                    foregroundColor: Theme.of(context).dialogBackgroundColor),
                onPressed: () {},
                // onPressed: () =>
                //     Provider.of<OrderingProvider4>(context, listen: false)
                //         .switchIsChangeToCashback(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mustPay >= 0 ? loc.qoldi : loc.qaytim,
                        style: MyThemes.txtStyle(
                            fontSize: 4.16,
                            color: Theme.of(context).canvasColor)),
                    Row(
                      children: [
                        Text(
                          MoneyFormatter.formatter.format(mustPay),
                          style: MyThemes.txtStyle(
                              fontSize: 4.16,
                              color: Theme.of(context).canvasColor),
                        ),
                        SizedBox(width: SizeConfig.h),
                        // clientSelected && mustPay < 0
                        //     ? Image.asset(
                        //         isChangeToCashback
                        //             ? "assets/images/saveCoin.png"
                        //             : "assets/images/lock.png",
                        //         color: Theme.of(context).canvasColor,
                        //       )
                        //     : const SizedBox(),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          Provider.of<OrderingProvider4>(context, listen: false)
                  .getCurrentClientIsNotNULL
              ? Column(
                  children: [
                    Divider(
                        color: Theme.of(context).canvasColor, thickness: .5),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: SizeConfig.v,
                          right: SizeConfig.h * 1.75,
                          left: SizeConfig.h * 1.75),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _textInRow(
                              text1: "${loc.mijoz}:    ",
                              text2:
                                  "${context.watch<OrderingProvider4>().getClientFirstname} ${context.watch<OrderingProvider4>().getClientLastName}",
                              context: context),
                          _textInRow(
                              text1: "${loc.balans}:",
                              text2: MoneyFormatter.inputMoneyFormatter.format(
                                context
                                    .watch<OrderingProvider4>()
                                    .getClientPointBalance,
                              ),
                              context: context),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox(
                  height: 1.0,
                  width: 1.0,
                ),
        ],
      ),
    );
  }

  _payment(
      {required String rangeNumber,
      required String text1,
      required String text2,
      required bool selected,
      required BuildContext con}) {
    TextStyle textStyle = MyThemes.txtStyle(
      color: Theme.of(con).canvasColor,
      fontSize: 3.12,
      fontWeight: FontWeight.w500,
    );

    return Container(
      height: SizeConfig.v * 5,
      color: selected
          ? Theme.of(con).primaryColor
          : Theme.of(con).dialogBackgroundColor,
      padding: EdgeInsets.only(right: SizeConfig.h * 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: 54,
              child: Text(rangeNumber,
                  textAlign: TextAlign.center, style: textStyle)),
          Expanded(
            flex: 480,
            child: Padding(
              padding: EdgeInsets.only(left: SizeConfig.h),
              child: Text(text1, style: textStyle),
            ),
          ),
          Expanded(
            flex: 281,
            child: Text(
              text2,
              textAlign: TextAlign.end,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  Container _headOfPaymentList(AppLocalizations loc, BuildContext context) {
    TextStyle topStyle = MyThemes.txtStyle(
        fontSize: 2.34,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).canvasColor);
    return Container(
      height: SizeConfig.v * 5.17,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).canvasColor, width: .5),
          bottom: BorderSide(color: Theme.of(context).canvasColor, width: .3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 54,
            child: Text(
              "№",
              textAlign: TextAlign.center,
              style: topStyle,
            ),
          ),
          VerticalDivider(
            width: 0.5,
            color: Theme.of(context).dividerColor,
            thickness: .4,
          ),
          Expanded(
            flex: 480,
            child: Padding(
              padding: EdgeInsets.only(left: SizeConfig.h),
              child: Text(loc.tolov_turi, style: topStyle),
            ),
          ),
          VerticalDivider(color: Theme.of(context).dividerColor, thickness: .4),
          Expanded(
            flex: 281,
            child: Padding(
              padding: EdgeInsets.only(right: SizeConfig.h * 1.5),
              child: Text(loc.summa, textAlign: TextAlign.end, style: topStyle),
            ),
          ),
        ],
      ),
    );
  }

  _textInRow({
    required String text1,
    required String text2,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          text1,
          style: MyThemes.txtStyle(
            fontStyle: FontStyle.italic,
            fontSize: 2.56,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).dividerColor,
          ),
        ),
        SizedBox(width: SizeConfig.h * 3),
        Text(
          text2,
          style: MyThemes.txtStyle(
            fontStyle: FontStyle.italic,
            fontSize: 2.56,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).canvasColor,
          ),
        ),
      ],
    );
  }

  String getPaymentName(
    String id,
    AppLocalizations loc,
    int type,
  ) {
    for (Payment p in otherPaymentsGlobal) {
      if (p.id == id.replaceFirst('@', '')) {
        if (p.id == Pref.getString(PrefKeys.cardId, "")) {
          return type == 1 ? 'HUMO' : 'UZCARD';
        } else if (p.id == Pref.getString(PrefKeys.clickId, "")) {
          return type == 1 ? 'CLICK QR' : 'CLICK PASS';
        } else if (p.id == Pref.getString(PrefKeys.uzumId, "")) {
          return type == 1 ? 'UZUM QR' : 'UZUM';
        } else if (p.id == Pref.getString(PrefKeys.paymeId, "")) {
          return type == 1 ? 'PAYME QR' : 'PAYME GO';
        } else {
          return p.name ?? 'NFC';
        }
      }
    }
    return 'NFC';
  }
}
