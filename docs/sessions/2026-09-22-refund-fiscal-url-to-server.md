# Task: Vozvrat cheki serverga sotuv emas, vozvratning o'z fiskal URL'i bilan ketishi

**Boshlangan:** 2026-09-22
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Onlayn vozvratda server (`refund_for_pos_new`) fiskal moduldan OLDIN chaqirilardi,
shuning uchun serverdagi vozvrat yozuvida asl sotuv chekining `url`i qolardi.
Tartib almashtiriladi: avval fiskal vozvrat, keyin server. Shunda serverga
vozvratning o'z `QRCodeURL`i ketadi. Oflayn navbat allaqachon shu tartibda ishlaydi.

## Scope
- `lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart` — oqim tartibi
- `lib/features/checks/return_page/right/return_dialog/bloc/return_state.dart` — success holatiga ogohlantirish
- `lib/features/checks/return_page/right/return_dialog/return_dialog.dart` — ogohlantirishni ko'rsatish
- `lib/changes/services/receipt/refund_upload_queue.dart` — bitta vozvratni yuborish umumiy metodga chiqariladi
- Scope dan tashqari: backend endpointlari, `refund_for_pos_new` body'sidagi maydonlar
  (foydalanuvchi: "qanday ketayotgan bo'lsa ketsin, asosiysi vozvrat URL'i")

## Tahlil (2026-09-22)
- Chop etilgan vozvrat cheki va ObjectBox yozuvi TO'G'RI — `LocalService.sell` javobidan
  yangi `url`/`refundInfo` yoziladi (return_bloc.dart:175-186).
- Xato faqat serverga ketayotgan body'da: `receiptCreateGrouppForRefund` fiskaldan oldin
  chaqirilib, `"url": refundedRec.url` = sotuv URL'i ketardi (receipt_api_4.dart:132-139).
- Oflayn yo'l (`RefundUploadQueue.flush`) fiskaldan KEYIN yuboradi, shuning uchun u
  yerda URL to'g'ri edi — onlayn va oflayn bir-biriga zid edi.
- Lokal himoya bor: `return_page.dart:107-174` shu kassadagi va admin paneldagi
  vozvratlarni hisobga olib qoldiqni chiqaradi, qoldiq 0 bo'lsa mahsulot ro'yxatga
  chiqmaydi — server "allaqachon qaytarilgan" deb rad etishi amalda lokalda to'silgan.
- Fiskal vozvrat XATO bersa ham chek lokalga saqlanardi va unda sotuvning `url`/`refundInfo`
  qolardi → qayta chop etilganda sotuv QR'i chiqardi. Endi bu maydonlar tozalanadi.
- `&` chalkashligi: JSON'dagi `&` = `&`; xom JSON'dan ko'chirilgan URL soliq
  sahifasida "48 soat" xabarini beradi — bu ilova xatosi emas.

## Bajarilgan
- [x] Tahlil va reja tasdiqlandi (foydalanuvchi bilan)
- [x] `RefundUploadQueue.uploadOne()` — bitta vozvratni serverga yuborish umumiy metodi
    → lib/changes/services/receipt/refund_upload_queue.dart
    → Sabab: `flush` va `ReturnBloc` bir xil qoida bilan ishlashi kerak (200/201/409 =
      yuborildi, 5xx/tarmoq = navbatda, 4xx = rad etilgan)
- [x] `ReturnBloc._return` tartibi: fiskal → ObjectBox + chop → server
    → lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart
    → Sabab: serverga vozvratning o'z URL'i ketishi uchun; oflayn yo'l bilan bir xil
- [x] Fiskal bo'lmagan / xato bergan vozvratda sotuv `url`/`refundInfo`/fiskal maydonlari tozalanadi
    → return_bloc.dart `_clearFiscalFields`
    → Sabab: qayta chop etishda va serverda sotuv QR'i chiqmasin
- [x] Server rad etganda: `ReturnSuccedState(warning: ...)` — "Qayta urinish" tugmasi YO'Q
    → return_state.dart, return_dialog.dart
    → Sabab: fiskal vozvrat allaqachon bajarilgan, qayta urinish ikkinchi fiskal chek chiqarardi;
      chek `rejected` belgilanadi, cheklar ekranidagi "Yangilash" orqali qo'lda yuboriladi

- [x] Fiskal XATO bersa endi hech narsa saqlanmaydi va serverga ketmaydi (`ReturnFailedState`, "Qayta urinish" toza)
    → return_bloc.dart `_return` (fiscal.error != null → return)
    → Sabab: yangi tartibda fiskal xato = hali hech narsa o'zgarmagan; eski xulq (lokalga saqlash)
      server allaqachon qabul qilgani uchun edi, endi kerak emas va retry'da ikkinchi yozuv yaratardi
- [x] `ReturnBlocDeps` — bloc bog'liqliklari in'ektsiya qilinadi (internet, server, OFD, chek raqami, fiskal, ObjectBox, server)
    → return_bloc.dart oxiri; `ReturnBloc({deps})`, ishlab chiqarishda `ReturnBlocDeps.production()`
    → Sabab: oqim tartibini tarmoqsiz/modulsiz/ObjectBox'siz test qilish
- [x] `RefundUploadQueue`: `sendRequest`/`persist` in'ektsiya + `_inFlight` himoyasi
    → refund_upload_queue.dart
    → Sabab: bloc chekni `uploaded=false` bilan yozib darhol yuboradi; shu lahzada tarmoq hodisasi `flush`
      ni ishga tushirsa ikki marta POST bo'lardi
- [x] Testlar: test/return_bloc_flow_test.dart (11 holat), test/refund_upload_queue_test.dart (9 holat)
- [x] E2E Mac'da soxta fiskal modul (Node, 127.0.0.1:3448) + DEV backend bilan, ilova ichidagi haqiqiy
  servislar VM Service orqali chaqirilib (UI'siz — ilova oynasi boshqa Space'da kadr chizmagan):
    • Sotuv DP2 (fiskal seq 38011) → server 201 (eslatma: `discountID` bo'sh bo'lsa server 500
      `order_discount_type: ""` — haqiqiy sotuvda ReceiptBuilder default `9fb3ada6-...` qo'yadi)
    • Vozvrat DP3 (onlayn): fiskal `Api.SendRefundReceipt` RefundInfo=38011 → seq 38012 → ObjectBox → server.
      **DEV serverda DP3 `url` = r=38012 (vozvratniki)**, sotuv DP2 `refund_amount`=1 ✔
    • Fiskal xato (`fail` rejimi): `ReturnFailedState(MOCK...)`, ObjectBox'da yangi yozuv YO'Q, server chaqirilmadi ✔
    • Server 400 (noto'g'ri item id): `ReturnSuccedState(warning=...)`, DP5 `rejected=true, uploaded=false`,
      url=r=38013 (o'ziniki), serverda DP5 yo'q ✔
    • Server o'chgan (`BackendHealth._goDown`): `ReturnSuccedState(warning=null)`, DP6 `uploaded=false`;
      `recordSuccess` + `RefundUploadQueue.flush` → `uploaded=true`, **serverda DP6 url=r=38014** ✔
- [x] `flutter test` to'liq: 1184 test o'tdi (2026-09-22)

## Keyingi qadamlar (prioritet bo'yicha)
- [x] Reliz 1.1.2+126: commit fa2d395 (fix) + release commit, tag v1.1.2+126, GitLab + GitHub push,
      GitHub Actions run 35692912238 (success, 6m47s), `pos_1.1.2+126.exe` PRO backend'ga yuklandi
      (HTTP 201), `GET api.7i.uz/file` = 1.1.2+126, CDN 200 — 2026-09-22
- [ ] Do'konda haqiqiy fiskal modul bilan: onlayn vozvrat → admin panelda vozvrat URL'i vozvratniki
- [ ] Do'konda: server o'chirilgan holda vozvrat → navbat → server tiklangach URL to'g'ri ketishi

## Qabul qilingan qarorlar
- Tartib: fiskal → lokal → server. Sabab: server rad etishi lokal qoldiq tekshiruvi bilan
  amalda to'silgan; oflayn yo'l allaqachon shu tartibda; `rejected` mexanizmi mavjud.
- Fiskal xato bersa HECH NARSA saqlanmaydi (avvalgi reja "saqlash qoladi" edi — o'zgartirildi).
  Sabab: yangi tartibda bu holatda server ham, lokal ham tegilmagan; saqlash retry'da qoldiqni
  ikki marta kamaytirardi. Xavf: modul chekni yozib, javob yo'qolgan bo'lsa retry ikkinchi fiskal
  vozvrat chiqaradi — sotuvdagi bilan bir xil, qabul qilindi.
- Server rad etganda `ReturnSuccedState(warning)`, `ReturnFailedState` emas. Sabab: "Qayta urinish"
  tugmasi fiskal vozvratni qayta chiqarardi; chek `rejected`, cheklar ekranidan qo'lda yuboriladi.
- `refund_for_pos_new` body'siga fiskal maydonlar qo'shilmadi. Sabab: foydalanuvchi
  backend qabul qilishini bilmaydi, asosiy maqsad URL. (Serverdagi vozvrat yozuvida
  `receipt_seq/fiscal_sign` sotuvniki bo'lib qoladi — backend ularni asl orderdan nusxalaydi.)

## Ochiq savollar
- Backend `refund_for_pos_new` da `terminal_id/receipt_seq/fiscal_sign` qabul qiladimi? — backend jamoasi, shoshilinch emas
- `receiptCreateGrouppForRefund`: birinchi so'rov 201, ikkinchisi (`refund_order_items`) 4xx bo'lsa
  serverda itemsiz vozvrat sarlavhasi qolishi mumkin; qo'lda qayta yuborishda birinchi so'rov 409
  → `uploaded` deb belgilanadi, itemlar ketmaydi. Eski xulq, alohida task (E2E'da server 400 ni
  birinchi so'rovda berdi, sarlavha yaratilmadi)

## Test / Verifikatsiya
- [x] `flutter analyze` (return_page, services/receipt, l10n) — xato yo'q, faqat eski deprecation info'lar (2026-09-22)
- [x] `flutter gen-l10n` — `qaytarish_server_rad_etdi(error)` uz/ru generatsiya qilindi
- [x] `url` bo'sh bo'lgan vozvrat yozuvi UI'da "Pre Check" deb ko'rinmaydi — ikkala joy `!isRefund` bilan himoyalangan
  (build_list_item.dart:91, check_view_content.dart:116)
- [x] Birlik testlar (20) + to'liq to'plam (1184) — o'tdi
- [x] E2E (yuqorida) — 4 holat, DEV serverda tekshirildi
- [ ] Do'konda haqiqiy fiskal modul bilan (yuqoridagi "Keyingi qadamlar")
