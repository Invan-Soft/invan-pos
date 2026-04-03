import 'package:flutter/material.dart';
import 'package:invan2/features/authentication/bloc/auth_bloc/phone_number_card.dart';
import 'package:invan2/idle_service.dart';
import 'package:invan2/widgets/auth_background_widget.dart';


class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {

@override
void initState() {
  super.initState();
  IdleService().onCriticalAuthPageEntered();   // ← YANGI
}

@override
void dispose() {
  IdleService().onCriticalAuthPageExited();    // ← YANGI
  super.dispose();
}

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
