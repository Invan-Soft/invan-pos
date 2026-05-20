import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/changes/dialogs/add_description/input_text/comments_input.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

class AddDescriptionDialog extends StatefulWidget {
  final BuildContext con;

  const AddDescriptionDialog(this.con, {Key? key}) : super(key: key);

  @override
  State<AddDescriptionDialog> createState() =>
      _ClientSearchDialogWithBlocState();
}

class _ClientSearchDialogWithBlocState extends State<AddDescriptionDialog> {
  bool isWaiting = false;
  bool isOkButtonPressed = false;

  late ClientBloc clientBloc;
  @override
  void initState() {
    clientBloc = BlocProvider.of(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        width: SizeConfig.h * 38.96,
        height: SizeConfig.v * 23 ,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: MyThemes.textWhiteColor,
              blurRadius: 3,
            ),
          ],
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        child: const AddInputCommentDialog(),
      ),
    );
  }
}
