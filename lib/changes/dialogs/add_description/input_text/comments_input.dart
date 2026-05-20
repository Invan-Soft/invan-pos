import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../providers/ordering_provider_4.dart';

class AddInputCommentDialog extends StatefulWidget {
  const AddInputCommentDialog({
    super.key,
  });

  @override
  State<AddInputCommentDialog> createState() =>
      _SearchFieldOfClientSearchDialogState();
}

class _SearchFieldOfClientSearchDialogState
    extends State<AddInputCommentDialog> {
  final FocusNode _focusNode = FocusNode();
  late final OrderingProvider4 orderingProvider4;

  @override
  void initState() {
    orderingProvider4 = Provider.of<OrderingProvider4>(context, listen: false);
    super.initState();
  }

  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (orderingProvider4.setComment() != "") {
      commentController.text = orderingProvider4.setComment();
    }

    AppLocalizations loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          VisibilityDetector(
            onVisibilityChanged: (VisibilityInfo info) {
              if (info.visibleFraction > 0) {
                _focusNode.requestFocus();
              }
            },
            key: const Key('visible-detector-key'),
            child: MyBarcodeListener(
              onBarcodeScannedClick: (v) {},
              onBarcodeScannedMagnetic: (v) {},
              onBarcodeScannedPayme: (v) {},
              onShiftDeletePressed: () {},
              onDelPressed: () {},
              onF12Pressed: () {},
              onF5pressed: () {},
              bufferDuration: const Duration(milliseconds: 300),
              onBarcodeScanned: (v) {},
              onF1pressed: () {},
              onF2pressed: () {},
              onF3pressed: () {},
              onDownPressed: () {},
              onUpPressed: () {},
              onBarcodeScannedClient: (v) {},
              child: TextField(
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                focusNode: _focusNode,
                autofocus: true,
                onSubmitted: (v) {
                  orderingProvider4.getComment(commentController.text, true);
                  Navigator.pop(context);
                },
                controller: commentController,
                style: TextStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: SizeConfig.v * 2,
                ),
                cursorColor: Theme.of(context).primaryColor,
                decoration: InputDecoration(
                  fillColor: Theme.of(context).dialogBackgroundColor,
                  filled: true,
                  hintStyle: TextStyle(
                    color: Theme.of(context).canvasColor,
                    fontSize: SizeConfig.v * 1.8,
                  ),
                  hintText: loc.izoh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.v),
                    borderSide: BorderSide.none,
                  ),
                ),
                inputFormatters: const [],
              ),
            ),
          ),
          const Spacer(),
          DefaultButton(
            height: 9,
            text: loc.saqlash,
            isButtonEnabled: true,
            onPress: () {
              orderingProvider4.getComment(commentController.text, true);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
