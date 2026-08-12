# Task: Adminkada OFD o'chiq bo'lganda markirovka va cashsale sozlamalarini to'liq o'chirish

**Boshlangan:** 2026-08-07
**Holat:** in-progress
**Branch:** chore/lint-cleanup

## Maqsad

Adminkadan OFD (`apps_soliq_app` → `markCheckWithOfd`) o'chirilgan bo'lsa, undan kelib
chiqadigan sozlamalar ("Mahsulotning naqd to'lov cheklovi" va "Avto markirovkani
aniqlash") ham amalda ishlamasligi, sozlamalar sahifasida qulflangan bo'lishi kerak.
Markirovkali MXIK'li mahsulot (masalan suv `02201...`) oddiy mahsulot kabi urilishi kerak.

## Scope

Ta'sirlanadi:
- `lib/utils/helpers/` — OFD sozlama helperlari
- `lib/changes/domain/marking/mxik_rules.dart`
- `lib/changes/domain/cart/sold_item_builder.dart`
- `lib/changes/providers/ordering_provider_4.dart` (marking bayrog'i o'rnatiladigan joylar)
- `lib/features/settings/view/report_setting/settings_reports_page.dart`
- `lib/features/home/features/home_orders/order_list/order_list_item.dart`
- activate/update POS bloklari

Scope dan tashqari:
- OFD yoqilgan holatdagi markirovka oqimi (skan, ONKM validatsiya) — tegilmaydi
- Fiskal chek formati — `mark`/`marking_names` allaqachon to'g'ri gated, o'zgarmaydi

## Muammo tahlili (sessiya boshida topilgan)

Cashsale qismi avvalgi ishda to'g'ri bajarilgan. Markirovkada 2 ta bo'shliq bor edi:

**1. Savat qatorining `marking` bayrog'i OFD tekshiruvisiz o'rnatilardi** (3 joy):
- `sold_item_builder.dart:27`
- `ordering_provider_4.dart:722`
- `ordering_provider_4.dart:1607`

Uchalasi `(product.isMarking ?? false) || isMxikMarking(mxik)` ishlatardi.
Oqibati zanjiri (OFD o'chiq holatda):
- `basket_grouping.dart:110` → qator markirovka guruhi deb belgilanadi
- `order_list.dart:197` → tahrir `beginMarkGroupEdit` yo'liga ketadi
- `_saveMarkGroup:2040` → `currentCount` = qatorlar soni = **1** (oddiy yo'lda bir qatorga
  birlashadi), `newCount` = kiritilgan qty. `newCount >= currentCount` → o'zgarishsiz.
  Natijada **qty ni na oshirib, na kamaytirib bo'lardi** — faqat 0 qilib o'chirish ishlardi.
- `operation_on_product_provider.dart:1014` → `!target.marking` false → **blok qty tahriri ham
  ishlamasdi**.

**2. "Avto markirovkani aniqlash" switch'i qulflanmagan** — OFD o'chiq bo'lsa ham yoqiq
ko'rinardi va bosilardi (cashsale switch'i esa qulflangan edi).

Qo'shimcha: `markCheckWithOfd` o'qishlari ikki xil default ishlatardi (`false` va `true`).

## Bajarilgan

- [x] `OfdAdminSetting` yaratildi — OFD holatini o'qishning yagona nuqtasi va
      bog'liq sozlamalarni sinxronlash
  → lib/utils/helpers/ofd_admin_setting.dart
  → Sabab: `markCheckWithOfd` loyiha bo'ylab 10 joyda, ikki xil default bilan
    o'qilardi. Endi bitta joyda, bitta default (`true`, fail-safe).

- [x] `MarkingSettingHelper` yaratildi (`CashsaleSettingHelper` juftligi)
  → lib/utils/helpers/marking_setting_helper.dart
  → Sabab: markirovka avto-aniqlash ham cashsale kabi OFD ga bog'langan bo'lishi
    kerak edi, lekin uning uchun helper yo'q edi.

- [x] `CashsaleSettingHelper` soddalashtirildi — OFD o'qishi va `syncWithOfd`
      `OfdAdminSetting` ga ko'chdi
  → lib/utils/helpers/cashsale_setting_helper.dart

- [x] ASOSIY TUZATISH: savat qatorining `marking` bayrog'i endi
      `MxikRules.isProductMarkable` ga tayanadi (3 joy)
  → lib/changes/domain/cart/sold_item_builder.dart:30
  → lib/changes/providers/ordering_provider_4.dart:712
  → lib/changes/providers/ordering_provider_4.dart:1595
  → Sabab: OFD o'chiq bo'lganda qator markirovka guruhi bo'lib qolib,
    `_saveMarkGroup` orqali qty tahriri butunlay bloklanardi.

- [x] `MxikRules.isProductMarkable` helperlarga o'tkazildi
  → lib/changes/domain/marking/mxik_rules.dart:45

- [x] `ordering_provider_4` dagi qo'lda yozilgan markirovka mantiqi olib
      tashlandi (`addProduct` va skan yo'li endi bitta qarordan foydalanadi)
  → lib/changes/providers/ordering_provider_4.dart:428, 4241
  → Sabab: `addProduct` da 6 qatorlik takroriy mantiq `isProductMarkable` ning
    aynan o'zi edi.

- [x] Qolgan xom `Pref.getBool(markCheckWithOfd, ...)` o'qishlari helperlarga
      ko'chirildi (5 joy)
  → ordering_provider_4.dart:455, 587, 908, 1302
  → operation_on_product_provider.dart:126, 465
  → order_list_item.dart:40

- [x] Settings: "Avto markirovkani aniqlash" switch'i OFD o'chiq bo'lsa
      qulflanadi + izoh chiqadi (cashsale switch'i kabi)
  → lib/features/settings/view/report_setting/settings_reports_page.dart:167

- [x] Activate/Update POS endi ikkala sozlamani ham sinxronlaydi
  → lib/features/authentication/bloc/bloc_activate_pos/apd_bloc_bloc.dart:103
  → lib/changes/dialogs/upd/bloc/upd_bloc.dart:253

- [x] Testlar: 11 ta yangi test
  → test/ofd_admin_setting_test.dart (yangi, 9 ta)
  → test/sold_item_builder_test.dart (OFD o'chiq / avto-aniqlash o'chiq guruhlari)

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] Windows do'kon sinovi (pastdagi "Test / Verifikatsiya" ro'yxati bo'yicha)
- [ ] Sinov o'tsa — commit va relizga kiritish
- [ ] `ordering_provider_4.dart:4243` dagi ochiq savolni alohida tekshirish

## Qabul qilingan qarorlar

- `marking` bayrog'i endi `MxikRules.isProductMarkable` bilan bir xil qaror qabul qiladi —
  savat qatori mahsulot qo'shish paytidagi qaror bilan mos bo'lishi uchun
  (`ordering_provider_4.dart:436` allaqachon shu mantiqni ishlatardi).
- Yagona default `true` (fail-safe): kalit yo'q bo'lsa OFD cheklovlari YOQIQ hisoblanadi.
  Amalda kalit activate/update POS'da doim yoziladi, shuning uchun bu chetki holat.

## Ochiq savollar

- `ordering_provider_4.dart:4262` da skan yo'li faqat `isMarkingByMxik` ni tekshiradi,
  `product.isMarking` ni emas — MXIK notanish, lekin `is_marking=true` mahsulot skan
  qilinganda markirovka dialogi chiqmaydi. Bu shu task scope'idan tashqari, alohida
  tekshirilishi kerak.

## Test / Verifikatsiya

Bajarilgan (2026-08-07):
- `flutter test` → **369/369 o'tdi** (11 tasi yangi)
- `flutter analyze lib/ test/` → yangi error/warning yo'q (599 info, avval 601 edi)

Windows do'kon sinovi (KUTILMOQDA) — adminkadan OFD **o'chirilgan** POS'da:
- [ ] Markirovkali MXIK'li mahsulot (suv `02201...`) skan qilinadi → markirovka
      dialogi CHIQMAYDI, oddiy mahsulot kabi savatga tushadi
- [ ] Savatda o'sha qatorni bosib qty **oshirish** ishlaydi
- [ ] Qty **kamaytirish** ishlaydi (ilgari ikkalasi ham ishlamasdi)
- [ ] O'sha mahsulot blokda sotilsa — blok qty tahriri ishlaydi
- [ ] Sozlamalar → "Avto markirovkani aniqlash" va "Mahsulotning naqd to'lov
      cheklovini tekshirish" — ikkalasi ham o'chiq va qulflangan, izoh ko'rinadi
- [ ] Chek fiskalga ketadi, `marking_names` bo'sh

Adminkada OFD **yoqilgan** POS'da (regressiya tekshiruvi):
- [ ] Markirovkali mahsulot skan → mark dialogi chiqadi, avvalgidek ishlaydi
- [ ] Ikkala switch tahrirlanadi
- [ ] Markirovkali mahsulot savatda 1 qator + qty bo'lib guruhlanadi (avvalgidek)
- [ ] Alkogol qo'shilganda naqd to'lov ogohlantirishi chiqadi
