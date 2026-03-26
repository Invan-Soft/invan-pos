part of 'get_mxik_from_soliq_bloc.dart';

class GetMxikFromSoliqState {}

class GetMxikFromSoliqInitial extends GetMxikFromSoliqState {}

class GetMxikFromSoliqProccesState extends GetMxikFromSoliqState {}

class GetMxikFromSoliqSuccesState extends GetMxikFromSoliqState {
  final FromSoliq fromSoliq;

  GetMxikFromSoliqSuccesState({
    required this.fromSoliq,
  });
}

class GetMxikFromSoliqFailureState extends GetMxikFromSoliqState {}

//////////////

class CreatToInvan2ProccesState extends GetMxikFromSoliqState {}

class CreatToInvan2SuccesState extends GetMxikFromSoliqState {
  final ItemModel item;
  final double value;
  CreatToInvan2SuccesState( {required this.value, required this.item});
}

class CreatToInvan2FailureState extends GetMxikFromSoliqState {}
