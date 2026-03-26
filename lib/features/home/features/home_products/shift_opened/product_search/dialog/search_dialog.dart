import 'package:flutter/material.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/app_virtual_keyboard.dart';
import 'package:invan2/utils/utils.dart';
import 'search_dialog_content.dart';
import '../../../../../../../changes/providers/product_search_provider.dart';

class SearchDialog extends StatelessWidget {
  const SearchDialog({
    super.key,
    required this.searchTypeEnum,
  });

  final SearchTypeEnum searchTypeEnum;

  @override
  Widget build(BuildContext context) {
    final bool virtualKeyboardOn =
        Pref.getBool(PrefKeys.virtualKeyboard, false);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: SizeConfig.v * 2,
        ),
        child: Container(
          width: SizeConfig.h * 72,
          height: SizeConfig.v * 94,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 13,
                  spreadRadius: 1,
                  offset: Offset(1, 1),
                ),
              ],
              color: Theme.of(context).colorScheme.background),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
              color: Theme.of(context).dialogBackgroundColor,
              child: virtualKeyboardOn
                  ? Column(
                      children: [
                        Expanded(
                          child: SearchDialogContent(
                              searchTypeEnum: searchTypeEnum),
                        ),
                        AppVirtualKeyboardDialog(searchTypeEnum: searchTypeEnum)
                      ],
                    )
                  : SearchDialogContent(searchTypeEnum: searchTypeEnum),
            ),
          ),
        ),
      ),
    );
  }
}
