import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/printing/api/print_sold_api.dart';
import 'package:printing/printing.dart';
import 'package:invan2/utils/utils.dart';

class PreviewSoldItems extends StatelessWidget {
  const PreviewSoldItems({
    super.key,
    required this.receipt,
    required this.sdacha,
    // required this.shift,
  });

  final ReceiptModel4 receipt;
  final double sdacha;

  // final ShiftsCreateContent shift;

  static MaterialPageRoute route(
    ReceiptModel4 receipt,
    double sdacha,
    // ShiftsCreateContent shift,
  ) =>
      MaterialPageRoute(
        builder: (_) => PreviewSoldItems(
          receipt: receipt,
          sdacha: sdacha,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Pdf Preview Page'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 30),
        child: PdfPreview(build: (format) {
          return PrintSoldApi.generatePdf80(
            receiptsCreateGroup: receipt,
            sdacha: sdacha,
          );
        }),
      ),
    );
  }
}
