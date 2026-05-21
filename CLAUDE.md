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

---

## SESSIYA HUJJATLARI (token tejash uchun majburiy)

Bir necha sessiya davom etadigan har bir katta task uchun `docs/sessions/` papkasida hujjat yuritiladi. Maqsad: keyingi sessiyada Claude butun loyihani qayta tahlil qilmasdan, faqat shu hujjatni o'qib ishni davom ettira oladi.

### Claude uchun qoidalar

**Har sessiya boshida:**
1. `docs/sessions/` papkasidagi `Holat: in-progress` yoki `Holat: blocked` deb belgilangan fayllarni ko'rib chiq.
2. Agar shunday fayl bo'lsa, foydalanuvchidan so'ra: *"Bu task'ni davom ettiramizmi: <fayl-nomi>?"*
3. Agar foydalanuvchi rozi bo'lsa, **faqat shu hujjatni** o'qi va undagi `Keyingi qadamlar` bo'limidan davom et. Loyiha bo'ylab qayta qidiruv qilmaslik kerak — hujjatdagi fayl yo'llari va qator raqamlariga ishonib bevosita o'sha joylarni o'qi.

**Sessiya davomida:**
- Har katta qadam tugagach (3-5 ta fayl o'zgarishi yoki muhim qaror qabul qilingach), hujjatning `## Bajarilgan` bo'limini yangilab qo'y. Har qator quyidagicha:
  ```
  - [x] <qisqa-tavsif>
    → <fayl-yo'l:qator>
    → Sabab: <nima uchun shu yondashuv>
  ```
- Yangi muammo yoki ochiq savol paydo bo'lsa, `## Ochiq savollar` ga qo'sh.

**Sessiya yakunida (foydalanuvchi "tugat" / "sessiya yakunlanmoqda" desa yoki uzoq pauza bo'lsa):**
- `## Holat` ni yangila: `in-progress` / `blocked` / `done`
- `## Keyingi qadamlar` ni aniqlashtir: birinchi qadam aniq fayl-qatorga ishora qilishi kerak
- Agar `done` bo'lsa, faylga `Yakunlangan: YYYY-MM-DD` qo'sh

### Hujjat sxemasi

Fayl nomi: `docs/sessions/YYYY-MM-DD-<task-qisqa-nomi>.md`

Tarkibi:
```markdown
# Task: <to'liq nomi>

**Boshlangan:** YYYY-MM-DD
**Holat:** in-progress | blocked | done
**Branch:** <branch-nomi>

## Maqsad
<1-3 jumla — nima va nima uchun>

## Scope
- <qaysi fayl/modullar ta'sirlanadi>
- <nima scope dan tashqari>

## Bajarilgan
- [x] ...

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] ...

## Qabul qilingan qarorlar
- <qaror> — <nima uchun>

## Ochiq savollar
- <savol> — <kim/qachon javob beradi>

## Test / Verifikatsiya
- <qanday tekshirildi yoki tekshirilishi kerak>
```

### Foydalanuvchi uchun

- Yangi katta task boshlanganda menga shunchaki: *"docs/sessions/ da yangi hujjat och: <task nomi>"* deyish kifoya.
- Boshqa hech narsa yozmaysiz — barchasini men yozaman.
- Keyingi sessiyada: *"<fayl-nomi> dan davom et"* deyishingiz yetarli.

### Task yakunlash qoidalari

Foydalanuvchi *"task tugadi"* / *"yakunlandi"* / *"arxivla"* desa yoki task haqiqatan tugagani aniq bo'lsa:

1. **Hujjat oxiriga qo'sh:** `Holat: done`, `Yakunlangan: YYYY-MM-DD`
2. **Hujjatni `docs/sessions/archive/` ga ko'chir** (`git mv` orqali — git history saqlanadi)
3. **`docs/sessions/archive/INDEX.md` ga bitta qator qo'sh** (jadval oxiriga, sana bo'yicha tartiblangan):
   ```
   | YYYY-MM-DD | <task qisqa nomi> | <1-jumlali mavzu/kalit so'zlar> | [link](<fayl-nomi>.md) |
   ```
   Mavzu/kalit so'zlar foydalanuvchi tabiiy tilda izlaganda topiladigan so'zlarni o'z ichiga olishi kerak (masalan: "form API har actionda POST", "fiskal sotuv tezlashtirish", "click callback retry").
4. **Memory'dan in-progress pointer'ni o'chir** (yangi sessiyada noise bo'lmasligi uchun)
5. **Muhim arxitektura qarorlari** (masalan: "Provider o'rniga BLoC tanlandi, sabab X") bo'lsa, ularni `docs/decisions/NNNN-<qisqa-nom>.md` ga ADR sifatida ko'chir. Format:
   ```markdown
   # ADR-NNNN: <Qaror>
   **Status:** Accepted | Superseded | Deprecated
   **Sana:** YYYY-MM-DD
   ## Kontekst
   ## Qaror
   ## Sabab
   ## Oqibatlar
   ```
6. Foydalanuvchiga ayt: *"Task arxivlandi va INDEX yangilandi. Muhim qarorlar ADR sifatida saqlandi (agar bo'lsa)."*

### Arxivdan task qidirish (foydalanuvchi tabiiy tilda tasvirlasa)

Foydalanuvchi fayl nomini eslamasligi mumkin va arxivlangan task'ni tabiiy tilda tasvirlashi mumkin (masalan: *"form'da har actionda API yuborilardiku, oldin shu haqida ish qilgandik"*).

Bunday holatda:

1. **Birinchi: `docs/sessions/archive/INDEX.md` ni o'qi.** Foydalanuvchi tavsifiga mos keladigan qatorlarni izla (mavzu/kalit so'zlar bo'yicha).
2. **Topilsa:** mos kelgan fayl(lar)ni foydalanuvchiga ko'rsat va tasdiqlashini so'ra:
   *"Bu task'ni nazarda tutyapsizmi: \<task nomi\> (\<sana\>)? Ko'rib chiqamanmi?"*
3. **Bir nechta moslik bo'lsa:** ro'yxat ko'rsat, foydalanuvchi tanlasin.
4. **INDEX'da topilmasa:** to'liq matn qidiruvi — `grep -rli "<kalit so'z>" docs/sessions/archive/`
5. **Hech narsa topilmasa:** foydalanuvchiga ayt: *"Arxivda topa olmadim. Yangi task sifatida boshlaymizmi yoki boshqa kalit so'zlar bilan qidiraymi?"*

Maqsad: foydalanuvchi hech qachon fayl nomi, sana yoki aniq atamani eslab qolishga majbur bo'lmasligi.

### Arxivlangan task qayta ochilganda (eng muhim qoida)

**ARXIVLANGAN HUJJAT HECH QACHON TAHRIRLANMAYDI** (Holat va Yakunlangan maydonlaridan tashqari). Arxiv = o'zgarmas tarix.

Agar arxivdagi task bo'yicha:
- Muammo/bug topildi, yoki
- Talab o'zgardi, yoki
- Avvalgi qaror endi xato bo'lib chiqdi —

shunda:

1. **`docs/sessions/` da YANGI hujjat och** (eski faylga tegmasdan)
2. Yangi hujjatning `## Maqsad` dan keyin `## Avvalgi implementatsiya` bo'limini qo'sh va eski arxiv faylga link ber:
   ```markdown
   ## Avvalgi implementatsiya
   docs/sessions/archive/YYYY-MM-DD-<eski-task>.md (Yakunlangan YYYY-MM-DD)
   ↑ U yerda <eski qaror> qabul qilingan edi. Sabab: <eski sabab>. Endi <nima o'zgardi>.
   ```
3. **Eski arxiv faylning eng yuqorisiga** (Holat satridan oldin) faqat quyidagi blokni qo'sh — tarkibga tegmasdan:
   ```markdown
   > ⚠️ **Superseded by:** docs/sessions/YYYY-MM-DD-<yangi-task>.md (YYYY-MM-DD)
   > Bu hujjat o'sha vaqtdagi qarorni aks ettiradi. Joriy implementatsiya o'zgargan.
   ```
4. Agar bu task'dan **doimiy printsip** kelib chiqqan bo'lsa (kelajakda yana xato qaror qabul qilinmasligi uchun), uni **feedback memory** sifatida saqla (masalan: "Bu loyihada form API'lar Save bosilganda yuboriladi, har actionda emas").
5. ADR mavjud bo'lsa, eski ADR'ning `Status` ni `Superseded by ADR-NNNN` ga o'zgartir va yangi ADR yarat.

**Pattern qisqacha:**

| Vaziyat | Harakat |
|---------|---------|
| Yangi task | `docs/sessions/` da yangi hujjat |
| Task tugadi | `docs/sessions/archive/` ga ko'chir |
| Arxivdagi qaror o'zgaradi | YANGI hujjat och, eski tegilmaydi (faqat yuqoriga "Superseded by") |
| Arxivdagi bug | YANGI bug-fix hujjati och, eskisi tegilmaydi |

Qoida: **Arxiv = read-only. Yozish faqat yangi faylga.**
