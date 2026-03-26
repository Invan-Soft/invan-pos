part of 'supplier_search_bloc.dart';

abstract class SupplierSearchState {}

class SupplierInitialState extends SupplierSearchState {}

class SupplierLoadingState extends SupplierSearchState {}

class SupplierFoundState extends SupplierSearchState {
  final SupplierModel supplier;
  SupplierFoundState({required this.supplier});
}

class SupplierNotFoundState extends SupplierSearchState {}

class SupplierErrorState extends SupplierSearchState {
  final String error;
  SupplierErrorState(this.error);
}