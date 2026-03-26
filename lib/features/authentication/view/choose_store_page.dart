import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/authentication/bloc/ss_bloc/ss_bloc.dart';
import 'package:invan2/features/authentication/view/phone_number_page.dart';
import 'package:invan2/widgets/auth_background_widget.dart';
import '../model/model.dart';
import 'choose_store_card.dart';

class ChooseStorePage extends StatelessWidget {
  const ChooseStorePage({
    super.key,
    required this.token,
    required this.stores,
  });

  final String token;
  final List<StoresModel> stores;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AuthBackgroundWidget(
        onPres: () {
          AppNavigation.pushReplacement(const PhoneNumberPage());
        },
        isBackButtoned: true,
        isWaiting: false,
        child: BlocProvider(
          create: (context) => SsBloc(
            selectedStore: stores.first,
            token: token,
            stores: stores,
          ),
          child: const ChooseStoreCard(),
        ),
      ),
    );
  }
}
