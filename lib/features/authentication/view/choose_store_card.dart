import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/changes/components/shortcuts.dart';
import 'package:invan2/features/authentication/bloc/ss_bloc/ss_bloc.dart';
import 'package:invan2/features/authentication/model/stores_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/apd_text_widget.dart';
import 'package:invan2/widgets/widgets.dart';

import '../../../utils/l10n/app_localizations.dart';

// ignore: must_be_immutable
class ChooseStoreCard extends StatefulWidget {
  const ChooseStoreCard({super.key});

  @override
  State<ChooseStoreCard> createState() => _ChooseStoreCardState();
}

class _ChooseStoreCardState extends State<ChooseStoreCard> {
  late AppLocalizations loc;

  late SsBloc ssBloc;

  late FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode();
    ssBloc = BlocProvider.of(context, listen: false);
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    loc = AppLocalizations.of(context)!;
    return Container(
      height: SizeConfig.v * 25.5,
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.h * 30.3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.v * 1.56),
      ),
      child: BlocBuilder<SsBloc, SsState>(
        builder: (context, state) {
          if (state is SsInitial) {
            return _ssInitial(
              state.stores,
              context,
              state.selectedStore,
            );
          }
          if (state is SsLoadingState) {
            return _padding(Center(
              child: Column(
                children: [
                  SpinKitCircle(
                    color: Theme
                        .of(context)
                        .primaryColor,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: ApdText(
                        state.message,
                      ),
                    ),
                  ),
                ],
              ),
            ));
          }

          if (state is SsLoadingFailedState) {
            return _padding(
              Center(
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: ApdText(
                          state.message == "net"
                              ? loc.internet_yoq
                              : state.message,
                        ),
                      ),
                    ),
                    DefaultButton(
                      isButtonEnabled: true,
                      onPress: () => ssBloc.add(SsRetryEvent()),
                      text: loc.qayta_urinish,
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(
            child: Text("Error On Choose Store Card"),
          );
        },
      ),
    );
  }

  _padding(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.v * 2, vertical: SizeConfig.v * 2),
      child: child,
    );
  }

  _ssInitial(List<StoresModel> stores,
      BuildContext context,
      StoresModel selectedStore,) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.v * 3.2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                stores.isEmpty
                    ? Container()
                    : Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.v,
                    vertical: SizeConfig.v * .8,
                  ),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SizeConfig.v),
                      border: Border.all(
                          color: Theme
                              .of(context)
                              .primaryColor,
                          width: 2)),
                  child: Shortcuts(
                    shortcuts: shortCutss,
                    child: Actions(
                      actions: actions(selectedStore.id),
                      child: Focus(
                        focusNode: focusNode,
                        child: PopupMenuButton(
                          color: MyThemes.lightGreyColorr,
                          padding: const EdgeInsets.all(5),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                color: Theme
                                    .of(context)
                                    .primaryColor,
                                width: 2),
                            borderRadius:
                            BorderRadius.circular(SizeConfig.v),
                          ),
                          tooltip: '',
                          child: Container(
                            color: Colors.white,
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                Text(
                                  selectedStore.name,
                                  style: MyThemes.txtStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black,
                                  size: SizeConfig.v * 5,
                                ),
                              ],
                            ),
                          ),
                          onSelected: (selectedServiceId) =>
                              ssBloc
                                  .add(SsSelectStoreEvent(selectedServiceId)),
                          itemBuilder: (_) {
                            return stores.map(
                                  (e) {
                                return PopupMenuItem(
                                  value: e.id,
                                  child: SizedBox(
                                    width: SizeConfig.h * 30,
                                    child: Text(
                                      e.name,
                                      style: MyThemes.txtStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                DefaultButton(
                  onPress: () =>
                      ssBloc.add(SsButtonPressedEvent(
                        loc: loc,
                        selectedStoreId: selectedStore.id,
                      )),
                  text: loc.keyingisi,
                  isButtonEnabled: stores.isNotEmpty,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: SizeConfig.v * 2.2,
          left: SizeConfig.v * 5.2,
          child: Text(
            "  ${loc.filial_tanlang}   ",
            style: TextStyle(
              backgroundColor: Colors.white,
              fontWeight: FontWeight.bold,
              color: const Color(0xff434862),
              fontSize: SizeConfig.v * 1.8,
            ),
          ),
        ),
      ],
    );
  }

  Map<Type, Action<Intent>> actions(String id) =>
      {
        IntendEnter: CallbackAction<IntendEnter>(
          onInvoke: (intent) {
            ssBloc.add(SsButtonPressedEvent(
              loc: loc,
              selectedStoreId: id,
            ));
            return;
          },
        ),
      };

  Map<ShortcutActivator, Intent> get shortCutss =>
      {
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): IntendEnter(),
        LogicalKeySet(LogicalKeyboardKey.enter): IntendEnter(),
      };
}
