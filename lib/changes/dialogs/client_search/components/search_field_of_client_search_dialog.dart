import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import '../../../../widgets/my_snackbar.dart';

// ignore: must_be_immutable
class SearchFieldOfClientSearchDialog extends StatefulWidget {
  final int? maxLen;
  final bool? isText;
  final bool? isHome;

  const SearchFieldOfClientSearchDialog({
    super.key,
    this.maxLen,
    this.isText,
    this.isHome,
  });

  @override
  State<SearchFieldOfClientSearchDialog> createState() =>
      _SearchFieldOfClientSearchDialogState();
}

class _SearchFieldOfClientSearchDialogState
    extends State<SearchFieldOfClientSearchDialog> {
  final FocusNode _focusNode = FocusNode();
  late BlBloc blBloc = BlocProvider.of(context, listen: false);

  // bool isOffline = false;

  @override
  void initState() {
    super.initState();
    blBloc = BlocProvider.of(context, listen: false);
    blBloc.add(
      BlStatusChangedEvent(
        status: BLStatus.client,
        where: 'Client',
      ),
    );
    blBloc.add(
      BlVisibilityChangedEvent(true), // Set to true to allow barcode processing
    );
  }

  // Future<void> checkConnectivity() async {
  //   var connectivityResult = await Connectivity().checkConnectivity();
  //   setState(() {
  //     isOffline = connectivityResult == ConnectivityResult.none;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    ClientBloc clientBloc = BlocProvider.of(context);
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Pref.getBool('switchClients', true) == false
        ? VisibilityDetector(
            key: const Key('visible-detector-key'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction > 0) {
                Future.delayed(Duration.zero, () {
                  FocusScope.of(context).requestFocus(_focusNode);
                });
              }
            },
            child: MyBarcodeListener(
              onBarcodeScannedClick: (v) {},
              onBarcodeScannedMagnetic: (v) {},
              onBarcodeScannedPayme: (v) {},
              onShiftDeletePressed: () {},
              onDelPressed: () {},
              onF12Pressed: () {},
              onF5pressed: () {},
              bufferDuration: const Duration(milliseconds: 300),
              onBarcodeScanned: (v) {},
              onF1pressed: () {},
              onF2pressed: () {},
              onF3pressed: () {},
              onDownPressed: () {},
              onUpPressed: () {},
              onBarcodeScannedClient: (v) {
                clientBloc.controller.text = v;
                clientBloc.add(ClientSearchEvent(widget.isText ?? false));
              },
              child: TextField(
                focusNode: _focusNode,
                enabled: true,
                // readOnly: true,
                readOnly: !(widget.isText ?? false),
                autofocus: true,
                onSubmitted: (v) {
                  clientBloc.add(ClientSearchEvent(widget.isText ?? false));
                },
                controller: clientBloc.controller,
                style: TextStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: SizeConfig.v * 2,
                ),
                cursorColor: Theme.of(context).primaryColor,
                decoration: InputDecoration(
                  contentPadding: widget.isText == true
                      ? EdgeInsets.symmetric(
                          vertical: SizeConfig.v * 2.4,
                          horizontal: SizeConfig.v * 1.1)
                      : EdgeInsets.symmetric(
                          vertical: SizeConfig.v * 1.9,
                          horizontal: SizeConfig.v * 1.1),
                  fillColor: Theme.of(context).dialogBackgroundColor,
                  filled: true,
                  suffixIcon: widget.isText == true
                      ? const Text('')
                      : IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: () {
                            if (widget.maxLen != null) {
                              if (clientBloc.controller.text.length !=
                                  widget.maxLen) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    mySnackBar(context,
                                        duration: 1500,
                                        msg: loc.yaroqsiz_id_kiritdingiz));
                                return;
                              }
                            }

                            return clientBloc
                                .add(ClientSearchEvent(widget.isText ?? false));
                          },
                          icon: Icon(
                            Icons.search,
                            color: MyThemes.lightGreyColorr,
                          ),
                        ),
                  hintStyle: TextStyle(
                    color: Theme.of(context).canvasColor,
                    fontSize: SizeConfig.v * 2,
                  ),
                  hintText: widget.isText == true
                      ? loc.ha == 'Ha'
                          ? 'Inn...'
                          : "Инн..."
                      : "${loc.id}...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.v),
                    borderSide: BorderSide.none,
                  ),
                ),
                inputFormatters: widget.isText == true
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ]
                    : [],
              ),
            ),
          )
        : VisibilityDetector(
            onVisibilityChanged: (VisibilityInfo info) {
              if (info.visibleFraction > 0) {
                Future.delayed(Duration.zero, () {
                  FocusScope.of(context).requestFocus(_focusNode);
                });
              }
            },
            key: const Key('visible-detector-key'),
            child: TextField(
              focusNode: _focusNode,
              autofocus: true,
              // enabled: !isOffline,
              onSubmitted: (v) {
                clientBloc.add(ClientSearchEvent(widget.isText ?? false));
              },
              controller: clientBloc.controller,
              style: TextStyle(
                color: Theme.of(context).canvasColor,
                fontSize: SizeConfig.v * 2,
              ),
              cursorColor: Theme.of(context).primaryColor,
              decoration: InputDecoration(
                contentPadding: widget.isText == true
                    ? EdgeInsets.symmetric(
                        vertical: SizeConfig.v * 2.5,
                        horizontal: SizeConfig.v * 1.1)
                    : EdgeInsets.symmetric(
                        vertical: SizeConfig.v * 1.9,
                        horizontal: SizeConfig.v * 1.1),
                fillColor: Theme.of(context).dialogBackgroundColor,
                filled: true,
                suffixIcon: widget.isText == true
                    ? const Text('')
                    : IconButton(
                        focusNode: FocusNode(skipTraversal: true),
                        onPressed: () {
                          if (widget.maxLen != null) {
                            if (clientBloc.controller.text.length !=
                                widget.maxLen) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  mySnackBar(context,
                                      duration: 1500,
                                      msg: loc.yaroqsiz_id_kiritdingiz));
                              return;
                            }
                          }

                          return clientBloc
                              .add(ClientSearchEvent(widget.isText ?? false));
                        },
                        icon: Icon(
                          Icons.search,
                          color: MyThemes.lightGreyColorr,
                        ),
                      ),
                hintStyle: TextStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: SizeConfig.v * 2,
                ),
                hintText: widget.isText == true
                    ? loc.ha == 'Ha'
                        ? 'Inn...'
                        : "Инн..."
                    : "${loc.id}...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.v),
                  borderSide: BorderSide.none,
                ),
              ),
              inputFormatters: widget.isText == true
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ]
                  : [],
            ),
          );
  }

  @override
  void dispose() {
    blBloc.add(
      BlStatusChangedEvent(
        status: widget.isHome == true ? BLStatus.other : BLStatus.home,
        where: widget.isHome == true ? 'Other' : 'Home',
      ),
    );
    blBloc.add(
      BlVisibilityChangedEvent(false),
    );
    super.dispose();
  }
}
