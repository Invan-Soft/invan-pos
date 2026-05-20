import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/changes/components/form_validator.dart';
import 'package:invan2/features/authentication/bloc/auth_bloc/auth_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/widgets/apd_text_widget.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../utils/l10n/app_localizations.dart';

class PhoneNumberCard extends StatefulWidget {
  const PhoneNumberCard({super.key});

  @override
  PhoneNumberCardState createState() => PhoneNumberCardState();
}

class PhoneNumberCardState extends State<PhoneNumberCard> {
  final TextStyle _inputStyle = MyThemes.txtStyle(
    fontWeight: FontWeight.bold,
    color: const Color(0xff434862),
    fontSize: 2.9,
  );
  TextEditingController smsController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passController = TextEditingController();

  late AuthBloc authBloc;

  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _smsFocusNode = FocusNode(skipTraversal: true);

  @override
  void dispose() {
    _phoneNumberFocusNode.dispose();
    _smsFocusNode.dispose();

    super.dispose();
  }

  late AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    authBloc = BlocProvider.of(context, listen: false);
    loc = AppLocalizations.of(context)!;

    return Container(
      width: SizeConfig.v * 73,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.v * 1.56),
      ),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthInitialState) {
            if (state.restart) {
              phoneController.text = '';
              smsController.text = '';
            } else if (state.smsRestart ?? false) {
              smsController.text = '';
            }
          }
        },
        builder: (context, state) {
          if (state is AuthVerifyFailedState) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.v * 3),
                child: Column(
                  children: [
                    ApdText(
                      state.error.isEmpty
                          ? loc.internet_yoq
                          : (state.error == "empty"
                              ? loc.xodim_uchun_tashkilot_biriktirilmagan
                              : state.error),
                    ),
                    SizedBox(
                      height: SizeConfig.v * 5,
                    ),
                    DefaultButton(
                      isButtonEnabled: true,
                      text: loc.qayta_urinish,
                      onPress: () {
                        if (state.error
                            .trim()
                            .toLowerCase()
                            .contains("Incorrect sms code".toLowerCase())) {
                          authBloc.add(AuthSmsIncorrectEvent());
                          return;
                        }
                        authBloc.add(AuthInitialEvent());
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is AuthInitialState) {
            return Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.v * 3.2, horizontal: SizeConfig.v * 3.2),
              child: Column(
                children: [
                  _phoneNumberField(
                    readOnly: state.isSms,
                    buttonState: state.enabled,
                    autoFocus: !state.isSms,
                  ),
                  SizedBox(height: SizeConfig.v * 0.7),
                  _usernameField(
                    readOnly: state.isSms,
                    buttonState: state.enabled,
                    // autoFocus: !state.isSms,
                    autoFocus: false,
                  ),
                  // state.isSms
                  //     ? _smsField(buttonState: state.enabled)
                  //     : const SizedBox(height: 0),
                  // SizedBox(height: SizeConfig.v * 0.7),
                  // _posType(),
                  SizedBox(height: SizeConfig.v * 1),

                  _buttonn(
                    buttonState: state.enabled,
                    context: context,
                    isSms: state.isSms,
                  ),
                ],
              ),
            );
          }
          if (state is AuthLoadingState) {
            return Container(
              padding: EdgeInsets.all(SizeConfig.v * 5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SizeConfig.h)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SpinKitCircle(
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(
                    height: SizeConfig.v * 2,
                  ),
                  ApdText(
                    state.message,
                  ),
                ],
              ),
            );
          }
          if (state is AuthLoadingFailedState) {
            return Padding(
              padding: EdgeInsets.all(SizeConfig.v * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ApdText(
                    "ERROR: ${state.message}",
                  ),
                  SizedBox(
                    height: SizeConfig.v * 5,
                  ),
                  DefaultButton(
                    onPress: () {
                      authBloc.add(AuthInitialEvent());
                    },
                    text: loc.qayta_urinish,
                    isButtonEnabled: true,
                  )
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  _phoneNumberField(
      {required bool buttonState,
      required bool autoFocus,
      required bool readOnly}) {
    return SizedBox(
      height: SizeConfig.v * 7,
      child: TextField(
        controller: phoneController,
        textInputAction: TextInputAction.next,
        onChanged: (v) {
          authBloc.add(AuthTypePhoneNumberEvent(v));
        },
        onSubmitted: (v) {
          authBloc.add(
            AuthOnSubmittedPhoneNumberEvent(
              str: phoneController.text,
              loc: loc,
              pass: passController.text,
            ),
          );
        },
        // readOnly: readOnly,
        // focusNode: _phoneNumberFocusNode,
        decoration: _decoration(isSms: false, label: loc.tel_raqam),
        style: _inputStyle,
        // autofocus: autoFocus,
        inputFormatters: <TextInputFormatter>[FormValidator.phoneFormatter],
      ),
    );
  }

  _usernameField(
      {required bool buttonState,
      required bool autoFocus,
      required bool readOnly}) {
    return SizedBox(
      height: SizeConfig.v * 7,
      child: TextField(
        controller: passController,
        onSubmitted: (v) {
          authBloc.add(
            AuthOnSubmittedPhoneNumberEvent(
              str: phoneController.text,
              loc: loc,
              pass: passController.text,
            ),
          );
        },
        readOnly: readOnly,
        // focusNode: _phoneNumberFocusNode,
        decoration: _labelDecoration(isSms: false, label: "*Пароль"),
        style: _inputStyle,
        autofocus: autoFocus,
      ),
    );
  }

  _posType() {
    return PopupMenuButton(
      color: MyThemes.lightGreyColorr,
      padding: const EdgeInsets.all(5),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        borderRadius: BorderRadius.circular(SizeConfig.v),
      ),
      tooltip: '',
      child: Container(
        height: SizeConfig.v * 7,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
          borderRadius: BorderRadius.circular(SizeConfig.v),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
              child: Pref.getBool(PrefKeys.withOFD, false)
                  ? Text(
                      "OFD",
                      style: MyThemes.txtStyle(fontSize: 2),
                    )
                  : Text(
                      "Simple",
                      style: MyThemes.txtStyle(fontSize: 2),
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
      onSelected: (type) {
        if (type == PosType.ofd) {
          Pref.setBool(PrefKeys.withOFD, true);
          Pref.setBool(PrefKeys.withINCOM, false);
        } else {
          Pref.setBool(PrefKeys.withOFD, false);
          Pref.setBool(PrefKeys.withINCOM, false);
        }
        setState(() {});
      },
      itemBuilder: (_) {
        return [
          PopupMenuItem(
            value: PosType.ofd,
            child: SizedBox(
              width: SizeConfig.h * 30,
              child: Text(
                "OFD",
                style: MyThemes.txtStyle(fontSize: 2),
              ),
            ),
          ),
          PopupMenuItem(
            value: PosType.simple,
            child: SizedBox(
              width: SizeConfig.h * 30,
              child: Text(
                "Simple",
                style: MyThemes.txtStyle(fontSize: 2),
              ),
            ),
          ),
        ];
      },
    );
  }

  _buttonn(
      {required bool buttonState,
      required BuildContext context,
      required bool isSms}) {
    return DefaultButton(
      text: isSms ? loc.tizimgaKirish : loc.kirish,
      isButtonEnabled: buttonState,
      onPress: () {
        authBloc.add(
          AuthOnSubmittedPhoneNumberEvent(
            str: phoneController.text,
            loc: loc,
            pass: passController.text,
          ),
        );
        // }
      },
    );
  }

  InputDecoration _decoration({required String label, required bool isSms}) {
    return InputDecoration(
        constraints: BoxConstraints(maxHeight: SizeConfig.v * 7.55),
        prefix: isSms ? const Text("") : Text("+998", style: _inputStyle),
        label: Text(
          label,
          style: MyThemes.txtStyle(fontSize: 2),
        ),
        focusedBorder: _inputBorder(),
        enabledBorder: _inputBorder(),
        disabledBorder: _inputBorder(),
        border: _inputBorder());
  }

  InputDecoration _labelDecoration(
      {required String label, required bool isSms}) {
    return InputDecoration(
        constraints: BoxConstraints(maxHeight: SizeConfig.v * 7.55),
        label: Text(
          label,
          style: MyThemes.txtStyle(fontSize: 2),
        ),
        focusedBorder: _inputBorder(),
        enabledBorder: _inputBorder(),
        disabledBorder: _inputBorder(),
        border: _inputBorder());
  }

  OutlineInputBorder _inputBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      );
}

enum PosType {
  simple,
  ofd,
}
