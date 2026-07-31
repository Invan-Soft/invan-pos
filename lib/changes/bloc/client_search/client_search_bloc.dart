import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/models/supplier_model.dart';
import 'package:invan2/changes/services/supplier_service.dart';

part 'client_search_event.dart';

part 'client_search_state.dart';

class ClientBloc extends Bloc<ClientEvent, SearchClientState> {
  TextEditingController controller = TextEditingController();

  ClientBloc() : super(ClientInitialState()) {
    on<ClientSearchEvent>(_clientSearch);
    on<ClientInitialEvent>(_initial);
    on<ClientClearControllerEvent>(_clearController);
  }

  _clearController(
      ClientClearControllerEvent event, Emitter<SearchClientState> emit) {
    controller.text = '';
  }

  _initial(ClientInitialEvent event, Emitter<SearchClientState> emit) {
    controller = TextEditingController();
    emit(ClientInitialState());
  }

  _clientSearch(
      ClientSearchEvent event, Emitter<SearchClientState> emit) async {
    String fixedText = _fixKeyboardLayout(controller.text.trim());
    if (fixedText.length > 8) {
      emit(ClientLoadingState(ClientLS.internet));

      emit(ClientLoadingState(ClientLS.client));
      if (!await InternetConnectionChecker().hasConnection &&
          fixedText.length == 36) {
        emit(ClientFoundState(
          client: ClientModel(
            id: fixedText,
            phoneNumber: '',
            firstName: '',
            externalId: '',
            discountValue: 0,
          ),
        ));
      } else if (event.alsoCheckSupplier) {
        // Perechisleniya/Didox oynasi: xuddi shu INN bo'yicha clients_by_pos
        // va supplier (postavshik) API'lariga parallel so'rov yuboriladi —
        // qaysinisi natija (ma'lumot) qaytarsa, o'shani ishlatamiz.
        final results = await Future.wait([
          ClientApi.clientByCardIdd(
              cardId: fixedText,
              isSpecialClient: event.isSpecialClient,
              where: "CLIENT SEARCH BLOC (perechisleniya)"),
          SupplierApi.searchSuppliers(search: fixedText),
        ]);
        final HttpResult clientResult = results[0];
        final HttpResult supplierResult = results[1];

        try {
          // Client ustuvor: shu INN bo'yicha mijoz topilsa, o'shani ishlatamiz.
          final clientItem = _firstDataItem(clientResult);
          if (clientItem != null) {
            emit(ClientFoundState(client: ClientModel.fromJson(clientItem)));
            return;
          }
          // Mijoz topilmadi — shu INN'ni supplier (postavshik) bazasidan qidiramiz.
          final supplierItem = _firstDataItem(supplierResult);
          if (supplierItem != null) {
            emit(ClientSearchSupplierFoundState(
                supplier: SupplierModel.fromJson(supplierItem)));
            return;
          }
        } catch (e) {
          // Kutilmagan javob shakli yoki parse xatosi — UI SpinKit'da abadiy
          // qotmasligi uchun har qanday holatda ham xato holatini emit qilamiz.
          emit(ClientErrorState("Ma'lumotni o'qishda xato"));
          return;
        }

        // Ikkalasida ham topilmadi. Ikkalasi ham xato bo'lsa — error ko'rsatamiz,
        // aks holda (kamida bittasi muvaffaqiyatli, lekin bo'sh) — "topilmadi".
        if (!clientResult.isSuccess && !supplierResult.isSuccess) {
          emit(ClientErrorState(clientResult.getError));
          return;
        }

        emit(ClientNotFoundState());
      } else {
        HttpResult httpResult = await ClientApi.clientByCardIdd(
            cardId: fixedText,
            isSpecialClient: event.isSpecialClient,
            where: "CLIENT SEARCH BLOC");
        if (httpResult.isSuccess) {
          ClientModel? client;
          if (httpResult.result['data'].isEmpty) {
            emit(ClientNotFoundState());
          } else {
            client = ClientModel.fromJson(httpResult.result['data'][0]);
            emit(ClientFoundState(client: client));
          }
        } else {
          emit(ClientErrorState(httpResult.getError));
        }
      }
    } else {
      emit(ClientInvalidIdState(controller.text));
    }
  }

  /// HttpResult javobidan birinchi ma'lumot elementini (Map) XAVFSIZ ajratadi.
  /// Qo'llab-quvvatlanadigan shakllar: {data: [...]} yoki top-level [...].
  /// Muvaffaqiyatsiz javob, kutilmagan shakl, bo'sh ro'yxat yoki Map bo'lmagan
  /// element bo'lsa null qaytaradi — HECH QACHON exception tashlamaydi.
  Map<String, dynamic>? _firstDataItem(HttpResult r) {
    if (!r.isSuccess) return null;
    final dynamic res = r.result;
    List? list;
    if (res is Map && res['data'] is List) {
      list = res['data'] as List;
    } else if (res is List) {
      list = res;
    }
    if (list == null || list.isEmpty) return null;
    final first = list.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
    return null;
  }

  String _fixKeyboardLayout(String text) {
    const layoutMap = {
      'а': 'f',
      'б': ',',
      'в': 'd',
      'г': 'u',
      'д': 'l',
      'е': 't',
      'ё': '`',
      'ж': ';',
      'з': 'p',
      'и': 'b',
      'й': 'q',
      'к': 'r',
      'л': 'k',
      'м': 'v',
      'н': 'y',
      'о': 'j',
      'п': 'g',
      'р': 'h',
      'с': 'c',
      'т': 'n',
      'у': 'e',
      'ф': 'a',
      'х': '[',
      'ц': 'w',
      'ч': 'x',
      'ш': 'i',
      'щ': 'o',
      'ь': 'm',
      'ы': 's',
      'ъ': ']',
      'э': '\'',
      'ю': '.',
      'я': 'z',
    };

    final buffer = StringBuffer();
    for (final ch in text.split('')) {
      buffer.write(layoutMap[ch] ?? ch);
    }
    return buffer.toString();
  }
}

enum ClientLS { internet, client }
