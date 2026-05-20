import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invan2/changes/models/invoice_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/invoices_service.dart';

part 'invoice_event.dart';

part 'invoice_state.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  InvoiceBloc() : super(InvoiceInitial()) {
    // on<GetInvoiceByIdEvent>(getInvoiceById);
    on<GetInvoiceProductsEvent>(getInvoiceProducts);
  }

  Future<void> getInvoiceProducts(
      GetInvoiceProductsEvent event, Emitter<InvoiceState> emit) async {
    emit(GetInvoiceProductsLoading());

    try {
      HttpResult result =
          await InvoicesService.getInvoiceProducts(event.invoiceId);

      if (result.isSuccess) {
        final invoice = InvoiceModel.fromJson(result.result);
        emit(GetInvoiceProductsLoaded(invoice: invoice));
      } else {
        emit(GetInvoiceProductsField());
      }
    } catch (e, stack) {
      emit(GetInvoiceProductsField());
    }
  }
}
