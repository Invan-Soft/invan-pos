import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/dialogs/upd/bloc/upd_bloc.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_text.dart';
import 'package:invan2/utils/helpers/upper_case_string_extention.dart';

class UpdFailedWidget extends StatelessWidget {
  final UpdFailedRepo repo;
  const UpdFailedWidget({
    required this.repo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    UpdBloc updBloc = BlocProvider.of(context);
    return CupertinoAlertDialog(
      title: CupertinoActionSheetAction(
        onPressed: () => updBloc.add(UpdCallSomeFailedEvent()),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
                title: UpdText(
                  repo.apdStatus.name.capitalize(),
                  textAlign: TextAlign.start,
                ),
              ),
              UpdText("ERROR: ${repo.error!}")
            ],
          ),
        ),
      ),
    );
  }
}
