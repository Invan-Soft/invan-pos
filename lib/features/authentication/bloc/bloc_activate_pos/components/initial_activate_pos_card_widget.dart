import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/authentication/bloc/bloc_activate_pos/apd_bloc_bloc.dart';
// import 'package:invan2/features/authentication/bloc/bloc_activate_pos/apd_bloc_bloc.dart';
import 'package:invan2/features/authentication/model/get_available_pos_response.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/default_button.dart';

import '../../../../../utils/l10n/app_localizations.dart';

// ignore: must_be_immutable
class ActivatePosDeviceInitialWidget extends StatelessWidget {
  ActivatePosDeviceInitialWidget({
    super.key,
    required this.selectedPosName,
    required this.availablePosList,
    required this.isButtonEnabled,
    required this.defaultButtonPressed,
  });
  final VoidCallback defaultButtonPressed;
  final String selectedPosName;
  final List<GetAvailablePosResponseData> availablePosList;
  final bool isButtonEnabled;
  late AppLocalizations loc;
  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!;
    APDblocc apDbloc = BlocProvider.of(context, listen: false);

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.v * 3.2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                availablePosList.isEmpty
                    ? Container(
                        height: 5,
                        width: 5,
                        color: Colors.red,
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.v,
                          vertical: SizeConfig.v * .8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(SizeConfig.v),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: PopupMenuButton(
                          color: MyThemes.lightGreyColorr,
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 2,
                                  color: Theme.of(context).primaryColor),
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.v)),
                          tooltip: loc.mavjud_pos_qurilmalar,
                          onSelected: (selectedPosId) {
                            apDbloc.add(APDselectPosEvent(selectedPosId));
                          },
                          // offset: const Off  set(.5, 0.0),
                          position: PopupMenuPosition.over,
                          itemBuilder: (_) {
                            return availablePosList.map(
                              (e) {
                                return PopupMenuItem(
                                  value: e.sId,
                                  child: SizedBox(
                                    width: SizeConfig.h * 30,
                                    child: Text(
                                      e.name!,
                                      style: MyThemes.txtStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList();
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  isButtonEnabled ? selectedPosName : "",
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
                        ),
                      ),
                SizedBox(height: SizeConfig.v * 2),
                DefaultButton(
                  onPress: defaultButtonPressed,
                  text: loc.keyingisi,
                  isButtonEnabled: isButtonEnabled,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: SizeConfig.v * (isButtonEnabled ? 2.2 : 5.2),
          left: SizeConfig.v * 5,
          child: Text(
            "  ${loc.kassa_tanlang}  ",
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
}
