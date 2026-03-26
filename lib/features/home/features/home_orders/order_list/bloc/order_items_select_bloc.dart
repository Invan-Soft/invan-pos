import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../changes/dialogs/virtual_keyboard/content_of_virtual_keyboard.dart';

part 'order_items_select_event.dart';
part 'order_items_select_state.dart';

class OrderItemsSelectBloc
    extends Bloc<OrderItemsSelectEvent, OrderItemsSelectState> {
  int back = 0;
  OrderItemsSelectBloc()
      : super(const OrderItemsSelectState(
          selected: -1,
        )) {
    on<GetItemIdexEvent>(_arrow);
  }

  _arrow(GetItemIdexEvent event, Emitter<OrderItemsSelectState> emit) {

    int v = -1;
    if (event.orderedProductsLength < 0) return;

    switch (event.arrowTo) {
      case ArrowTo.up:
        v = (state.selected - 1) % event.orderedProductsLength;
        break;
      case ArrowTo.down:
        v = (state.selected + 1) % event.orderedProductsLength;

        break;
      case ArrowTo.right:
        if (back > 0) {
          back--;
        }
        break;
      case ArrowTo.left:
        back++;

        break;
    }

    emit(state.copyWith(selected: v));
  }
}
