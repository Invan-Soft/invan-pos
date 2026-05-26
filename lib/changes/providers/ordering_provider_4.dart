
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
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
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/ofd/incom_response_model.dart';
import 'package:invan2/changes/models/ofd/payment_result_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/local_selling_service.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/features/home/bloc/invoice/invoice_bloc.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
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

// ignore: depend_on_referenced_packages
import 'package:file/local.dart' as fl;
import '../../alice_service.dart';
import '../services/discount_service.dart';
import '../../features/home/features/home_orders/calculation_part/total_price_dialog/discount_type_status.dart';
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
import '../models/product_discount_model.dart';
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
  String _lastRRN = '';
  String _lastCardNumber = '';
  int _lastCardType = 0;
  final int _amountActions = 0;
  double _newClientPersentageDiscount = 0;
  bool _alcoholWarningShown = false;
  bool _cashsaleWarningShown = false;   // cashsale==0 uchun
  bool _bigTotalWarningShown = false;   // cashsale==1 + total > 25M uchun

  /* //////////////////////// PROVIDER GETTERS //////////////////////// */

  OrderingProvider4() {
    DiscountService.onDiscountsCleared = clearAllDiscountEffects;
  }

  /// Discountlar serverdan o'chirilganda barcha savatchadagi
  /// discount ta'sirlarini tozalash uchun chaqiriladi.
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
      num basePrice = ItemsSingleton.getItemBasePrice(products[i], false);
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
    """.trim();

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
    bool canDelete = Pref.getBool(PrefKeys.isRedDeleteActivated, false);

    if (canDelete) {
      if (getLastAddedIndex >= getLastAddedIndex) {
        final removedId =
            _currentClient.orderedProducts[getLastAddedIndex].productId;
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
        notifyListeners();
        return;
      }
    } else {
      try {
        final removedId =
            _currentClient.orderedProducts[getLastAddedIndex].productId;
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
      final percent = originalPrice > 0 ? (discount / originalPrice) * 100 : 0.0;

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
    final existingIndex = _currentClient.orderedProducts
        .indexWhere((e) => e.productId == product.id && !e.isPriceOnlyChanged);

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
      return false; // narxi 0 bo'lsa dialog ko'rsatib basketga qo'shamiz
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

  Map<String, int> _showCount = {};
  Map<String, int> _showCountFreeGift = {};

  Map<String, ReturnedProduct> _returnedProducts = {};

  List<ReturnedGift> _returnedFreeGiftProducts = [];
  List<ReturnedGiftX> _returnedBuyXGetX = [];
  Map<String, String> _giftProducts = {};

  int _freeGiftDialogCount = 0;

  void findFreeProducts() {
    // Free Gift threshold har safar qayta hisoblansin
    DiscountSingleton.maxPrice();
    _findFreeGiftProducts();
    _findBuyXGetXProducts();

    final returnedProducts = DiscountSingleton.buyXGetYOrFreeGifts(
          _currentClient.orderedProducts,
          getClientGroupId,
          0,
          false,
        ) ??
        [];

    if (returnedProducts == null || returnedProducts.isEmpty) return;

    for (final product in returnedProducts) {
      final discountId = product.discountId;
      if (discountId != null) {
        _returnedProducts[discountId] = product;
      }
    }
  }

  void _findFreeGiftProducts() {
    List<ReturnedGift> returned = DiscountSingleton.buyXGetYOrFreeGifts(
          _currentClient.orderedProducts,
          getClientGroupId,
          _totalPriceForAllProduct(),
          true,
        ) ??
        [];
    _returnedFreeGiftProducts = returned;
  }

  void _findBuyXGetXProducts() {
    final buyXGetXList = DiscountSingleton.getBuyXGetXDiscounts(
      _currentClient.orderedProducts,
      getClientGroupId,
    );

    if (buyXGetXList.isNotEmpty) {
      _returnedBuyXGetX = buyXGetXList;
      _returnedBuyXGetX.forEach(
        (element) {},
      );
    } else {
      _returnedBuyXGetX = [];
    }
  }

 
void useFreeProducts() {
  if (_returnedProducts.isEmpty) return;

  final orderedProducts = _currentClient.orderedProducts;

  for (final returnedProduct in _returnedProducts.values) {
    final mustQty = returnedProduct.mustProductQuantity ?? 0;
    final availableProducts = returnedProduct.availableProducts;
    final returnedProductId = returnedProduct.returnedProductId;
    final returnedProductQty = returnedProduct.returnedProductQuantity?.toDouble() ?? 0.0;

    if (availableProducts == null || availableProducts.isEmpty || returnedProductId == null) {
      continue;
    }

    final isSameProduct = availableProducts.any((p) => p.id == returnedProductId);

    bool thresholdMet;
    if (isSameProduct) {
      final totalQtyOfProduct = orderedProducts
          .where((p) => p.productId == returnedProductId && !p.isPriceOnlyChanged)
          .fold<num>(0, (sum, p) => sum + (p.saleType == 2 ? p.value * p.boxValue : p.value));
      thresholdMet = totalQtyOfProduct >= mustQty + returnedProductQty;
    } else {
      final nonGiftTotal = orderedProducts
          .where((p) => p.productId != returnedProductId && !p.isPriceOnlyChanged)
          .fold<num>(0, (sum, p) => sum + p.realPrice * p.value);
      thresholdMet = nonGiftTotal >= mustQty;
    }

    if (!thresholdMet) {
      for (final item in orderedProducts) {
        if (item.productId == returnedProductId) {
          _resetItemDiscount(item);
        }
      }
      continue;
    }

    final prod = ItemsSingleton.getProductById(returnedProductId);
    final firstTierPrice = (prod != null)
        ? ItemsSingleton.onePrice(prod.shopPrices).toDouble()
        : 0.0;

    // Tegishli barcha qatorlar (to'lanadigan + tekin bo'ladigan)
    final eligibleItems = orderedProducts
        .where((item) =>
            item.productId == returnedProductId &&
            !item.isPriceOnlyChanged &&
            !item.isPriceChanged)
        .toList();

    // Box itemlar (katta effectiveQty) avval ishlansin — individual itemlar keyinida
    eligibleItems.sort((a, b) {
      final aQty = a.saleType == 2 ? (a.value * a.boxValue) : a.value;
      final bQty = b.saleType == 2 ? (b.value * b.boxValue) : b.value;
      return bQty.compareTo(aQty);
    });

    num freeLeft = returnedProductQty;

    for (final item in eligibleItems) {
      // 1. Har bir qator uchun 6050 ni majburiy qo'yamiz
      if (firstTierPrice > 0) {
        final adjustedFirstTierPrice = item.saleType == 2
            ? firstTierPrice * item.boxValue
            : firstTierPrice;
        item.realPrice = adjustedFirstTierPrice;
        item.onlyPrice = adjustedFirstTierPrice;
      }

      if (freeLeft <= 0) {
        // To'lanadigan qator — chegirmasiz qoladi
        item.price = item.realPrice;
        item.discountPercent = 0;
        item.singleDiscount = 0;
        _resetItemDiscount(item); // eski chegirmalarni tozalaydi
        continue;
      }

      final itemQty = item.saleType == 2
          ? (item.value * item.boxValue).toDouble()
          : item.value.toDouble();
      final effectiveFree = freeLeft >= itemQty ? itemQty : freeLeft;
      freeLeft -= effectiveFree;

      final paidQty = itemQty - effectiveFree;
      final ratio = paidQty / itemQty;

      item
        ..price = item.realPrice * ratio
        ..discountPercent = 100 - (ratio * 100)
        ..singleDiscount = (item.realPrice * effectiveFree) / itemQty;

      item.discount.clear();

      final discountModel = ProductDiscountModel(
        idd: returnedProduct.discountId ?? '',
        typeId: returnedProduct.discountGroupType ?? '',
        typeName: 'Buy X Get Y',
        name: returnedProduct.discountName ?? '',
        value: item.discountPercent ?? 100,
        total: item.singleDiscount * item.value,
      );

      item.productDiscount.removeWhere((e) => e.idd == discountModel.idd);
      item.productDiscount.add(discountModel);
      DiscountSingleton.addDiscountForProduct(item);
    }
  }

  _currentClient.orderedProducts = orderedProducts;
  notifyListeners();
}
  void useFreeGiftProducts() {
    final orderedProducts = _currentClient.orderedProducts;

    if (_returnedFreeGiftProducts.isEmpty) {
      for (final item in orderedProducts) {
        if (item.isPriceOnlyChanged) continue;
        if (_giftProducts.containsKey(item.productId) &&
            item.price != item.realPrice) {
          _resetItemDiscount(item);
        }
      }
      _giftProducts.clear();
      _currentClient.orderedProducts = orderedProducts;
      return;
    }

    for (final gift in _returnedFreeGiftProducts) {
      final giftProductId = gift.getProduct?.id;
      if (giftProductId == null) continue;

      final nonGiftTotal = orderedProducts
          .where((p) => p.productId != giftProductId && !p.isPriceOnlyChanged)
          .fold<num>(0, (sum, p) => sum + p.realPrice * p.value);

      final giftItems = orderedProducts
          .where((item) =>
              item.productId == giftProductId &&
              !item.isPriceOnlyChanged &&
              !item.isPriceChanged)
          .toList();

      if (nonGiftTotal >= gift.buyAmount) {
        // Threshold qondirildi — faqat gift.getProductAmount miqdorini tekin ber
        _giftProducts[giftProductId] = gift.discountId ?? '';
        num freeLeft = gift.getProductAmount.toDouble();

        for (final item in giftItems) {
          if (freeLeft <= 0) {
            // Kvota tugadi — bu qatorni to'liq narxda qoldirish kerak
            _resetItemDiscount(item);
            continue;
          }

          final itemQty = item.saleType == 2
              ? (item.value * item.boxValue).toDouble()
              : item.value.toDouble();
          final effectiveFree = freeLeft >= itemQty ? itemQty : freeLeft;
          freeLeft -= effectiveFree;

          final ratio = (itemQty - effectiveFree) / itemQty;
          item
            ..price = item.realPrice * ratio
            ..discountPercent = 100 - (ratio * 100)
            ..singleDiscount = (item.realPrice * effectiveFree) / itemQty;

          item.discount.clear();
          DiscountSingleton.addDiscountForProduct(item);
          _addDiscountForReceipt(item, gift.discountName ?? '',
              gift.discountId ?? '', gift.discountGroupType ?? '');
        }
      } else {
        for (final item in giftItems) {
          if (item.price != item.realPrice) {
            _resetItemDiscount(item);
          }
        }
        _giftProducts.remove(giftProductId);
      }
    }

    _currentClient.orderedProducts = orderedProducts;
  }

void useBuyXGetXProducts() {
  if (_returnedBuyXGetX.isEmpty) return;

  final orderedProducts = _currentClient.orderedProducts;

  for (ReturnedGiftX gift in _returnedBuyXGetX) {
    final productId = gift.getProduct?.id;
    if (productId == null) continue;

    // Shu productId ga tegishli barcha normal qatorlar
    final items = orderedProducts
        .where((item) =>
            item.productId == productId &&
            !item.isPriceOnlyChanged &&
            !item.isPriceChanged)
        .toList();

    if (items.isEmpty) continue;


    num freeQtyLeft = gift.getProductAmount;   // nechta tekin berish kerak

    // ================== 1. BITTA QATOR (oddiy mahsulot) ==================
    if (items.length == 1) {
      final item = items.first;
      final totalQty = item.saleType == 2
          ? (item.value * item.boxValue).toDouble()
          : item.value.toDouble();
      final buy = gift.buyAmount.toDouble();
      final get = gift.getProductAmount.toDouble();

      // Discount bo'lsa - 3 talik narx emas, 1-chi (asosiy) narxdan hisoblansin
      final prod = ItemsSingleton.getProductById(gift.getProduct?.id ?? '');
      final firstTierPrice = prod != null ? ItemsSingleton.onePrice(prod.shopPrices).toDouble() : 0.0;
      if (firstTierPrice > 0 && firstTierPrice > item.realPrice) {
        item.realPrice = firstTierPrice;
        item.onlyPrice = firstTierPrice;
        item.price = firstTierPrice;
      }

      num freeQty = 0;
      final setSize = buy + get;
      if (gift.isRepeatable) {
        // isRepeatable=true: nechta set bo'lsa shuncha tekin
        if (totalQty >= setSize) {
          freeQty = (totalQty / setSize).floor() * get;
        }
      } else {
        // isRepeatable=false: faqat bitta set, qancha olmasin
        if (totalQty >= setSize) {
          freeQty = get;
        }
      }

      final paidQty = totalQty - freeQty;

      if (paidQty > 0) {
        final ratio = paidQty / totalQty;
        item.price = item.realPrice * ratio;
        item.discountPercent = 100 - (ratio * 100);
        item.singleDiscount = (item.realPrice * freeQty) / totalQty;
      } else {
        item.price = 0;
        item.discountPercent = 100;
        item.singleDiscount = item.realPrice;
      }

      // Discount model
      item.discount.clear();
      final discountModel = ProductDiscountModel(
        idd: gift.discountId ?? '',
        typeId: gift.discountGroupType ?? '',
        typeName: 'Buy X Get X',
        name: gift.discountName ?? '',
        value: item.discountPercent ?? 100,
        total: item.singleDiscount * item.value,
      );

      item.productDiscount.removeWhere((e) => e.idd == discountModel.idd);
      item.productDiscount.add(discountModel);
      DiscountSingleton.addDiscountForProduct(item);
    }
    else {
      // BuyXGetX: perSetGet == perSetBuy (symmetric), perSet = buy + get = 2 × buyAmount
      final perSetGet = gift.buyAmount.toDouble();
      final perSetSize = perSetGet * 2;

      for (final item in items.reversed) {
        if (freeQtyLeft <= 0) {
          _resetItemDiscount(item);
          continue;
        }

        final itemQty = item.saleType == 2
            ? (item.value * item.boxValue).toDouble()
            : item.value.toDouble();

        // Box: cap free at natural ratio so excess free slots pass to individual items.
        // Individual: can absorb all remaining free slots (up to itemQty).
        final naturalCap = item.saleType == 2
            ? (itemQty / perSetSize).floor() * perSetGet
            : itemQty;
        final freeInThis = min(naturalCap, freeQtyLeft);

        if (freeInThis <= 0) {
          _resetItemDiscount(item);
          continue;
        }

        if (freeInThis >= itemQty) {
          // Butun qator tekin
          item.price = 0;
          item.discountPercent = 100;
          item.singleDiscount = item.realPrice;
          freeQtyLeft -= itemQty;
        } else {
          // Qisman tekin
          final paidQty = itemQty - freeInThis;
          final ratio = paidQty / itemQty;
          item.price = item.realPrice * ratio;
          item.discountPercent = 100 - (ratio * 100);
          item.singleDiscount = (item.realPrice * freeInThis) / itemQty;
          freeQtyLeft -= freeInThis;
        }

        // Discount model
        item.discount.clear();
        final discountModel = ProductDiscountModel(
          idd: gift.discountId ?? '',
          typeId: gift.discountGroupType ?? '',
          typeName: 'Buy X Get X',
          name: gift.discountName ?? '',
          value: item.discountPercent ?? 100,
          total: item.singleDiscount * item.value,
        );

        item.productDiscount.removeWhere((e) => e.idd == discountModel.idd);
        item.productDiscount.add(discountModel);
        DiscountSingleton.addDiscountForProduct(item);
      }
    }
  }

  notifyListeners();
}
  void _resetItemDiscount(ReceiptModelSoldItem4 item) {
    item
      ..price = item.realPrice
      ..discountPercent = 0
      ..singleDiscount = 0
      ..discount.clear()
      ..productDiscount.clear();
  }

  ReceiptModelSoldItem4 _addDiscountForReceipt(ReceiptModelSoldItem4 item,
      String discountName, String discountId, String discountGroupType) {
    ProductDiscountModel productDiscountModel = ProductDiscountModel(
      idd: discountId,
      typeId: discountGroupType,
      typeName: discountName,
      name: discountName,
      value: item.singleDiscount,
      total: 0,
    );
    item.productDiscount.removeWhere((e) => e.idd == productDiscountModel.idd);
    item.productDiscount.add(productDiscountModel);
    return item;
  }

  num _totalPriceForAllProduct() => _currentClient.orderedProducts
      .fold(0, (sum, p) => sum + p.price * p.value);

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

  
String _markirovka(String rawMark) {
  if (rawMark.trim().isEmpty) return rawMark;

  String clean = rawMark
      .replaceAll(RegExp(r'[\x1D\x1E\x1F]'), '')
      .replaceAll(RegExp(r'\(\d{2}\)'), '');     

  return clean; 
}

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
      } 
      else {
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
  (e) => !(e.isDeleted ?? false) &&
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
                      text: e.toString(),
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
  (e) => !(e.isDeleted ?? false) &&
         e.mark != null &&
         e.mark == markValue,   
);
      if (alreadyAdded) {
        if (!dialogForMark) {
          dialogForMark = true;
          final loc = AppLocalizations.of(
              AppNavigation.navigatorKey.currentContext!)!;
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

    // Avvalgi dona itemlarning narxini yangilaymiz (box itemlar o'zgarmaydi)
    for (final item in _currentClient.orderedProducts) {
      if (item.productId == freshProduct.id &&
          !(item.isDeleted ?? false) &&
          item.saleType != 2) {
        item.price = price;
        item.realPrice = price;
        item.onlyPrice = price;
      }
    }

    // Markirovkali mahsulotlarga ham product/category chegirmalarini qo'llaymiz
    for (final item in _currentClient.orderedProducts) {
      if (item.productId == freshProduct.id &&
          !(item.isDeleted ?? false) &&
          item.saleType != 2 &&
          !item.isPriceOnlyChanged) {
        item.singleDiscount = 0;
        _applyDiscounts(freshProduct, item);
      }
    }

    // BuyXGetY, Free Gift, BuyXGetX chegirmalarini tekshiramiz
    DiscountSingleton.productId(freshProduct.id ?? '');
    findFreeProducts();

    _currentClient.lastAddedIndex = 0;
    isTpEdited = false;
    notifyListeners();

    final loc = AppLocalizations.of(AppNavigation.navigatorKey.currentContext!)!;

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
    print('Box Product ${freshProduct.name} ${freshProduct.boxBarcodeQuantity}${freshProduct.hasBoxBarcode}');
 final rawBoxValue = freshProduct.boxBarcodeQuantity;
final boxValue = (rawBoxValue == null || rawBoxValue == 0)
    ? 1
    : rawBoxValue.toInt();
    final unitPrice =
        ItemsSingleton.finalPrice(freshProduct, 1, isKg).toDouble();
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

  Future<void> pressDialogSaveButton(ReceiptModelSoldItem4 item) async {
    if (item.value > 0) {
      _currentClient.orderedProducts[_tappedIndexToEdit] = item;
    } else {
      pressDialogDeleteButton();
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

  void pressDialogDeleteButton() async {
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
      notifyListeners();
    }
  }

  void selectClient(int i) {
    _currentClient = _sixClient4List[i];
    _index = i;
    _clearEmptyClients();
    notifyListeners();
  }

  void _clearEmptyClients() {
    List<int> clientNumbers = [];
    for (int i = 0; i < _sixClient4List.length; i++) {
      if (_sixClient4List[i].orderedProducts.isEmpty) {
        clientNumbers.add(_sixClient4List[i].clientNumber);
      }
    }
    _sixClient4List.removeWhere((e) => e.orderedProducts.isEmpty);
  }

  void _paymentOnClients() {
    _selectedSupplier = null;
    _alcoholWarningShown = false;
    _cashsaleWarningShown = false;
    _bigTotalWarningShown = false;
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
      }
    }
    _currentClient.orderedProducts.clear();
    _sixClient4List = <SixClientModel4>[];

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

  initClientByBloc(
    ClientModel? client,
  ) {
    _currentClient.selectedClient = client;
    _currentClient.discountPercent = _currentClient.discountPercent ??
        0 + (client?.discountValue ?? 0).toDouble();
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

    ClientModel? xClient = _sixClientModel4.selectedClient;
    String clientPhone = xClient == null ? "" : xClient.phoneNumber!;
    String clientId = xClient == null ? "" : xClient.id!;
    //---------------------------------------------------------------------
    double clientDiscountVat = xClient == null ? 0 : xClient.discountValue!;
    String clientDiscountID = xClient == null
        ? "9a2aa8fe-806e-44d7-8c9d-575fa67ebefd"
        : xClient.discountId ?? "9a2aa8fe-806e-44d7-8c9d-575fa67ebefd";
    String? clientName = xClient?.firstName ?? "";

    if (DiscountTypeStatus.disTypeStatus == TpStatus.summa) {
      double totalPrice =
          ItemsSingleton.getTotalPrice(getCurrentClient.orderedProducts);
      clientDiscountID = "9fb3ada6-a73b-4b81-9295-5c1605e54552";
      clientDiscountVat = DiscountTypeStatus.summa - totalPrice;
    } else if (DiscountTypeStatus.disTypeStatus == TpStatus.discount) {
      if (_currentClient.discountPercent != null &&
          _currentClient.discountPercent != 0) {
        clientDiscountID = "1fe92aa8-2a61-4bf1-b907-182b497584ad";
        clientDiscountVat = _currentClient.discountPercent!;
      }
    }
    DiscountTypeStatus.disTypeStatus = TpStatus.discount;

    double allDiscountVat = clientDiscountVat;
    String allDiscountID = clientDiscountID;
    //-----------     PREFS -----------------------------------------------
    final cashierId = Pref.getString(PrefKeys.cashierId, "not initialized");
    final cashierName = Pref.getString(PrefKeys.cashierName, "not initialized");
    final posName = Pref.getString(PrefKeys.posName, "not initialized");
    // ignore: unused_local_variable
    final donate = Pref.getDonate('donate', false);
    String supplierId = _selectedSupplier?.id ?? "";
    //-------------------------------------------------------
    final receiptModel4 = ReceiptModel4(
      newid: xClient?.id ?? "",
      zdachiToCashback: _zdachaToCashBack,
      clientPhone: clientPhone,
      cashierId: cashierId,
      supplierId: supplierId,
      cashierName: cashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: false,
      externalId: "",
      createdDate:
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()),
      totalPrice: _totalPrice + 0,
      discountVat: double.parse(allDiscountVat.round().toStringAsFixed(1)),
      discountID: allDiscountID,
      uploaded: false,
      rejected: false,
      clientName: clientName,
      clientId: clientId,
      cashback: _fromPointBalance.round(),
      sdacha: _sdachaa,
      returnForCheck: "",
      posName: posName,
      isDonate: true,
      cashboxId: Pref.getString(PrefKeys.activatedPosId, ""),
      orderId: "",
      orderType: "sale",
      comment: _comments,
      isShow: _showComments,
      shopId: Pref.getString(PrefKeys.storeId, ""),
      userId: Pref.getString(PrefKeys.userId, ""),
    );
    receiptModel4.payment.addAll(paymentsMapAsList);
    receiptModel4.soldItemList.addAll(_sixClientModel4.orderedProducts);

    for (var item in receiptModel4.soldItemList) {
      if (item.mark != null && item.mark!.isNotEmpty) {
        item.mark = cleanMarkForFiscal(item.mark!);
      }
    }
    //-------------------------------------------------------------------------
    bool isChanged = false;
    if (!isTpEdited) {
      isChanged = true;
    } else {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        if (receiptModel4.soldItemList[i].isPriceOnlyChanged ||
            receiptModel4.soldItemList[i].isPriceChanged) {
          isChanged = true;
          break;
        }
      }
    }
    if (isChanged) {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        double discountSingle =
            receiptModel4.soldItemList[i].discount.isNotEmpty
                ? receiptModel4.soldItemList[i].discount.first.total
                : 0;

        if (receiptModel4.soldItemList[i].discount.isNotEmpty) {
          if (receiptModel4.soldItemList[i].discount.first.name == 'single') {
            receiptModel4.soldItemList[i].singleDiscount =
                double.parse(discountSingle.round().toStringAsFixed(1));
          } else {
            receiptModel4.soldItemList[i].singleDiscount =
                double.parse(discountSingle.round().toStringAsFixed(1));
          }
        }
      }
      receiptModel4.discountVat = 0;
    } else {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        double discountSingle =
            receiptModel4.soldItemList[i].discount.isNotEmpty
                ? receiptModel4.soldItemList[i].discount.first.total
                : 0;

        if (receiptModel4.soldItemList[i].discount.isNotEmpty) {
          if (receiptModel4.soldItemList[i].discount.first.name == 'single') {
            receiptModel4.soldItemList[i].singleDiscount =
                double.parse(discountSingle.round().toStringAsFixed(1));
          }
        }
      }
    }
    receiptModel4.discountVat =
        double.parse(receiptModel4.discountVat.round().toStringAsFixed(1));
    if (receiptModel4.payment.isNotEmpty &&
        receiptModel4.soldItemList.isNotEmpty) {
      await ReceiptSingleton4.toOBJECTBOX(
        receiptModel4,
        clientBalance: getCurrentClient.selectedClient?.pointBalance,
      );

      /// Tekin maxsulotlarni tozalash ///
      _returnedProducts = {};
      _returnedFreeGiftProducts = [];
      _giftProducts = {};
      _freeGiftDialogCount = 0;
      _showCount = {};
      _showCountFreeGift = {};

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

  static String cleanMarkForFiscal(String rawMark) {
  if (rawMark.trim().isEmpty) return rawMark;

  String clean = rawMark
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'\(\d{2,3}\)'), '');

  // 01+14raqam+21 topamiz, keyin belgilarni 93 kelguncha olamiz
  final match = RegExp(r'(01\d{14}21.*?)(?=93)').firstMatch(clean);
  
  if (match != null) return match.group(1)!;

  return clean;
}
      Future<PaymentResult> pressPaymentButtonOnlyOFD(BuildContext context) async {
    AppLocalizations loc = AppLocalizations.of(context)!;

    if (_isChangeToCashback && _sdachaa > 0) {
      _zdachaToCashBack = _sdachaa;
      _sdachaa = 0;
    } else {
      _zdachaToCashBack = 0;
    }

    ClientModel? xClient = _sixClientModel4.selectedClient;
    String clientPhone = xClient == null ? "" : xClient.phoneNumber!;
    String clientId = xClient == null ? "" : xClient.id!;
    double clientDiscountVat = xClient == null ? 0 : xClient.discountValue!;
    String clientDiscountID = xClient == null
        ? "9a2aa8fe-806e-44d7-8c9d-575fa67ebefd"
        : xClient.discountId ?? "9a2aa8fe-806e-44d7-8c9d-575fa67ebefd";
    String? clientName = xClient?.firstName ?? "";

    if (DiscountTypeStatus.disTypeStatus == TpStatus.summa) {
      double totalPrice = ItemsSingleton.getTotalPrice(getCurrentClient.orderedProducts);
      clientDiscountID = "9fb3ada6-a73b-4b81-9295-5c1605e54552";
      clientDiscountVat = DiscountTypeStatus.summa - totalPrice;
    } else if (DiscountTypeStatus.disTypeStatus == TpStatus.discount) {
      if (_currentClient.discountPercent != null && _currentClient.discountPercent != 0) {
        clientDiscountID = "1fe92aa8-2a61-4bf1-b907-182b497584ad";
        clientDiscountVat = _currentClient.discountPercent!;
      }
    }
    DiscountTypeStatus.disTypeStatus = TpStatus.discount;

    double allDiscountVat = clientDiscountVat;
    String allDiscountID = clientDiscountID;

    final cashierId = Pref.getString(PrefKeys.cashierId, "");
    final cashierName = Pref.getString(PrefKeys.cashierName, "");
    final posName = Pref.getString(PrefKeys.posName, '');
    String supplierId = _selectedSupplier?.id ?? "";

    final receiptModel4 = ReceiptModel4(
      createdDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(
        DateTime.now().subtract(const Duration(hours: 5)),
      ),
      newid: xClient?.id ?? "",
      supplierId: supplierId,
      zdachiToCashback: _zdachaToCashBack,
      clientPhone: clientPhone,
      cashierId: cashierId,
      cashierName: cashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: false,
      discountVat: allDiscountVat,
      discountID: allDiscountID,
      totalPrice: _totalPrice + 0,
      uploaded: false,
      rejected: false,
      clientName: clientName,
      clientId: clientId,
      cashback: _fromPointBalance.round(),
      sdacha: _sdachaa,
      returnForCheck: "",
      posName: posName,
      commissionTIN: '',
      isDonate: Pref.getBool('donate', false),
      cashboxId: Pref.getString(PrefKeys.activatedPosId, ""),
      orderType: "sale",
      shopId: Pref.getString(PrefKeys.organization, ""),
      userId: Pref.getString(PrefKeys.userId, ""),
      orderId: "",
      externalId: "",
      comment: _comments,
      isShow: _showComments,
    );

    receiptModel4.cardType = _lastCardType;
    receiptModel4.cardNumber = _lastCardNumber;
    receiptModel4.pptId = _lastRRN;

    receiptModel4.payment.addAll(paymentsMapAsList);
    receiptModel4.soldItemList.addAll(_sixClientModel4.orderedProducts);

    for (var item in receiptModel4.soldItemList) {
      if (item.mark != null && item.mark!.isNotEmpty) {
        final originalMark = item.mark!;

        item.mark = cleanMarkForFiscal(originalMark);
      }
    }

    bool isChanged = false;
    if (!isTpEdited) {
      isChanged = true;
    } else {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        if (receiptModel4.soldItemList[i].isPriceOnlyChanged ||
            receiptModel4.soldItemList[i].isPriceChanged) {
          isChanged = true;
          break;
        }
      }
    }

    if (isChanged) {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        if (receiptModel4.soldItemList[i].price == receiptModel4.soldItemList[i].onlyPrice) {
          receiptModel4.soldItemList[i].discount.clear();
        } else {
          double discountSingle = receiptModel4.soldItemList[i].discount.isNotEmpty
              ? receiptModel4.soldItemList[i].discount.first.total
              : 0;

          if (receiptModel4.soldItemList[i].discount.isNotEmpty) {
            if (receiptModel4.soldItemList[i].discount.first.name == 'single') {
              receiptModel4.soldItemList[i].singleDiscount = double.parse(discountSingle.round().toStringAsFixed(1));
            } else {
              receiptModel4.soldItemList[i].singleDiscount = double.parse(discountSingle.round().toStringAsFixed(1));
            }
          }
        }
      }
      receiptModel4.discountVat = 0;
    } else {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        if (receiptModel4.soldItemList[i].price == receiptModel4.soldItemList[i].onlyPrice) {
          receiptModel4.soldItemList[i].discount.clear();
        } else {
          double discountSingle = receiptModel4.soldItemList[i].discount.isNotEmpty
              ? receiptModel4.soldItemList[i].discount.first.total
              : 0;

          if (receiptModel4.soldItemList[i].discount.isNotEmpty) {
            if (receiptModel4.soldItemList[i].discount.first.name == 'single') {
              receiptModel4.soldItemList[i].singleDiscount = double.parse(discountSingle.round().toStringAsFixed(1));
            }
          }
        }
      }
    }

    receiptModel4.discountVat = double.parse(receiptModel4.discountVat.round().toStringAsFixed(1));

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

          if (receiptModel4.payment.isNotEmpty && receiptModel4.soldItemList.isNotEmpty) {
            await ReceiptSingleton4.toOBJECTBOX(
              receiptModel4,
              communicatorRECEIPT: response,
              clientBalance: getCurrentClient.selectedClient?.pointBalance,
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
      return PaymentResult(mxikError: err, success: false, errorMessage: err.toString());
    });

    if (paymentResult.success) {
      _returnedProducts = {};
      _giftProducts = {};
      _freeGiftDialogCount = 0;
      _showCount = {};
      _showCountFreeGift = {};

      DiscountSingleton.maxPrice();
      _paymentOnClients();
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

  int selectedPaymentIndex = -1;
  TextEditingController controller = TextEditingController(text: '0');

  late SixClientModel4 _sixClientModel4;
  late num _totalPrice;
  final focusNodeListener = FocusNode();
  late String _comments = "";
  late bool _showComments = true;

  double _zdachaToCashBack = 0;
  double _mustPay = 0;

  double _sdachaa = 0;
  double _fromPointBalance = 0;
  bool _gettingPointBalance = false;

  num _discountAmount = 0;
  bool _isButtonEnabled = false;
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

  void removeFromPaymentList() {
    if (selectedPaymentIndex >= 0 && paymentsMap.isNotEmpty) {
      final paymentKeyList = paymentsMap.keys.toList();
      if (selectedPaymentIndex < paymentKeyList.length) {
        final selectedPaymentKey = paymentKeyList[selectedPaymentIndex];

        if (selectedPaymentKey == Pref.getString(PrefKeys.debtId, '')) {
          Pref.setBool(PrefKeys.debtClick, false);
        }

        paymentsMap.remove(selectedPaymentKey);
      }

      selectedPaymentIndex = -1;
    } else {
      paymentsMap.clear();
      selectedPaymentIndex = -1;
      Pref.setBool(PrefKeys.debtClick, false);
    }

    _checkButtonIsEnable();
    notifyListeners();
  }

  selectPaymentIndex(int v) {
    selectedPaymentIndex = v;
    notifyListeners();
  }

  changeTheSelectedPaymentIndex(bool up) {
    if (!up) {
      if (selectedPaymentIndex < paymentsMap.length - 1) {
        selectedPaymentIndex++;
      } else {
        selectedPaymentIndex = 0;
      }
    } else {
      if (selectedPaymentIndex <= 0) {
        selectedPaymentIndex = paymentsMap.length - 1;
      } else {
        selectedPaymentIndex--;
      }
    }
    notifyListeners();
  }

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

  onClientSearchButtonPressed(BuildContext context, WherePath route) async {
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

  SupplierModel? _selectedSupplier;

  SupplierModel? get getSelectedSupplier => _selectedSupplier;

  BuildContext? supplierCon;

  onSupplierSearchButtonPressed(BuildContext context) async {
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

  Map<String, Payment> paymentsMap = {};

  // Click Pass muvaffaqiyatli to'langan bo'lsa true
  bool _clickPassPaid = false;
  bool get clickPassPaid => _clickPassPaid;

  // Payme (Go yoki QR) muvaffaqiyatli to'langan bo'lsa true
  bool _paymePaid = false;
  bool get paymePaid => _paymePaid;
  void setPaymePaid(bool v) => _paymePaid = v;

  String? _selectedPaymentType;

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

  void _payByAll(double v, Payment payment) {
    final updatedPayment = Payment(
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
      type: payment.type,
      value: v,
    );

    String key = updatedPayment.type == 1
        ? '@${updatedPayment.id}'
        : updatedPayment.id ?? '';

    paymentsMap = {
      ...paymentsMap,
      key: updatedPayment,
    };

    _checkButtonIsEnable();
    notifyListeners();
  }

  void _checkButtonIsEnable() {
    num currentMoney = 0;
    paymentsMap.forEach(
      (key, value) {
        currentMoney += value.value ?? 0;
      },
    );
    _mustPay = _totalPrice - currentMoney + _zdachaToCashBack;

    _sdachaa = (currentMoney - _totalPrice).roundToDouble();

    if (_mustPay > 0) {
      _isButtonEnabled = false;
    } else {
      _isButtonEnabled = true;
    }

    notifyListeners();
  }

  double getAvailableSumma() {
    double paid = 0;
    paymentsMap.forEach((key, payment) {
      if (key != _selectedPaymentType) {
        paid += payment.value ?? 0;
      }
    });
    double a = _totalPrice - paid;
    return a;
  }

  double getSelectedPaymentSumma() {
    double paid = 0;
    paymentsMap.forEach((key, payment) {
      if (key == _selectedPaymentType) {
        paid += payment.value ?? 0;
      }
    });
    return paid;
  }

  /// OTHER ///

//#####FOR DOUBLE UZCARD  COUNT ###########
  /// cheq.out yoki log matnidan RRN va karta raqamini ajratib olish
  Map<String, String?> parseTerminalReceipt(String receiptText) {
    String? rrn;
    String? cardNumber;
    String? authCode;
    String? amount;
    String? date;
    String? cardType;

    // Chek matnidagi har bir qatorni tekshiramiz
    for (final line in receiptText.split('\n')) {
      // RECV <- PRINT: prefiksini olib tashlaymiz (log formatida bo'lsa)
      final content =
          line.replaceFirst(RegExp(r'^.*RECV <- PRINT:'), '').trim();

      // RRN: "RRN :608610728951" yoki "RRN:608610728951"
      if (rrn == null) {
        final m = RegExp(r'RRN\s*:?\s*(\d{6,20})').firstMatch(content);
        if (m != null) rrn = m.group(1);
      }

      // Karta raqami: "4916********3620", "986017******4357", "9860 **** **** 1220"
      if (cardNumber == null) {
        final m = RegExp(r'(\d{4,8}[\*\s]{4,12}\d{4})').firstMatch(content);
        if (m != null) cardNumber = m.group(1)?.replaceAll(RegExp(r'\s+'), '');
      }

      // Avtorizatsiya kodi
      if (authCode == null) {
        final m =
            RegExp(r'[Aa]vtorizatsiya\s+kodi\s*:?\s*(\w+)').firstMatch(content);
        if (m != null) authCode = m.group(1);
      }

      // Miqdor/Summa
      if (amount == null) {
        final m = RegExp(r'MIQDOR\s*:\s*([\d\s,.]+UZS?)').firstMatch(content);
        if (m != null) amount = m.group(1)?.trim();
      }

      // Sana
      if (date == null) {
        final m = RegExp(r'Sana\s*:?\s*(.+)').firstMatch(content);
        if (m != null) date = m.group(1)?.trim();
      }

      // Karta turi
      if (cardType == null) {
        if (content.contains('HUMO'))
          cardType = 'HUMO';
        else if (content.contains('UZCARD'))
          cardType = 'UZCARD';
        else if (content.contains('VISA')) cardType = 'VISA INT';
      }
    }

    return {
      'rrn': rrn,
      'cardNumber': cardNumber,
      'authCode': authCode,
      'amount': amount,
      'date': date,
      'cardType': cardType,
    };
  }

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


          final bool isApproved = asString.contains("ОДО") && asString.contains("РЕНО") ||
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
            String message = '';
            String subMessage = '';
            if (asString.contains("ОТКЛОНЕНА")) {
              message = 'ОТКЛОНЕНА';
              if (asString.contains("ВЕРНЫЙ PIN") || asString.contains("ЕРНЫЙ PIN")) {
                subMessage = "НЕВЕРНЫЙ PIN";
              } else if (asString.contains("ЛИМИТ ПОПЫТОК PIN")) {
                subMessage = "ЛИМИТ ПОПЫТОК PIN";
              } else if (asString.contains("КАРТА НЕДЕЙСТ") || asString.contains("НЕДЕЙСТВИТЕЛЬНА")) {
                subMessage = "КАРТА НЕДЕЙСТВИТЕЛЬНА";
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
                msg: message.isEmpty
                    ? "Nimadir hato bo'ldi"
                    : "$message\n\n$subMessage"));
          }
        },
      ).catchError((error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(mySnackBar(context, msg: error.toString()));
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

    if (!(Pref.getBool(PrefKeys.isUzcardEnabled, false))) {
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


          final bool isApprovedH = asString.contains("ОДО") && asString.contains("РЕНО") ||
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
            String message = '';
            String subMessage = '';
            if (asString.contains("ОТКЛОНЕНА")) {
              message = 'ОТКЛОНЕНА';
              if (asString.contains("ВЕРНЫЙ PIN") || asString.contains("ЕРНЫЙ PIN")) {
                subMessage = "НЕВЕРНЫЙ PIN";
              } else if (asString.contains("ЛИМИТ ПОПЫТОК PIN")) {
                subMessage = "ЛИМИТ ПОПЫТОК PIN";
              } else if (asString.contains("КАРТА НЕДЕЙСТ") || asString.contains("НЕДЕЙСТВИТЕЛЬНА")) {
                subMessage = "КАРТА НЕДЕЙСТВИТЕЛЬНА";
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
                msg: message.isEmpty
                    ? "Nimadir hato bo'ldi | ${asString.length > 60 ? asString.substring(0, 60) : asString}"
                    : "$message\n\n$subMessage"));
          }
        },
      ).catchError((error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(mySnackBar(context, msg: error.toString()));
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

      if (parsed > 0) {
        if (balance > parsed) {
          if (available >= parsed) {
            allPaymentType(payment);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              mySnackBar(context, msg: loc.client_cartasida_yetarli_emas));
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

    Log.d('typePaynet() — summa: $summa, receipt: $receiptNumber', name: 'OrderingProvider4');

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
              Log.d('typePaynet() — to\'lov qabul qilindi', name: 'OrderingProvider4');
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

  List<dynamic> _items = CategorySingleton.topCategories;
  List<CategoryData> _pathList = [];

  bool displayingNotFoundDialog = false;

/* //////////////////////// PROVIDER GETTERS //////////////////////// */

  List<dynamic> get getItems {
    List<CategoryData> categoryList =
        HiveBoxes.getCategories().values.toList().cast<CategoryData>();

    List<dynamic> list = [];

    List<CategoryData> categoryListForLength = [];
    for (var element in _items) {
      if (element is CategoryData) {
        categoryListForLength.add(element);
      } else {
        break;
      }
    }
    for (var element in _items) {
      if (element is LocalCategoryItemModel) {
        if (element.isCategory) {
          final category = CategorySingleton.getCategoryById(element.id);
          list.add(category);
        } else {
          final product = ItemsSingleton.getProductById(element.id);
          list.add(product);
        }
      } else if (element is CategoryData) {
        if (element.parentId == null || element.parentId!.isEmpty) {
          if (categoryListForLength.length == 1) {
            if (element.id != null &&
                element.id!.isEmpty &&
                categoryList.length < 2 &&
                _items.length == 1) {
              list.add(element);
            }
            for (CategoryData c in categoryList) {
              if (element.id != null &&
                  element.id!.isNotEmpty &&
                  element.id == c.parentId) {
                list.add(c);
              }
            }
          } else if (categoryListForLength.length > 1) {
            for (CategoryData c in categoryList) {
              if (c.id == element.id) {
                list.add(c);
              }
            }
          }
        } else {
          if (categoryListForLength.length == 1) {
            for (CategoryData c in categoryList) {
              if (element.id != null &&
                  element.id!.isNotEmpty &&
                  element.id == c.parentId) {
                list.add(c);
              }
            }
          }
        }
      } else if (element is ItemModel) {
        list.add(element);
      } else {
        list.add(null);
      }
    }

    return list;
  }

  List<CategoryData> get getPathList => _pathList;

/////////////////////////////////////////////////////////////////////

/* //////////////////////// PROVIDER METHODS //////////////////////// */

  onBarcodeScanned(String barcode, GlobalKey<ScaffoldState> scaffoldKey) async {
    if (barcode.isEmpty || barcode.startsWith('http')) return;
    if (isMarkingDialogDisplaying) return;
    // UUID formatdagi QR kodlar (masalan, PayNet OTP) product emas
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(barcode)) return;

    if (barcode.trimLeft().startsWith('{')) {
      final utsenkaItem = _parseUtsenkaQr(barcode);
      if (utsenkaItem != null) {
        _currentClient.orderedProducts.insert(0, utsenkaItem);
        notifyListeners();
        return;
      }
    }

    int taroziPrefix = Pref.getInt(PrefKeys.taroziPrefix, 28);
    if (barcode.startsWith('$taroziPrefix') && barcode.length == 13) {
      scanWeightItem(barcode, scaffoldKey);
      return;
    }

    String pattern = barcode;
    ItemModel? item;

    DateTime? expiryDate;

    final ai17Match = RegExp(r'\(17\)(\d{6})').firstMatch(barcode);
    if (ai17Match != null) expiryDate = _parseGS1Date(ai17Match.group(1)!);

    // Qavsiz: 01(14 raqam) dan keyin kelgan AI larni parse qilish
    if (expiryDate == null && barcode.startsWith('01') && barcode.length > 16) {
      final rest = barcode.substring(16); // "1726032510BATCH123..."
      final ai17 = RegExp(r'^17(\d{6})').firstMatch(rest);
      if (ai17 != null) expiryDate = _parseGS1Date(ai17.group(1)!);

      if (expiryDate == null) {
        final ai15 = RegExp(r'^15(\d{6})').firstMatch(rest);
        if (ai15 != null) expiryDate = _parseGS1Date(ai15.group(1)!);
      }
    }

    // Qavsli AI 15
    if (expiryDate == null) {
      final ai15Match = RegExp(r'\(15\)(\d{6})').firstMatch(barcode);
      if (ai15Match != null) expiryDate = _parseGS1Date(ai15Match.group(1)!);
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


        final boxProduct =
            ItemsSingleton.getProductByBoxBarcodeOnly(ean13) ??
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
      if (pattern.length > 18) {
        pattern = ItemsSingleton.extractBarcode(
            barcode.startsWith('01') ? barcode.substring(2) : barcode);
        pattern = pattern.endsWith('21')
            ? pattern.substring(0, pattern.length - 2)
            : pattern;
        triedPatterns.add(pattern);
      }
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
      final bool isMarkingByMxik = markCheckEnabled &&
          sellWithMarkingEnabled && _isMxikMarking(mxikStr);
    
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

  bool _isMxikMarking(String mxikStr) =>
      mxikStr.startsWith('02009') ||
      mxikStr.startsWith('02201') ||
      mxikStr.startsWith('02202') ||
      _isAlcoholMxik(mxikStr);

  bool _isAlcoholMxik(String mxikStr) =>
      mxikStr.startsWith('02203') ||
      mxikStr.startsWith('02204') ||
      mxikStr.startsWith('02205') ||
      mxikStr.startsWith('02206') ||
      mxikStr.startsWith('02207') ||
      mxikStr.startsWith('02208') ||
      mxikStr.startsWith('024');

  /// Mahsulot markirovkali deb hisoblanadimi.
  /// Qoidalar:
  ///   0) OFD marking check (`markCheckWithOfd`) o'chiq bo'lsa — hech narsa markirovkali emas
  ///   1) `product.isMarking == true` → markirovkali (sozlamadan qat'iy nazar, OFD ON bo'lsa)
  ///   2) Aks holda "Avto markirovkani aniqlash" sozlamasi yoqilgan bo'lsa
  ///      va MXIK kod ro'yxatda bo'lsa (`_isMxikMarking`) → markirovkali
  ///   3) "Avto markirovkani aniqlash" o'chirilgan bo'lsa MXIK umuman tekshirilmaydi
  bool _isProductMarkable(ItemModel product) {
    if (!Pref.getBool(PrefKeys.markCheckWithOfd, false)) return false;
    if (product.isMarking ?? false) return true;
    if (!Pref.getBool(PrefKeys.sellProductsWithMarking, true)) return false;
    return _isMxikMarking((product.mxikCode ?? '').trim());
  }

  /// Mahsulot uchun product_type ni aniqlaydi.
  /// Mahsulot markirovkali bo'lsagina type qaytaradi:
  ///   1) MXIK ro'yxatda topilsa → MXIK type ni qaytaradi
  ///   2) Aks holda default '5'
  ///   3) Markirovkali bo'lmasa bo'sh
  String _resolveProductType(ItemModel product) {
    if (!_isProductMarkable(product)) return '';
    final mxikType = _getProductType((product.mxikCode ?? '').trim());
    return mxikType.isNotEmpty ? mxikType : '5';
  }

  String _resolveProductPackage(ItemModel product) =>
      _resolveProductType(product).isNotEmpty ? 'KIZ' : '';

  /// MXIK kodiga qarab product_type qaytaradi.
  /// Bo'sh string = bu mahsulot uchun type yo'q.
  String _getProductType(String mxik) {
    if (mxik.startsWith('024')) return '1';           // Sigareta
    if (mxik.startsWith('02203')) return '3';         // Pivo
    if (mxik.startsWith('02204') ||
        mxik.startsWith('02205') ||
        mxik.startsWith('02206') ||
        mxik.startsWith('02207') ||
        mxik.startsWith('02208')) return '2';          // Alkogol (pivo emas)
    if (mxik.startsWith('02009') ||
        mxik.startsWith('02201') ||
        mxik.startsWith('02202')) return '5';          // Sharbat, suv va sovutuvchi ichimliklar
    if (mxik.startsWith('030')) return '4';           // MXIK 030 → type 4, package KIZ
    if (mxik.startsWith('085')) return '6';           // MXIK 085 → type 6, package KIZ
    return '';
  }

  // ─── GS1 sana formati: YYMMDD → DateTime ─────────────────
  DateTime? _parseGS1Date(String yymmdd) {
    try {
      int yy = int.parse(yymmdd.substring(0, 2));
      int mm = int.parse(yymmdd.substring(2, 4));
      int dd = int.parse(yymmdd.substring(4, 6));
      int year = yy <= 49 ? 2000 + yy : 1900 + yy;
      if (dd == 0) dd = DateTime(year, mm + 1, 0).day;
      return DateTime(year, mm, dd);
    } catch (_) {
      return null;
    }
  }


  void scanWeightItem(
    String barcode,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) async {
    String gramString = barcode.substring(7, barcode.length);

    double gram = double.tryParse(gramString) ?? 0;
    double value = (gram / 10000);

    double val = (value * 1000).floorToDouble() / 1000;

    final item = ItemsSingleton.getProductByBarcode(barcode.substring(2, 7));
    if (item != null) {
      addProduct(
        context: scaffoldKey.currentState!.context,
        value: val,
        product: item,
        where: "PRODUCTS GRID VIEW / scanWeightItem",
        isTarozi: true,
      );
    } else {
      if (!displayingNotFoundDialog) {
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
    }
  }

  void pressCategory(CategoryData categoryData) {
    _collectItemsByCategory(categoryData.id!);
    _pathList.add(categoryData);
    notifyListeners();
  }

  void pressSubCategory(SubCategoryModel subModel) {
    _collectItemsBySubCategory(subModel.id!);
    CategoryData categoryData = CategoryData(
      id: subModel.id,
      children: [],
      name: subModel.name,
    );
    _pathList.add(categoryData);
    notifyListeners();
  }

  void pressProduct(BuildContext context, ItemModel product, String where) {
    product.mark = null;
    addProduct(context: context, product: product, value: 1, where: where);
  }

  void pressPath(CategoryData categoryData) {
    _collectItemsByCategory(categoryData.id!);
    _pathList = _pathList.sublist(0, _pathList.indexOf(categoryData) + 1);
    notifyListeners();
  }

  void pressAllPath() {
    _items = <dynamic>[];
    _items.addAll(CategorySingleton.topCategories);
    _pathList = [];
    notifyListeners();
  }

  void clearPathList() {
    _pathList = [];
    notifyListeners();
  }

  void changeGridviewItems(List<dynamic>? items) {
    if (items != null) {
      _items = items;
      notifyListeners();
    } else {
      pressAllPath();
    }
  }


  void _collectItemsByCategory(String categoryId) {
    _items = <dynamic>[];

    _items.addAll(
      CategorySingleton.collectCategoryByParentCategory(categoryId),
    );
    _items.addAll(
      ItemsSingleton.collectProductsByCategory(categoryId),
    );
  }

  void _collectItemsBySubCategory(String subCategoryId) {
    _items = <dynamic>[];
    _items.addAll(
      ItemsSingleton.collectProductsBySubategory(subCategoryId),
    );
  }

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
