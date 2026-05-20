import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/dialogs/upd/bloc/upd_bloc.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_main_widget.dart';

class UpdDialog extends StatelessWidget {
  const UpdDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UpdBloc(),
      child: const UpdDialogMainWidget(),
    );
  }
}
