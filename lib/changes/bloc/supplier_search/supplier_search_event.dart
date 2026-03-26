part of 'supplier_search_bloc.dart';

abstract class SupplierEvent {}

class SupplierSearchEvent extends SupplierEvent {}

class SupplierInitialEvent extends SupplierEvent {}

class SupplierClearControllerEvent extends SupplierEvent {}