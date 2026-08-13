# Task: Cashback balansdan ortiq to'lash (kumulyativ tekshiruv yo'q)

**Boshlangan:** 2026-08-12
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad

Kassir "Bonus karta" tugmasini bir necha marta bosib, mijozning cashback
balansidan **ko'p** summa to'lay olardi. Real holat: balans 78 000, chekka
kiritilgan cashback 131 000. Sabab — balans tekshiruvi faqat *shu bosishda*
kiritilgan songa nisbatan qilinardi, chekka allaqachon kiritilgan cashback
hisobga olinmasdi.

## Scope

**Ta'sirlanadi:**
- `lib/changes/providers/ordering_provider_4.dart` → `typeFromCashbackBalance`
- `test/cashback_balance_test.dart` (yangi)

**Scope dan tashqari:**
- Ko'p-kassa / oflayn ssenariysi (balans snapshot'i, server yechimi yuklashda) —
  `## Ochiq savollar` ga qarang
- `_fromPointBalance` doim 0 bo'lishi — alohida masala, `## Ochiq savollar`
- Server tomoni (`api/v1/pay_by_loyalty`) — o'zgarmaydi

## Muammoning mexanikasi

Uch fayl birga xato hosil qiladi:

1. **`typeFromCashbackBalance`** (`ordering_provider_4.dart:3850`)
   ```dart
   if (balance > parsed) { ... }   // faqat YANGI son tekshiriladi
   ```
   Chekdagi mavjud cashback (`getSelectedPaymentSumma()`) hisobga olinmaydi.

2. **`allPaymentType`** (`ordering_provider_4.dart:3617`)
   ```dart
   _payByAll(summa + currentPaymentValue, payment);   // USTIGA qo'shiladi
   ```

3. **`getAvailableSumma`** (`payment_tally_controller.dart:65-74`)
   ataylab **tanlangan to'lov turini** `paid` dan chiqarib tashlaydi, shuning
   uchun yig'indining yagona chegarasi — chek jami summasi, balans emas.

**Qo'shimcha omil:** `balance > parsed` qat'iy `>` edi — ya'ni balansning
**to'liq** summasini bir bosishda kiritib bo'lmasdi (78 000 balansga 78 000
yozsa "yetarli emas" chiqardi). Bu kassirni summani **bo'lib** kiritishga
majburlardi — aynan bug'ni ochadigan yo'lga.

## Takrorlash (Windows kassada tasdiqlangan)

Balans 78 000, chek jami 100 000, markirovkasiz mahsulot:

| № | Harakat | Natija |
|---|---------|--------|
| 1 | `78000` → Bonus karta | ❌ "kartada yetarli emas" (qat'iy `>`) |
| 2 | `90000` → Bonus karta | ❌ "kartada yetarli emas" (to'g'ri) |
| 3 | `50000` → Bonus karta | ✅ CASHBACK = 50 000 |
| 4 | `50000` → Bonus karta | ✅ CASHBACK = **100 000** ← BUG |

Foydalanuvchidagi 131 000 shu ketma-ketlikning kattaroq varianti
(masalan 70 000 + 61 000, chek jami ≥ 131 000).

## Bajarilgan

- [x] Sabab aniqlandi — kumulyativ bo'lmagan balans tekshiruvi
  → `lib/changes/providers/ordering_provider_4.dart:3850` (eski holat)
  → Sabab: `allPaymentType` (`:3617`) summani ustiga qo'shadi, `getAvailableSumma`
    (`payment_tally_controller.dart:65-74`) esa tanlangan turni chegirmaydi —
    ya'ni yig'indi faqat chek jamisi bilan cheklanardi.

- [x] Windows kassada qo'lda takrorlandi (foydalanuvchi tasdiqladi)
  → 50 000 + 50 000 = 100 000, balans 78 000 bo'lsa ham o'tib ketdi
  → Sabab: sotuvni yakunlamasdan, to'lov ekranining o'zida ko'rinadi —
    real balansga zarar yetmaydi.

- [x] Tuzatish: tekshiruv qoldiq balans bo'yicha
  → `lib/changes/providers/ordering_provider_4.dart:3849-3873`
  → `used = getSelectedPaymentSumma()`, `freeBalance = balance - used`,
    `if (freeBalance >= parsed)`
  → Sabab: `allPaymentType` yig'ib borgani uchun tekshiruv ham yig'indi
    bo'yicha borishi shart.

- [x] Qat'iy `>` → `>=`
  → `lib/changes/providers/ordering_provider_4.dart:3863`
  → Sabab: `>` balansning aynan o'zini kiritishga yo'l qo'ymay, kassirni
    summani bo'lib kiritishga majburlardi — aynan bug'ni ochadigan yo'l.

- [x] Xato xabariga qoldiq balans qo'shildi
  → `lib/changes/providers/ordering_provider_4.dart:3868-3872`
  → Sabab: kassir "yetarli emas" o'rniga qancha ishlata olishini ko'rsin.
    l10n kaliti o'zgarmadi (`client_cartasida_yetarli_emas`).

- [x] Widget test — 12 ta holat
  → `test/cashback_balance_test.dart`
  → Sabab: `typeFromCashbackBalance` BuildContext + AppLocalizations talab
    qiladi, shuning uchun unit emas widget test. `SizeConfig().init(c)` shart —
    `mySnackBar` `SizeConfig.h/v` ni o'qiydi.

- [x] Test bug'ni haqiqatan tutishi isbotlandi
  → Tuzatish `git stash` bilan olib tashlanganda **4 ta test yiqildi**
    (to'liq balans, 50k+50k, 70k+61k, 3× bosish), qaytarilgach 12/12 o'tdi.

- [x] Regressiya yo'q: to'liq to'plam `flutter test` → **424/424 o'tdi**

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] Windows kassada tuzatishni tekshirish — yuqoridagi 4 qadamli jadval;
      3-qadamda 50 000 o'tishi, 4-qadamda **rad etilishi** va xabarda
      `(28,000)` ko'rinishi kerak
- [ ] Tasdiqlangach commit + relizga kiritish
- [ ] `## Ochiq savollar` dagi 2 ta punktni hal qilish (alohida tasklar)

## Qabul qilingan qarorlar

- **Tekshiruv qoldiq balans bo'yicha:** `freeBalance = balance - getSelectedPaymentSumma()`.
  `allPaymentType` yig'ib borgani uchun tekshiruv ham yig'indi bo'yicha borishi shart.
- **`>` → `>=`:** to'liq qoldiq balansni bir bosishda ishlatishga ruxsat.
  Sabab: qat'iy `>` kassirni bo'lib kiritishga majburlab, aynan bug'ni ochardi.
- **Summa kiritilmagan tarmoq (`parsed == 0`) tegilmadi.** U yerda yakuniy
  cashback aynan `available` bo'ladi va mavjud `available <= balance` tekshiruvi
  allaqachon to'g'ri ishlaydi. Uni "balansgacha qisman to'lash" ga o'zgartirish
  bug fix emas, UX o'zgarishi bo'lardi.
- **Xato xabariga qoldiq balans qo'shildi** — kassir qancha ishlatishi
  mumkinligini ko'rsin (l10n kaliti o'zgarmadi).
- **`allPaymentType` ga tegilmadi** — u umumiy (barcha to'lov turlari uchun),
  cashback qoidasi u yerga tegishli emas.
- **Ko'p-kassa / oflayn ssenariysi scope dan CHIQARILDI** (2026-08-13,
  foydalanuvchi qarori). Nazariy jihatdan balans mijoz tanlanganda snapshot
  olinadi va server uni chek yuklanganda yechadi (`api/v1/pay_by_loyalty`),
  ya'ni 2 kassa parallel sotsa bir balans ikki marta ketishi mumkin edi.
  **Amalda bunday bo'lmaydi:** bitta mijoz bir vaqtning o'zida ikkita kassadan
  o'tmaydi. Muhandislik ishi talab qilmaydi.

## Ochiq savollar

- **`_fromPointBalance` hech qachon 0 dan boshqa qiymat olmaydi**
  (`ordering_provider_4.dart:3179`, `3232` — faqat e'lon va reset), shuning
  uchun `receipt_builder.dart:129` ObjectBox'ga `cashback: 0` yozadi.
  **Tekshirildi — amaliy zarari yo'q:**
  - Backend'ga umuman ketmaydi: `ReceiptModel4.toJson()` da `"cashback"` kaliti
    yo'q (faqat `cashback_phone` va `zdachi_to_cashback`). Balans yechilishi
    alohida `api/v1/pay_by_loyalty` orqali boradi.
  - OFD'ga ketishidan oldin `receipt_singleton_4.dart:269` uni to'lov
    ro'yxatidan qayta hisoblaydi (`saleOnOFD` nusxa ustida ishlaydi), keyin
    `_countOtherOFD` orqali itemlarga `other` sifatida yoyiladi.
  - Vozvratda ham ahamiyatsiz: `saleOnOFD` ning `isRefund` tarmog'i hammasini
    CASH deb hisoblaydi, `cashbackValue` 0 bo'lib qoladi.
  - Hisobotlar/smena chekida ishlatilmaydi — ular to'lov turi nomi bo'yicha
    yig'adi, `receipt.cashback` ni o'qimaydi.

  Ya'ni maydon amalda **o'lik** (faqat ObjectBox ustuni + 2 ta debug ekran:
  `reciepts_screen.dart`, `receipts_screen_18.dart`). Tozalash kerakmi yoki
  to'g'ri to'ldirish kerakmi — alohida, shoshilinch bo'lmagan qaror.

## Test / Verifikatsiya

- `test/cashback_balance_test.dart` — widget test, real `typeFromCashbackBalance`
  ni chaqiradi (BuildContext + AppLocalizations kerak).
- Windows kassada qo'lda: yuqoridagi 4 qadamli jadval.
