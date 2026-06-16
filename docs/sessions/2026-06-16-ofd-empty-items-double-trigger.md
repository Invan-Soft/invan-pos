# Task: OFD bo'sh items xatosi — "Передан недействительный параметр в JSON"

**Boshlangan:** 2026-06-16
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Maydonda OFD sotuvда chek `items:[]` (bo'sh) bilan, lekin `receivedCash:1 229 000` bilan
yuborilib, fiskal modul `Передан недействительный параметр в JSON` xatosini qaytargan.
Log: version 1.1.2+104, 2026-06-15 23:43, Kassa 1a, Tiin Optom. Bu xatoni butunlay to'xtatish.

## Sabab (tahlil)
- `items` ← `_sixClientModel4.orderedProducts`; `receivedCash` ← `paymentsMap` (alohida manba).
  → receipt_singleton_4.dart:315 (items), :234-240 (receivedCash).
- 104 versiya 25-may'da bumplangan (5567d13) — kechagi red-delete OFD fix (461fbb4, 15-iyun)
  bu build'da YO'Q. Demak red-delete `where(isDeleted)` filtri sababchi EMAS.
- Empty+cash hosil bo'lishi: birinchi muvaffaqiyatli sotuv `_paymentOnClients()` orqali
  `orderedProducts`ni tozalaydi (:2603/2606), lekin ESKI kodda `paymentsMap` faqat sahifaga
  qayta kirishda (`initPaymentPageValues`:3197) tozalanardi → qolib ketadi. Ikkinchi
  `pressPaymentButtonOnlyOFD` chaqiruvi bo'sh items + qolgan naqd bilan sell() qiladi.
- Ikkilamchi chaqiruv manbai: ikkita trigger bor — tugma (complete_button.dart:270) VA
  klaviatura SPACE (keyboard_of_payment_page.dart:622-627). Ikkalasi `getPaymentInProgress`
  guard'ini PRESS paytida o'qiydi, lekin `setPaymentInProgress(true)` listener'da ASINXRON
  o'rnatiladi (complete_button.dart:182) → tor race oynasi double-fire'ga yo'l ochadi.
  `_paymentInProgress` muvaffaqiyatdan keyin false QILINMAYDI (faqat 3219 sahifa kirishida).
- ESLATMA: sof concurrent double-fire ko'proq DUBL chek beradi; empty+cash aniq stsenariysi
  birinchi success-clear + paymentsMap omon qolishini talab qiladi. Aniq trigger ketma-ketligi
  runtime timing'ga bog'liq (skaner suffiks tugmasi / tez ikki bosish / sdacha dialog interplay) —
  statik tahlil bilan 100% pinlab bo'lmadi. Shu sabab guard'ga diagnostik log qo'shildi.

## Bajarilgan
- [x] Defensive guard: OFD'ga yuborishdan oldin `soldItemList.isEmpty` bo'lsa to'xtatish
  → lib/changes/providers/ordering_provider_4.dart (pressPaymentButtonOnlyOFD, sell()dan oldin)
  → `PaymentResult(success:false, skipped:true)` + `LogHelper.write(warn, ...)` diagnostik log
  → Sabab: bo'sh chek hech qachon fiskal modulga yetmaydi; sababdan qat'iy nazar xato yo'qoladi.
- [x] Muvaffaqiyatli OFD sotuvdan keyin `paymentsMap = {}` DARHOL tozalash
  → ordering_provider_4.dart (pressPaymentButtonOnlyOFD success bloki, _paymentOnClients yonida)
  → Sabab: qolgan naqd/karta qiymati keyingi chaqiruvga sizib o'tmasligi uchun.
- [x] PaymentResult'ga `bool skipped` maydoni (default false)
  → lib/changes/models/ofd/payment_result_model.dart
- [x] complete_button: `result.skipped` bo'lsa qizil xatosiz, CmtBInitialEvent + setPaymentInProgress(false)
  → lib/features/payment/right/complete_button/complete_button.dart:209-216
- [x] flutter analyze: yangi error yo'q (faqat avvaldan mavjud info/warning).

## Reproduksiya (2026-06-16, boshqa Windows PC'da tasdiqlandi)
- Vaqtinchalik test kodi bilan double-trigger qo'lda chiqarildi: SPACE'dagi `!getPaymentInProgress`
  guard'ni ochib + 2-OFD chaqiruviga 3s delay + paymentsMap clear'ni izohlab. "Yakunlash"+SPACE
  bosilganda 1-chek muvaffaqiyatli, 2-chaqiruv `items:[] + naqd` yuborib AYNAN
  "Передан недействительный параметр в JSON" xatosini berdi. ROOT CAUSE TASDIQLANDI: double-trigger.
- Test kodi to'liq qaytarib olindi (35942c4 dan keyin), faqat toza prod fix qoldi.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Prod build'da yakuniy tekshiruv: oddiy OFD sotuv ishlashi; "Yakunlash"+SPACE → dubl chek YO'Q,
  bo'sh-items xatosi YO'Q, kassir qizil xato ko'rmasligi (guard log yozadi, jim o'tadi).
- [ ] (Ixtiyoriy) chuqurroq root-cause: guard'ni press paytida sinxron o'rnatish
  (onPressed/SPACE ichida darhol setPaymentInProgress(true)) yoki bloc droppable transformer.
  Hozirgi fix (bo'sh-items bloklash + paymentsMap darhol tozalash) buni baribir yopadi.

## Qabul qilingan qarorlar
- Defense-in-depth: aniq trigger pinlanmasa ham, bo'sh-items guard + paymentsMap darhol tozalash
  xatoni butunlay yopadi. Root-cause (race) keyin diagnostika asosida aniqlanadi.
- `skipped` flag bilan kassirga soxta "to'lov amalga oshmadi" ko'rsatilmaydi.

## Ochiq savollar
- Aniq trigger: SPACE tugmasi / barcode skaner suffiks / sdacha dialog ortidagi qayta bosishmi?
  → Diagnostik log maydonda javob beradi.

## Test / Verifikatsiya
- flutter analyze: edited 3 fayl — yangi error yo'q.
- Qo'lda Windows test kutilmoqda.
