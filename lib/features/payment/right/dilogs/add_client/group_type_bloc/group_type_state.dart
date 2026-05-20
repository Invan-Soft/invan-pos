part of 'group_type_bloc.dart';

class GroupTypeState {}

class GroupTypeInitial extends GroupTypeState {}

class GroupTypeSuccesState extends GroupTypeState {
  final List<ClientGroupType> types;
  final ClientGroupType defaultType;

  GroupTypeSuccesState( {required this.types, required this.defaultType,});
}

class GroupTypeFailureState extends GroupTypeState {}

class GroupTypeProccesState extends GroupTypeState {}
