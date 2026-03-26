import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../features/home/bloc/invoice/invoice_bloc.dart';
import '../../utils/helpers/size_config.dart';
import '../../utils/l10n/app_localizations.dart';
import '../../utils/themes.dart';
import '../../app_navigation.dart';

class InvoiceSearchDialog extends StatefulWidget {
  final Function(String) onSearch;

  const InvoiceSearchDialog({super.key, required this.onSearch});

  @override
  State<InvoiceSearchDialog> createState() => _InvoiceSearchDialogState();
}

class _InvoiceSearchDialogState extends State<InvoiceSearchDialog> {
  final TextEditingController idController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFieldFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;

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
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Input field
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.h * 1.5,
                vertical: SizeConfig.v * 0.5,
              ),
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.h * 2),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: idController,
                      focusNode: _textFieldFocus,
                      decoration: InputDecoration(
                        hintStyle: TextStyle(color: Colors.white),
                        hintText:
                            loc.ha == "Ha" ? "Invoice ID..." : "ID инвойса...",
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).canvasColor,
                        fontSize: SizeConfig.v * 2,
                      ),
                      onSubmitted: (_) => _searchPressed(),
                    ),
                  ),
                  IconButton(
                    onPressed: _searchPressed,
                    icon: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: SizeConfig.v * 3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: BlocConsumer<InvoiceBloc, InvoiceState>(
                listener: (context, state) async {
                  if (state is GetInvoiceProductsLoaded) {
                    await Future.delayed(const Duration(milliseconds: 600));
                    if (mounted) {
                      AppNavigation.pop();
                      widget.onSearch(idController.text.trim());

                      idController.clear();
                      _hasSearched = false;
                    }
                  }
                  if (state is GetInvoiceProductsField) {
                    await Future.delayed(const Duration(milliseconds: 600));
                    if (mounted) {
                      AppNavigation.pop();
                      idController.clear();
                      _hasSearched = false;
                      setState(() {});
                    }
                  }

                  if (state is GetInvoiceProductsField) {
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) {
                      idController.clear();
                      _textFieldFocus.requestFocus();
                      _hasSearched = false;
                      setState(() {});
                    }
                  }
                },
                builder: (context, state) {
                  if (!_hasSearched) {
                    return Center(
                      child: Text(
                        loc.ha == "Ha"
                            ? "Invoice ID ni kiriting"
                            : "Введите ID инвойса",
                        style: MyThemes.txtStyleWhite(
                          fontSize: 2.2,
                          color: Theme.of(context).canvasColor.withOpacity(0.7),
                        ),
                      ),
                    );
                  }

                  if (state is GetInvoiceProductsLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpinKitCircle(
                            color: Theme.of(context).primaryColor,
                            size: SizeConfig.v * 8,
                          ),
                          SizedBox(height: SizeConfig.v * 3),
                          Text(
                            loc.ha == "Ha"
                                ? "Invoice qidirilmoqda..."
                                : "Поиск инвойса...",
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyleWhite(
                              fontSize: 2.5,
                              color: Theme.of(context).canvasColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is GetInvoiceProductsLoaded) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: SizeConfig.v * 8,
                          ),
                          SizedBox(height: SizeConfig.v * 3),
                          Text(
                            loc.ha == "Ha"
                                ? "Invoice topildi!"
                                : "Инвойс найден!",
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyleWhite(
                              fontSize: 3,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: SizeConfig.v * 1.5),
                          Text(
                            loc.ha == "Ha"
                                ? "Mahsulotlar yuklanmoqda..."
                                : "Загрузка товаров...",
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyleWhite(
                              fontSize: 2,
                              color: Theme.of(context)
                                  .canvasColor
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is GetInvoiceProductsField) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.redAccent, size: SizeConfig.v * 8),
                          SizedBox(height: SizeConfig.v * 2),
                          Text(
                            loc.ha == "Ha"
                                ? "Invoice topilmadi"
                                : "Инвойс не найден",
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyleWhite(
                              fontSize: 1.8,
                              color: Theme.of(context)
                                  .canvasColor
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchPressed() {
    final text = idController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _hasSearched = true;
    });

    context.read<InvoiceBloc>().add(
          GetInvoiceProductsEvent(invoiceId: text),
        );
  }

  @override
  void dispose() {
    idController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }
}
