import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/utils/utils.dart';

class CheckViewSoldItems extends StatelessWidget {
  const CheckViewSoldItems({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckFBloc, CheckFState>(
      builder: (context, state) {
        final orderedProducts = state.selectedCheck!.soldItemList;
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: orderedProducts.length,
          itemBuilder: (context, index) {
            final item = orderedProducts[index];
            double width = 80;
            if (item.onlyPrice.toStringAsFixed(0).length > 11) {
              width = 160;
            } else if (item.onlyPrice.toStringAsFixed(0).length > 9) {
              width = 150;
            } else if (item.onlyPrice.toStringAsFixed(0).length > 7) {
              width = 125;
            } else if (item.onlyPrice.toStringAsFixed(0).length > 5) {
              width = 100;
            }

            return ListTile(
              contentPadding: EdgeInsets.only(
                left: SizeConfig.h * 2,
                right: SizeConfig.h,
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      item.productName,
                      style: MyThemes.txtStyle(
                        fontSize: 2.1,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).dividerColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  Text(
                    '${item.value % 1 == 0 ? item.value.toStringAsFixed(0) : item.value.toString()} * ${MoneyFormatter.formatVat.format(item.price)}',
                    style: MyThemes.txtStyle(
                      fontSize: 2.1,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                  item.price != item.onlyPrice
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                MoneyFormatter.formatVat.format(item.onlyPrice),
                                textAlign: TextAlign.center,
                                style: MyThemes.txtStyle(
                                  textDecoration: TextDecoration.lineThrough,
                                  fontSize: 2,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.normal,
                                  color: Theme.of(context).canvasColor,
                                ),
                              ),
                              Container(
                                height: 2,
                                width: width,
                                color: Colors.red,
                              )
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              trailing: SizedBox(
                width: SizeConfig.h * 25,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      MoneyFormatter.formatVat.format(item.value * item.price),
                      style: MyThemes.txtStyle(
                        fontSize: 2.1,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                    item.price != item.onlyPrice
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  MoneyFormatter.formatVat
                                      .format(item.value * item.onlyPrice),
                                  textAlign: TextAlign.center,
                                  style: MyThemes.txtStyle(
                                    textDecoration: TextDecoration.lineThrough,
                                    fontSize: 2,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.normal,
                                    color: Theme.of(context).canvasColor,
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: width,
                                  color: Colors.red,
                                )
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
