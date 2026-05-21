# Task: Fiskal sotuvni (pressPaymentButtonOnlyOFD) tezlashtirish

**Boshlangan:** 2026-05-20
**Holat:** in-progress
**Branch:** main

## Maqsad

`OrderingProvider4.pressPaymentButtonOnlyOFD` orqali soliq/OFD sotuvi bajarilganda foydalanuvchi "Sotuv tugadi" javobini kutish vaqti sezilarli darajada uzun. Maqsad — bu oqimni 600 ms dan 2.5 sekundgacha tezlashtirish, kod toza va backwards-compatible holatda qolishi.

## Scope

**Ta'sirlanadigan fayllar:**
- `lib/changes/providers/ordering_provider_4.dart` — `pressPaymentButtonOnlyOFD` (qator 2863-3053)
- `lib/changes/services/local_selling_service.dart` — `sell()`, `saleWithOutIncom()`
- `lib/fiscal_service/base_service.dart` — `post()`, `getTerminalID()`, `getFactoryId()`
- `lib/fiscal_service/storage_service.dart` — `getFactoryID()`
- `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart` — `toOBJECTBOX`
- `lib/features/printing/methods/printing_methods.dart` — `printCheck`
- `lib/changes/repository/log_repository.dart` — `addLog`, `requestSend`

**Scope dan tashqari:**
- INCOM rejimi (`Pref.getBool(PrefKeys.withINCOM)=true`) — boshqa oqim, alohida task
- pressPaymentButton (oddiy to'lov) — alohida task
- Return/refund oqimi — alohida task

## Aniqlangan bottleneck'lar (asl tahlil)

1. Har sotuvda fiskal modulga 3 ta HTTP POST: `getFactoryID` + `getTerminalID` + asosiy sale → 300-800 ms
2. `LogRepository.addLog` va `requestSend` Telegramga `await` bilan POST yuboradi (`log_repository.dart:81-86, 209-215`) → 100-500 ms, internet sekinligida bir necha sekund
3. `Printing.listPrinters()` har sotuvda chaqiriladi (`printing_methods.dart:287`) → 200-1500 ms Windowsda
4. `http.post` har safar yangi TCP ulanish → 20-80 ms har sotuv
5. ✅ `cleanMarkForFiscal` dublikati — bajarildi
6. ✅ `Pref.setString("bodyForDiscountError", ...)` har sotuvda — bajarildi
7. `getTimeZoneTime()` — network emas, sof DateTime.now() hisobi, ahamiyatli emas
8. `printCheck` `await` bilan `toOBJECTBOX` ichida — UI 200-1500 ms kutib turadi

## Bajarilgan

- [x] **#5 — Dublikat `cleanMarkForFiscal` olib tashlandi**
  → `lib/changes/services/local_selling_service.dart:66-80` (oldingi 76-84 qator olib tashlandi)
  → Sabab: `ReceiptSingleton4.saleOnOFD(receiptData)` body Map'ni qurib bo'ladi, undan keyin `item.mark` ni mutate qilish dead code (yuborilayotgan body'ga ta'sir qilmaydi). Tozalash ordering_provider_4.dart:2944-2950 da `sell()` chaqiruvidan oldin bajariladi — bu yetarli (single source of truth).

- [x] **#6 — Pref I/O olib tashlandi, `orderBody` parametrga aylantirildi**
  → `lib/fiscal_service/base_service.dart:17-21` — `BaseService.post` ga `String? orderBody` ixtiyoriy parametri qo'shildi
  → `lib/fiscal_service/base_service.dart:9` — ishlatilmagan `prefs.dart` importi olib tashlandi
  → `lib/changes/services/local_selling_service.dart:296-299` — `Pref.setString("bodyForDiscountError", ...)` o'rniga body to'g'ridan-to'g'ri parametr orqali uzatiladi
  → Sabab: global mutable holat o'rniga aniq parametr; har sotuvda ikkita Pref disk I/O (yozish + xato bo'lsa o'qish/o'chirish) yo'qoldi. Boshqa BaseService.post chaqiruvchilarining signaturasiga ta'sir qilmaydi (ixtiyoriy parametr).

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] **#0 — Stopwatch bilan o'lchov o'tkazish** (eng to'g'ri yondashuv — keyingi qadamlarni aniqlashtirish uchun)
  → `lib/changes/providers/ordering_provider_4.dart:3004` (`LocalService.sell` chaqiruvi atrofida)
  → `lib/changes/services/local_selling_service.dart:241-304` (`saleWithOutIncom` ichidagi har bosqich)
  → `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart:75-92` (`printCheck`)
  → Maqsad: haqiqiy bottleneck'ni raqamlar bilan tasdiqlash, gipotezaga emas

- [ ] **#1 — FactoryID/TerminalID smena boshida keshlash** (taxminiy ta'sir: 300-800 ms)
  → Hozir: `lib/changes/services/local_selling_service.dart:244-245` har sotuvda chaqiriladi
  → Reja:
    - `PrefKeys` ga `cachedFactoryID` va `cachedTerminalID` qo'shish (`lib/utils/helpers/prefs.dart` yoki tegishli fayl)
    - Smena ochilishida (`ShiftSingleton4.openShift` yoki shunga o'xshash) yoki ilova startida bir marta olib Prefga yozish
    - `saleWithOutIncom` da avval Prefdan o'qib olish; agar bo'sh bo'lsa fallback sifatida network'dan olish + Prefga yozish
  → Yo'qotilmasligi kerak: fiskal modul almashtirilsa qayta ulanishda kesh tozalanishi kerak

- [ ] **#3 — `printCheck` ni `unawaited` qilish** (taxminiy ta'sir: 200-1500 ms UX)
  → `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart:75, 84` — `await PrintingMethods.printCheck(...)` ni `unawaited(PrintingMethods.printCheck(...))` ga aylantirish
  → ObjectBox'ga yozilgandan keyin UI darhol qaytadi, chop etish fonda davom etadi
  → Diqqat: printer xatosi bo'lsa qanday ko'rsatish kerak — toast/snackbar mexanizmi qo'shilishi mumkin

- [ ] **#2 — Telegram log chaqiriqlarini `unawaited` qilish** (100-500 ms)
  → `lib/changes/repository/log_repository.dart:81-86` (`addLog` ichida)
  → `lib/changes/repository/log_repository.dart:209-215` (`requestSend` ichida)
  → `await LogService.sendToTelegramm(...)` → `unawaited(LogService.sendToTelegramm(...))`
  → `await box.add(log)` ham fire-and-forget qilish mumkin (Hive yozish lokal, lekin disk I/O)
  → Jo'natilmagan log'lar baribir `sendUnsentLogs()` orqali tiklanadi

- [ ] **#4 — `Printing.listPrinters()` natijasini keshlash** (200-800 ms, agar #3 qilinmasa)
  → `lib/features/printing/methods/printing_methods.dart:287`
  → Static field + 5-15 daqiqalik TTL yoki sozlamalarda printer o'zgarganda invalidate
  → Agar #3 qilinsa, bu qadam past prioritet

- [ ] **#5 — `http.Client` singleton fiskal modul uchun** (20-80 ms har sotuv)
  → `lib/fiscal_service/base_service.dart:20`
  → `lib/changes/services/local_selling_service.dart` ichidagi barcha `http.post` chaqiruvlari (91, 348, 382, 416, 463, 540 qatorlar)
  → Static `http.Client _client = http.Client()` qilib har joyda `_client.post(...)` ishlatish
  → Keep-alive TCP ulanish qayta ishlatiladi

## Qabul qilingan qarorlar

- **`BaseService.post` signaturasini buzmaslik:** `orderBody` ni ixtiyoriy nomli parametr qildi, global static state ishlatmadi. Sabab: 20+ ta chaqiruvchi bor, ularning hech birini buzmaslik kerak.
- **`cleanMarkForFiscal` faqat `ordering_provider_4` da qoladi:** single source of truth, `sell()` ichidagi dublikat olib tashlandi. Boshqa joydan `LocalService.sell` chaqirilsa, ular ham `cleanMarkForFiscal` qilishi kerak (hozircha boshqa chaqiruvchi yo'q).
- **O'lchovsiz katta o'zgartirishlarga kirishmaslik:** keyingi qadam (#0) — Stopwatch o'lchovi. Aniq raqamlar bo'lmaguncha #1-#5 ni boshlash xato.

## Ochiq savollar

- `printCheck` ni `unawaited` qilganda printer xatosi (qog'oz tugagan, ulanish yo'q) qanday foydalanuvchiga ko'rsatiladi? Toast/snackbar yoki sotuv ekranida indikator?
- `FactoryID`/`TerminalID` keshini qachon invalidate qilish kerak? Smena yopilganda? Fiskal modul qayta ulanganda? Ilova qayta ishga tushganda?
- Telegram log'lari `unawaited` bo'lsa, sotuv muvaffaqiyatsiz bo'lib log ham yo'qolib qolish ehtimoli bormi? (Tahmin: `sendUnsentLogs` keyingi log chaqirig'ida ishga tushadi, lekin tekshirish kerak)

## Test / Verifikatsiya

**Bajarilganlar uchun (#5, #6):**
- [x] `flutter analyze lib/changes/services/local_selling_service.dart lib/fiscal_service/base_service.dart` — yangi diagnostika yo'q (3 ta ogohlantirish pre-existing)
- [ ] Markirovkali chek bilan haqiqiy sotuv qilib, fiskal modul body'da clean mark yetishini tekshirish (manual)
- [ ] Pref'da `bodyForDiscountError` kaliti endi yozilmasligini tekshirish (DevTools yoki Pref dump)
- [ ] Xato sotuvda log ichida `Order Body == ...` qismi mavjudligini tekshirish (xatolik simulyatsiyasi bilan)

**Kelgusi qadamlar uchun:**
- Stopwatch o'lchovi bitta haqiqiy sotuv ustida (log fayliga yoki `debugPrint` orqali)
- Har optimallashtirishdan keyin yana o'lchash — regressiyani aniqlash
