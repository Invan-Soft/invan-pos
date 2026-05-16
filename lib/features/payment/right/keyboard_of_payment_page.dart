// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/epay/e_pay_model.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/payment/right/complete_button/complete_button.dart';
import 'package:invan2/features/payment/right/number_button_of_payment_page.dart';
import 'package:invan2/utils/helpers/e_pay_helper.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:invan2/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'complete_button/complete_bloc/comlete_bloc.dart';
import 'complete_button/pri_check.dart';

// ignore: must_be_immutable
class KeyboardOfPaymentPage extends StatefulWidget {
  BuildContext homeContextt;

  KeyboardOfPaymentPage(this.homeContextt, {super.key});

  @override
  State<KeyboardOfPaymentPage> createState() => _KeyboardOfPaymentPageState();
}

class _KeyboardOfPaymentPageState extends State<KeyboardOfPaymentPage> {
  late final OrderingProvider4 orderingProvider4;
  bool idf = true;

  @override
  void initState() {
    orderingProvider4 = Provider.of<OrderingProvider4>(context, listen: false);
    super.initState();
  }

  List<String> popItems = ["Debt"];
  int selectedItem = 0;

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: SizeConfig.v * 74,
      child: Column(
        children: [
          Expanded(
            flex: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.v * 1.78),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          //ALL
                          _buildPayments(context),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _cashButton789(context, loc),
                      _terminal456(context, loc),
                      _humoCard123(context),
                      _bonusCard(context, loc),
                      _clickAndPayme(context, loc),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ====================== PASTKI QISM ======================
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Agar Payme/Click + Debt birga bo'lsa → ikkala tugma ham chiqmasin, text chiqsin
                if (_isSpecialPaymentAndDebtTogether(orderingProvider4))
                  Expanded(
                    flex: 13,
                    child: Padding(
                      padding: EdgeInsets.all(SizeConfig.v * 1.5),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(SizeConfig.v * 1.5),
                        ),
                        child: Text(
                          loc.ha == "Ha"
                              ? "Payme yoki Click bilan\nDebt birga tanlangan!\nBitta turini tanlang\n\n"
                              : "Payme или Click вместе с Долгом!\nВыберите один тип оплаты",
                          textAlign: TextAlign.center,
                          style: MyThemes.txtStyle(
                            color: Colors.redAccent,
                            fontSize: 2.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (_shouldShowSimpleCheck(orderingProvider4) ||
                      _isDebtSelected(orderingProvider4))
                    Expanded(
                      flex: _isDebtSelected(orderingProvider4) ? 13 : 3,
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: SimpleCheck(widget.homeContextt),
                      ),
                    ),

                  // Complete Button
                  if (_shouldShowCompleteButton(orderingProvider4))
                    Expanded(
                      flex: _shouldShowSimpleCheck(orderingProvider4) ? 10 : 13,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: _shouldShowSimpleCheck(orderingProvider4)
                              ? SizeConfig.h * 1.9
                              : 0,
                        ),
                        child: CompleteButtonOfPaymentPageOnBloc(
                          widget.homeContextt,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  /// ==================== 1. Payme/Click + Debt birga tanlanganmi? ====================
  /// FAQAT Payme va Click uchun ishlaydi (Uzum emas!)
  bool _isSpecialPaymentAndDebtTogether(OrderingProvider4 provider) {
    final bool hasSpecial = provider.paymentsMapAsList.any((payment) {
      final name = payment.name.toUpperCase();
      return name.contains('PAYME') || name.contains('CLICK');
    });

    final bool hasDebt = provider.paymentsMap.keys.any((key) =>
        key == Pref.getString(PrefKeys.debtId, '') ||
        key.toUpperCase().contains('DEBT'));

    return hasSpecial && hasDebt;
  }

  /// ==================== SimpleCheck chiqishi kerakmi? ====================
  bool _shouldShowSimpleCheck(OrderingProvider4 provider) {
    if (!Pref.getBool(PrefKeys.withOFD, false)) return false;
    if (!Pref.getBool(PrefKeys.preCheck, false)) return false;

    // FAQAT Click Pass muvaffaqiyatli to'langan bo'lsa Simple Check chiqmasin
    if (provider.clickPassPaid == true) {
      return false;
    }

  
    return true;
  }

  bool _isDebtSelected(OrderingProvider4 provider) {
    return provider.paymentsMap.keys.any((key) =>
        key == Pref.getString(PrefKeys.debtId, '') ||
        key.toUpperCase().contains('DEBT'));
  }

  bool _shouldShowCompleteButton(OrderingProvider4 provider) {
    return !_isDebtSelected(provider);
  }

  Column _buildPayments(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final orderingProvider = context.watch<OrderingProvider4>();
    final bool cardOnly = orderingProvider.isCardOnlyPaymentRequired;

    final String cashId = Pref.getString(PrefKeys.cashId, "");
    final String cashbackId = Pref.getString(PrefKeys.cashbackId, "");
    final String debtId = Pref.getString(PrefKeys.debtId, "");
    final String paymeId = Pref.getString(PrefKeys.paymeId, "");
    final String clickId = Pref.getString(PrefKeys.clickId, "");
    final String uzumId = Pref.getString(PrefKeys.uzumId, "");
    final String paynetId = Pref.getString(PrefKeys.paynetId, "");
    final String cardId = Pref.getString(PrefKeys.cardId, "");
    final bool isCashHidden = orderingProvider.isCashPaymentHidden ||
        orderingProvider.isCashHiddenByCashsale ||
        orderingProvider.isBigTotalHidden;

    final bool isPaymeEnabled = Pref.getBool(PrefKeys.paymeEnable, false);
    final bool isClickEnabled = Pref.getBool(PrefKeys.clickEnable, false);
    final bool isUzumEnabled = Pref.getBool(PrefKeys.uzumEnable, false);


    return Column(
      children: otherPaymentsGlobal.map((p) {
        final id = p.id ?? "";

        p.value = 0;
        p.type = 0;

        if (id == cashbackId) {
          if (cardOnly) return const SizedBox.shrink();
          return orderingProvider.getCurrentClientIsNotNULL
              ? _functionalButton(loc.bonus_karta, () {
                  orderingProvider4.typeFromCashbackBalance(context, p);
                })
              : const SizedBox.shrink();
        }

        if (id == debtId) {
          if (cardOnly) return const SizedBox.shrink();
          return orderingProvider.getCurrentClientIsNotNULL &&
                  orderingProvider.getCurrentClientIsAvailableForDebt
              ? _functionalButton(loc.qarz, () {
                  orderingProvider.allPaymentType(p);
                })
              : const SizedBox.shrink();
        }
        if (id == paymeId) {
          if (!isPaymeEnabled || cardOnly) return const SizedBox.shrink();
          return _functionalButtonWithImg("payme", () async {
            await typeDialog("Payme Go", "Payme QR", () async {
              Navigator.pop(context);
              await orderingProvider.typePayme(context, p);
            }, () async {
              Navigator.pop(context);
              p.type = 1;
              orderingProvider.allPaymentType(p);
              orderingProvider.setPaymePaid(true);
            });
          });
        }

        if (id == clickId) {
          if (!isClickEnabled || cardOnly) return const SizedBox.shrink();
          return _functionalButtonWithImg("click", () async {
            await typeDialog("CLICK PASS", "CLICK QR", () async {
              Navigator.pop(context);
              await orderingProvider.typeClick(context, p);
            }, () {
              Navigator.pop(context);
              p.type = 1;
              orderingProvider.allPaymentType(p);
            });
          });
        }

        if (id == uzumId) {
          if (!isUzumEnabled || cardOnly) return const SizedBox.shrink();
          return _functionalButtonWithImg("Uzum", () async {
            await typeDialog("UZUM PASS", "UZUM QR", () async {
              Navigator.pop(context);
              bool enabled = EPayHelper.instance.hasEnabled(EPayEnum.uzum);
              if (!enabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  mySnackBar(context, msg: "Uzum yoqilmagan"),
                );
                return;
              }
              await orderingProvider.typeUzum(context, p);
            }, () {
              Navigator.pop(context);
              p.type = 1;
              orderingProvider.allPaymentType(p);
            });
          });
        }

    //    PAYNET TEMPORARILY HIDDEN
        if ((paynetId.isNotEmpty && id == paynetId) ||
            (p.name?.toUpperCase().contains('PAYNET') == true)) {
          if (cardOnly) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.v * 1.78),
            child: SizedBox(
              width: SizeConfig.h * 18.77,
              height: SizeConfig.v * 9.68,
              child: RawMaterialButton(
                focusNode: FocusNode(skipTraversal: true),
                elevation: 0,
                fillColor: Theme.of(context).dialogBackgroundColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
                onPressed: () async {
                  await typeDialog("Paynet Pass", "Paynet QR", () async {
                    Navigator.pop(context);
                    await orderingProvider.typePaynet(context, p);
                  }, () {
                    Navigator.pop(context);
                    p.type = 1;
                    orderingProvider.allPaymentType(p);
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.v * 7),
                  child: Image.asset(
                    "assets/images/paynet-logo.png",
                    scale: 3,
                  ),
                ),
              ),
            ),
          );
        }

        // if ((paynetId.isNotEmpty && id == paynetId) ||
        //     (p.name?.toUpperCase().contains('PAYNET') == true)) {
        //   return const SizedBox.shrink();
        // }

        if (id == cashId) {
          if (isCashHidden || cardOnly) return const SizedBox.shrink();
          return _functionalButton(
            loc.ha == 'Ha' ? 'Naqd pul' : 'Наличные',
            () => orderingProvider.allPaymentType(p),
          );
        }
        if (id == cardId) {
          return _functionalButton("${loc.plastik} ${loc.karta}", () async {
            Pref.setBool("credit", false);
            Pref.setBool("advance", false);
            setState(() {});
            await typeDialog("Uzcard", "Humo", () async {
              Navigator.pop(context);
              orderingProvider.typeUzcard(context, p);
            }, () async {
              Navigator.pop(context);
              p.type = 1;
              orderingProvider.typeHumo(context, p);
            }, isCard: true);
          });
        }
        if (cardOnly) return const SizedBox.shrink();
        return _functionalButton(p.name ?? '', () {
          orderingProvider.allPaymentType(p);
        });
      }).toList(),
    );
  }


  Row _clickAndPayme(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.h * 1.56, bottom: SizeConfig.v * 1.78),
            child: SizedBox(
              width: SizeConfig.h * 6.73,
              height: SizeConfig.v * 9.68,
              child: RawMaterialButton(
                focusNode: FocusNode(skipTraversal: true),
                elevation: 0,
                fillColor: Theme.of(context).dialogBackgroundColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
                child: Icon(
                  Icons.arrow_back_outlined,
                  size: SizeConfig.v * 4,
                  color: Theme.of(context).canvasColor,
                ),
                onPressed: () => pressDeleteButton(context, isNumPad: false),
              ),
            ),
          ),
        ),

        /////////////////////////////////////////////////////////////////////////

        Pref.getBool(PrefKeys.transfer, false)
            ? Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.h * 1.56, bottom: SizeConfig.v * 1.78),
                  child: SizedBox(
                    width: SizeConfig.h * 15,
                    height: SizeConfig.v * 9.68,
                    child: RawMaterialButton(
                      focusNode: FocusNode(skipTraversal: true),
                      elevation: 0,
                      fillColor: Theme.of(context).dialogBackgroundColor,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.v * 1.1)),
                      child: Center(
                        child: Text(
                          loc.ha == 'Ha' ? 'Transferlar' : 'Перечисления',
                          style: MyThemes.txtStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).canvasColor,
                            fontSize: 2.8,
                          ),
                        ),
                      ),
                      onPressed: () {
                        if (Provider.of<OrderingProvider4>(context,
                                listen: false)
                            .getPaymentInProgress) return;
                        Provider.of<OrderingProvider4>(context, listen: false)
                            .onClientSearchButtonPressedWithInn(context);
                      },
                    ),
                  ),
                ),
              )
            : const Text(''),
      ],
    );
  }

  Row _bonusCard(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NumberButtonOfPaymentPage(
          number: "0",
          onPress: () => pressNum(context, 0),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.h * 1.56,
            bottom: SizeConfig.v * 1.78,
          ),
          child: SizedBox(
            width: SizeConfig.h * 6.73,
            height: SizeConfig.v * 9.68,
            child: RawMaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              elevation: 0,
              fillColor: Theme.of(context).dialogBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
              child: Text(
                '.',
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).canvasColor,
                  fontSize: 3.5,
                ),
              ),
              onPressed: () {
                Provider.of<OrderingProvider4>(context, listen: false)
                    .onDotPressed();
              },
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.h * 1.56,
            bottom: SizeConfig.v * 1.78,
          ),
          child: SizedBox(
            width: SizeConfig.h * 6.73,
            height: SizeConfig.v * 9.68,
            child: RawMaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              elevation: 0,
              fillColor: Theme.of(context).dialogBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
              child: Text(
                'C',
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).canvasColor,
                  fontSize: 3.5,
                ),
              ),
              onPressed: () => pressCButton(context),
            ),
          ),
        ),
      ],
    );
  }

  Row _humoCard123(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // const HumoCardButton(),
        NumberButtonOfPaymentPage(
          number: "1",
          onPress: () => pressNum(context, 1),
        ),
        NumberButtonOfPaymentPage(
          number: "2",
          onPress: () => pressNum(context, 2),
        ),
        NumberButtonOfPaymentPage(
          number: "3",
          onPress: () => pressNum(context, 3),
        ),
      ],
    );
  }

  Row _terminal456(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // _functionalButton(
        //   // loc.terminal,
        //   "UzCard",
        //   () => orderingProvider4.typeTerminal(),
        // ),
        NumberButtonOfPaymentPage(
          number: "4",
          onPress: () => pressNum(context, 4),
        ),
        NumberButtonOfPaymentPage(
          number: "5",
          onPress: () => pressNum(context, 5),
        ),
        NumberButtonOfPaymentPage(
          number: "6",
          onPress: () => pressNum(context, 6),
        ),
      ],
    );
  }

  Row _cashButton789(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // _functionalButton(
        //   loc.naqd,
        //   () => orderingProvider4.typeCash(),
        // ),
        VisibilityDetector(
          onVisibilityChanged: (VisibilityInfo info) {
            if (info.visibleFraction > 0) {
              context
                  .read<OrderingProvider4>()
                  .focusNodeListener
                  .requestFocus();
            }
          },
          key: const Key('visible-dete'),
          child: RawKeyboardListener(
            key: const Key("PaymentPage"),
            focusNode: context.read<OrderingProvider4>().focusNodeListener,
            autofocus: false,
            onKey: (event) {
              if (event.logicalKey == LogicalKeyboardKey.digit0 ||
                  event.logicalKey == LogicalKeyboardKey.numpad0) {
                pressNum(context, 0, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit1 ||
                  event.logicalKey == LogicalKeyboardKey.numpad1) {
                pressNum(context, 1, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
                  event.logicalKey == LogicalKeyboardKey.numpad2) {
                pressNum(context, 2, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
                  event.logicalKey == LogicalKeyboardKey.numpad3) {
                pressNum(context, 3, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
                  event.logicalKey == LogicalKeyboardKey.numpad4) {
                pressNum(context, 4, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit5 ||
                  event.logicalKey == LogicalKeyboardKey.numpad5) {
                pressNum(context, 5, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit6 ||
                  event.logicalKey == LogicalKeyboardKey.numpad6) {
                pressNum(context, 6, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit7 ||
                  event.logicalKey == LogicalKeyboardKey.numpad7) {
                pressNum(context, 7, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit8 ||
                  event.logicalKey == LogicalKeyboardKey.numpad8) {
                pressNum(context, 8, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.digit9 ||
                  event.logicalKey == LogicalKeyboardKey.numpad9) {
                pressNum(context, 9, isNumPad: true);
              } else if (event.logicalKey == LogicalKeyboardKey.delete) {
                pressCButton(context);
              } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
                pressDeleteButton(context, isNumPad: true);
              } else if (event.isKeyPressed(LogicalKeyboardKey.f5)) {
                // orderingProvider4.typeCash();
              } else if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
                AppNavigation.pop();
              } else if (event.isKeyPressed(LogicalKeyboardKey.space)) {
                if (context.read<OrderingProvider4>().getIsButtonEnabled &&
                    !context.read<OrderingProvider4>().getPaymentInProgress) {
                  BlocProvider.of<CmtBBloc>(context, listen: false)
                      .add(CtPrepareToPayEvent());
                }
              }
            },
            child: NumberButtonOfPaymentPage(
              number: "7",
              onPress: () => pressNum(context, 7),
            ),
          ),
        ),
        NumberButtonOfPaymentPage(
          number: "8",
          onPress: () => pressNum(context, 8),
        ),
        NumberButtonOfPaymentPage(
          number: "9",
          onPress: () => pressNum(context, 9),
        ),
      ],
    );
  }

  Widget _cardTypeCheckbox({
    required BuildContext context,
    required String label,
    required double width,
    required bool checked,
    required double checkScale,
    required double gap,
    required void Function(bool?) onChanged,
  }) {
    return SizedBox(
      width: width,
      height: SizeConfig.v * 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).canvasColor,
                  fontSize: 4,
                ),
              ),
            ),
          ),
          SizedBox(width: gap),
          Transform.scale(
            scale: checkScale,
            child: Checkbox(
              value: checked,
              onChanged: onChanged,
              activeColor: Theme.of(context).primaryColor,
              checkColor: Colors.white,
              side: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding _functionalButton(String title, VoidCallback callBack,
      {bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.v * 1.78),
      child: SizedBox(
        width: SizeConfig.h * 18.77,
        height: SizeConfig.v * 9.68,
        child: RawMaterialButton(
          focusNode: FocusNode(skipTraversal: true),
          elevation: 0,
          fillColor: Theme.of(context).dialogBackgroundColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
          onPressed: enabled ? callBack : null,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: MyThemes.txtStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).canvasColor,
              fontSize: 3,
            ),
          ),
        ),
      ),
    );
  }

  Padding _functionalButtonWithImg(String img, VoidCallback callBack,
      {bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.v * 1.78),
      child: SizedBox(
        width: SizeConfig.h * 18.77,
        height: SizeConfig.v * 9.68,
        child: RawMaterialButton(
          focusNode: FocusNode(skipTraversal: true),
          elevation: 0,
          fillColor: Theme.of(context).dialogBackgroundColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
          onPressed: enabled ? callBack : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.v * 7),
            child: Image.asset(
              "assets/images/${Pref.getBool(PrefKeys.isDarkMode, true) ? img : "${img}_dark"}.png",
              scale: 3,
            ),
          ),
        ),
      ),
    );
  }

  void pressCButton(BuildContext context) {
    Provider.of<OrderingProvider4>(context, listen: false).onCButtonPressed();
  }

  void pressDeleteButton(BuildContext context, {bool isNumPad = false}) {
    if (isNumPad) {
      if (idf) {
        Provider.of<OrderingProvider4>(context, listen: false)
            .onBackSpacePressed();
        idf = false;
        if (mounted) {
          setState(() {});
        }
      } else {
        idf = true;
      }
    } else {
      Provider.of<OrderingProvider4>(context, listen: false)
          .onBackSpacePressed();
    }
  }

  void pressNum(BuildContext context, int num, {bool isNumPad = false}) {
    if (isNumPad) {
      if (idf) {
        Provider.of<OrderingProvider4>(context, listen: false)
            .onNumPressed(num);
        idf = false;
        if (mounted) {
          setState(() {});
        }
      } else {
        idf = true;
        // if (mounted) {
        //   setState(() {});
        // }
      }
    } else {
      Provider.of<OrderingProvider4>(context, listen: false).onNumPressed(num);
    }
  }

  typeDialog(String title1, String title2, VoidCallback on1, VoidCallback on2,
      {bool isCard = false}) async {
    AppLocalizations loc = AppLocalizations.of(context)!;
    await Pref.setInt('card_type', 2);
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent.withOpacity(0.0),
      builder: (_) {
        return AlertDialog(
          alignment: Alignment.center,
          backgroundColor: Colors.transparent,
          content: Container(
            height: isCard && Pref.getBool(PrefKeys.withOFD, false)
                ? SizeConfig.v * 40
                : SizeConfig.v * 24,
            // width: SizeConfig.h * 30,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: MyThemes.textWhiteColor,
                  blurRadius: 3,
                ),
              ],
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(
                SizeConfig.v * 1.1,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: SizeConfig.v * 1.78,
                    right: SizeConfig.v * 1.78,
                    bottom: SizeConfig.v * 1.78,
                    top: SizeConfig.v * 1.78,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      isCard && Pref.getBool(PrefKeys.withOFD, false)
                          ? StatefulBuilder(
                              builder: (BuildContext context, StateSetter setState) {
                                final double btnW = ((SizeConfig.h * 50) / 2) - (SizeConfig.h * .5);
                                final double gap = SizeConfig.h * 1;
                                final double checkScale = (SizeConfig.v * 2).clamp(1.2, 2.0);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _cardTypeCheckbox(
                                      context: context,
                                      label: loc.ha == 'Ha' ? 'Korporativ' : 'Корпоративная',
                                      width: btnW,
                                      checked: Pref.getInt('card_type', 0) == 1,
                                      checkScale: checkScale,
                                      gap: gap,
                                      onChanged: (v) async {
                                        if (v != null) {
                                          await Pref.setInt('card_type', v ? 1 : 2);
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    SizedBox(width: SizeConfig.h * 1),
                                    _cardTypeCheckbox(
                                      context: context,
                                      label: loc.ha == 'Ha' ? 'Ijtimoiy Karta' : 'Социальная Карта',
                                      width: btnW,
                                      checked: Pref.getInt('card_type', 0) == 3,
                                      checkScale: checkScale,
                                      gap: gap,
                                      onChanged: (v) async {
                                        if (v != null) {
                                          await Pref.setInt('card_type', v ? 3 : 2);
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                      Row(
                        children: [
                          SizedBox(
                            width:
                                ((SizeConfig.h * 50) / 2) - (SizeConfig.h * .5),
                            height: SizeConfig.v * 20,
                            child: RawMaterialButton(
                              focusNode: FocusNode(skipTraversal: true),
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.v),
                              elevation: 0,
                              fillColor:
                                  Theme.of(context).dialogBackgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(SizeConfig.v * 1.1),
                              ),
                              onPressed: on1,
                              child: Text(
                                title1,
                                style: MyThemes.txtStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).canvasColor,
                                  fontSize: 6,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: SizeConfig.v * 1.78,
                          ),
                          SizedBox(
                            width:
                                ((SizeConfig.h * 50) / 2) - (SizeConfig.h * .5),
                            height: SizeConfig.v * 20,
                            child: RawMaterialButton(
                              focusNode: FocusNode(skipTraversal: true),
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.v),
                              elevation: 0,
                              fillColor:
                                  Theme.of(context).dialogBackgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(SizeConfig.v * 1.1),
                              ),
                              onPressed: on2,
                              child: Text(
                                title2,
                                style: MyThemes.txtStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).canvasColor,
                                  fontSize: 6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
