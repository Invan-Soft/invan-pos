import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import '../../../../../../changes/services/get_def_mxik_from_soliq_service.dart';
import 'package:http/http.dart' as http;
import '../../../../features/get_products/singletons/items_singleton.dart';
import '../../../services/creat_product_service.dart';
import '../model/created_product_model.dart';
import '../model/from_soliq_model.dart';
part 'get_mxik_from_soliq_event.dart';
part 'get_mxik_from_soliq_state.dart';

class GetMxikFromSoliqBloc
    extends Bloc<GetMxikFromSoliqEvent, GetMxikFromSoliqState> {
  GetMxikFromSoliqBloc() : super(GetMxikFromSoliqInitial()) {
    on<GetFromSoliq>(getMxikFromSoliq);
    on<CreatToInvan2Event>(sendToInvan2);
  }
  Future<void> sendToInvan2(
    CreatToInvan2Event event,
    Emitter<GetMxikFromSoliqState> emit,
  ) async {
    emit(CreatToInvan2ProccesState());
    HttpResult skeGenerateResponse = await CreatProductService.skuGenerate();
    if (skeGenerateResponse.isSuccess) {
      String newSku = skeGenerateResponse.result['id'];
      event.item.sku = newSku;
      HttpResult cpresponse = await CreatProductService.productCreate(
          jsonEncode(event.item.toJson()));
      if (cpresponse.isSuccess) {
        HttpResult getProductResponse =
            await CreatProductService.productGet(cpresponse.result['id']);
        if (getProductResponse.isSuccess) {
          String sku = getProductResponse.result['sku'];
          HttpResult oldProductRes =
              await CreatProductService.productOldGet(sku);
          List<ItemModel> itemsList = List<ItemModel>.from(
            oldProductRes.result['data'].map(
              (e) => ItemModel.fromJson(e),
            ),
          ).toList();
          itemsList.where((e) => e.id == cpresponse.result['id']);

          await ItemsSingleton.putItems(itemsList);
          await ItemsSingleton.storeProducts();
          emit(CreatToInvan2SuccesState(item: itemsList.first, value :event.value));
        }
      } else {
        emit(CreatToInvan2FailureState());
      }
    } else {
      emit(CreatToInvan2FailureState());
    }
  }

  Future<void> getMxikFromSoliq(
    GetFromSoliq event,
    Emitter<GetMxikFromSoliqState> emit,
  ) async {
    emit(GetMxikFromSoliqProccesState());
    http.Response httpResult1 =
        await GetFromSoliqService.getFromSoliq(event.barcode);

    if (httpResult1.statusCode == 200) {
      List<FromSoliq> fromSoliq1 = List<FromSoliq>.from(json
          .decode(utf8.decode(httpResult1.bodyBytes))['data']
          .map((e) => FromSoliq.fromJson(e)));

      if (fromSoliq1.isNotEmpty) {
        http.Response httpResult =
            await GetFromSoliqService.getFromSoliqWithMxik(
                fromSoliq1.first.mxik ?? "");
        if (httpResult.statusCode == 200) {
          List<FromSoliq> fromSoliq = List<FromSoliq>.from(json
              .decode(utf8.decode(httpResult.bodyBytes))['data']
              .map((e) => FromSoliq.fromJson(e)));
          if (fromSoliq.isNotEmpty) {
            emit(GetMxikFromSoliqSuccesState(
              fromSoliq: fromSoliq.first,
            ));
          }
        } else {
          emit(GetMxikFromSoliqFailureState());
        }
      } else {
        emit(GetMxikFromSoliqFailureState());
      }
    } else {
      emit(GetMxikFromSoliqFailureState());
    }
  }
}
