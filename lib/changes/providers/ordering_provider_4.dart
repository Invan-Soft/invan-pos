import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/changes/bloc/payme/payme_bloc.dart';
import 'package:invan2/changes/dialogs/client_search/client_search_dialog_with_bloc.dart';
import 'package:invan2/changes/dialogs/contains_no_mxik_package_item_dialog.dart';
import 'package:invan2/changes/dialogs/alcohol_warning_dialog.dart';
import 'package:invan2/changes/dialogs/contains_zero_price_item_dialog.dart';
import 'package:invan2/changes/dialogs/markirovka_dialog.dart';
import 'package:invan2/changes/dialogs/not_found_product_dialog.dart';
import 'package:invan2/changes/dialogs/payme_dialog.dart';
import 'package:invan2/changes/providers/ordering/discount_effects_controller.dart';
import 'package:invan2/changes/providers/ordering/catalog_navigation_controller.dart';
import 'package:invan2/changes/providers/ordering/payment_tally_controller.dart';
import 'package:invan2/changes/domain/barcode/barcode_classifier.dart';
import 'package:invan2/changes/domain/barcode/scanned_product_lookup.dart';
import 'package:invan2/changes/domain/barcode/tarozi_label.dart';
import 'package:invan2/changes/domain/barcode/utsenka_qr.dart';
import 'package:invan2/changes/domain/cart/cash_restriction_rules.dart';
import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
import 'package:invan2/changes/services/telegram_notifier.dart';
import 'package:invan2/changes/domain/cart/deleted_item_recorder.dart';
import 'package:invan2/changes/domain/cart/row_repricer.dart';
import 'package:invan2/changes/providers/ordering/cart_edit_controller.dart';
import 'package:invan2/changes/dialogs/terminal_error_dialog.dart';
import 'package:invan2/changes/domain/receipt/receipt_builder.dart';
import 'package:invan2/changes/domain/receipt/receipt_payments.dart';
import 'package:invan2/changes/domain/marking/mark_cleaner.dart';
import 'package:invan2/changes/domain/cart/box_row_builder.dart';
import 'package:invan2/changes/domain/cart/client_discount.dart';
import 'package:invan2/changes/domain/cart/invoice_row_builder.dart';
import 'package:invan2/changes/domain/cart/marked_row_builder.dart';
import 'package:invan2/changes/domain/cart/sold_item_builder.dart';
import 'package:invan2/changes/services/onkm_validator.dart';
import 'package:invan2/changes/domain/marking/mark_validator.dart';
import 'package:invan2/changes/domain/marking/marked_cart.dart';
import 'package:invan2/changes/domain/marking/mxik_rules.dart';
import 'package:invan2/changes/domain/terminal/terminal_receipt_parser.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/ofd/incom_response_model.dart';
import 'package:invan2/changes/models/ofd/payment_result_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/models/deleted_item_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/cashier_service_time/cashier_service_time_service.dart';
import 'package:invan2/changes/services/local_selling_service.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/features/home/bloc/invoice/invoice_bloc.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/operation_on_total_price_dialog.dart';
import 'package:invan2/features/payment/right/complete_button/uzum_pay_bloc/uzum_pay_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/click/bloc/click_bloc.dart';
import 'package:invan2/changes/services/payment/paynet_service.dart';
import 'package:invan2/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/paynet/paynet_dialog.dart';
import 'package:invan2/features/payment/right/dilogs/click/clic_pass_dialog.dart';
import 'package:invan2/features/payment/right/dilogs/uzum/uzum_dialog.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';
import 'package:windows1251/windows1251.dart';
import 'package:file/local.dart' as fl;
import '../../alice_service.dart';
import '../services/discount_service.dart';
import '../../features/home/features/operation_on_product/operation_on_product.dart';
import '../../features/payment/right/complete_button/complete_bloc/comlete_bloc.dart';
import '../../features/payment/right/complete_button/pre_complete_bloc/per_comlete_bloc.dart';
import '../bloc/supplier_search/supplier_search_bloc.dart';
import '../dialogs/add_description/add_description.dart';
import '../dialogs/client_search/client_search_with_inn_dialog.dart';
import '../dialogs/contains_discount_item_dialog.dart';
import '../dialogs/contains_discount_item_dialog_2.dart';
import '../dialogs/creat_product/creat_product_dialog.dart';
import '../dialogs/supplier_search/supplier_search_dialog.dart';
import '../models/organization_model.dart';
import '../models/supplier_model.dart';
import '../services/api/result_http_model.dart';
import '../singletons/discounts/discount_singleton.dart';

bool isTpEdited = true;

enum PaymentType {
  cash,
  card,
  card2,
  card3,
  click,
  humo,
  humo2,
  humo3,
  cashback,
  payme,
  debt,
  uzum,
  clickQr,
  paymeQr,
  uzumQr,
  other
}

enum DiscountFromWhere {
  single,
  client,
  total,
}

enum WherePath {
  homeScreen,
  paymentScreen,
}

class OrderingProvider4 extends ChangeNotifier {
  List<SixClientModel4> _sixClient4List = [];
  SixClientModel4 _currentClient = SixClientModel4(
    clientNumber: 1,
    lastAddedIndex: -1,
    orderedProducts: [],
    discountAmountFromNewClient: 0,
  );
  int _index = 0;
  final GlobalKey<MarkingDialogState> _markingDialogKey =
      GlobalKey<MarkingDialogState>();
  int _clientNumber = 1;
  int _tappedIndexToEdit = -1;
  late final CartEditController _cartEdit = CartEditController(
    rowsOf: () => _currentClient.orderedProducts,
    notify: notifyListeners,
    recordDeletedItem: _recordDeletedItem,
    reprice: _repriceProductRowsByTotalUnits,
    syncManualPrice: _syncManualPriceAcrossProductRows,
    refreshDiscountEffects: () {
      findFreeProducts();
      useFreeProducts();
      useFreeGiftProducts();
      useBuyXGetXProducts();
    },
    clearShowCounts: (pid) {
      _showCount.remove(pid);
      _showCountFreeGift.remove(pid);
    },
    resetClientDiscount: () {
      _currentClient.selectedClient = null;
      _newClientPersentageDiscount = 0;
    },
    flagOrphanDeletedItems: _flagOrphanDeletedItemsIfCartEmpty,
    isRedDeleteOn: () => Pref.getBool(PrefKeys.isRedDeleteActivated, false),
    currentEmployeeName: () =>
        HiveBoxes.getCurrentEmployee!.user?.firstName ?? "Noma'lum xodim",
    posNameOf: () => Pref.getString(PrefKeys.posName, "Noma'lum POS"),
    notifyDeleted: TelegramNotifier.productDeleted,
    setLastAddedIndex: (i) => _currentClient.lastAddedIndex = i,
  );

  String? get _markGroupEditProductId => _cartEdit.markGroupProductId;
  set _markGroupEditProductId(String? v) => _cartEdit.markGroupProductId = v;

  String? get _boxGroupEditProductId => _cartEdit.boxGroupProductId;
  set _boxGroupEditProductId(String? v) => _cartEdit.boxGroupProductId = v;

  Future<void> _saveMarkGroup(ReceiptModelSoldItem4 edited,
          {Employee? approvedBy}) =>
      _cartEdit.saveMarkGroup(edited, approvedBy: approvedBy);

  Future<void> _saveBoxGroup(ReceiptModelSoldItem4 edited,
          {Employee? approvedBy}) =>
      _cartEdit.saveBoxGroup(edited, approvedBy: approvedBy);

  void _deleteMarkGroup(String pid, {Employee? approvedBy}) =>
      _cartEdit.deleteMarkGroup(pid, approvedBy: approvedBy);

  void _deleteBoxGroup(String pid, {Employee? approvedBy}) =>
      _cartEdit.deleteBoxGroup(pid, approvedBy: approvedBy);
  String _lastRRN = '';
  String _lastCardNumber = '';
  int _lastCardType = 0;
  final int _amountActions = 0;
  double _newClientPersentageDiscount = 0;
  bool _alcoholWarningShown = false;
  bool _cashsaleWarningShown = false;
  bool _bigTotalWarningShown = false;

  final List<DeletedItemModel4> _orphanDeletedItems = [];

  OrderingProvider4() {
    DiscountService.onDiscountsCleared = clearAllDiscountEffects;
  }

  void clearAllDiscountEffects() {
    for (final client in _sixClient4List) {
      for (final item in client.orderedProducts) {
        _resetItemDiscount(item);
      }
    }
    for (final item in _currentClient.orderedProducts) {
      _resetItemDiscount(item);
    }
    _returnedProducts = {};
    _returnedFreeGiftProducts = [];
    _returnedBuyXGetX = [];
    _giftProducts = {};
    _freeGiftDialogCount = 0;
    _showCount = {};
    _showCountFreeGift = {};
    DiscountSingleton.resetAll();
    notifyListeners();
  }

  Employee get currentEmployee => HiveBoxes.getCurrentEmployee ?? Employee();

  int get getAmountOfActions => _amountActions;

  int get getSelectedIndex => _index;

  List<SixClientModel4> get getSixClient4List => _sixClient4List;

  List<DeletedItemModel4> get getOrphanDeletedItems => _orphanDeletedItems;

  int get getLastAddedIndex => _currentClient.lastAddedIndex;

  SixClientModel4 get getCurrentClient => _currentClient;

  double get getNewClientDiscountPercentage => _newClientPersentageDiscount;

  List<ReceiptModelSoldItem4> get getCurrentClientOrderedProducts =>
      _currentClient.orderedProducts;

  setNewClientDiscountPercentage(double percentage) {
    _newClientPersentageDiscount = percentage;
    final products = _currentClient.orderedProducts;
    ClientDiscount.applyPercentage(
      products,
      percentage,
      makeDiscount: (howMuch) => ItemsSingleton.discounter(
        howMuch: howMuch,
        quantity: 1,
        where: DiscountFromWhere.client,
      ),
    );
    _currentClient.orderedProducts = [];
    _currentClient.orderedProducts.addAll(products);
    notifyListeners();
  }

  bool cancelOrdering(bool access) {
    if (_currentClient.orderedProducts.isEmpty) return true;
    if (!access) {
      if (!(currentEmployee.access?.deleteS ?? false)) {
        _currentClient.orderedProducts = [];
        _currentClient.lastAddedIndex = -1;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    }
    _currentClient.orderedProducts = [];
    _currentClient.lastAddedIndex = -1;
    _returnedProducts.clear();
    _returnedFreeGiftProducts.clear();
    _giftProducts.clear();
    _freeGiftDialogCount = 0;
    _showCount = {};
    _showCountFreeGift = {};
    DiscountSingleton.maxPrice();

    notifyListeners();
    return true;
  }

  Future<void> cancelOrderingWithTelegram() async {
    if (_currentClient.orderedProducts.isEmpty) return;

    final employeeName =
        HiveBoxes.getCurrentEmployee?.user?.firstName ?? "Noma'lum xodim";
    final posName = Pref.getString(PrefKeys.posName, "Noma'lum POS");
    final deleteTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final products = _currentClient.orderedProducts
        .where((p) => !(p.isDeleted ?? false))
        .toList();

    _currentClient.orderedProducts = [];
    _currentClient.lastAddedIndex = -1;
    _returnedProducts.clear();
    _returnedFreeGiftProducts.clear();
    _giftProducts.clear();
    _freeGiftDialogCount = 0;
    _showCount = {};
    _showCountFreeGift = {};
    DiscountSingleton.maxPrice();
    notifyListeners();

    if (products.isEmpty) return;

    await TelegramNotifier.cartCancelled(
      posName: posName,
      employeeName: employeeName,
      deleteTime: deleteTime,
      productLines: [
        for (int i = 0; i < products.length; i++)
          '${i + 1}. ${products[i].productName} — qty: ${products[i].value}',
      ],
    );
  }

  Future<void> onMxikError(List<NoMxikItem> v) async {
    for (int i = 0; i < _currentClient.orderedProducts.length; i++) {
      for (int n = 0; n < v.length; n++) {
        if (_currentClient.orderedProducts[i].barcode == v[n].barode) {
          _currentClient.orderedProducts[i].mxikError = true;
          break;
        }
      }
    }
    notifyListeners();
    return;
  }

  void removeLastAdded() {
    LogHelper.activity('CART_REMOVE_LAST', {'index': getLastAddedIndex});
    _cartEdit.removeLastAdded(getLastAddedIndex);
  }

  void addProduct(
      {required double value,
      required ItemModel product,
      required String where,
      required BuildContext context,
      bool isTarozi = false}) async {
    try {
      CashierServiceTimeService.instance
          .onProductAdded(_currentClient.clientNumber);

      if (_currentClient.orderedProducts.isEmpty) {
        _returnedProducts.clear();
        _returnedFreeGiftProducts.clear();
        _giftProducts.clear();
        _freeGiftDialogCount = 0;
        _showCount = {};
        _showCountFreeGift = {};

        DiscountSingleton.maxPrice();
      }

      final isKg = _isKg(product);
      final price =
          ItemsSingleton.finalPrice(product, value.toInt(), isKg, isFirst: true)
              .toDouble();

      LogHelper.activity('CART_ADD', {
        'name': product.name,
        'barcode': product.barcode,
        'qty': value,
        'price': price,
        'where': where,
        'isTarozi': isTarozi,
      });

      final bool markCheckEnabled =
          Pref.getBool(PrefKeys.markCheckWithOfd, false);
      final bool sellWithMarkingEnabled =
          Pref.getBool(PrefKeys.sellProductsWithMarking, true);
      // `is_marking == false` bo'lsa MXIK ro'yxatda bo'lsa ham markirovka
      // dialogi chiqmaydi — oddiy mahsulot (qoida: MxikRules).
      final bool isMarkingByMxik = markCheckEnabled &&
          sellWithMarkingEnabled &&
          MxikRules.isMxikAutoDetectCandidate(product);

      final isMarking =
          markCheckEnabled && (product.isMarking == true || isMarkingByMxik);

      if (isMarking && price > 0) {
        await _handleMarkingProduct(context, product, price);
        return;
      } else {
        await _handleRegularProduct(context, product, value, price, isKg);
      }

      if (!_applyExistingManualPrice(product.id)) {
        _repriceProductRowsByTotalUnits(product.id);
      }

      DiscountSingleton.productId(product.id ?? '');

      findFreeProducts();

      _currentClient.lastAddedIndex = 0;
      isTpEdited = false;
      notifyListeners();

      final addedMxik = (product.mxikCode ?? '').trim();
      if (Pref.getBool(PrefKeys.markCheckWithOfd, true) &&
          _isAlcoholMxik(addedMxik) &&
          !_alcoholWarningShown) {
        _alcoholWarningShown = true;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const CashPaymentWarningDialog(),
        );
      }
      if (!_cashsaleWarningShown && isCashHiddenByCashsale) {
        _cashsaleWarningShown = true;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const CashPaymentWarningDialog(),
        );
      }
      if (!_bigTotalWarningShown && isBigTotalHidden) {
        _bigTotalWarningShown = true;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const CashPaymentWarningDialog(),
        );
      }

      await _showPostAddDiscountDialogs(context, product);

      if (_currentClient.orderedProducts.isNotEmpty &&
          _currentClient.orderedProducts[0].isKg &&
          !isTarozi) {
        _tappedIndexToEdit = 0;
        await OperationOnProduct.operationOnProductDialog(
          context: context,
          item: _currentClient.orderedProducts[0],
          isClientMinimumPrice: false,
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in addProduct: $e\n$stackTrace');
      }
    }
  }

  bool get isCardOnlyPaymentRequired =>
      CashRestrictionRules.cardOnlyRequired(_currentClient.orderedProducts);

  bool get isCashPaymentHidden => CashRestrictionRules.cashHiddenByMarking(
        _currentClient.orderedProducts,
        ofdOn: Pref.getBool(PrefKeys.markCheckWithOfd, false),
        markingSaleOn: Pref.getBool(PrefKeys.sellProductsWithMarking, true),
      );

  bool get isCashHiddenByCashsale => CashRestrictionRules.cashHiddenByCashsale(
        _currentClient.orderedProducts,
        ofdOn: Pref.getBool(PrefKeys.markCheckWithOfd, true),
        cashsaleCheckOn: Pref.getBool('checkProductByCashsale', true),
      );

  bool get isBigTotalHidden => CashRestrictionRules.bigTotalHidden(
        _currentClient.orderedProducts,
        ofdOn: Pref.getBool(PrefKeys.markCheckWithOfd, true),
        cashsaleCheckOn: Pref.getBool('checkProductByCashsale', true),
        limit: BhmService.cashLimit,
      );

  void resetCashRestrictionWarnings() {
    _alcoholWarningShown = false;
    _cashsaleWarningShown = false;
    _bigTotalWarningShown = false;
    notifyListeners();
  }

  Future<void> loadInvoiceByBarcodeWithBloc({
    required String barcode,
    required BuildContext context,
  }) async {
    final bloc = context.read<InvoiceBloc>();
    bloc.add(GetInvoiceProductsEvent(invoiceId: barcode));

    try {
      await for (final state in bloc.stream) {
        if (state is GetInvoiceProductsLoading) {
          continue;
        }

        if (state is GetInvoiceProductsLoaded) {
          final invoice = state.invoice;

          cancelOrdering(true);
          if (invoice.client.firstName.isNotEmpty ||
              invoice.client.lastName.isNotEmpty) {
            _currentClient.selectedClient = ClientModel(
              id: invoice.client.id,
              firstName: invoice.client.firstName,
              lastName: invoice.client.lastName,
              phoneNumber: "",
              discountValue: 0,
            );
          }
          
          Pref.setString(
              'invoice_id_for_order', "Invoice Id: ${invoice.externalId}");
          bool hasMissingProduct = false;

          for (var item in invoice.items) {
            final product = ItemsSingleton.getProductById(item.productId);
            if (product == null) {
              hasMissingProduct = true;
              continue;
            }

            final soldItem = InvoiceRowBuilder.build(item, product);
            _currentClient.orderedProducts.insert(0, soldItem);
          }

          if (hasMissingProduct && context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("POS yangilanishi kerak"),
                content: const Text(
                    "Ba'zi mahsulotlar sizning qurilmangizga yuklanmagan.\nPOS versiyasini yangilashingiz kerak."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Ok"))
                ],
              ),
            );
          }

          _currentClient.lastAddedIndex = -1;
          notifyListeners();
          break;
        }

        if (state is GetInvoiceProductsField) {
          break;
        }
      }
    } catch (e) {
      print("CATCH ERROR: $e");
    }
  }

  bool _isKg(ItemModel product) => RowRepricer.isKg(product);

  Future<void> _handleMarkingProduct(
      BuildContext context, ItemModel product, double price) async {
    final isPriceZero = price <= 0;

    final isMxikInvalid =
        product.mxikCode == null || product.mxikCode!.trim().isEmpty;
    final isPackageInvalid =
        product.packageCode == null || product.packageCode!.trim().isEmpty;
    final isMxikOrPackageInvalid = isMxikInvalid || isPackageInvalid;

    if (isPriceZero) {
      await _showZeroPriceDialog(context);
      return;
    }

    if (isMxikOrPackageInvalid) {
      _currentClient.orderedProducts.removeAt(_currentClient.lastAddedIndex);
      await _showMxikPackageDialog(context);
      return;
    }

    await marking(context, product);
  }

  ReceiptModelSoldItem4? _parseUtsenkaQr(String barcode) {
    final offer = UtsenkaQr.parse(barcode);
    if (offer == null) return null;

    final item = _createSoldItem(offer.product, offer.price, 1, false);
    item.realPrice = offer.originalPrice;
    item.onlyPrice = offer.originalPrice;
    item.singleDiscount = offer.discount;
    item.discountPercent = offer.percent;
    item.isPriceChanged = true;
    item.isPriceOnlyChanged = true;
    return item;
  }

  Future<void> _handleRegularProduct(BuildContext context, ItemModel product,
      double value, double price, bool isKg) async {
    final existingIndex = _currentClient.orderedProducts.indexWhere((e) =>
        e.productId == product.id &&
        e.saleType != 2 &&
        (!e.isPriceOnlyChanged || e.singleDiscount == 0));

    if (existingIndex != -1) {
      await _updateExistingProduct(context, product, value, existingIndex);
    } else {
      await _addNewProduct(context, product, value, price, isKg);
    }
  }

  Future<void> _updateExistingProduct(
      BuildContext context, ItemModel product, double value, int index) async {
    ReceiptModelSoldItem4 soldItem =
        _currentClient.orderedProducts.removeAt(index);

    final newValue = double.parse((soldItem.value + value).toStringAsFixed(2));

    int priceValue = newValue.toInt();
    if (soldItem.singleDiscount > 0) {
      priceValue = 1;
    }

    double newPrice;

    if (soldItem.isPriceOnlyChanged) {
      newPrice = soldItem.onlyPrice;
    } else {
      newPrice = ItemsSingleton.finalPrice(product, priceValue, soldItem.isKg)
          .toDouble();
    }
    soldItem.value = newValue;

    if (!soldItem.isPriceOnlyChanged) {
      soldItem.price = newPrice;
      soldItem.onlyPrice = newPrice;
      soldItem.realPrice = newPrice;
    }

    _applyDiscounts(product, soldItem);

    if (await _checkAndShowDialogsIfNeeded(context, soldItem)) return;

    _currentClient.orderedProducts.insert(0, soldItem);
  }

  Future<void> _addNewProduct(BuildContext context, ItemModel product,
      double value, double price, bool isKg) async {
    double val = double.parse(
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(3));

    ReceiptModelSoldItem4 soldItem = _createSoldItem(product, price, val, isKg);

    _applyDiscounts(product, soldItem);

    if (await _checkAndShowDialogsIfNeeded(context, soldItem)) return;

    _currentClient.orderedProducts.insert(0, soldItem);
  }

  void _applyDiscounts(ItemModel product, ReceiptModelSoldItem4 soldItem) {
    if (soldItem.isPriceOnlyChanged) return;

    final categoryId = product.categories?.isNotEmpty == true
        ? product.categories![0].id ?? ''
        : '';
    soldItem = DiscountSingleton.addDiscountOnProduct(
        soldItem, categoryId, getClientGroupId);

    if (_newClientPersentageDiscount > 0 &&
        _newClientPersentageDiscount <= 100) {
      final newPrice =
          soldItem.price * (1 - _newClientPersentageDiscount / 100);
      soldItem.price = newPrice;
      soldItem.discountPercent = 100 - (newPrice * 100 / soldItem.onlyPrice);
    }
  }

  Future<bool> _checkAndShowDialogsIfNeeded(
      BuildContext context, ReceiptModelSoldItem4 soldItem) async {
    final isPriceZero = soldItem.price <= 0;
    final bool markCheckEnabled =
        Pref.getBool(PrefKeys.markCheckWithOfd, false);
    final isMxikOrPackageInvalid = markCheckEnabled &&
        (soldItem.mxik.isEmpty || soldItem.packageCode?.isEmpty != false);

    if (soldItem.value <= 0) {
      final loc = AppLocalizations.of(context)!;
      await showGeneralDialog(
        barrierDismissible: false,
        context: context,
        pageBuilder: (_, __, ___) => ContainsZeroPriceItemDialog(
          provider: this,
          text: loc.ha == 'Ha'
              ? '0 kg mahsulotni sotish mumkin emas.'
              : '0 кг продукта не может быть продано.',
        ),
      );
      return true;
    }

    if (isPriceZero) {
      await _showZeroPriceDialog(context);
      return true;
    }

    if (isMxikOrPackageInvalid) {
      await _showMxikPackageDialog(context);
      return true;
    }

    return false;
  }

  Future<void> _showZeroPriceDialog(BuildContext context) async {
    await showGeneralDialog(
      barrierDismissible: false,
      context: context,
      pageBuilder: (_, __, ___) => ContainsZeroPriceItemDialog(
        provider: this,
        delete: false,
      ),
    );
  }

  Future<void> _showMxikPackageDialog(BuildContext context) async {
    await showGeneralDialog(
      barrierDismissible: false,
      context: context,
      pageBuilder: (_, __, ___) =>
          ContainsNoMxikPackageItemDialogg(provider: this),
    );
  }

  ReceiptModelSoldItem4 _createSoldItem(
          ItemModel product, double price, double value, bool isKg) =>
      SoldItemBuilder.build(product, price, value, isKg);

  late final DiscountEffectsController _discountFx =
      DiscountEffectsController(notifyListeners);

  Map<String, int> get _showCount => _discountFx.showCount;
  set _showCount(Map<String, int> v) => _discountFx.showCount = v;

  Map<String, int> get _showCountFreeGift => _discountFx.showCountFreeGift;
  set _showCountFreeGift(Map<String, int> v) =>
      _discountFx.showCountFreeGift = v;

  Map<String, ReturnedProduct> get _returnedProducts =>
      _discountFx.returnedProducts;
  set _returnedProducts(Map<String, ReturnedProduct> v) =>
      _discountFx.returnedProducts = v;

  List<ReturnedGift> get _returnedFreeGiftProducts =>
      _discountFx.returnedFreeGiftProducts;
  set _returnedFreeGiftProducts(List<ReturnedGift> v) =>
      _discountFx.returnedFreeGiftProducts = v;

  List<ReturnedGiftX> get _returnedBuyXGetX => _discountFx.returnedBuyXGetX;
  set _returnedBuyXGetX(List<ReturnedGiftX> v) =>
      _discountFx.returnedBuyXGetX = v;

  Map<String, String> get _giftProducts => _discountFx.giftProducts;
  set _giftProducts(Map<String, String> v) => _discountFx.giftProducts = v;

  set _freeGiftDialogCount(int v) => _discountFx.freeGiftDialogCount = v;

  void findFreeProducts() => _discountFx.findFreeProducts(
      _currentClient.orderedProducts, getClientGroupId);

  void useFreeProducts() =>
      _discountFx.useFreeProducts(_currentClient.orderedProducts);

  void useFreeGiftProducts() =>
      _discountFx.useFreeGiftProducts(_currentClient.orderedProducts);

  void useBuyXGetXProducts() =>
      _discountFx.useBuyXGetXProducts(_currentClient.orderedProducts);

  void _resetItemDiscount(ReceiptModelSoldItem4 item) =>
      _discountFx.resetItemDiscount(item);

  num _totalPriceForAllProduct() => DiscountEffectsController.totalPriceForAll(
      _currentClient.orderedProducts);

  bool isMarkingDialogDisplaying = false;
  bool isMarkingChecking = false;

  marking(BuildContext context, ItemModel item) async {
    bool isKg = false;
    if (item.measurementUnit != null &&
        item.measurementUnit!.shortName != null &&
        (item.measurementUnit!.shortName! == 'кг' ||
            item.measurementUnit!.shortName! == 'kg')) {
      isKg = true;
    }

    double price = ItemsSingleton.finalPrice(item, 1, isKg).toDouble();

    if (item.mark == null || item.mark!.isEmpty) {
      if (!isMarkingDialogDisplaying) {
        isMarkingDialogDisplaying = true;
        await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return MarkingDialog(
                key: _markingDialogKey,
                price: price.toString(),
                name: item.name.toString(),
                onSubmitted: (v) async {
                  if (v.isNotEmpty && v.length > 15) {
                    AppNavigation.pop();
                    AppNavigation.pop();
                    isMarkingDialogDisplaying = false;
                    isMarkingDialogDisplaying = false;

                    if (v.isNotEmpty && v.length > 15) {
                      v = _markirovka(v);
                      await _markingCheck(item, v, context);
                    } else {
                      return;
                    }
                  }
                },
                onAddButtonPressed: (v) async {
                  if (v.isNotEmpty && v.length > 15) {
                    isMarkingDialogDisplaying = false;
                    v = _markirovka(v);

                    AppNavigation.pop();

                    await _markingCheck(item, v, context);
                  }
                },
                onCancelButtonPressed: () {
                  isMarkingDialogDisplaying = false;
                  AppNavigation.pop();
                  AppNavigation.pop();
                },
              );
            });
        isMarkingDialogDisplaying = false;
        isMarkingDialogDisplaying = false;
        notifyListeners();
      } else {
        return;
      }
    } else {
      await _markingCheck(item, item.mark ?? '', context);
    }
  }

  String _markirovka(String rawMark) => MarkCleaner.scanTime(rawMark);

  bool isLoading = false;

  bool dialogForMark = false;

  Future<void> _showMarkDialog(String message) async {
    if (dialogForMark) return;
    dialogForMark = true;
    await showGeneralDialog(
      barrierDismissible: false,
      context: AppNavigation.navigatorKey.currentContext!,
      pageBuilder: (f, d, context) => ContainsZeroPriceItemDialog(
        text: message,
        text2: 'Ok',
        delete: false,
        isFirst: true,
        provider: this,
      ),
    ).then((value) {});
    dialogForMark = false;
  }

  void setDialogForMark(bool value) {
    dialogForMark = value;
    notifyListeners();
  }

  bool dialogForDiscount = false;

  Future<void> _showPostAddDiscountDialogs(
      BuildContext context, ItemModel product) async {
    final loc =
        AppLocalizations.of(AppNavigation.navigatorKey.currentContext!)!;
    final pid = product.id ?? '';

    bool isShowOld = false;
    if (DiscountSingleton.availableDiscount.availableProducts != null) {
      for (final p in DiscountSingleton.availableDiscount.availableProducts!) {
        if (p.id == product.id) {
          if ((_showCount[pid] ?? 0) < 1) isShowOld = true;
          _showCount[pid] = 1;
        }
      }
    }
    if (isShowOld && !dialogForDiscount) {
      setDialogForDiscount(true);
      await showGeneralDialog(
        barrierDismissible: false,
        context: context,
        pageBuilder: (_, __, ___) => ContainsDiscountItemDialog(
          provider: this,
          returnedProduct: DiscountSingleton.availableDiscount,
          isFirst: true,
        ),
      );
    }

    bool isShowBuyXGetX = false;
    String buyXGetXText = '';
    final buyXGetXItem = _returnedBuyXGetX.firstWhereOrNull(
      (g) => g.getProduct?.id == product.id,
    );
    if (buyXGetXItem != null && (_showCountFreeGift[pid] ?? 0) < 1) {
      isShowBuyXGetX = true;
      final productName =
          buyXGetXItem.getProduct?.name ?? product.name ?? 'mahsulot';
      final buyAmount = buyXGetXItem.buyAmount;
      final freeAmount = buyXGetXItem.getProductAmount;
      buyXGetXText = loc.ha.toLowerCase() == 'ha'
          ? '$productName dan $buyAmount ta sotib olgani uchun,\n$freeAmount ta tekin berish kerak!'
          : 'За каждые $buyAmount $productName  $freeAmount бесплатно';
      _showCountFreeGift[pid] = 1;
    }
    if (isShowBuyXGetX && !dialogForDiscount) {
      setDialogForDiscount(true);
      await showGeneralDialog(
        barrierDismissible: false,
        context: AppNavigation.navigatorKey.currentContext!,
        pageBuilder: (_, __, ___) => ContainsDiscountItemDialog2(
          provider: this,
          text: buyXGetXText,
          isFirst: true,
        ),
      );
    }

    await freeGiftDialog();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();
  }

  void setDialogForDiscount(bool value) {
    dialogForDiscount = value;
    notifyListeners();
  }

  Future<void> _markingCheck(
      ItemModel item, String v, BuildContext context) async {
    if (dialogForMark) return;

    final AppLocalizations loc = AppLocalizations.of(context)!;
    final bool isUz = loc.ha.toLowerCase() == 'ha';

    final check = MarkValidator.validate(v, item);
    v = check.mark;
    item.mark = v;

    switch (check.issue) {
      case MarkIssue.invalidFormat:
        await _showMarkDialog(isUz
            ? 'Noto\'g\'ri markirovka kodi! Faqat GS1 DataMatrix formatidagi kod qabul qilinadi.'
            : 'Неверный код маркировки! Принимаются только коды в формате GS1 DataMatrix.');
        return;
      case MarkIssue.wrongProduct:
        await _showMarkDialog(isUz
            ? 'Noto\'g\'ri markirovka! Bu markirovka boshqa mahsulotga tegishli.'
            : 'Неверная маркировка! Эта маркировка принадлежит другому товару.');
        return;
      case MarkIssue.expired:
        await _showMarkDialog(isUz
            ? 'Bu mahsulotning muddati tugagan!'
            : 'Срок годности этого товара ист\u04ddк!');
        return;
      case MarkIssue.none:
        break;
    }

    if (!dialogForMark) {
      if (!Pref.getBool('validation_onkm', true)) {
        final action = MarkedCart.decideWithoutOnkm(
            _currentClient.orderedProducts, item.id, v);

        if (action == MarkAction.warnDuplicate) {
          await _showMarkDialog(loc.ha.toLowerCase() == 'ha'
              ? 'Bu markirovkali mahsulot oldin qo\'shilgan!'
              : 'Этот отмеченный продукт уже был добавлен ранее!');
        } else if (action == MarkAction.attachToExistingRow) {
          _currentClient
              .orderedProducts[MarkedCart.indexOfWithoutMark(
                  _currentClient.orderedProducts, item.id)]
              .mark = v;
          notifyListeners();
        } else {
          addSeperatedProduct(item..mark = v);
        }
        return;
      }

      bool hasInternet = await InternetConnectionChecker().hasConnection;

      if (hasInternet) {
        if (Pref.getBool(PrefKeys.markCheckWithOfd, false)) {
          try {
            isLoading = true;
            notifyListeners();

            final http.Response response = await OnkmValidator.validate(
              item: item,
              km: v,
              ownerTin: Pref.getString(PrefKeys.organizationINN, ''),
              onResponse: alice.onHttpResponse,
            );

            HttpResult httpResult = OnkmValidator.toResult(response);

            if (response.statusCode == 500) {
              if (MarkedCart.hasMark(
                  _currentClient.orderedProducts, item.id, v)) {
                await _showMarkDialog(loc.ha.toLowerCase() == 'ha'
                    ? 'Bu markirovkali mahsulot oldin qo\'shilgan!'
                    : 'Этот отмеченный продукт уже был добавлен ранее!');
              } else {
                addSeperatedProduct(item..mark = v);
              }
            }
            isLoading = false;
            notifyListeners();

            if (httpResult.isSuccess) {
              if (httpResult.result['success']) {
                if (MarkedCart.hasMark(
                    _currentClient.orderedProducts, item.id, v)) {
                  await _showMarkDialog(loc.ha.toLowerCase() == 'ha'
                      ? 'Bu markirovkali mahsulot oldin qo\'shilgan!'
                      : 'Этот отмеченный продукт уже был добавlen ранее!');
                } else {
                  addSeperatedProduct(item..mark = v);
                }
              } else {
                await _showMarkDialog(loc.ha.toLowerCase() == 'ha'
                    ? httpResult.result['messageLat']
                    : httpResult.result['messageRu']);
              }
            }
          } catch (e) {
            isLoading = false;
            notifyListeners();
            if (!dialogForMark) {
              dialogForMark = true;
              await showGeneralDialog(
                  barrierDismissible: false,
                  context: AppNavigation.navigatorKey.currentContext!,
                  pageBuilder: (f, d, context) {
                    return ContainsZeroPriceItemDialog(
                      text: NetworkErrorHelper.friendlyMessage(e,
                          isUz: loc.ha.toLowerCase() == 'ha'),
                      text2: 'Ok',
                      provider: this,
                      delete: false,
                      isFirst: true,
                    );
                  }).then((value) {});
            }
          }
        } else {
          if (!MarkedCart.hasMark(_currentClient.orderedProducts, item.id, v)) {
            addSeperatedProduct(item..mark = v);
          } else {
            if (!dialogForMark) {
              setDialogForMark(true);
              dialogForMark = true;
              await showGeneralDialog(
                  barrierDismissible: false,
                  context: AppNavigation.navigatorKey.currentContext!,
                  pageBuilder: (f, d, context) {
                    return ContainsZeroPriceItemDialog(
                      text: loc.ha.toLowerCase() == 'ha'
                          ? 'Bu markirovkali mahsulot oldin qo\'shilgan!'
                          : 'Этот отмеченный продукт уже был  добавлен ранее!',
                      text2: 'Ok',
                      delete: false,
                      provider: this,
                      isFirst: true,
                    );
                  }).then((value) {});
            }
          }
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!dialogForMark) {
          dialogForMark = true;
          await showGeneralDialog(
              barrierDismissible: false,
              context: AppNavigation.navigatorKey.currentContext!,
              pageBuilder: (f, d, context) {
                return ContainsZeroPriceItemDialog(
                  text: loc.ha.toLowerCase() == 'ha'
                      ? "Hurmatli tadbirkor!\nSizning kassangiz hozirda oflayn-rejimda ishlamoqda."
                          "\nSizdan tovarlarni sotish jarayonida raqamli markirovka qoidalariga qat'iy rioya etishingizni so'raymiz."
                          "\nBelgilangan talablarga amal qilmaslik amaldagi normativ-huquqiy hujjatlarga muvofiq javobgarlikka sabab bo'lishi mumkin."
                          "\nSiz internet tarmog'iga ulanmasdan operatsiyani amalga oshirishingizni tasdiqlaysizmi?"
                      : "Уважаемый предприниматель!\nВаша касса в настоящее время работает в автономном режиме."
                          "\nПросим вас строго соблюдать правила цифровой маркировки при продаже товаров."
                          "\nНесоблюдение указанных требований может повлечь за собой ответственность в соответствии с действующими нормативными правовыми актами."
                          "\nПодтверждаете ли вы, что будете осуществлять операции без подключения к сети Интернет?",
                  text2: loc.ha.toLowerCase() == 'ha'
                      ? 'Tasdiqlayman'
                      : 'Подтверждаю',
                  provider: this,
                  delete: false,
                  size: true,
                  isFirst: true,
                );
              }).then((value) {});
        }
        if (!MarkedCart.hasMark(_currentClient.orderedProducts, item.id, v)) {
          addSeperatedProduct(item..mark = v);
        } else {
          if (!dialogForMark) {
            dialogForMark = true;
            await showGeneralDialog(
                barrierDismissible: false,
                context: AppNavigation.navigatorKey.currentContext!,
                pageBuilder: (f, d, context) {
                  return ContainsZeroPriceItemDialog(
                    text: loc.ha.toLowerCase() == 'ha'
                        ? 'Bu markirovkali mahsulot oldin qo\'shilgan!'
                        : 'Этот отмеченный продукт уже был добавlen ранее!',
                    text2: 'Ok',
                    delete: false,
                    provider: this,
                    isFirst: true,
                  );
                }).then((value) {});
          }
        }
      }
    }
  }

  addSeperatedProduct(ItemModel product) async {
    final freshProduct =
        ItemsSingleton.getProductById(product.id ?? '') ?? product;

    bool isKg = freshProduct.measurementUnit?.shortName == 'кг' ||
        freshProduct.measurementUnit?.shortName == 'kg';
    final markValue = product.mark;

    if (markValue != null && markValue.isNotEmpty) {
      final alreadyAdded = _currentClient.orderedProducts.any(
        (e) => !(e.isDeleted ?? false) && e.mark != null && e.mark == markValue,
      );
      if (alreadyAdded) {
        if (!dialogForMark) {
          dialogForMark = true;
          final loc =
              AppLocalizations.of(AppNavigation.navigatorKey.currentContext!)!;
          await showGeneralDialog(
            barrierDismissible: false,
            context: AppNavigation.navigatorKey.currentContext!,
            pageBuilder: (f, d, ctx) => ContainsZeroPriceItemDialog(
              text: loc.ha.toLowerCase() == 'ha'
                  ? 'Bu markirovkali mahsulot oldin qo\'shilgan!'
                  : 'Этот отмеченный продукт уже был добавлен ранее!',
              text2: 'Ok',
              delete: false,
              isFirst: true,
              provider: this,
            ),
          ).then((value) {});
          dialogForMark = false;
        }
        return;
      }
    }

    final existingCount = _currentClient.orderedProducts
        .where((e) =>
            e.productId == freshProduct.id &&
            !(e.isDeleted ?? false) &&
            e.saleType != 2)
        .length;
    final totalCount = existingCount + 1;

    double price =
        ItemsSingleton.finalPrice(freshProduct, totalCount, isKg).toDouble();

    if (price <= 0) {
      price = ItemsSingleton.finalPrice(freshProduct, 1, isKg).toDouble();
    }

    final soldItem = MarkedRowBuilder.build(
      freshProduct,
      price,
      markValue: markValue,
      sellerId: Pref.getString(PrefKeys.cashierId, ""),
    );

    _currentClient.orderedProducts.insert(0, soldItem);

    if (!_applyExistingManualPrice(freshProduct.id)) {
      _repriceProductRowsByTotalUnits(freshProduct.id);
    }

    DiscountSingleton.productId(freshProduct.id ?? '');
    findFreeProducts();

    _currentClient.lastAddedIndex = 0;
    isTpEdited = false;
    notifyListeners();

    await _showPostAddDiscountDialogs(
        AppNavigation.navigatorKey.currentContext!, freshProduct);
    notifyListeners();
  }

  void _repriceProductRowsByTotalUnits(String? productId) =>
      RowRepricer.byTotalUnits(_currentClient.orderedProducts, productId,
          applyDiscounts: _applyDiscounts);

  void _syncManualPriceAcrossProductRows(ReceiptModelSoldItem4 edited) =>
      RowRepricer.syncManualPrice(_currentClient.orderedProducts, edited);

  bool _applyExistingManualPrice(String? productId) =>
      RowRepricer.applyExistingManualPrice(
          _currentClient.orderedProducts, productId);

  Future<void> _addBoxProduct(ItemModel product, String rawMark) async {
    final freshProduct =
        ItemsSingleton.getProductById(product.id ?? '') ?? product;

    final alreadyAdded = _currentClient.orderedProducts.any(
      (e) => !(e.isDeleted ?? false) && e.saleType == 2 && e.mark == rawMark,
    );
    if (alreadyAdded) {
      final loc =
          AppLocalizations.of(AppNavigation.navigatorKey.currentContext!)!;
      await _showMarkDialog(loc.ha.toLowerCase() == 'ha'
          ? 'Bu box allaqachon qo\'shilgan!'
          : 'Этот бокс уже добавлен!');
      return;
    }

    final isKg = _isKg(freshProduct);
    print(
        'Box Product ${freshProduct.name} ${freshProduct.boxBarcodeQuantity}${freshProduct.hasBoxBarcode}');
    final rawBoxValue = freshProduct.boxBarcodeQuantity;
    final boxValue =
        (rawBoxValue == null || rawBoxValue == 0) ? 1 : rawBoxValue.toInt();
    final unitPrice =
        ItemsSingleton.finalPrice(freshProduct, boxValue, isKg).toDouble();
    final boxPrice = unitPrice * boxValue;

    final existingBoxCount = _currentClient.orderedProducts
        .where((e) =>
            e.productId == (freshProduct.id ?? '') &&
            !(e.isDeleted ?? false) &&
            e.saleType == 2)
        .length;
    final newBoxQuantity = existingBoxCount + 1;

    final soldItem = BoxRowBuilder.build(
      freshProduct,
      boxPrice: boxPrice,
      boxValue: boxValue,
      boxQuantity: newBoxQuantity,
      rawMark: rawMark,
      sellerId: Pref.getString(PrefKeys.cashierId, ''),
    );

    _currentClient.orderedProducts.insert(0, soldItem);

    for (final item in _currentClient.orderedProducts) {
      if (item.productId == (freshProduct.id ?? '') &&
          !(item.isDeleted ?? false) &&
          item.saleType == 2) {
        item.boxQuantity = newBoxQuantity;
      }
    }

    if (!_applyExistingManualPrice(freshProduct.id)) {
      _repriceProductRowsByTotalUnits(freshProduct.id);
    }

    _currentClient.lastAddedIndex = 0;
    isTpEdited = false;

    DiscountSingleton.productId(freshProduct.id ?? '');
    findFreeProducts();
    await freeGiftDialog();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();

    notifyListeners();
  }

  void tapIndexToEdit(int i) {
    _tappedIndexToEdit = i;
  }

  void beginMarkGroupEdit(String productId) {
    _markGroupEditProductId = productId;
  }

  void endMarkGroupEdit() {
    _markGroupEditProductId = null;
  }

  void beginBoxGroupEdit(String productId) {
    _boxGroupEditProductId = productId;
  }

  void endBoxGroupEdit() {
    _boxGroupEditProductId = null;
  }

  Future<void> pressDialogSaveButton(ReceiptModelSoldItem4 item,
      {Employee? approvedBy}) async {
    if (_boxGroupEditProductId != null) {
      await _saveBoxGroup(item, approvedBy: approvedBy);
      return;
    }
    if (_markGroupEditProductId != null) {
      await _saveMarkGroup(item, approvedBy: approvedBy);
      return;
    }
    if (item.value > 0) {
      final oldItem = _currentClient.orderedProducts[_tappedIndexToEdit];
      if (item.value < oldItem.value) {
        _recordDeletedItem(oldItem,
            quantity: oldItem.value - item.value, approvedBy: approvedBy);
      }
      _currentClient.orderedProducts[_tappedIndexToEdit] = item;

      if (item.isPriceOnlyChanged && item.price != oldItem.price) {
        _syncManualPriceAcrossProductRows(item);
      }

      _repriceProductRowsByTotalUnits(item.productId);
    } else {
      pressDialogDeleteButton(approvedBy: approvedBy);
    }

    findFreeProducts();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();

    notifyListeners();

    if (!_cashsaleWarningShown && isCashHiddenByCashsale) {
      final ctx = AppNavigation.navigatorKey.currentContext;
      if (ctx != null) {
        _cashsaleWarningShown = true;
        await showDialog(
          context: ctx,
          barrierDismissible: false,
          builder: (_) => const CashPaymentWarningDialog(),
        );
      }
    }
    if (!_bigTotalWarningShown && isBigTotalHidden) {
      final ctx = AppNavigation.navigatorKey.currentContext;
      if (ctx != null) {
        _bigTotalWarningShown = true;
        await showDialog(
          context: ctx,
          barrierDismissible: false,
          builder: (_) => const CashPaymentWarningDialog(),
        );
      }
    }
  }

  void _recordDeletedItem(ReceiptModelSoldItem4 item,
          {double? quantity, Employee? approvedBy}) =>
      DeletedItemRecorder.record(
        _currentClient.deletedItems,
        item,
        quantity: quantity,
        approvedBy: approvedBy,
        currentEmployeeId: () =>
            HiveBoxes.getCurrentEmployee?.user?.id ??
            Pref.getString(PrefKeys.cashierId, ""),
      );

  void _flagOrphanDeletedItemsIfCartEmpty() =>
      DeletedItemRecorder.flagOrphansIfCartEmpty(
          _currentClient.orderedProducts, _currentClient.deletedItems);

  void pressDialogDeleteButton({Employee? approvedBy}) async {
    LogHelper.activity('CART_DELETE_ITEM', {'editIndex': _tappedIndexToEdit});
    if (_boxGroupEditProductId != null) {
      _deleteBoxGroup(_boxGroupEditProductId!, approvedBy: approvedBy);
      return;
    }
    if (_markGroupEditProductId != null) {
      _deleteMarkGroup(_markGroupEditProductId!, approvedBy: approvedBy);
      return;
    }

    await _cartEdit.deleteRow(_tappedIndexToEdit, approvedBy: approvedBy);
  }

  Future<void> freeGiftDialog() async {
    if (_returnedFreeGiftProducts.isEmpty) return;

    final loc =
        AppLocalizations.of(AppNavigation.navigatorKey.currentContext!)!;

    for (ReturnedGift gift in _returnedFreeGiftProducts) {
      final productId = gift.getProduct?.id;

      if (productId == null) continue;

      final currentCount = _showCount[productId] ?? 0;

      if (currentCount >= 1) continue;

      if (_totalPriceForAllProduct() > gift.buyAmount) {
        String buyAmount = MoneyFormatter.formatter.format(gift.buyAmount);

        if (!dialogForDiscount) {
          setDialogForDiscount(true);
          if (gift.isGetX == true ?? false) {
            await showGeneralDialog(
              barrierDismissible: false,
              context: AppNavigation.navigatorKey.currentContext!,
              pageBuilder: (_, __, ___) => ContainsDiscountItemDialog2(
                provider: this,
                text: loc.ha.toLowerCase() == 'ha'
                    ? '${gift.getProduct?.name ?? ''} $buyAmount dan oshgani uchun.\n\n${gift.getProduct?.name ?? ''} mahsulotdan yana  ${gift.getProductAmount} ta berishingiz kerak!!!'
                    : 'За превышение суммы $buyAmount.\n\nОбязательно ${gift.getProductAmount} товара категории ${gift.getProduct?.name ?? ''}!!!',
                isFirst: true,
              ),
            );
          } else {
            await showGeneralDialog(
              barrierDismissible: false,
              context: AppNavigation.navigatorKey.currentContext!,
              pageBuilder: (_, __, ___) => ContainsDiscountItemDialog2(
                provider: this,
                text: loc.ha.toLowerCase() == 'ha'
                    ? '$buyAmount dan oshgani uchun.\n\n${gift.getProduct?.name ?? ''} mahsulotdan ${gift.getProductAmount} ta berishingiz kerak!!!'
                    : 'За превышение суммы $buyAmount.\n\nОбязательно ${gift.getProductAmount} товара категории ${gift.getProduct?.name ?? ''}!!!',
                isFirst: true,
              ),
            );
          }

          _showCount[productId] = 1;
        }
      }
    }
  }

  Future<void> recheckDiscountsAfterClientChanged() async {
    if (_currentClient.orderedProducts.isEmpty) return;

    for (final item in _currentClient.orderedProducts) {
      if (item.isPriceOnlyChanged || item.isPriceChanged) continue;
      final freshProduct = ItemsSingleton.getProductById(item.productId);
      if (freshProduct == null) continue;
      item.singleDiscount = 0;
      _applyDiscounts(freshProduct, item);
    }

    findFreeProducts();
    notifyListeners();

    await freeGiftDialog();

    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();

    notifyListeners();
  }

  void recalcDiscountsAfterClientRemoved() {
    if (_currentClient.orderedProducts.isEmpty) return;

    _returnedProducts.clear();
    _returnedFreeGiftProducts.clear();
    _returnedBuyXGetX.clear();
    _giftProducts.clear();
    _showCount.clear();
    _showCountFreeGift.clear();
    _freeGiftDialogCount = 0;
    DiscountSingleton.maxPrice();
    DiscountSingleton.resetAll();

    for (final item in _currentClient.orderedProducts) {
      if (item.isPriceOnlyChanged) continue;
      final freshProduct = ItemsSingleton.getProductById(item.productId);
      if (freshProduct == null) continue;

      item.price = item.realPrice;
      item.discountPercent = 0;
      item.singleDiscount = 0;
      item.isPriceChanged = false;
      item.discount.clear();
      item.productDiscount.clear();

      _applyDiscounts(freshProduct, item);
    }

    findFreeProducts();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();

    notifyListeners();
  }

  int i = 0;

  void addClient() {
    i++;
    if (_currentClient.orderedProducts.isNotEmpty) {
      _clientNumber++;
      final sixClientModel = SixClientModel4(
        clientNumber: _clientNumber,
        lastAddedIndex: -1,
        orderedProducts: [],
        discountAmountFromNewClient: 0,
      );
      if (_sixClient4List.isEmpty) {
        _sixClient4List.add(_currentClient);
      }

      _sixClient4List.add(sixClientModel);
      _currentClient = _sixClient4List.last;
      _index = _sixClient4List.length - 1;
      _syncReceiptCompanyPrefsFromCurrentClient();
      notifyListeners();
    }
  }

  void selectClient(int i) {
    LogHelper.activity('CLIENT_SELECT', {'index': i});
    _currentClient = _sixClient4List[i];
    _index = i;
    _clearEmptyClients();
    _syncReceiptCompanyPrefsFromCurrentClient();
    notifyListeners();
  }

  void _syncReceiptCompanyPrefsFromCurrentClient() {
    final String? name = _currentClient.receiptCompanyName;
    final int? copies = _currentClient.receiptCopies;

    if (name == null || name.isEmpty) {
      Pref.removeWithKey(PrefKeys.companyNameDialog);
    } else {
      Pref.setString(PrefKeys.companyNameDialog, name);
    }

    if (copies == null) {
      Pref.removeWithKey(PrefKeys.companyResipt);
    } else {
      Pref.setInt(PrefKeys.companyResipt, copies);
    }
  }

  void setReceiptCompanyInfo({
    required String companyName,
    required int copies,
  }) {
    _currentClient.receiptCompanyName = companyName;
    _currentClient.receiptCopies = copies;
    _syncReceiptCompanyPrefsFromCurrentClient();
  }

  void _clearEmptyClients() {
    List<int> clientNumbers = [];
    for (int i = 0; i < _sixClient4List.length; i++) {
      if (_sixClient4List[i].orderedProducts.isEmpty) {
        clientNumbers.add(_sixClient4List[i].clientNumber);
        _harvestDeletedItems(_sixClient4List[i]);
      }
    }
    _sixClient4List.removeWhere((e) => e.orderedProducts.isEmpty);
  }

  void _harvestDeletedItems(SixClientModel4 client) {
    if (client.deletedItems.isEmpty) return;
    for (final d in client.deletedItems) {
      if (d.checkNumber.isEmpty) d.checkNumber = '-';
      _orphanDeletedItems.add(d);
    }
    client.deletedItems.clear();
  }

  void _paymentOnClients() {
    _selectedSupplier = null;
    _currentClient.receiptCompanyName = null;
    _currentClient.receiptCopies = null;
    _alcoholWarningShown = false;
    _cashsaleWarningShown = false;
    _bigTotalWarningShown = false;
    _harvestDeletedItems(_currentClient);
    if (_sixClient4List.isEmpty) {
      _clientNumber = 1;
      _currentClient = SixClientModel4(
        clientNumber: _clientNumber,
        lastAddedIndex: -1,
        orderedProducts: [],
        discountAmountFromNewClient: 0,
      );
    } else if (_sixClient4List.length == 1) {
      _clientNumber = 1;
      _currentClient = SixClientModel4(
        clientNumber: _clientNumber,
        lastAddedIndex: -1,
        orderedProducts: [],
        discountAmountFromNewClient: 0,
      );
      _sixClient4List[0].orderedProducts = [];
      _clearEmptyClients();
    } else {
      _sixClient4List[_index].orderedProducts = [];
      _clearEmptyClients();
      _index = 0;
      _currentClient = _sixClient4List.first;
    }
    _syncReceiptCompanyPrefsFromCurrentClient();
  }

  clearSixClient4List() {
    _alcoholWarningShown = false;
    _cashsaleWarningShown = false;
    _bigTotalWarningShown = false;
    if (_sixClient4List.isNotEmpty) {
      for (var v in _sixClient4List) {
        v.orderedProducts.clear();
        v.clientNumber = 0;
        v.lastAddedIndex = -1;
        v.selectedSupplier = null;
        v.receiptCompanyName = null;
        v.receiptCopies = null;
      }
    }
    _currentClient.orderedProducts.clear();
    _currentClient.selectedSupplier = null;
    _currentClient.receiptCompanyName = null;
    _currentClient.receiptCopies = null;
    _sixClient4List = <SixClientModel4>[];
    _syncReceiptCompanyPrefsFromCurrentClient();

    notifyListeners();
  }

  FocusNode focusNodeTotal = FocusNode();

  totalFocusRequest() {
    focusNodeTotal.requestFocus();
    notifyListeners();
  }

  onTotalPriceOperationCompleted({
    required num discountPercent,
    required List<ReceiptModelSoldItem4> products,
  }) async {
    _currentClient.discountPercent =
        discountPercent > 0 ? discountPercent + 0 : 0;
    _currentClient.orderedProducts = [];
    _currentClient.orderedProducts.addAll(products);
    notifyListeners();
  }

  onTotalPriceButtonPressed(BuildContext context) async {
    if ((currentEmployee.access?.applyManualDiscountsNewSale ?? false) &&
        getCurrentClient.orderedProducts.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => OperationOnTotalPriceDialog(
          currentClient: getCurrentClient,
          totalPrice: ItemsSingleton.getRealTotalPrice(
              getCurrentClient.orderedProducts),
        ),
      );
    }
    return;
  }

  Future<Object?> goToPaymentPage(BuildContext context) async {
    Object? mxikError;
    double totalPrice =
        ItemsSingleton.getTotalPrice(getCurrentClient.orderedProducts);
    if (getCurrentClient.orderedProducts.isNotEmpty && totalPrice > 0) {
      initPaymentPageValues(
        sixClientModel4: getCurrentClient,
        totalPrice: totalPrice,
        discountAmount: getCurrentClient.discountAmount ?? 0,
      );
      CmtBBloc ctBloc = BlocProvider.of(context, listen: false);
      ctBloc.add(CmtBInitialEvent());
      PreCmtBBloc prectBloc = BlocProvider.of(context, listen: false);
      prectBloc.add(PreCmtBInitialEvent());
      Log.d('=========', name: 'OrderingProvider.goToPaymentPage');
      mxikError = await AppNavigation.push(PaymentPage(context));
    }
    return mxikError;
  }

  addedClientInPaymentScreen(BuildContext context) async {
    double totalPrice =
        ItemsSingleton.getTotalPrice(getCurrentClient.orderedProducts);
    if (getCurrentClient.orderedProducts.isNotEmpty && totalPrice > 0) {
      _totalPrice = totalPrice;
      _mustPay = totalPrice;
      _discountAmount = getCurrentClient.discountAmount ?? 0;
      notifyListeners();
    }
  }

  bool _isInnClient = false;

  initClientByBloc(
    ClientModel? client, {
    bool isInnClient = false,
  }) {
    final String? previousClientId = _currentClient.selectedClient?.id;
    _isInnClient = isInnClient;
    _currentClient.selectedClient = client;
    _currentClient.discountPercent = _currentClient.discountPercent ??
        0 + (client?.discountValue ?? 0).toDouble();
    dropDebtPaymentIfNoDebtor();
    if (previousClientId != client?.id) {
      _tally.removeCashbackPayment();
    }
    notifyListeners();
  }

  getComment(String comment, bool isShow) {
    _showComments = isShow;
    _comments = comment;
  }

  String setComment() {
    return _comments;
  }

  bool isShowComment() {
    return _showComments;
  }

  Future<void> pressPaymentButton(BuildContext context) async {
    LogHelper.activity('PAYMENT_PRESS', {
      'items': _sixClientModel4.orderedProducts.length,
      'mustPay': _mustPay,
      'paymentType': _selectedPaymentType,
    });
    for (int i = 0; i < _sixClientModel4.orderedProducts.length; i++) {
      if (_sixClientModel4.orderedProducts[i].isDeleted!) {
        _sixClientModel4.orderedProducts.removeAt(i);
        i--;
      }
    }
    if (_isChangeToCashback && _mustPay < 0) {
      _zdachaToCashBack = _sdachaa;
      _sdachaa = 0;
    } else {
      _zdachaToCashBack = 0;
    }

    final receiptModel4 = ReceiptBuilder.build(
      sixClient: _sixClientModel4,
      selectedSupplier: _selectedSupplier,
      currentClientDiscountPercent: _currentClient.discountPercent,
      currentCart: getCurrentClient.orderedProducts,
      totalPrice: _totalPrice,
      zdachaToCashBack: _zdachaToCashBack,
      sdacha: _sdachaa,
      fromPointBalance: _fromPointBalance,
      comments: _comments,
      showComments: _showComments,
      payments: paymentsMapAsList,
      orphanDeletedItems: _orphanDeletedItems,
      isTpEdited: isTpEdited,
    );
    if (receiptModel4.payment.isNotEmpty &&
        receiptModel4.soldItemList.isNotEmpty) {
      await ReceiptSingleton4.toOBJECTBOX(
        receiptModel4,
        clientBalance:
            _isInnClient ? null : getCurrentClient.selectedClient?.pointBalance,
      );

      _returnedProducts = {};
      _returnedFreeGiftProducts = [];
      _giftProducts = {};
      _freeGiftDialogCount = 0;
      _showCount = {};
      _showCountFreeGift = {};

      _sixClientModel4.deletedItems.clear();
      _orphanDeletedItems.clear();

      DiscountSingleton.maxPrice();
    }
    _paymentOnClients();
    _newClientPersentageDiscount = 0;
    controller.text = '0';
    _comments = "";
    _showComments = true;
    notifyListeners();
  }

  List<ReceiptModelPaymentType4> get paymentsMapAsList => ReceiptPayments.build(
        paymentsMap,
        ids: PaymentIds(
          cash: Pref.getString(PrefKeys.cashId, ""),
          card: Pref.getString(PrefKeys.cardId, ""),
          cashback: Pref.getString(PrefKeys.cashbackId, ""),
          debt: Pref.getString(PrefKeys.debtId, ""),
          payme: Pref.getString(PrefKeys.paymeId, ""),
          click: Pref.getString(PrefKeys.clickId, ""),
          uzum: Pref.getString(PrefKeys.uzumId, ""),
        ),
        sdacha: _sdachaa,
        zdachaToCashBack: _zdachaToCashBack,
      );

  static String cleanMarkForFiscal(String rawMark) =>
      MarkCleaner.forFiscal(rawMark);

  Future<PaymentResult> pressPaymentButtonOnlyOFD(BuildContext context) async {
    AppLocalizations loc = AppLocalizations.of(context)!;

    if (_isChangeToCashback && _sdachaa > 0) {
      _zdachaToCashBack = _sdachaa;
      _sdachaa = 0;
    } else {
      _zdachaToCashBack = 0;
    }

    final receiptModel4 = ReceiptBuilder.buildOnlyOfd(
      sixClient: _sixClientModel4,
      selectedSupplier: _selectedSupplier,
      currentClientDiscountPercent: _currentClient.discountPercent,
      currentCart: getCurrentClient.orderedProducts,
      totalPrice: _totalPrice,
      zdachaToCashBack: _zdachaToCashBack,
      sdacha: _sdachaa,
      fromPointBalance: _fromPointBalance,
      comments: _comments,
      showComments: _showComments,
      payments: paymentsMapAsList,
      orphanDeletedItems: _orphanDeletedItems,
      isTpEdited: isTpEdited,
      lastCardType: _lastCardType,
      lastCardNumber: _lastCardNumber,
      lastRRN: _lastRRN,
    );

    if (receiptModel4.soldItemList.isEmpty) {
      LogHelper.write(
        LogLevel.warn,
        "BO'SH ITEMS — OFD'ga yuborilmadi (double-trigger guard). "
        "paymentsMap.length=${paymentsMap.length}, "
        "orderedProducts.length=${_sixClientModel4.orderedProducts.length}",
      );
      _comments = "";
      _showComments = true;
      controller.text = '0';
      _newClientPersentageDiscount = 0;
      notifyListeners();
      return PaymentResult(mxikError: null, success: false, skipped: true);
    }

    PaymentResult paymentResult = await LocalService.sell(
      loc: loc,
      receiptData: receiptModel4,
    ).then(
      (CommunicatorRESPONSE response) async {
        if (!response.error! && response.info != null) {
          receiptModel4.url = response.info?.qrCodeUrl ?? '';
          receiptModel4.payment.clear();
          receiptModel4.payment.addAll(paymentsMapAsList);
          receiptModel4.refundInfo = jsonEncode(response.info!.toJson());

          if (receiptModel4.payment.isNotEmpty &&
              receiptModel4.soldItemList.isNotEmpty) {
            await ReceiptSingleton4.toOBJECTBOX(
              receiptModel4,
              communicatorRECEIPT: response,
              clientBalance: _isInnClient
                  ? null
                  : getCurrentClient.selectedClient?.pointBalance,
            );
          }

          return PaymentResult(mxikError: null, success: true);
        } else {
          return PaymentResult(
            mxikError: response.mxikError,
            success: false,
            errorMessage: response.paycheck?.toString(),
          );
        }
      },
    ).catchError((err) {
      return PaymentResult(
          mxikError: err, success: false, errorMessage: err.toString());
    });

    if (paymentResult.success) {
      _returnedProducts = {};
      _giftProducts = {};
      _freeGiftDialogCount = 0;
      _showCount = {};
      _showCountFreeGift = {};

      _sixClientModel4.deletedItems.clear();
      _orphanDeletedItems.clear();

      DiscountSingleton.maxPrice();
      _paymentOnClients();
      paymentsMap = {};
    }

    _comments = "";
    _showComments = true;
    controller.text = '0';
    _newClientPersentageDiscount = 0;
    notifyListeners();
    return paymentResult;
  }

  initPaymentPageValues({
    required SixClientModel4 sixClientModel4,
    required double totalPrice,
    required num discountAmount,
  }) {
    _isChangeToCashback = false;
    _zdachaToCashBack = 0;
    _selectedPaymentType = null;
    _sixClientModel4 = sixClientModel4;
    _paymentInProgress = false;
    _totalPrice = totalPrice;
    _mustPay = totalPrice;
    _sdachaa = 0;
    paymentsMap = {};
    _lastCardNumber = '';
    _lastRRN = '';
    _lastCardType = 0;
    _showComments = true;
    _comments = "";
    _fromPointBalance = 0;
    _gettingPointBalance = false;
    _isButtonEnabled = false;
    controller.text = '';
    _discountAmount = discountAmount;
    _isChangeToCashback = false;
    clickedCount = 0;
    controller = TextEditingController(text: '0');
    _isOfdWithOfd = false;
    _clickPassPaid = false;
    _paymePaid = false;
    PaynetService.paymentId = null;
  }

  late bool _paymentInProgress;

  late final PaymentTallyController _tally =
      PaymentTallyController(notifyListeners);

  int get selectedPaymentIndex => _tally.selectedPaymentIndex;
  set selectedPaymentIndex(int v) => _tally.selectedPaymentIndex = v;

  TextEditingController controller = TextEditingController(text: '0');

  late SixClientModel4 _sixClientModel4;

  num get _totalPrice => _tally.totalPrice;
  set _totalPrice(num v) => _tally.totalPrice = v;

  final focusNodeListener = FocusNode();
  late String _comments = "";
  late bool _showComments = true;

  double get _zdachaToCashBack => _tally.zdachaToCashBack;
  set _zdachaToCashBack(double v) => _tally.zdachaToCashBack = v;

  double get _mustPay => _tally.mustPay;
  set _mustPay(double v) => _tally.mustPay = v;

  double get _sdachaa => _tally.sdacha;
  set _sdachaa(double v) => _tally.sdacha = v;

  double _fromPointBalance = 0;
  bool _gettingPointBalance = false;

  num _discountAmount = 0;

  bool get _isButtonEnabled => _tally.isButtonEnabled;
  set _isButtonEnabled(bool v) => _tally.isButtonEnabled = v;
  bool _isOfdWithOfd = false;
  bool _isChangeToCashback = false;

  bool get getOfdIsWithOfd => _isOfdWithOfd;

  bool get getPaymentInProgress => _paymentInProgress;

  SixClientModel4 get getSixClientModel4 => _sixClientModel4;

  num get getTotalPaymentPrice => _totalPrice;

  bool get isDidox => _isDidox;

  double get getMustPay => _mustPay;

  double get getSdacha => _sdachaa;

  bool get getIsButtonEnabled => _isButtonEnabled;

  double get getFromPointBalance => _fromPointBalance;

  String get getClientGroupId => _currentClient.selectedClient?.groupId ?? "";

  String get getClientType =>
      _currentClient.selectedClient?.discountGroupType ?? "";

  num get getClientPointBalance =>
      _currentClient.selectedClient?.pointBalance ?? 0;

  String get getClientFirstname =>
      _currentClient.selectedClient?.firstName ?? "";

  String get getClientLastName => _currentClient.selectedClient?.lastName ?? "";

  bool get getGettingPointBalance => _gettingPointBalance;

  bool get isChangeToCashback => _isChangeToCashback;

  bool get getCurrentClientIsNotNULL => _currentClient.selectedClient != null;

  bool get getCurrentClientIsAvailableForDebt =>
      _currentClient.selectedClient != null &&
      _currentClient.selectedClient!.isAvailableForDebt != null &&
      _currentClient.selectedClient!.isAvailableForDebt!;

  num get getDiscountAmount => _discountAmount;

  bool get isEnabledPettyCashToCashbackButton {
    return (_sixClientModel4.selectedClient != null) && _mustPay < 0;
  }

  List<bool> get _isBonusCardEnabled {
    num point = 0;
    bool clintIsNotNull = false;
    if (_sixClientModel4.selectedClient != null) {
      point = _sixClientModel4.selectedClient?.pointBalance ?? 0;
      clintIsNotNull = _sixClientModel4.selectedClient != null;
    }

    return <bool>[clintIsNotNull, point > 0];
  }

  bool _isDidox = false;

  setDidox(bool isDidox) {
    _isDidox = isDidox;
    notifyListeners();
  }

  setIsOfdWithOfd() {
    _isOfdWithOfd = !_isOfdWithOfd;
    notifyListeners();
  }

  setPaymentInProgress(bool v) {
    _paymentInProgress = v;
    notifyListeners();
  }

  void removeFromPaymentList() => _tally.removeFromPaymentList();

  bool get _hasEligibleDebtor =>
      _currentClient.selectedClient != null || _selectedSupplier != null;

  bool get isDebtSelectedWithoutDebtor {
    if (_hasEligibleDebtor) return false;
    final String debtId = Pref.getString(PrefKeys.debtId, '');
    return paymentsMap.entries.any((e) =>
        (debtId.isNotEmpty && e.key.replaceFirst('@', '') == debtId) ||
        (e.value.name ?? '').toUpperCase().contains('DEBT'));
  }

  bool dropDebtPaymentIfNoDebtor() {
    if (_hasEligibleDebtor) return false;
    return _tally.removeDebtPayment();
  }

  bool get isCashbackSelectedWithoutClient {
    if (_currentClient.selectedClient != null) return false;
    return _tally.hasCashbackPayment;
  }

  bool dropCashbackPaymentIfNoClient() {
    if (_currentClient.selectedClient != null) return false;
    return _tally.removeCashbackPayment();
  }

  selectPaymentIndex(int v) => _tally.selectPaymentIndex(v);

  changeTheSelectedPaymentIndex(bool up) =>
      _tally.changeTheSelectedPaymentIndex(up);

  int clickedCount = 0;

  void switchIsChangeToCashback() {
    _isChangeToCashback = !_isChangeToCashback;
    clickedCount++;
    if (clickedCount == 2) {
      _mustPay = 0;
      _isChangeToCashback = true;
      clickedCount = 0;
    }
    notifyListeners();
  }

  onCButtonPressed() {
    controller.text = '0';
    focusNodeListener.requestFocus();
    notifyListeners();
  }

  onDotPressed() {
    controller.text = MoneyFormatter.remover(controller.text);
    double parsed = double.tryParse(controller.text) ?? 0;

    if (controller.text.contains('.') || controller.text.isEmpty) {
      controller.text = MoneyFormatter.inputMoneyFormatter.format(parsed);
      notifyListeners();
      return;
    } else {
      controller.text += '.';

      focusNodeListener.requestFocus();
      controller.text = MoneyFormatter.inputMoneyFormatter
          .format(double.tryParse(controller.text));
      notifyListeners();
    }
  }

  void onNumPressed(num num) {
    if (controller.text.length < 15) {
      controller.text = MoneyFormatter.remover(controller.text);
      if (controller.text.startsWith('0')) {
        controller.text = controller.text.substring(1);
      }
      controller.text += num.toString();
      double parsed = double.parse(controller.text);
      controller.text = MoneyFormatter.inputMoneyFormatter.format(parsed);
      focusNodeListener.requestFocus();
      notifyListeners();
    }
  }

  onBackSpacePressed() {
    if (controller.text == "0") {
      if (paymentsMap.isEmpty) {}
      return;
    }
    if (controller.text.length == 1) {
      controller.text = '0';
      notifyListeners();
      return;
    }
    if (controller.text.isNotEmpty) {
      controller.text = MoneyFormatter.remover(controller.text);
      double parsed = double.tryParse(
              controller.text.substring(0, controller.text.length - 1)) ??
          0;

      controller.text = MoneyFormatter.inputMoneyFormatter.format(parsed);
    } else {
      controller.text = '0';
    }

    focusNodeListener.requestFocus();
    notifyListeners();
  }

  BuildContext? cont;

  onAddComments(BuildContext context) async {
    cont = context;
    await showDialog(
      context: cont!,
      builder: (cont) => Builder(builder: (context) {
        return AddDescriptionDialog(
          context,
        );
      }),
    );
    return;
  }

  BuildContext? con;

  Future<void> _showClientSupplierConflictWarning(
    BuildContext context, {
    required bool clientAlreadySelected,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final bool isUz = loc.ha == 'Ha';
    final String message = clientAlreadySelected
        ? (isUz
            ? "Mijoz allaqachon tanlangan. Supplier qo'shish uchun avval mijozni o'chiring."
            : "Клиент уже выбран. Чтобы добавить поставщика, сначала удалите клиента.")
        : (isUz
            ? "Allaqachon supplier tanlangan. Mijoz qo'shish uchun avval supplierni o'chiring."
            : "Поставщик уже выбран. Чтобы добавить клиента, сначала удалите поставщика.");

    await showCupertinoDialog(
      barrierDismissible: true,
      context: context,
      builder: (_) => Theme(
        data: ThemeData.dark(),
        child: CupertinoAlertDialog(
          content: Text(message, style: const TextStyle(fontSize: 20)),
          actions: [
            CupertinoButton(
              onPressed: () => AppNavigation.pop(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  onClientSearchButtonPressed(BuildContext context, WherePath route) async {
    if (_selectedSupplier != null) {
      await _showClientSupplierConflictWarning(
        context,
        clientAlreadySelected: false,
      );
      return;
    }
    ClientBloc clientBloc = BlocProvider.of(context, listen: false);
    clientBloc.add(ClientInitialEvent());
    con = context;
    await showDialog(
      context: con!,
      builder: (con) => Builder(
        builder: (context) {
          return ClientSearchDialogWithBloc(
            context,
            client: _currentClient.selectedClient,
            onDelClientPressed: () {
              _currentClient.selectedClient = null;
              Provider.of<OrderingProvider4>(context, listen: false)
                  .setNewClientDiscountPercentage(0);
              OrderingProvider4().getCurrentClient.discountAmountFromNewClient =
                  0;
              recalcDiscountsAfterClientRemoved();
              dropDebtPaymentIfNoDebtor();
              dropCashbackPaymentIfNoClient();
              AppNavigation.pop();
              notifyListeners();
            },
            currentClient: getCurrentClient,
            totalPrice:
                ItemsSingleton.getTotalPrice(getCurrentClient.orderedProducts),
            route: route,
          );
        },
      ),
    );

    if (getClientGroupId.isNotEmpty) {
      _currentClient.orderedProducts = _currentClient.orderedProducts
          .map((item) => DiscountSingleton.addDiscountOnProduct(
              item, item.soldBy, getClientGroupId))
          .toList();
      notifyListeners();
    }
    return;
  }

  SupplierModel? get _selectedSupplier => _currentClient.selectedSupplier;

  set _selectedSupplier(SupplierModel? supplier) =>
      _currentClient.selectedSupplier = supplier;

  SupplierModel? get getSelectedSupplier => _selectedSupplier;

  void setSelectedSupplierFromInnSearch(SupplierModel? supplier) {
    _selectedSupplier = supplier;
    dropDebtPaymentIfNoDebtor();
    notifyListeners();
  }

  BuildContext? supplierCon;

  onSupplierSearchButtonPressed(BuildContext context) async {
    if (_currentClient.selectedClient != null) {
      await _showClientSupplierConflictWarning(
        context,
        clientAlreadySelected: true,
      );
      return;
    }
    SupplierBloc supplierBloc = BlocProvider.of(context, listen: false);
    supplierBloc.add(SupplierInitialEvent());
    supplierCon = context;

    await showDialog(
      context: supplierCon!,
      builder: (con) => Builder(
        builder: (context) {
          return SupplierSearchDialog(
            currentSupplier: _selectedSupplier,
            onSupplierSelected: (supplier) {
              _selectedSupplier = supplier;
              notifyListeners();
            },
            onDeleteSupplier: () {
              _selectedSupplier = null;
              notifyListeners();
              AppNavigation.pop();
            },
          );
        },
      ),
    );
    return;
  }

  onCreateProductButtonPressed(BuildContext context, {String? barcode}) async {
    con = context;
    await showDialog(
      context: con!,
      builder: (con) => Builder(
        builder: (context) {
          return CreateProductDialog(barcode: barcode ?? "");
        },
      ),
    );
    return;
  }

  Map<String, Payment> get paymentsMap => _tally.paymentsMap;
  set paymentsMap(Map<String, Payment> v) => _tally.paymentsMap = v;

  bool _clickPassPaid = false;
  bool get clickPassPaid => _clickPassPaid;

  bool _paymePaid = false;
  bool get paymePaid => _paymePaid;
  void setPaymePaid(bool v) => _paymePaid = v;

  String? get _selectedPaymentType => _tally.selectedPaymentType;
  set _selectedPaymentType(String? v) => _tally.selectedPaymentType = v;

  void allPaymentType(Payment payment) {
    _selectedPaymentType =
        payment.type == 1 ? '@${payment.id}' : payment.id ?? '';
    double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    double available = getAvailableSumma();
    double currentPaymentValue = getSelectedPaymentSumma();

    double summa = parsed > 0
        ? (available - currentPaymentValue >= parsed
            ? parsed
            : available - currentPaymentValue)
        : available - currentPaymentValue;

    if (payment.id == Pref.getString(PrefKeys.cashId, "")) {
      if (parsed > 0) {
        _payByAll(parsed + currentPaymentValue, payment);
      } else {
        _payByAll(summa + currentPaymentValue, payment);
      }
    } else if (summa > 0) {
      _payByAll(summa + currentPaymentValue, payment);
    }
    controller.text = '0';
    notifyListeners();
  }

  void _payByAll(double v, Payment payment) => _tally.payByAll(v, payment);

  double getAvailableSumma() => _tally.getAvailableSumma();

  double getSelectedPaymentSumma() => _tally.getSelectedPaymentSumma();

  Map<String, String?> parseTerminalReceipt(String receiptText) =>
      TerminalReceiptParser.parseTerminalReceipt(receiptText);

  void typeUzcard(BuildContext context, Payment payment) async {
    _selectedPaymentType =
        payment.type == 1 ? '@${payment.id}' : payment.id ?? '';
    AppLocalizations loc = AppLocalizations.of(context)!;

    double available = getAvailableSumma();
    double currentPaymentValue = getSelectedPaymentSumma();
    double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    double summa = parsed > 0
        ? (available - currentPaymentValue >= parsed
            ? parsed
            : available - currentPaymentValue)
        : available - currentPaymentValue;

    const fs = fl.LocalFileSystem();
    final shell = Shell();

    if (!(Pref.getBool(PrefKeys.isUzcardEnabled, false))) {
      _lastCardType = Pref.getInt('card_type', 2);
      allPaymentType(payment);
      controller.text = '0';
      return;
    }

    if (summa > 0) {
      String summaAsString = summa.toStringAsFixed(2);
      summaAsString = (double.parse(summaAsString) * 100).round().toString();
      await shell.startAndReadAsString(
        'C:/Arcus2/CommandLineTool/bin/CommandLineTool.exe',
        arguments: ['/o1', '/a$summaAsString', '/c860'],
      ).then(
        (value) async {
          var logsDirectory = fs.directory('C:\\Arcus2\\Logs\\');
          var log = await logsDirectory
              .list(recursive: true, followLinks: false)
              .last;
          final file = File(log.path);
          var data = await file.readAsBytes();
          String asString = windows1251.decode(data);
          var receiptDirectory = fs.directory('C:\\Arcus2\\cheq.out');
          final file2 = File(receiptDirectory.path);
          var data2 = await file2.readAsBytes();
          String asString2 = windows1251.decode(data2);

          final bool isApproved =
              asString.contains("ОДО") && asString.contains("РЕНО") ||
                  asString.contains("ОДОБРЕНО") ||
                  asString.contains("TASDIQLANDI");

          if (isApproved) {
            allPaymentType(payment);
            controller.text = '0';
            final paymentInfo = parseTerminalReceipt(asString2);
            _lastRRN = paymentInfo['rrn'] ?? '';
            _lastCardNumber = paymentInfo['cardNumber'] ?? '';
            _lastCardType = Pref.getInt('card_type', 2);
            await PrintingMethods.printHumoRecipts(asString2.toString());
            ScaffoldMessenger.of(context)
                .showSnackBar(mySnackBar(context, msg: "ОДОБРЕНО"));
          } else {
            await showTerminalErrorDialog(
              context,
              log: asString,
              receipt: asString2,
            );
          }
        },
      ).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
            msg: NetworkErrorHelper.friendlyMessage(error,
                isUz: loc.ha.toLowerCase() == 'ha')));
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(mySnackBar(context, msg: loc.qiymat_kiriting));
    }
  }

  void typeHumo(BuildContext context, Payment payment) async {
    _selectedPaymentType =
        payment.type == 1 ? '@${payment.id}' : payment.id ?? '';
    AppLocalizations loc = AppLocalizations.of(context)!;

    double available = getAvailableSumma();
    double currentPaymentValue = getSelectedPaymentSumma();
    double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    double summa = parsed > 0
        ? (available - currentPaymentValue >= parsed
            ? parsed
            : available - currentPaymentValue)
        : available - currentPaymentValue;

    const fs = fl.LocalFileSystem();
    final shell = Shell();

    if (!(Pref.getBool(PrefKeys.isHumoEnabled, false))) {
      _lastCardType = Pref.getInt('card_type', 2);
      allPaymentType(Payment(
        id: payment.id,
        name: payment.name,
        title: payment.title,
        enable: payment.enable,
        isAdded: payment.isAdded,
        merchantId: payment.merchantId,
        merchantUserId: payment.merchantUserId,
        password: payment.password,
        secretKey: payment.secretKey,
        serviceId: payment.serviceId,
        type: 1,
        value: payment.value,
      ));
      controller.text = '0';
      return;
    }

    if (summa > 0) {
      String summaAsString = summa.toStringAsFixed(2);
      summaAsString = (double.parse(summaAsString) * 100).round().toString();
      await shell.startAndReadAsString(
        'C:/Arcus2/CommandLineTool/bin/CommandLineTool.exe',
        arguments: ['/o1', '/a$summaAsString', '/c860'],
      ).then(
        (value) async {
          var logsDirectory = fs.directory('C:\\Arcus2\\Logs\\');
          var log = await logsDirectory
              .list(recursive: true, followLinks: false)
              .last;
          final file = File(log.path);
          var data = await file.readAsBytes();
          String asString = windows1251.decode(data);
          var reciptDirectory = fs.directory('C:\\Arcus2\\cheq.out');
          final file2 = File(reciptDirectory.path);
          var data2 = await file2.readAsBytes();
          String asString2 = windows1251.decode(data2);

          final bool isApprovedH =
              asString.contains("ОДО") && asString.contains("РЕНО") ||
                  asString.contains("ОДОБРЕНО") ||
                  asString.contains("TASDIQLANDI");

          if (isApprovedH) {
            allPaymentType(Payment(
              id: payment.id,
              name: payment.name,
              title: payment.title,
              enable: payment.enable,
              isAdded: payment.isAdded,
              merchantId: payment.merchantId,
              merchantUserId: payment.merchantUserId,
              password: payment.password,
              secretKey: payment.secretKey,
              serviceId: payment.serviceId,
              type: 1,
              value: payment.value,
            ));
            controller.text = '0';
            final paymentInfo = parseTerminalReceipt(asString2);
            _lastRRN = paymentInfo['rrn'] ?? '';
            _lastCardNumber = paymentInfo['cardNumber'] ?? '';
            _lastCardType = Pref.getInt('card_type', 2);
            await PrintingMethods.printHumoRecipts(asString2.toString());
            ScaffoldMessenger.of(context)
                .showSnackBar(mySnackBar(context, msg: "ОДОБРЕНО"));
          } else {
            await showTerminalErrorDialog(
              context,
              log: asString,
              receipt: asString2,
            );
          }
        },
      ).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
            msg: NetworkErrorHelper.friendlyMessage(error,
                isUz: loc.ha.toLowerCase() == 'ha')));
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(mySnackBar(context, msg: loc.qiymat_kiriting));
    }
  }

  void typeFromCashbackBalance(BuildContext context, Payment payment) {
    AppLocalizations loc = AppLocalizations.of(context)!;

    _selectedPaymentType = Pref.getString(PrefKeys.cashbackId, '');
    if (_isBonusCardEnabled[0] && _isBonusCardEnabled[1]) {
      double parsed =
          double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
      double available = getAvailableSumma();
      num balance = _sixClientModel4.selectedClient?.pointBalance ?? 0.0;

      double used = getSelectedPaymentSumma();
      double freeBalance = balance.toDouble() - used;
      if (freeBalance < 0) freeBalance = 0;

      if (parsed > 0) {
        if (freeBalance >= parsed) {
          if (available >= parsed) {
            allPaymentType(payment);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            mySnackBar(context,
                msg: '${loc.client_cartasida_yetarli_emas} '
                    '(${MoneyFormatter.inputMoneyFormatter.format(freeBalance)})'),
          );
        }
      } else if (available > 0) {
        if (available <= balance) {
          allPaymentType(payment);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              mySnackBar(context, msg: loc.client_cartasida_yetarli_emas));
        }
      }
    } else {
      Log.d('====== if (parsed > 0) || ELSE =======');
      if (_isBonusCardEnabled[0] && !_isBonusCardEnabled[1]) {
        Log.d('_isBonusCardEnabled[0] && !_isBonusCardEnabled[1]');
        ScaffoldMessenger.of(context).showSnackBar(
            mySnackBar(context, msg: loc.client_cartasida_yetarli_emas));
      } else {
        Log.d('_isBonusCardEnabled[0] && !_isBonusCardEnabled[1] || ELSE');

        ScaffoldMessenger.of(context)
            .showSnackBar(mySnackBar(context, msg: loc.clint_tanlanmagan));
      }
    }
    controller.text = '0';
    notifyListeners();
  }

  Future<void> typePayme(BuildContext context, Payment payment) async {
    AppLocalizations loc = AppLocalizations.of(context)!;

    if (!(Pref.getBool(PrefKeys.isPaymegoActivated, false))) {
      ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(context, msg: "PAYME ${loc.tolov_turi_activlashtirilmagan}"),
      );
      return;
    }

    _selectedPaymentType =
        payment.type == 1 ? '@${payment.id}' : payment.id ?? '';

    double available = getAvailableSumma();
    double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;

    double amount =
        parsed > 0 ? (available >= parsed ? parsed : available) : available;
    PaymeBloc paymeBloc = BlocProvider.of(context, listen: false);

    paymeBloc.add(PaymeCreateReceiptEvent(
        amount: amount.toInt(), items: _currentClient.orderedProducts));
    await showDialog(
      context: context,
      builder: (_) => PaymeDialog(
        callback: () {
          AppNavigation.pop();
          allPaymentType(payment);
          _paymePaid = true;
        },
      ),
    );

    controller.text = '0';
    notifyListeners();
  }

  bool _clickPayIsWorking = false;
  bool _paynetPayIsWorking = false;

  Future<void> typeClick(BuildContext context, Payment payment) async {
    _selectedPaymentType =
        payment.type == 1 ? '@${payment.id}' : payment.id ?? '';

    ClickBloc clickBloc = BlocProvider.of(context);
    final int number = MyObjectbox.saleStore
        .box<ReceiptModel4>()
        .query()
        .build()
        .find()
        .length;

    final String receiptNumber =
        "${Pref.getString(PrefKeys.checkId, "0")}$number";
    AppLocalizations loc = AppLocalizations.of(context)!;

    if (!(Pref.getBool(PrefKeys.isClickPassActivated, false))) {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
          msg: "CLICK ${loc.tolov_turi_activlashtirilmagan}"));
      return;
    }

    final double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    final double summa = _tally.amountIgnoringCurrent(parsed);

    if (summa > 0 && !_clickPayIsWorking) {
      _clickPayIsWorking = true;
      notifyListeners();
      clickBloc.add(ClickCallInitialEvent());
      await showGeneralDialog(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ClickPassDialog(
            summa: summa,
            receiptNumber: receiptNumber,
            pay: () {
              allPaymentType(payment);
              _clickPassPaid = true;
            },
          );
        },
        barrierDismissible: false,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 100),
      );
      _clickPayIsWorking = false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(context, msg: loc.qiymat_kiriting),
      );
    }
    _clickPayIsWorking = false;
    notifyListeners();
    controller.text = '0';
    notifyListeners();
  }

  Future<void> typeUzum(BuildContext context, Payment payment) async {
    final int number = MyObjectbox.saleStore
        .box<ReceiptModel4>()
        .query()
        .build()
        .find()
        .length;

    final String receiptNumber =
        "${Pref.getString(PrefKeys.checkId, "0")}$number";
    AppLocalizations loc = AppLocalizations.of(context)!;

    final double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    final double summa = _tally.amountIgnoringCurrent(parsed);

    if (summa > 0) {
      notifyListeners();
      await showGeneralDialog(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) {
          return BlocProvider(
            create: (context) => UzumPayBloc(),
            child: UzumDialogContent(
              pay: () => allPaymentType(payment),
              summa: summa,
              receiptNumber: receiptNumber,
            ),
          );
        },
        barrierDismissible: false,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 100),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(context, msg: loc.qiymat_kiriting),
      );
    }
    notifyListeners();
    controller.text = '0';
    notifyListeners();
  }

  Future<void> typePaynet(BuildContext context, Payment payment) async {
    _selectedPaymentType =
        payment.type == 1 ? '@${payment.id}' : payment.id ?? '';

    PaynetBloc paynetBloc = BlocProvider.of(context);
    final int number = MyObjectbox.saleStore
        .box<ReceiptModel4>()
        .query()
        .build()
        .find()
        .length;

    final String receiptNumber =
        "${Pref.getString(PrefKeys.checkId, "0")}$number";
    AppLocalizations loc = AppLocalizations.of(context)!;

    final double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    final double summa = _tally.amountIgnoringCurrent(parsed);

    Log.d('typePaynet() — summa: $summa, receipt: $receiptNumber',
        name: 'OrderingProvider4');

    if (summa > 0 && !_paynetPayIsWorking) {
      _paynetPayIsWorking = true;
      notifyListeners();
      paynetBloc.add(PaynetCallInitialEvent());
      await showGeneralDialog(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) {
          return PaynetDialog(
            summa: summa,
            receiptNumber: receiptNumber,
            pay: () {
              allPaymentType(payment);
              Log.d('typePaynet() — to\'lov qabul qilindi',
                  name: 'OrderingProvider4');
            },
          );
        },
        barrierDismissible: false,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 100),
      );
      _paynetPayIsWorking = false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(context, msg: loc.qiymat_kiriting),
      );
    }
    _paynetPayIsWorking = false;
    notifyListeners();
    controller.text = '0';
    notifyListeners();
  }

  late final CatalogNavigationController _catalog =
      CatalogNavigationController(notifyListeners);

  bool displayingNotFoundDialog = false;
  bool _invalidBarcodeDialogActive = false;

  List<dynamic> get getItems => _catalog.getItems;

  List<CategoryData> get getPathList => _catalog.getPathList;

  Future<void> _showInvalidFormatBarcodeDialog() async {
    if (_invalidBarcodeDialogActive) return;
    _invalidBarcodeDialogActive = true;
    final ctx = AppNavigation.navigatorKey.currentContext;
    if (ctx == null) {
      _invalidBarcodeDialogActive = false;
      return;
    }
    final loc = AppLocalizations.of(ctx);
    await showGeneralDialog(
      barrierDismissible: false,
      context: ctx,
      pageBuilder: (_, __, ___) => ContainsZeroPriceItemDialog(
        text: loc?.notogri_format_qr ?? "Noto'g'ri formatdagi QR kod",
        text2: 'Ok',
        delete: false,
        isFirst: false,
        provider: this,
      ),
    );
    _invalidBarcodeDialogActive = false;
  }

  onBarcodeScanned(String barcode, GlobalKey<ScaffoldState> scaffoldKey) async {
    barcode = BarcodeClassifier.sanitize(barcode);

    final kind = BarcodeClassifier.classify(
      barcode,
      taroziPrefix: Pref.getInt(PrefKeys.taroziPrefix, 28),
      taroziPiecePrefix: Pref.getInt(PrefKeys.taroziPiecePrefix, 21),
    );

    if (kind == ScannedCodeKind.empty) return;
    if (kind == ScannedCodeKind.url) {
      await _showInvalidFormatBarcodeDialog();
      return;
    }
    if (isMarkingDialogDisplaying) return;

    switch (kind) {
      case ScannedCodeKind.empty:
      case ScannedCodeKind.url:
      case ScannedCodeKind.uuid:
        return;
      case ScannedCodeKind.freeText:
      case ScannedCodeKind.noDigits:
        await _showInvalidFormatBarcodeDialog();
        return;
      case ScannedCodeKind.utsenkaQr:
        final utsenkaItem = _parseUtsenkaQr(barcode);
        if (utsenkaItem != null) {
          _currentClient.orderedProducts.insert(0, utsenkaItem);
          notifyListeners();
          return;
        }
        await _showInvalidFormatBarcodeDialog();
        return;
      case ScannedCodeKind.weightItem:
        scanWeightItem(barcode, scaffoldKey);
        return;
      case ScannedCodeKind.pieceItem:
        scanPieceItem(barcode, scaffoldKey);
        return;
      case ScannedCodeKind.product:
        break;
    }

    final DateTime? expiryDate = BarcodeClassifier.parseExpiry(barcode);

    if (expiryDate != null) {
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (expiryDate.isBefore(today)) {
        await _showMarkDialog('Срок годности этого товара ист�к!');
        return;
      }
    }
    final boxProduct = ScannedProductLookup.findBoxProduct(barcode);
    if (boxProduct != null) {
      await _addBoxProduct(boxProduct, barcode);
      return;
    }
    final match = ScannedProductLookup.find(
      barcode,
      isMarkable: _isProductMarkable,
      cleanMark: _markirovka,
    );
    final triedPatterns = match.triedPatterns;
    ItemModel? item = match.item;
    if (item != null) {
      final mxikStr = (item.mxikCode ?? '').trim();
      final bool markCheckEnabled =
          Pref.getBool(PrefKeys.markCheckWithOfd, false);
      final bool sellWithMarkingEnabled =
          Pref.getBool(PrefKeys.sellProductsWithMarking, true);
      // `is_marking == false` bo'lsa MXIK ro'yxatda bo'lsa ham markirovka
      // dialogi chiqmaydi — oddiy mahsulot (qoida: MxikRules).
      final bool isMarkingByMxik = markCheckEnabled &&
          sellWithMarkingEnabled &&
          MxikRules.isMxikAutoDetectCandidate(item);

      if (markCheckEnabled && _isAlcoholMxik(mxikStr)) {
        Pref.setBool(PrefKeys.isCashDisableForAlcohol, true);
      }
      if (isMarkingByMxik) {
        await marking(scaffoldKey.currentState!.context, item);
        return;
      }

      addProduct(
        context: scaffoldKey.currentState!.context,
        value: item.hasBoxBarcode == true &&
                item.boxBarcode != null &&
                item.boxBarcode == barcode.trim()
            ? (item.boxBarcodeQuantity ?? 0).toDouble()
            : 1,
        product: item,
        where: "PRODUCTS GRID VIEW / scanBarcode",
      );
      return;
    }
    {
      final zeroPriceItem =
          ScannedProductLookup.findZeroPriceProduct(triedPatterns);
      if (zeroPriceItem != null) {
        // ignore: use_build_context_synchronously
        addProduct(
          context: scaffoldKey.currentState!.context,
          value: 1,
          product: zeroPriceItem,
          where: "PRODUCTS GRID VIEW / scanBarcode zeroPriceItem",
        );
        return;
      }
    }

    if (!displayingNotFoundDialog) {
      displayingNotFoundDialog = true;
      await showDialog(
        barrierDismissible: false,
        context: scaffoldKey.currentState!.context,
        builder: (context) {
          return NotFoundProductDialog(
            onOKButtonPressed: () {
              displayingNotFoundDialog = false;
              AppNavigation.pop();
            },
            onCreateButtonPressed: () {
              AppNavigation.pop();
              Provider.of<OrderingProvider4>(context, listen: false)
                  .onCreateProductButtonPressed(context, barcode: barcode);
            },
          );
        },
      );
      displayingNotFoundDialog = false;
      notifyListeners();
    }
  }

  bool _isAlcoholMxik(String mxikStr) => MxikRules.isAlcoholMxik(mxikStr);

  bool _isProductMarkable(ItemModel product) =>
      MxikRules.isProductMarkable(product);

  void scanWeightItem(
    String barcode,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) async =>
      _addFromTaroziLabel(barcode, scaffoldKey,
          value: TaroziLabel.weightKg(barcode), where: 'scanWeightItem');

  void scanPieceItem(
    String barcode,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) async =>
      _addFromTaroziLabel(barcode, scaffoldKey,
          value: 1, where: 'scanPieceItem');

  Future<void> _addFromTaroziLabel(
    String barcode,
    GlobalKey<ScaffoldState> scaffoldKey, {
    required double value,
    required String where,
  }) async {
    final item = TaroziLabel.findProduct(TaroziLabel.plu(barcode));
    if (item == null) {
      await _showBarcodeNotFoundDialog(scaffoldKey);
      return;
    }
    addProduct(
      context: scaffoldKey.currentState!.context,
      value: value,
      product: item,
      where: "PRODUCTS GRID VIEW / $where",
      isTarozi: true,
    );
  }

  Future<void> _showBarcodeNotFoundDialog(
    GlobalKey<ScaffoldState> scaffoldKey,
  ) async {
    if (displayingNotFoundDialog) return;
    displayingNotFoundDialog = true;
    await showDialog(
      context: scaffoldKey.currentState!.context,
      builder: (context) {
        return Theme(
          data: ThemeData.dark(),
          child: CupertinoAlertDialog(
            title: Text(
              'Нет продукта с этим штрих-кодом',
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
              ),
            ),
            actions: [
              CupertinoButton(
                onPressed: () {
                  displayingNotFoundDialog = false;
                  AppNavigation.pop();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    displayingNotFoundDialog = false;
    notifyListeners();
  }

  void pressCategory(CategoryData categoryData) =>
      _catalog.pressCategory(categoryData);

  void pressSubCategory(SubCategoryModel subModel) =>
      _catalog.pressSubCategory(subModel);

  void pressProduct(BuildContext context, ItemModel product, String where) {
    product.mark = null;
    addProduct(context: context, product: product, value: 1, where: where);
  }

  void pressPath(CategoryData categoryData) => _catalog.pressPath(categoryData);

  void pressAllPath() => _catalog.pressAllPath();

  void clearPathList() => _catalog.clearPathList();

  void changeGridviewItems(List<dynamic>? items) =>
      _catalog.changeGridviewItems(items);

  onClientSearchButtonPressedWithInn(BuildContext context) async {
    ClientBloc clientBloc = BlocProvider.of(context, listen: false);
    clientBloc.add(ClientInitialEvent());

    con = context;
    await showDialog(
      context: con!,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      builder: (con) => Builder(builder: (context) {
        return TransferWithInnDialog(
          context,
          client: _currentClient.selectedClient,
          onDelClientPressed: () {
            _currentClient.selectedClient = null;
            removeFromPaymentList();
            AppNavigation.pop();
            notifyListeners();
          },
        );
      }),
    );
    return;
  }
}
