import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart';
import 'package:uuid/uuid.dart';

import '../../../../../changes/services/api.dart';
import '../../../../../utils/utils.dart';

part 'usr_event.dart';

part 'usr_state.dart';

// Usr means UnSentReceipts
class UsrBloc extends Bloc<UsrEvent, UsrState> {
  StreamSubscription? subscription;
  int unsents = 0;
  bool uploadingWorkingg = false;
  bool uploadingWorkingg2 = false;
  bool _responseSuccess = true;

  UsrBloc() : super(UsrInitial()) {
    on<UsrSendEvent>(_send);
    on<UsrSendSpecialEvent>(_sendSpecial);
    on<UsrCallInitialEvent>(_callInitial);
    on<UsrDataChangedEvent>(_dataChanged);
  }

  _dataChanged(UsrDataChangedEvent event, Emitter<UsrState> emit) {
    unsents = event.unsents;
    emit(UsrInitial());
  }

  _callInitial(UsrCallInitialEvent event, Emitter<UsrState> emit) {
    emit(UsrInitial());
  }

  _send(UsrSendEvent event, Emitter<UsrState> emit) async {
    unsents = event.unsents ?? unsents;
    emit(UsrLoadingState(""));
    await Future.delayed(const Duration(milliseconds: 500));
    _responseSuccess = true;
    if (!uploadingWorkingg) {
      uploadingWorkingg = true;
      emit(UsrLoadingState("Checking for Internet..."));
      bool internet = await InternetConnectionChecker().hasConnection;
      await Future.delayed(const Duration(milliseconds: 900));
      if (internet) {
        emit(UsrInSendingState());

        final box = MyObjectbox.saleStore.box<ReceiptModel4>();
        List<ReceiptModel4> receiptList = _find10().map((r) {
          final needsRepair = r.externalId.isEmpty ||
              (!r.isRefund && r.orderId.isEmpty);
          if (needsRepair) {
            LogRepository.addLog(
              "Repairing receipt before upload: ext=${r.externalId}, order=${r.orderId}",
              where: "UsrBloc._send",
              statusCode: 0,
              success: false,
              file: 'usr_bloc.dart',
              checkNo: r.externalId,
              createdDate: r.createdDate,
            );
            if (r.externalId.isEmpty) {
              r.externalId = "REP-${r.id}";
            }
            if (!r.isRefund && r.orderId.isEmpty) {
              r.orderId = const Uuid().v7();
            }
            box.put(r, mode: PutMode.update);
          }
          return r;
        }).where((r) => r.soldItemList.isNotEmpty).toList();

        if (receiptList.isNotEmpty) {
          for (; receiptList.isNotEmpty && _responseSuccess;) {
            HttpResult? v = await ReceiptApi4.receiptCreateGroup(receiptList);
            if (v.statusCode != 201) {
              emit(UsrErrorState(v.getError));
              _responseSuccess = false;
              uploadingWorkingg = false;
              for (int i = 0; i < receiptList.length; i++) {
                receiptList[i].rejected = true;
              }
              _put10(receiptList);
              return;
            } else {
              if (v.statusCode == 201) {
                for (int i = 0; i < receiptList.length; i++) {
                  if (receiptList[i].isRefund == false) {
                    receiptList[i].uploaded = true;
                    receiptList[i].rejected = false;
                  }
                }
                _put10(receiptList);
                if (receiptList.isEmpty) return;
                receiptList = _find10();
                if (receiptList.isEmpty) {
                  _responseSuccess = false;
                  uploadingWorkingg = false;

                  //////////////   CLOSE SHIFT   ///////////////
                  if (Pref.getString(PrefKeys.closedDate, '').isNotEmpty &&
                      Pref.getInt(PrefKeys.closedCount, 0) == 1) {
                    if (kDebugMode) {
                      print('CLOSE SHIFT');
                    }
                    await ShiftApi4.closeShift();
                    await Pref.setInt(PrefKeys.closedCount, 0);
                    await Pref.setString(PrefKeys.closedDate, '');
                  }
                  //////////////   OPEN SHIFT   ///////////////
                  if (Pref.getString(PrefKeys.openedDate, '').isNotEmpty &&
                      Pref.getInt(PrefKeys.openedCount, 0) == 1) {
                    if (kDebugMode) {
                      print('OPEN SHIFT');
                    }
                    await ShiftApi4.openShift();
                    await Pref.setInt(PrefKeys.openedCount, 0);
                    await Pref.setString(PrefKeys.openedDate, '');
                  }

                  emit(UsrFinishedState());
                  return;
                } else {
                  _responseSuccess = true;
                }
              } else {
                _responseSuccess = false;
                uploadingWorkingg = false;
                emit(UsrBackendRejectedState(v.result.body.toString()));
                return;
              }
            }
          }
        } else {
          uploadingWorkingg = false;
          emit(UsrNoUnsentReceiptsState());
          return;
        }
      } else {
        //if no internet
        uploadingWorkingg = false;
        emit(UsrNoInternetState("If no internet bloc 99 "));
        return;
      }
    } else {
      emit(UsrAlreadyInProgressState());
      return;
    }
  }

  _sendSpecial(UsrSendSpecialEvent event, Emitter<UsrState> emit) async {
    unsents = event.unsents ?? unsents;
    emit(UsrLoadingState(""));
    await Future.delayed(const Duration(milliseconds: 500));
    if (uploadingWorkingg2 == false) {
      uploadingWorkingg2 = true;
      emit(UsrLoadingState("Checking for Internet..."));
      bool internet = await InternetConnectionChecker().hasConnection;
      await Future.delayed(const Duration(milliseconds: 900));
      if (internet) {
        emit(UsrInSendingState());

        List<ReceiptModel4> receiptList = _findIsRejected10();

        if (receiptList.isNotEmpty) {
          for (int i = 0; i < receiptList.length; i++) {
            HttpResult? v =
                await ReceiptApi4.receiptCreateGroup([receiptList[i]]);
            if (v.statusCode == 201 || v.statusCode == 409) {
              if (receiptList[i].isRefund == false) {
                receiptList[i].uploaded = true;
                receiptList[i].rejected = false;
              }
              // List<ReceiptModel4> refundedReceiptList = [];
              // if (receiptList[i].isRefund == true) {
              //   HttpResult? refundResponse =
              //       await ReceiptApi4.receiptCreateGrouppForRefund(
              //           receiptList[i]);
              //   if (refundResponse.statusCode == 200) {
              //     receiptList[i].uploaded = true;
              //     refundedReceiptList.add(receiptList[i]);
              //   }
              // }
              // if (refundedReceiptList.isNotEmpty) {
              //   _put10(refundedReceiptList);
              // }
              if (receiptList.isEmpty) return;
            }
          }
          uploadingWorkingg2 = false;
          _put10(receiptList);
          emit(UsrFinishedState());
        } else {
          uploadingWorkingg2 = false;
          emit(UsrNoUnsentReceiptsState());
          return;
        }
      } else {
        //if no internet
        uploadingWorkingg2 = false;
        emit(UsrNoInternetState("If no internet bloc 99 "));
        return;
      }
    } else {
      emit(UsrAlreadyInProgressState());
      return;
    }
  }

  static _put10(List<ReceiptModel4> receiptList) {
    if (receiptList.isNotEmpty) {
      final box = MyObjectbox.saleStore.box<ReceiptModel4>();
      if (receiptList.length > 1) {
        box.putMany(receiptList);
      } else {
        box.put(receiptList[0]);
      }
    } else {
      if (kDebugMode) {
        print("No receipts to save.");
      }
    }
  }

  static List<ReceiptModel4> _find10() {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final query = box
        .query(ReceiptModel4_.uploaded.equals(false) &
            ReceiptModel4_.rejected.equals(false))
        .build();
    List<ReceiptModel4> receiptList = query.find().take(10).toList();
    query.close();
    return receiptList;
  }

  static List<ReceiptModel4> _findIsRejected10() {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final query = box
        .query(ReceiptModel4_.uploaded.equals(false) &
            ReceiptModel4_.rejected.equals(true))
        .build();
    List<ReceiptModel4> receiptList = query.find().take(10).toList();
    query.close();
    return receiptList;
  }
}
