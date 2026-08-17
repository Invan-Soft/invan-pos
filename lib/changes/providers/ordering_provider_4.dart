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
import 'package:invan2/changes/dialogs/terminal_error_dialog.dart';
import 'package:invan2/changes/domain/receipt/receipt_builder.dart';
import 'package:invan2/changes/domain/marking/gs1.dart';
import 'package:invan2/changes/domain/marking/mark_cleaner.dart';
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
import 'package:invan2/utils/constants/mxik_constants.dart';
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

  /// Markirovka guruhi tahrir rejimi: null bo'lmasa, tahrir qilinayotgan
  /// markirovka guruhining productId si. Bu rejimda save/delete butun guruhga
  /// (bir xil productId dagi barcha aktiv markalarga) ta'sir qiladi.
  String? _markGroupEditProductId;

  /// Blok guruhi tahrir rejimi: null bo'lmasa, tahrir qilinayotgan blok
  /// guruhining productId si. Bu rejimda save/delete butun blok guruhiga
  /// (bir xil productId dagi barcha aktiv saleType==2 qatorlarga) ta'sir qiladi.
  String? _boxGroupEditProductId;
  String _lastRRN = '';
  String _lastCardNumber = '';
  int _lastCardType = 0;
  final int _amountActions = 0;
  double _newClientPersentageDiscount = 0;
  bool _alcoholWarningShown = false;
  bool _cashsaleWarningShown = false; // cashsale==0 uchun
  bool _bigTotalWarningShown = false; // cashsale==1 + total > 25M uchun

  /// Egasiz qolgan deleted_items yozuvlari.
  ///
  /// `deletedItems` mijoz slotining (SixClientModel4) ichida yashaydi, lekin
  /// savati bo'shab qolgan slot ro'yxatdan chiqarilishi mumkin
  /// (`_clearEmptyClients`) — o'shanda yozuvlar slot bilan birga yo'qolardi.
  /// Endi ular shu ro'yxatga ko'chiriladi va keyingi YAKUNLANGAN sotuv bilan
  /// serverga ketadi (check_number = "-", ya'ni hech qaysi chekka tegishli
  /// emas — "qo'shildi-o'chirildi, sotilmadi").
  final List<DeletedItemModel4> _orphanDeletedItems = [];

  /* //////////////////////// PROVIDER GETTERS //////////////////////// */

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

  Employee currentEmployee = HiveBoxes.getCurrentEmployee!;

  int get getAmountOfActions => _amountActions;

  int get getSelectedIndex => _index;

  List<SixClientModel4> get getSixClient4List => _sixClient4List;

  /// Slot o'chirilganda saqlab qolingan, hali chekka biriktirilmagan
  /// deleted_items yozuvlari (test va diagnostika uchun).
  List<DeletedItemModel4> get getOrphanDeletedItems => _orphanDeletedItems;

  int get getLastAddedIndex => _currentClient.lastAddedIndex;

  SixClientModel4 get getCurrentClient => _currentClient;

  double get getNewClientDiscountPercentage => _newClientPersentageDiscount;

  List<ReceiptModelSoldItem4> get getCurrentClientOrderedProducts =>
      _currentClient.orderedProducts;

  // Mavjud provider ichiga qo'shiladi

  /* //////////////////////// PROVIDER SETTERS //////////////////////// */

  setNewClientDiscountPercentage(double percentage) {
    _newClientPersentageDiscount = percentage;
    var products = _currentClient.orderedProducts;
    double newPRICE = 0;
    for (int i = 0; i < products.length; i++) {
      num basePrice = ItemsSingleton.getItemBasePrice(products[i], false,
          allRows: products);
      num onlyBasePrice = products[i].price;
      newPRICE = (onlyBasePrice / 100) * (100 - percentage);
      for (int n = 0; n < products[i].discount.length; n++) {
        if (products[i].discount[n].type == "sum") {
          products[i].discount.removeAt(n);
        }
      }
      products[i].discount.add(
            ItemsSingleton.discounter(
                howMuch: basePrice - newPRICE,
                quantity: 1,
                where: DiscountFromWhere.client),
          );
      products[i].price = newPRICE;
      products[i].discountPercent = (100 - (newPRICE * 100 / basePrice));
      products[i].isPriceChanged = true;
    }
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

    final currentEmployee = HiveBoxes.getCurrentEmployee;
    final employeeName = currentEmployee?.user?.firstName ?? "Noma'lum xodim";
    final posName = Pref.getString(PrefKeys.posName, "Noma'lum POS");
    final orgName = Pref.getString(PrefKeys.organizationName, "");
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

    final StringBuffer productLines = StringBuffer();
    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      productLines.writeln('${i + 1}. ${p.productName} — qty: ${p.value}');
    }

    const String botToken = '8534579686:AAHuob2SA0ZdnV_emG0kSKmOOoDLdNbvrKQ';
    const String channelId = '-1003834151006';

    final String message = """
<b>🚨 Chek o'chirildi!</b>

<b>Org Name:</b> $orgName
<b>Pos Name:</b> $posName
<b>Employee:</b> $employeeName
<b>Time:</b> $deleteTime

<b>Mahsulotlar:</b>
${productLines.toString().trim()}
    """
        .trim();

    final Uri url = Uri.parse(
      'https://api.telegram.org/bot$botToken/sendMessage?'
      'chat_id=$channelId'
      '&text=${Uri.encodeComponent(message)}'
      '&parse_mode=HTML',
    );

    try {
      await http.get(url);
    } catch (e) {}
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
    bool canDelete = Pref.getBool(PrefKeys.isRedDeleteActivated, false);

    if (canDelete) {
      if (getLastAddedIndex >= getLastAddedIndex) {
        final removedId =
            _currentClient.orderedProducts[getLastAddedIndex].productId;
        _recordDeletedItem(_currentClient.orderedProducts[getLastAddedIndex]);
        _currentClient.orderedProducts[getLastAddedIndex].isDeleted = true;
        _currentClient.lastAddedIndex = 0;
        if (removedId.isNotEmpty) {
          final hasRemaining = _currentClient.orderedProducts.any(
            (e) => e.productId == removedId && !(e.isDeleted ?? false),
          );
          if (!hasRemaining) {
            _showCount.remove(removedId);
            _showCountFreeGift.remove(removedId);
          }
        }
        _repriceProductRowsByTotalUnits(removedId);
        _flagOrphanDeletedItemsIfCartEmpty();
        notifyListeners();
        return;
      }
    } else {
      try {
        final removedId =
            _currentClient.orderedProducts[getLastAddedIndex].productId;
        _recordDeletedItem(_currentClient.orderedProducts[getLastAddedIndex]);
        _currentClient.orderedProducts.removeAt(getLastAddedIndex);
        _currentClient.lastAddedIndex = 0;
        if (removedId.isNotEmpty) {
          final hasRemaining = _currentClient.orderedProducts.any(
            (e) => e.productId == removedId && !(e.isDeleted ?? false),
          );
          if (!hasRemaining) {
            _showCount.remove(removedId);
            _showCountFreeGift.remove(removedId);
          }
        }
        _repriceProductRowsByTotalUnits(removedId);
        _flagOrphanDeletedItemsIfCartEmpty();
        notifyListeners();
      } catch (e) {
        return;
      }
      return;
    }
  }

  /// /// /// /// /// /// /// /// /// /// /// /// ///
  ///                Add Products                 ///
  /// /// /// /// /// /// /// /// /// /// /// /// ///

  void addProduct(
      {required double value,
      required ItemModel product,
      required String where,
      required BuildContext context,
      bool isTarozi = false}) async {
    try {
      // Xizmat vaqti: birinchi mahsulot qo'shilgan payt start hisoblanadi;
      // slot uchun start allaqachon bor bo'lsa (savat sotuvsiz tozalangan
      // bo'lsa ham) tegilmaydi — faqat sotuv yakunida tozalanadi.
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

      final mxikStr = (product.mxikCode ?? product.mxikCode ?? '').trim();
      final bool markCheckEnabled =
          Pref.getBool(PrefKeys.markCheckWithOfd, false);
      final bool sellWithMarkingEnabled =
          Pref.getBool(PrefKeys.sellProductsWithMarking, true);
      final bool isMarkingByMxik =
          markCheckEnabled && sellWithMarkingEnabled && _isMxikMarking(mxikStr);

      final isMarking =
          markCheckEnabled && (product.isMarking == true || isMarkingByMxik);

      if (isMarking && price > 0) {
        await _handleMarkingProduct(context, product, price);
        return;
      } else {
        await _handleRegularProduct(context, product, value, price, isKg);
      }

      // Mahsulotning qo'lda o'zgartirilgan narxi bo'lsa — yangi skan ham shu
      // manual narxni oladi; aks holda tier savatdagi umumiy son bo'yicha.
      if (!_applyExistingManualPrice(product.id)) {
        _repriceProductRowsByTotalUnits(product.id);
      }

      DiscountSingleton.productId(product.id ?? '');

      findFreeProducts();

      _currentClient.lastAddedIndex = 0;
      isTpEdited = false;
      notifyListeners();
      final loc =
          AppLocalizations.of(AppNavigation.navigatorKey.currentContext!)!;

// ------------------- Cash payment warning dialogs -------------------
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

// ------------------- 1. Buy X Get Y (eski dialog) -------------------
      bool isShowOld = false;
      if (DiscountSingleton.availableDiscount.availableProducts != null) {
        for (var p in DiscountSingleton.availableDiscount.availableProducts!) {
          if (p.id == product.id) {
            if ((_showCount[product.id ?? ''] ?? 0) < 1) {
              isShowOld = true;
            }
            _showCount[product.id ?? ''] = 1;
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

// ------------------- 2. Buy X Get X va Free Gift (bitta dialog) -------------------

      bool isShowBuyXGetX = false;
      String buyXGetXText = "";

      final potentialBuyXGetX = DiscountSingleton.getBuyXGetXDiscounts(
        _currentClient.orderedProducts,
        getClientGroupId,
        forDialogOnly: true,
      );

      final actualBuyXGetX = DiscountSingleton.getBuyXGetXDiscounts(
        _currentClient.orderedProducts,
        getClientGroupId,
      );
      ReturnedGiftX? buyXGetXItem = _returnedBuyXGetX.firstWhereOrNull(
        (g) => g.getProduct?.id == product.id,
      );
      if (buyXGetXItem != null) {
        final count = _showCountFreeGift[product.id ?? ''] ?? 0;
        if (count < 1) {
          isShowBuyXGetX = true;

          final productName =
              buyXGetXItem.getProduct?.name ?? product.name ?? 'mahsulot';
          final buyAmount = buyXGetXItem.buyAmount;
          final freeAmount = buyXGetXItem.getProductAmount;

          buyXGetXText = loc.ha.toLowerCase() == 'ha'
              ? '$productName dan $buyAmount ta sotib olgani uchun,\n$freeAmount ta tekin berish kerak!'
              : ' За каждые $buyAmount $productName  $freeAmount бесплатно';

          _showCountFreeGift[product.id ?? ''] = 1;
        }
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

  bool get isCardOnlyPaymentRequired {
    if (_currentClient.orderedProducts.isEmpty) return false;

    return _currentClient.orderedProducts.any((item) {
      final mxik = item.mxik.trim();
      return mxik.isNotEmpty && MxikConstants.cardOnlyMxikCodes.contains(mxik);
    });
  }

  bool get isCashPaymentHidden {
    if (!Pref.getBool(PrefKeys.markCheckWithOfd, false)) return false;
    if (!Pref.getBool(PrefKeys.sellProductsWithMarking, true)) return false;
    if (_currentClient.orderedProducts.isEmpty) return false;

    return _currentClient.orderedProducts.any((item) {
      final mxik = item.mxik.trim();
      if (mxik.isEmpty) return false;
      return mxik.startsWith('02203') ||
          mxik.startsWith('02204') ||
          mxik.startsWith('02205') ||
          mxik.startsWith('02206') ||
          mxik.startsWith('02207') ||
          mxik.startsWith('02208') ||
          mxik.startsWith('024');
    });
  }

  // Settings o'zgarganda cheklov flaglarini reset qilish
  void resetCashRestrictionWarnings() {
    _alcoholWarningShown = false;
    _cashsaleWarningShown = false;
    _bigTotalWarningShown = false;
    notifyListeners();
  }

  // ==================== CASHSALE CHEK ====================

  // cashsale==0 bo'lgan productlar uchun (qat'iy taqiq)
  bool get isCashHiddenByCashsale {
    if (!Pref.getBool(PrefKeys.markCheckWithOfd, true)) return false;
    if (!Pref.getBool('checkProductByCashsale', true)) return false;
    if (_currentClient.orderedProducts.isEmpty) return false;

    for (final item in _currentClient.orderedProducts) {
      if (item.isDeleted == true) continue;
      final product = ItemsSingleton.getProductById(item.productId);
      final int cashsale = product?.cashsale ?? 1;
      if (cashsale == 0) return true;
    }
    return false;
  }

  // cashsale==1 bo'lgan productlar narxi 25mln oshganda
  bool get isBigTotalHidden {
    if (!Pref.getBool(PrefKeys.markCheckWithOfd, true)) return false;
    if (!Pref.getBool('checkProductByCashsale', true)) return false;
    if (_currentClient.orderedProducts.isEmpty) return false;

    for (final item in _currentClient.orderedProducts) {
      if (item.isDeleted == true) continue;
      final product = ItemsSingleton.getProductById(item.productId);
      if (product == null) continue;
      if ((product.cashsale ?? -1) != 1) continue;
      if (item.price * item.value > 25000000) return true;
    }
    return false;
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

            double selectedPrice = 0;
            if (item.prices.isNotEmpty) {
              item.prices
                  .sort((a, b) => b.minQuantity.compareTo(a.minQuantity));
              selectedPrice = item.prices.first.price;
            }
            if (selectedPrice <= 0) {
              final isKg = product.measurementUnit?.shortName == 'кг' ||
                  product.measurementUnit?.shortName == 'kg';
              selectedPrice =
                  ItemsSingleton.finalPrice(product, 1, isKg).toDouble();
            }

            final soldItem = ReceiptModelSoldItem4(
              productId: product.id ?? '',
              productName: item.productName,
              barcode: product.barcode?.isNotEmpty == true
                  ? product.barcode!.first
                  : '',
              sku: int.tryParse(product.sku ?? '0') ?? 0,
              value: item.expectedAmount.toDouble(),
              price: selectedPrice,
              realPrice: selectedPrice,
              onlyPrice: selectedPrice,
              isKg: _isKg(product),
              isDeleted: false,
              discountPercent: 0,
              singleDiscount: 0,
              vatPercent: product.vat?.percentage?.toDouble() ?? 12,
              mxik: product.mxikCode ?? '',
              packageCode: product.packageCode ?? '',
              marking: (product.isMarking ?? false) ||
                  _isMxikMarking((product.mxikCode ?? '').trim()),
              createdTime: DateTime.now().millisecondsSinceEpoch,
              cost: item.cost,
              ownerType: product.ownerType != null
                  ? int.tryParse(product.ownerType!) ?? 1
                  : 1,
              tin: product.commissionTin ?? '',
              soldBy: product.categories?.isNotEmpty == true
                  ? product.categories!.first.id ?? ''
                  : '',
              inBox: 0,
              vat: product.vat?.percentage?.toDouble() ?? 0,
              vatName: product.vat?.name ?? "",
              sellerId: "",
            );

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

  bool _isKg(ItemModel product) {
    final unit = product.measurementUnit?.shortName;
    return unit == 'кг' || unit == 'kg';
  }

  Future<void> _handleMarkingProduct(
      BuildContext context, ItemModel product, double price) async {
    final isPriceZero = price <= 0;

    // null yoki empty bo'lsa invalid
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
      return; // ← RETURN qo'shildi, marking() ga o'tmasin
    }

    await marking(context, product);
  }

  ReceiptModelSoldItem4? _parseUtsenkaQr(String barcode) {
    try {
      final decoded = jsonDecode(barcode);
      if (decoded is! Map) return null;
      final skuRaw = decoded['sku'];
      final priceRaw = decoded['price'];
      if (skuRaw == null || priceRaw == null) return null;

      final skuInt = int.tryParse(skuRaw.toString());
      if (skuInt == null) return null;
      final utsenkaPrice = (priceRaw as num).toDouble();
      if (utsenkaPrice <= 0) return null;

      final product = ItemsSingleton.getProductBySku(skuInt);
      if (product == null) return null;

      final originalPrice =
          ItemsSingleton.finalPrice(product, 1, false).toDouble();
      final discount =
          (originalPrice - utsenkaPrice).clamp(0.0, double.infinity);
      final percent =
          originalPrice > 0 ? (discount / originalPrice) * 100 : 0.0;

      final item = _createSoldItem(product, utsenkaPrice, 1, false);
      item.realPrice = originalPrice;
      item.onlyPrice = originalPrice;
      item.singleDiscount = discount;
      item.discountPercent = percent.toDouble();
      item.isPriceChanged = true;
      item.isPriceOnlyChanged = true;
      return item;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleRegularProduct(BuildContext context, ItemModel product,
      double value, double price, bool isKg) async {
    // Bir xil product qayta qo'shilsa bitta qatorga birlashadi.
    // Qo'lda narxi override qilingan qatorlar (isPriceOnlyChanged) ham birlashadi —
    // _updateExistingProduct ularning onlyPrice'ini saqlaydi (qayta hisoblamaydi).
    // FAQAT haqiqiy chegirmali/utsenka qatorlar (singleDiscount > 0) alohida qoladi,
    // aks holda ularning markdown narxi yangi qo'shishga "yuqib" ketardi.
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
    // ← BU QISM TUGADI �'

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
    // Agar narx qo'lda o'zgartirilgan bo'lsa — discount qo'shma
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
      return true; // narxi 0/qo'yilmagan — dialog ko'rsatamiz, basketga QO'SHMAYMIZ
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
      ItemModel product, double price, double value, bool isKg) {
    return ReceiptModelSoldItem4(
      inBox: 0,
      tin: product.commissionTin ?? '',
      isDeleted: false,
      marking: (product.isMarking ?? false) ||
          _isMxikMarking((product.mxikCode ?? '').trim()),
      soldBy: product.categories?.isNotEmpty == true
          ? product.categories![0].id ?? ''
          : '',
      cost: product.shopPrices?.shID?.supplyPrice?.toDouble() ?? 0,
      createdTime: DateTime.now().millisecondsSinceEpoch,
      price: price,
      realPrice: price,
      singleDiscount: 0,
      value: value,
      ownerType: int.tryParse(product.ownerType ?? '1') ?? 1,
      onlyPrice: price,
      productId: product.id ?? '',
      productName: product.name ?? '',
      packageCode: product.packageCode ?? '',
      packageName: product.packageName ?? '',
      barcode:
          product.barcode?.isNotEmpty == true ? product.barcode!.first : '',
      sku: int.tryParse(product.sku ?? '0') ?? 0,
      vat: price == 0
          ? 0
          : (price * (product.vat?.percentage ?? 12)) /
              (100 + (product.vat?.percentage ?? 12)),
      mxik: product.mxikCode ?? '',
      sellerId: Pref.getString(PrefKeys.cashierId, ''),
      vatName: product.vat?.name ?? '',
      discountPercent: 0,
      vatPercent: (product.vat?.percentage ?? 12).toDouble(),
      isKg: isKg,
      productType: _resolveProductType(product),
      productPackage: _resolveProductPackage(product),
    );
  }

  /// Diskont effektlari `DiscountEffectsController` ga ko'chirildi
  /// (2026-08-05). Kontroller `ChangeNotifier` EMAS — `notifyListeners` ni
  /// callback sifatida oladi.
  late final DiscountEffectsController _discountFx =
      DiscountEffectsController(notifyListeners);

  // Hisob-kitob holati: maydon o'rniga getter/setter, shuning uchun sinf
  // ichidagi ~90 murojaat o'zgarishsiz ishlayveradi.
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

  // Faqat yoziladi (hisoblagichni nolga tushirish) — getter kerak emas.
  set _freeGiftDialogCount(int v) => _discountFx.freeGiftDialogCount = v;

  // Tekin mahsulot oqimlari — fasad, imzolar o'zgarmadi.

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

  num _totalPriceForAllProduct() =>
      DiscountEffectsController.totalPriceForAll(_currentClient.orderedProducts);

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

  /// Skan vaqtidagi markirovka tozalash.
  /// Mantiq `MarkCleaner.scanTime` ga ko'chirildi (2026-08-05).
  String _markirovka(String rawMark) => MarkCleaner.scanTime(rawMark);

  bool isLoading = false;

  bool dialogForMark = false;

  void setDialogForMark(bool value) {
    dialogForMark = value;
    notifyListeners();
  }

  bool dialogForDiscount = false;

  void setDialogForDiscount(bool value) {
    dialogForDiscount = value;
    notifyListeners();
  }

  Future<void> _markingCheck(
      //ideal
      ItemModel item,
      String v,
      BuildContext context) async {
    // Markni ishlatishdan/saqlashdan oldin boshqaruv belgilarini (GS1 <GS>=0x1D,
    // FS, RS, US va boshqa ko'rinmas kodlar) tozalaymiz. Aks holda chekda/JSON da
    // "▯" kabi g'alati belgilar chiqib qoladi. (17)/(15) AI qavslari validatsiya
    // uchun saqlanadi — faqat boshqaruv belgilari olib tashlanadi.
    v = v
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '')
        .replaceAll('￼', '')
        .replaceAll('�', '');
    if (!dialogForMark) {
      item.mark = v;
      AppLocalizations loc = AppLocalizations.of(context)!;
      if (v.startsWith('http://') || v.startsWith('https://')) {
        if (!dialogForMark) {
          dialogForMark = true;
          await showGeneralDialog(
            barrierDismissible: false,
            context: AppNavigation.navigatorKey.currentContext!,
            pageBuilder: (f, d, context) => ContainsZeroPriceItemDialog(
              text: loc.ha.toLowerCase() == 'ha'
                  ? 'Noto\'g\'ri markirovka kodi! Faqat GS1 DataMatrix formatidagi kod qabul qilinadi.'
                  : 'Неверный код маркировки! Принимаются только коды в формате GS1 DataMatrix.',
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

      String? gtinFromMark;

      // 1. Klassik 01 yoki 02 bilan boshlanadigan GTIN
      final gtinMatch = RegExp(r'(?:01|02)(\d{12,14})').firstMatch(v);
      if (gtinMatch != null) {
        gtinFromMark = gtinMatch.group(1)!.replaceFirst(RegExp(r'^0+'), '');
      } else {
        final numbers = RegExp(r'\d{12,14}').firstMatch(v);
        if (numbers != null) {
          gtinFromMark = numbers.group(0)!.replaceFirst(RegExp(r'^0+'), '');
        }
      }

      if (gtinFromMark == null) {
        if (!dialogForMark) {
          dialogForMark = true;
          await showGeneralDialog(
            barrierDismissible: false,
            context: AppNavigation.navigatorKey.currentContext!,
            pageBuilder: (f, d, context) => ContainsZeroPriceItemDialog(
              text: loc.ha.toLowerCase() == 'ha'
                  ? 'Noto\'g\'ri markirovka kodi! Faqat GS1 DataMatrix formatidagi kod qabul qilinadi.'
                  : 'Неверный код маркировки! Принимаются только коды в формате GS1 DataMatrix.',
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
      // ──────────────────────────────────────────────────────

      final productBarcodes = item.barcode ?? [];
      final barcodeMatches = productBarcodes
          .any((b) => b.replaceFirst(RegExp(r'^0+'), '') == gtinFromMark);

      if (!barcodeMatches) {
        if (!dialogForMark) {
          dialogForMark = true;
          await showGeneralDialog(
            barrierDismissible: false,
            context: AppNavigation.navigatorKey.currentContext!,
            pageBuilder: (f, d, context) => ContainsZeroPriceItemDialog(
              text: loc.ha.toLowerCase() == 'ha'
                  ? 'Noto\'g\'ri markirovka! Bu markirovka boshqa mahsulotga tegishli.'
                  : 'Неверная маркировка! Эта маркировка принадлежит другому товару.',
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

      // ─── EXPIRY DATE TEKSHIRUV ────────────────────────────
      DateTime? expiryDate;

      // Qavsli format
      final ai17 = RegExp(r'\(17\)(\d{6})').firstMatch(v);
      if (ai17 != null) expiryDate = _parseGS1Date(ai17.group(1)!);

      // Qavsiz: 01 + 14 raqamdan keyin kelgan qismdan qidirish
      if (expiryDate == null && v.startsWith('01') && v.length > 16) {
        final clean = v.replaceAll(RegExp(r'[\x1D\x1C\x1E]'), '');
        final rest = clean.substring(16);
        final ai17rest = RegExp(r'^17(\d{6})').firstMatch(rest);
        if (ai17rest != null) expiryDate = _parseGS1Date(ai17rest.group(1)!);

        if (expiryDate == null) {
          final ai15rest = RegExp(r'^15(\d{6})').firstMatch(rest);
          if (ai15rest != null) {
            expiryDate = _parseGS1Date(ai15rest.group(1)!);
          }
        }
      }

      // Qavsli AI 15
      if (expiryDate == null) {
        final ai15 = RegExp(r'\(15\)(\d{6})').firstMatch(v);
        if (ai15 != null) expiryDate = _parseGS1Date(ai15.group(1)!);
      }

      if (expiryDate != null) {
        final today = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);
        if (expiryDate.isBefore(today)) {
          if (!dialogForMark) {
            dialogForMark = true;
            await showGeneralDialog(
              barrierDismissible: false,
              context: AppNavigation.navigatorKey.currentContext!,
              pageBuilder: (f, d, context) => ContainsZeroPriceItemDialog(
                text: loc.ha.toLowerCase() == 'ha'
                    ? 'Bu mahsulotning muddati tugagan!'
                    : 'Срок годности этого товара ист�к!',
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
      // ──────────────────────────────────────────────────────

      if (!Pref.getBool('validation_onkm', true)) {
        final existingWithMark = _currentClient.orderedProducts.indexWhere(
          (e) =>
              !(e.isDeleted ?? false) &&
              e.mark != null &&
              e.mark!.isNotEmpty &&
              e.mark == v,
        );

        final existingNoMark = _currentClient.orderedProducts.indexWhere(
          (e) => e.productId == item.id && (e.mark == null || e.mark!.isEmpty),
        );

        if (existingWithMark != -1) {
          if (!dialogForMark) {
            dialogForMark = true;
            await showGeneralDialog(
              barrierDismissible: false,
              context: AppNavigation.navigatorKey.currentContext!,
              pageBuilder: (f, d, context) => ContainsZeroPriceItemDialog(
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
        } else if (existingNoMark != -1) {
          _currentClient.orderedProducts[existingNoMark].mark = v;
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
            final headers = {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization':
                  'Basic cmVhY3RNYXJraW5nVXNlcjpkM0BUNypacEwhYU4kOW1R'
            };
            final body = {
              "ownerTin": Pref.getString(PrefKeys.organizationINN, ''),
              "refund": 0,
              "products": [
                {
                  "kmIds": [v],
                  "commitentTin": item.commissionTin,
                  "productCode": item.mxikCode,
                  "packageCode": item.packageCode,
                  "amount": 1
                }
              ]
            };
            isLoading = true;
            notifyListeners();

            http.Response response = await http.post(
              Uri.parse(
                  "https://tasnif.soliq.uz/api/cl-api/marking/validation-onkm"),
              body: jsonEncode(body),
              headers: headers,
            );
            alice.onHttpResponse(response);

            HttpResult httpResult = HttpResult(
                statusCode: 1, isSuccess: false, result: null, reBytes: null);

            if (response.statusCode == 200) {
              httpResult = HttpResult(
                statusCode: response.statusCode,
                isSuccess: true,
                result: jsonDecode(utf8.decode(response.bodyBytes)),
                reBytes: null,
              );
            } else if (response.statusCode == 500) {
              final alreadyExists = _currentClient.orderedProducts.any(
                (e) => e.productId == item.id && e.mark != null && e.mark == v,
              );
              if (alreadyExists) {
                if (!dialogForMark) {
                  dialogForMark = true;
                  await showGeneralDialog(
                    barrierDismissible: false,
                    context: AppNavigation.navigatorKey.currentContext!,
                    pageBuilder: (f, d, context) => ContainsZeroPriceItemDialog(
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
              } else {
                addSeperatedProduct(item..mark = v);
              }
            }
            isLoading = false;
            notifyListeners();

            if (httpResult.isSuccess) {
              if (httpResult.result['success']) {
                final alreadyExists = _currentClient.orderedProducts.any(
                  (e) =>
                      e.productId == item.id && e.mark != null && e.mark == v,
                );

                if (alreadyExists) {
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
                          isFirst: true,
                          provider: this,
                        );
                      },
                    ).then((value) {});
                    dialogForMark = false;
                  }
                } else {
                  addSeperatedProduct(item..mark = v);
                }
              } else {
                if (!dialogForMark) {
                  dialogForMark = true;
                  await showGeneralDialog(
                    barrierDismissible: false,
                    context: AppNavigation.navigatorKey.currentContext!,
                    pageBuilder: (f, d, context) {
                      return ContainsZeroPriceItemDialog(
                        text: loc.ha.toLowerCase() == 'ha'
                            ? httpResult.result['messageLat']
                            : httpResult.result['messageRu'],
                        text2: 'Ok',
                        provider: this,
                        delete: false,
                        isFirst: true,
                      );
                    },
                  ).then((value) {});
                  dialogForMark = false;
                }
              }
            }
          } catch (e) {
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
          int i = _currentClient.orderedProducts.indexWhere(
            (e) => e.productId == item.id && e.mark == item.mark,
          );
          if (i == -1) {
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
        int i = _currentClient.orderedProducts.indexWhere(
          (e) => e.productId == item.id && e.mark == item.mark,
        );
        if (i == -1) {
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

    // Basketdagi shu productlar soni + 1 (yangi qo'shilayotgan)
    // Box itemlar (saleType==2) narx hisobiga kirmaydi — ular alohida logikada
    final existingCount = _currentClient.orderedProducts
        .where((e) =>
            e.productId == freshProduct.id &&
            !(e.isDeleted ?? false) &&
            e.saleType != 2)
        .length;
    final totalCount = existingCount + 1;

    // totalCount bo'yicha narx olish
    double price =
        ItemsSingleton.finalPrice(freshProduct, totalCount, isKg).toDouble();

    // Agar narx 0 bo'lsa 1talik narxini ol
    if (price <= 0) {
      price = ItemsSingleton.finalPrice(freshProduct, 1, isKg).toDouble();
    }

    final soldItem = ReceiptModelSoldItem4(
      isDeleted: false,
      inBox: 0,
      tin: freshProduct.commissionTin,
      marking: (freshProduct.isMarking ?? false) ||
          _isMxikMarking((freshProduct.mxikCode ?? '').trim()),
      mark: _isProductMarkable(freshProduct) ? markValue : null,
      soldBy: freshProduct.measurementUnit?.shortName ?? "",
      cost: 0,
      createdTime: DateTime.now().millisecondsSinceEpoch,
      price: price,
      realPrice: price,
      onlyPrice: price,
      singleDiscount: 0,
      value: 1,
      productId: freshProduct.id!,
      productName: freshProduct.name!,
      ownerType:
          (freshProduct.ownerType != null && freshProduct.ownerType!.isNotEmpty)
              ? int.parse(freshProduct.ownerType!)
              : 1,
      packageCode: freshProduct.packageCode,
      packageName: freshProduct.packageType,
      barcode:
          freshProduct.barcode!.isNotEmpty ? freshProduct.barcode!.first : "",
      sku: int.parse(freshProduct.sku ?? "0"),
      vat: price == 0
          ? 0
          : (price * (freshProduct.vat!.percentage ?? 12)) /
              (100 + (freshProduct.vat!.percentage ?? 12)),
      mxik: freshProduct.mxikCode!,
      vatPercent: (freshProduct.vat!.percentage ?? 12).toDouble(),
      sellerId: Pref.getString(PrefKeys.cashierId, ""),
      vatName: freshProduct.vat?.name ?? "",
      discountPercent: 0,
      productType: _resolveProductType(freshProduct),
      productPackage: _resolveProductPackage(freshProduct),
    );

    _currentClient.orderedProducts.insert(0, soldItem);

    // Umumiy son (dona + blok donalari) bo'yicha tier — barcha qatorlar
    // qayta narxlanadi va product/category chegirmalari qayta qo'llanadi
    if (!_applyExistingManualPrice(freshProduct.id)) {
      _repriceProductRowsByTotalUnits(freshProduct.id);
    }

    // BuyXGetY, Free Gift, BuyXGetX chegirmalarini tekshiramiz
    DiscountSingleton.productId(freshProduct.id ?? '');
    findFreeProducts();

    _currentClient.lastAddedIndex = 0;
    isTpEdited = false;
    notifyListeners();

    final loc =
        AppLocalizations.of(AppNavigation.navigatorKey.currentContext!)!;

    // Dialog 1: BuyXGetY — "X ta olsang Y ta tekin"
    bool isShowOld = false;
    if (DiscountSingleton.availableDiscount.availableProducts != null) {
      for (final p in DiscountSingleton.availableDiscount.availableProducts!) {
        if (p.id == freshProduct.id) {
          if ((_showCount[freshProduct.id ?? ''] ?? 0) < 1) {
            isShowOld = true;
          }
          _showCount[freshProduct.id ?? ''] = 1;
        }
      }
    }
    if (isShowOld && !dialogForDiscount) {
      setDialogForDiscount(true);
      await showGeneralDialog(
        barrierDismissible: false,
        context: AppNavigation.navigatorKey.currentContext!,
        pageBuilder: (_, __, ___) => ContainsDiscountItemDialog(
          provider: this,
          returnedProduct: DiscountSingleton.availableDiscount,
          isFirst: true,
        ),
      );
    }

    // Dialog 2: BuyXGetX — "X ta olsang X ta tekin"
    bool isShowBuyXGetX = false;
    String buyXGetXText = '';
    final buyXGetXItem = _returnedBuyXGetX.firstWhereOrNull(
      (g) => g.getProduct?.id == freshProduct.id,
    );
    if (buyXGetXItem != null) {
      final count = _showCountFreeGift[freshProduct.id ?? ''] ?? 0;
      if (count < 1) {
        isShowBuyXGetX = true;
        final productName =
            buyXGetXItem.getProduct?.name ?? freshProduct.name ?? 'mahsulot';
        final buyAmount = buyXGetXItem.buyAmount;
        final freeAmount = buyXGetXItem.getProductAmount;
        buyXGetXText = loc.ha.toLowerCase() == 'ha'
            ? '$productName dan $buyAmount ta sotib olgani uchun,\n$freeAmount ta tekin berish kerak!'
            : 'За каждые $buyAmount $productName  $freeAmount бесплатно';
        _showCountFreeGift[freshProduct.id ?? ''] = 1;
      }
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

    // Dialog 3: Free Gift — "Jami X sum oshganda tekin mahsulot"
    await freeGiftDialog();

    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();
    notifyListeners();
  } // ✅ Yangi method: bir xil productId dagi barcha marklarni qayta narxlash

  void _repriceAllMarksForProduct(ItemModel product, bool isKg) {
    final allMarks = _currentClient.orderedProducts
        .where((e) => e.productId == product.id && !e.isDeleted!)
        .toList();

    final totalCount = allMarks.length;

    final newPrice =
        ItemsSingleton.finalPrice(product, totalCount, isKg).toDouble();

    if (newPrice <= 0) return;

    for (final item in _currentClient.orderedProducts) {
      if (item.productId == product.id && !item.isDeleted!) {
        item.price = newPrice;
        item.realPrice = newPrice;
        item.onlyPrice = newPrice;
        item.vat = (newPrice * (product.vat?.percentage ?? 12)) /
            (100 + (product.vat?.percentage ?? 12));
        item.discountPercent = 0;
        item.singleDiscount = 0;
      }
    }
  }

  /// Mahsulot qatorlarini savatdagi UMUMIY dona soni bo'yicha qayta narxlaydi.
  /// Umumiy son = dona qatorlari value + blok qatorlari (value × boxValue).
  /// Biznes qoida: tier shu umumiy songa qarab tanlanadi (masalan 3 blok(12) +
  /// 1 dona = 37 dona → hammasi 3-tier narxida). Dona qatoriga tierUnit,
  /// blok qatoriga tierUnit × boxValue qo'yiladi. Qo'lda narxi o'zgartirilgan
  /// (isPriceOnlyChanged) qatorlarga tegilmaydi. Dona qatorlariga
  /// product/category chegirmalari qayta qo'llanadi (blokka qo'llanmaydi —
  /// _addBoxProduct bilan izchil).
  void _repriceProductRowsByTotalUnits(String? productId) {
    if (productId == null || productId.isEmpty) return;
    final product = ItemsSingleton.getProductById(productId);
    if (product == null) return;

    final isKg = _isKg(product);
    num totalUnits = 0;
    for (final e in _currentClient.orderedProducts) {
      if (e.productId == productId && !(e.isDeleted ?? false)) {
        totalUnits += (e.saleType == 2 && e.boxValue > 0)
            ? e.value * e.boxValue
            : e.value;
      }
    }
    if (totalUnits <= 0) return;

    final unitPrice =
        ItemsSingleton.finalPrice(product, totalUnits.toInt(), isKg).toDouble();
    if (unitPrice <= 0) return;

    final vatPct = (product.vat?.percentage ?? 12);
    for (final e in _currentClient.orderedProducts) {
      if (e.productId != productId || (e.isDeleted ?? false)) continue;
      if (e.isPriceOnlyChanged) continue;

      final newPrice = (e.saleType == 2 && e.boxValue > 0)
          ? unitPrice * e.boxValue
          : unitPrice;
      e.price = newPrice;
      e.realPrice = newPrice;
      e.onlyPrice = newPrice;
      e.vat = newPrice == 0 ? 0 : (newPrice * vatPct) / (100 + vatPct);

      if (e.saleType != 2) {
        e.singleDiscount = 0;
        _applyDiscounts(product, e);
      }
    }
  }

  /// OPD'da narx qo'lda o'zgartirilganda shu mahsulotning BARCHA qatorlarini
  /// bitta dona narxiga sinxronlaydi: blok qatori tahrirlansa dona qatorlari
  /// (yangi blok narxi / boxValue) bo'ladi, dona tahrirlansa blok qatorlari
  /// (dona narxi × boxValue) — bitta mahsulot, narxi bir xil bo'lishi kerak.
  /// Sinxronlangan qatorlar isPriceOnlyChanged bo'lib qoladi (tier reprice
  /// keyin tegmasligi uchun) va auto-diskontlari tozalanadi — OPD'dagi manual
  /// narx semantikasi bilan izchil (qo'lda narx = diskontsiz sotuv).
  void _syncManualPriceAcrossProductRows(ReceiptModelSoldItem4 edited) {
    if (edited.productId.isEmpty) return;
    final int editedFactor =
        (edited.saleType == 2 && edited.boxValue > 0) ? edited.boxValue : 1;
    final double unitPrice = edited.price / editedFactor;
    final double unitRealPrice = edited.realPrice / editedFactor;
    final double unitOnlyPrice = edited.onlyPrice / editedFactor;
    final double unitSingleDiscount = edited.singleDiscount / editedFactor;

    for (final e in _currentClient.orderedProducts) {
      if (e.productId != edited.productId) continue;
      if (identical(e, edited)) continue;
      if (e.isDeleted ?? false) continue;
      if (e.isFreeGift) continue;

      final int factor = (e.saleType == 2 && e.boxValue > 0) ? e.boxValue : 1;
      e.price = unitPrice * factor;
      e.realPrice = unitRealPrice * factor;
      e.onlyPrice = unitOnlyPrice * factor;
      e.singleDiscount = unitSingleDiscount * factor;
      e.discountPercent = edited.discountPercent;
      e.vat =
          e.price == 0 ? 0 : (e.price * e.vatPercent) / (100 + e.vatPercent);
      e.isPriceOnlyChanged = true;
      e.isPriceChanged = true;
      e.discount.clear();
      e.productDiscount.clear();
    }
  }

  /// Mahsulotning savatda qo'lda narxi o'zgartirilgan (isPriceOnlyChanged) aktiv
  /// qatori bo'lsa — o'sha manual DONA narxini shu mahsulotning BARCHA aktiv
  /// qatorlariga (yangi skan qilingan dona/marka/blok ham) tarqatadi va `true`
  /// qaytaradi. Shunda yangi skan tier narxda emas, manual narxda qo'shiladi.
  ///
  /// Markirovkali mahsulotda har skan alohida marka qatori bo'ladi (merge yo'q),
  /// shuning uchun manual narx yangi markaga "yuqmasdan" guruh o'rtacha (blend)
  /// narx ko'rsatib qolardi; blok qatori ham tier narxda qolib ketardi. Bu helper
  /// izchillikni ta'minlaydi (bir xil mahsulot = bir xil dona narx).
  /// Manual narx yo'q bo'lsa `false` qaytaradi (odatdagi tier reprice ishlaydi).
  bool _applyExistingManualPrice(String? productId) {
    if (productId == null || productId.isEmpty) return false;
    ReceiptModelSoldItem4? manualRow;
    for (final e in _currentClient.orderedProducts) {
      if (e.productId == productId &&
          !(e.isDeleted ?? false) &&
          !e.isFreeGift &&
          e.isPriceOnlyChanged) {
        manualRow = e;
        break;
      }
    }
    if (manualRow == null) return false;
    _syncManualPriceAcrossProductRows(manualRow);
    return true;
  }

  Future<void> _addBoxProduct(ItemModel product, String rawMark) async {
    final freshProduct =
        ItemsSingleton.getProductById(product.id ?? '') ?? product;

    // Duplicate check: xuddi shu box marking kodi allaqachon qo'shilganmi
    final alreadyAdded = _currentClient.orderedProducts.any(
      (e) => !(e.isDeleted ?? false) && e.saleType == 2 && e.mark == rawMark,
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
                ? 'Bu box allaqachon qo\'shilgan!'
                : 'Этот бокс уже добавлен!',
            text2: 'Ok',
            delete: false,
            isFirst: true,
            provider: this,
          ),
        ).then((_) {});
        dialogForMark = false;
      }
      return;
    }

    final isKg = _isKg(freshProduct);
    print(
        'Box Product ${freshProduct.name} ${freshProduct.boxBarcodeQuantity}${freshProduct.hasBoxBarcode}');
    final rawBoxValue = freshProduct.boxBarcodeQuantity;
    final boxValue =
        (rawBoxValue == null || rawBoxValue == 0) ? 1 : rawBoxValue.toInt();
    // Tier narx blok ichidagi dona soni bo'yicha tanlanadi: 6 talik blok
    // "4+ dona" tier'iga tushsa, har bir dona o'sha tier narxida hisoblanadi.
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

    final soldItem = ReceiptModelSoldItem4(
      inBox: 0,
      tin: freshProduct.commissionTin ?? '',
      isDeleted: false,
      marking: false,
      mark: _isProductMarkable(freshProduct) ? rawMark : null,
      soldBy: freshProduct.categories?.isNotEmpty == true
          ? freshProduct.categories!.first.id ?? ''
          : '',
      cost: freshProduct.shopPrices?.shID?.supplyPrice?.toDouble() ?? 0,
      createdTime: DateTime.now().millisecondsSinceEpoch,
      price: boxPrice,
      realPrice: boxPrice,
      onlyPrice: boxPrice,
      singleDiscount: 0,
      value: 1,
      productId: freshProduct.id ?? '',
      productName: '${freshProduct.name ?? ''} //blok',
      ownerType: int.tryParse(freshProduct.ownerType ?? '1') ?? 1,
      packageCode: freshProduct.packageCode,
      packageName: freshProduct.packageName,
      barcode: freshProduct.barcode?.isNotEmpty == true
          ? freshProduct.barcode!.first
          : '',
      sku: int.tryParse(freshProduct.sku ?? '0') ?? 0,
      vat: boxPrice == 0
          ? 0
          : (boxPrice * (freshProduct.vat?.percentage ?? 12)) /
              (100 + (freshProduct.vat?.percentage ?? 12)),
      mxik: freshProduct.mxikCode ?? '',
      sellerId: Pref.getString(PrefKeys.cashierId, ''),
      vatName: freshProduct.vat?.name ?? '',
      vatPercent: (freshProduct.vat?.percentage ?? 12).toDouble(),
      discountPercent: 0,
      productType: _resolveProductType(freshProduct),
      productPackage: _resolveProductPackage(freshProduct),
      saleType: 2,
      boxValue: boxValue,
      boxQuantity: newBoxQuantity,
    );

    _currentClient.orderedProducts.insert(0, soldItem);

    // Shu productning barcha box itemlarida boxQuantity ni yangilaymiz
    for (final item in _currentClient.orderedProducts) {
      if (item.productId == (freshProduct.id ?? '') &&
          !(item.isDeleted ?? false) &&
          item.saleType == 2) {
        item.boxQuantity = newBoxQuantity;
      }
    }

    // Umumiy son (dona + blok donalari) bo'yicha tier — shu productning barcha
    // qatorlari (avvalgi dona qatorlari ham) qayta narxlanadi
    if (!_applyExistingManualPrice(freshProduct.id)) {
      _repriceProductRowsByTotalUnits(freshProduct.id);
    }

    _currentClient.lastAddedIndex = 0;
    isTpEdited = false;

    // BuyXGetY, BuyXGetX, Free Gift chegirmalarini box mahsulot uchun ham qo'llaymiz
    DiscountSingleton.productId(freshProduct.id ?? '');
    findFreeProducts();
    await freeGiftDialog();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();

    notifyListeners();
  }

  /// /// /// /// /// /// /// /// /// /// /// /// ///
  ///                Add Products                 ///
  /// /// /// /// /// /// /// /// /// /// /// /// ///

  void tapIndexToEdit(int i) {
    _tappedIndexToEdit = i;
  }

  /// Markirovka guruhi tahririni boshlaydi (order_list dan chaqiriladi).
  void beginMarkGroupEdit(String productId) {
    _markGroupEditProductId = productId;
  }

  /// Markirovka guruhi tahririni tugatadi (dialog yopilgach).
  void endMarkGroupEdit() {
    _markGroupEditProductId = null;
  }

  /// Blok guruhi tahririni boshlaydi (order_list dan chaqiriladi).
  void beginBoxGroupEdit(String productId) {
    _boxGroupEditProductId = productId;
  }

  /// Blok guruhi tahririni tugatadi (dialog yopilgach).
  void endBoxGroupEdit() {
    _boxGroupEditProductId = null;
  }

  /// Berilgan productId uchun aktiv (o'chirilmagan) markirovka itemlarining
  /// orderedProducts dagi indekslari. Eng yangi (insert(0) bilan qo'shilgan)
  /// markalar pastroq indeksda bo'ladi.
  List<int> _activeMarkIndices(String productId) {
    final result = <int>[];
    for (var i = 0; i < _currentClient.orderedProducts.length; i++) {
      final e = _currentClient.orderedProducts[i];
      if (e.productId == productId && e.marking && !(e.isDeleted ?? false)) {
        result.add(i);
      }
    }
    return result;
  }

  /// Markirovka guruhini saqlash: yangi qty ga qarab eng yangi markalarni
  /// o'chiradi (qty kamayganda) yoki narx/diskont o'zgarishini barcha markalarga
  /// qo'llaydi. Qty ni oshirib bo'lmaydi (yangi mark skanerlanishi kerak).
  Future<void> _saveMarkGroup(ReceiptModelSoldItem4 edited,
      {Employee? approvedBy}) async {
    final pid = _markGroupEditProductId!;
    final indices = _activeMarkIndices(pid);
    if (indices.isEmpty) return;

    final currentCount = indices.length;
    final newCount = edited.value.floor();

    if (newCount <= 0) {
      _deleteMarkGroup(pid, approvedBy: approvedBy);
      return;
    }

    if (newCount < currentCount) {
      // Eng yangi markalarni o'chiramiz: indices o'sish tartibida, eng past
      // indeks = eng yangi. Birinchi (currentCount - newCount) tasini olamiz.
      final removeCount = currentCount - newCount;
      final toRemove = indices.take(removeCount).toList()
        ..sort((a, b) => b.compareTo(a)); // teskari tartib (xavfsiz o'chirish)
      final redDelete = Pref.getBool(PrefKeys.isRedDeleteActivated, false);
      for (final idx in toRemove) {
        _recordDeletedItem(_currentClient.orderedProducts[idx],
            approvedBy: approvedBy);
        if (redDelete) {
          _currentClient.orderedProducts[idx].isDeleted = true;
        } else {
          _currentClient.orderedProducts.removeAt(idx);
        }
      }
    }
    // newCount >= currentCount → qty oshmaydi (skan kerak), o'zgarishsiz.

    // Narx/diskont o'zgarishini guruhdagi qolgan barcha markalarga qo'llaymiz.
    for (final m in _activeMarkIndices(pid)) {
      final item = _currentClient.orderedProducts[m];
      item.price = edited.price;
      item.realPrice = edited.realPrice;
      item.onlyPrice = edited.onlyPrice;
      item.singleDiscount = edited.singleDiscount;
      item.discountPercent = edited.discountPercent;
      item.isPriceOnlyChanged = edited.isPriceOnlyChanged;
      item.isPriceChanged = edited.isPriceChanged;
      item.tin = edited.tin;
      item.vat = (edited.price * item.vatPercent) / (100 + item.vatPercent);
    }

    final remaining = _activeMarkIndices(pid);
    if (remaining.isEmpty) {
      _showCount.remove(pid);
      _showCountFreeGift.remove(pid);
      if (_currentClient.orderedProducts.every((e) => (e.isDeleted ?? false))) {
        _currentClient.selectedClient = null;
        _newClientPersentageDiscount = 0;
      }
    }

    // Narx qo'lda o'zgartirilgan bo'lsa — mahsulotning BOSHQA qatorlariga
    // (ayniqsa blok qatori) ham sinxronlaymiz. Aks holda marka guruhini
    // tahrirlaganda blok tier narxda qolib ketardi (bir xil mahsulot, narxi
    // bir xil bo'lishi kerak).
    if (edited.isPriceOnlyChanged) {
      _syncManualPriceAcrossProductRows(edited);
    }

    _repriceProductRowsByTotalUnits(pid);
    findFreeProducts();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();
    notifyListeners();
  }

  /// Markirovka guruhidagi barcha aktiv markalarni o'chiradi (red-delete ni hisobga olib).
  void _deleteMarkGroup(String pid, {Employee? approvedBy}) {
    final redDelete = Pref.getBool(PrefKeys.isRedDeleteActivated, false);
    final indices = _activeMarkIndices(pid)..sort((a, b) => b.compareTo(a));
    for (final idx in indices) {
      _recordDeletedItem(_currentClient.orderedProducts[idx],
          approvedBy: approvedBy);
      if (redDelete) {
        _currentClient.orderedProducts[idx].isDeleted = true;
      } else {
        _currentClient.orderedProducts.removeAt(idx);
      }
    }
    _showCount.remove(pid);
    _showCountFreeGift.remove(pid);

    if (_currentClient.orderedProducts.isEmpty ||
        _currentClient.orderedProducts.every((e) => (e.isDeleted ?? false))) {
      _currentClient.selectedClient = null;
      _newClientPersentageDiscount = 0;
      // Savat sotuvsiz bo'shadi — yig'ilgan o'chirishlarni "sotuvsiz" (-) belgila.
      _flagOrphanDeletedItemsIfCartEmpty();
    }

    _repriceProductRowsByTotalUnits(pid);
    findFreeProducts();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();
    notifyListeners();
  }

  /// Berilgan productId uchun aktiv (o'chirilmagan) blok itemlarining
  /// (saleType==2) orderedProducts dagi indekslari. Eng yangi (insert(0) bilan
  /// qo'shilgan) bloklar pastroq indeksda bo'ladi.
  List<int> _activeBoxIndices(String productId) {
    final result = <int>[];
    for (var i = 0; i < _currentClient.orderedProducts.length; i++) {
      final e = _currentClient.orderedProducts[i];
      if (e.productId == productId &&
          e.saleType == 2 &&
          !(e.isDeleted ?? false)) {
        result.add(i);
      }
    }
    return result;
  }

  /// Blok guruhini saqlash: yangi qty (blok soni) ga qarab eng yangi bloklarni
  /// o'chiradi (qty kamayganda) yoki narx o'zgarishini butun mahsulotga qo'llaydi.
  /// Qty ni oshirib bo'lmaydi (yangi blok skanerlanishi kerak — OPD'da "+" bloklangan).
  /// [edited.value] blok soni hisobida keladi (order_list displayValue = blok soni).
  Future<void> _saveBoxGroup(ReceiptModelSoldItem4 edited,
      {Employee? approvedBy}) async {
    final pid = _boxGroupEditProductId!;
    final indices = _activeBoxIndices(pid);
    if (indices.isEmpty) return;

    final currentCount = indices.length;
    final newCount = edited.value.floor();

    if (newCount <= 0) {
      _deleteBoxGroup(pid, approvedBy: approvedBy);
      return;
    }

    if (newCount < currentCount) {
      // Eng yangi bloklarni o'chiramiz: indices o'sish tartibida, eng past
      // indeks = eng yangi. Birinchi (currentCount - newCount) tasini olamiz.
      final removeCount = currentCount - newCount;
      final toRemove = indices.take(removeCount).toList()
        ..sort((a, b) => b.compareTo(a)); // teskari tartib (xavfsiz o'chirish)
      final redDelete = Pref.getBool(PrefKeys.isRedDeleteActivated, false);
      for (final idx in toRemove) {
        _recordDeletedItem(_currentClient.orderedProducts[idx],
            approvedBy: approvedBy);
        if (redDelete) {
          _currentClient.orderedProducts[idx].isDeleted = true;
        } else {
          _currentClient.orderedProducts.removeAt(idx);
        }
      }
    }
    // newCount >= currentCount → qty oshmaydi (skan kerak), o'zgarishsiz.

    if (edited.isPriceOnlyChanged) {
      // Narx qo'lda o'zgartirilgan: blok narxini qolgan bloklarga va (blok⇄dona
      // bitta dona narxi bazasida) mahsulotning boshqa qatorlariga sinxronlaymiz.
      for (final m in _activeBoxIndices(pid)) {
        final item = _currentClient.orderedProducts[m];
        item.price = edited.price;
        item.realPrice = edited.realPrice;
        item.onlyPrice = edited.onlyPrice;
        item.singleDiscount = edited.singleDiscount;
        item.discountPercent = edited.discountPercent;
        item.isPriceOnlyChanged = true;
        item.isPriceChanged = edited.isPriceChanged;
        item.vat = (edited.price * item.vatPercent) / (100 + item.vatPercent);
      }
      _syncManualPriceAcrossProductRows(edited);
    } else {
      // Faqat qty o'zgardi: tier savatdagi umumiy dona bo'yicha qayta tanlanadi.
      _repriceProductRowsByTotalUnits(pid);
    }

    final remaining = _activeBoxIndices(pid);
    if (remaining.isEmpty) {
      _showCount.remove(pid);
      _showCountFreeGift.remove(pid);
      if (_currentClient.orderedProducts.every((e) => (e.isDeleted ?? false))) {
        _currentClient.selectedClient = null;
        _newClientPersentageDiscount = 0;
      }
    }

    findFreeProducts();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();
    notifyListeners();
  }

  /// Blok guruhidagi barcha aktiv bloklarni o'chiradi (red-delete ni hisobga olib).
  void _deleteBoxGroup(String pid, {Employee? approvedBy}) {
    final redDelete = Pref.getBool(PrefKeys.isRedDeleteActivated, false);
    final indices = _activeBoxIndices(pid)..sort((a, b) => b.compareTo(a));
    for (final idx in indices) {
      _recordDeletedItem(_currentClient.orderedProducts[idx],
          approvedBy: approvedBy);
      if (redDelete) {
        _currentClient.orderedProducts[idx].isDeleted = true;
      } else {
        _currentClient.orderedProducts.removeAt(idx);
      }
    }
    _showCount.remove(pid);
    _showCountFreeGift.remove(pid);

    if (_currentClient.orderedProducts.isEmpty ||
        _currentClient.orderedProducts.every((e) => (e.isDeleted ?? false))) {
      _currentClient.selectedClient = null;
      _newClientPersentageDiscount = 0;
      // Savat sotuvsiz bo'shadi — yig'ilgan o'chirishlarni "sotuvsiz" (-) belgila.
      _flagOrphanDeletedItemsIfCartEmpty();
    }

    _repriceProductRowsByTotalUnits(pid);
    findFreeProducts();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();
    notifyListeners();
  }

  /// [approvedBy] — qty kamaytirishga PIN bilan ruxsat bergan xodim
  /// (OPD dialogida "−" bosilganda so'raladi). deleted_by da o'sha ketadi.
  Future<void> pressDialogSaveButton(ReceiptModelSoldItem4 item,
      {Employee? approvedBy}) async {
    // Blok guruhi tahriri: butun blok guruhiga qo'llaymiz (qty kamaytirish =
    // eng yangi bloklarni o'chirish, narx o'zgarishi = butun mahsulotga).
    if (_boxGroupEditProductId != null) {
      await _saveBoxGroup(item, approvedBy: approvedBy);
      return;
    }
    // Markirovka guruhi tahriri: butun guruhga qo'llaymiz (qty kamaytirish =
    // eng yangi markalarni o'chirish, narx o'zgarishi = barcha markalarga).
    if (_markGroupEditProductId != null) {
      await _saveMarkGroup(item, approvedBy: approvedBy);
      return;
    }
    if (item.value > 0) {
      // Qty kamaytirilsa (masalan 3 → 2) farq ham o'chirilgan hisoblanadi —
      // deleted_items ga eski narx bilan yoziladi.
      final oldItem = _currentClient.orderedProducts[_tappedIndexToEdit];
      if (item.value < oldItem.value) {
        _recordDeletedItem(oldItem,
            quantity: oldItem.value - item.value, approvedBy: approvedBy);
      }
      _currentClient.orderedProducts[_tappedIndexToEdit] = item;

      // Narx SHU tahrirda qo'lda o'zgartirilgan bo'lsa, mahsulotning boshqa
      // qatorlariga ham sinxronlaymiz (blok ⇄ dona, bitta dona narx bazasida).
      if (item.isPriceOnlyChanged && item.price != oldItem.price) {
        _syncManualPriceAcrossProductRows(item);
      }

      // Qty o'zgargach tier savatdagi umumiy son bo'yicha qayta tanlanadi va
      // product/category discount qayta qo'llanadi (manual narx saqlanadi).
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

  /// O'chirilgan mahsulotni joriy savat sessiyasining deleted-items
  /// ro'yxatiga yozadi — sotuv yakunlanganda order_pos "deleted_items"
  /// massivida serverga ketadi (offline chekda ham saqlanadi).
  ///
  /// [approvedBy] — o'chirishga PIN kodi bilan ruxsat bergan xodim. Kassirning
  /// o'zida `deletePrice` ruxsati bo'lmasa, PIN dialogi ochiladi va o'sha PIN
  /// egasi shu yerga keladi — `deleted_by` da AYNAN O'SHA xodim ketadi.
  /// null bo'lsa (PIN so'ralmagan, kassirning o'zida ruxsat bor) — joriy kassir.
  void _recordDeletedItem(ReceiptModelSoldItem4 item,
      {double? quantity, Employee? approvedBy}) {
    // Auto-boshqariladigan qatorlar (free gift qayta hisoblash va h.k.) emas,
    // faqat kassir qo'li bilan o'chirgan qatorlar shu metod orqali yoziladi.
    // quantity berilsa qisman o'chirish (qty kamaytirish), aks holda butun qator.
    // Red-delete'da allaqachon o'chirilgan qator qayta yozilmaydi (X tugmasi
    // ketma-ket bosilganda index 0 dagi o'sha qatorga qayta tushishi mumkin).
    if (item.isDeleted ?? false) return;
    final qty = quantity ?? item.value;
    if (qty <= 0) return;
    final employeeId = approvedBy?.user?.id ??
        HiveBoxes.getCurrentEmployee?.user?.id ??
        Pref.getString(PrefKeys.cashierId, "");
    _currentClient.deletedItems.add(
      DeletedItemModel4(
        deletedBy: employeeId,
        deletedTime:
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()),
        addedTime: item.createdTime > 0
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                DateTime.fromMillisecondsSinceEpoch(item.createdTime).toUtc())
            : '',
        productId: item.productId,
        quantity: qty,
        totalPrice: double.parse((item.price * qty).round().toStringAsFixed(1)),
      ),
    );
  }

  /// Savat SOTUVSIZ bo'shaganda (barcha aktiv mahsulot o'chirilib, chek
  /// yakunlanmasdan) — shu paytgacha yig'ilgan, hali biror chek raqami
  /// olmagan o'chirishlarni "sotuvsiz" deb belgilaydi: checkNumber = "-".
  /// Keyingi yakunlangan sotuv bilan shu "-" holatida yuklanadi, shunda
  /// backend "mahsulot qo'shildi-o'chirildi, lekin sotuv bo'lmadi" holatni
  /// ajrata oladi (masalan, kassir klientdan pul olib o'chirib tashladimi).
  ///
  /// Savatda aktiv mahsulot qolgan bo'lsa — hech narsa qilmaydi (no-op),
  /// shuning uchun barcha to'liq-o'chirish metodlaridan xavfsiz chaqiriladi.
  void _flagOrphanDeletedItemsIfCartEmpty() {
    final hasActive =
        _currentClient.orderedProducts.any((p) => !(p.isDeleted ?? false));
    if (hasActive) return;
    for (final d in _currentClient.deletedItems) {
      if (d.checkNumber.isEmpty) d.checkNumber = '-';
    }
  }

  /// [approvedBy] — PIN kodi bilan o'chirishga ruxsat bergan xodim (kassirda
  /// `deletePrice` ruxsati bo'lmaganda so'raladi). deleted_by da o'sha ketadi.
  void pressDialogDeleteButton({Employee? approvedBy}) async {
    LogHelper.activity('CART_DELETE_ITEM', {'editIndex': _tappedIndexToEdit});
    // Blok guruhi tahririda: butun blok guruhini o'chiramiz.
    if (_boxGroupEditProductId != null) {
      _deleteBoxGroup(_boxGroupEditProductId!, approvedBy: approvedBy);
      return;
    }
    // Markirovka guruhi tahririda: butun guruhni o'chiramiz.
    if (_markGroupEditProductId != null) {
      _deleteMarkGroup(_markGroupEditProductId!, approvedBy: approvedBy);
      return;
    }

    bool isRedDeleteActivated =
        Pref.getBool(PrefKeys.isRedDeleteActivated, false);

    final currentEmployee = HiveBoxes.getCurrentEmployee!;
    final employeeName = currentEmployee.user?.firstName ??
        currentEmployee.user?.firstName ??
        "Noma'lum xodim";

    final deletedProduct = _currentClient.orderedProducts[_tappedIndexToEdit];
    final productName = deletedProduct.productName ?? "Noma'lum mahsulot";
    final productId = deletedProduct.productId ?? "-";
    final posName = Pref.getString(PrefKeys.posName, "Noma'lum POS");
    final deleteTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final product_qunatity = deletedProduct.value ?? "0";
    final deletedProductId = deletedProduct.productId;

    _recordDeletedItem(deletedProduct, approvedBy: approvedBy);

    if (isRedDeleteActivated) {
      _currentClient.orderedProducts[_tappedIndexToEdit].isDeleted = true;
    } else {
      _currentClient.orderedProducts.removeAt(_tappedIndexToEdit);
    }

    // Agar shu productdan boshqa hech narsa qolmagan bo'lsa, dialog flagini tozala
    if (deletedProductId.isNotEmpty) {
      final hasRemaining = _currentClient.orderedProducts.any(
        (e) => e.productId == deletedProductId && !(e.isDeleted ?? false),
      );
      if (!hasRemaining) {
        _showCount.remove(deletedProductId);
        _showCountFreeGift.remove(deletedProductId);
      }
    }

    if (_currentClient.orderedProducts.isEmpty) {
      _currentClient.selectedClient = null;
      _newClientPersentageDiscount = 0;
    }

    // Qator o'chgach umumiy son kamayadi — qolgan qatorlar tier'i qayta tanlanadi
    _repriceProductRowsByTotalUnits(deletedProductId);

    // Savat sotuvsiz bo'shagan bo'lsa (red-delete'da ham) yig'ilgan
    // o'chirishlarni "sotuvsiz" (-) belgila.
    _flagOrphanDeletedItemsIfCartEmpty();

    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();
    notifyListeners();
    await _sendToTelegram(
      productName: productName,
      productId: productId,
      product_qunatity: product_qunatity.toString(),
      posName: posName,
      employeeName: employeeName,
      deleteTime: deleteTime,
    );
  }

  Future<void> _sendToTelegram({
    required String productName,
    required String productId,
    required String posName,
    required String employeeName,
    required String deleteTime,
    required String product_qunatity,
  }) async {
    const String botToken = '8534579686:AAHuob2SA0ZdnV_emG0kSKmOOoDLdNbvrKQ';
    const String channelId = '-1003834151006';
    final String orgName = Pref.getString(PrefKeys.organizationName, "");

    final String message = """
<b>🚨 Mahsulot o'chirildi!</b>

<b>Org Name:</b> $orgName
<b>Product:</b> $productName
<b>Quantity:</b> $product_qunatity
<b>Pos Name:</b> $posName
<b>Employee:</b> $employeeName
<b>Time:</b> $deleteTime
  """
        .trim();

    final Uri url = Uri.parse(
      'https://api.telegram.org/bot$botToken/sendMessage?'
      'chat_id=$channelId'
      '&text=${Uri.encodeComponent(message)}'
      '&parse_mode=HTML',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        await LogHelper.logRequest(
          method: "Sent DeletedProduct To Telegram",
          path: "Ordering4Provider sendToTelegram",
          statusCode: response.statusCode,
          body: '',
          response: response.body,
        );
      }
    } catch (e) {}
  }

  Future<void> freeGiftDialog() async {
    if (_returnedFreeGiftProducts.isEmpty) return;

    final loc =
        AppLocalizations.of(AppNavigation.navigatorKey.currentContext!)!;

    for (ReturnedGift gift in _returnedFreeGiftProducts) {
      final productId = gift.getProduct?.id;

      if (productId == null) continue;

      // Mapda bu product uchun count borligini tekshir
      final currentCount = _showCount[productId] ?? 0;

      if (currentCount >= 1) continue; // allaqachon chiqqan – o'tkaz

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

          // Count ni oshiramiz – bu product uchun endi chiqmaydi
          _showCount[productId] = 1;
        }
      }
    }
  }

  /// Mijoz savatga qo'shilganda (QR scan / person-icon qidiruv orqali)
  /// diskontlarni qayta hisoblaydi va diskont dialoglarini ko'rsatadi.
  ///
  /// Muammo: diskontlar `getClientGroupId` bo'yicha filtrlanadi. Maxsus
  /// mijozlar uchun yaratilgan diskont (masalan Free Gift "50k dan oshsa")
  /// savat allaqachon shartni qondirgan bo'lsa ham, mijoz tanlanganda
  /// dialog chiqmasdi — faqat keyingi product urilganda `addProduct`
  /// oqimi orqali chiqardi. Bu metod o'sha oqimni mijoz tanlangan zahoti
  /// yangi product urilishini kutmasdan ishga tushiradi.
  Future<void> recheckDiscountsAfterClientChanged() async {
    if (_currentClient.orderedProducts.isEmpty) return;

    // 1. Product/Category chegirmalarini yangi client group bilan qayta
    //    qo'llaymiz. Qo'lda narxi/chegirmasi o'zgartirilgan qatorlarga tegmaymiz
    //    (flat-rate mijoz diskonti ham isPriceChanged orqali bu yerda saqlanadi).
    for (final item in _currentClient.orderedProducts) {
      if (item.isPriceOnlyChanged || item.isPriceChanged) continue;
      final freshProduct = ItemsSingleton.getProductById(item.productId);
      if (freshProduct == null) continue;
      item.singleDiscount = 0;
      _applyDiscounts(freshProduct, item);
    }

    // 2. BuyXGetY / Free Gift / BuyXGetX chegirmalarini topamiz
    findFreeProducts();
    notifyListeners();

    // 3. Free Gift dialog — jami summa threshold'iga bog'liq, productga emas
    await freeGiftDialog();

    // 4. Chegirmalarni savatga qo'llaymiz
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();

    notifyListeners();
  }

  /// Mijoz tepadan o'chirilganda chaqiriladi. Faqat o'sha mijoz (customer group)
  /// uchun qo'llangan avtomatik diskontlarni bekor qiladi va savatni mijozsiz
  /// holatda qayta hisoblaydi.
  ///
  /// Mijoz olib tashlangach `getClientGroupId` bo'sh bo'ladi — customer-group
  /// diskontlar `_checkOptions` filtridan o'tmaydi va qo'llanmaydi. `isForAllClients`
  /// diskontlar esa saqlanadi. Qo'lda narxi o'zgartirilgan (`isPriceOnlyChanged`,
  /// masalan utsenka) qatorlarga tegmaydi.
  ///
  /// Misol: Free Gift'da tekin berilgan 10,000 li product mijoz o'chirilganda
  /// yana 10,000 ga qaytadi (tekin emas).
  void recalcDiscountsAfterClientRemoved() {
    if (_currentClient.orderedProducts.isEmpty) return;

    // Avvalgi avtomatik diskont holatini to'liq tozalaymiz (mijoz endi yo'q)
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
      // Qo'lda narx o'zgartirilgan qatorlarga tegmaymiz (utsenka va h.k.)
      if (item.isPriceOnlyChanged) continue;
      final freshProduct = ItemsSingleton.getProductById(item.productId);
      if (freshProduct == null) continue;

      // Asl narxga qaytarib, mijoz tufayli qo'llangan eski diskontlarni tozalaymiz
      item.price = item.realPrice;
      item.discountPercent = 0;
      item.singleDiscount = 0;
      item.isPriceChanged = false;
      item.discount.clear();
      item.productDiscount.clear();

      // Mijozsiz holatda faqat amaldagi (isForAllClients) product/category
      // diskontlarini qayta qo'llaymiz
      _applyDiscounts(freshProduct, item);
    }

    // BuyXGetY / Free Gift / BuyXGetX ni mijozsiz qayta hisoblab qo'llaymiz.
    // Customer-group diskontlar topilmaydi → tekin/chegirmali qatorlar asl narxda qoladi.
    findFreeProducts();
    useFreeProducts();
    useFreeGiftProducts();
    useBuyXGetXProducts();

    notifyListeners();
  }

/////////////////// OPERATION ON SIX CLIENTS //////////////////////
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
      // Yangi (bo'sh) savat — oldingi savatning kompaniya nomi qolib
      // ketmasligi uchun Pref tozalanadi.
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

  /// Chekka bosiladigan kompaniya nomi va nusxa soni chop etishda GLOBAL
  /// Pref'dan o'qiladi (`print_sold_api.dart`, `printing_methods.dart`).
  /// Qiymatlarning o'zi esa har savatga alohida saqlanadi — shuning uchun
  /// savat almashganda Pref'ni joriy savatnikiga moslaymiz.
  ///
  /// Aks holda 1-mijoz uchun "Перечисления"da kiritilgan kompaniya nomi
  /// 2-mijozning chekiga bosilib ketardi.
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

  /// "Перечисления" oynasida "Ok" bosilganda chaqiriladi: qiymatlar joriy
  /// savatga yoziladi va darhol Pref'ga ham (shu savat sotilsa chop etish
  /// o'sha zahoti to'g'ri o'qishi uchun).
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
        // Slot ro'yxatdan chiqib ketishidan OLDIN uning o'chirish yozuvlarini
        // saqlab qolamiz — aks holda ular slot bilan birga yo'qolardi.
        _harvestDeletedItems(_sixClient4List[i]);
      }
    }
    _sixClient4List.removeWhere((e) => e.orderedProducts.isEmpty);
  }

  /// Slot yo'q qilinishidan oldin undagi deleted_items yozuvlarini
  /// `_orphanDeletedItems` ga ko'chiradi.
  ///
  /// Bu faqat savati BO'SH slotga nisbatan chaqiriladi — demak bu yozuvlar
  /// hech qanday chekka tegishli emas. Shuning uchun hali chek raqami
  /// olmaganlariga "-" qo'yiladi ("sotilmasdan o'chirilgan"): keyingi sotuv
  /// bilan ketganda ular o'sha chekning raqamini o'zlashtirib olmaydi.
  void _harvestDeletedItems(SixClientModel4 client) {
    if (client.deletedItems.isEmpty) return;
    for (final d in client.deletedItems) {
      if (d.checkNumber.isEmpty) d.checkNumber = '-';
      _orphanDeletedItems.add(d);
    }
    client.deletedItems.clear();
  }

  void _paymentOnClients() {
    // Faqat SOTILGAN slotning supplieri tozalanadi (`_selectedSupplier` =
    // `_currentClient.selectedSupplier`). Boshqa mijozlarning slotlari
    // o'z supplierini saqlab qoladi.
    _selectedSupplier = null;
    // Chek allaqachon chop etilgan (toBOJECTBOX ichida) — endi bu savatning
    // kompaniya nomi/nusxa soni ham keraksiz.
    _currentClient.receiptCompanyName = null;
    _currentClient.receiptCopies = null;
    _alcoholWarningShown = false;
    _cashsaleWarningShown = false;
    _bigTotalWarningShown = false;
    // Joriy slot bu yerda har holatda bo'shatiladi yoki yangi obyektga
    // almashtiriladi. Muvaffaqiyatli sotuvda uning deleted_items ro'yxati
    // allaqachon tozalangan (chekka biriktirilgan) — bu chaqiruv no-op.
    // Sotuv saqlanmagan holatda esa yozuvlar shu yerda saqlab qolinadi.
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
    // Sotuvdan keyin joriy savat almashdi — Pref yangi savatnikiga moslanadi
    // (yangi/bo'sh savatda kalitlar o'chadi).
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
        // Savat tozalanganda supplier ham qolmasin — aks holda bo'sh
        // savatda "Allaqachon supplier tanlangan" bloki qolib ketardi.
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

/////////////////////////// PAYMENT ///////////////////////////////

  ///          ON TOTAL PRICE OPERATIONS             ///

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

/////         Client Search Functions                     //////

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
    // Mijoz tozalanganda (null — masalan qidiruvda "mijoz topilmadi") qarz
    // qatori ham chiqib ketsin.
    dropDebtPaymentIfNoDebtor();
    // Cashback esa AYNAN eski mijozning balansiga qarab tekshirilgan edi —
    // mijoz o'zgargan bo'lsa (o'chirilgan yoki boshqasiga almashtirilgan)
    // qator qolmasligi kerak.
    if (previousClientId != client?.id) {
      _tally.removeCashbackPayment();
    }
    notifyListeners();
  }

/////////// PAYMENT PROVIDER
// _mustPay, _isChangeToCashback, _zdachaToCashBack, _sdacha, xClient
// clientName, _fromPointBalance

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

    // Chek yig'ish `ReceiptBuilder` ga ko'chirildi (2026-08-06).
    // Saqlash (toOBJECTBOX) va tozalash quyida, providerda qoladi —
    // chegara asl kodda ham aynan shu joyda edi.
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

      /// Tekin maxsulotlarni tozalash ///
      _returnedProducts = {};
      _returnedFreeGiftProducts = [];
      _giftProducts = {};
      _freeGiftDialogCount = 0;
      _showCount = {};
      _showCountFreeGift = {};

      // O'chirilganlar chekka biriktirildi — keyingi sotuvga o'tmasligi uchun
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

  List<ReceiptModelPaymentType4> get paymentsMapAsList =>
      paymentsMap.entries.map((e) {
        String name = e.value.name ?? '';
        double paymentValue = e.value.value ?? 0;
        if (e.key == Pref.getString(PrefKeys.cashId, "")) {
          name = 'CASH';
        }

        if (e.key.replaceFirst('@', '') ==
            Pref.getString(PrefKeys.cardId, "")) {
          name = 'UZCARD';
        }
        if (e.key.replaceFirst('@', '') ==
                Pref.getString(PrefKeys.cardId, "") &&
            e.value.type == 1) {
          name = 'HUMO';
        }

        if (e.key == Pref.getString(PrefKeys.cashbackId, "")) {
          name = 'CASHBACK';
        }
        if (e.key == Pref.getString(PrefKeys.debtId, "")) {
          name = 'DEBT';
        }
        if (_sdachaa > 0 && e.key == Pref.getString(PrefKeys.cashId, "")) {
          paymentValue -= _sdachaa;
        }
        if (_zdachaToCashBack > 0 &&
            e.key == Pref.getString(PrefKeys.cashId, "")) {
          paymentValue -= _zdachaToCashBack;
        }

        if (e.key.replaceFirst('@', '') ==
            Pref.getString(PrefKeys.paymeId, "")) {
          name = 'PAYME GO';
        }
        if (e.key.replaceFirst('@', '') ==
            Pref.getString(PrefKeys.clickId, "")) {
          name = 'CLICK PASS';
        }
        if (e.key.replaceFirst('@', '') ==
            Pref.getString(PrefKeys.uzumId, "")) {
          name = 'UZUM';
        }

        if (e.key.replaceFirst('@', '') ==
                Pref.getString(PrefKeys.paymeId, "") &&
            e.value.type == 1) {
          name = 'PAYME QR';
        }
        if (e.key.replaceFirst('@', '') ==
                Pref.getString(PrefKeys.clickId, "") &&
            e.value.type == 1) {
          name = 'CLICK QR';
        }
        if (e.key.replaceFirst('@', '') ==
                Pref.getString(PrefKeys.uzumId, "") &&
            e.value.type == 1) {
          name = 'UZUM QR';
        }

        paymentValue = double.parse(paymentValue.round().toStringAsFixed(3));
        return ReceiptModelPaymentType4(
          name: name,
          payId: e.key,
          value: paymentValue,
        );
      }).toList();

  /// Fiskal chekka yuborishdan oldingi markirovka tozalash.
  /// Mantiq `MarkCleaner.forFiscal` ga ko'chirildi (2026-08-05).
  /// Imzo saqlanadi — `test/marking_paren_strip_test.dart` shu nomni chaqiradi.
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

    // Chek yig'ish `ReceiptBuilder.buildOnlyOfd` ga ko'chirildi (2026-08-06).
    // OFD'ga yuborish va guard quyida, providerda qoladi.
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

    // GUARD: items bo'sh bo'lsa OFD'ga umuman yubormaymiz.
    // Double-trigger holatida birinchi muvaffaqiyatli sotuv orderedProducts'ni
    // tozalaydi (_paymentOnClients), lekin paymentsMap qolib ketishi mumkin —
    // natijada ikkinchi chaqiruv "items:[] + receivedCash" yuborib, fiskal modul
    // "Передан недействительный параметр в JSON" xatosini qaytaradi.
    // skipped=true bilan qaytamiz => kassirga qizil xato ko'rsatilmaydi.
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

      // O'chirilganlar chekka biriktirildi — keyingi sotuvga o'tmasligi uchun
      _sixClientModel4.deletedItems.clear();
      _orphanDeletedItems.clear();

      DiscountSingleton.maxPrice();
      _paymentOnClients();
      // Muvaffaqiyatli sotuvdan keyin to'lov ro'yxatini DARHOL tozalaymiz.
      // Aks holda double-trigger holatida qolib ketgan naqd/karta qiymati
      // keyingi (bo'sh items) chaqiruvga "sizib" o'tib, noto'g'ri chek hosil
      // qiladi. Avval paymentsMap faqat sahifaga qayta kirishda tozalanardi.
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
    ////////////////////////////////////////
    _cardEnabled = Pref.getBool(PrefKeys.cardEnabled, false);
    _cashEnabled = Pref.getBool(PrefKeys.cashEnabled, false);
    _giftEnabled = Pref.getBool(PrefKeys.giftEnabled, false);
    _nfcEnabled = Pref.getBool(PrefKeys.nfcEnabled, false);
    _debtEnabled = Pref.getBool(PrefKeys.debtEnabled, false);
  }

  late bool _paymentInProgress;

  /// To'lov hisobi `PaymentTallyController` ga ko'chirildi (2026-08-05).
  /// Kontroller `ChangeNotifier` EMAS — `notifyListeners` ni callback
  /// sifatida oladi (Faza 2 dagi kabi).
  late final PaymentTallyController _tally =
      PaymentTallyController(notifyListeners);

  // Quyidagilar fasad: maydon o'rniga getter/setter, shuning uchun sinf
  // ichidagi mavjud murojaatlar va UI kodi o'zgarishsiz ishlayveradi.
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

/////////////////////////////////////////////////////////////////////
  bool _cardEnabled = Pref.getBool(PrefKeys.cardEnabled, false);
  bool _cashEnabled = Pref.getBool(PrefKeys.cashEnabled, false);
  bool _giftEnabled = Pref.getBool(PrefKeys.giftEnabled, false);
  bool _nfcEnabled = Pref.getBool(PrefKeys.nfcEnabled, false);
  bool _debtEnabled = Pref.getBool(PrefKeys.debtEnabled, false);

/////////////////////////////////////////////////////////////////////
///////////////   GETTERS   /////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
  ///
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

  /// Qarz yozib qo'yish uchun EGA (qarzdor) bormi — mijoz yoki supplier.
  ///
  /// MUHIM: bu shart adminkadagi `is_available_for_debt` bayrog'iga QARAMAYDI.
  /// O'sha bayroq faqat "Qarz" tugmasini ko'rsatish/yashirish uchun ishlatiladi
  /// (`keyboard_of_payment_page.dart` — eskidan shunday) va sotuvni to'xtatish
  /// uchun ishlatilmasligi kerak. Sababi: `ClientModel` bir necha joyda shu
  /// maydonsiz yaratiladi (internetsiz 36-belgili ID qidiruvi —
  /// `client_search_bloc.dart`, invoice/nakladnoy orqali kelgan mijoz —
  /// `initOrderByInvoice`), o'sha holatda `isAvailableForDebt == null` bo'lib
  /// ilgari muammosiz o'tib turgan qarz sotuvlari bloklanib qolardi.
  ///
  /// Tuzatilishi kerak bo'lgan haqiqiy holat esa boshqa: qarz qo'shilgandan
  /// KEYIN qarzdor butunlay yo'qolsa (Didox supplier DELETE, "mijoz topilmadi"
  /// qidiruvi) chek egasiz qarzga yozilardi — shuning uchun bu yerda faqat
  /// "mijoz YOKI supplier bormi" tekshiriladi.
  bool get _hasEligibleDebtor =>
      _currentClient.selectedClient != null || _selectedSupplier != null;

  /// `paymentsMap` da DEBT bor, lekin egasi (mijoz/supplier) yo'q.
  /// Bu holatda sotuv "mijozsiz qarz" bo'lib yozilib ketardi.
  bool get isDebtSelectedWithoutDebtor {
    if (_hasEligibleDebtor) return false;
    final String debtId = Pref.getString(PrefKeys.debtId, '');
    return paymentsMap.entries.any((e) =>
        (debtId.isNotEmpty && e.key.replaceFirst('@', '') == debtId) ||
        (e.value.name ?? '').toUpperCase().contains('DEBT'));
  }

  /// Mijoz/supplier butunlay olib tashlanganda `paymentsMap` da qolib ketgan
  /// DEBT qatorini tozalaydi. Qarz tugmasi UI da faqat qarzdor bor bo'lsa
  /// ko'rinadi, lekin qarz QO'SHILGANDAN KEYIN qarzdor yo'qolsa (DELETE,
  /// "mijoz topilmadi" qidiruvi, supplier o'chirilishi) qator qolib ketardi.
  ///
  /// Mijoz boshqa mijozga ALMASHTIRILSA qator tegilmaydi — qarz egasi bor,
  /// adminka bayrog'i esa bu yerda tekshirilmaydi (`_hasEligibleDebtor` izohi).
  bool dropDebtPaymentIfNoDebtor() {
    if (_hasEligibleDebtor) return false;
    return _tally.removeDebtPayment();
  }

  /// `paymentsMap` da CASHBACK bor, lekin mijoz yo'q. Bunda chek "bonus bilan
  /// to'landi" bo'lib yozilardi, lekin `pay_by_loyalty/{client_id}` bo'sh id
  /// bilan ketib xato berardi — balansdan pul yechilmasdan tovar ketardi.
  bool get isCashbackSelectedWithoutClient {
    if (_currentClient.selectedClient != null) return false;
    return _tally.hasCashbackPayment;
  }

  /// Mijoz olib tashlanganda cashback qatorini tozalaydi.
  bool dropCashbackPaymentIfNoClient() {
    if (_currentClient.selectedClient != null) return false;
    return _tally.removeCashbackPayment();
  }

  selectPaymentIndex(int v) => _tally.selectPaymentIndex(v);

  changeTheSelectedPaymentIndex(bool up) =>
      _tally.changeTheSelectedPaymentIndex(up);

//////////////////////////////////////////////////////////

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

//////////////         KEYBOARD FUNCTIONS       ///////////////////

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

  // Mijoz va supplier bir vaqtda tanlanmaydi — biri tanlangan bo'lsa,
  // ikkinchisini qo'shishga urinishda ogohlantirish chiqadi va eskisini
  // avval o'chirish talab qilinadi.
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
              // Mijoz olib tashlandi — faqat o'sha mijoz uchun qo'llangan
              // customer-group diskontlarni (Free Gift va h.k.) bekor qilamiz.
              recalcDiscountsAfterClientRemoved();
              // Qarzga sotuv tanlangan bo'lsa, qarzdor qolmagani uchun DEBT
              // qatori ham ro'yxatdan chiqadi. Cashback ham xuddi shunday —
              // u mijoz balansiga bog'liq.
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

  /// Tanlangan supplier HAR SAVAT (slot) uchun alohida saqlanadi —
  /// `_currentClient.selectedSupplier`. Oldin bu provider darajasidagi bitta
  /// maydon edi: 1-mijozda supplier tanlansa, 2-mijozga o'tib mijoz/cashback
  /// tanlamoqchi bo'lganda "Allaqachon supplier tanlangan" chiqib qolardi.
  SupplierModel? get _selectedSupplier => _currentClient.selectedSupplier;

  set _selectedSupplier(SupplierModel? supplier) =>
      _currentClient.selectedSupplier = supplier;

  SupplierModel? get getSelectedSupplier => _selectedSupplier;

  // Perechisleniya/Didox INN qidiruvida clients_by_pos'da topilmay,
  // supplier API'sida topilgan natijani o'rnatish uchun (yoki tozalash
  // uchun null bilan chaqiriladi).
  void setSelectedSupplierFromInnSearch(SupplierModel? supplier) {
    _selectedSupplier = supplier;
    // Supplier o'chirilganda (null) qarz qatori ham ro'yxatdan chiqadi —
    // aks holda qarzdorsiz DEBT sotuvi ketardi.
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

  /// OTHER ///

  /// UI to'g'ridan-to'g'ri o'qiydi (payment/left/left.dart,
  /// keyboard_of_payment_page.dart) — imzo o'zgarmadi.
  Map<String, Payment> get paymentsMap => _tally.paymentsMap;
  set paymentsMap(Map<String, Payment> v) => _tally.paymentsMap = v;

  // Click Pass muvaffaqiyatli to'langan bo'lsa true
  bool _clickPassPaid = false;
  bool get clickPassPaid => _clickPassPaid;

  // Payme (Go yoki QR) muvaffaqiyatli to'langan bo'lsa true
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

  // To'lov arifmetikasi `PaymentTallyController` ga ko'chirildi (2026-08-05).
  // Quyidagilar fasad — imzolar o'zgarmadi.

  void _payByAll(double v, Payment payment) => _tally.payByAll(v, payment);

  // `_checkButtonIsEnable` olib tashlandi: uni faqat `_payByAll` va
  // `removeFromPaymentList` chaqirardi, ikkalasi ham kontrollerga ko'chdi.

  double getAvailableSumma() => _tally.getAvailableSumma();

  double getSelectedPaymentSumma() => _tally.getSelectedPaymentSumma();

  /// OTHER ///

//#####FOR DOUBLE UZCARD  COUNT ###########
  /// cheq.out yoki log matnidan RRN va karta raqamini ajratib olish
  /// Terminal chek matnini tahlil qiladi.
  /// Mantiq `TerminalReceiptParser` ga ko'chirildi (2026-08-05).
  Map<String, String?> parseTerminalReceipt(String receiptText) =>
      TerminalReceiptParser.parseTerminalReceipt(receiptText);

  // `_terminalErrorMessage` olib tashlandi: yagona chaqiruvchisi
  // `_showTerminalErrorDialog` edi, u `dialogs/terminal_error_dialog.dart`
  // ga ko'chdi va TerminalReceiptParser ni bevosita chaqiradi.


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
          /////////// receipt uzcard
          var receiptDirectory = fs.directory('C:\\Arcus2\\cheq.out');
          final file2 = File(receiptDirectory.path);
          var data2 = await file2.readAsBytes();
          String asString2 = windows1251.decode(data2);
          ////////////

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

//#####FOR DOUBLE HUMO CARDS COUNT ###########

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
          /////////// recipt humo
          var reciptDirectory = fs.directory('C:\\Arcus2\\cheq.out');
          final file2 = File(reciptDirectory.path);
          var data2 = await file2.readAsBytes();
          String asString2 = windows1251.decode(data2);
          ////////////

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

      // Chekka ALLAQACHON kiritilgan cashback. `allPaymentType` yangi summani
      // shuning USTIGA qo'shadi (`_payByAll(summa + currentPaymentValue)`),
      // shuning uchun balans tekshiruvi ham YIG'INDI bo'yicha borishi shart.
      // Avval faqat `parsed` tekshirilardi — tugmani bir necha marta bosib
      // balansdan ko'p to'lash mumkin edi (78 000 balansdan 131 000 ketgan).
      double used = getSelectedPaymentSumma();
      double freeBalance = balance.toDouble() - used;
      if (freeBalance < 0) freeBalance = 0;

      if (parsed > 0) {
        // `>=`: to'liq qoldiq balansni bitta bosishda ishlatishga ruxsat.
        // Avvalgi qat'iy `>` balansning aynan o'zini kiritishga yo'l qo'ymay,
        // kassirni summani bo'lib kiritishga majburlardi — aynan shu yo'l
        // yuqoridagi bug'ni ochardi.
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
        // Summa kiritilmagan: butun qoldiq yopiladi, ya'ni yakuniy cashback
        // aynan `available` bo'ladi (`summa + currentPaymentValue == available`).
        // Shuning uchun bu yerda `available <= balance` allaqachon to'g'ri
        // kumulyativ tekshiruv — o'zgartirilmadi.
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

    double available = getAvailableSumma();
    double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    double summa =
        parsed > 0 ? (available >= parsed ? parsed : available) : available;

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

    double available = getAvailableSumma();
    double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    double summa =
        parsed > 0 ? (available >= parsed ? parsed : available) : available;

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

    double available = getAvailableSumma();
    double parsed =
        double.tryParse(MoneyFormatter.remover(controller.text)) ?? 0;
    double summa =
        parsed > 0 ? (available >= parsed ? parsed : available) : available;

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

  /// Katalog navigatsiyasi `CatalogNavigationController` ga ko'chirildi
  /// (2026-08-05). Kontroller `ChangeNotifier` EMAS — `notifyListeners` ni
  /// callback sifatida oladi, aks holda UI qayta chizilmay qolardi.
  late final CatalogNavigationController _catalog =
      CatalogNavigationController(notifyListeners);

  bool displayingNotFoundDialog = false;
  bool _invalidBarcodeDialogActive = false;

/* //////////////////////// PROVIDER GETTERS //////////////////////// */

  List<dynamic> get getItems => _catalog.getItems;

  List<CategoryData> get getPathList => _catalog.getPathList;

/////////////////////////////////////////////////////////////////////

/* //////////////////////// PROVIDER METHODS //////////////////////// */

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
    // Skaner (ayniqsa macOS klaviatura-emulyatsiyasida) barcode oxiriga
    // ko'rinmas maxsus belgi qo'shib yuborishi mumkin (masalan codeUnit
    // 63233 = U+F701). Private-use (0xE000-0xF8FF) belgilarni olib
    // tashlaymiz — ular hech qachon haqiqiy barcode qismi emas. Aks holda
    // aniq/nol-farqli qidiruv mos kelmay mahsulot "topilmadi" bo'lardi.
    barcode = BarcodeClassifier.sanitize(barcode);

    // Skaner kodining turi `BarcodeClassifier` da aniqlanadi (2026-08-06).
    // Tekshiruvlar tartibi asl koddagidek — u yerda tartib muhim edi.
    final kind = BarcodeClassifier.classify(
      barcode,
      taroziPrefix: Pref.getInt(PrefKeys.taroziPrefix, 28),
      taroziPiecePrefix: Pref.getInt(PrefKeys.taroziPiecePrefix, 21),
    );

    // ASL TARTIB SAQLANADI: bo'sh -> URL -> isMarkingDialogDisplaying -> qolgani.
    // Markirovka dialogi ochiq bo'lsa, tarozi/utsenka/UUID kodlari ham
    // e'tiborsiz qolishi kerak — shuning uchun bu tekshiruv switch'dan OLDIN.
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

    String pattern = barcode;
    ItemModel? item;

    final DateTime? expiryDate = BarcodeClassifier.parseExpiry(barcode);

    if (expiryDate != null) {
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (expiryDate.isBefore(today)) {
        if (!dialogForMark) {
          dialogForMark = true;
          await showGeneralDialog(
            barrierDismissible: false,
            context: AppNavigation.navigatorKey.currentContext!,
            pageBuilder: (f, d, context) => ContainsZeroPriceItemDialog(
              text: 'Срок годности этого товара ист�к!',
              text2: 'Ok',
              delete: false,
              isFirst: true,
              provider: this,
            ),
          ).then((value) {});
          dialogForMark = false;
        }
        return; // ← bu dialogForMark dan TASHQARIDA bo'lishi kerak
      }
    }
    if (barcode.startsWith('01') && barcode.length > 16) {
      final boxGtinMatch = RegExp(r'^01(\d{14})').firstMatch(barcode);
      if (boxGtinMatch != null) {
        final gtin14 = boxGtinMatch.group(1)!;
        final ean13 = gtin14.substring(1);
        final gtin14NoLeadZero = gtin14.replaceFirst(RegExp(r'^0+'), '');

        final boxProduct = ItemsSingleton.getProductByBoxBarcodeOnly(ean13) ??
            ItemsSingleton.getProductByBoxBarcodeOnly(gtin14NoLeadZero) ??
            ItemsSingleton.getProductByBoxBarcodeOnly(gtin14);

        if (boxProduct != null) {
          await _addBoxProduct(boxProduct, barcode);
          return;
        }
      }
    }
    // ─────────────────────────────────────────────────────────
    // Narxi=0 tekshiruvi uchun sinab ko'rilgan barcode variantlarini yig'amiz
    final List<String> triedPatterns = [barcode];

    if (barcode.contains('(01)')) {
      final gtinMatch = RegExp(r'\(01\)(\d{13,14})').firstMatch(barcode);
      if (gtinMatch != null) {
        String gtin = gtinMatch.group(1)!;
        gtin = gtin.replaceFirst(RegExp(r'^0+'), '');
        triedPatterns.add(gtin);
        item = ItemsSingleton.getProductByBarcode(gtin);
        if (item != null) {
          item.mark = _isProductMarkable(item) ? _markirovka(barcode) : null;
        }
      }
    }

    if (item == null && barcode.startsWith('01') && barcode.length > 16) {
      final gtinMatch = RegExp(r'^01(\d{14})').firstMatch(barcode);
      if (gtinMatch != null) {
        String gtin = gtinMatch.group(1)!;
        gtin = gtin.replaceFirst(RegExp(r'^0+'), '');
        triedPatterns.add(gtin);
        item = ItemsSingleton.getProductByBarcode(gtin);
        if (item != null) {
          item.mark = _isProductMarkable(item) ? _markirovka(barcode) : null;
        }
      }
    }

    if (item == null) {
      // Hech qanday "ichidan raqam ajratib olish" YO'Q: satr qanday o'qitilgan
      // bo'lsa shundayligicha 100% teng barcode sifatida solishtiriladi.
      // Ma'lum formatlar (GS1 "01"+GTIN14, tarozi prefiksi, utsenka QR)
      // yuqorida strukturaviy tarzda ochilgan; ularga tushmagan noto'g'ri
      // format hech narsa topmaydi — "topilmadi" dialogi chiqadi.
      //
      // SKU fallback skaner uchun ham OCHIQ: do'konlar narx yorlig'iga SKU'ni
      // barcode qilib chiqaradi, kassir uni skan qiladi. Fragment-himoya SKU
      // qidiruvining o'zida: faqat sof raqam va normalizatsiyasiz AYNAN teng
      // moslik ("0206" hech qachon "206" deb topilmaydi).
      item = ItemsSingleton.getProductByBarcode(pattern);
      if (item != null) {
        item.mark = null;
      }
    }

    if (item != null) {
      final mxikStr = (item.mxikCode ?? '').trim();
      final bool markCheckEnabled =
          Pref.getBool(PrefKeys.markCheckWithOfd, false);
      final bool sellWithMarkingEnabled =
          Pref.getBool(PrefKeys.sellProductsWithMarking, true);
      final bool isMarkingByMxik =
          markCheckEnabled && sellWithMarkingEnabled && _isMxikMarking(mxikStr);

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
    // ─── Narxi 0 bo'lgan mahsulotni tekshirish ───────────────
    {
      ItemModel? zeroPriceItem;
      for (final tried in triedPatterns) {
        zeroPriceItem = ItemsSingleton.products.firstWhereOrNull(
          (p) => p.barcode?.any((b) => b.trim() == tried.trim()) ?? false,
        );
        if (zeroPriceItem != null) break;
      }
      if (zeroPriceItem != null) {
        // Dialog addProduct ichida _checkAndShowDialogsIfNeeded orqali 1 marta ko'rsatiladi
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

    // // ─── Box barcode ─────────────────────────────────────────
    // ItemModel? boxItem = ItemsSingleton.getProductByBoxBarcode(barcode);
    // if (boxItem != null) {
    //   addProduct(
    //     context: scaffoldKey.currentState!.context,
    //     value: 0,
    //     product: boxItem,
    //     where: "PRODUCTS GRID VIEW / scanBarcode box item",
    //   );
    //   return;
    // }

    // ─── Topilmadi ───────────────────────────────────────────
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

  // MXIK va GS1 qoidalari `MxikRules` / `Gs1` ga ko'chirildi (2026-08-05).
  bool _isMxikMarking(String mxikStr) => MxikRules.isMxikMarking(mxikStr);

  bool _isAlcoholMxik(String mxikStr) => MxikRules.isAlcoholMxik(mxikStr);

  bool _isProductMarkable(ItemModel product) =>
      MxikRules.isProductMarkable(product);

  String _resolveProductType(ItemModel product) =>
      MxikRules.resolveProductType(product);

  String _resolveProductPackage(ItemModel product) =>
      MxikRules.resolveProductPackage(product);

  // `_getProductType` olib tashlandi: yagona chaqiruvchisi `_resolveProductType`
  // edi, u endi to'g'ridan-to'g'ri MxikRules ga delegatsiya qiladi.

  DateTime? _parseGS1Date(String yymmdd) => Gs1.parseDate(yymmdd);

  void scanWeightItem(
    String barcode,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) async {
    String gramString = barcode.substring(7, barcode.length);

    double gram = double.tryParse(gramString) ?? 0;
    double value = (gram / 10000);

    double val = (value * 1000).floorToDouble() / 1000;

    // Tarozi formati: PLU (SKU) 5 xonaga nol bilan to'ldiriladi ("00206").
    // Avval aynan shu ko'rinishda, topilmasa format bo'yicha nol'lar olib
    // tashlangan ko'rinishda qidiriladi. Bu tarozi FORMATINING qoidasi —
    // ixtiyoriy kiritishdan raqam ajratib olish emas.
    final String plu = barcode.substring(2, 7);
    var item = ItemsSingleton.getProductByBarcode(plu);
    if (item == null) {
      final noZeros = plu.replaceFirst(RegExp(r'^0+'), '');
      if (noZeros.isNotEmpty && noZeros != plu) {
        item = ItemsSingleton.getProductByBarcode(noZeros);
      }
    }
    if (item != null) {
      addProduct(
        context: scaffoldKey.currentState!.context,
        value: val,
        product: item,
        where: "PRODUCTS GRID VIEW / scanWeightItem",
        isTarozi: true,
      );
    } else {
      await _showBarcodeNotFoundDialog(scaffoldKey);
    }
  }

  /// Shtuchniy (dona) tovar: shtrix-kodda faqat prefiks(2)+SKU(5) muhim —
  /// qolgan raqamlar (kiloli formatdagi gram qismi) e'tiborga olinmaydi,
  /// miqdor doim 1 dona sifatida qo'shiladi. SKU aynan (exact) mos kelmasa
  /// "topilmadi" ko'rsatiladi — yaqin/o'xshash boshqa mahsulot urilmaydi.
  void scanPieceItem(
    String barcode,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) async {
    final String sku = barcode.substring(2, 7);
    var item = ItemsSingleton.getProductByBarcode(sku);
    if (item == null) {
      final noZeros = sku.replaceFirst(RegExp(r'^0+'), '');
      if (noZeros.isNotEmpty && noZeros != sku) {
        item = ItemsSingleton.getProductByBarcode(noZeros);
      }
    }
    if (item != null) {
      addProduct(
        context: scaffoldKey.currentState!.context,
        value: 1,
        product: item,
        where: "PRODUCTS GRID VIEW / scanPieceItem",
        isTarozi: true,
      );
    } else {
      await _showBarcodeNotFoundDialog(scaffoldKey);
    }
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

  // Katalog navigatsiyasi `CatalogNavigationController` ga ko'chirildi
  // (2026-08-05). Quyidagilar fasad — public imzolar o'zgarmadi.

  void pressCategory(CategoryData categoryData) =>
      _catalog.pressCategory(categoryData);

  void pressSubCategory(SubCategoryModel subModel) =>
      _catalog.pressSubCategory(subModel);

  /// Savatga ko'prik — kontrollerga KO'CHMAYDI, chunki `addProduct` savat
  /// mantiqiga tegishli.
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
