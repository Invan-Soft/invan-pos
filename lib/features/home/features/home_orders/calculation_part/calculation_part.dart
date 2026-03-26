// ignore_for_file: use_build_context_synchronously, unnecessary_cast
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/dialogs/mxik/mxik_error_message.dart';
import 'package:invan2/changes/dialogs/printer_not_selected_dialog.dart';
import 'package:invan2/changes/models/ofd/incom_response_model.dart';
import 'package:invan2/changes/services/invoices_service.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/home/bloc/invoice/invoice_bloc.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/text_in_row_calculation.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';

class CalculationPart extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CalculationPart({required this.scaffoldKey, super.key});

  @override
  State<CalculationPart> createState() => _CalculationPartState();
}

class _CalculationPartState extends State<CalculationPart> {
  bool idf = true;

  @override
  Widget build(BuildContext context) {
    BlBloc blBloc = BlocProvider.of(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final orderingProvider = Provider.of<OrderingProvider4>(context);
    final currentClient = orderingProvider.getCurrentClient;
    final totalPrice =
        ItemsSingleton.getTotalPrice(currentClient.orderedProducts);
    final totalNDS = ItemsSingleton.getNDS(currentClient.orderedProducts);
    final discountAmount =
        ItemsSingleton.getBaseTotalPrice(currentClient.orderedProducts, false) -
            totalPrice;

    return Container(
      padding: EdgeInsets.all(SizeConfig.v * 1.46),
      height: SizeConfig.v * 20.41,
      width: double.infinity,
      //SizeConfig.h * 55.22,
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).highlightColor.withOpacity(.5),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SUMMA
                TextRowCalculation(
                    fsize: 3.5, title: loc.summa, money: totalPrice),
                //+discountAmount),
                //  SKIDKA
                TextRowCalculation(
                  fsize: 2.34,
                  title: loc.chegirmalar,
                  money: discountAmount > 0 ? discountAmount : 0,
                  // money: 0,
                ),
                // NDS
                TextRowCalculation(
                    fsize: 2.34,
                    title: loc.ha == "Ha" ? "Nds" : "Ндс",
                    money: totalNDS),
                const Spacer(),
                // TOTAL
                TextButton(
                  focusNode: FocusNode(skipTraversal: true),
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).dialogBackgroundColor,
                      padding: const EdgeInsets.all(0.0)),
                  onPressed: () async {
                    blBloc.add(BlStatusChangedEvent(
                        status: BLStatus.other,
                        where:
                            "lib/features/home/features/home_orders/calculation_part/calculation_part.dart total"));
                    await Provider.of<OrderingProvider4>(context, listen: false)
                        .onTotalPriceButtonPressed(context);

                    blBloc.add(BlStatusChangedEvent(
                        status: BLStatus.home,
                        where:
                            "lib/features/home/features/home_orders/calculation_part/calculation_part.dart total"));
                  },
                  child: TextRowCalculation(
                    fsize: 3.9,
                    title: loc.jami,
                    money: totalPrice,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: SizeConfig.h * 1.22),
            width: SizeConfig.h * 8.9,
            child: MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              disabledColor: MyThemes.lightPrimaryColor.withOpacity(.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  SizeConfig.v * .8,
                ),
              ),
              color: Theme.of(context).primaryColor,
              onPressed: () async {
                Object? mxikError;
                bool printerSelected =
                    HiveBoxes.getPrinters().values.isNotEmpty;
                bool printerRequired =
                    Pref.getBool(PrefKeys.printerRequired, false);
                bool mxikDialogError = false;
                List<NoMxikItem>? errorMxikList;

                if (printerRequired && !printerSelected) {
                  showCupertinoDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return const PrinterNotSelectedDialog(
                        text: 'Принтер не выбран ',
                      );
                    },
                  );
                } else {
                  if (mxikDialogError == false) {
                    blBloc.add(BlStatusChangedEvent(
                        status: BLStatus.other,
                        where:
                            "lib/features/home/features/home_orders/calculation_part/calculation_part.dart total"));

                    mxikError = await Provider.of<OrderingProvider4>(
                      context,
                      listen: false,
                    ).goToPaymentPage(context);

                    blBloc.add(
                      BlStatusChangedEvent(
                        status: BLStatus.home,
                        where:
                            "lib/features/home/features/home_orders/calculation_part/calculation_part.dart total",
                      ),
                    );

                    if (mxikError is MxikError) {
                      MxikError m = mxikError as MxikError;
                      List<NoMxikItem> items = m.message!;

                      showGeneralDialog(
                        context: context,
                        pageBuilder: (context, animation, secondaryAnimation) {
                          // mxik feko
                          // return MxikErrorDialog(
                          //   items: items,
                          // );
                          return MxikErrorMessageDialog(
                            items: items,
                          );
                        },
                      );
                    }
                  } else {
                    showGeneralDialog(
                      context: context,
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return MxikErrorMessageDialog(
                          items: errorMxikList ?? [],
                        );
                      },
                    );
                  }
                }
              },
              child: Text(
                "${loc.tolov}\n(F5)",
                textAlign: TextAlign.center,
                style: MyThemes.txtStyle(
                  color: MyThemes.textWhiteColor,
                  fontSize: 3.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
