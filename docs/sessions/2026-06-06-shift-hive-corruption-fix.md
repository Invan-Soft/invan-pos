# Task: Smena (shifts.hive) buzilishi va Z-otchot bo'sh muammosi

**Boshlangan:** 2026-06-06
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Svet o'chishi (yoki force-kill) Hive `shifts` box compaction'i paytiga to'g'ri kelganda `shifts.hive` 0KB bo'lib buziladi. Natijada `shiftsOpened=true` (prefs butun), lekin `shifts.get(currentShiftKey)=null` → Z/X-otchot bo'm-bo'sh, smenani yopib bo'lmaydi. Cheklar (ObjectBox) butun qoladi. Shu holatdan o'zini tiklash + buzilish chastotasini kamaytirish.

## Ildiz sabab (tahlil)
- `shifts.hive` ga HAR sotuvda yoziladi: `ReceiptSingleton4.toOBJECTBOX` → `ShiftSingleton4.updateTheShift` / `updateShiftOnRefund` (bir xil `currentShiftKey` ga ustiga).
- Bu per-sotuv yozuv ORTIQCHA: `getCurrentHiveShift()` baribir barcha summalarni ObjectBox cheklaridan qaytadan hisoblab, ustiga yozadi.
- Per-sotuv yozuv → o'chirilgan yozuvlar to'planadi → Hive default compaction (~deletedEntries>60 && >15%) ishga tushadi → butun faylni qayta yozadi → o'sha lahzada uzilish (svet/force-kill) → 0KB.
- `prefs` boshqa box (boshqa fayl) → butun qoladi → desync.
- Buzilgan kassa: shifts.hive 0KB, sana 2026-06-05 22:42 (do'kon yopilishi). Papka 2026-03-28 da yaratilgan (~2 oy yig'ilgan smenalar, fayl katta → compaction uzoq → uzilishga ko'proq moyil).

## Scope
- `receipt_singleton_4.dart` — per-sotuv shift yozuvini olib tashlash
- `shift_singleton_4.dart` `getCurrentHiveShift()` — self-heal (null bo'lsa qayta tiklash)
- `buttons.dart` (shifts_opened) — close tugmasi null-safe + getCurrentHiveShift orqali
- Scope dan tashqari: backend 500 xatosi (api/v1/order_pos COALESCE varchar/text[]) — bu Sirojiddin backendida, alohida.

## Bajarilgan
- [x] Per-sotuv shift yozuvi olib tashlandi
  → receipt_singleton_4.dart:76 atrofi (updateTheShift/updateShiftOnRefund chaqiruvlari kommentga olindi)
  → endi ishlatilmaydigan ShiftSingleton4 importi ham olib tashlandi
  → Sabab: yozuv ortiqcha edi (getCurrentHiveShift baribir qaytadan hisoblaydi) + compaction churn'ni keltirardi
- [x] getCurrentHiveShift self-heal qo'shildi
  → shift_singleton_4.dart:85283 atrofi
  → currentShift==null && shiftsOpened && shiftOpenedTime>0 && key>=0 → _initOfflineShiftOnHive(0) bilan tiklab, box.put
  → shiftOpenedTime<=0 bo'lsa tiklamaydi (butun-tarix xatosi oldini olish)
- [x] buttons.dart close tugmasi null-safe
  → buttons.dart:35 atrofi — getCurrentHiveShift() + `if (shift==null) return`
  → eski `.get(...)!` null'da crash berib tugmani "ishlamas" qilardi (1-skrinshot muammosi)
  → shift_singleton_4 importi qo'shildi, ishlatilmagan shift_hive_model importi olib tashlandi
- [x] dart analyze — tegilgan 3 faylda mening o'zgartirishlardan XATO yo'q (faqat avvaldan bor warninglar)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da test: smena ochib ~60+ sotuv, `type nul > shifts.hive`, ilovani qayta ochib (1) otchot to'lishini (2) smena yopilishini tekshirish
- [ ] (ixtiyoriy) Event Viewer ID 41 (2026-06-05 22:42) — svetmi yoki force-kill tasdiqlash

## Qabul qilingan qarorlar
- Per-sotuv yozuv olib tashlanadi (o'chirilmaydi, faqat chaqiruv) — getCurrentHiveShift baribir qaytadan hisoblaydi.
- Self-heal: null bo'lsa `_initOfflineShiftOnHive(0)` bilan qayta tiklanadi (startingCash yo'qolgan → 0). shiftOpenedTime prefs'da butun (desync holatida).
- Auto-compaction o'chirilmadi (per-sotuv yozuv ketgach, shifts box deyarli yozilmaydi → compaction baribir kamdan-kam).

## Ochiq savollar
- Buzilish svetmi yoki force-kill — Event Viewer ID 41 (2026-06-05 22:42) tasdiqlaydi (foydalanuvchi tekshiradi).

## Test / Verifikatsiya
- Windows: smena ochib, ~60+ sotuv, `type nul > shifts.hive`, ilovani qayta ochib otchot to'lishini va smena yopilishini tekshirish.
