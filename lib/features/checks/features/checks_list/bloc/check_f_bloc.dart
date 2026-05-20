import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/receipts_get_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/search_receipt_sevice.dart';
import 'package:invan2/features/get_products/singletons/checks_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

part 'check_f_event.dart';

part 'check_f_state.dart';

class CheckFBloc extends Bloc<CheckFEvent, CheckFState> {
  List<ReceiptModel4> checksList;
  List<ReceiptModel4> listt = [];
  String glPattern = '';

  int get pagesLength {
    if (total % limit == 0) {
      return total ~/ limit;
    }
    return total ~/ limit + 1;
  }

  int limit = 20;
  int total = 0;
  int currentPage = 1;
  ReceiptModel4? selectedCheck;

  List<ReceiptModel4> get getReceipts {
    listt.sort(((a, b) => b.date.compareTo(a.date)));
    return listt;
  }

  bool isOk = false;
  int selected = 0;

  CheckFBloc({required this.checksList})
      : selectedCheck = checksList.isEmpty ? null : checksList[0],
        listt = checksList,
        super(CheckFInitial(checksList.isEmpty ? null : checksList[0],
            selected: 0, checksList: checksList)) {
    on<CheckFSearchWhenOnChangeEvent>(_searchOnChanged);
    on<CheckFSearchGlobalEvent>(_searchGlobal);
    on<CheckFCallInitialEvent>(_callInitial);
    on<CheckFSelectCheckEvent>(_selectCheck);
    on<CheckFDateChangedEvent>(_dataChanged);
  }

  _selectCheck(CheckFSelectCheckEvent event, Emitter<CheckFState> emit) {
    selectedCheck = getReceipts[event.selected];
    selected = event.selected;
    emit(CheckFInitial(selectedCheck,
        selected: event.selected, checksList: getReceipts));
  }

  _callInitial(CheckFCallInitialEvent event, Emitter<CheckFState> emit) async {
    listt = checksList;
    currentPage = 1;
    total = 0;
    isOk = false;
    emit(CheckFInitial(checksList.isEmpty ? null : getReceipts[0],
        selected: 0, checksList: getReceipts));
  }

  _searchGlobal(
      CheckFSearchGlobalEvent event, Emitter<CheckFState> emit) async {
    glPattern = event.pattern;
    currentPage = event.page;
    if (event.fromSubmit) {
      listt = [];
      emit(CheckFLoadingState(CheckF.searching, selectedCheck));
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (event.isRetry) {
      emit(CheckFLoadingState(CheckF.searching, selectedCheck));
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!event.isRetry && !event.fromSubmit) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    HttpResult httpResult = await SearchReceiptService.getReceiptss(
      event.pattern.toUpperCase(),
    );
    if (httpResult.isSuccess) {
      listt.addAll(_getList(httpResult, event.pattern));
      if (listt.isEmpty) {
        isOk = false;
        emit(ChecksFNotFoundState(selectedCheck));
        return;
      }
      isOk = true;
      selectedCheck = getReceipts[0];
      emit(CheckFInitial(getReceipts[0], selected: 0, checksList: getReceipts));
    } else {
      emit(CheckFErrorState(httpResult.getError));
    }
  }

  _searchOnChanged(
      CheckFSearchWhenOnChangeEvent event, Emitter<CheckFState> emit) async {
    emit(CheckFLoadingState(CheckF.searching, selectedCheck));
    await Future.delayed(const Duration(milliseconds: 150));
    listt = [];
    listt = checksList
        .where((e) =>
            e.externalId.toLowerCase().contains(event.pattern.toLowerCase()))
        .toList();
    if (listt.isEmpty) {
      emit(ChecksFNotFoundState(selectedCheck));
      return;
    }
    selectedCheck = getReceipts[0];
    isOk = false;
    emit(CheckFInitial(getReceipts[0], selected: 0, checksList: getReceipts));
  }

  _dataChanged(CheckFDateChangedEvent event, Emitter<CheckFState> emit) {
    checksList = event.data;
    selected = 0;
    listt = checksList;
    selectedCheck = event.data.isEmpty ? null : getReceipts[0];
    isOk = false;
    emit(CheckFInitial(
      selectedCheck,
      selected: selected,
      checksList: getReceipts,
    ));
  }

  List<ReceiptModel4> _getList(HttpResult r, String pattern) {
    List<ReceiptModel4> l = [];
    List<GlobalReceipt> getReceiptModel = List<GlobalReceipt>.from(
      json.decode(utf8.decode(r.reBytes))['data'].map((e) {
        return GlobalReceipt.fromJson(e);
      }),
    ).toList();
    List<ReceiptModel4> o = checksList
        .where(
          (e) => e.externalId.toLowerCase().contains(
                pattern.toLowerCase(),
              ),
        )
        .toList();

    if (getReceiptModel.isNotEmpty) {
      for (int i = 0; i < getReceiptModel.length; i++) {
        bool contains = false;
        /*for (int n = 0; n < o.length; n++) {
          if (getReceiptModel[i].externalId == o[n].externalId &&
              getReceiptModel[i].id == o[n].orderId) {
            contains = false;
          }
        }*/
        if (!contains) {
          l.add(
            ChecksSingleton.globalToLocall(getReceiptModel[i]),
          );
        }
      }
    }
    return l;
  }
}

enum CheckF { searching, other }
