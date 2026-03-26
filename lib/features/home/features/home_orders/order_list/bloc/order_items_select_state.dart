part of 'order_items_select_bloc.dart';

class OrderItemsSelectState extends Equatable {
  final int selected;
  const OrderItemsSelectState({
    required this.selected,
  });
  OrderItemsSelectState copyWith({
    int? selected,
  }) =>
      OrderItemsSelectState(selected: selected ?? this.selected);

  @override
  List<Object?> get props => [
        selected,
      ];
}
