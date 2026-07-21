# Task: O'chirilgan mahsulotlarni order_pos API'ga deleted_items sifatida jo'natish

**Boshlangan:** 2026-07-16
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Savatdan o'chirilgan mahsulotlar hozir faqat Telegram kanalga ketadi. Endi ular
sotuv yakunlanganda `api/v1/order_pos` body'sidagi `deleted_items` massivida
serverga ham ketadi: `deleted_by` (kassir id), `deleted_time`, `product_id`,
`quantity`, `total_price` (narx × soni). Offline sotuvda ham chek bilan birga
saqlanib, keyin yuboriladi.

## Scope
- lib/changes/models/deleted_item_model.dart (yangi)
- lib/changes/models/six_client_model.dart
- lib/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart
- lib/changes/providers/ordering_provider_4.dart
- lib/changes/services/receipt_api_4.dart
- lib/objectbox.g.dart, lib/objectbox-model.json (kodgen)
- Scope'dan tashqari: Telegram jo'natish O'ZGARMAGAN (saqlanib qoldi), butun
  savatni bekor qilish (cancelOrdering) deleted_items ga yozilmaydi — u alohida
  Telegram oqimiga ega va order yaratilmaydi.

## Bajarilgan
- [x] DeletedItemModel4 modeli (deleted_by/deleted_time/product_id/quantity/total_price)
  → lib/changes/models/deleted_item_model.dart
- [x] SixClientModel4 ga per-slot `deletedItems` ro'yxati (field initializer, konstruktor o'zgarmadi)
  → lib/changes/models/six_client_model.dart
- [x] ReceiptModel4 ga `deletedItemsJson` (String, default "[]") — ObjectBox'da offline saqlanadi
  → receipt_model_4.dart; toJson'da `"deleted_items"`, fromJson'da parse
  → Sabab: yangi ToMany entity o'rniga JSON-string — migratsiya xavfsiz (additiv property), kodgen minimal
- [x] `_recordDeletedItem()` helper — kassir id (HiveBoxes.getCurrentEmployee.user.id, fallback PrefKeys.cashierId), vaqt `yyyy-MM-dd HH:mm:ss`, total = price × value
  → ordering_provider_4.dart (pressDialogDeleteButton dan oldin)
- [x] O'chirish nuqtalariga yozuv: removeLastAdded (2 branch), pressDialogDeleteButton, _saveMarkGroup (mark qty kamayishi), _deleteMarkGroup
  → ordering_provider_4.dart
- [x] To'lovda biriktirish + tozalash: pressPaymentButton va pressPaymentButtonOnlyOFD — `receiptModel4.deletedItemsJson = jsonEncode(...)`, muvaffaqiyatli saqlashdan keyin `deletedItems.clear()`
  → Sabab: sotuv muvaffaqiyatsiz bo'lsa ro'yxat yo'qolmaydi; savat sotuvsiz tashlab ketilsa ham keyingi yakunlangan sotuvga biriktiriladi (audit yo'qolmaydi)
- [x] receipt_api_4.dart `func()` server nusxasiga deletedItemsJson ko'chirildi (eski DB yozuvlari uchun bo'sh → "[]" guard)
- [x] ObjectBox kodgen: `dart run build_runner build` — "Found new property ReceiptModel4.deletedItemsJson"
- [x] dart analyze — yangi xato/warning yo'q
- [x] Qty kamaytirish ham yoziladi (3 pepsi → 2: farq 1 dona deleted bo'lib ketadi)
  → ordering_provider_4.dart pressDialogSaveButton — oldItem.value − item.value farqi, eski narx bilan
  → Sabab: foydalanuvchi testda qty kamaytirishni ham o'chirish deb kutdi (2026-07-16 feedback)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da real test: (1) mahsulot qo'shib o'chirish → sotuv → order_pos body'sida deleted_items borligini curl-log orqali tekshirish (LogHelper 'order_pos CURL'); (2) offline sotuv → keyin flush → deleted_items ketganini tekshirish; (3) red-delete rejimida ham
- [ ] Backend deleted_items ni qabul qilishini tasdiqlash (schema allaqachon Swaggerda bor)

## Qabul qilingan qarorlar
- deleted_items ObjectBox'da alohida entity emas, ReceiptModel4.deletedItemsJson (String) — additiv migratsiya, ToMany kodgen shart emas
- Telegram jo'natish saqlanib qoldi (foydalanuvchi olib tashlashni aniq aytmadi)
- Miqdor kamaytirish (5→3 tahrir) HAM deleted_items ga yoziladi (farq miqdori, eski narx) — foydalanuvchi talabi
- Savat sotuvsiz tozalansa (cancelOrdering) deleted_items ga yozilmaydi — order yo'q, alohida Telegram oqimi bor

## Ochiq savollar
- Telegram jo'natishni olib tashlash kerakmi? (hozircha ikkalasi ham ishlaydi)

## Test / Verifikatsiya
- dart analyze toza; build_runner kodgen muvaffaqiyatli
- **OFFLINE BATCH testi (18-test):** 10 ta chek, har birida boshqa delete case
  (1 dona / 50 ta / 50→35 / 2 xil product / tarozi 2.5→1.0 / deletesiz / value=0 /
  X tugma / mark-guruh / 100→40+15). Real `ReceiptApi4.receiptCreateGroup` orqali
  qurilgan upload body tekshirildi: 10 order, har birida o'z deleted_items,
  cheklar aro aralashish yo'q, deletesiz chekda bo'sh massiv — hammasi to'g'ri
- **test/deleted_items_orderpos_test.dart — 17 test, hammasi o'tdi** (real provider
  metodlari Hive temp-muhitda): OPD delete (to'liq/o'rtadagi qator), qty kamaytirish
  (3→2, 5→1, kasr/tarozi 1.5→0.5, value=0), qty oshirish yozilmasligi, faqat narx
  o'zgarsa yozilmasligi, removeLastAdded, mark-guruh (qty kamaytirish + to'liq delete),
  bir sessiyada yig'ilish, toJson'da deleted_items, ReceiptApi4.func nusxasi, bo'sh
  ro'yxat [], eski chek ("" guard), sotuvdan keyin tozalash
- Guard qo'shildi: allaqachon isDeleted=true qator qayta yozilmaydi (X tugma
  ketma-ket bosilganda double-record oldini oladi); red-delete foydalanuvchi uchun
  muhim emas deb aytildi (2026-07-16), guard baribir zararsiz
- Windows'da real sotuv testi kutilmoqda (order_pos CURL logda deleted_items)
