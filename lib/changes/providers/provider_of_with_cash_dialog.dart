import 'package:flutter/cupertino.dart';

class WithCashProvider extends ChangeNotifier {
  TextEditingController? controller;
  bool isTheFirstTapping = true;
  initController(double totalPrice) {
    isTheFirstTapping = true;
    controller = TextEditingController(text: totalPrice.toStringAsFixed(2));
    controller!.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller!.text.length,
    );
  }

  disposeController() {
    controller!.dispose();
  }

  changeControllerValue(String v) {
    controller!.text = v;
    notifyListeners();
  }

  increaseControllerText(int num) {
    if (isTheFirstTapping) {
      controller!.text = num .toString();
      isTheFirstTapping = false;
      return;
    }

    controller!.text += num.toString();
    notifyListeners();
  }

  decreaseControllerText() {
    if (controller!.text.isNotEmpty) {
      controller!.text =
          controller!.text.substring(0, controller!.text.length - 1);
    }
    notifyListeners();
  }
}
