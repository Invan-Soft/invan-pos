import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/changes/components/logo_widget.dart';

import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/alice_pincode.dart';

import '../app_navigation.dart';

class AuthBackgroundWidget extends StatelessWidget {
  const AuthBackgroundWidget({
    Key? key,
    required this.isWaiting,
    required this.child,
    required this.isBackButtoned,
    required this.onPres,
  }) : super(key: key);
  final VoidCallback onPres;
  final Widget child;
  final bool isWaiting;
  final bool isBackButtoned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          backgroundColor: Theme
              .of(context)
              .primaryColor,
          onPressed: () {
            showDialog(
              context: context, builder: (context) => AlicePincodePage(),);
          },
          child: const Icon(
            Icons.http_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),

    backgroundColor: Theme.of(context).colorScheme.background,
    body: Stack(
    children: [
    Positioned(
    top: 50,
    left: 50,
    child: isBackButtoned
    ? Ink(
    padding: EdgeInsets.all(SizeConfig.v * 0.42),
    decoration: const BoxDecoration(
    // color: Colors.white,
    shape: BoxShape.circle,
    ),
    child: FloatingActionButton(
    focusNode: FocusNode(skipTraversal: true),
    backgroundColor: Theme.of(context).primaryColor,
    onPressed: isBackButtoned ? onPres : null,
    child: Icon(
    Icons.arrow_back,
    size: SizeConfig.v * 4,
    color: Colors.white,
    ),
    ),
    )
        : const SizedBox(),
    ),
    Positioned.fill(
    child: Center(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
    SizedBox(height: SizeConfig.v * 13.67),
    Hero(
    tag: "logo_auth",
    child: LogoInvanWidget(width: SizeConfig.h * 26.5),
    ),
    SizedBox(height: SizeConfig.v * 17.57),
    child,
    ],
    ),
    ),
    ),
    isWaiting
    ? Positioned.fill(
    child: Container(
    width: double.infinity,
    height: double.infinity,
    color: Theme.of(context).primaryColor.withOpacity(.4),
    child: Center(
    child: SpinKitCircle(
    color: Theme.of(context).primaryColor,
    ),
    ),
    ),
    )
        : const Positioned(
    top: 0,
    left: 0,
    child: SizedBox(
    height: 0,
    width: 0,
    ),
    ),
    ],
    ),
    );
  }
}
