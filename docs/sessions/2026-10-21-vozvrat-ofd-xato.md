# Task: Vozvrat OFD xatosi (RefundInfo — OFD serveriga ulanish xatosi) tahlili

**Boshlangan:** 2026-10-21
**Holat:** in-progress
**Branch:** fix/vozvrat-ofd-xato (asos: `ayyubxon` b1fd08d = 1.1.2+130 + Shorebird patch)

## Maqsad
Tiin Optom, Kassa 5 (DESKTOP-AOC7AML) dan Telegramga kelgan vozvrat xatosini tahlil qilish:
`При регистрации чека возврата и при проверки информации об отозванном чеке (RefundInfo)
возникла ошибка подключения к серверу ОФД. Повторите попытку.` (2026-10-21 21:56:27 va
21:56:46, ikki marta). Bizning xatomi yoki muhit (fiskal modul ↔ OFD)? Fiskal body'dagi
`staffName: Aqliddin` va log'dagi `Employee: Dilorom` nomuvofiqligi.

## Scope
- Tahlil: `lib/changes/services/local_selling_service.dart`, `lib/fiscal_service/`,
  `lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart`,
  `lib/changes/repository/log_repository.dart`, `lib/changes/services/log_service.dart`
- Tuzatish: faqat `LogRepository._currentEmployee` (Telegram log'idagi xodim)
- Scope dan tashqari: fiskal so'rov, vozvrat oqimi (to'g'ri ishlayapti), `api_provider.dart`,
  terminal kodi

## Tahlil (2026-10-21)
- **Xato matni bizning repoda bor, lekin u FiscalDriveAPI xato KODINING tarjimasi.**
  `ErrorModel.toMessage()` (lib/fiscal_service/model/error/error_response_model.dart:56-57)
  `code == 65274` (0xFEFA) → `ApiErrorResponses.netwokError`
  (lib/fiscal_service/api_error_response.dart:15-16). Ya'ni FiscalDriveAPI
  (`http://127.0.0.1:3448/rpc/api`, `Api.SendRefundReceipt`) JSON-RPC `error.code = 65274`
  qaytargan: modul RefundInfo'ni OFD serverida onlayn tekshirmoqchi bo'lgan va OFD serveriga
  ULANA OLMAGAN. Matn FiscalDriveAPI hujjatidagi kodlar jadvalidan so'zma-so'z ko'chirilgan.
- **So'rov `localhost:8080/invan` ga ketmagan.** Kassada `withINCOM = false`
  (log'dagi `BaseService Body` = `Api.SendRefundReceipt` + `FactoryID` — bu
  `saleWithOutIncom` yo'li, local_selling_service.dart:79-108, 268-342). Telegram'dagi
  `URL: http://localhost:8080/invan` — `LogRepository.requestSend(url: AppConstants.localhost)`
  ga qattiq yozilgan qiymat (local_selling_service.dart:198-207), haqiqiy manzil emas.
- **`Status Code: 0`** — HTTP status emas. `LocalService._statusCode` (local_selling_service.dart:31)
  faqat INCOM yo'lida to'ldiriladi (:95); INCOM'siz yo'lda hech qachon yozilmaydi va boshlang'ich
  `0` qoladi. FiscalDriveAPI'ning o'zi HTTP 200 qaytargan (JSON-RPC xatosi body ichida,
  base_service.dart:35-38, `Failure(200, body)`). `0 < 200` bo'lgani uchun log Telegramga ketgan
  (log_repository.dart `isSend`).
- **Vozvrat oqimi xatoda TO'G'RI ishladi** (return_bloc.dart:171-188): fiskal xato →
  `ReturnFailedState`, ObjectBox'ga yozilmaydi (`saveLocal` chaqirilmaydi), serverga
  ketmaydi (`uploadToServer` chaqirilmaydi), qoldiq kamaymaydi. Testlar:
  test/return_bloc_flow_test.dart 6- va 7-holat. Kassir dialogda
  "Qaytarish amalga oshirilmadi" + `Error: <matn>` va "Bekor qilish" / "Qayta urinish"
  tugmalarini ko'radi (return_dialog.dart:135-193). 19 soniyalik ikkinchi xabar = kassir
  "Qayta urinish" bosgan.
- **Qayta urinish xavfsiz:** 65274 RefundInfo tekshiruvi bosqichida — vozvrat cheki FM'da
  ro'yxatdan o'tishidan OLDIN qaytadi, ikkinchi fiskal vozvrat chiqmaydi. Har urinish
  `event.receiptModel4` dan yangi model quradi; `ReceiptApi4.func`/`saleOnOFD` sotilgan
  itemlarni o'zgartirmaydi. Yagona yon ta'sir: `getCheckNo()` (receipt_singleton_4.dart:214)
  har urinishda lokal chek hisoblagichini +1 qiladi — muvaffaqiyatsiz urinish raqamni "yeydi"
  (kosmetik, fiskal emas, eski xulq).
- **RefundInfo to'g'ri:** qiymatlar asl sotuvda FiscalDriveAPI javobidan saqlangan
  (`toOBJECTBOX`, receipt_singleton_4.dart:63-82 → `refundInfo` JSON), `_refundInfo`
  (:560-571) va `RequestRefundInfo.fromJson` (request_receipt_model.dart:382-387) orqali
  modulga hammasi STRING bo'lib ketadi: `TerminalID "LG230110020518"`, `ReceiptSeq "1270"`,
  `DateTime "20261021215439"` (sotuv vaqti 21:54:39, FM'niki), `FiscalSign "554350080406"`.
  Format xato bo'lsa modul 65275 (noto'g'ri qiymatlar) / 65277 (yaroqsiz FP) / 65532
  (yaroqsiz parametr) qaytarardi, 65274 emas. Kod yo'li eski, 1.1.2+129 dan beri o'zgarmagan.
- **`git log v1.1.2+129..HEAD`** vozvrat yo'lida: faqat dd624bf (YagonaQr) `receipt_vat.dart` ga
  tekkan — vozvrat shoxi (`isRefund` → hammasi naqd, return'dan oldin) o'zgarmagan.
- **`staffName: Aqliddin` TO'G'RI** — `saleOnOFD` `Pref cashierName` ni oladi
  (receipt_singleton_4.dart:275), u PIN bilan kirgan JORIY kassir (lock_buttons_with_shortcuts.dart:262).
  **`Employee: Dilorom` XATO edi** — `LogRepository._currentEmployee` `static final`
  (log_repository.dart:20): ilova ochilgandan keyingi birinchi log'da bir marta o'qilib qotib
  qolardi. Dilorom smenani/ilovani ochgan, keyin Aqliddin PIN bilan kirgan. 2026-03-26 dan
  beri (boshlang'ich commit) barcha Telegram log'larida "Employee" shunday.

## Bajarilgan
- [x] Xato manbai, oqim, RefundInfo, staffName, git tarixi tahlil qilindi (yuqorida)
- [x] `LogRepository._currentEmployee` — `static final` → getter (har log'da qayta o'qiladi,
      xato bersa `null`)
    → lib/changes/repository/log_repository.dart:20-31
    → Sabab: Telegram'da noto'g'ri xodim chiqardi va tahlilni chalg'itdi (bu safar ham)
- [x] Test: test/log_repository_employee_test.dart (3 holat) — tuzatishdan oldin 3 tasi ham
      yiqildi (`Dilorom` qotgan), keyin o'tdi
- [x] Commit `4de89e6` (fix + test); to'liq `flutter test` 2038 o'tdi, 7 skip, 0 yiqildi
- [x] `docs/port-changelog.md` — 18-task bo'limi (jadval, xronologiya, bo'lim). Odoo forkiga: kerak

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Foydalanuvchi: commitni ko'rib `ayyubxon` ga merge qilish / Shorebird patch qarori
- [ ] Do'kon (Kassa 5): FiscalDriveAPI ↔ OFD aloqasini tekshirish (pastda "Do'konga tavsiya")
- [ ] Ixtiyoriy (taklif, qilinmagan): `LocalService.sell` INCOM'siz yo'lda log'ga haqiqiy URL
      (`AppLinks.baseUrl`) va JSON-RPC `error.code` ni yozish (local_selling_service.dart:186-207);
      65274 uchun kassirga tushunarli o'zbekcha matn

## Do'konga tavsiya
1. Vozvratni bir necha daqiqadan keyin qayta urinish — xavfsiz (hech narsa saqlanmagan).
2. Kassa 5 kompyuterida: PowerShell `Test-NetConnection s0.ofd.uz -Port 3447` (s1, s2 ham) —
   `TcpTestSucceeded : True` bo'lishi kerak. Umumiy internet bor bo'lsa ham (ilova internet
   tekshiruvidan o'tgan) 3447-port firewall/provayder tomonidan yopiq bo'lishi mumkin.
3. FiscalDriveAPI config (`C:\Program Files\FiscalDriveAPI\config.ini`, `[server]`) da eski
   `ofd*.yt.uz` qolmaganini va servis yangi config bilan ishlayotganini tekshirish
   (`C:\ProgramData\InVanPos2\cache\ofd_migration.log`; config yangilangan, lekin kompyuter
   o'shandan beri qayta yoqilmagan bo'lsa servis eski manzilni ushlaydi — 2026-06-11 taski).
4. Ilovadagi OFD sahifasi (lock ekrani → OFD) `GetUnsentsCount` — yuborilmagan cheklar soni
   o'sib borayotgan bo'lsa FM OFD'ga umuman ulanmayapti (sotuvlar FM'da navbatda turadi,
   vozvrat esa onlayn tekshiruv talab qiladi). `ResendUnsent` bilan sinab ko'rish.
5. Xom javob (kod/detal): `Documents\request_logs_of_invan_pos.txt` (24 soatlik oyna) va
   FiscalDriveAPI servisining o'z log'i.

## Qabul qilingan qarorlar
- Asosiy xato (65274) bizniki emas — kodga tegilmadi. Sabab: so'rov to'g'ri, modul OFD'ga ulana olmagan.
- Faqat log'dagi xodim tuzatildi (getter + try/catch). Sabab: real xato, kichik, xavfsiz; log
  yozish hech qachon exception tashlamasligi kerak (employees qutisi yopiq bo'lsa `null`).
- URL/status kod log'i o'zgartirilmadi — fiskal sotuv yo'li, faqat taklif sifatida qoldirildi.

## Ochiq savollar
- 65274: original chek OFD'ga hali yetib bormagani (FM navbatida) ham shu kodni beradimi yoki
  faqat tarmoq xatosi? FiscalDriveAPI hujjati/qo'llab-quvvatlash — do'kondagi `GetUnsentsCount`
  bilan aniqlanadi
- Vozvrat oxir-oqibat o'tdimi (keyinroq qayta urinilganmi)? — do'kondan

## Test / Verifikatsiya
- `flutter test test/log_repository_employee_test.dart` — tuzatishdan oldin 3/3 yiqildi, keyin 3/3 o'tdi
- `flutter analyze` (o'zgargan fayllar) — xato yo'q
- To'liq `flutter test` (b1fd08d + 4de89e6): 2038 o'tdi, 7 skip, 0 yiqildi (oldingi asos 2035 + 3 yangi)
