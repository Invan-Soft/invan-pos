import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/content_of_virtual_keyboard.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/product_search_provider.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

part 'serch_dialog_event.dart';

part 'serch_dialog_state.dart';

// SD means SearchDialog
class SDbloc extends Bloc<SDevent, SDstate> {
  SearchTypeEnum searchTypeEnum = SearchTypeEnum.byBarcode;

  bool capsLock = false;
  bool shift = false;
  int back = 0;

  SDbloc()
      : super(SDstate(
    controller: TextEditingController(),
    searchedProducts: const [],
    selected: -1,
    status: SDStatus.pure,
  )) {
    on<SDtypedEvent>(_type);
    on<SDinitializeSearchTypeEnumEvent>(_init);
    on<SDtypeFromVirtualKeyboardEvent>(_typeVirtual);
    on<SDbackSpacePressedEvent>(_backSpace);
    on<SDcapsLockEvent>(_capsLock);
    on<SDshiftEvent>(_shift);
    on<SDarrowEvent>(_arrow);
    on<SDreturnEvent>(_return);
  }

  _return(SDreturnEvent event, Emitter<SDstate> emit) {
    emit(state.copyWith(status: SDStatus.pop));
  }

  _arrow(SDarrowEvent event, Emitter<SDstate> emit) {
    int v = -1;
    if (state.searchedProducts.isEmpty) return;

    switch (event.arrowTo) {
      case ArrowTo.up:
        v = (state.selected - 1) % state.searchedProducts.length;

        break;
      case ArrowTo.down:
        v = (state.selected + 1) % state.searchedProducts.length;

        break;
      case ArrowTo.right:
        if (back > 0) {
          back--;
        }
        break;
      case ArrowTo.left:
        if (back < state.controller.text.length) {
          back++;
        }
        break;
    }
    state.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: state.controller.text.length - back),
    );
    emit(state.copyWith(searchedProducts: state.searchedProducts, selected: v));
  }

  _shift(SDshiftEvent event, Emitter<SDstate> emit) {
    shift = !shift;
    emit(
        state.copyWith(searchedProducts: state.searchedProducts, selected: -1));
  }

  _capsLock(SDcapsLockEvent event, Emitter<SDstate> emit) {
    capsLock = !capsLock;
    emit(
        state.copyWith(searchedProducts: state.searchedProducts, selected: -1));
  }

  _backSpace(SDbackSpacePressedEvent event, Emitter<SDstate> emit) {
    if (state.controller.text.isNotEmpty) {
      if (back == 0) {
        state.controller.text = state.controller.text
            .substring(0, state.controller.text.length - 1);
      } else if (back != state.controller.text.length) {
        List v = state.controller.text.split("");
        v.removeAt(state.controller.text.length - back - 1);
        state.controller.text = v.join();
      }

      emit(state.copyWith(searchedProducts: _search(), selected: -1));
    }
  }

  _typeVirtual(SDtypeFromVirtualKeyboardEvent event, Emitter<SDstate> emit) {
    String typed = (capsLock ? event.v : event.v.toLowerCase());
    if (back == 0) {
      state.controller.text = state.controller.text + typed;
    } else {
      List v = state.controller.text.split("");
      v.insert(state.controller.text.length - back, typed);
      state.controller.text = v.join();
    }
    emit(state.copyWith(searchedProducts: _search(), selected: -1));
  }

  _init(SDinitializeSearchTypeEnumEvent event, Emitter<SDstate> emit) {
    back = 0;
    shift = false;
    capsLock = false;
    // state.controller = TextEditingController();
    searchTypeEnum = event.searchTypeEnum;
    // state.controller.addListener(() {
    //   state.controller.selection = TextSelection.fromPosition(
    //     TextPosition(offset: state.controller.text.length - back),
    //   );
    // });
    emit(state.copyWith(searchedProducts: [], selected: -1));
  }

  _type(SDtypedEvent event, Emitter<SDstate> emit) {
    emit(state.copyWith(searchedProducts: _search(), selected: -1));
  }

  List<ItemModel> _search() {
    switch (searchTypeEnum) {
      case SearchTypeEnum.option:
        return ItemsSingleton.search(state.controller.text);

      case SearchTypeEnum.byBarcode:
        return ItemsSingleton.searchProductsByBarcode(state.controller.text);

      case SearchTypeEnum.bySKU:
        return ItemsSingleton.searchProductsBySku(state.controller.text);

      case SearchTypeEnum.byProductName:
        return ItemsSingleton.searchProductsByName(state.controller.text);
    }
  }
}
