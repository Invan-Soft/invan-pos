// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/home/features/operation_on_product/opd_center/components/opd_only_price.dart';
import 'package:invan2/features/home/features/operation_on_product/opd_center/components/opd_stir.dart';
import 'package:invan2/features/home/features/operation_on_product/opd_center/components/opd_box.dart';
import 'package:invan2/features/home/features/operation_on_product/opd_center/components/opd_price.dart';
import 'package:invan2/features/home/features/operation_on_product/opd_center/components/opd_summa.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'components/opd_value.dart';
import '../../../../../changes/providers/operation_on_product_provider.dart';
import 'components/opd_discount.dart';

class OPDCenter extends StatefulWidget {
  final ReceiptModelSoldItem4 item;

  const OPDCenter({super.key, required this.item});

  @override
  OPDCenterState createState() => OPDCenterState();
}

class OPDCenterState extends State<OPDCenter> {
  final _keyboardFocusNode = FocusNode();

  late bool ofd;

  @override
  void initState() {
    ofd = Pref.getBool(PrefKeys.withOFD, false);
    super.initState();
  }

  bool comissionInfo = false;
  final ScrollController _scrollController = ScrollController();
  bool idf = true;
  int i = 0;

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
              const OPDprice(),
              OPDQuantity(value: widget.item.value),
              widget.item.soldBy == "box"
                  ? const OPDbox(value: 0)
                  : const SizedBox(),
              const OPDDiscount(),
              // const OPDonlyPrice(),
              Divider(color: Theme.of(context).dividerColor),
              VisibilityDetector(
                onVisibilityChanged: (VisibilityInfo info) {
                  if (info.visibleFraction > 0) {
                    context
                        .read<OperationOnProductProvider>()
                        .focusNode
                        .requestFocus();
                  }
                },
                key: const Key('Operation On Product dialog / visibility'),
                child: RawKeyboardListener(
                  includeSemantics: true,
                  key: const Key("Operation On Product dialog"),
                  focusNode:
                      context.read<OperationOnProductProvider>().focusNode,
                  autofocus: true,
                  onKey: _onKeyEventFunc,
                  child: OPDsumma(
                    (widget.item.price * widget.item.value).toStringAsFixed(1),
                  ),
                ),
              ),
              /*ofd
                  ? OPDstir(
                      value: comissionInfo,
                      onChanged: (v) {
                        setState(
                          () {
                            comissionInfo = v;
                          },
                        );
                      },
                      onChanged2: (v) {
                        setState(
                          () {},
                        );
                      },
                      item: widget.item)
                  : const SizedBox(),*/
            ],
          ),
        ),
      ),
    );
  }

  _onKeyEventFunc(RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.digit0 ||
        event.logicalKey == LogicalKeyboardKey.numpad0) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '0');
    } else if (event.logicalKey == LogicalKeyboardKey.digit1 ||
        event.logicalKey == LogicalKeyboardKey.numpad1) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '1');
    } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
        event.logicalKey == LogicalKeyboardKey.numpad2) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '2');
    } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
        event.logicalKey == LogicalKeyboardKey.numpad3) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '3');
    } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
        event.logicalKey == LogicalKeyboardKey.numpad4) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '4');
    } else if (event.logicalKey == LogicalKeyboardKey.digit5 ||
        event.logicalKey == LogicalKeyboardKey.numpad5) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '5');
    } else if (event.logicalKey == LogicalKeyboardKey.digit6 ||
        event.logicalKey == LogicalKeyboardKey.numpad6) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '6');
    } else if (event.logicalKey == LogicalKeyboardKey.digit7 ||
        event.logicalKey == LogicalKeyboardKey.numpad7) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '7');
    } else if (event.logicalKey == LogicalKeyboardKey.digit8 ||
        event.logicalKey == LogicalKeyboardKey.numpad8) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '8');
    } else if (event.logicalKey == LogicalKeyboardKey.digit9 ||
        event.logicalKey == LogicalKeyboardKey.numpad9) {
      if (event is RawKeyDownEvent) return;
      pressNum(context, '9');
    } else if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      // if (event is RawKeyDownEvent) return;
      // pressNum(context, '10');
      pressDeleteButton(context);
    } else if (event.logicalKey == LogicalKeyboardKey.period ||
        event.logicalKey == LogicalKeyboardKey.numpadDecimal) {
      // if (event is RawKeyDownEvent) return;
      pressNum(context, '.');
      // if (widget.item.soldBy == "weight") {
      //   pressDotButton(context, isNumPad: true);
      // }
    } else if (event.isKeyPressed(LogicalKeyboardKey.numpadSubtract)) {
      Provider.of<OperationOnProductProvider>(context, listen: false)
          .decreaseQuantity(1);
    } else if (event.isKeyPressed(LogicalKeyboardKey.numpadAdd)) {
      Provider.of<OperationOnProductProvider>(context, listen: false)
          .increaseQuantity(1);
    } else if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
      context.read<OperationOnProductProvider>().onSaveButtonPressed(context);
    }
  }

  void pressDeleteButton(
    BuildContext context,
  ) {
    if (idf) {
      Provider.of<OperationOnProductProvider>(context, listen: false)
          .onBackSpacePressed();
      idf = false;
      setState(() {});
    } else {
      idf = true;
      setState(() {});
    }
  }

  void pressDotButton(BuildContext context, {bool isNumPad = false}) {
    if (isNumPad) {
      if (idf) {
        Provider.of<OperationOnProductProvider>(context, listen: false)
            .onDotPressed();
        idf = false;
        setState(() {});
      } else {
        idf = true;
      }
    } else {
      Provider.of<OperationOnProductProvider>(context, listen: false)
          .onDotPressed();
    }
  }

  void pressNum(BuildContext context, String num) {
    Provider.of<OperationOnProductProvider>(context, listen: false)
        .onNumPressed(num);
    return;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }
}
