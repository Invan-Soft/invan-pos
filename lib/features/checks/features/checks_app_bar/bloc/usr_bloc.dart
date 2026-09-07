import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart';
import 'package:uuid/uuid.dart';

import '../../../../../changes/services/api.dart';
import 'package:invan2/changes/services/health/backend_health.dart';

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
      bool internet = await BackendHealth.isUsable();
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
            if (v.statusCode == 409) {
              // Server "bu cheklar menda allaqachon bor" dedi — bu
              // MUVAFFAQIYAT. Qo'lda yuborish yo'li (`_sendSpecial`) buni
              // doim shunday tushungan, avtomatik yo'l esa yo'q edi:
              // 409 "rad etildi" deb belgilanar va chek serverda turgani
              // holda kassada abadiy qizil (!) bo'lib qolardi.
              for (int i = 0; i < receiptList.length; i++) {
                receiptList[i].uploaded = true;
                receiptList[i].rejected = false;
              }
              _put10(receiptList);
              uploadingWorkingg = false;
              emit(UsrFinishedState());
              return;
            }
            if (v.statusCode != 201) {
              emit(UsrErrorState(v.getError));
              _responseSuccess = false;
              uploadingWorkingg = false;

              // Server javob berdimi (4xx/5xx) — bu haqiqiy rad etish:
              // qayta yuborish foydasiz, chek `rejected` bo'lib qo'lda
              // ko'rib chiqiladi.
              //
              // Tarmoq xatosi (timeout = -1, ulanish xatosi = -2) rad etish
              // EMAS. Ilgari ular ham `rejected=true` bo'lardi va chek
              // avtomatik navbatdan (`_find10` faqat rejected=false oladi)
              // BUTUNLAY chiqib ketardi — internet tiklansa ham hech qachon
              // o'zi yuborilmasdi. 2026-08-13 hodisasida 2 ta chek shunday
              // yo'qolgan. Endi bunday chek navbatda qoladi.
              //
              // Tarmoq xatosi Telegramga yozilmaydi — bu loyihada tarmoq
              // xatolari ataylab filtrlanadi (LogRepository.isNetworkError),
              // aks holda har uzilishda o'nlab xabar ketardi.
              // 5xx ikki xil ma'noni anglatishi mumkin, shuning uchun
              // taxmin qilmasdan SERVERNING O'ZIDAN so'raymiz:
              //   • server tirik javob berdi → ayb shu chek(lar)da →
              //     rad etilgan, kassir "Rad etilgan cheklar" da ko'radi;
              //   • server javob bermadi → yiqilgan → cheklar navbatda
              //     qoladi va tiklangach o'zi ketadi.
              //
              // Nima uchun shunday: agar HAR 5xx rad etish deb hisoblansa,
              // server o'chgan paytda bitta guruhdagi 10 tagacha SOG'LOM
              // chek avtomatik navbatdan chiqib ketardi. Agar HECH BIRI
              // rad etish deb hisoblanmasa, serverda xatoga olib keladigan
              // buzuq chek abadiy aylanaverar va kassir uni ko'rmasdi.
              final bool serverRejected =
                  await BackendHealth.isDocumentRejection(v.statusCode);
              if (serverRejected) {
                // GURUH yiqildi, lekin server tirik. Bu HAMMA chek yomon
                // degani EMAS: `api/v1/order_pos` guruhni bittalab qayta
                // ishlaydi va bitta buzuq chekka kelib butun so'rovga xato
                // qaytaradi — undan oldingilari serverda SAQLANIB qolgan
                // bo'ladi.
                //
                // 2026-09-03 da aynan shunday bo'ldi: iyul oyidan qolgan
                // bitta chek (DH148, "sql: no rows in result set") 10 talik
                // guruhni bloklab turardi. Serverda cheklar bor edi, kassada
                // esa hammasi qizil (!) bo'lib ko'rinardi.
                //
                // Shuning uchun guruh yiqilsa BITTALAB qayta yuboramiz:
                // yaxshi cheklar o'tadi, buzug'i yolg'iz qolib ajratiladi.
                await _sendEachSeparately(receiptList);
              }
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

                  // Barcha cheklar ketdi — endi serverga yetmagan smena
                  // ochish/yopish navbatini yuboramiz.
                  await ShiftSyncQueue.flush(reason: 'receipts-uploaded');

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
      bool internet = await BackendHealth.isUsable();
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

  /// Guruh yiqilgandan keyin cheklarni BITTALAB yuboradi.
  ///
  /// Maqsad — bitta buzuq chek qolganlarini garovga olmasin. Har chek
  /// alohida yuboriladi va o'z taqdirini oladi:
  ///   * 201 yoki 409 → serverda bor, `uploaded`
  ///   * boshqa 4xx/5xx (server tirik) → aynan shu chek muammoli,
  ///     `rejected` — kassir uni "Rad etilgan cheklar" da ko'radi
  ///   * tarmoq xatosi / server yiqildi → to'xtaymiz, qolganlari navbatda
  Future<void> _sendEachSeparately(List<ReceiptModel4> receiptList) async {
    for (final ReceiptModel4 receipt in receiptList) {
      final HttpResult one = await ReceiptApi4.receiptCreateGroup([receipt]);

      if (one.statusCode == 201 || one.statusCode == 409) {
        receipt.uploaded = true;
        receipt.rejected = false;
        continue;
      }

      final bool rejected =
          await BackendHealth.isDocumentRejection(one.statusCode);
      if (!rejected) {
        // Server javob bermay qoldi — qolganlarini urinishning ma'nosi yo'q,
        // ular navbatda qolsin.
        break;
      }

      receipt.rejected = true;
      LogRepository.addLog(
        "Chek serverda xatoga olib keldi (bittalab yuborishda): "
        "${one.getError}",
        where: "UsrBloc._sendEachSeparately",
        file: "usr_bloc.dart",
        method: "POST",
        path: "api/v1/order_pos",
        statusCode: one.statusCode,
        checkNo: receipt.externalId,
        createdDate: receipt.createdDate,
        success: false,
      );
    }
    _put10(receiptList);
  }

  /// Yuborilishi kerak bo'lgan SOTUV cheklari.
  ///
  /// Qaytarishlar ATAYLAB chiqarib tashlangan: ular butunlay boshqa
  /// endpointdan (`refund_for_pos_new` + `refund_order_items`) ketadi va
  /// `RefundUploadQueue` bilan yuboriladi. `receiptCreateGroup` ularni
  /// `jsonListFromRefund` ga yig'adi-yu hech qayerga yubormaydi — ya'ni
  /// bu yerga tushgan qaytarish yuborilmagan holicha qolar, bundan ham
  /// yomoni: server guruhga 4xx qaytarsa GURUHDAGI HAMMA chek (haqiqiy
  /// sotuvlar ham) `rejected = true` bo'lib qolardi.
  static List<ReceiptModel4> _find10() {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final query = box
        .query(ReceiptModel4_.uploaded.equals(false) &
            ReceiptModel4_.rejected.equals(false) &
            ReceiptModel4_.isRefund.equals(false))
        .build();
    List<ReceiptModel4> receiptList = query.find().take(10).toList();
    query.close();
    return receiptList;
  }

  /// Server rad etgan SOTUV cheklari (qo'lda qayta yuborish uchun).
  ///
  /// Qaytarishlar bu yerga ham kirmaydi — yuqoridagi izohga qarang.
  static List<ReceiptModel4> _findIsRejected10() {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final query = box
        .query(ReceiptModel4_.uploaded.equals(false) &
            ReceiptModel4_.rejected.equals(true) &
            ReceiptModel4_.isRefund.equals(false))
        .build();
    List<ReceiptModel4> receiptList = query.find().take(10).toList();
    query.close();
    return receiptList;
  }
}
