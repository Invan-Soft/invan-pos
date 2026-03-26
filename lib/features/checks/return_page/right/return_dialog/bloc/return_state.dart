part of 'return_bloc.dart';

abstract class ReturnState {}

class ReturnInitial extends ReturnState {}

class ReturnLoadingState extends ReturnState {
  final ReturnMessage message;
  ReturnLoadingState({required this.message});
}

class ReturnNoInternetState extends ReturnState {}

class ReturnSuccedState extends ReturnState {}

class ReturnFailedState extends ReturnState {
  final String error;
  
  ReturnFailedState(
      {required this.error});
}
