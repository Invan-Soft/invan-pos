import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../changes/providers/return_page_provider.dart';
import '../return_page_dialog/return_page_dialog.dart';

class BuildLeftList extends StatefulWidget {
  const BuildLeftList({Key? key}) : super(key: key);

  @override
  BuildLeftListState createState() => BuildLeftListState();
}

class BuildLeftListState extends State<BuildLeftList> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final returnPageProvider = Provider.of<ReturnPageProviderr>(context);
    final leftList = returnPageProvider.getLeftList;
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: leftList.length,
      itemBuilder: (context, index) {
        final item = leftList[index];
        return Material(
          color: Theme.of(context).dialogBackgroundColor,
          child: ListTile(
            onTap: () async {
              returnPageProvider.pressLeftIndex(index);
              if (item.value != 1) {
                double? returnedValue = await showDialog(
                  context: context,
                  builder: (_) => ReturnPageDialogg(value: item.value),
                );
                if (returnedValue == null) return;
                returnPageProvider.pressLeftProductDialog2(returnedValue);
              } else {
                returnPageProvider.pressLeftProduct();
              }
            },
            hoverColor: Theme.of(context).primaryColor,
            title: Text(
              '${item.productName} x ${item.value % 1 == 0 ? item.value.toStringAsFixed(0) : item.value.toString()}',
              style: MyThemes.txtStyle(
                fontSize: 2.3,
                color: Theme.of(context).canvasColor,
              ),
            ),
            trailing: Text(
              // '${item.price! * item.value!}',
              MoneyFormatter.formatVat.format(item.price * item.value),
              style: MyThemes.txtStyle(
                fontSize: 2.3,
                color: Theme.of(context).canvasColor,
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
