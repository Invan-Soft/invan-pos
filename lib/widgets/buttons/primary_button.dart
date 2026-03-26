import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// ignore: must_be_immutable
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  bool isLoading;
  PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        fixedSize: const Size(300, 56),
      ),
      child: isLoading
          ? SpinKitCircle(
              color: Theme.of(context).primaryColor,
            )
          : Text(label),
    );
  }
}
