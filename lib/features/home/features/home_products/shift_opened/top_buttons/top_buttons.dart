import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'path.dart';
import 'package:provider/provider.dart';
import 'package:invan2/features/features.dart';

class TopButtons extends StatelessWidget {
  const TopButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocalCategoryProvider>(context);
    final isEditingLocalCategory = provider.getIsLocalCategoryEditing;

    return Container(
      height: SizeConfig.v  * 5.17,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(

            color: Theme.of(context).highlightColor,
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: Path()),
          isEditingLocalCategory
              ? const Positioned(
                  top: 0,
                  left: 0,
                  child:  SizedBox(width: 0, height: 0),
                )
              : const Positioned.fill(
                  child: SizedBox(),
                ),
        ],
      ),
    );
  }
}
