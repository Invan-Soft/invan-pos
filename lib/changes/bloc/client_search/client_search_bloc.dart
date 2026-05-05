import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';

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
