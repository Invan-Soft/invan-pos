# `is_marking=false` + markirovka MXIK: port qilish qo'llanmasi

**Manba:** `ayyubxon` branch, ish daraxti `efa4727` (1.1.2+124) ustida, 2026-09-11. Hali kommit qilinmagan.
**Diff bazasi:** `efa4727` → ish daraxti (faqat feature va test fayllari).

Bu hujjat o'zgarishlarni **InVan 1** (yoki shu loyihaning boshqa nusxasi) ga qo'lda ko'chirish uchun yozilgan. Yangi fayllar to'liq, o'zgargan fayllar diff ko'rinishida. InVan 1 da fayl/sinf nomlari boshqacha bo'lsa, 5-bo'limdagi "qayerga qo'yiladi" jadvalidan foydalaning — mantiq o'sha, joyi boshqa.

---

## 1. Nima va nima uchun

Adminkada mahsulotga **markirovka talab qiladigan MXIK** (02202..., 02203... va h.k.) xato kiritilgan, lekin mahsulot **markirovkali emas** (`is_marking=false`, DataMatrix yo'q). Ilgari POS:

- savatda MXIK bo'yicha uni markirovkali deb hisoblab **markirovka dialogini ochardi** — kassirda skanerlaydigan kod yo'q, mahsulot sotilmasdi;
- "Avto markirovkani aniqlash" o'chiq bo'lsa qator oddiy tushardi, lekin fiskal modulga `SPIC=02202..., Label=""` ketib **soliq chekni rad etardi**.

Endi `is_marking` (adminka bayrog'i) markirovkalilikning **birinchi mezoni**:

| `is_marking` | Savat | Fiskal modul (SPIC / Barcode / Label) | `order_pos` (backend) |
|---|---|---|---|
| `true` | markirovka dialogi, KM shart | asl MXIK / asl / KM | o'zgarmagan |
| `false`, MXIK markirovka ro'yxatida | **dialog yo'q**, oddiy qator | **statik MXIK `01905012001000000` / bo'sh / bo'sh** | **o'zgarmagan**: `product_mxik` asl, `product_barcode` asl |
| `false`, oddiy MXIK | oddiy qator | asl / asl / bo'sh | o'zgarmagan |
| `null` (bayroq kelmagan) | eski MXIK avto-aniqlash (sozlama yoqiq bo'lsa dialog) | KM bo'lsa asl; KM bo'lmasa statik | o'zgarmagan |

Markirovka MXIK ro'yxati (mavjud `isMxikMarking`): `02009`, `02201`, `02202`, `02203`–`02208`, `024`.

## 2. Qoida (aniq ta'rif)

**Savat (dialog chiqadimi):**
```
markirovkali = OFD_yoqiq && (
    is_marking == true
 || (is_marking != false && avtoAniqlash_yoqiq && MXIK_royxatda)
)
```
Ya'ni eski formuladan yagona farq: `is_marking == false` bo'lsa MXIK umuman tekshirilmaydi.

**Fiskal body (har item uchun, sotuv va vozvratda bir xil):**
```
agar  is_marking(katalogdan) == false
  &&  MXIK_royxatda(item.mxik)
  &&  item.mark bo'sh                      // KM yo'q
  &&  statikMxik bo'sh emas
unda  SPIC    = statikMxik                 // Pref mxik_code = 01905012001000000
      Barcode = ""
aks holda hech narsa o'zgarmaydi.
Label har doim = item.mark ?? "" (o'zgarmagan).
```

Nega uchta shart:
- **`is_marking=true`** mahsulot haqiqatan markirovkali — KM siz qolsa ham (masalan invoice qatori) uni statik MXIK bilan "oddiy tovar" qilib o'tkazmaymiz (eski xatti-harakat: asl MXIK, bo'sh Label).
- **KM bor** bo'lsa (masalan `null` bayroqli mahsulotda avto-aniqlash ishlab KM skanerlangan) asl MXIK ketishi shart — aks holda KM statik SPIC bilan soliqqa noto'g'ri ro'yxatga olinadi.
- **statik MXIK bo'sh** (Pref yozilmagan chetki holat) — bo'sh SPIC yuborishdan ko'ra asl MXIK ketgani xavfsizroq, modul bo'sh SPIC ni har doim rad etadi.

`is_marking` chek qatorida saqlanmaydi — fiskal body qurilayotganda **katalogdan** (`ItemsSingleton.getProductById`) o'qiladi. Mahsulot katalogda yo'q (o'chirilgan) yoki qidiruv xato bersa → `false` deb olinadi (qaror MXIK + KM bo'yicha). Qidiruv faqat 2-3 shart bajarilganda chaqiriladi (20 000 mahsulot, 60 qator — 48 ms).

## 3. Qanday ishlaydi (oqim)

```
Mahsulot skanerlandi / bosildi
  └─ addProduct / onBarcodeScanned
       └─ MxikRules.isMxikAutoDetectCandidate(product)      ← is_marking != false && MXIK ro'yxatda
            ├─ true  → marking() → MarkingDialog → KM → MarkedRowBuilder (marking=true, mark=KM)
            └─ false → oddiy qator: SoldItemBuilder (marking=false, mark=null, mxik=asl, product_type="")

To'lov
  └─ ReceiptBuilder → ReceiptModel4 → LocalService.sell → ReceiptSingleton4.saleOnOFD
       └─ har qator: FiscalMxikFallback.resolve(isMarkingProduct: katalogdan, mxik, mark, barcode, staticMxik)
            ├─ substituted → classCode=019..., barcode="", LogHelper.write(warn, "FISKAL MXIK FALLBACK ...")
            └─ aks holda  → classCode=e.mxik, barcode=e.barcode
       └─ saleWithOutIncom → FiscalReceiptModel: SPIC=classCode, Barcode=barcode, Label=mark

Backend order_pos ← ReceiptModelSoldItem4.toJson (product_mxik, product_barcode) — TEGILMAYDI
Vozvrat ← o'sha saleOnOFD (isRefund) — bir xil qoida
```

## 4. O'zgarishlar ro'yxati

| Fayl | Nima |
|---|---|
| `lib/changes/domain/marking/fiscal_mxik_fallback.dart` | **YANGI** — sof qoida (`mayNeedFallback`, `needsFallback`, `resolve`) |
| `lib/changes/domain/marking/mxik_rules.dart` | `isMxikAutoDetectCandidate` yangi; `isProductMarkable` uni ishlatadi |
| `lib/changes/providers/ordering_provider_4.dart` | `addProduct` va skaner yo'lidagi `isMarkingByMxik` markaziy predikatga o'tdi; `_isMxikMarking` wrapper o'chirildi |
| `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart` | `saleOnOFD`: `classCode`/`barcode` qoida orqali; `_isMarkingInCatalog` helper; log |
| `test/fiscal_mxik_fallback_test.dart` | **YANGI** — 24 test (sof qoida + `saleOnOFD`) |
| `test/fiscal_mxik_fallback_scenarios_test.dart` | **YANGI** — 20 chetki holat |
| `test/mxik_rules_test.dart`, `sold_item_builder_test.dart`, `marked_row_builder_test.dart`, `invoice_row_builder_test.dart`, `box_row_builder_test.dart`, `marking_flag_ofd_gating_test.dart` | `is_marking=false` holatlari qo'shildi |

Tegilmagan (ataylab): `isMxikMarking` ro'yxati, `CashRestrictionRules` (alkogol naqd cheklovi hamon MXIK bo'yicha), `order_pos` JSON, `get_items_service` dagi Soliq bo'yicha `isMarking=true` sinxroni, vozvrat oqimi.

## 5. Qo'llash tartibi (InVan 1 uchun)

InVan 1 da domen sinflari (`MxikRules`, `SoldItemBuilder`, ...) bo'lmasligi mumkin — mantiq `OrderingProvider` ichida bo'lsa, o'sha joylarga qo'llang:

| Qadam | InVan 2 da qayerda | InVan 1 da nimani qidirish |
|---|---|---|
| 1 | `fiscal_mxik_fallback.dart` yarating | istalgan joy; faqat `isMxikMarking` ga bog'liq |
| 2 | `MxikRules.isProductMarkable` — `is_marking == false` → `false` | "markirovkali deb hisoblash" funksiyasi: `isMarking`, `mxik.startsWith('0220')` tekshiruvlari bor joy. Savat qatorining `marking` bayrog'i, `product_type`, `product_package` ham shu qarordan chiqishi kerak |
| 3 | `addProduct` dagi `isMarkingByMxik` | mahsulot qo'shishda markirovka dialogini ochish sharti (`MarkingDialog`/`marking()` chaqiruvi oldidagi `if`) |
| 4 | skaner yo'li `onBarcodeScanned` dagi `isMarkingByMxik` | shtrix-kod skanerlanganda `marking()` ga yo'naltiruvchi shart |
| 5 | DataMatrix skanida `item.mark = isMarkable(item) ? ... : null` | agar bor bo'lsa — o'sha `isMarkable` 2-qadamdagi funksiyaga tayanadi (alohida o'zgarish shart emas) |
| 6 | `saleOnOFD` — OFD item quruvchi | fiskal body'da `classCode`/`barcode` (yoki `SPIC`/`Barcode`) to'ldiriladigan joy. Sotuv VA vozvrat shu joydan o'tishiga ishonch hosil qiling |
| 7 | testlar | 7-bo'lim ro'yxati bo'yicha |

Statik MXIK: InVan 2 da `Pref.getString(PrefKeys.mxikCode)` (`mxik_code`), `main.dart` har ishga tushishda `'01905012001000000'` yozadi. InVan 1 da mahsulotga default MXIK qo'yadigan joy qanday nomlansa, o'shani ishlating.

## 6. Kod

### 6.1. YANGI: `lib/changes/domain/marking/fiscal_mxik_fallback.dart`

```dart
// Fiskal modulga ketadigan item uchun MXIK / shtrix-kod fallback qoidasi.
//
// MUAMMO (2026-09-11): adminkada mahsulot markirovkali deb belgilanMAGAN
// (`is_marking=false` — markirovkalilikni aniqlovchi BIRINCHI mezon), lekin
// unga markirovka talab qiladigan MXIK (02202..., 02203... va h.k. —
// `MxikRules.isMxikMarking` ro'yxati) XATO kiritilgan. Mahsulotning o'zida
// markirovka kodi (seriya raqami) yo'q. Bunday qator fiskal modulga
// `SPIC=02202..., Label=""` bo'lib ketsa, soliq uni rad etadi — kassir chekni
// umuman yopa olmaydi.
//
// QOIDA — uch shart BIRGA bajarilsa, FAQAT fiskal body'da:
//   1) `isMarkingProduct == false` — adminkada markirovkali emas
//   2) MXIK markirovka ro'yxatida
//   3) qatorda markirovka kodi (KM) yo'q
// natija:
//   - `classCode` (SPIC) → statik MXIK (`Pref mxikCode`, 01905012001000000)
//   - `barcode`          → bo'sh
// Boshqa hech narsa o'zgarmaydi: backend chek `order_pos` (`product_mxik`,
// `product_barcode`), savat qatori, `product_type`/`product_package` avvalgidek.
//
// Savat tomoni (2026-09-11): `is_marking=false` mahsulotga markirovka dialogi
// ham CHIQMAYDI — `MxikRules.isMxikAutoDetectCandidate`. Shuning uchun bunday
// qator savatga oddiy (KM siz) tushadi va shu qoida bilan fiskalga ketadi.
//
// Nega 3-shart ham kerak: qanday yo'l bilan bo'lmasin qatorda KM bor bo'lsa
// (masalan bayroq `null` mahsulotda avto-aniqlash ishlab KM skanerlangan)
// asl MXIK ketishi shart — aks holda KM statik SPIC bilan ketib, soliqda
// noto'g'ri ro'yxatga olinadi.
//
// Nega 1-shart kerak: `is_marking=true` bo'lsa mahsulot haqiqatan markirovkali;
// KM siz qolgan bo'lsa ham (masalan invoice qatori) uni statik MXIK bilan
// "oddiy tovar" qilib o'tkazib yubormaymiz.
//
// Qoida sotuv va vozvratga BIR XIL qo'llanadi (ikkalasi
// `ReceiptSingleton4.saleOnOFD` orqali o'tadi) — shunda vozvrat sotuv bilan
// mos keladi.
//
// Sof funksiya — Pref/Hive o'qimaydi: `isMarkingProduct` va statik MXIK
// parametr sifatida keladi. Testlar: test/fiscal_mxik_fallback_test.dart

import 'package:invan2/changes/domain/marking/mxik_rules.dart';

/// Fiskal item uchun yakuniy `classCode` (SPIC) va `barcode`.
class FiscalItemCodes {
  const FiscalItemCodes({
    required this.classCode,
    required this.barcode,
    required this.substituted,
  });

  final String classCode;
  final String barcode;

  /// Almashtirish qo'llandimi (log va test uchun).
  final bool substituted;
}

class FiscalMxikFallback {
  const FiscalMxikFallback._();

  /// Qatorda markirovka kodi bormi (bo'sh joy = yo'q).
  static bool hasMark(String? mark) => mark != null && mark.trim().isNotEmpty;

  /// Fallback UMUMAN mumkinmi — `is_marking` ga qaramasdan: MXIK markirovka
  /// ro'yxatida va KM yo'q. Chaqiruvchi katalog qidiruvini (qimmat) faqat shu
  /// `true` bo'lganda qiladi.
  static bool mayNeedFallback({required String mxik, required String? mark}) =>
      MxikRules.isMxikMarking(mxik.trim()) && !hasMark(mark);

  /// Qator fiskal fallback'ga muhtojmi.
  ///
  /// [isMarkingProduct] — katalogdagi mahsulotning `is_marking` bayrog'i
  /// (adminka). Mahsulot katalogda topilmasa chaqiruvchi `false` beradi.
  static bool needsFallback({
    required bool isMarkingProduct,
    required String mxik,
    required String? mark,
  }) =>
      !isMarkingProduct && mayNeedFallback(mxik: mxik, mark: mark);

  /// Fiskal body uchun `classCode`/`barcode` ni hisoblaydi.
  ///
  /// [staticMxik] bo'sh bo'lsa (Pref yozilmagan chetki holat) almashtirish
  /// QILINMAYDI — bo'sh SPIC yuborishdan ko'ra asl MXIK ketgani xavfsizroq
  /// (fiskal modul bo'sh SPIC ni har doim rad etadi).
  static FiscalItemCodes resolve({
    required bool isMarkingProduct,
    required String mxik,
    required String? mark,
    required String barcode,
    required String staticMxik,
  }) {
    final String fallback = staticMxik.trim();
    final bool needs = needsFallback(
      isMarkingProduct: isMarkingProduct,
      mxik: mxik,
      mark: mark,
    );
    if (fallback.isEmpty || !needs) {
      return FiscalItemCodes(
        classCode: mxik,
        barcode: barcode,
        substituted: false,
      );
    }
    return FiscalItemCodes(
      classCode: fallback,
      barcode: '',
      substituted: true,
    );
  }
}
```

InVan 1 da `MxikRules.isMxikMarking` bo'lmasa, uning o'rniga mavjud "MXIK markirovka ro'yxatida" funksiyasini qo'ying (02009, 02201, 02202, 02203–02208, 024).

### 6.2. `lib/changes/domain/marking/mxik_rules.dart`

```diff
@@ -30,22 +30,40 @@ class MxikRules {
       mxikStr.startsWith('02208') ||
       mxikStr.startsWith('024');
 
+  /// MXIK bo'yicha avto-aniqlash shu mahsulotga qo'llanadimi (sozlamalardan
+  /// qat'i nazar — OFD va "Avto markirovkani aniqlash" ni chaqiruvchi tekshiradi).
+  ///
+  /// `is_marking` (adminka bayrog'i) — markirovkalilikning BIRINCHI mezoni:
+  ///   - `false` — adminka aniq "markirovkali emas" degan. MXIK markirovka
+  ///     ro'yxatida bo'lsa ham (adminkada MXIK xato kiritilgan) mahsulot
+  ///     markirovkali deb HISOBLANMAYDI: markirovka dialogi chiqmaydi, savatga
+  ///     oddiy qator tushadi; fiskalga statik MXIK ketadi (`FiscalMxikFallback`).
+  ///     (2026-09-11, foydalanuvchi talabi)
+  ///   - `null` — bayroq kelmagan: eski xatti-harakat, MXIK bo'yicha aniqlanadi.
+  ///   - `true` — bu yerga kelmaydi (`isProductMarkable` avvalroq true qaytaradi).
+  static bool isMxikAutoDetectCandidate(ItemModel product) =>
+      product.isMarking != false &&
+      isMxikMarking((product.mxikCode ?? '').trim());
+
   /// Mahsulot markirovkali deb hisoblanadimi.
   /// Qoidalar:
   ///   0) Adminkada OFD o'chiq bo'lsa — hech narsa markirovkali emas
   ///   1) `product.isMarking == true` → markirovkali (sozlamadan qat'iy nazar, OFD ON bo'lsa)
-  ///   2) Aks holda "Avto markirovkani aniqlash" sozlamasi yoqilgan bo'lsa
-  ///      va MXIK kod ro'yxatda bo'lsa (`isMxikMarking`) → markirovkali
-  ///   3) "Avto markirovkani aniqlash" o'chirilgan bo'lsa MXIK umuman tekshirilmaydi
+  ///   2) `product.isMarking == false` → markirovkali EMAS (MXIK tekshirilmaydi)
+  ///   3) Aks holda (`null`) "Avto markirovkani aniqlash" sozlamasi yoqilgan
+  ///      bo'lsa va MXIK kod ro'yxatda bo'lsa (`isMxikMarking`) → markirovkali
+  ///   4) "Avto markirovkani aniqlash" o'chirilgan bo'lsa MXIK umuman tekshirilmaydi
   ///
   /// Savat qatorining `marking` bayrog'i ham shu qarorni ishlatadi
   /// (`SoldItemBuilder`) — aks holda OFD o'chiq bo'lsa ham qator markirovka
   /// guruhi bo'lib qolib, qty tahriri bloklanardi.
+  /// `addProduct` va skaner yo'li (`OrderingProvider4`) ham xuddi shu
+  /// [isMxikAutoDetectCandidate] ni ishlatadi — qoida bitta joyda.
   static bool isProductMarkable(ItemModel product) {
     if (!OfdAdminSetting.isEnabled) return false;
     if (product.isMarking ?? false) return true;
     if (!MarkingSettingHelper.isAutoDetectEnabled) return false;
-    return isMxikMarking((product.mxikCode ?? '').trim());
+    return isMxikAutoDetectCandidate(product);
   }
```

Kontekst: `OfdAdminSetting.isEnabled` = `Pref markCheckWithOfd` (adminkadan OFD yoqiqmi), `MarkingSettingHelper.isAutoDetectEnabled` = OFD yoqiq && `Pref sellProductsWithMarking` ("Avto markirovkani aniqlash"). `isProductMarkable` dan `resolveProductType`/`resolveProductPackage` (backend `product_type`/`product_package`) va savat qatorining `marking` bayrog'i chiqadi — shuning uchun `is_marking=false` qatorda ular oddiy tovardagidek bo'sh bo'ladi.

### 6.3. `lib/changes/providers/ordering_provider_4.dart`

Ikki joy: `addProduct` (mahsulot qo'shish) va `onBarcodeScanned` (skaner). Ikkalasida ham `_isMxikMarking(mxikStr)` → `MxikRules.isMxikAutoDetectCandidate(product)`.

```diff
@@ -370,13 +370,15 @@ class OrderingProvider4 extends ChangeNotifier {
         'isTarozi': isTarozi,
       });
 
-      final mxikStr = (product.mxikCode ?? product.mxikCode ?? '').trim();
       final bool markCheckEnabled =
           Pref.getBool(PrefKeys.markCheckWithOfd, false);
       final bool sellWithMarkingEnabled =
           Pref.getBool(PrefKeys.sellProductsWithMarking, true);
-      final bool isMarkingByMxik =
-          markCheckEnabled && sellWithMarkingEnabled && _isMxikMarking(mxikStr);
+      // `is_marking == false` bo'lsa MXIK ro'yxatda bo'lsa ham markirovka
+      // dialogi chiqmaydi — oddiy mahsulot (qoida: MxikRules).
+      final bool isMarkingByMxik = markCheckEnabled &&
+          sellWithMarkingEnabled &&
+          MxikRules.isMxikAutoDetectCandidate(product);
 
       final isMarking =
           markCheckEnabled && (product.isMarking == true || isMarkingByMxik);
@@ -2940,8 +2942,11 @@ class OrderingProvider4 extends ChangeNotifier {
           Pref.getBool(PrefKeys.markCheckWithOfd, false);
       final bool sellWithMarkingEnabled =
           Pref.getBool(PrefKeys.sellProductsWithMarking, true);
-      final bool isMarkingByMxik =
-          markCheckEnabled && sellWithMarkingEnabled && _isMxikMarking(mxikStr);
+      // `is_marking == false` bo'lsa MXIK ro'yxatda bo'lsa ham markirovka
+      // dialogi chiqmaydi — oddiy mahsulot (qoida: MxikRules).
+      final bool isMarkingByMxik = markCheckEnabled &&
+          sellWithMarkingEnabled &&
+          MxikRules.isMxikAutoDetectCandidate(item);
 
       if (markCheckEnabled && _isAlcoholMxik(mxikStr)) {
         Pref.setBool(PrefKeys.isCashDisableForAlcohol, true);
@@ -3002,8 +3007,6 @@ class OrderingProvider4 extends ChangeNotifier {
     }
   }
 
-  bool _isMxikMarking(String mxikStr) => MxikRules.isMxikMarking(mxikStr);
-
   bool _isAlcoholMxik(String mxikStr) => MxikRules.isAlcoholMxik(mxikStr);
```

InVan 1 da bu shart `if (product.isMarking == true || mxik.startsWith('0220...'))` ko'rinishida bo'lsa, MXIK qismini `product.isMarking != false && <MXIK ro'yxatda>` ga o'zgartiring. Skaner yo'lidagi `mxikStr` alkogol tekshiruvida (`_isAlcoholMxik`) ishlatilgani uchun u yerda qoldi; `addProduct` da endi kerak emas.

### 6.4. `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart`

`saleOnOFD` — fiskal body'ni (`params.items[]`) yig'adigan yagona joy; sotuv (`pressPaymentButtonOnlyOFD`), vozvrat (`ReturnBloc`) va qayta yuborish (`PreOfdBloc`) shu orqali o'tadi.

```diff
@@ -1,10 +1,12 @@
 
 import 'dart:convert';
 import 'package:flutter/foundation.dart';
+import 'package:invan2/changes/domain/marking/fiscal_mxik_fallback.dart';
 import 'package:invan2/changes/models/discount_model.dart';
 import 'package:invan2/changes/models/ofd/epos_response_model.dart';
 import 'package:invan2/changes/models/product/sale_item_model.dart';
 import 'package:invan2/changes/models/product_discount_model.dart';
+import 'package:invan2/changes/services/log_helper.dart';
 import 'package:invan2/changes/services/payment/click_service.dart';
 import 'package:invan2/changes/services/receipt_api_4.dart';
 import 'package:invan2/features/features.dart';
@@ -216,6 +218,27 @@ class ReceiptSingleton4 {
   }
 
  
+  /// Chek qatori mahsulotining adminka `is_marking` bayrog'i (katalogdan).
+  ///
+  /// Bayroq chek qatorida saqlanmaydi, shuning uchun `ItemsSingleton` dan
+  /// o'qiladi. Faqat fallback UMUMAN mumkin bo'lganda (MXIK markirovka
+  /// ro'yxatida va KM yo'q) qidiriladi — katalog bo'ylab chiziqli qidiruv
+  /// har qator uchun bekorga yurmasin.
+  ///
+  /// Mahsulot katalogda yo'q (o'chirilgan, eski chek vozvrati) yoki qidiruv
+  /// xato bersa — `false`: qaror MXIK va KM bo'yicha qilinadi. Bu yo'l to'lov
+  /// yo'li, shuning uchun hech qachon exception tashlamasligi kerak.
+  static bool _isMarkingInCatalog(ReceiptModelSoldItem4 e) {
+    if (!FiscalMxikFallback.mayNeedFallback(mxik: e.mxik, mark: e.mark)) {
+      return false; // natija baribir ishlatilmaydi — qidiruv shart emas
+    }
+    try {
+      return ItemsSingleton.getProductById(e.productId)?.isMarking ?? false;
+    } catch (_) {
+      return false;
+    }
+  }
+
     static Map<String, dynamic> saleOnOFD(ReceiptModel4 incomingReceipt) {
     ReceiptModel4 receipt = ReceiptApi4.func(incomingReceipt);
 
@@ -288,6 +311,14 @@ class ReceiptSingleton4 {
     String terId = Pref.getString(PrefKeys.terminalID, '');
     double totalPrice = ItemsSingleton.getOfdTotalPrice(receipt.soldItemList);
 
+    // Adminkada markirovkali deb belgilanMAGAN (`is_marking=false`), lekin
+    // MXIK'i markirovka ro'yxatida bo'lgan va KM siz qator → fiskalga statik
+    // MXIK va bo'sh shtrix-kod ketadi (adminkada MXIK xato kiritilgan holat;
+    // aks holda soliq chekni rad etadi). FAQAT fiskal body — `order_pos`
+    // (`product_mxik`, `product_barcode`) va savat qatori o'zgarmaydi. Sotuv va
+    // vozvrat bir xil. Qarang: lib/changes/domain/marking/fiscal_mxik_fallback.dart
+    final String staticMxik = Pref.getString(PrefKeys.mxikCode, '');
+
     // OFD itemlarini avval MODEL sifatida quramiz (toJson keyin). Shunda
     // yuborishdan oldin §10.2.1 balansini tekshirib/tuzatish imkoni bo'ladi.
     final List<SalingItemModel> ofdItems = receipt.soldItemList.map((e) {
@@ -299,13 +330,29 @@ class ReceiptSingleton4 {
       );
       num price = _countPrice(e);
 
+      final FiscalItemCodes codes = FiscalMxikFallback.resolve(
+        isMarkingProduct: _isMarkingInCatalog(e),
+        mxik: e.mxik,
+        mark: e.mark,
+        barcode: e.barcode,
+        staticMxik: staticMxik,
+      );
+      if (codes.substituted) {
+        LogHelper.write(
+          LogLevel.warn,
+          'FISKAL MXIK FALLBACK: "${e.productName}" is_marking=false, '
+          "MXIK=${e.mxik} markirovka ro'yxatida, KM yo'q -> "
+          "SPIC=${codes.classCode}, Barcode='' (adminkada MXIK tekshirilsin)",
+        );
+      }
+
       return SalingItemModel(
         id: e.productId,
         tin: e.commissionTIN,
         label: e.mark ?? '',
         amount: e.value * 1000,
-        barcode: e.barcode,
-        classCode: e.mxik,
+        barcode: codes.barcode,
+        classCode: codes.classCode,
         name: e.productName.replaceAll(' //blok', ''),
         discount: discount,
         ownerType: e.ownerType,
```

`LogHelper.write` — faylga yozadigan, to'liq try/catch ichidagi log. InVan 1 da bo'lmasa oddiy `print` yoki mavjud log xizmati. `ItemsSingleton.getProductById` — xotiradagi katalogdan id bo'yicha (katta-kichik harf farqsiz) qidiruv.

### 6.5. YANGI: `test/fiscal_mxik_fallback_test.dart`

Sof qoida (15 test) + `saleOnOFD` orqali haqiqiy fiskal body (9 test). Harness (`setUpPosTestEnv`, `kCashierId`, ...) InVan 2 ga xos — InVan 1 da Pref/Hive setup'ini o'zingiznikiga moslang; `expect` lar o'zgarmaydi.

```dart
// Fiskal MXIK fallback — test.
//
// HOLAT (2026-09-11): adminkada mahsulot markirovkali deb belgilanMAGAN
// (`is_marking=false` — birinchi mezon), lekin unga markirovka talab qiladigan
// MXIK (02202... va h.k.) xato kiritilgan; mahsulotda markirovka kodi yo'q.
// Bunday qator fiskal modulga asl MXIK bilan ketsa soliq rad etadi.
//
// KUTILGAN: FAQAT fiskal body'da `classCode` → statik MXIK (019...),
// `barcode` → bo'sh. Backend chek `order_pos` (`product_mxik`) va savat qatori
// o'zgarmaydi. Sotuv va vozvratda bir xil.
//
// Uch shart birga: is_marking=false + MXIK ro'yxatda + KM yo'q.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/marking/fiscal_mxik_fallback.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStaticMxik = '01905012001000000';
const kSuvMxik = '02202001001000000'; // suv — markirovka ro'yxatida
const kPivoMxik = '02203001001000000'; // pivo — alkogol, ro'yxatda
const kSigaretaMxik = '02400000000000000'; // sigareta — ro'yxatda
const kSharbatMxik = '02009001001000000'; // sharbat — ro'yxatda
const kOddiyMxik = '01234567890123456'; // oddiy tovar
const kBarcode = '4780000000001';
const kMark = '0104780000000001215Ab1cD2eF3g';

/// Katalog mahsuloti IDlari (is_marking bayrog'i katalogdan o'qiladi).
const kSuvXatoId = 'suv-xato'; // is_marking=false, MXIK 02202 (adminka xatosi)
const kSuvHaqiqiyId = 'suv-haqiqiy'; // is_marking=true, MXIK 02202
const kNonId = 'non'; // is_marking=false, oddiy MXIK
const kOchirilganId = 'ochirilgan'; // katalogda YO'Q

ItemModel product(String id, {required bool isMarking, required String mxik}) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.isMarking = isMarking;
  m.mxikCode = mxik;
  m.barcode = [kBarcode];
  return m;
}

ReceiptModelSoldItem4 row({
  required String mxik,
  String? mark,
  String productId = kSuvXatoId,
  String name = 'Suv 1L',
  double price = 5000,
  double value = 1,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: kBarcode,
    sku: 1001,
    vatPercent: 12,
    vat: (price * 12) / 112,
    mxik: mxik,
    tin: '',
    onlyPrice: price,
    realPrice: price,
    price: price,
    cost: 0,
    vatName: 'НДС 12%',
    createdTime: DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: name,
    sellerId: kCashierId,
    soldBy: kCashierId,
    singleDiscount: 0,
    ownerType: 1,
    mark: mark,
    marking: mark != null,
    packageCode: 'PACK-1',
    packageName: 'dona',
  );
}

ReceiptModel4 receiptWith(List<ReceiptModelSoldItem4> rows,
    {bool isRefund = false}) {
  double total = 0;
  for (final r in rows) {
    total += r.price * r.value;
  }
  final r = ReceiptModel4(
    createdDate: '2026-09-11 10:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'ext-1',
    orderType: isRefund ? 'refund' : 'sale',
    shopId: 'shop-1',
    userId: kUserId,
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: kCashierId,
    cashierName: kCashierName,
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: isRefund,
    totalPrice: total,
    uploaded: false,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: isRefund ? 'ext-0' : '',
    posName: 'Test POS',
    isDonate: false,
  );
  r.soldItemList.addAll(rows);
  r.payment.add(
    ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: total),
  );
  return r;
}

List<Map<String, dynamic>> ofdItems(ReceiptModel4 r) {
  final body = ReceiptSingleton4.saleOnOFD(r);
  return (body['params']['items'] as List).cast<Map<String, dynamic>>();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('needsFallback (sof qoida)', () {
    test('is_marking=false + markirovka MXIK + KM yo\'q → kerak', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: null),
          isTrue);
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: ''),
          isTrue);
    });

    test('is_marking=TRUE → hech qachon kerak emas (haqiqiy markirovkali)', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: true, mxik: kSuvMxik, mark: null),
          isFalse);
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: true, mxik: kSuvMxik, mark: kMark),
          isFalse);
    });

    test('KM faqat bo\'sh joy → KM yo\'q deb hisoblanadi', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: '   '),
          isTrue);
    });

    test('is_marking=false, lekin KM skanerlangan → kerak emas', () {
      // "Avto markirovkani aniqlash" haqiqiy markirovkali tovarni ushlagan —
      // asl MXIK ketishi shart.
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: kMark),
          isFalse);
    });

    test('oddiy MXIK + KM yo\'q → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kOddiyMxik, mark: null),
          isFalse);
    });

    test('statik MXIK ning o\'zi ro\'yxatda emas → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kStaticMxik, mark: null),
          isFalse);
    });

    test('bo\'sh MXIK → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: '', mark: null),
          isFalse);
    });

    test('butun avto-markirovka ro\'yxati qamrab olinadi', () {
      for (final m in [kSuvMxik, kPivoMxik, kSigaretaMxik, kSharbatMxik]) {
        expect(
            FiscalMxikFallback.needsFallback(
                isMarkingProduct: false, mxik: m, mark: null),
            isTrue,
            reason: m);
      }
      for (final p in ['02201', '02204', '02205', '02206', '02207', '02208']) {
        expect(
            FiscalMxikFallback.needsFallback(
                isMarkingProduct: false, mxik: '${p}000000000000', mark: null),
            isTrue,
            reason: p);
      }
    });

    test('MXIK atrofidagi bo\'sh joy e\'tiborga olinmaydi', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: ' $kSuvMxik ', mark: null),
          isTrue);
    });
  });

  group('resolve (sof qoida)', () {
    test('almashtirish: classCode = statik, barcode bo\'sh', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isTrue);
      expect(c.classCode, kStaticMxik);
      expect(c.barcode, '');
    });

    test('is_marking=true → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: true,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('KM bor → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: kMark,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('oddiy tovar → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kOddiyMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kOddiyMxik);
      expect(c.barcode, kBarcode);
    });

    test('statik MXIK bo\'sh (Pref yozilmagan) → xavfsiz: asl MXIK qoladi',
        () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: '  ',
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('statik MXIK atrofidagi bo\'sh joy tozalanadi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: ' $kStaticMxik ',
      );
      expect(c.classCode, kStaticMxik);
    });
  });

  group('saleOnOFD (fiskal body)', () {
    setUpAll(() async {
      await setUpPosTestEnv('fiscal_mxik_fallback_test',
          withEmployee: false);
      await Pref.setString(PrefKeys.mxikCode, kStaticMxik);
    });
    tearDownAll(tearDownPosTestEnv);

    setUp(() {
      // Katalog: `is_marking` shu yerdan o'qiladi.
      ItemsSingleton.products = [
        product(kSuvXatoId, isMarking: false, mxik: kSuvMxik),
        product(kSuvHaqiqiyId, isMarking: true, mxik: kSuvMxik),
        product(kNonId, isMarking: false, mxik: kOddiyMxik),
      ];
    });
    tearDown(() => ItemsSingleton.products = []);

    test(
        'sotuv: is_marking=false + KM siz suv → statik SPIC, bo\'sh Barcode; qolganlar tegilmaydi',
        () {
      final rows = [
        row(mxik: kSuvMxik, productId: kSuvXatoId),
        row(mxik: kSuvMxik, mark: kMark, productId: kSuvHaqiqiyId),
        row(mxik: kOddiyMxik, productId: kNonId, name: 'Non'),
      ];
      final items = ofdItems(receiptWith(rows));

      expect(items.length, 3);

      final xato = items.firstWhere((e) => e['id'] == kSuvXatoId);
      expect(xato['classCode'], kStaticMxik);
      expect(xato['barcode'], '');
      expect(xato['label'], '');

      final haqiqiy = items.firstWhere((e) => e['id'] == kSuvHaqiqiyId);
      expect(haqiqiy['classCode'], kSuvMxik);
      expect(haqiqiy['barcode'], kBarcode);
      expect(haqiqiy['label'], kMark);

      final non = items.firstWhere((e) => e['id'] == kNonId);
      expect(non['classCode'], kOddiyMxik);
      expect(non['barcode'], kBarcode);
      expect(non['label'], '');
    });

    test('is_marking=true + KM yo\'q (masalan invoice qatori) → asl MXIK qoladi',
        () {
      final items =
          ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kSuvHaqiqiyId)]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['barcode'], kBarcode);
    });

    test('is_marking=false, lekin KM skanerlangan (avto-aniqlash) → asl MXIK',
        () {
      final items = ofdItems(
          receiptWith([row(mxik: kSuvMxik, mark: kMark, productId: kSuvXatoId)]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['barcode'], kBarcode);
      expect(items.single['label'], kMark);
    });

    test('mahsulot katalogda yo\'q (o\'chirilgan) → MXIK + KM bo\'yicha almashtiriladi',
        () {
      final items =
          ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kOchirilganId)]));
      expect(items.single['classCode'], kStaticMxik);
      expect(items.single['barcode'], '');
    });

    test('alkogol MXIK, is_marking=false, KM siz → statik SPIC', () {
      ItemsSingleton.products = [
        product('pivo', isMarking: false, mxik: kPivoMxik),
      ];
      final items = ofdItems(
          receiptWith([row(mxik: kPivoMxik, productId: 'pivo', name: 'Pivo')]));
      expect(items.single['classCode'], kStaticMxik);
      expect(items.single['barcode'], '');
    });

    test('vozvrat: sotuv bilan bir xil almashtiriladi', () {
      final rows = [
        row(mxik: kSuvMxik, productId: kSuvXatoId),
        row(mxik: kSuvMxik, mark: kMark, productId: kSuvHaqiqiyId),
      ];
      final body =
          ReceiptSingleton4.saleOnOFD(receiptWith(rows, isRefund: true));
      expect(body['method'], 'refund');
      final items =
          (body['params']['items'] as List).cast<Map<String, dynamic>>();

      final xato = items.firstWhere((e) => e['id'] == kSuvXatoId);
      expect(xato['classCode'], kStaticMxik);
      expect(xato['barcode'], '');

      final haqiqiy = items.firstWhere((e) => e['id'] == kSuvHaqiqiyId);
      expect(haqiqiy['classCode'], kSuvMxik);
      expect(haqiqiy['barcode'], kBarcode);
    });

    test(
        'faqat fiskal: chek qatori va order_pos JSON (product_mxik/product_barcode) o\'zgarmaydi',
        () {
      final r = receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId)]);
      ofdItems(r);

      final item = r.soldItemList.first;
      expect(item.mxik, kSuvMxik);
      expect(item.barcode, kBarcode);
      expect(item.toJson()['product_mxik'], kSuvMxik);
      expect(item.toJson()['product_barcode'], kBarcode);
    });

    test('narx/summa maydonlariga ta\'sir qilmaydi', () {
      final items = ofdItems(
          receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId, price: 5000)]));
      expect(items.single['price'], 500000); // tiyinda
      expect(items.single['amount'], 1000);
    });

    test('Pref statik MXIK bo\'sh → asl MXIK ketadi (xavfsiz chetki holat)',
        () async {
      await Pref.setString(PrefKeys.mxikCode, '');
      try {
        final items =
            ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId)]));
        expect(items.single['classCode'], kSuvMxik);
        expect(items.single['barcode'], kBarcode);
      } finally {
        await Pref.setString(PrefKeys.mxikCode, kStaticMxik);
      }
    });
  });
}
```

### 6.6. YANGI: `test/fiscal_mxik_fallback_scenarios_test.dart` (20 chetki holat)

To'liq matn InVan 2 repo'sida (433 qator). Holatlar ro'yxati — InVan 1 da ham shular tekshirilishi kerak:

| # | Holat | Kutilgan |
|---|---|---|
| 1 | Blok (box) qatori, `is_marking=false`, MXIK 022 | blok KM saqlanmaydi, `marking=false`, fiskalga statik SPIC, nomdan ` //blok` kesiladi |
| 1 | Blok, `is_marking=true` | KM saqlanadi, asl SPIC, Label=KM |
| 2 | Invoice qatori, `is_marking=false`, MXIK 022 | oddiy qator, statik SPIC, `amount` = qty×1000 |
| 2 | Invoice, `is_marking=true`, KM yo'q | asl SPIC, bo'sh Label (eski xatti-harakat) |
| 3 | DataMatrix to'g'ridan-to'g'ri skan, `is_marking=false` | mahsulot GTIN bo'yicha topiladi, `mark` biriktirilMAYDI |
| 3 | DataMatrix, `is_marking=true` / `null` | `mark` biriktiriladi, kripto qism kesilgan |
| 4 | `is_marking=null`, avto-aniqlash yoqiq, KM skanerlangan | markirovkali, asl SPIC + Label |
| 4 | `is_marking=null`, avto-aniqlash o'chiq | oddiy qator, statik SPIC (null ≠ true) |
| 5 | Katalog bo'sh | xato yo'q, MXIK+KM bo'yicha statik |
| 5 | Katalogda `id=null` mahsulot bor | to'lov yo'li yiqilmaydi (try/catch), statik |
| 5 | Oddiy MXIK qatorda buzilgan katalog | qidiruv chaqirilmaydi, asl SPIC |
| 5 | `productId` katta-kichik harf farqi | topiladi |
| 6 | Sotuvda `false`, keyin adminka `true` qildi, vozvrat | vozvrat ASL MXIK (katalog joriy holatidan) — 8-bo'limga qarang |
| 6 | Sotuv va vozvrat `false` | ikkalasi statik |
| 7 | Alkogol MXIK + `is_marking=false` | statik SPIC, LEKIN `cashHiddenByMarking` hamon `true` (naqd yopiq) |
| 8 | 3 dona oddiy qator | `amount` 3000, `price` tiyinda, statik SPIC |
| 8 | `isDeleted` qator `saleOnOFD` ga kelsa | xato yo'q |
| 8 | `mxik` bo'sh qator | fallback aralashmaydi, SPIC bo'sh (eski) |
| 9 | 20 000 katalog, 60 qator | < 1 s (o'lchandi: 48 ms) |

### 6.7. Mavjud testlarga qo'shimchalar

```diff
--- a/test/mxik_rules_test.dart
+++ b/test/mxik_rules_test.dart
@@ -155,6 +155,77 @@ void main() {
 
       expect(MxikRules.isProductMarkable(item()), isFalse);
     });
+
+    // 2026-09-11: `is_marking` — birinchi mezon. Adminka aniq `false` degan
+    // bo'lsa MXIK ro'yxatda bo'lsa ham (adminkada MXIK xato) markirovkali emas.
+    test('is_marking = false + MXIK ro\'yxatda -> markirovkali EMAS', () async {
+      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
+      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
+
+      expect(
+        MxikRules.isProductMarkable(
+            item(mxik: '02202001001000000', isMarking: false)),
+        isFalse,
+      );
+      expect(
+        MxikRules.isProductMarkable(
+            item(mxik: '02205000000000000', isMarking: false)),
+        isFalse,
+        reason: 'alkogol MXIK ham',
+      );
+    });
+
+    test('is_marking = null (bayroq kelmagan) + MXIK ro\'yxatda -> markirovkali',
+        () async {
+      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
+      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
+
+      expect(
+        MxikRules.isProductMarkable(
+            item(mxik: '02202001001000000', isMarking: null)),
+        isTrue,
+      );
+    });
+
+    test('is_marking = true, MXIK ro\'yxatda -> markirovkali (o\'zgarmagan)',
+        () async {
+      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
+      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
+
+      expect(
+        MxikRules.isProductMarkable(
+            item(mxik: '02202001001000000', isMarking: true)),
+        isTrue,
+      );
+    });
+  });
+
+  group('isMxikAutoDetectCandidate (sozlamalarsiz sof qoida)', () {
+    test('is_marking = false -> MXIK ro\'yxatda bo\'lsa ham false', () {
+      expect(
+        MxikRules.isMxikAutoDetectCandidate(
+            item(mxik: '02202001001000000', isMarking: false)),
+        isFalse,
+      );
+    });
+
+    test('is_marking = null + MXIK ro\'yxatda -> true', () {
+      expect(
+        MxikRules.isMxikAutoDetectCandidate(item(mxik: '02202001001000000')),
+        isTrue,
+      );
+    });
+
+    test('is_marking = null + MXIK ro\'yxatda emas -> false', () {
+      expect(
+        MxikRules.isMxikAutoDetectCandidate(item(mxik: '01234567890123456')),
+        isFalse,
+      );
+    });
+
+    test('mxikCode null -> false', () {
+      expect(MxikRules.isMxikAutoDetectCandidate(item()), isFalse);
+    });
   });
 
   group('resolveProductType / resolveProductPackage', () {
@@ -163,6 +234,13 @@ void main() {
       await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
     });
 
+    test('is_marking = false + MXIK ro\'yxatda -> bo\'sh type va package', () {
+      final p = item(mxik: '02202001001000000', isMarking: false);
+
+      expect(MxikRules.resolveProductType(p), '');
+      expect(MxikRules.resolveProductPackage(p), '');
+    });
+
     test('markirovkali emas -> bo\'sh type va bo\'sh package', () {
       final p = item(mxik: '99999999999999999');
```

```diff
--- a/test/sold_item_builder_test.dart
+++ b/test/sold_item_builder_test.dart
@@ -99,6 +99,20 @@ void main() {
       expect(r.marking, isFalse);
     });
 
+    // 2026-09-11: adminka `is_marking=false` degan bo'lsa MXIK ro'yxatda
+    // bo'lsa ham oddiy qator (markirovka dialogi ham chiqmaydi).
+    test('is_marking = false + MXIK ro\'yxatda -> marking false, type bo\'sh',
+        () {
+      final r = SoldItemBuilder.build(
+          product(mxik: '02202001001000000', isMarking: false), 5000, 1, false);
+
+      expect(r.marking, isFalse);
+      expect(r.productType, '');
+      expect(r.productPackage, '');
+      expect(r.mxik, '02202001001000000',
+          reason: 'savat qatorida asl MXIK qoladi (order_pos o\'zgarmaydi)');
+    });
+
     test('markirovkali mahsulotga productType va KIZ qo\'yiladi', () {
```

```diff
--- a/test/marked_row_builder_test.dart
+++ b/test/marked_row_builder_test.dart
@@ -21,7 +21,7 @@ const kPlainMxik = '01101001001000000';
 
 ItemModel product({
   String mxik = kMarkingMxik,
-  bool isMarking = false,
+  bool? isMarking, // null = bayroq kelmagan (MXIK bo'yicha avto-aniqlash)
   String unit = 'dona',
@@ -78,6 +78,21 @@ void main() {
       expect(row(p: product(mxik: kPlainMxik)).marking, isFalse);
     });
 
+    // 2026-09-11: `is_marking=false` — MXIK ro'yxatda bo'lsa ham oddiy qator.
+    test('is_marking = false: marking false, mark null, type bo\'sh', () {
+      final r = row(p: product(isMarking: false), mark: 'KM-XYZ');
+      expect(r.marking, isFalse);
+      expect(r.mark, isNull);
+      expect(r.productType, isEmpty);
+      expect(r.productPackage, isEmpty);
+    });
+
+    test('is_marking = true: marking true, mark saqlanadi', () {
+      final r = row(p: product(isMarking: true), mark: 'KM-XYZ');
+      expect(r.marking, isTrue);
+      expect(r.mark, 'KM-XYZ');
+    });
+
     test('OFD o\'chiq bo\'lsa marking false va mark null', () async {
```

DIQQAT: bu testda helper default'i `isMarking = false` edi — yangi qoida bilan u "markirovkali emas" degani. Niyat "MXIK avto-aniqlash" bo'lgani uchun default `null` qilindi. InVan 1 testlarida ham shunday default bo'lsa, xuddi shunday o'zgartiring, aks holda eski testlar yiqiladi.

```diff
--- a/test/invoice_row_builder_test.dart
+++ b/test/invoice_row_builder_test.dart
@@ -43,12 +43,14 @@ ItemModel product({
   String mxik = '01101001001000000',
   String? ownerType = '2',
+  bool? isMarking,
 }) {
   final m = ItemModel();
   m.id = 'suv-id';
   m.name = 'Suv (katalogdan)';
   m.sku = '1001';
   m.mxikCode = mxik;
+  m.isMarking = isMarking;
@@ -184,6 +186,14 @@ void main() {
       expect(r.marking, isTrue);
     });
 
+    // 2026-09-11: `is_marking=false` — MXIK ro'yxatda bo'lsa ham oddiy qator.
+    test('is_marking = false + MXIK ro\'yxatda -> marking false', () {
+      final r = InvoiceRowBuilder.build(invoiceItem(),
+          product(mxik: '02202001001000000', isMarking: false));
+      expect(r.marking, isFalse);
+      expect(r.mxik, '02202001001000000');
+    });
+
```

```diff
--- a/test/box_row_builder_test.dart
+++ b/test/box_row_builder_test.dart
@@ -22,12 +22,14 @@ ItemModel product({
   String? ownerType = '2',
+  bool? isMarking,
 }) {
   final m = ItemModel();
   m.id = 'suv-id';
   m.name = name;
   m.sku = '1001';
   m.mxikCode = mxik;
+  m.isMarking = isMarking;
@@ -84,6 +86,16 @@ void main() {
       expect(row(p: product(mxik: kMarkingMxik), rawMark: 'KM-9').mark, 'KM-9');
     });
 
+    // 2026-09-11: `is_marking=false` — MXIK ro'yxatda bo'lsa ham blok KM
+    // saqlanmaydi (mahsulot markirovkali emas).
+    test('is_marking = false + MXIK ro\'yxatda -> mark null', () {
+      expect(
+        row(p: product(mxik: kMarkingMxik, isMarking: false), rawMark: 'KM-9')
+            .mark,
+        isNull,
+      );
+    });
+
```

```diff
--- a/test/marking_flag_ofd_gating_test.dart
+++ b/test/marking_flag_ofd_gating_test.dart
@@ -14,6 +14,8 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:invan2/app_navigation.dart';
+import 'package:invan2/changes/dialogs/alcohol_warning_dialog.dart';
+import 'package:invan2/changes/dialogs/markirovka_dialog.dart';
 import 'package:invan2/changes/models/product/item_model.dart';
@@ -200,6 +202,56 @@ void main() {
     });
   });
 
+  // 2026-09-11: `is_marking=false` — adminka aniq "markirovkali emas" degan.
+  // MXIK 02202 (markirovka ro'yxatida) bo'lsa ham markirovka dialogi
+  // CHIQMAYDI, savatga oddiy qator tushadi (fiskalga esa statik MXIK ketadi —
+  // test/fiscal_mxik_fallback_test.dart).
+  group('OFD YOQIQ, avto-aniqlash YOQIQ, is_marking = false — dialog yo\'q',
+      () {
+    setUp(() async {
+      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
+      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
+    });
+
+    testWidgets('markirovka dialogi chiqmaydi, qator oddiy (marking = false)',
+        (tester) async {
+      final ctx = await appContext(tester);
+      ItemsSingleton.products = [suv(isMarking: false)];
+      final p = freshProvider();
+
+      p.addProduct(
+          value: 1, product: suv(isMarking: false), where: 'test', context: ctx);
+      await settle(tester);
+
+      expect(find.byType(MarkingDialog), findsNothing);
+      expect(cart(p), hasLength(1));
+      expect(cart(p).first.marking, isFalse);
+      expect(cart(p).first.mark, isNull);
+      expect(cart(p).first.mxik, kSuvMxik,
+          reason: 'savat qatorida asl MXIK qoladi — order_pos o\'zgarmaydi');
+    });
+
+    // Alkogol MXIK (02203) + is_marking=false: markirovka dialogi yo'q, lekin
+    // alkogol naqd-cheklov ogohlantirishi hamon MXIK bo'yicha chiqadi
+    // (o'zgarmagan qoida — CashRestrictionRules).
+    testWidgets('alkogol MXIK: MarkingDialog yo\'q, naqd ogohlantirishi bor',
+        (tester) async {
+      final ctx = await appContext(tester);
+      final pivo = suv(isMarking: false, mxik: '02203001001000000');
+      ItemsSingleton.products = [pivo];
+      final p = freshProvider();
+
+      p.addProduct(value: 1, product: pivo, where: 'test', context: ctx);
+      await settle(tester);
+
+      expect(find.byType(MarkingDialog), findsNothing);
+      expect(find.byType(CashPaymentWarningDialog), findsOneWidget);
+      expect(cart(p), hasLength(1));
+      expect(cart(p).first.marking, isFalse);
+      expect(p.isCashPaymentHidden, isTrue,
+          reason: 'naqd cheklovi MXIK bo\'yicha — o\'zgarmagan');
+    });
+  });
```

## 7. Tekshirish

InVan 2 da (2026-09-11):
- `flutter test` — **1155/1155** o'tdi (44 tasi yangi)
- `flutter analyze` — yangi xato/ogohlantirish yo'q

Windows do'kon sinovi (kutilmoqda), OFD yoqiq, "Avto markirovkani aniqlash" yoqiq:
- [ ] Adminkada `is_marking=false`, MXIK `02202...` mahsulot skanerlanadi → markirovka dialogi CHIQMAYDI, oddiy qator, qty tahriri ishlaydi
- [ ] To'lov → Alice'da fiskal so'rov: `SPIC=01905012001000000`, `Barcode=""`, `Label=""` → soliq qabul qiladi
- [ ] O'sha chek `order_pos` da: `product_mxik=02202...`, `product_barcode` asl, `product_type=""`
- [ ] Log faylda `FISKAL MXIK FALLBACK: ...` qatori bor
- [ ] O'sha chekni vozvrat qilish → fiskal so'rovda ham `SPIC=019...` → qabul qilinadi
- [ ] Haqiqiy markirovkali (`is_marking=true`) suv → dialog chiqadi, KM bilan sotiladi, `SPIC` asl, `Label` to'la (regressiya yo'q)
- [ ] Markirovkali tovarni vozvrat qilish — modul qabul qiladimi (8-bo'lim, vozvrat)

## 8. Eslatmalar va ochiq savollar

**Alkogol MXIK xato kiritilgan mahsulot.** Markirovka dialogi chiqmaydi, fiskalga statik MXIK ketadi, LEKIN naqd to'lov cheklovi (`CashRestrictionRules.cashHiddenByMarking`) va alkogol ogohlantirishi hamon `row.mxik` bo'yicha ishlaydi — kassir faqat karta bilan sota oladi. Eski qoida, tegilmadi. Kerak bo'lsa `is_marking=false` da bu cheklovni ham olib tashlash mumkin (alohida qaror).

**`is_marking=null`.** Backend `is_marking` ni har doim yuborsa `null` amalda bo'lmaydi va "Avto markirovkani aniqlash" sozlamasi savatda deyarli ishlamaydi (faqat `true` bayroq dialog ochadi). Bu "is_marking birinchi mezon" talabiga mos.

**`switchMarking` sinxroni.** `get_items_service.dart` (default o'chiq sozlama) Soliq ro'yxati bo'yicha MXIK'i mos mahsulotlarga lokal `isMarking=true` qo'yadi — unda xato MXIK'li mahsulotga dialog yana chiqadi. Tegilmadi.

**Vozvrat (muhim, o'rganilgan).** InVan 2 da vozvrat lokal chekdan emas, **serverdan qayta yuklanadi** (`ReUpdateBloc` → `SearchReceiptService.getReceiptss(orderId)` → `ChecksSingleton.globalToLocall`). Server item modeli (`ItemsGTR`) `marking_names` ni o'qimaydi, `globalToLocall` da `mark:` izohda — **vozvrat qatorida KM hech qachon bo'lmaydi** (bu mendan oldingi holat). Qisman vozvrat `_itemCopyWith` ham `mark` ni ko'chirmaydi. Oqibatlar:

| Holat | Sotuvda fiskalga | Vozvratda fiskalga |
|---|---|---|
| `is_marking=false`, MXIK 022, KM siz | SPIC 019 | SPIC 019 — mos |
| `is_marking=true`, KM bilan | SPIC 022 + Label | SPIC 022, Label bo'sh — eski holat |
| sotuvdan keyin adminka `false`→`true` | SPIC 019 | SPIC 022, Label bo'sh |
| `is_marking=null`, avto-aniqlash bilan KM | SPIC 022 + Label | SPIC 019 — yangi nomuvofiqlik |
| yangilanishdan oldin `false` + KM bilan sotilgan | SPIC 022 + Label | SPIC 019 — faqat eski cheklar |

Fiskal modul vozvrat itemlarini asl sotuv bilan solishtirsa, oxirgi ikki qator rad etiladi (kam uchraydi). Solishtirmasa (hozircha markirovkali vozvratlar ishlayotgani shuni ko'rsatadi) — xavfsiz. Tavsiya: server javobida `items[].marking_names` kelsa, `globalToLocall` da `mark` ni tiklash — vozvratda KM ham ketadi, nomuvofiqlik yo'qoladi. Buning uchun Alice'da bitta vozvrat so'rovi javobini ko'rish kerak. InVan 1 da vozvrat qanday yig'ilishini (lokal chekdanmi, serverdanmi) alohida tekshiring.

**InVan 1 ga xos.** Agar InVan 1 da chek qatori `is_marking` ni saqlasa yoki mahsulot obyekti qatorda bo'lsa, `_isMarkingInCatalog` o'rniga to'g'ridan-to'g'ri o'sha bayroqni bering — katalog qidiruvi shart bo'lmaydi.
