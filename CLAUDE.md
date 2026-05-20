# InVan 2 POS - Loyiha Arxitekturasi

**Loyiha:** InVan 2 POS (Point of Sale System)
**Versiya:** 1.1.2+88 (branch: ayyubxon)
**Platform:** Windows Desktop (Flutter)
**Backend API:** https://dev.api.7i.uz/ (dev) / https://api.7i.uz/ (pro)

---

## ASOSIY PAPKA TUZILMASI

```
lib/
├── main.dart                        # App ishga tushirish (256 qator)
├── app/
│   ├── app.dart                     # MultiProvider setup (288 qator)
│   ├── theme_bloc/
│   └── wrapper/
├── changes/                         # ASOSIY BIZNES LOGIKA
│   ├── providers/                   # 19 ta ChangeNotifier provider
│   │   ├── ordering_provider_4.dart # ENG MUHIM FAYL (4550 qator)
│   │   ├── settings_provider.dart
│   │   ├── language_provider.dart
│   │   ├── paging_provider.dart
│   │   ├── local_category_provider.dart
│   │   ├── return_provider.dart
│   │   ├── update_provider.dart
│   │   └── [13 ta boshqa provider...]
│   ├── bloc/
│   │   ├── client_search/
│   │   ├── network/
│   │   ├── payme/
│   │   └── supplier_search/
│   ├── services/
│   │   ├── api/
│   │   │   ├── api_provider.dart          # HTTP wrapper (362 qator)
│   │   │   └── result_http_model.dart
│   │   ├── payment/
│   │   │   ├── click_service.dart
│   │   │   ├── payme_service.dart
│   │   │   └── uzum_service.dart
│   │   ├── local_selling_service.dart     # Fiskal chek (562 qator)
│   │   ├── discount_service.dart          # Diskount boshqaruv (60 qator)
│   │   └── web_socket_service/
│   │       ├── ws_service.dart            # WebSocket (541 qator)
│   │       ├── product/products_ws_service.dart
│   │       ├── discount/discount_ws_service.dart
│   │       ├── category/categories_ws_service.dart
│   │       └── urls/urls.dart
│   ├── models/                            # 41 ta data modeli
│   │   ├── discount_model.dart
│   │   ├── product_discount_model.dart
│   │   ├── six_client_model.dart
│   │   └── [boshqa modellar...]
│   ├── dialogs/
│   │   ├── contains_discount_item_dialog.dart
│   │   └── [boshqa dialoglar...]
│   ├── singletons/
│   │   ├── discounts/
│   │   │   ├── discount_singleton.dart    # Diskount facade (112 qator)
│   │   │   └── discount_helpers.dart      # Murakkab diskount logikasi
│   │   └── organization_singleton.dart
│   └── repository/
│       └── log_repository.dart
├── features/
│   ├── home/                        # Asosiy POS ekrani
│   │   ├── bloc/
│   │   │   ├── home_bloc/
│   │   │   └── invoice/invoice_bloc.dart
│   │   └── features/
│   │       ├── home_orders/
│   │       ├── home_products/
│   │       ├── home_app_bar/
│   │       └── operation_on_product/
│   ├── payment/                     # To'lov ekrani
│   │   ├── right/
│   │   │   ├── complete_button/
│   │   │   ├── keyboard_of_payment_page.dart
│   │   │   └── dilogs/ (click, uzum, payme...)
│   │   ├── left/
│   │   └── appbar/
│   ├── checks/                      # Cheklar tarixi
│   │   ├── features/ (checks_list, check_view)
│   │   └── return_page/
│   ├── get_products/
│   │   ├── singletons/items_singleton.dart  # Mahsulot kesh
│   │   └── soliq/                    # MXIK soliq
│   ├── get_discounts/
│   │   └── model/discounts_response.dart   # Diskount modeli (511 qator)
│   ├── get_categories/
│   ├── get_employees/
│   ├── authentication/
│   ├── drawer/
│   ├── settings/
│   ├── printing/
│   ├── report/
│   ├── hive_repository/
│   │   └── tiin/singletons/my_objectbox/
│   ├── lock/
│   └── rule_cash/
├── fiscal_service/                  # Fiskal integratsiya
│   ├── model/ (fiscal_receipt_model, request_receipt_model)
│   ├── api_methods.dart
│   ├── post_methods.dart
│   └── z_report_service.dart
├── routes/
│   ├── app_routes.dart
│   └── app_rout_names.dart
└── utils/ (constants, helpers, themes.dart)
```

---

## PAKETLAR (pubspec.yaml)

### State Management & UI:
- `flutter_bloc: ^9.1.0` - BLoC pattern
- `provider: ^6.1.4` - Provider (ASOSIY)

### Local Storage:
- `hive: ^2.2.3` - Asosiy lokal kesh
- `objectbox: ^2.2.0` - Fiskal cheklar uchun

### Network:
- `http: ^1.3.0` - HTTP so'rovlar
- `socket_io_client: ^2.0.0` - WebSocket

### Boshqa:
- `intl`, `google_fonts`, `easy_localization`, `pdf`, `printing`, `qr`, `excel`, `crypto`

---

## STATE MANAGEMENT ARXITEKTURASI

### Asosiy: Provider (ChangeNotifier)
Barcha biznes logika `Provider + ChangeNotifier` orqali boshqariladi.

### BLoC (ikkilamchi):
`app.dart` da yaratilgan: ThemeModeBloc, NetworkBloc, PaymeBloc, ClientSearchBloc, GetMxikFromSoliqBloc, SyncBloc, CmtBBloc, PreCmtBBloc, ClickBloc, AccessBloc, BlBloc (barcode listener)

### Hive (lokal persistentlik):
- 29+ Hive adapter ro'yxatdan o'tgan
- Cache yo'li (Windows): `C:\ProgramData\InVanPos2\cache\`

---

## ORDERING_PROVIDER_4 - ENG MUHIM PROVIDER (4550 qator)

`lib/changes/providers/ordering_provider_4.dart`

### Asosiy holatlar:
```dart
SixClientModel4 _currentClient        // Joriy xarid sessiyasi
List<SixClientModel4> _sixClientList  // Ko'p mijozli qo'llab-quvvatlash (6 ta)
```

### Enumlar:
```dart
enum PaymentType { cash, card, card2, click, payme, uzum, debt, ... }
enum DiscountFromWhere { single, client, total }
enum WherePath { homeScreen, paymentScreen }
```

### Asosiy metodlar:

**Mahsulot boshqaruvi:**
- `addProduct()` - Savatga qo'shish
- `removeLastAdded()` - Oxirgi mahsulotni o'chirish
- `_updateExistingProduct()` / `_addNewProduct()`
- `tapIndexToEdit()`, `pressDialogSaveButton()`, `pressDialogDeleteButton()`

**Diskont qayta ishlash:**
- `_applyDiscounts()` - Mahsulot darajasida diskont qo'llash
- `_addDiscountForReceipt()` - Chek diskontini qo'shish
- `findFreeProducts()`, `useFreeProducts()`, `useFreeGiftProducts()`
- `useBuyXGetXProducts()`, `freeGiftDialog()`

**Mijoz boshqaruvi:**
- `selectClient()`, `addClient()`, `_paymentOnClients()`, `_clearEmptyClients()`

**To'lov qayta ishlash:**
- `pressPaymentButton()` - Asosiy to'lov handleri
- `pressPaymentButtonOnlyOFD()` - Faqat OFD to'lovi
- `typeUzcard()`, `typeHumo()`, `typePayme()`, `typeClick()`, `typeUzum()`
- `typeFromCashbackBalance()`, `onNumPressed()`, `onBackSpacePressed()`

**Markirovka (MXIK):**
- `_markingCheck()`, `marking()`, `_markirovka()`, `cleanMarkForFiscal()`

---

## API PROVIDER

`lib/changes/services/api/api_provider.dart`

```dart
static const INVAN2DEV = 'https://dev.api.7i.uz/';
static const INVAN2PRO = 'https://api.7i.uz/';
static const baseUrlINVAN2 = INVAN2DEV;  // Hozir dev ishlatilmoqda
```

- Metodlar: `postResponse()`, `getResponse()`, `putResponse()`
- 30 soniyalik timeout, HTTP 200-300 = muvaffaqiyat
- 409 statusda log yozilmaydi, Alice network debugger

---

## LOCAL_SELLING_SERVICE - FISKAL CHEK

`lib/changes/services/local_selling_service.dart`

- `sell()` - ReceiptModel4 → OFD formatga, fiskal modulga yuborish
- `saleWithOutIncom()` - INCOM-siz fiskal chek
- `sendUpdateItems()`, `getLabelsItemWithMxik()`, `checkLocalMxikList()`

---

## WEBSOCKET SERVICE

`lib/changes/services/web_socket_service/ws_service.dart`

- Retry: 5 soniya, max 15 urinish, eksponensial backoff
- Type 0: To'liq mahsulot import
- Type 1/2/3: Mahsulot qo'shish/yangilash/o'chirish
- Type 10/11/12: Kategoriya
- Type 13: Mahsulot narxi yangilash
- Type 15/16/17: Diskont yaratish/yangilash/o'chirish

---

## DISKONT TIZIMI

### DiscountSingleton (`lib/changes/singletons/discounts/discount_singleton.dart`)
```dart
static addDiscountOnProduct()      // Mahsulotga diskont qo'llash
static buyXGetYOrFreeGifts()       // Buy X Get Y
static getBuyXGetXDiscounts()      // Buy X Get X
```

### Diskont qo'llash oqimi:
```
addProduct() → _applyDiscounts() → DiscountSingleton.addDiscountOnProduct()
  → DiscountHelpers → ReceiptModelSoldItem4 ga qo'llash → UI yangilash
```

---

## TO'LOV OQIMI

```
OrderingProvider4.pressPaymentButton()
  → LocalService.sell() / saleWithOutIncom()
  → Fiskal xizmat (INCOM yoki lokal)
  → To'lov protsessori (Click/PayMe/Uzum/Card/Naqd)
  → ObjectBox ga yozish
  → Asosiy ekranga qaytish
```

---

## MUHIM KONSTANTALAR

- Dev API: `https://dev.api.7i.uz/`
- Pro API: `https://api.7i.uz/`
- Lokal fiskal: `http://localhost:8080`
- Cache yo'li: `C:\ProgramData\InVanPos2\cache\`
- Auto-sync: har 1 daqiqada
