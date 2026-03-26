import 'package:flutter/material.dart';
import 'package:invan2/features/authentication/bloc/auth_bloc/phone_number_card.dart';
import 'package:invan2/widgets/auth_background_widget.dart';


class PhoneNumberPage extends StatelessWidget {
  const PhoneNumberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AuthBackgroundWidget(
        onPres: () async {
        },
        isBackButtoned: false,
        isWaiting: false,
        child: const PhoneNumberCard(),
      ),
    );
  }
}
