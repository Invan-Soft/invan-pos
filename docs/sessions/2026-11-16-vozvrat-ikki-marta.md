# Task: Bitta chek ikki marta vozvrat qilinishi ("refund amount is greater than expected amount")

**Boshlangan:** 2026-11-16
**Holat:** in-progress
**Branch:** fix/vozvrat-ikki-marta (ayyubxon dan)

## Maqsad
Do'konda (Tiin Optom, Kassa 1a, 2026-11-14, 1.1.2+130) server vozvratni `refund amount is greater than expected
amount` bilan rad etgan: chekdagi hamma tovar allaqachon qaytarilgan, kassa esa yana vozvrat yuborgan. Qaysi holatda
shunday bo'lishini topish va yopish.

## Scope
- `lib/features/checks/features/check_view/` ("Qaytarish" tugmasi, `ReUpdateBloc`)
- `lib/features/checks/return_page/` (`ReturnBloc`, oyna, sahifa)
- `lib/changes/domain/receipt/refund_preflight.dart` (yangi)
- Scope'dan tashqari: vozvrat MIQDORI/SUMMASI hisobidagi boshqa tirqichlar (kg da double arifmetika, bir xil
  `productId` ikki qatorda, chek darajasidagi chegirma + oldin to'liq qaytarilgan qator) — tahlil qilingan,
  tuzatilmagan (quyida "Ochiq savollar").

## Sabab (kassada qayta chiqarilgan, Mac DEV, 1.1.2+129)
1. Sotuv DT35 (2 tovar).
2. Cheklar → DT35 → "Qaytarish" ikki marta bosildi (150 ms). `ReUpdateBloc` ikkala hodisani parallel ishladi,
   ikkalasi `ReUpdateSuccesState` berdi → ikkita `ReturnPage` ustma-ust (logda ikkita `NAV_PUSH`).
3. Ustkisida vozvrat → DT36 serverga ketdi.
4. "Ok" → tagidan ikkinchi `ReturnPage`: ro'yxat sahifa ochilganda bir marta hisoblangan, tovarlar hali ham chapda.
5. Yana vozvrat → DT37: fiskal chek chiqdi, server 400 `refund amount is greater than expected amount ...
   sold=1, already_refunded=1, requested=1`. Kassa "muvaffaqiyatli" ko'rsatdi (+129; +130 da ogohlantirish bor).

Ikki sahifa ochilishining boshqa yo'li (kod bo'yicha, kassada sinalmagan): bosh sahifadan Cheklar ochilganda
`currentPageId` "home" bo'lib qoladi — Cheklar ichidagi yon menyudan yana "Cheklar" bosilsa ikkinchi Cheklar sahifasi
ustiga ochiladi; ikkalasi bitta global `ReUpdateBloc` ni eshitadi → bitta bosish ikkita vozvrat sahifasi.

## Bajarilgan
- [x] `ReUpdateBloc`: so'rov ketayotganda ikkinchi hodisa qabul qilinmaydi; Success'dan keyin Failure chiqarilmaydi
  → lib/features/checks/features/check_view/bloc/re_update_bloc.dart
  → Sabab: ikki bosish = ikki sahifa
- [x] Vozvrat sahifasini faqat ustki (`isCurrent`) Cheklar sahifasi ochadi
  → lib/features/checks/features/check_view/check_view_content.dart
  → Sabab: `ReUpdateBloc` global, ustma-ust Cheklar sahifalari hammasi eshitadi
- [x] `ReturnBloc`: bir vaqtda bitta vozvrat (`_running`); fiskaldan oldin `_preflight`
  → lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart
  → Sabab: eskirgan sahifa qaysi yo'l bilan paydo bo'lmasin, fiskal chek chiqmasligi kerak
- [x] `RefundPreflight` (sof hisob): sahifa eskirganmi (`pageOpenedAt` dan keyingi lokal vozvrat), server qoldig'idan
  oshganmi (minus serverga yetmagan lokal vozvratlar)
  → lib/changes/domain/receipt/refund_preflight.dart
- [x] `ReturnBlockedState` + oynada xabar (faqat "Ok", "Qayta urinish" yo'q)
  → return_state.dart, return_dialog.dart
- [x] "Bekor qilish" (internet tekshiruvi paytida) vozvratni ham to'xtatadi (`cancelBeforeStart`)
  → return_bloc.dart, return_dialog.dart
  → Sabab: ilgari oyna yopilar, vozvrat orqa fonda davom etardi
- [x] Testlar: test/refund_double_guard_test.dart (10 ta)

## Keyingi qadamlar (prioritet bo'yicha)
- [x] Shorebird Patch 4 → 1.1.2+130 stable (2026-11-16, run 43816945688) — `patch/130-vozvrat-ikki-marta`
  (Patch 3 `815d9d8` + faqat shu fix; Kaftpay/OPD kirmagan)
- [x] `fix/vozvrat-ikki-marta` → `ayyubxon` merge (2026-11-16)
- [ ] Do'konda tekshirish: Patch 4 olgan kassada "Qaytarish" ikki marta → bitta sahifa
- [ ] Windows'da sinov (fiskal modul bilan): ikki bosish, vozvrat, "Bekor qilish"
- [ ] Do'kondagi AC93667 ni tasdiqlash: adminkada shu sotuvning muvaffaqiyatli vozvrati AC93667 dan oldingi
  raqam va bir-ikki daqiqa oldin bo'lishi kerak
- [ ] Odoo forkiga port (`serverRemaining` Odoo API'siga moslanadi)

## Qabul qilingan qarorlar
- Tekshiruv fiskaldan OLDIN — rad etilganda hech narsa (fiskal, lokal, server) o'zgarmaydi.
- Server javob bermasa server tekshiruvi o'tkazib yuboriladi — oflayn vozvrat (`RefundUploadQueue`) ishlashda davom
  etadi; lokal "sahifa eskirgan" tekshiruvi baribir ishlaydi.
- Sahifa eskirgani `pageOpenedAt` bilan aniqlanadi (qoldiqni qayta hisoblash emas) — sodda va qat'iy: sahifa ochiq
  turganda shu chek bo'yicha lokal vozvrat saqlangan bo'lsa, chek qayta ochiladi.

## Ochiq savollar
- Vozvrat miqdori/summasidagi boshqa tirqichlar (tahlil 2026-11-14/16, tuzatilmagan): kg da `v -= arrivedValue`
  yaxlitlanmagan double; bir xil `productId` ikki qatorda birinchi `refundItemId` ostida qo'shiladi; chek darajasidagi
  chegirmada oldin to'liq qaytarilgan qatorlar nisbatni buzadi; rad etilgan vozvrat qo'lda qayta yuborilganda 1-qadam
  409 bersa 2-qadamsiz "yuborilgan" bo'ladi. Endi server tekshiruvi (`firstOverdrawn`) miqdor oshishini fiskaldan
  oldin ushlaydi, lekin ildizlari ochiq — foydalanuvchi qarori.
- Rad etilgan vozvrat (masalan DT37) "Yangilash" bosilganda har safar qayta yuboriladi va yana 400 + Telegram log
  beradi — rad etilganlar uchun alohida tartib kerakmi.

## Test / Verifikatsiya
- `flutter test test/refund_double_guard_test.dart test/return_bloc_flow_test.dart` + refund/return/check testlari:
  123 o'tdi, 6 skip; `flutter analyze` — xato yo'q.
- Mac DEV kassasi (tuzatilgan build): sotuv DT38 → "Qaytarish" ikki marta (150 ms) → bitta `NAV_PUSH`, bitta sahifa
  → vozvrat DT39 serverga ketdi → "Ok" → to'g'ri Cheklar sahifasiga qaytdi.
- Kassada sinalmagan: `ReturnBlockedState` oynasi, server qoldig'i tekshiruvi (boshqa kassa), "Bekor qilish",
  ustma-ust Cheklar sahifalari — testlar bilan qoplangan.
