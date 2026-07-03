import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/components/check_list_widget.dart';
import 'package:invan2/features/checks/features/checks_list/components/search_field_widget.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';

class ChecksListt extends StatefulWidget {
  const ChecksListt({Key? key}) : super(key: key);

  @override
  State<ChecksListt> createState() => _ChecksListtState();
}

class _ChecksListtState extends State<ChecksListt> {
  final TextEditingController controller = TextEditingController();
  List<ReceiptModel4> receipts = [];

  late CheckFBloc checkFBloc;
  StreamSubscription? _receiptsSub;

  @override
  void initState() {
    receipts =
        MyObjectbox.saleStore.box<ReceiptModel4>().getAll().reversed.toList();
    checkFBloc = BlocProvider.of(context);

    // Cheklar bazasini bevosita kuzatamiz. triggerImmediately: true — sahifaga
    // kirilgan zahoti joriy holat bilan bir marta ishlaydi (kirishdagi eskirishni
    // tuzatadi), keyin har o'zgarishda (masalan chek orqa fonda yuborilib
    // uploaded=true bo'lganda) ro'yxatni jonli yangilaydi. Wrapper listeneriga
    // bog'liq emas, shuning uchun ishonchli.
    _receiptsSub = MyObjectbox.saleStore
        .box<ReceiptModel4>()
        .query()
        .watch(triggerImmediately: true)
        .listen((query) {
      if (!mounted) return;
      final fresh = query.find().reversed.toList();
      receipts = fresh;
      checkFBloc.add(CheckFRefreshEvent(fresh,
          isSearching: controller.text.trim().isNotEmpty));
    });

    super.initState();
  }

  @override
  void dispose() {
    _receiptsSub?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).dialogBackgroundColor,
      child: Column(
        children: [
          ChecksSearchFieldWidgett(controller: controller),
          CheckListWidget(
            onOkButtonPressed: () {
              controller.text = '';
              checkFBloc.add(CheckFCallInitialEvent());
            },
            receipts: receipts,
          )
        ],
      ),
    );
  }
}
