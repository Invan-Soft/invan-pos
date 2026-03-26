import 'dart:convert';

import 'package:invan2/changes/models/product/item_model.dart';

import '../../fiscal_service/model/error/error_response_model.dart';

abstract class ApiState {
  final int code;
  final Object response;

  ApiState(this.code, this.response);

  dynamic decodedData() => jsonDecode(response.toString());
}

class Success extends ApiState {
  Success(int code, Object response) : super(code, response);

  @override
  decodedData() {
    return jsonDecode(response.toString())['result'];
  }

  decodeResult() => jsonDecode(response.toString())['result'];
}

class SuccessItem extends ApiState {
  SuccessItem(int code, List<ItemModel> response) : super(code, response);

  @override
  decodedData() {
    return jsonDecode(response.toString())['result'];
  }

  decodeResult() => jsonDecode(response.toString())['result'];
}

class Failure extends ApiState {
  Failure(int code, Object response) : super(code, response);

  @override
  String toString() {
    return response.toString();
  }

  String errorMessage() {
    if (code == 200) {
      var decoded = jsonDecode(response.toString())['error'];
      ErrorModel error = ErrorModel.fromJson(decoded);
      return error.toMessage();
    }
    return response.toString();
  }
}
