import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'local_category/add_local_category_dialog/dialog_content.dart';

class AddLocalCategoryButton extends StatelessWidget {
  const AddLocalCategoryButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      minWidth: SizeConfig.v * 10,
      height: double.infinity,
      color: Theme.of(context).colorScheme.background,
      child: Icon(
        Icons.add,
        size: SizeConfig.v * 5,
        color: Theme.of(context).dialogBackgroundColor,
      ),
      onPressed: () {
        showDialog(
            context: context, builder: (_) => const AddLocalCategoryDialog());
      },
    );
  }
}
