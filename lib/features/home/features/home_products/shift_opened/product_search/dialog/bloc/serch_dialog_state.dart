part of 'serch_dialog_bloc.dart';

// SD means SearchDialog

// ignore: must_be_immutable
class SDstate extends Equatable {
  TextEditingController controller;
  final SDStatus status;
  final int selected;
  final List<ItemModel> searchedProducts;
  SDstate({
    required this.status,
    required this.controller,
    required this.searchedProducts,
    required this.selected,
  });
  SDstate copyWith({
    TextEditingController? controller,
    SDStatus? status,
    int? selected,
    List<ItemModel>? searchedProducts,
  }) =>
      SDstate(
          controller: controller ?? this.controller,
          status: status ?? this.status,
          searchedProducts: searchedProducts ?? this.searchedProducts,
          selected: selected ?? this.selected);

  @override
  List<Object?> get props => [
        status,
        searchedProducts,
        selected,
        controller,
      ];
}

enum SDStatus { pop, pure }
