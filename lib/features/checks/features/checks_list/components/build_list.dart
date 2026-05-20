import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'build_list_item.dart';

class BuildList extends StatefulWidget {
  final List<ReceiptModel4> list;
  final int selectedIndex;
  const BuildList({Key? key, required this.list, required this.selectedIndex})
      : super(key: key);

  @override
  State<BuildList> createState() => _BuildListState();
}

class _BuildListState extends State<BuildList> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    CheckFBloc checkFBloc = BlocProvider.of(context);
    return widget.list.isEmpty
        ? Center(
            child: Text(
              'No Checks yet!',
              style: MyThemes.txtStyle(
                color: Colors.black54,
                fontSize: 2.2,
              ),
            ),
          )
        : ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.list.length + 1,
            itemBuilder: (context, index) {
              if (widget.list.length == index) {
                if (checkFBloc.pagesLength > checkFBloc.currentPage) {
                  checkFBloc.add(
                    CheckFSearchGlobalEvent(
                      checkFBloc.glPattern,
                      page: checkFBloc.currentPage + 1,
                      isRetry: false,
                    ),
                  );
                  return CupertinoActivityIndicator(
                    radius: SizeConfig.v * 2,
                  );
                }
                return SizedBox(
                  height: SizeConfig.h * 5,
                );
              }
              final item = widget.list[index];
              return BuildListItem(
                receiptModel4: item,
                onPressed: () => checkFBloc.add(CheckFSelectCheckEvent(index)),
                isSelected: widget.selectedIndex == index,
              );
            },
          );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
