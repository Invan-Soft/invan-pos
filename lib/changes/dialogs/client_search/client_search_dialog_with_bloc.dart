import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/changes/dialogs/client_search/components/found_client_widget.dart';
import 'package:invan2/changes/dialogs/client_search/components/search_field_of_client_search_dialog.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';
import '../../../features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
import '../../../features/payment/right/dilogs/add_client/bloc/addclient_bloc.dart';
import '../../../features/payment/right/dilogs/add_client/create_client_dialog.dart';
import '../../models/six_client_model.dart';
import '../../providers/ordering_provider_4.dart';

class ClientSearchDialogWithBloc extends StatefulWidget {
  final BuildContext con;
  final ClientModel? client;
  final VoidCallback onDelClientPressed;
  final SixClientModel4 currentClient;
  final num totalPrice;
  final WherePath route;

  const ClientSearchDialogWithBloc(this.con,
      {super.key,
      this.client,
      required this.onDelClientPressed,
      required this.currentClient,
      required this.totalPrice,
      required this.route});

  @override
  State<ClientSearchDialogWithBloc> createState() =>
      _ClientSearchDialogWithBlocState();
}

class _ClientSearchDialogWithBlocState
    extends State<ClientSearchDialogWithBloc> {
  bool isWaiting = false;
  bool isOkButtonPressed = false;
  late ClientBloc clientBloc;
  late TpBloc tpBloc;

  @override
  void initState() {
    clientBloc = BlocProvider.of(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        width: SizeConfig.h * 38.96,
        height: SizeConfig.v * 42.18,
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
        child: BlocConsumer<ClientBloc, SearchClientState>(
          listener: (context, state) async {
            if (state is ClientFoundState) {
              Provider.of<OrderingProvider4>(context, listen: false)
                  .initClientByBloc(state.client);
              if (state.client.discountGroupType ==
                  Pref.getString(PrefKeys.flatRate, "")) {
                Provider.of<OrderingProvider4>(context, listen: false)
                    .setNewClientDiscountPercentage(
                        state.client.discountValue ?? 0);
                OrderingProvider4()
                    .getCurrentClient
                    .discountAmountFromNewClient = state.client.discountValue;

                if (widget.route == WherePath.paymentScreen) {
                  Provider.of<OrderingProvider4>(context, listen: false)
                      .addedClientInPaymentScreen(context);
                }
              }
              await Future.delayed(const Duration(seconds: 1));
              clientBloc.add(ClientClearControllerEvent());
              AppNavigation.pop();
            }
            if (state is ClientNotFoundState) {
              // ignore: use_build_context_synchronously
              Provider.of<OrderingProvider4>(context, listen: false)
                  .initClientByBloc(null);
              await Future.delayed(const Duration(seconds: 1));
              clientBloc.add(ClientInitialEvent());
            }
            if (state is ClientInvalidIdState ||
                state is ClientNoInternetState ||
                state is ClientErrorState) {
              await Future.delayed(const Duration(seconds: 1));
              clientBloc.add(ClientInitialEvent());
            }
          },
          builder: (ctx, state) {
            if (state is ClientInitialState) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.v * 2,
                    horizontal: SizeConfig.v * 2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                              flex: 10,
                              child: SearchFieldOfClientSearchDialog()),
                          widget.route == WherePath.homeScreen
                              ? Expanded(
                                  flex: 1,
                                  child: TextButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    onPressed: () async {
                                      BlocProvider.of<AddClientBloc>(context)
                                          .add(AddClientCallInitialEvent());
                                      await showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierLabel:
                                            MaterialLocalizations.of(context)
                                                .modalBarrierDismissLabel,
                                        barrierColor: Colors.transparent,
                                        builder: (_) {
                                          return const AlertDialog(
                                              alignment: Alignment.topRight,
                                              backgroundColor:
                                                  Colors.transparent,
                                              content: ClientCreateDialog());
                                        },
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      fixedSize: Size(SizeConfig.h * 5,
                                          SizeConfig.v * 7.37),
                                      elevation: 0,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .background,
                                    ),
                                    child: Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Theme.of(context).canvasColor,
                                      size: 28,
                                    ),
                                  ),
                                )
                              : const Expanded(flex: 0, child: Text('')),
                        ],
                      ),
                      widget.client != null
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.v * 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 1),
                              ),
                              child: Column(
                                children: [
                                  FoundClientWidget(
                                    widget.client!,
                                    hPadding: 2,
                                    currentClient: widget.currentClient,
                                    isType: true,
                                  ),
                                  SizedBox(height: SizeConfig.v * 2),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: SizeConfig.v * 4),
                                    child: ElevatedButton(
                                      onPressed: widget.onDelClientPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade400,
                                        foregroundColor:
                                            Theme.of(context).canvasColor,
                                        minimumSize: Size(
                                            double.infinity, SizeConfig.v * 5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        loc.ochirish,
                                        style: MyThemes.txtStyleWhite(
                                            fontSize: 2.2, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              );
            }

            if (state is ClientLoadingState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SpinKitCircle(
                      color: Theme.of(context).primaryColor,
                    ),
                    _setText(state.status == ClientLS.internet
                        ? loc.internet_tekshirilmoqda
                        : loc.klient_qidirilmoqda)
                  ],
                ),
              );
            }
            if (state is ClientFoundState) {
              return FoundClientWidget(
                state.client,
                hPadding: 2,
                currentClient: widget.currentClient,
              );
            }
            if (state is ClientInvalidIdState) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 2),
                  child: _setText(loc.yaroqsiz_id_kiritdingiz),
                ),
              );
            }
            if (state is ClientNotFoundState) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 2),
                  child: _setText(loc.mjoz_topilmadi),
                ),
              );
            }
            if (state is ClientNoInternetState) {
              return Center(
                child: _setText(loc.internet_yoq),
              );
            }
            if (state is ClientErrorState) {
              return Center(
                child: _setText(state.error),
              );
            }

            return const SizedBox(
              height: 0,
              width: 0,
            );
          },
        ),
      ),
    );
  }

  _setText(String v) {
    return Text(
      v,
      textAlign: TextAlign.center,
      style: MyThemes.txtStyleWhite(
          fontSize: 4, color: Theme.of(context).canvasColor),
    );
  }
}
