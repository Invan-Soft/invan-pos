import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/dialogs/no_access_dialog/bloc/nad_bloc.dart';
import 'package:invan2/changes/dialogs/no_access_dialog/no_access_dialog_content.dart';
import 'package:invan2/utils/helpers/size_config.dart';

class NoAccessDialog extends StatelessWidget {
  const NoAccessDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(

        alignment: Alignment.center,
        width: SizeConfig.h * 40.58,
        height: SizeConfig.v * 75.7,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        child: BlocProvider(
          create: (context) => NadBloc(),
          child:const   NoAccessDialogContent(),
        ),
      ),
    );
  }
}
