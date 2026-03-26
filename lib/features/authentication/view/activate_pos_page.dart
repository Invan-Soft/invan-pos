import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/authentication/bloc/bloc_activate_pos/apd_bloc_bloc.dart';
import 'package:invan2/features/authentication/view/activate_pos_card_bloc.dart';
import 'package:invan2/features/authentication/view/phone_number_page.dart';
import 'package:invan2/widgets/auth_background_widget.dart';
import '../model/model.dart';

class ActivatePosPage extends StatelessWidget {
  const ActivatePosPage({
    Key? key,
    required this.token,
    required this.availablePosList,
    required this.selectedStore,
    required this.macAddress,
  }) : super(key: key);

  final String token;
  final List<GetAvailablePosResponseData> availablePosList;
  final StoresModel selectedStore;
  final String macAddress;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: BlocProvider(
        create: (context) => APDblocc(
            availablePosList: availablePosList,
            selectedStore: selectedStore,
            selectedPos:
                availablePosList.isEmpty ? null : availablePosList.first),
        child: AuthBackgroundWidget(
          onPres: () {
             AppNavigation.pushReplacement(const PhoneNumberPage());
          },
          isBackButtoned: true,
          isWaiting: false,
          child: ActivatePosCardBloc(
            acceptService: selectedStore.id,
            macAddress: macAddress,
            token: token,
          ),
        ),
      ),
    );
  }
}
