import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../../../utils/utils.dart';
import '../../../../bloc/barcode_listener_bloc/bl_bloc.dart';
import 'local_category/add_local_category_dialog/dialog_content.dart';
import 'local_category_button.dart';
import 'package:invan2/features/features.dart';

class LocalCategoryButtons extends StatefulWidget {
  const LocalCategoryButtons({super.key});

  @override
  LocalCategoryButtonsState createState() => LocalCategoryButtonsState();
}

class LocalCategoryButtonsState extends State<LocalCategoryButtons> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final LocalCategoryProvider localCategoryProvider =
        Provider.of<LocalCategoryProvider>(context);
    final localCategoryList = localCategoryProvider.getLocalCategoryList;
    final currentSelectedButton =
        localCategoryProvider.getCurrentSelectedCategoryButton;

    BlBloc blBloc = BlocProvider.of(context, listen: false);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalCategoryButton(
          onPress: () {
            localCategoryProvider.pressBarchasiButton(context: context);
          },
          text: loc.barchasi,
          isSelected: currentSelectedButton < 0,
        ),
        ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: .5),
          shrinkWrap: true,
          controller: _scrollController,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: localCategoryList.length + 1,
          itemBuilder: (context, index) {
            if (index == localCategoryList.length) {
              return Container(
                margin: const EdgeInsets.only(left: 0.0),
                width: SizeConfig.h * 6,
                height: SizeConfig.v * 9,
                child: MaterialButton(
                  focusNode: FocusNode(skipTraversal: true),
                  child: Icon(
                    Icons.add,
                    size: SizeConfig.v * 5,
                    color: Theme.of(context).dialogBackgroundColor,
                  ),
                  onPressed: () async {
                    blBloc.add(BlStatusChangedEvent(
                        status: BLStatus.other,
                        where:
                            "lib/features/home/features/home_products/shift_opened/bottom_buttons/bottom_buttons.dart"));
                    await showDialog(
                        context: context,
                        builder: (_) => const AddLocalCategoryDialog());

                    blBloc.add(BlStatusChangedEvent(
                        status: BLStatus.home,
                        where:
                            "lib/features/home/features/home_products/shift_opened/bottom_buttons\bottom_buttons.dart"));
                  },
                ),
              );
            }
            final item = localCategoryList[index];
            return LocalCategoryButton(
              text: item.name,
              isSelected: currentSelectedButton == index,
              onPress: () => localCategoryProvider.pressCategoryButton(
                context: context,
                index: index,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
