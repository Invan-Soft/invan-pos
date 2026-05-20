part of 'invoice_bloc.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class GetInvoiceLoading extends InvoiceState {}

class GetInvoiceLoaded extends InvoiceState {
  InvoiceModel invoice;

  GetInvoiceLoaded({required this.invoice});
}

class GetInvoiceField extends InvoiceState {}

class GetInvoiceProductsLoading extends InvoiceState {}

class GetInvoiceProductsLoaded extends InvoiceState {
  InvoiceModel invoice;
  GetInvoiceProductsLoaded({required this.invoice});
}

class GetInvoiceProductsField extends InvoiceState {}
