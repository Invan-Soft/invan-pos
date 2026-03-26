import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

import '../../../../../utils/l10n/app_localizations.dart';

class ChecksSearchFieldWidgett extends StatefulWidget {
  final TextEditingController controller;

  const ChecksSearchFieldWidgett({super.key, required this.controller});

  @override
  State<ChecksSearchFieldWidgett> createState() =>
      _ChecksSearchFieldWidgettState();
}

class _ChecksSearchFieldWidgettState extends State<ChecksSearchFieldWidgett> {
  @override
  Widget build(BuildContext context) {
    CheckFBloc checkFBloc = BlocProvider.of(context);
    AppLocalizations loc = AppLocalizations.of(context)!;
    return BlocBuilder<CheckFBloc, CheckFState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.all(SizeConfig.h),
          child: SizedBox(
            height: SizeConfig.v * 5,
            child: TextField(
              controller: widget.controller,
              style: TextStyle(color: Theme.of(context).canvasColor),
              cursorColor: Theme.of(context).primaryColor,
              onChanged: (value) {
                if (value.isEmpty) {
                  widget.controller.text = '';
                  checkFBloc.add(CheckFCallInitialEvent());
                  return;
                }
                setState(() {
                  checkFBloc.isOk = false;
                });
              },
              onSubmitted: (v) {
                if (v.isEmpty) {
                  widget.controller.text = '';
                  checkFBloc.add(CheckFCallInitialEvent());
                  return;
                }
                checkFBloc
                    .add(CheckFSearchGlobalEvent(v, page: 1, fromSubmit: true));
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.background,
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).primaryColor,
                ),
                suffixIcon: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(2),
                  width: SizeConfig.h * 6,
                  height: SizeConfig.v * 5,
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(SizeConfig.v - 2))),
                  child: TextButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () {
                      if (checkFBloc.isOk) {
                        widget.controller.text = '';
                        checkFBloc.add(CheckFCallInitialEvent());
                        return;
                      }
                      if (widget.controller.text.isEmpty) {
                        widget.controller.text = '';
                        checkFBloc.add(CheckFCallInitialEvent());
                        return;
                      }
                      checkFBloc.add(
                        CheckFSearchGlobalEvent(widget.controller.text,
                            page: 1, fromSubmit: true),
                      );
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.all(0.0)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          checkFBloc.isOk ? "CLEAR" : "SEARCH",
                          style: MyThemes.txtStyleWhite(),
                        ),
                      ),
                    ),
                  ),
                ),
                errorBorder: _border(),
                enabledBorder: _border(),
                focusedBorder: _border(),
                disabledBorder: _border(),
                border: _border(),
                hintStyle: TextStyle(color: Theme.of(context).primaryColor),
                hintText: loc.chekRaqaminiKiriting,
              ),
            ),
          ),
        );
      },
    );
  }

  OutlineInputBorder _border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(SizeConfig.v),
      borderSide: BorderSide.none);
}
