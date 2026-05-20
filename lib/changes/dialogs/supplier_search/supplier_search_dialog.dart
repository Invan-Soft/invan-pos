import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/themes.dart';
import '../../../utils/helpers/size_config.dart';
import '../../bloc/supplier_search/supplier_search_bloc.dart';
import '../../models/supplier_model.dart';
import 'components/search_filed_of_supplier_search._dialog.dart';

class SupplierSearchDialog extends StatefulWidget {
  final Function(SupplierModel supplier) onSupplierSelected;
  final VoidCallback onDeleteSupplier;
  final SupplierModel? currentSupplier;

  const SupplierSearchDialog({
    super.key,
    required this.onSupplierSelected,
    required this.onDeleteSupplier,
    this.currentSupplier,
  });

  @override
  State<SupplierSearchDialog> createState() => _SupplierSearchDialogState();
}

class _SupplierSearchDialogState extends State<SupplierSearchDialog> {
  late SupplierBloc supplierBloc;

  @override
  void initState() {
    supplierBloc = BlocProvider.of(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    final bool isUz = loc.ha == 'Ha';

    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        width: SizeConfig.h * 38.96,
        height: SizeConfig.v * 42.18,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: MyThemes.textWhiteColor,
              blurRadius: 3,
            ),
          ],
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
        ),
        child: BlocConsumer<SupplierBloc, SupplierSearchState>(
          listener: (context, state) async {
            if (state is SupplierFoundState) {
              widget.onSupplierSelected(state.supplier);
              await Future.delayed(const Duration(milliseconds: 800));
              supplierBloc.add(SupplierClearControllerEvent());
              AppNavigation.pop();
            }
            if (state is SupplierNotFoundState) {
              await Future.delayed(const Duration(seconds: 1));
              supplierBloc.add(SupplierInitialEvent());
            }
            if (state is SupplierErrorState) {
              await Future.delayed(const Duration(seconds: 1));
              supplierBloc.add(SupplierInitialEvent());
            }
          },
          builder: (context, state) {
            if (state is SupplierInitialState) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.v * 2,
                  horizontal: SizeConfig.v * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SearchFieldOfSupplierSearchDialog(),
                    widget.currentSupplier != null
                        ? _buildSupplierCard(
                      widget.currentSupplier!,
                      isUz: isUz,
                      showDeleteButton: true,
                    )
                        : const SizedBox.shrink(),
                  ],
                ),
              );
            }

            if (state is SupplierLoadingState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SpinKitCircle(color: Theme.of(context).primaryColor),
                    _buildText(
                      isUz
                          ? 'Supplier qidirilmoqda...'
                          : 'Поиск поставщика...',
                    ),
                  ],
                ),
              );
            }

            if (state is SupplierFoundState) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.v * 2,
                  horizontal: SizeConfig.v * 2,
                ),
                child: _buildSupplierCard(
                  state.supplier,
                  isUz: isUz,
                  showDeleteButton: false,
                ),
              );
            }

            if (state is SupplierNotFoundState) {
              return Center(
                child: _buildText(
                  isUz ? 'Supplier topilmadi' : 'Поставщик не найден',
                ),
              );
            }

            if (state is SupplierErrorState) {
              return Center(child: _buildText(state.error));
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSupplierCard(
      SupplierModel supplier, {
        required bool isUz,
        required bool showDeleteButton,
      }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.v * 2.5,
        horizontal: SizeConfig.h * 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildRow(
                isUz ? 'Kompaniya' : 'Компания',
                supplier.supplierCompanyName,
              ),
              SizedBox(height: SizeConfig.v * 2),

              if (supplier.name.isNotEmpty) ...[
                _buildRow(
                  isUz ? 'Ism' : 'Имя',
                  supplier.name,
                ),
                SizedBox(height: SizeConfig.v * 2),
              ],

              _buildRow(
                isUz ? 'Telefon' : 'Телефон',
                supplier.phoneNumber.isNotEmpty
                    ? supplier.phoneNumber.first
                    : '-',
              ),
              SizedBox(height: SizeConfig.v * 2),

              _buildRow('ID', supplier.externalId),
            ],
          ),

          if (showDeleteButton)
            ElevatedButton(
              onPressed: widget.onDeleteSupplier,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, SizeConfig.v * 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isUz ? "O'chirish" : "Удалить",
                style:
                MyThemes.txtStyleWhite(fontSize: 2.2, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: MyThemes.txtStyleWhite(
            fontSize: 1.9,
            color: Theme.of(context).canvasColor,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: MyThemes.txtStyleWhite(
              fontSize: 1.9,
              color: Theme.of(context).canvasColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: MyThemes.txtStyleWhite(
        fontSize: 4,
        color: Theme.of(context).canvasColor,
      ),
    );
  }
}