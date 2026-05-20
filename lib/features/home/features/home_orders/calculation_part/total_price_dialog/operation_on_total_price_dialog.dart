import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/components/shortcuts.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/bottom_buttons_of_operation_on_total_price_dialog.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/operation_centr.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class OperationOnTotalPriceDialog extends StatefulWidget {
  final SixClientModel4 currentClient;
  final num totalPrice;

  const OperationOnTotalPriceDialog({
    required this.currentClient,
    required this.totalPrice,
    super.key,
  });

  @override
  State<OperationOnTotalPriceDialog> createState() =>
      _OperationOnTotalPriceDialogState();
}

class _OperationOnTotalPriceDialogState
    extends State<OperationOnTotalPriceDialog> {
  late TpBloc tpBloc;

  @override
  Widget build(BuildContext context) {
    OrderingProvider4 provider =
        Provider.of<OrderingProvider4>(context, listen: false);
    return BlocProvider(
      create: (context) => TpBloc(
        inputStatus: TpStatus.discount,
        discountPercent: widget.currentClient.discountPercent ?? 0,
        discountString:
            (widget.currentClient.discountPercent ?? 0).toStringAsFixed(0),
        isClientMinimumPriced: false,
        // widget.currentClient.selectedClient?.isMinimumPrice ?? false,
        products: widget.currentClient.orderedProducts,
        selectedAll: true,
        totalPrice: widget.totalPrice,
        totalPriceString: widget.totalPrice.toStringAsFixed(0),
      ),
      child: AlertDialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        content: Container(
          width: SizeConfig.h * 38.96,
          height: SizeConfig.v * 32.18,
          decoration: BoxDecoration(
            color: Pref.getBool(PrefKeys.isDarkMode, true)
                ? Theme.of(context).dialogBackgroundColor
                : MyThemes.lightGreyColorr,
            borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
          ),
          child: BlocConsumer<TpBloc, TpState>(
            listener: (context, state) {
              if (state is TpComletedState) {
                Provider.of<OrderingProvider4>(context, listen: false)
                    .onTotalPriceOperationCompleted(
                  discountPercent: state.dicountPercent,
                  products: state.products,
                );
              }
            },
            builder: (context, state) {
              tpBloc = BlocProvider.of(context, listen: false);

              return VisibilityDetector(
                key: const Key("Oeration On Total Price Dialog"),
                onVisibilityChanged: (v) {
                  if (v.visibleFraction > 0) {
                    provider.totalFocusRequest();
                  }
                },
                child: Shortcuts(
                  shortcuts: shortCuts,
                  child: Actions(
                    key: const Key("On total price dialog Actions key"),
                    actions: actionss(state),
                    child: Focus(
                      focusNode: provider.focusNodeTotal,
                      child: Column(
                        children: [
                          _topSide(context),
                          const OperationCentr(),
                          const SaveButtonOnTotalPriceOperation()
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Container _topSide(BuildContext context) {
    num corePrice = ItemsSingleton.getRealTotalPrice(tpBloc.products);
    return Container(
      height: SizeConfig.v * 6.64,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 1.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              corePrice.toStringAsFixed(1),
              overflow: TextOverflow.ellipsis,
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
              ),
            ),
          ),
          CloseButton(
            color: Theme.of(context).canvasColor,
            onPressed: () {
              AppNavigation.pop();
            },
          ),
        ],
      ),
    );
  }

  Map<Type, Action<Intent>> actionss(TpState state) => {
        Intend0: CallbackAction<Intend0>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 0,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend1: CallbackAction<Intend1>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 1,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend2: CallbackAction<Intend2>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 2,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend3: CallbackAction<Intend3>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 3,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend4: CallbackAction<Intend4>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 4,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend5: CallbackAction<Intend5>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 5,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend6: CallbackAction<Intend6>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 6,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend7: CallbackAction<Intend7>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 7,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend8: CallbackAction<Intend8>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 8,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        Intend9: CallbackAction<Intend9>(
          onInvoke: (intent) {
            tpBloc.add(TpNumPressedEvent(
                pressed: 9,
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        IntendBackSpace: CallbackAction<IntendBackSpace>(
          onInvoke: (intent) {
            tpBloc.add(TpBackSpacePressedEvent(
                inputStatus: state.inputStatus,
                isAllSelected: state.isSelectedAll));
            return;
          },
        ),
        IntendEnter: CallbackAction<IntendEnter>(
          onInvoke: (intent) {
            tpBloc.add(TpSaveButtonPressedEvent());
            AppNavigation.pop();
            return;
          },
        ),
      };

  Map<ShortcutActivator, Intent> get shortCuts => {
        LogicalKeySet(LogicalKeyboardKey.numpad0): Intend0(),
        LogicalKeySet(LogicalKeyboardKey.numpad1): Intend1(),
        LogicalKeySet(LogicalKeyboardKey.numpad2): Intend2(),
        LogicalKeySet(LogicalKeyboardKey.numpad3): Intend3(),
        LogicalKeySet(LogicalKeyboardKey.numpad4): Intend4(),
        LogicalKeySet(LogicalKeyboardKey.numpad5): Intend5(),
        LogicalKeySet(LogicalKeyboardKey.numpad6): Intend6(),
        LogicalKeySet(LogicalKeyboardKey.numpad7): Intend7(),
        LogicalKeySet(LogicalKeyboardKey.numpad8): Intend8(),
        LogicalKeySet(LogicalKeyboardKey.numpad9): Intend9(),
        ///////////////////////////////////////////////
        LogicalKeySet(LogicalKeyboardKey.digit0): Intend0(),
        LogicalKeySet(LogicalKeyboardKey.digit1): Intend1(),
        LogicalKeySet(LogicalKeyboardKey.digit2): Intend2(),
        LogicalKeySet(LogicalKeyboardKey.digit3): Intend3(),
        LogicalKeySet(LogicalKeyboardKey.digit4): Intend4(),
        LogicalKeySet(LogicalKeyboardKey.digit5): Intend5(),
        LogicalKeySet(LogicalKeyboardKey.digit6): Intend6(),
        LogicalKeySet(LogicalKeyboardKey.digit7): Intend7(),
        LogicalKeySet(LogicalKeyboardKey.digit8): Intend8(),
        LogicalKeySet(LogicalKeyboardKey.digit9): Intend9(),
        ///////////////////////////////////////////////
        LogicalKeySet(LogicalKeyboardKey.backspace): IntendBackSpace(),
        LogicalKeySet(LogicalKeyboardKey.numpadDecimal): IntendDot(),
        LogicalKeySet(LogicalKeyboardKey.period): IntendDot(),
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): IntendEnter(),
        LogicalKeySet(LogicalKeyboardKey.tab): IntendTab(),
      };
}
