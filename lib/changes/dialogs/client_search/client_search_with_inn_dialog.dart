import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/changes/dialogs/client_search/components/search_button_of_client_search_dialog.dart.dart';
import 'package:invan2/changes/dialogs/client_search/components/search_field_of_client_search_dialog.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/payment/right/dilogs/transfer/set_driver/set_driver_bloc.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import 'package:provider/provider.dart';
import '../../providers/ordering_provider_4.dart';
import '../../singletons/organization_singleton.dart';
import 'employee_search_password/employee_search_password.dart';

class TransferWithInnDialog extends StatefulWidget {
  final BuildContext con;
  final ClientModel? client;
  final VoidCallback onDelClientPressed;

  const TransferWithInnDialog(this.con,
      {super.key, this.client, required this.onDelClientPressed});

  @override
  State<TransferWithInnDialog> createState() => _TransferWithInnDialogState();
}

class _TransferWithInnDialogState extends State<TransferWithInnDialog> {
  TextEditingController companyController = TextEditingController();
  TextEditingController commentsController = TextEditingController();

  int a = 1;
  StreamController<int> counterController = StreamController();
  var focusNode = FocusNode();

  late ClientBloc clientBloc;
  late final OrderingProvider4 orderingProvider4;

  @override
  void initState() {
    clientBloc = BlocProvider.of(context, listen: false);
    orderingProvider4 = Provider.of<OrderingProvider4>(context, listen: false);

    super.initState();
    focusNode.requestFocus();
  }

  String agent = "";
  String agentPass = "";

  @override
  void dispose() {
    super.dispose();
    focusNode.canRequestFocus;
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;

    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        width: SizeConfig.h * 53,
        height: SizeConfig.v * 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.background,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.grey)),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Перечисления",
                      style: MyThemes.txtStyle(
                        color: MyThemes.textWhiteColor,
                        fontSize: 3.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(SizeConfig.v * 3),
              child: Column(
                children: [
                  MaterialButton(
                    focusNode: FocusNode(skipTraversal: true),
                    disabledColor: Theme.of(context).highlightColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConfig.v * 1.1,
                      ),
                    ),
                    color: Theme.of(context).dialogBackgroundColor,
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (_) => const SelectEmplyeeWithPassDialog());
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.v * 2.15,
                              horizontal: SizeConfig.v * 1.1),
                          child: BlocConsumer<SetDriverBloc, SetDriverState>(
                            listener: (context, state) {
                              if (state is SetDriverNameSucces) {
                                agent = state.name;
                                agentPass = state.pass;
                              }
                            },
                            builder: (context, state) {
                              return Text(
                                agent == "" ? loc.xodim : agent,
                                style: MyThemes.txtStyle(
                                  fontWeight: FontWeight.w400,
                                  color: MyThemes.textWhiteColor,
                                  fontSize: 2,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Didox",
                        style: MyThemes.txtStyle(
                          color: MyThemes.textWhiteColor,
                          fontSize: 2.5,
                        ),
                      ),
                      CupertinoSwitch(
                        value: context.watch<OrderingProvider4>().isDidox,
                        // OrderingProvider4().isDidox,
                        onChanged: (value) {
                          Provider.of<OrderingProvider4>(context, listen: false)
                              .setDidox(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  BlocConsumer<ClientBloc, SearchClientState>(
                    listener: (context, state) async {
                      if (state is ClientFoundState) {
                        Provider.of<OrderingProvider4>(context, listen: false)
                            .initClientByBloc(state.client);
                        await Future.delayed(const Duration(seconds: 1));
                        clientBloc.add(ClientClearControllerEvent());
                        // AppNavigation.pop();
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
                        if (widget.client != null) {
                          companyController.text = widget.client!.firstName!;
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              flex: 8,
                              child: SearchFieldOfClientSearchDialog(
                                maxLen: 9,
                                isText: true,
                                isHome: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                  height: SizeConfig.v * 7.1,
                                  child: SearchButtonOfClientDialog()),
                            ),
                          ],
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
                        companyController.text =
                            "Название компании:   ${state.client.firstName}";
                      }
                      if (state is ClientInvalidIdState) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.h * 2),
                            child: _setText(loc.yaroqsiz_id_kiritdingiz),
                          ),
                        );
                      }
                      if (state is ClientNotFoundState) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.h * 2),
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
                  const SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 8,
                        child: TextField(
                          controller: companyController,
                          enabled: false,
                          autofocus: true,
                          style: TextStyle(
                            color: Theme.of(context).canvasColor,
                            fontSize: SizeConfig.v * 2,
                          ),
                          cursorColor: Theme.of(context).primaryColor,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: SizeConfig.v * 2.5,
                                horizontal: SizeConfig.v * 1.1),
                            fillColor: Theme.of(context).dialogBackgroundColor,
                            filled: true,
                            hintStyle: TextStyle(
                              color: Theme.of(context).canvasColor,
                              fontSize: SizeConfig.v * 2,
                            ),
                            hintText: "Название компании",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(SizeConfig.v),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          inputFormatters: const [],
                        ),
                      ),
                      SizedBox(
                        width: SizeConfig.v * 1,
                      ),
                      widget.client != null
                          ? Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: SizeConfig.v * 6.8,
                                child: DefaultButton(
                                  isErrorButton: true,
                                  text: "DELETE",
                                  isButtonEnabled: true,
                                  onPress: widget.onDelClientPressed,
                                ),
                              ),
                            )
                          : const Text(""),
                    ],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  TextField(
                    maxLines: 4,
                    controller: commentsController,
                    style: TextStyle(
                      color: Theme.of(context).canvasColor,
                      fontSize: SizeConfig.v * 2,
                    ),
                    cursorColor: Theme.of(context).primaryColor,
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).dialogBackgroundColor,
                      filled: true,
                      hintStyle: TextStyle(
                        color: Theme.of(context).canvasColor,
                        fontSize: SizeConfig.v * 2,
                      ),
                      hintText: loc.izoh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.v),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    inputFormatters: const [],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          loc.soni,
                          style: MyThemes.txtStyle(
                            color: Theme.of(context).canvasColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.h * .1,
                              vertical: SizeConfig.h * .2),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).canvasColor,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _prefixIcon(),
                              TextButton(
                                focusNode: FocusNode(skipTraversal: true),
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).dialogBackgroundColor,
                                  padding: const EdgeInsets.all(0.0),
                                ),
                                child: StreamBuilder<int>(
                                    stream: counterController.stream,
                                    initialData: 1,
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.requireData.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: SizeConfig.v * 2.3,
                                          fontWeight: FontWeight.normal,
                                          fontStyle: FontStyle.normal,
                                          color: Theme.of(context).canvasColor,
                                        ),
                                      );
                                    }),
                              ),
                              _suffixIcon()
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  DefaultButton(
                    text: "Ok",
                    isButtonEnabled: true,
                    onPress: () async {
                      if (orderingProvider4.getCurrentClient.selectedClient ==
                          null) {
                        ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
                            context,
                            duration: 1500,
                            msg: loc
                                .qarzga_sotishga_client_tanlangan_boloshi_lozim));

                        return;
                      }
                      if (agent == loc.xodim) {
                        agent = "";
                      }
                      orderingProvider4.getComment(
                          "$agent    $agentPass \n ${commentsController.text}",
                          true);
                      // orderingProvider4.getAgent(agent);

                      context.read<OrderingProvider4>().removeFromPaymentList();
                      otherPaymentsGlobal.map((p) {
                        if (p.id == Pref.getString(PrefKeys.debtId, "")) {
                          orderingProvider4.allPaymentType(p);
                        }
                      }).toList();

                      Pref.setInt(PrefKeys.companyResipt, a);
                      Pref.setString(
                          PrefKeys.companyNameDialog, companyController.text);
                      AppNavigation.pop();
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _prefixIcon() {
    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        fixedSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        elevation: 0,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(.4),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        counterController.add(a > 1 ? a = a - 1 : 1);
      },
      child: Icon(
        Icons.remove,
        color: Theme.of(context).canvasColor,
      ),
    );
  }

  ElevatedButton _suffixIcon() {
    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        fixedSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        elevation: 0,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(.4),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        counterController.add(a < 4 ? a = a + 1 : 4);
      },
      child: Icon(
        Icons.add,
        color: Theme.of(context).canvasColor,
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
