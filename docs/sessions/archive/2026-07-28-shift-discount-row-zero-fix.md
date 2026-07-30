# Task: Smena yopishda "Chegirmalar" (Скидки) qatori 0 chiqishi — fix

**Boshlangan:** 2026-07-28
**Holat:** done
**Yakunlangan:** 2026-07-29
**Branch:** ayyubxon

## Maqsad
Smena yopilganda / Z-otchётda "Chegirmalar" (Скидки) qatori chegirma berilgan
bo'lsa ham 0 ko'rsatardi. Shunga bog'liq "Savdolar" (Продажи) qatori ham kam
chiqardi. Sabab: chegirma summasi noto'g'ri manbadan hisoblanardi. Fix qilindi.

## Muammoning aniq tavsifi (foydalanuvchi so'zi bilan)
Do'konda: 1 mln lik savdo bo'lgan, har mahsulotga OPD (operation-on-product)
dialogidagi pastki **"Chegirma %"** maydoni orqali 50% chegirma berilgan, jami
~600 ming so'm bo'lgan. Smena yopishda "Chegirmalar" qatorida chegirma summasi
o'rniga **0** turgan. Ilgari bu qator to'g'ri ishlagan (nechchi pul chegirma
urilgan bo'lsa, o'shani ko'rsatardi).

## Ildiz sabab (root cause)
Fayl: `lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart`
Metod: `getCurrentHiveShift()` (~85280-qatordan boshlanadi). Bu metod Z/X-otchёt
va smena yopishda barcha summalarni ObjectBox cheklaridan **qaytadan** hisoblaydi
(per-sale hive yozuvi 2026-06-06 da olib tashlangan — qarang
`docs/sessions/2026-06-06-shift-hive-corruption-fix.md`).

Eski kod chegirmani FAQAT `item.discount` (DiscountModel ToMany) ro'yxatidan
yig'ardi:
```dart
for (var d in item.discount) {
  discountAmount += (d.total * item.value);
}
```

Muammo: `item.discount` ro'yxati **hamma chegirma turida to'lmaydi**:
- OPD "Chegirma %" (`onDiscountChanged`) va "Chegirmali narxi" (`onPriceChanged`)
  `item.discount`'ni **clear()** qiladi, faqat `singleDiscount` + `price`'ni
  o'zgartiradi → ro'yxat bo'sh → chegirma 0 chiqardi.
- Utsenka QR (`_parseUtsenkaQr`) faqat `singleDiscount` o'rnatadi, `item.discount`
  ga tegmaydi → 0.
- Admin/kategoriya % yoki summa chegirmasi bitta qatorda **1 dan ortiq miqdorda**
  qo'shilganda: `discount_helpers.dart` da `singleDiscount` faqat `value == 1` da
  oshiriladi (masalan `_productPercentage`, `_categoryPercentage`,
  `_productNumeric`, `_categoryNumeric` — hammasida `if (product.value == 1)`
  sharti bor). Shunda `addDiscountForProduct` `item.discount` ga `total: 0`
  yozuv qo'shadi → ro'yxat bo'sh emas, lekin summasi 0 → chegirma 0.

## Yechim (fix) — YAKUNIY
Fayl: `shift_singleton_4.dart`, `getCurrentHiveShift()` ichidagi
`for (var item in e.soldItemList)` sikli (~85391-85413). **Sof narx-farqi:**

```dart
final double perUnitDiscount = item.realPrice - item.price;
if (perUnitDiscount > 0) {
  discountAmount += perUnitDiscount * item.value;
}
```

Ya'ni chegirma = `(asl narx − sotilgan narx) × miqdor`. Bu fiskal OFD chekida
ishlatiladigan `_countDiscountOFD` formulasi bilan AYNAN bir xil → smena
hisoboti chek/adminka bilan mos.

**Muhim:** `discountAmount` faqat ikki joyga yoziladi — `salesSummary.discounts`
(Chegirmalar) va `grossSales` (Savdolar). Naqd pulga (`cashPayment`,
`expCashAmount`) UMUMAN tegmaydi.

### ⚠️ Nega item.discount daftaridan EMAS (blok bug'i — 2026-07-29 topildi)
Dastlab "ledger-first" (avval `item.discount` daftari, aks holda realPrice−price)
qilingan edi. **U BLOKNI BUZARDI.** Sabab: `consolidateSoldItems`
(receipt_singleton_4.dart:188-199) sotuvda blok qatorini dona hisobiga yoyadi —
`item.value` ni `boxValue` marta oshiradi (1 blok → 12 dona), LEKIN
`item.discount[].total` ni yoymaydi (u butun-blok qiymati bo'lib qoladi).
Natijada `d.total × value` blok chegirmasini `boxValue` marta ko'p ko'rsatardi.

Real misol (ekran, 2026-07-29): Montella Daily blok, buyXgetY 1+1, 2 blok sotildi,
boxValue=12. Kutilgan naqd to'g'ri (36,000), lekin:
- Konsolidatsiyadan keyin: value=24, item.discount[].total=36,000 (yoyilmagan)
- Ledger: `36,000 × 24 = 864,000` ❌ (ekranda Chegirmalar=864,000, Savdolar=900,000)
- Sof narx-farqi: `(3,000−1,500) × 24 = 36,000` ✅ (Savdolar=72,000)

`realPrice` va `price` konsolidatsiyada dona hisobiga TO'G'RI bo'linadi
(realPrice=realPriceTotal/value, price=priceTotal/value), shuning uchun
`realPrice − price` har doim to'g'ri — blok uchun ham, oddiy mahsulot uchun ham.

## Chegirma holatlari jadvali (Chegirmalar qatoriga qanday tushadi)

| # | Chegirma turi | Qanday saqlanadi | Otchётda qaysi yo'l | Natija |
|---|---|---|---|---|
Yakuniy yechimda HAMMA holat bir xil formuladan sanaladi: `(realPrice−price)×value`.

| # | Chegirma turi | price/realPrice holati | Natija |
|---|---|---|---|
| 1 | OPD "Chegirma %" | realPrice=asl, price=chegirmali | ✅ |
| 2 | OPD "Chegirmali narxi" | realPrice=asl, price=chegirmali | ✅ |
| 3 | OPD "Asl narxi" (qo'lda narx) | realPrice=price | ✅ sanalmaydi (chegirma emas) |
| 4 | Mijozga umumiy % | realPrice=asl, price kamayadi | ✅ |
| 5 | "Tepada" chegirma (foiz/summa) | realPrice=asl, price kamayadi | ✅ |
| 6 | Admin %/summa (1 yoki 2+ dona) | realPrice=asl, price kamayadi | ✅ |
| 7 | BuyXGetX/Y, Free Gift | realPrice=asl, price kamayadi | ✅ |
| 8 | Utsenka QR (markdown) | realPrice=asl, price=chegirmali | ✅ |
| 9 | **Blok + promo (BuyXGetX/Y)** | konsolidatsiyada dona hisobiga to'g'ri bo'linadi | ✅ (blok bug'i tuzatildi) |
| 10 | Blok/tier narx (optom, promosiz) | price=realPrice | ✅ sanalmaydi (optom) |
| 11 | Chegirmasiz oddiy sotuv | price=realPrice | ✅ sanalmaydi |

3, 10 — chegirma EMAS (narx qo'lda tuzatilgan / optom narx), realPrice=price
bo'lgani uchun 0 bo'lishi TO'G'RI (foydalanuvchi alohida talab qildi: "dokonda
narx o'zgargan, rastada eski narx bo'lsa kassir eski narxda beradi — buni discount
deb ko'rish xato").

## Naqd pul tekshiruvi (ALOHIDA masala — chegirmaga aloqasi yo'q)
Foydalanuvchi: "kassada naqd otchётdan KO'P chiqqan, otchёt KAM ko'rsatgan" degan
maydon shikoyatini aytdi. To'liq tekshirildi:

- **Test A** (chegirma + tappa-teng naqd) → foydalanuvchi sinab ko'rdi:
  MUAMMO YO'Q, naqd to'g'ri.
- **Kodda naqd = mijoz bergan − qaytim** (`paymentsMapAsList`,
  ordering_provider_4.dart ~3444, ~3448) → yozilgan naqd hech qachon jismoniy
  naqddan ko'p bo'lolmaydi. Chegirma naqdga tegmaydi.
- **"Qaytimni keshbekka" (zdachaToCashBack)** → tugma kodda O'CHIRILGAN
  (`left.dart:286` da `switchIsChangeToCashback()` izohga olingan, v106 da ham).
  Ishlamaydi → bu yo'l sabab bo'lolmaydi.
- **Vozvrat** → har doim CASH sifatida yoziladi
  (`return_bloc.dart:79`, "to'lov turidan qat'iy nazar hammasi CASH orqali") va
  jismonan ham naqd chiqadi → mos keladi, mismatch yo'q.

**Xulosa:** chegirmali sotuv → naqd hisobida kodda BUG YO'Q. "Kassada naqd ko'p"
bo'lsa, eng ehtimoliy sabab — **to'lov turi noto'g'ri bosilgani** (mijoz naqd
bergan, kassir Click QR / Payme QR / karta tugmasini bosgan). Shunda naqd kassaga
tushadi, lekin otchёt uni online/karta deb yozadi → "Наличные" kam ko'rinadi.
Bu operatsion xato, chegirma bug'i emas. Diagnostika: muammoli smenaning
Click/Payme/karta cheklarini kassir bilan tekshirish.

## Bajarilgan
- [x] Root cause aniqlandi
  → shift_singleton_4.dart:85391 (getCurrentHiveShift, soldItem sikli)
  → Sabab: item.discount ro'yxati OPD %/manual/utsenka/admin-2+dona da bo'sh/0
- [x] 1-urinish: ikki bosqichli (ledger → realPrice−price zaxira) — BLOKNI BUZDI
- [x] 2026-07-29: blok bug'i aniqlandi (real ekran: Chegirmalar 864,000, aslida
  36,000) — konsolidatsiya value'ni yoyadi, d.total ni yoymaydi → ledger boxValue
  marta ko'p. Ledger butunlay olib tashlandi.
- [x] YAKUNIY fix: sof `(realPrice − price) × value`
  → shift_singleton_4.dart:85391-85413
  → Sabab: fiskal OFD formulasi bilan bir xil, blok konsolidatsiyasidan keyin ham
    to'g'ri (realPrice/price dona hisobiga bo'linadi), narx-tuzatish/optomni
    chegirma deb sanamaydi
- [x] `dart analyze` toza (faqat oldindan bor 1 ta aloqasiz `info` — empty_statement:84987)
- [x] Naqd pul masalasi to'liq tekshirildi → chegirmaga aloqasi yo'q, kodda bug yo'q
- [x] 11 ta chegirma holati jadval qilib tasdiqlandi (blok promo qo'shildi)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] **Windows'da real test** (asosiy qadam):
  1. OPD "Chegirma %" bilan 50% chegirma → smena yop → "Chegirmalar" to'g'ri
  2. Bitta mahsulotni 3-5 dona bir yo'la + admin chegirmasi → "Chegirmalar" to'g'ri
  3. **Blok + BuyXGetX/Y (1+1) promo** → "Chegirmalar" REAL summa (boxValue marta
     ko'p EMAS), "Savdolar" real (masalan 2 blok = 72,000, 900,000 emas)
  4. Tepadagi "Asl narxi"ni qo'lda tuzatish → "Chegirmalar" ga TUSHMASLIGI
  5. Blok/optom sotuv (promosiz) → "Chegirmalar" ga TUSHMASLIGI
  → Fayl: shift_singleton_4.dart:85391
- [ ] Test tasdiqlansa → commit + release (yangi versiya)
- [ ] (Ixtiyoriy, alohida) Agar "kassada naqd ko'p" shikoyati davom etsa: aniq bir
  smenaning to'lov turlarini tekshirish — Click/Payme deb yozilgan chek aslida
  naqd bo'lganmi. Bu chegirma task'idan alohida.

## Qabul qilingan qarorlar
- **Sof `(realPrice − price) × value` tanlandi** (item.discount daftariga
  tayanmaydi) — chunki (a) daftar ba'zi chegirma turlarida bo'sh/0; (b) blokda
  konsolidatsiya value'ni yoyadi-yu d.total ni yoymaydi, shu sababli ledger
  boxValue marta ko'p ko'rsatadi. Narx farqi esa fiskal OFD formulasi bilan
  bir xil va konsolidatsiyadan keyin ham to'g'ri — universal va ishonchli.
- **Narx qo'lda tuzatish (OPD "Asl narxi") va blok/optom narx chegirma
  sifatida SANALMAYDI** — chunki bu holatlarda `realPrice = price` qilinadi
  (farq 0). Foydalanuvchi buni aniq talab qildi.
- **Naqd pul masalasi bu task'ning fix'iga kiritilmadi** — chunki tekshiruvda
  chegirma naqdga umuman ta'sir qilmasligi aniqlandi; naqd shikoyati boshqa
  (operatsion) sababdan.

## Ochiq savollar
- "Kassada naqd otchётdan ko'p" shikoyati haqiqiy operatsion xatomi (to'lov turi
  noto'g'ri bosilgan) yoki shunchaki Продажи↔naqd chalkashligimi? — do'kondan
  aniq smena raqamlari kelsa hal bo'ladi. (Bu task uchun bloklovchi EMAS.)

## Test / Verifikatsiya
- `dart analyze` → toza (aloqasiz 1 info).
- **Windows'da real test → MUAMMOSIZ ISHLADI** (foydalanuvchi 2026-07-29 tasdiqladi):
  blok + BuyXGetY 1+1 promo, OPD %, oddiy chegirma va promosiz blok — hammasi
  "Chegirmalar" va "Savdolar" qatorlarida to'g'ri chiqdi.
- O'zgargan fayl: `shift_singleton_4.dart` (bitta metod, `getCurrentHiveShift`).
- ⚠️ Commit + release BU SESSIYADA qilinmadi — o'zgarish hali commit qilinmagan.
  Keyingi qadam: pubspec bump + dual push + tag + build (release skill).
