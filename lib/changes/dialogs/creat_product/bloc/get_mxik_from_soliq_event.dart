part of 'get_mxik_from_soliq_bloc.dart';

class GetMxikFromSoliqEvent {}

class GetFromSoliq extends GetMxikFromSoliqEvent {
  final String barcode;
  GetFromSoliq({required this.barcode});
}

class CreatToInvan2Event extends GetMxikFromSoliqEvent {
  final CreatProductToInvanModel item;
  final double value;
  CreatToInvan2Event({required this.value, required this.item});
}
