import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/domain/receipt/refund_mark_split.dart';
import 'package:invan2/changes/providers/return_page_provider.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

/// Vozvratda markirovkali qatorni bosganda: qaytayotgan shisha/blok KM'i
/// skanerlanadi. Sarlavha, mahsulot nomi va maydon. Dialog ochiq qoladi — har
/// to'g'ri skan 1 dona (blok qatorida 1 blok) o'ngga o'tkazadi; qatorda
/// qaytariladigan narsa qolmasa o'zi yopiladi; xato shu dialogning o'zida.
/// Yopish: Esc / tashqari.
class RefundMarkScanDialog extends StatefulWidget {
  const RefundMarkScanDialog({
    super.key,
    required this.provider,
    required this.row,
  });

  final ReturnPageProviderr provider;
  final ReceiptModelSoldItem4 row;

  @override
  State<RefundMarkScanDialog> createState() => _RefundMarkScanDialogState();
}

class _RefundMarkScanDialogState extends State<RefundMarkScanDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Xato skan natijasi — shu dialogning o'zida ko'rsatiladi (ikkinchi
  /// dialog ustma-ust chiqmasin); "Закрыть" dan keyin yana skan maydoni.
  RefundScanResult? _error;

  @override
  void initState() {
    super.initState();
    // Skan faqat shu maydonga tushsin. Uy sahifasining global skaner
    // tinglovchisi `home` holatida KM'ni sotuv savatiga ham qo'shardi
    // ("Этот отмеченный продукт уже был добавлен ранее!" ikkinchi dialogi).
    BlocProvider.of<BlBloc>(context, listen: false).add(BlStatusChangedEvent(
      status: BLStatus.other,
      where: 'refund_mark_scan_dialog.dart initState',
    ));
  }

  void _handleSubmit(String value) {
    _controller.clear();
    if (value.trim().isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    final result = widget.provider.scanMark(widget.row, value);

    if (result == RefundScanResult.matched) {
      if (!widget.provider.getLeftList.contains(widget.row)) {
        Navigator.of(context).pop();
        return;
      }
      _focusNode.requestFocus();
      return;
    }
    setState(() => _error = result);
  }

  String _message(AppLocalizations loc, RefundScanResult result) {
    switch (result) {
      case RefundScanResult.alreadyAdded:
        return loc.vozvrat_km_qoshilgan;
      case RefundScanResult.alreadyRefunded:
        return loc.vozvrat_km_oldin_qaytarilgan;
      case RefundScanResult.boxMarkOnUnitRow:
        return loc.vozvrat_km_blok_kodi;
      case RefundScanResult.unitMarkOnBoxRow:
        return loc.vozvrat_km_dona_kodi;
      case RefundScanResult.otherProduct:
        return loc.vozvrat_km_boshqa_mahsulot;
      case RefundScanResult.empty:
        return loc.vozvrat_km_qisqa;
      case RefundScanResult.notInReceipt:
      case RefundScanResult.matched:
        return loc.vozvrat_km_chekda_yoq;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final Color textColor = Theme.of(context).canvasColor;
    final RefundScanResult? error = _error;

    // Qutisi oddiy dialogdan 1.5 barobar; matnlar standart o'lchamda.
    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        width: SizeConfig.h * 63,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(SizeConfig.v * 3.75),
          // Fon bilan qo'shilib ketmasin — ozgina rangli chegara.
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        ),
        padding: EdgeInsets.all(SizeConfig.h * 2.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.kodni_scanerlash,
              style: MyThemes.txtStyle(color: textColor),
            ),
            SizedBox(height: SizeConfig.v * 1.5),
            // Blok qatori aniq ko'rinsin — kassir dona bilan adashtirmasin.
            Text.rich(
              TextSpan(
                text: "${loc.tovar}: ${widget.row.productName}",
                children: [
                  if (widget.row.saleType == 2 && widget.row.boxValue > 0)
                    TextSpan(
                      text: " — ${loc.vozvrat_km_blok_qator(widget.row.boxValue)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              style: MyThemes.txtStyle(color: textColor),
            ),
            SizedBox(height: SizeConfig.v * 2.25),
            if (error == null)
              TextField(
                autofocus: true,
                focusNode: _focusNode,
                controller: _controller,
                onSubmitted: _handleSubmit,
                style: MyThemes.txtStyleWhite(),
                decoration: InputDecoration(
                  constraints: BoxConstraints(maxHeight: SizeConfig.v * 7.74),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.h,
                    vertical: SizeConfig.v * 1.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.v * .9),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                    borderRadius: BorderRadius.circular(SizeConfig.v * .9),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 32),
                  SizedBox(width: SizeConfig.h),
                  Flexible(
                    child: Text(
                      _message(loc, error),
                      style: MyThemes.txtStyle(color: textColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.v * 2.25),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  autofocus: true,
                  onPressed: () => setState(() => _error = null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 0,
                  ),
                  child: Text(loc.vozvrat_km_yopish,
                      style: MyThemes.txtStyleWhite()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
