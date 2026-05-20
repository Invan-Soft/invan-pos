part of 'order_items_select_bloc.dart';

abstract class OrderItemsSelectEvent {}

class GetItemIdexEvent extends OrderItemsSelectEvent {
  final ArrowTo arrowTo;
  final int orderedProductsLength;
  GetItemIdexEvent(this.arrowTo,this.orderedProductsLength);
}
