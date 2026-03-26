import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/model/rule_cash_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/utils/utils.dart';

class Right extends StatefulWidget {
  const Right({Key? key}) : super(key: key);

  @override
  State<Right> createState() => _RightState();
}

class _RightState extends State<Right> {
  late Stream<List<RuleCashModel4>> _stream;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _stream = MyObjectbox.saleStore
        .box<RuleCashModel4>()
        .query()
        .watch(triggerImmediately: true)
        .map((event) => event.find());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.h * 1.2,
            top: SizeConfig.v * 3,
          ),
          child: Text(
            '${loc.kirim}/${loc.chiqim}',
            style: MyThemes.txtStyle(
              fontSize: 2.4,
              color:Theme.of(context).dividerColor,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.v * 1),
        Divider(
          thickness: 2,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          child: StreamBuilder<List<RuleCashModel4>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final list = snapshot.data ?? [];

                if (list.isEmpty) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  );
                } else {
                  return SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ListView.separated(
                      separatorBuilder: (context, index) {
                        return Divider(
                          color: Theme.of(context).dividerColor,
                        );
                      },
                      itemCount: list.length,
                      controller: _scrollController,
                      itemBuilder: (context, index) {
                        final item = list[index];

                        return ListTile(
                          title: Text(
                            '${item.time} ${item.cashierName}',
                            style: TextStyle(
                              color: Theme.of(context).canvasColor,
                            ),
                          ),
                          subtitle: Text(
                            item.note,
                            style: TextStyle(
                                color:Theme.of(context).dividerColor),
                          ),
                          trailing: Text(
                            '${item.isIncome ? '' : '-'}${MoneyFormatter.formatter.format(item.money)}',
                            style: TextStyle(
                              color: Theme.of(context).canvasColor,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              } else {
                return const  SizedBox();
              }
            },
          ),
        ),
      ],
    );
  }
}
