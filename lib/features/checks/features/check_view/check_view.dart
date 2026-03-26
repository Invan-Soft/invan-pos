import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'check_view_content.dart';

class CheckView extends StatefulWidget {
  const CheckView({super.key});
  @override
  CheckViewState createState() => CheckViewState();
}

class CheckViewState extends State<CheckView> {
  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.h * 5,
        right: SizeConfig.h * 5,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: SizeConfig.v * 15),
              const CheckViewContent(),
              SizedBox(height: SizeConfig.v * 15),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
