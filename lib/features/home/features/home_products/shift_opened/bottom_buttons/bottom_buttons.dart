import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'local_category_buttons.dart';

class BottomButtons extends StatefulWidget {
  const BottomButtons({super.key});

  @override
  BottomButtonsState createState() => BottomButtonsState();
}

class BottomButtonsState extends State<BottomButtons> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SizeConfig.v * 9,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          boxShadow: [
            BoxShadow(color: Theme.of(context).highlightColor, blurRadius: 3)
          ]),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: const LocalCategoryButtons(),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
