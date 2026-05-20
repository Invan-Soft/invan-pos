import 'package:flutter/material.dart';

import '../../../../../app_navigation.dart';
import '../../../../../changes/services/api.dart';
import '../../../../../utils/utils.dart';
import '../../../../../widgets/widgets.dart';
import '../../../../hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';

class EditRejectedReceiptsFieldsDialog extends StatefulWidget {
  final ReceiptModel4 receiptList;

  const EditRejectedReceiptsFieldsDialog({
    Key? key,
    required this.receiptList,
  }) : super(key: key);

  @override
  State<EditRejectedReceiptsFieldsDialog> createState() =>
      _EditRejectedReceiptsFieldsDialogState();
}

class _EditRejectedReceiptsFieldsDialogState
    extends State<EditRejectedReceiptsFieldsDialog> {
  final TextEditingController exC = TextEditingController();
  final TextEditingController reject = TextEditingController();
  late bool locationSwitch;

  static _put10(List<ReceiptModel4> receiptList) {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    if (receiptList.length > 1) {
      box.putMany(receiptList);
    } else {
      box.put(receiptList[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.white,
      color: Theme.of(context).colorScheme.background,
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).primaryColor,
            ),
            borderRadius: BorderRadius.circular(12)),
        height: MediaQuery.of(context).size.height * 0.5,
        width: 800,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              AppNavigation.pop();
                            },
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Text(
                            "Receipts fields",
                            style: MyThemes.txtStyle(
                                fontSize: 2,
                                color: Theme.of(context).canvasColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      listtile("Receipt id", widget.receiptList.externalId),
                      listtile("Pos name", widget.receiptList.posName),
                      listtile("Cashier name:", widget.receiptList.cashierName),

                      listtile("Created date", widget.receiptList.createdDate),
                      // listtile("Client name", widget.receiptList.clientName),
                      ...widget.receiptList.soldItemList
                          .map(
                            (e) => listtile("Product", e.productName),
                          )
                          .toList(),

                      // listtile(widget.receiptList.payment),
                      // listtile(widget.receiptList.soldItemList),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.h * 1),
                  child: DefaultButton(
                      text: 'Update',
                      isButtonEnabled: true,
                      onPress: () {
                        Navigator.pop(context);
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget listtile(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Theme.of(context).dialogBackgroundColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: SizeConfig.h * .5,
          vertical: SizeConfig.v * 0.5,
        ),
        onTap: () {},
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
          child: Text(
            "$title:  $subtitle",
            style: MyThemes.txtStyle(
                fontSize: 2, color: Theme.of(context).canvasColor),
          ),
        ),
      ),
    );
  }
}
