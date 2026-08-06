// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/product_search/dialog/bloc/serch_dialog_bloc.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/product_search/dialog/components/search_product_button.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import '../../../../../../../changes/dialogs/virtual_keyboard/content_of_virtual_keyboard.dart';
import '../../../../../../../changes/providers/product_search_provider.dart';
import '../../top_buttons/button_widgets/select_search_button.dart';
import '../../../../../../../features/get_products/singletons/items_singleton.dart';
import '../../../../../../../changes/models/product/item_model.dart';

class SearchDialogContent extends StatefulWidget {
  SearchDialogContent({
    super.key,
    required this.searchTypeEnum,
  });

  SearchTypeEnum searchTypeEnum;

  @override
  SearchDialogContentState createState() => SearchDialogContentState();
}

class SearchDialogContentState extends State<SearchDialogContent> {
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode();
  bool entering = false;
  final itemPressed = VoidCallback;
  late ScrollController scrollController;
  int select = 2;
  late SDbloc sdBloc;

  @override
  void initState() {
    scrollController = ScrollController();
    final SDbloc searchDialogBloc = BlocProvider.of(context);
    searchDialogBloc.state.controller = TextEditingController();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sdBloc = BlocProvider.of<SDbloc>(context);
  }

  List<ItemModel> _getCurrentResults() {
    final text = sdBloc.state.controller.text ?? '';
    switch (sdBloc.searchTypeEnum) {
      case SearchTypeEnum.option:
        return ItemsSingleton.search(text);
      case SearchTypeEnum.byBarcode:
        return ItemsSingleton.searchProductsByBarcode(text);
      case SearchTypeEnum.bySKU:
        return ItemsSingleton.searchProductsBySku(text);
      case SearchTypeEnum.byProductName:
        return ItemsSingleton.searchProductsByName(text);
    }
  }

  bool _popped = false;
  bool _retryScheduled = false;

  bool _isBarcodeLike(String q) => RegExp(r'^\d{6,}$').hasMatch(q);

  void _popWith(ItemModel item) {
    if (_popped) return;
    _popped = true;
    AppNavigation.pop(v: item);
  }

  /// Enter bosilganda mahsulot tanlash — yagona kirish nuqtasi (raw Enter,
  /// TextField onSubmitted va virtual klaviatura shu yerga keladi, _popped
  /// flag ikki marta pop bo'lishdan saqlaydi). Qoidalar:
  ///  - Skaner kiritishi yoki barcode-ko'rinishdagi matn (faqat raqam, ≥6):
  ///    FAQAT 100% teng barcode qabul qilinadi — prefix/contains taxmin yo'q.
  ///  - Skanerning raw Enter'i matn to'liq yetib kelishidan OLDIN kelishi
  ///    mumkin (klaviatura va text-input pipeline'lari alohida) — bunda
  ///    biroz kutib qayta tekshiriladi, qisman matndan mahsulot tanlanmaydi.
  ///  - Qo'lda ishlash: strelka bilan aniq tanlangan bo'lsa o'sha, aks holda
  ///    nom/SKU qidiruvida birinchi natija (eski xatti-harakat saqlanadi).
  ///  - Barcode rejimida aniq moslik bo'lmasa hech narsa avto-qo'shilmaydi.
  void _submit() {
    if (_popped) return;
    final text = sdBloc.state.controller.text.trim();
    final bool scanner = MyBarcodeListener.isScannerBurst;

    if (scanner || _isBarcodeLike(text)) {
      final exact = text.length >= 6
          ? ItemsSingleton.getProductByBarcode(text, allowSkuFallback: false)
          : null;
      if (exact != null) return _popWith(exact);
      if (scanner) return _retryExactAfterTextSettles();
      if (sdBloc.searchTypeEnum == SearchTypeEnum.byBarcode) return;
    }

    final results = _getCurrentResults();
    if (results.isEmpty) return;

    final selected = sdBloc.state.selected;
    if (selected >= 0) {
      // Foydalanuvchi strelka bilan aniq tanlagan. Indeks joriy ro'yxatga
      // sig'masa (ro'yxat o'zgarib ulgurgan) — taxmin qilmaymiz.
      if (selected < results.length) _popWith(results[selected]);
      return;
    }

    if (sdBloc.searchTypeEnum == SearchTypeEnum.byBarcode) return;
    _popWith(results[0]);
  }

  /// Skaner belgilarining bir qismi Enter'dan keyin yetib keladi — matn
  /// "to'lgach" aniq moslik bir marta qayta tekshiriladi. Baribir topilmasa,
  /// keyingi skan eski matnga yopishib qolmasligi uchun maydon tozalanadi.
  void _retryExactAfterTextSettles() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      _retryScheduled = false;
      if (!mounted || _popped) return;
      final text = sdBloc.state.controller.text.trim();
      final exact = text.length >= 6
          ? ItemsSingleton.getProductByBarcode(text, allowSkuFallback: false)
          : null;
      if (exact != null) return _popWith(exact);
      sdBloc.state.controller.clear();
      sdBloc.add(SDtypedEvent(''));
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _keyboardFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final SDbloc searchDialogBloc = BlocProvider.of(context);

    final hintText = widget.searchTypeEnum != SearchTypeEnum.option
        ? widget.searchTypeEnum != SearchTypeEnum.byBarcode
            ? widget.searchTypeEnum != SearchTypeEnum.bySKU
                ? loc.mahsulotNomiBoyichaQidirish
                : loc.artikulBoyichaQidirish
            : loc.shtrixKodOrqaliQidirish
        : 'Search';

    widget.searchTypeEnum == SearchTypeEnum.byBarcode
        ? select = 2
        : widget.searchTypeEnum == SearchTypeEnum.byProductName
            ? select = 1
            : widget.searchTypeEnum == SearchTypeEnum.bySKU
                ? select = 3
                : 2;

    return BlocConsumer<SDbloc, SDstate>(
      listener: (context, state) {
        if (state.status != SDStatus.pop) {
          if (state.selected > 4) {
            scrollController.animateTo((state.selected - 4) * 45,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease);
          } else if (state.selected > -1) {
            scrollController.animateTo(state.selected - 1 * 45,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease);
          }
        }

        if (state.status == SDStatus.pop) {
          // Virtual klaviatura Enter'i. _submit() aniq moslik qoidalarini
          // qo'llab, topilsa mahsulot bilan pop qiladi (mahsulotni dialog
          // ochgan tomon pressProduct qiladi). Topilmasa dialog shunchaki
          // yopiladi — bloc'ning eskirgan (stale) ro'yxatidan taxmin qilinmaydi.
          _submit();
          if (!_popped) {
            _popped = true;
            AppNavigation.pop();
          }
          return;
        }
      },
      builder: (context, state) {
        return RawKeyboardListener(
          onKey: (event) {
            if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
              sdBloc.add(SDarrowEvent(ArrowTo.down));
            }
            if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
              sdBloc.add(SDarrowEvent(ArrowTo.up));
            }
            if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
              _submit();
            }
          },
          focusNode: _keyboardFocusNode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Pref.getBool('switchProductName', true) ||
                            widget.searchTypeEnum !=
                                SearchTypeEnum.byProductName
                        ? TextField(
                            controller: state.controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: MyThemes.txtStyle(
                                color: Theme.of(context).canvasColor),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.only(left: SizeConfig.h * 1.5),
                              hintText: hintText,
                              hintStyle: MyThemes.txtStyle(color: Colors.grey),
                            ),
                            onChanged: (v) {
                              // if (widget.searchTypeEnum ==
                              //     SearchTypeEnum.byBarcode) {
                              //   final digitsOnly =
                              //       v.replaceAll(RegExp(r'[^0-9]'), '');
                              //   if (v != digitsOnly) {
                              //     state.controller.value = TextEditingValue(
                              //       text: digitsOnly,
                              //       selection: TextSelection.collapsed(
                              //           offset: digitsOnly.length),
                              //     );
                              //     sdBloc.add(SDtypedEvent(digitsOnly));
                              //     return;
                              //   }
                              // }
                              sdBloc.add(SDtypedEvent(v));
                            },
                            onSubmitted: (v) {
                              _submit();
                            },
                          )
                        : TextField(
                            controller: state.controller,
                            focusNode: _focusNode,
                            enabled: false,
                            readOnly: true,
                            style: MyThemes.txtStyle(
                                color: Colors.grey.withOpacity(0.6)),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.only(left: SizeConfig.h * 1.5),
                              hintText: hintText,
                              hintStyle: MyThemes.txtStyle(color: Colors.grey),
                            ),
                          ),
                  ),
                  Text(
                    "${state.selected > -1 ? "${(state.selected + 1)}/" : ""}${state.searchedProducts.isEmpty ? "" : state.searchedProducts.length}",
                    style: MyThemes.txtStyle(
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                  SizedBox(width: SizeConfig.h * 2),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          searchDialogBloc.add(SDinitializeSearchTypeEnumEvent(
                              SearchTypeEnum.byProductName));

                          if (!Pref.getBool('switchProductName', true)) {
                            state.controller.clear();
                            sdBloc.add(SDtypedEvent(""));
                          } else {
                            sdBloc.add(SDtypedEvent(state.controller.text));
                            if (state.searchedProducts.length == 1) {
                              sdBloc.add(SDarrowEvent(ArrowTo.down));
                            }
                          }

                          select = 1;
                          widget.searchTypeEnum = SearchTypeEnum.byProductName;
                          setState(() {});

                          if (Pref.getBool('switchProductName', true)) {
                            Future.delayed(const Duration(milliseconds: 50),
                                () {
                              FocusScope.of(context).requestFocus(_focusNode);
                            });
                          }
                        },
                        child: SelectSearchButton(
                          imageUrl: "assets/images/label.png",
                          bacColor: select == 1
                              ? MyThemes.darkPrimaryColor
                              : Colors.transparent,
                        ),
                      ),
                      SizedBox(width: SizeConfig.h),
                      InkWell(
                        onTap: () {
                          searchDialogBloc.add(SDinitializeSearchTypeEnumEvent(
                              SearchTypeEnum.byBarcode));

                          sdBloc.add(SDtypedEvent(state.controller.text));

                          select = 2;
                          widget.searchTypeEnum = SearchTypeEnum.byBarcode;
                          setState(() {});

                          Future.delayed(const Duration(milliseconds: 50), () {
                            FocusScope.of(context).requestFocus(_focusNode);
                          });
                        },
                        child: SelectSearchButton(
                          imageUrl: "assets/images/barcode.png",
                          bacColor: select == 2
                              ? MyThemes.darkPrimaryColor
                              : Colors.transparent,
                        ),
                      ),
                      SizedBox(width: SizeConfig.h),
                      InkWell(
                        onTap: () {
                          searchDialogBloc.add(SDinitializeSearchTypeEnumEvent(
                              SearchTypeEnum.bySKU));

                          sdBloc.add(SDtypedEvent(state.controller.text));

                          select = 3;
                          widget.searchTypeEnum = SearchTypeEnum.bySKU;
                          setState(() {});

                          Future.delayed(const Duration(milliseconds: 50), () {
                            FocusScope.of(context).requestFocus(_focusNode);
                          });
                        },
                        child: SelectSearchButton(
                          imageUrl: "assets/images/skuText.png",
                          bacColor: select == 3
                              ? MyThemes.darkPrimaryColor
                              : Colors.transparent,
                        ),
                      ),
                      SizedBox(width: SizeConfig.h),
                      CloseButton(
                        color: Theme.of(context).canvasColor,
                        onPressed: () {
                          AppNavigation.pop();
                        },
                      ),
                      SizedBox(width: SizeConfig.h),
                    ],
                  ),
                ],
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.searchedProducts.isEmpty) {
                      return Center(
                        child: Text(
                          'No items',
                          style: MyThemes.txtStyle(color: Colors.grey),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: SizeConfig.v * 40),
                        controller: scrollController,
                        itemCount: state.searchedProducts.length,
                        itemBuilder: (context, index) {
                          final product = state.searchedProducts[index];
                          return SearchProductButton(
                            productLength: state.searchedProducts.length,
                            selected: index == state.selected ||
                                state.searchedProducts.length == 1,
                            title: product.name!.trim(),
                            barcodes: product.barcode,
                            sku: product.sku,
                            onPressed: () {
                              AppNavigation.pop(
                                  v: state.searchedProducts[index]);
                            },
                            price: product.shopPrices != null &&
                                    product.shopPrices!.shID != null &&
                                    product.shopPrices!.shID!.shopPriceTiers !=
                                        null &&
                                    product.shopPrices!.shID!.shopPriceTiers!
                                        .isNotEmpty
                                ? product.shopPrices!.shID!.shopPriceTiers![0]
                                        .retailPrice ??
                                    0
                                : 0,
                          );
                        },
                      );
                      // );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
