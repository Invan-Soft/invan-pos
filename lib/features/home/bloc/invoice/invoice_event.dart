part of 'invoice_bloc.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();

  @override
  List<Object> get props => [];
}

class GetInvoiceByIdEvent extends InvoiceEvent {
  String invoiceId;

  GetInvoiceByIdEvent({required this.invoiceId});
}
class GetInvoiceProductsEvent extends InvoiceEvent {
  String invoiceId;

  GetInvoiceProductsEvent({required this.invoiceId});
}