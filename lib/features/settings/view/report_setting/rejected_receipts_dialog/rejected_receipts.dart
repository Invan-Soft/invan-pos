import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/features/settings/view/report_setting/rejected_receipts_dialog/rejected_receipt_fields.dart';
import 'package:invan2/widgets/default_button.dart';
import '../../../../../utils/utils.dart';
import '../../../../checks/features/checks_app_bar/bloc/usr_bloc.dart';
import '../../../../hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class EditRejectedReceiptsDialog extends StatefulWidget {
  const EditRejectedReceiptsDialog({Key? key}) : super(key: key);

  @override
  State<EditRejectedReceiptsDialog> createState() =>
      _EditRejectedReceiptsDialogState();
}

class _EditRejectedReceiptsDialogState
    extends State<EditRejectedReceiptsDialog> {
  final TextEditingController exC = TextEditingController();
  final TextEditingController reject = TextEditingController();
  late bool isRejected;
  List<ReceiptModel4> receiptList = [];

  @override
  void initState() {
    super.initState();
    receiptList = _find10();
  }

  static _put10(List<ReceiptModel4> receiptList) {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    if (receiptList.length > 1) {
      box.putMany(receiptList);
    } else {
      box.put(receiptList[0]);
    }
  }

  static List<ReceiptModel4> _find10() {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    List<ReceiptModel4> receiptList = box
        .getAll()
        .where((e) => e.rejected == true || e.uploaded == false)
        .toList();

    return receiptList;
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
                Column(
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
                    ...receiptList.map((x) {
                      isRejected = x.rejected;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          tileColor: Theme.of(context).dialogBackgroundColor,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.h * .5,
                            vertical: SizeConfig.v * 0.5,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: MaterialLocalizations.of(context)
                                  .modalBarrierDismissLabel,
                              barrierColor: Colors.transparent,
                              builder: (_) {
                                return AlertDialog(
                                    alignment: Alignment.center,
                                    backgroundColor: Colors.transparent,
                                    content: EditRejectedReceiptsFieldsDialog(
                                      receiptList: x,
                                    ));
                              },
                            );
                          },
                          title: Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: SizeConfig.v),
                            child: Text(
                              x.externalId,
                              style: MyThemes.txtStyle(
                                  fontSize: 2,
                                  color: Theme.of(context).canvasColor),
                            ),
                          ),
                          // trailing: ClipRRect(
                          //   child: CupertinoSwitch(
                          //       value: isRejected,
                          //       onChanged: (v) {
                          //         x.rejected = v;
                          //         _put10([x]);
                          //         setState(() {});
                          //       }),
                          // ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: SizeConfig.h * 1),
                        child: DefaultButton(
                          text: 'Delete',
                          isButtonEnabled: true,
                          deleteButton: true,
                          onPress: () async {
                            final receiptBox =
                                MyObjectbox.saleStore.box<ReceiptModel4>();
                            List<int> removedItemID = [];
                            receiptBox.getAll().forEach(
                              (element) {
                                if (element.rejected == true &&
                                    element.uploaded == false) {
                                  removedItemID.add(element.id);
                                }
                              },
                            );
                            receiptBox.removeMany(removedItemID);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(width: SizeConfig.h * 0.3),
                    ),
                    Expanded(
                      flex: 10,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: SizeConfig.h * 1),
                        child: DefaultButton(
                          text: 'Update',
                          isButtonEnabled: true,
                          onPress: () async {
                            UsrBloc usrBloc = BlocProvider.of(context);
                            usrBloc.add(UsrSendSpecialEvent(
                                "Checks appBar", usrBloc.unsents));
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
