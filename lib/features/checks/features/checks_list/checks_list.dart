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
  @override
  void initState() {
    receipts =
        MyObjectbox.saleStore.box<ReceiptModel4>().getAll().reversed.toList();
    checkFBloc = BlocProvider.of(context);

    super.initState();
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
