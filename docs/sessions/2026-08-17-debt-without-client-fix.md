# Task: Qarzdorsiz (mijozsiz) DEBT sotuvi bug'i

**Boshlangan:** 2026-08-17
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Kassada mijoz ham, supplier ham tanlanmagan holda qarzga (DEBT) sotuv o'tib ketgan
(prod misol: `#AH10862`, 16.08.2026, Tiin Optom / Kassa 5, 119 304 300 UZS, mijozsiz).
Sababi topilib, qaytalanmasligi ta'minlanishi kerak.

## ⚠️ Sabab — ikki HAR XIL muammo aralashib ketgan edi

### 1-muammo: qarzdor olib tashlansa DEBT qatori qoladi (TUZATILDI)
"Qarz" tugmasi **faqat UI da** qulflangan: u mijoz (`is_available_for_debt`) yoki
supplier tanlangan bo'lsagina ko'rinadi
(`lib/features/payment/right/keyboard_of_payment_page.dart:236-243`).
Lekin DEBT `paymentsMap` ga tushgandan KEYIN qarzdor olib tashlansa, qator
ro'yxatda qolib ketardi va sotuv yakunlanaverardi.

Qarzdor yo'qolishining yo'llari:
1. Didox/INN dialogida supplier DELETE — `setSelectedSupplierFromInnSearch(null)`
   (`client_search_with_inn_dialog.dart:367-372`)
2. Oddiy mijoz qidiruvida DELETE — `onClientSearchButtonPressed`ning
   `onDelClientPressed` i (`ordering_provider_4.dart:3486`)
3. Qidiruvda "mijoz topilmadi" → `initClientByBloc(null)`
   (`client_search_dialog_with_bloc.dart:103-109`, `client_search_with_inn_dialog.dart:202-207`)
4. Qarz ruxsati YO'Q mijozga almashtirish

Solishtirish uchun: INN oqimidagi **mijoz** DELETE si ishlayotgan edi, chunki u
`removeFromPaymentList()` ni chaqirardi (`ordering_provider_4.dart:4552-4557`).

### 2-muammo: supplierga qarzga sotuv = egasiz qarz (OCHIQ — asosiy sabab)
`#AH10862` aynan SHU yo'ldan kelgan, 1-muammodan EMAS. Do'kon supplierni
o'chirmagan; supplier sotuv paytida tanlangan turgan.

Dalil (foydalanuvchi kassasidagi haqiqiy `order_pos` body, `#DH243`,
`bodyForDiscountError` prefidan o'qildi):
```json
"external_id":"DH243", "client_id":"", "supplier_id":"31b260ff-1e5d-4cc1-865f-5e65945da75b"
```
Ya'ni supplier yo'lida `client_id` ATAYLAB bo'sh ketadi
(`receipt_builder.dart:61-68` dagi izoh: supplier nomi "faqat lokal", API'ga
yuborilmaydi). Natijada:
- bosilgan chekda "Xaridor: <supplier>" chiqadi (lokal `clientName`),
- panelda mijoz yo'q, qarz hech kimga biriktirilmaydi,
- chekni QIDIRUV orqali ochsa "Mijoz" bo'sh — chunki qidiruv serverdan oladi va
  `ChecksSingleton.globalToLocall` da `supplierId: ""` qattiq yozilgan,
  `clientName` esa faqat `r.client?.firstName` dan olinadi.

Bu 2026-07-28 dagi INN dual-search taskining tekshirilmay qolgan qadami:
"supplierId order body'siga tushayotganini tekshirish — bu qism o'zgartirilmadi".

## Scope
- `lib/changes/providers/ordering/payment_tally_controller.dart` — nuqtali DEBT o'chirish
- `lib/changes/providers/ordering_provider_4.dart` — qarzdor tekshiruvi + chaqiruv joylari
- `lib/features/payment/right/complete_button/pri_check.dart` — so'nggi to'siq
- `test/payment_tally_test.dart` — 5 ta yangi test
- Scope dan tashqari: OFD/fiskal oqimi, "ikkita Naqd pul tugmasi" masalasi (alohida, quyida)

## Bajarilgan
- [x] Sabab aniqlandi va reproduksiya qadamlari berildi; foydalanuvchi Case C ni (supplier DELETE) o'z kassasida takrorladi
- [x] `removeDebtPayment()` — faqat DEBT qatorini o'chiradi, naqd/kartaga tegmaydi
  → `lib/changes/providers/ordering/payment_tally_controller.dart:139`
  → Sabab: mavjud `removeFromPaymentList()` index tanlanmagan bo'lsa BARCHA to'lovni tozalab yuborardi
- [x] `isDebtSelectedWithoutDebtor` getter + `dropDebtPaymentIfNoDebtor()`
  → `lib/changes/providers/ordering_provider_4.dart:3331-3355`
  → Sabab: tekshiruv bitta joyda — "mijoz ham, supplier ham yo'q" sharti
- [x] Chaqiruv joylari: `setSelectedSupplierFromInnSearch`, `initClientByBloc`, `onDelClientPressed`
  → `ordering_provider_4.dart:2879-2890`, `:3496-3500`, `:3545-3552`
  → Sabab: uchala yo'l ham bitta provider metodiga tayanadi, UI o'zgarmaydi
- [x] So'nggi to'siq: qarzdorsiz DEBT bilan yakunlash tugmasi bosilsa sotuv boshlanmaydi, snackbar chiqadi
  → `lib/features/payment/right/complete_button/pri_check.dart:78-99`
  → Sabab: kelajakda topilmagan boshqa yo'l paydo bo'lsa ham pul yo'qolmasin
- [x] Testlar: 28/28 o'tdi (`test/payment_tally_test.dart`)
- [x] Audit (A): qarz sharti UI bilan tenglashtirildi — `_hasEligibleDebtor`
  → `lib/changes/providers/ordering_provider_4.dart:3334-3342`
  → Sabab: "mijoz bormi" yetarli emas edi; qarz ruxsati YO'Q mijozga almashtirilsa
    qator qolib ketardi. Supplier uchun qo'shimcha shart YO'Q — supplier tanlansa
    qarzga sotish mumkin (UI dagi shartning aynan o'zi).
- [x] Audit (B): cashback qatori mijoz o'zgarganda tozalanadi
  → `payment_tally_controller.dart:139-183` (`removeCashbackPayment`, umumiy `_removePaymentsWhere`)
  → `ordering_provider_4.dart` — `initClientByBloc` da mijoz IDsi o'zgargan bo'lsa
    (null yoki boshqa mijoz) cashback chiqadi; `onDelClientPressed` da ham
  → So'nggi to'siq ikkala yakunlash tugmasida: `pri_check.dart` va `complete_button.dart:266`
    (cashbackda COMPLETE tugmasi ishlatiladi, SimpleCheck emas — shuning uchun ikkalasi ham)
- [x] Testlar: 34/34 o'tdi (11 tasi yangi)
- [x] **Regressiya tuzatildi (do'kon shikoyati):** "qarzga sotish uchun mijoz tanlangan
      bo'lishi lozim" mijoz tanlangan holatda ham chiqib qolardi
  → `lib/changes/providers/ordering_provider_4.dart:3400` — `_hasEligibleDebtor` endi
    `selectedClient != null || selectedSupplier != null` (adminka
    `is_available_for_debt` bayrog'iga QARAMAYDI)
  → Sabab: git tarixi bo'yicha o'sha bayroq eskidan FAQAT "Qarz" tugmasini
    ko'rsatish/yashirish uchun ishlatilgan (`fef26ae^` dan ham oldin). Bugungi
    tuzatishda u sotuvni bloklashga ham qo'shilgani yangi xatti-harakat edi.
    `ClientModel` bir qancha joyda bu maydonsiz yaratiladi →
    `isAvailableForDebt == null`:
      - internetsiz 36-belgili ID qidiruvi — `client_search_bloc.dart:41-49`
      - invoice/nakladnoy mijozi — `ordering_provider_4.dart:671`
    Bunday mijozlar bilan ilgari ishlab turgan qarz sotuvi bloklanib qolgan edi.
  → Bug tuzatilgan holda qoladi: qarzdor BUTUNLAY yo'q (mijoz ham, supplier ham
    `null`) bo'lsa DEBT qatori olib tashlanadi va yakunlash bloklanadi.
  → Test: 2 ta test almashtirildi/qo'shildi (`payment_tally_test.dart:424-455`) →
    35/35 o'tdi

## Audit: shu sinfdagi boshqa holatlar (2026-08-17)
"UI da qulflangan, lekin qo'shilgandan keyin shart yo'qolsa qator qolib ketadi"
naqshini butun to'lov oqimi bo'ylab tekshirdim.

| # | Holat | Oqibat | Status |
|---|-------|--------|--------|
| A | Qarz qo'shilgach mijoz qarzga ruxsati YO'Q mijozga almashtiriladi | qarz noto'g'ri mijozga yoziladi | **tuzatildi** (`_hasEligibleDebtor`) |
| B | Bonus karta (cashback) qo'shilgach mijoz o'chiriladi/almashtiriladi | balansdan pul yechilmaydi, tovar ketadi | **tuzatildi** |
| C | Diskontli mijoz to'lov sahifasida DELETE qilinadi | narxlar tiklanadi, `_totalPrice` eski qoladi → items ≠ to'langan summa (OFD 10.2.1) | ochiq |
| D | "Mijoz topilmadi" — `initClientByBloc(null)` | mijoz diskonti savatda qoladi, chekda mijoz yo'q | ochiq |
| E | Naqdni yashiruvchi gate'lar (cashsale/bigTotal) C tufayli jami o'zgarsa | qolib ketgan naqd qatori | past ehtimol |

B tafsiloti: `receipt_api_4.dart:54-75` — `PUT api/v1/pay_by_loyalty/{clientId}`
bo'sh id bilan ketadi va xato qaytaradi, lekin `jsonList.remove(cashback)` (73-qator)
hech qachon ishlamaydi (`jsonList` — `List<Map>`, `cashback` — `ReceiptModel4`),
shuning uchun chek baribir yuklanadi.

Tekshirildi, muammo emas: `switchIsChangeToCashback` (UI da kommentga olingan),
company-name preflari (chop etishdan keyin tozalanadi), Click/Payme/Uzum/Paynet
(mijozga bog'liq emas).

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] **2-muammo (asosiy):** backend'dan javob — `order_pos` dagi `supplier_id`
      saqlanadimi va `client_id` bo'sh + DEBT bo'lgan sotuvda qarz kimga yoziladi?
      (`#DH232` / `#DH243` misolida so'ralsin)
      - Backend supplier qarzini yuritsa → panelda ko'rsatsin + POS'da
        `ChecksSingleton.globalToLocall` supplier'ni o'qiydigan qilinsin
      - Yuritmasa → POS supplierga qarzga sotishni bloklashi kerak
- [ ] Windows'da real test (1-muammo): Didox → supplier → Qarz → supplier DELETE →
      DEBT qatori yo'qolishi va yakunlash tugmasi o'chishi kerak
- [ ] Windows'da real test: mijoz DELETE, "mijoz topilmadi", mijozni almashtirish
- [ ] Windows'da real test (B): Bonus karta → mijoz DELETE / almashtirish
- [ ] Test o'tsa — commit + release
- [ ] C va D (diskont/summa nomuvofiqligi) — keyinroq, alohida

## Qabul qilingan qarorlar
- **Adminka `is_available_for_debt` bayrog'i sotuvni bloklamaydi** — u faqat "Qarz"
  tugmasi ko'rinishini boshqaradi (eskidan shunday). Sabab: bayroq bir qancha
  oqimda `null` bo'lib keladi (oflayn qidiruv, invoice mijozi) va ishlab turgan
  sotuvlarni to'xtatib qo'yadi. Bloklash sharti faqat "qarz egasi bormi".
- DEBT ni nuqtali o'chirish (butun `paymentsMap` ni tozalash emas) — kassir kiritgan
  qisman naqd/karta to'lovi yo'qolmasligi uchun
- Tuzatish UI da emas, providerda — uchala yo'l bitta joydan o'tadi
- So'nggi to'siq `pressPaymentButton` da emas, tugma bosilishida — bloklash sotuv
  oqimi boshlangandan keyin bo'lsa savat yo'qolib, chek yozilmay qolardi

## Ochiq savollar
- `#AH10862` (119 mln, qarz, mijozsiz) chekini backendda kimga biriktirish kerak —
  buni do'kon/buxgalteriya hal qiladi (kod tomondan tuzatib bo'lmaydi)

## Test / Verifikatsiya
- `flutter test test/payment_tally_test.dart` → 28/28 (5 tasi yangi)
- `flutter test` (to'liq) → 433 test o'tdi, 1 xato: `cashback_balance_test.dart` ning
  `tearDownAll` i 12 daqiqadan keyin timeout. **Bu bug bilan bog'liq emas** — o'zgarishlar
  `git stash` bilan olib tashlanib qayta tekshirildi: o'sha faylning 16 ta testi 4 soniyada
  o'tadi, keyin `tearDownAll` (Hive.close / temp dir delete) baribir osilib qoladi.
  Ya'ni oldindan mavjud muammo, alohida ko'rib chiqilishi kerak.
- `flutter analyze` — yangi ogohlantirish yo'q
- Windows sinovi kutilmoqda

## Yon topilma (alohida task uchun)
Do'kon panelida **ikkita "naqd" to'lov turi** bor: built-in `CASH` va admin panelda
yaratilgan `Naqd Pul` (+ `Shahzod`). Custom turlar:
- OFD chekiga **CARD** sifatida ketadi (`receipt_singleton_4.dart:262-265` — `else` shoxi),
- naqd hisobiga (smena) kirmaydi (`cashId` bo'yicha ajratiladi),
- `isAdded/enable` bayrog'i tekshirilmagani uchun admin panelda o'chirilsa ham
  POS da ko'rinaveradi (`keyboard_of_payment_page.dart:376-379`).
Bu alohida hal qilinadi.
