import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/utils.dart';
import '../dialog/printer_select_dialog.dart';
import 'package:invan2/features/features.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'printers_content_item.dart';

class PrintersContent extends StatelessWidget {
  const PrintersContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ValueListenableBuilder<Box<PrinterModel>>(
            valueListenable: HiveBoxes.getPrinters().listenable(),
            builder: (context, box, _) {
              final printers = box.values.toList().cast<PrinterModel>();

              if (printers.isEmpty) {
                return Container();
              } else {
                return ListView.builder(
                  itemCount: printers.length,
                  itemBuilder: (context, index) {
                    final printer = printers[index];
                    return PrintersContentItem(printerModel: printer);
                  },
                );
              }
            },
          ),
        ),
        Positioned(
          right: SizeConfig.v * 6,
          bottom: SizeConfig.v * 6,
          child: FloatingActionButton.large(
            heroTag: null,
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const PrinterSelectDialog(),
              );
            },
            child: Icon(
              Icons.add,
              size: SizeConfig.v * 6,
              color: MyThemes.textWhiteColor,
            ),
          ),
        ),
      ],
    );
  }
}
