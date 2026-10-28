# Task: Vozvratda markirovka — KM serverdan, qaytayotgan mahsulot skanerlanadi (dona + blok)

**Boshlangan:** 2026-10-27
**Holat:** in-progress (1.1.2+130 Shorebird Patch 3 stable'da; do'kon sinovi kutilmoqda)
**Branch:** fix/vozvrat-markirovka (asos: `ayyubxon` 7dc0de8), worktree `../pos-invan-2-vozvratkm`

## Maqsad
Vozvrat fiskal chekida `Label` (KM) bo'sh ketardi. Server `GET api/v1/order` javobida
`items[].marking_names` va `box_marking_names` ni qaytaradi (DEV, chek DT1 / #119,
2026-10-27), lekin ilova ularni o'qimasdi. Endi: chap ro'yxatda mahsulot bitta qator; kassir
qatorni bosib qaytayotgan shisha/blokni skanerlaydi; KM shu chekda sotilgan bo'lsa aynan o'sha
1 dona / 1 blok o'ngga o'tadi, bo'lmasa "Bu mahsulot shu chekda sotilmagan". Soliqqa vozvrat
sotuvdagidek: har KM alohida pozitsiya, `Label` = o'sha KM (blokda blok KM, `Amount 1000`).

## Kontekst (kod arxeologiyasi)
- Oqim: cheklar ro'yxati → "Vozvrat" → `ReUpdateBloc` (`SearchReceiptService.getReceiptss(orderId)`
  → `api/v1/order?search=<orderId>`) → `ChecksSingleton.globalToLocall` → `ReturnPage._copyWith`
  → `ReturnPageProviderr` (chap/o'ng ro'yxat) → `ReturnBloc` → `ReceiptSingleton4.saleOnOFD`
  (`label: e.mark ?? ''`) + ObjectBox + `refund_order_items` (`{id, price, quantity}`, KM yo'q).
- KM yo'qolgan joylar: `ItemsGTR.fromJson` maydonni o'qimasdi; `checks_singleton.dart` da
  `// mark:`, `// marking:` izohda; `return_page.dart` `mark: e.mark` (null).
- Sotuvda fiskal: har KM alohida pozitsiya (`Amount 1000`, `Label` = bitta KM). Blok qatori:
  `Amount 1000`, `Price` = blok narxi, `Label` = blok KM (emulyator `Sotuv_#119.json`,
  `docs/markirovka-box-sotish.md` §9).
- Server blok itemida `value` = TOKEN (`blok soni + ortiqcha dona`, `ReceiptModelSoldItem4.toJson`),
  `refund_amount` esa DONA (`funcToRefund`).
- Global skaner (`MyBarcodeListener`, uy sahifasi) faqat `BLStatus.home` da ishlaydi; cheklar
  sahifasi `BLStatus.other` qo'yadi — vozvrat dialogidagi skan savatga tushmaydi.

## Scope
- `lib/changes/models/receipts_get_model.dart` (`ItemsGTR`: KM + blok maydonlari, token → dona)
- `lib/features/get_products/singletons/checks_singleton.dart` (`globalToLocall`, `localOriginalItems`)
- `lib/features/checks/features/check_view/bloc/re_update_bloc.dart` (`refundableItems`)
- `lib/features/checks/return_page/return_page.dart` (`_copyWith`: havza qatorlari, qoldiq tuzatishi)
- YANGI `lib/changes/domain/receipt/refund_mark_split.dart` (`RefundMarkSplit`, `RefundMarkScan`)
- `lib/changes/providers/return_page_provider.dart` (`scanMark`, bekor qilish, skansiz ko'chirish yo'q)
- YANGI `lib/features/checks/return_page/return_page_dialog/refund_mark_scan_dialog.dart`
- `left/build_left_list.dart` (havza qatori → skan dialogi), `right/build_right_list.dart` (`KM: ...`)
- `receipt_singleton_4.dart` (`_fiscalAmount`: KM'li blok vozvrat qatori `Amount 1000`)
- l10n: `vozvrat_km_*` (uz/ru) + `flutter gen-l10n`
- `lib/changes/services/receipt_api_4.dart` (`funcToRefund`: `marking_names` / `box_marking_names`)
- Scope'dan tashqari: backend; boshqa kassada qaytarilgan KM'larni GET javobidan o'qish (backend
  qaytaradigan maydon hali kelishilmagan)

## Bajarilgan
- [x] `ItemsGTR` `marking_names`, `box_marking_names`, `sale_type`, `box_value`, `box_quantity`;
  blok itemida `value` token → dona (`value + boxQuantity × (boxValue − 1)`)
  → receipts_get_model.dart (`ItemsGTR.fromJson`, `isBox`); `toJson` ga blok maydonlari
    qo'shilmadi (qayta `fromJson` ikki marta o'girmasin)
- [x] `globalToLocall` → `mark` / `boxMark` (`'\n'` bilan), `marking`, blok maydonlari
- [x] Lokal original qidiruvi `ChecksSingleton.localOriginalItems` (return_page'dan ko'chdi);
  `ReUpdateBloc.refundableItems` lokal blok to'plamini ObjectBox'dan oladi
  → Sabab: ilgari `event.receiptModel4` dan — server qidiruvidagi chek endi saleType=2 bilan
    keladi, PIN yo'li (`ggg`) esa qatorsiz nusxa.
- [x] 1-urinish (bekor qilindi): chap ro'yxatni oldindan har KM alohida qatorga bo'lish.
  Foydalanuvchi: "alohida ko'rsatish xato" — KM skanerlab qaytariladi (pastdagi qaror).
- [x] `RefundMarkSplit.plan` — chap qatorlar: blok/dona, KM'li qism bitta qator + KM havzasi
  (`mark`, '\n'), KM'siz qismi alohida oddiy qator; oldin qaytarilgan KM'lar chiqariladi
- [x] `RefundMarkScan.candidates` + `check`
  (matched / empty / alreadyAdded / alreadyRefunded / boxMarkOnUnitRow / unitMarkOnBoxRow / notInReceipt)
- [x] Provider: `needsScan`, `scanMark(row, raw)` (1 dona / 1 blok o'ngga KM bilan),
  `pressRightProduct` KM qatorini havzaga qaytaradi, havza qatori skansiz ko'chmaydi;
  qator tugab ketsa ortgan KM'lar `_leftoverMarks` da (bekor qilinganda qayta tiklanadi)
- [x] `RefundMarkScanDialog` — ochiq qoladi, ketma-ket skan, sanagich, xato → alohida dialog,
  qator tugasa o'zi yopiladi
- [x] Eski bug tuzatildi: boshqa kassa cheki shu kassada qisman qaytarilganda qoldiq ikki marta
  ayirilardi → lokal original yo'q bo'lsa `server qoldig'i − serverga hali yetmagan lokal vozvratlar`
  (`uploaded == false`) → return_page.dart `remainingQty`, `_getAlreadyRefunded.pendingQty`
- [x] Fiskal: KM'li blok vozvrat qatori `Amount = boxQuantity × 1000` (`_fiscalAmount`)
- [x] l10n `vozvrat_km_*` (10 ta kalit, uz/ru), `flutter gen-l10n`
- [x] `test/refund_marking_test.dart` — 42 test (ItemsGTR, plan, scan, provider oqimi, fiskal JSON,
  ObjectBox: shu kassa + qoldiq tuzatishi); to'liq `flutter test` 2216 o'tdi / 4 skip;
  `flutter analyze` 590 = asos
- [x] Haqiqiy DT1 javobi → vozvrat fiskal JSON == `Sotuv_#119.json` (12 maydon, 2 pozitsiya;
  vaqtinchalik test, 1-urinish kodida; KM'li pozitsiya shakli o'zgarmagan)
- [x] Ilova worktree'dan DEV bilan ishga tushirilgan (`api_provider.dart` LOKAL DEV — commit qilinmasin)
- [x] Jonli sinov (Mac DEV, emulyator): vozvrat #123 (1 KM) va #124 (2 KM) sotuv #122 bilan 11 maydonda
  bir xil, oldin qaytarilgan KM qayta ketmadi, serverga `RefundUploadQueue: DT5/DT6 yuborildi`
- [x] Skan dialogi: sarlavha + mahsulot nomi + maydon (foydalanuvchi), quti 1.5×, matn standart, ko'k
  chegara; xato shu dialog ichida (ikkinchi dialog ustma-ust chiqmasin)
- [x] Bug: vozvrat sahifasida skan uy sahifasining global tinglovchisiga ham ketib sotuv savatiga
  tushardi ("Этот отмеченный продукт уже был добавлен ранее!") — `home_page.dart:226`
  VisibilityDetector cheklar sahifasiga o'tishda kechikib `BLStatus.home` qo'yadi. Vozvrat sahifasi
  va skan dialogi `BLStatus.other` qo'yadi → return_page.dart `build`, refund_mark_scan_dialog.dart `initState`
- [x] Bug (DT7): blok KM "shu chekda sotilmagan" — sotuvda blok KM `scanTime` siz saqlanadi (kripto qism
  qoladi: `...RYhH02993zdxZ`, skaner GS ni `029` qiladi), vozvratda `scanTime` "93" da kesardi →
  `RefundMarkScan.candidates`: dona shakli (`scanTime`→`forFiscal`) + blok shakli (`sanitize`→`forFiscal`);
  havzadagi saqlangan shakl o'ngga o'tadi (Label = sotuvdagi). Regressiya testi haqiqiy KM bilan; 44/44
- [x] Rus klaviatura tartibi (2026-10-28, foydalanuvchi: "kopincha rus klaviaturada bo'lishi mumkin"):
  YANGI `lib/changes/domain/barcode/keyboard_layout.dart` — `ruLettersToEn` (sotuvdagi
  `fixKeyboardLayout` jadvali, `MyBarcodeListenerState.fixKeyboardLayout` endi shuni chaqiradi, natija
  eski funksiya bilan belgima-belgi bir xil — test) va `ruToEnFull` (+ `Shift+7`→`&`, `/`→`.`→`/`,
  `Shift+/`→`?` va h.k., bitta o'tishda). `RefundMarkScan.candidates`: kod o'zi / harflari / to'liq
  o'girilgan × dona/blok tozalash. Windows ЙЦУКЕН; macOS "Russian" raqam qatori boshqacha. 49/49,
  to'liq 2223 o'tdi / 4 skip, analyze 590
- [x] Serverga vozvrat KM bilan (2026-10-28, backend `refund_order_items` ga maydon qo'shdi):
  `items[]` da `marking_names` (dona qatorlari) va `box_marking_names` (blok qatorlari), bir xil
  `refundItemId` li qatorlar KM'lari bitta itemga jamlanadi, KM yo'q — bo'sh massiv
  → receipt_api_4.dart `funcToRefund`, `ItemsI2`; oflayn navbat ham shu tanani ishlatadi
  (`receiptCreateGrouppForRefund`). Testlar: refund_marking 54, box_return/queue/return_bloc bilan 84
- [x] Serverdagi qaytarilgan KM'lar (2026-10-28, backend GET'ga qo'shdi; nomlar logdan tasdiqlandi:
  `refunded_marking_names`, `refunded_box_marking_names` — massiv, `marking_names` dan olib
  tashlanMAYDI): `ItemsGTR` o'qiydi → `ReUpdateBloc.serverRefundedMarks` (barcha item'lar, filtrdan
  oldin) → `ReUpdateSuccesState.refundedMarks` → `ReturnPage.serverRefundedMarks` → `_copyWith`:
  havzadan `server ∪ shu kassa` chiqariladi, skanerlansa "oldin qaytarilgan" (blok ham, rus tartibi ham)
  → re_update_bloc.dart, re_update_state.dart, check_view_content.dart, return_page.dart
  → Sabab: ObjectBox entity'ga maydon qo'shilmadi (sxema o'zgarmasin) — alohida parametr
- [x] Provider kaliti `refundItemId|productId|tur` — bekor qilingan KM o'z server item'iga qaytadi
- [x] Yangi xabar `otherProduct`: KM shu chekdagi boshqa mahsulotniki ("chekda yo'q" chalg'itardi)
- [x] Skan dialogi: blok qatorida nomdan keyin qalin "— Блок (12 шт)" (`vozvrat_km_blok_qator`)
- [x] Testlar: refunded ro'yxatlar (8), umumiy hayot sikli (sotuv 2 blok + 10 dona → A kassa →
  server holati vozvrat tanasidan → B → C → hammasi qaytgan), server + yuborilmagan lokal birlashmasi
  (ObjectBox); refund_marking 65/65, to'liq 2239 o'tdi / 4 skip, analyze 590
- [x] Sotuvda `order_pos` item'ida bo'sh `refunded_marking_names` / `refunded_box_marking_names` — server
  qabul qildi (201: #139, #140 markirovkasiz; #141 blok + dona KM)
- [x] Yakuniy E2E: sotuv #141 (1 blok + 2 dona) → vozvrat #142: 3 pozitsiya sotuv bilan 11 maydonda bir xil,
  `refund_order_items` 200 (quantity 14, KM 2 + 1). Vozvrat to'plamlari 108/108, to'liq 2240 / 4 skip, analyze 590
- [x] Commit `73ecadc` (fix/vozvrat-markirovka); port-changelog 19-task to'liq bo'lim
- [x] Merge `815d9d8` → `ayyubxon` (foydalanuvchi: "o'zing qil"), GitLab `ayyubxon` + GitHub `main` push;
  Shorebird **Patch 3** → `1.1.2+130` stable (run 40647516981, 2026-10-28; foydalanuvchi: staging'siz) —
  ogohlantirishsiz (native/asset o'zgarishi yo'q). +129 kassalarida yo'q

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Do'kon sinovi (Windows, haqiqiy fiskal modul): vozvrat soliq tomonidan qabul qilinishi, rus tartibida skan
- [ ] Backend: `refund_order_items` takroriy/begona KM'ni rad etsin (8-bo'lim, port-changelog)

## Qabul qilingan qarorlar
- KM skanerlab qaytariladi (foydalanuvchi, 2026-10-27): chapda mahsulot bitta qator, KM ro'yxati
  yashirin havza; skanerlangan KM havzada bo'lsa aynan o'sha birlik o'tadi.
- O'ng ro'yxatda har qaytgan dona/blok alohida qator (`KM: ...` bilan); bosilsa o'sha KM chapga qaytadi.
- Dialog ochiq qoladi, ketma-ket skan (10 ta shisha uchun 10 marta bosilmaydi).
- Chekda KM yo'q (eski chek / KM'siz sotilgan) — avvalgidek miqdor dialogi, KM'siz.
- Boshqa kassada qaytarilgan KM'ni bilib bo'lmaydi — havzada qoladi, miqdor server qoldig'idan oshmaydi
  (qaytarilgan shisha allaqachon do'konda, xaridorda bo'lmaydi).
- KM manbai: server `marking_names` / `box_marking_names`; bo'sh bo'lsa lokal originalning `mark` / `boxMark`.
- Skan tozalash sotuvdagi bilan aynan bir xil, ikkala yo'l nomzod (dona: `scanTime`→`forFiscal`,
  blok: `sanitize`→`forFiscal`) — o'ngga havzadagi saqlangan shakl o'tadi.
- KM'li blok vozvrat qatori fiskalga sotuvdagidek: `Amount = blok soni × 1000` (dona × 1000 emas).

## Ochiq savollar
- Klient yopa olmaydigan tirqichlar (backend validatsiyasi kerak): (1) ikki kassa bir chekni bir
  vaqtda qaytarsa — ikkalasi ham GET'ni boshqasi yuborishidan oldin olgan; (2) boshqa kassadagi oflayn
  (navbatdagi) vozvrat; (3) eski versiya / adminkadagi KM'siz vozvratlar — qaysi KM qaytgani noma'lum,
  faqat miqdor cheklanadi. Taklif: `refund_order_items` KM `marking_names`/`box_marking_names` da
  yo'q yoki `refunded_*` da bor bo'lsa rad etsin (409/400).
- Blok token formulasi koddan va eski izohdan chiqarildi — jonli blok cheki bilan hali tasdiqlanmagan.


## Test / Verifikatsiya
- `flutter test test/refund_marking_test.dart` — 65/65 (ObjectBox guruhi `libobjectbox.dylib` worktree
  ildizida bo'lganda; fayl commit qilinmaydi)
- To'liq `flutter test` — 2239 o'tdi, 4 skip; `flutter analyze` — 590 (asos bilan teng)
- Jonli DEV sinovi — kutilmoqda
