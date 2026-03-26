import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:provider/provider.dart';
import '../../../../changes/providers/return_page_provider.dart';
import 'package:invan2/utils/themes.dart';
import '../return_page_dialog/return_page_dialog.dart';

class BuildRightList extends StatefulWidget {
  const BuildRightList({super.key});

  @override
  BuildRightListState createState() => BuildRightListState();
}

class BuildRightListState extends State<BuildRightList> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final returnPageProvider = Provider.of<ReturnPageProviderr>(context);
    final rightList = returnPageProvider.getRightList;

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: rightList.length,
      itemBuilder: (context, index) {
        final item = rightList[index];

        return Material(
          color:Theme.of(context).dialogBackgroundColor,
          child: ListTile(
            onTap: () async {
              returnPageProvider.pressRightIndex(index);

              if (item.value != 1) {
                double returnedValue = await showDialog(
                  context: context,
                  builder: (_) => ReturnPageDialogg(value: item.value),
                );

                returnPageProvider.pressRightProductDialog2(returnedValue);
              } else {
                returnPageProvider.pressRightProduct();
              }
            },
            hoverColor: Theme.of(context).primaryColor,
            title: Text(
              '${item.productName} x ${item.value % 1 == 0 ? item.value.toStringAsFixed(0) : item.value.toString()}',
              style: MyThemes.txtStyle(
                fontSize: 2.3,
                color:Theme.of(context).canvasColor
              ),
            ),
            trailing: Text(
              MoneyFormatter.formatVat.format(item.price * item.value),
              style: MyThemes.txtStyle(
                fontSize: 2.3,
                color:Theme.of(context).canvasColor,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
