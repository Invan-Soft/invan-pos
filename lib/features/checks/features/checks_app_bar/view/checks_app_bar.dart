import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/checks/features/checks_app_bar/bloc/usr_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/widgets.dart';
import '../../../../../utils/l10n/app_localizations.dart';
import 'build_checks_text.dart';

class ChecksAppBarr extends StatefulWidget {
  const ChecksAppBarr({
    super.key,
    required this.pressLockButton,
  });

  final VoidCallback pressLockButton;

  @override
  State<ChecksAppBarr> createState() => _ChecksAppBarrState();
}

late StreamSubscription subscription;
late UsrBloc usrBloc;

class _ChecksAppBarrState extends State<ChecksAppBarr> {
  @override
  void initState() {
    usrBloc = BlocProvider.of(context);
    Stream<Query<ReceiptModel4>>? stream =
        MyObjectbox.saleStore.box<ReceiptModel4>().query().watch();
    subscription = stream.listen((event) async {
      int v = event
          .find()
          .reversed
          .toList()
          .where((e) => !e.uploaded)
          .toList()
          .length;
      usrBloc.add(UsrDataChangedEvent(v));
    });
    super.initState();
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;

    return Container(
      width: SizeConfig.h * 100 - 16,
      height: SizeConfig.v * 9.5,
      color: Theme.of(context).colorScheme.background,
      child: Row(
        children: [
          SizedBox(width: SizeConfig.h),
          TextButton(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              AppNavigation.pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(0.0),
              foregroundColor: Theme.of(context).colorScheme.background,
            ),
            child: Icon(
              Icons.arrow_back_ios,
              size: SizeConfig.v * 5,
              color: Theme.of(context).canvasColor,
            ),
          ),
          const BuildChecksText(),
          BlocConsumer<UsrBloc, UsrState>(listener: ((context, state) async {
            if (state is UsrFinishedState ||
                state is UsrNoUnsentReceiptsState ||
                state is UsrNoInternetState) {
              await Future.delayed(const Duration(seconds: 2));
              usrBloc.add(UsrCallInitialEvent());
            }
          }), builder: (_, state) {
            if (state is UsrAlreadyInProgressState) {
              return _setText(loc.jonatish_allaqachon_ishlamoqda, context);
            }
            if (state is UsrBackendRejectedState) {
              return _setText("SERVER ERROR: ${state.error}", context);
            }

            if (state is UsrErrorState) {
              return _setText("ERROR: ${state.error}", context);
            }

            if (state is UsrFinishedState) {
              return _setText(loc.jonatish_tugatildi, context);
            }
            if (state is UsrInSendingState) {
              return _setText(loc.jonatish_jaroyonda, context);
            }
            if (state is UsrNoInternetState) {
              return _setText(loc.internet_yoq, context);
            }
            if (state is UsrLoadingState) {
              if (state.message.isEmpty) {
                return CupertinoActivityIndicator(
                  radius: SizeConfig.v * 2,
                );
              }
              return _setText(loc.internet_tekshirilmoqda, context);
            }
            if (state is UsrNoUnsentReceiptsState) {
              return _setText(loc.jonatilmagan_cheklar_mavjud_emas, context);
            }
            return _setText(
                "${usrBloc.unsents == 0 ? "" : "${usrBloc.unsents}"} ${usrBloc.uploadingWorkingg ? loc.jonatish_jaroyonda : ""}",
                context);
          }),
          const SizedBox(width: 20),
          AppBarSyncButton(
            onPress: () {
              usrBloc
                  .add(UsrSendSpecialEvent("Checks appBar", usrBloc.unsents));
            },
          ),
          AppBarLockButton(
            onPress: widget.pressLockButton,
            color: Theme.of(context).colorScheme.background,
          ),
          AppBarLamp(),
          SizedBox(width: SizeConfig.h * 2),
        ],
      ),
    );
  }

  Text _setText(String v, BuildContext context) {
    return Text(
      v,
      style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
    );
  }
}
