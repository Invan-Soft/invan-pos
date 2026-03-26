import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/utils.dart';

class PrintersContentItem extends StatelessWidget {
  const PrintersContentItem({
    super.key,
    required this.printerModel,
  });

  final PrinterModel printerModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 3.5),
      child: Column(
        children: [
          ListTile(
            trailing: IconButton(
              focusNode: FocusNode(skipTraversal: true),
              icon: Icon(
                Icons.close,
                size: SizeConfig.v * 4,
                color: Theme.of(context).canvasColor,
              ),
              onPressed: () async {
                await removePrinterFromHive(printerModel);
              },
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.h * .5,
              vertical: SizeConfig.v * 1.5,
            ),
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.h),
              child: Row(
                children: [
                  Text(
                    printerModel.name ?? '',
                    style: MyThemes.txtStyle(
                        fontSize: 2.7, color: Theme.of(context).canvasColor),
                  ),
                  SizedBox(width: SizeConfig.h * 2),
                  Text(
                    '(${printerModel.paperSize ?? 80})',
                    style: MyThemes.txtStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Future<void> removePrinterFromHive(PrinterModel printerModel) async {
    final box = HiveBoxes.getPrinters();
    final printers = box.values.toList().cast<PrinterModel>();

    await box.clear();

    printers.removeWhere((element) => element.url == printerModel.url);

    await box.addAll(printers);
  }
}
