import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/settings/bloc/settings_bloc.dart';
import 'payments/payments.dart';
import 'package:invan2/features/settings/view/pincode.dart';
import 'report_setting/settings_reports_page.dart';
import 'package:invan2/utils/themes.dart';
import '../features/features.dart';
import 'left_side.dart';

class SettingsContent extends StatefulWidget {
  const   SettingsContent({Key? key}) : super(key: key);

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  @override
  Widget build(BuildContext context) {
    SettingsBloc settingsBloc = context.watch();
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: LeftSide(index: settingsBloc.index),
          ),
          Container(
            height: double.infinity,
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
          BlocConsumer<SettingsBloc, SettingsState>(
            listener: (context, state) async {
              if (state is SettingsInvalidPinState) {
                await Future.delayed(const Duration(milliseconds: 500));
                settingsBloc.add(SettingsCallPinEvent(state.status));
              }
            },
            builder: (context, state) {
              if (state is SettingsInitial) {
                return _bg(const PrintersContent());
              } else if (state is SettingsSettingsState ||
                  state is SettingsInitial) {
                return _bg(const ChildSettingsContent());
              } else if (state is SettingsPinState) {
                return _bg(PincodeWidgetOfSettingss(status: state.status));
              } else if (state is SettingsReportsState) {
                return _bg(const SettingsReportPage());
              } else if (state is SettingsClickState) {
                return _bg(const ClickContent());
              } else if (state is SettingsHumoState) {
                return _bg(const HumoContent());
              } else if (state is SettingsPaymeState) {
                return _bg(const PaymeContent());
              } else if (state is SettingsUzumState) {
                return _bg(const UzumContent());
              } else if (state is SettingsInvalidPinState) {
                return _bg(
                  Center(
                    child: Text(
                      loc.notogri_pin_kiritdingiz,
                      style: MyThemes.txtStyle(
                        fontSize: 5,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ),
                );
              }
              return _bg(
                const Center(
                  child: Text(
                    "State managment error",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Expanded _bg(Widget child) {
    return Expanded(
      flex: 5,
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: Theme.of(context).dialogBackgroundColor,
        child: child,
      ),
    );
  }
}
