import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/no_access_dialog/bg_of_nad.dart';
import 'package:invan2/changes/dialogs/no_access_dialog/bloc/nad_bloc.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';

class NoAccessDialogContent extends StatefulWidget {
  const NoAccessDialogContent({Key? key}) : super(key: key);

  @override
  State<NoAccessDialogContent> createState() => _NoAccessDialogContentState();
}

class _NoAccessDialogContentState extends State<NoAccessDialogContent> {
  late FocusNode focusNode;
  @override
  void initState() {
    focusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    NadBloc nadBloc = BlocProvider.of(context);
    return BlocConsumer<NadBloc, NadState>(
      listener: (context, state) async {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }

        if (state is NadSuccessedState) {
          await Future.delayed(const Duration(seconds: 1));
          AppNavigation.pop(v: true);
        }
        if (state is NadFailedState) {
          await Future.delayed(const Duration(seconds: 1));
          nadBloc.add(NadCallInitialEvent());
        }
      },
      builder: (context, state) {
        if (state is NadLoadingState) {
         return BgOfNad(
              color: Theme.of(context).primaryColor,
              child: Center(
                  child: CupertinoActivityIndicator(radius: SizeConfig.v * 4)));
        }
        if (state is NadSuccessedState) {
          return BgOfNad(
            color: Colors.greenAccent,
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: SizeConfig.v * 23,
            ),
          );
        }
        if (state is NadFailedState) {
          return BgOfNad(
            color: Colors.redAccent,
            child: Icon(
              Icons.cancel,
              color: Colors.white,
              size: SizeConfig.v * 23,
            ),
          );
        }
        return BgOfNad(
          color: Colors.redAccent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                        text: "Your have not permission to cancel ordering.",
                        style: MyThemes.txtStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text:
                            "\nPlease call someone who has permission to cancel ordering.",
                        style: MyThemes.txtStyle(
                            color: Colors.white, fontSize: 3.5),
                      )
                    ]),
                  ),
                ),
              ),
              SizedBox(
                height: 70,
                child: TextField(
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.redAccent),
                  showCursor: false,
                  cursorHeight: 0.0,
                  cursorColor: Colors.transparent,
                  onSubmitted: (v) => nadBloc.add(NadScannedEvent(v)),
                  decoration: InputDecoration(
                    hoverColor: Colors.redAccent,
                    fillColor: Colors.transparent,
                    filled: true,
                    border: _border(),
                    errorBorder: _border(),
                    enabledBorder: _border(),
                    focusedBorder: _border(),
                    disabledBorder: _border(),
                    focusedErrorBorder: _border(),
                  ),
                ),
              ),
              DefaultButton(
                text: "Cancel",
                isButtonEnabled: true,
                onPress: () {
                  AppNavigation.pop(v: false);
                },
              )
            ],
          ),
        );
      },
    );
  }

  OutlineInputBorder _border() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide.none,
    );
  }
}
