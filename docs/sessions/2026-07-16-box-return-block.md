# Task: Blok vozvrat — UI da blok, orqa fonda dona

**Boshlangan:** 2026-07-16
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Blok sotilganda vozvrat hozir dona-dona (12 ta) qilinadi. Endi: cheklar
ko'rinishida "N blok" deb tursin, vozvrat sahifasida blokdan faqat BUTUN blok
qaytarish mumkin bo'lsin. Orqa fonda (refund API, fiskal, lokal DB) esa avvalgidek
dona hisobida (12 ta) ketaveradi — xuddi sotuvdagi kabi (UI=blok, data=dona).

## Kontekst (kod arxeologiyasi)
- Sotuvda savat blok qatori: `value=1`, `price=blokNarxi`, `saleType=2`,
  `boxValue=12`, nom "Name //blok" (`_addBoxProduct`, ordering_provider_4.dart:2203)
- To'lovda `ReceiptSingleton4.consolidateSoldItems` (receipt_singleton_4.dart:111)
  productId bo'yicha birlashtiradi: DB da `value=fizik dona (12)`, `price=dona narxi`,
  `saleType=2`, `boxValue=12`, `boxQuantity=blok soni`, nomdan " //blok" olib tashlanadi
- order_pos API ga toJson: `value = boxQuantity + loose` (token), `sale_type/box_value` bilan
- Cheklar ro'yxati lokal ObjectBox'dan (app.dart:108) → check_view_sold_items.dart
  `value * price` (12 * 2000) ko'rsatardi
- Return oqimi: check_view_content → ReUpdateBloc (API dan qoldiq qty) → ReturnPage
  `_copyWith` (lokal original bilan merge; blok maydonlarini YO'QOTARDI) →
  ReturnPageProviderr (left/right list) → ReturnBloc → refund_for_pos_new +
  refund_order_items (quantity=DONA) + fiskal LocalService.sell + ObjectBox
- refund_order_items quantity semantikasi = fizik dona (hozirgi ishlayotgan xatti-harakat)

## Scope
- lib/features/checks/return_page/return_page.dart (`_copyWith` — blok/dona qatorlarga ajratish)
- lib/changes/providers/return_page_provider.dart (merge kaliti productId+saleType, box maydonlarini ko'chirish)
- lib/features/checks/return_page/left/build_left_list.dart, right/build_right_list.dart (blok tap + "N blok" ko'rinish)
- lib/features/checks/return_page/return_page_dialog/return_page_dialog.dart (blok uchun faqat butun son)
- lib/features/checks/features/check_view/check_view_sold_items.dart ("N blok × blokNarx" ko'rinish)
- lib/changes/services/receipt_api_4.dart (`funcToRefund` — bir xil refundItemId larni jamlash)
- Scope'dan tashqari: chek printeri formati, order_pos body (o'zgarmaydi), backend

## Bajarilgan
- [x] `_copyWith`: qoldiq blok va dona qatorlarga ajratiladi, blok maydonlari
  lokal originaldan ko'chiriladi
  → lib/features/checks/return_page/return_page.dart (makeItem closure,
    blocksAvailable = min(boxQuantity, qoldiq ~/ boxValue))
  → Sabab: avval saleType/boxValue yo'qolardi — blok 12 dona bo'lib ko'rinardi
- [x] ReturnPageProviderr: merge kaliti productId+(saleType==2), butun qator
  ko'chganda `v += item.value` (avval v++ — blokda 12 o'rniga 1 qo'shilardi,
  yashirin bug), value o'zgargach boxQuantity sinxron (_syncBoxQuantity),
  `_itemCopyWith` blok maydonlarini ko'chiradi
  → lib/changes/providers/return_page_provider.dart
- [x] Left/Right ro'yxatlar: blok qatori "Name x N blok" ko'rinishida; tap:
  1 blok → butun qator, N blok → dialog blok hisobida so'raydi va
  N×boxValue dona ko'chiradi
  → lib/features/checks/return_page/left/build_left_list.dart,
    right/build_right_list.dart
- [x] ReturnPageDialogg `wholeUnitsOnly` param — blokda faqat butun son (digitsOnly)
  → lib/features/checks/return_page/return_page_dialog/return_page_dialog.dart
- [x] Check view: blok item "N blok * blokNarx (+ M * donaNarx)" ko'rinishida,
  trailing total o'zgarmagan (value×price)
  → lib/features/checks/features/check_view/check_view_sold_items.dart
- [x] funcToRefund: bir xil refundItemId li qatorlar (blok+dona) bitta itemga
  jamlanadi, quantity dona hisobida
  → lib/changes/services/receipt_api_4.dart
- [x] Testlar: 6 ta unit test (provider ko'chirish + funcToRefund body)
  → test/box_return_block_test.dart — hammasi o'tdi
- [x] flutter analyze — yangi xato yo'q (faqat pre-existing info/warninglar)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows real test: blok sotish → cheklar da "1 blok * narx" ko'rinishi
- [ ] Windows real test: vozvrat sahifasida blok "x 1 blok" bo'lib turishi,
      tap qilganda butun blok o'tishi, dialog (2+ blok) faqat butun son olishi
- [ ] Backend tekshiruv: refund_order_items body da quantity=12 (dona) ketishi,
      admin panelda 12 dona vozvrat ko'rinishi
- [ ] Aralash case: 1 blok + 4 dona sotib, blokni alohida / donani alohida qaytarish

## Bug-fix: "3 blok sotib 1 blok vozvratdan keyin 2 blok yo'qoldi" (2026-07-16)
Foydalanuvchi testi: 3 blok sotildi → 1 blok vozvrat → vozvratga qayta
kirilganda qolgan 2 blok ko'rinmadi.

**Muhim aniqlik (foydalanuvchi tasdiqladi):** backend hamma narsani DONA
hisobida yuritadi — sotuvda "36 ta sotildi", vozvratda "12 ta qaytdi" bo'lishi
kerak. (Birinchi urinishda quantity'ni TOKEN (blok soni) qilib yuborish deb
xato diagnoz qo'yilgan edi — foydalanuvchi to'g'rilagach dona'ga qaytarildi.)

**HAQIQIY ILDIZ SABAB (skrinshotlar bilan tasdiqlandi, DH119/DH120 case):**
`ReceiptSingleton4.toOBJECTBOX` har chekni `consolidateSoldItems`dan o'tkazardi
— VOZVRAT chekini ham. Konsolidatsiya savat formatini kutadi (blok qatori
value=1 token, price=blok narxi), vozvrat qatori esa allaqachon dona hisobida
(value=12, price=dona narxi). Natija: 12 dona "12 blok" deb olinib value=144,
price=150 bo'lib saqlandi (check view'da "12 blok * 1,800" ko'rinishi shundan).
Keyin `_getAlreadyRefundedQty` 144 deb hisoblab, qoldiq 36−144 ≤ 0 → return
sahifasi bo'm-bo'sh. Ya'ni muammo backendda EMAS, lokal saqlashda edi.

**Fix (asosiy):**
- toOBJECTBOX: `isRefund` chekda consolidateSoldItems chaqirilmaydi
  → receipt_singleton_4.dart:27 atrofida guard
- `_getAlreadyRefundedQty` self-heal: eski buzilgan vozvrat yozuvi
  (refund boxQuantity > sotuv boxQuantity) uchun dona = value/boxValue —
  foydalanuvchining mavjud DH119 cheki yana ishlaydi
- consolidate semantikasi 2 ta test bilan mixlandi (savat→dona; vozvrat qatori
  konsolidatsiyada buzilishi hujjatlashtirilgan)

**Qo'shimcha mustahkamlik (oldinroq kiritilgan, saqlanadi):**
- re_update_bloc: lokal chekda saleType==2 bo'lgan mahsulotlar API filtridan
  o'tkazilmaydi (har doim ro'yxatga kiradi, value'ga tegilmaydi)
- `_copyWith`: hasBox itemda remainingQty = lokal sotuv (36) − lokal vozvratlar
  (12) = 24; API e.value ishlatilmaydi. Oddiy itemlar avvalgidek min() bilan.
- funcToRefund: quantity DONA (1 blok = 12) — foydalanuvchi talabi, backend
  dona hisobida.
- Cheklama (hujjatlashtirildi): blok mahsulot uchun ADMIN paneldan qilingan
  vozvratlar POS return sahifasida hisobga olinmaydi (lokal DB'da yo'q) —
  bunday holatda backend refund POST'ni o'zi rad etishi kutiladi.

**Verifikatsiya (foydalanuvchi):**
- Mavjud DH119: vozvratga kirganda self-heal tufayli "x 2 blok" ko'rinishi kerak
  (DH120 ning "12 blok * 1,800" ko'rinishi lokal buzuq YOZUVda qoladi — kosmetik,
  yangi vozvratlarda chiqmaydi)
- YANGI chek: 3 blok sotish → 1 blok vozvrat → vozvrat cheki check view'da
  "1 blok * 21,600" → qayta kirganda "x 2 blok" → yana 1 blok → "x 1 blok"

## Qabul qilingan qarorlar
- refund_order_items quantity har doim DONA hisobida (1 blok = boxValue dona) —
  backend sotuvni ham dona hisobida yuritadi (foydalanuvchi tasdiqladi).
- Blok mahsulot qoldig'i (return sahifasida) faqat LOKAL hisobdan: sotuv cheki
  dona soni − shu kassadagi vozvratlar. Sabab: API value/refund_amount birligi
  blok itemda ishonchsiz, shu sabab item "yo'qolib" qolardi.
- Ichki data DONA hisobida qoladi (value=dona, price=dona narxi) — fiskal/API/DB
  o'zgarmaydi; blok faqat display+granularity qatlami. Sabab: refund_order_items,
  OFD tenglama va _getAlreadyRefundedQty allaqachon dona bilan ishlaydi.
- Aralash qoldiq (masalan 12 dan 8 qolgan, boxValue=12): butun blokka yetmasa
  dona sifatida qaytariladi (blocksAvailable = floor(qoldiq/boxValue), max boxQuantity).

## Ochiq savollar
- ⚠️ refund_for_pos_new bodysidagi qo'lda qo'shilgan "userId" (receipt_api_4.dart:139)
  hali ham turibdi — backend bilan kelishib olib tashlash/qoldirish hal qilinishi kerak.

## Test / Verifikatsiya
- flutter analyze
- Windows: blok sotish → cheklar da "1 blok" ko'rinishi → vozvrat → faqat blok
  qaytarish mumkinligi → backendda 12 dona refund bo'lishi
