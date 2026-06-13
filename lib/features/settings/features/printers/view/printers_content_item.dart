import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/printing/repository/printer_backup.dart';
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

    // ESKI KOD XAVFLI edi: box.clear() + box.addAll(). clear() bilan addAll()
    // orasida dastur uzilsa (svet o'chishi/crash) HAMMA printer yo'qolardi.
    // Endi faqat kerakli kalit(lar)ni o'chiramiz — atomik, qisman yo'qotish yo'q.
    final keysToDelete = box.keys.where((k) {
      final p = box.get(k);
      return p is PrinterModel && p.url == printerModel.url;
    }).toList();
    await box.deleteAll(keysToDelete);
    await box.flush();

    await PrinterBackup.save(box.values.toList().cast<PrinterModel>());
  }
}
