import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../../changes/dialogs/virtual_keyboard/content_of_virtual_keyboard.dart';
import 'bloc/order_items_select_bloc.dart';
import 'order_list_top.dart';
import 'package:invan2/utils/utils.dart';
import 'order_list_item.dart';
import '../../operation_on_product/operation_on_product.dart';

class OrderList extends StatefulWidget {
  const OrderList({super.key});

  @override
  OrderListState createState() => OrderListState();
}

class OrderListState extends State<OrderList> {
  late ScrollController _scrollController;
  final _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final indexBloc = BlocProvider.of<OrderItemsSelectBloc>(context);
    BlBloc blBloc = BlocProvider.of(context, listen: false);
    final orderingProvider = Provider.of<OrderingProvider4>(context);
    final List<ReceiptModelSoldItem4> orderedProducts =
        context.watch<OrderingProvider4>().getCurrentClient.orderedProducts;
    final lastAI =
        context.watch<OrderingProvider4>().getCurrentClient.lastAddedIndex;
    return Expanded(
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              OrderListTop(),
              Expanded(
                child: Builder(builder: (context) {
                  if (orderedProducts.isEmpty) {
                    return Container();
                  }
                  return RawKeyboardListener(
                    focusNode: _keyboardFocusNode,
                    autofocus: false,
                    onKey: (event) async {
                      Log.d(event.physicalKey, name: 'order_list');
                      if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                        indexBloc.add(
                          GetItemIdexEvent(ArrowTo.down, orderedProducts.length),
                        );
                      }
                      if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                        indexBloc.add(
                          GetItemIdexEvent(ArrowTo.up, orderedProducts.length),
                        );
                      }
                      if (event.isKeyPressed(LogicalKeyboardKey.space)) {
                        if (!orderedProducts[indexBloc.state.selected].isDeleted!) {
                          orderingProvider.tapIndexToEdit(indexBloc.state.selected);
                          blBloc.add(BlStatusChangedEvent(
                              status: BLStatus.other,
                              where:
                                  "lib/features/home/features/home_orders/order_list/order_list.dart oderlistItem"));
                          await OperationOnProduct.operationOnProductDialog(
                            context: context,
                            item: orderedProducts[indexBloc.state.selected],
                            isClientMinimumPrice:
                                //  Provider.of<OrderingProvider4>(
                                //             context,
                                //             listen: false)
                                //         .getCurrentClient
                                //         .selectedClient
                                //         ?.isMinimumPrice ??
                                false,
                          );
                          blBloc.add(BlStatusChangedEvent(
                              status: BLStatus.home,
                              where:
                                  "lib/features/home/features/home_orders/order_list/order_list.dart oderlistItem"));
                        }
                      }
                    },
                    child:
                        BlocConsumer<OrderItemsSelectBloc, OrderItemsSelectState>(
                      listener: (context, state) {
                        if (state.selected > 2) {
                          _scrollController.animateTo((state.selected - 2) * 100,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.ease);
                        } else if (state.selected > -1 &&
                            state.selected < (orderedProducts.length - 4)) {
                          _scrollController.animateTo(state.selected - 1 * 10,
                              duration: const Duration(milliseconds: 50),
                              curve: Curves.ease);
                        }
                      },
                      builder: (context, state) {
                        return ListView.builder(
                          padding: EdgeInsets.only(top: SizeConfig.v * 1.46),
                          physics: const BouncingScrollPhysics(),
                          controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: orderedProducts.length,
                          itemBuilder: (context, index) {
                            return OrderListItem(
                              selected: index == state.selected,
                              index: (index - orderedProducts.length).abs(),
                              isLastAdded: lastAI == index,
                              orderedProduct: orderedProducts[index],
                              onPressed: () async {
                                if (!orderedProducts[index].isDeleted!) {
                                  orderingProvider.tapIndexToEdit(index);
                                  blBloc.add(BlStatusChangedEvent(
                                      status: BLStatus.other,
                                      where:
                                          "lib/features/home/features/home_orders/order_list/order_list.dart oderlistItem"));
                                  await OperationOnProduct.operationOnProductDialog(
                                    context: context,
                                    item: orderedProducts[index],
                                    isClientMinimumPrice: false,
                                  );
                                  blBloc.add(BlStatusChangedEvent(
                                      status: BLStatus.home,
                                      where:
                                          "lib/features/home/features/home_orders/order_list/order_list.dart oderlistItem"));
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
          if (context.watch<OrderingProvider4>().isLoading)
            Positioned.fill(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    SizeConfig.v * 1.1,
                  ),
                  color: Theme.of(context).primaryColor.withOpacity(.4),
                ),
                child: Center(
                  child: SpinKitCircle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }
}
