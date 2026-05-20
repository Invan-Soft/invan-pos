import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

class AddLocalCategoryDialog extends StatefulWidget {
  const AddLocalCategoryDialog({Key? key}) : super(key: key);

  @override
  AddLocalCategoryDialogState createState() => AddLocalCategoryDialogState();
}

class AddLocalCategoryDialogState extends State<AddLocalCategoryDialog> {
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
         width: SizeConfig.v * 60 ,
        height: SizeConfig.v * 10,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(
            SizeConfig.v,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).canvasColor,
              blurRadius: 4,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.v,
        ),
        child: Center(
          child: TextField(
            enableInteractiveSelection: true,
            autofocus: true,
            focusNode: _focusNode,
            style: MyThemes.txtStyle(
              color: Theme.of(context).canvasColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: loc.nominiKiriting,
              hintStyle: MyThemes.txtStyle(color: Colors.grey),
            ),
            onSubmitted: (v) {
              if (v.isEmpty) {
                _focusNode.requestFocus();
              } else {
                AppNavigation.pop();
                AppNavigation.pop();
                Provider.of<LocalCategoryProvider>(context, listen: false)
                    .pressAddCategoryButton(context, v);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
