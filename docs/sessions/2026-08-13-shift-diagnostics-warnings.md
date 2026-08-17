# Task: Smena (ochish/yopish) diagnostikasi — tushunarli ogohlantirish va Telegram xabarlari

**Boshlangan:** 2026-08-13
**Holat:** in-progress — 1-bosqich (diagnostika) **relizga chiqdi**, 2-bosqich (sinxron) boshlanmagan
**Branch:** ayyubxon
**Reliz:** `1.1.2+120` (2026-08-17, commit `023ac8f`) — PROD backendga yuklandi

> **Keyingi sessiyada shu yerdan boshlang:** pastdagi `## Ildiz sabab` bo'limini
> o'qing (nima uchun bu muammolar chiqayotgani bir joyda tushuntirilgan), keyin
> `## Keyingi qadamlar` dagi **1-qadam** dan davom eting. Undan oldin
> `## Ochiq savollar` dagi qarorni foydalanuvchidan olish kerak.

## Maqsad
Smena bilan bog'liq har bir muammo (ketmagan cheklar, internet yo'q, server smenani ochiq
ko'rsatishi va h.k.) kassirga **aniq sabab** bilan aytilsin va Telegramga **tushunarli,
tuzilgan** xabar ketsin. Hozir kassir "Pos is open on the web" / "Невозможно закрыть смену"
kabi tushunarsiz matn ko'radi, Telegramga esa "openshift funksiyasi false qaytargan holat"
ketadi — sabab ham, holat ham ko'rinmaydi.

## Kontekst — 2026-08-13 16:26 hodisasi (Tiin Optom / Kassa 1a)
Log tahlili (`request_logs_of_invan_pos.txt`, 10:34–16:38):
- ~15:46–16:24 internet uzilgan (39 daq). Fiskal (localhost) ishlagan, server so'rovlari yo'q.
- 15:46:16 va 15:50:40 da 2 ta sotuv fiskallashgan, lekin `order_pos` ketmagan.
- ~16:22-16:23 kassir smenani yopgan → oflayn shox: lokal yopiq, serverga yuborilmagan
  (`closedCount=1`, `closedDate` set).
- 16:24:42 internet qaytdi → `NetworkSuccess` bir marta emit bo'ldi, lekin
  `_isBoxEmpty()` gate'i (ketmagan cheklar bor edi) tufayli smena-yopish retry'i **o'tkazib
  yuborildi** (app.dart:171).
- 16:25:55 ilova restart (internet ulangan holda) → `onStatusChange` boshqa emit qilmadi →
  retry umuman ishga tushmadi.
- Natija: serverda `Kassa 1a = open`, POS'da `shiftsOpened=false` → 15 marta smena ochishga
  urinish, hammasi `isReturn=null` → "Pos is open on the web".
- Butun logda birorta `POST api/v1/shift_pos` yo'q — yopish serverga hech qachon ketmagan.

## Scope
**Ichida:**
- Yangi `ShiftDiagnostics` servisi — holat snapshot'i, sabab kodlari, uz/ru xabarlar,
  tuzilgan Telegram hisoboti, takroriy xabarlarni bosish (dedupe).
- Smena yopishdan **oldin** ogohlantirish dialogi (internet yo'q / ketmagan cheklar).
- Smena ochish xatolarini sabab bo'yicha ajratish (server ochiq / web ochgan / kassa
  ro'yxatda yo'q / server javob bermadi).
- Serverga yetmagan yopishni qo'lda yuborish tugmasi (deadlock'dan chiqish yo'li).

**Tashqarisida (keyingi bosqich, alohida tasdiq bilan):**
- `_isBoxEmpty()` gate'ini olib tashlash (app.dart:171).
- Retry'ni startup'da ham ishga tushirish.
- Onlayn yopish muvaffaqiyatsiz bo'lganda `closedCount=1` qo'yish.
- `openShift()` da Hive smenasini serverdan javob olgandan keyin yaratish.

## Bajarilgan
- [x] Log tahlili va sabab zanjiri aniqlandi
  → Yuqoridagi "Kontekst" bo'limi
  → Sabab: 3 ta to'siq (isBoxEmpty gate, faqat status-o'zgarish trigger, rejected cheklar)
- [x] `ShiftDiagnostics` servisi — 13 ta sabab kodi, holat snapshot'i, uz/ru xabarlar,
  tuzilgan Telegram hisoboti, 5 daqiqalik dedupe
  → lib/changes/services/shift/shift_diagnostics.dart
  → Sabab: sabab kodlari bitta joyda bo'lsa, UI ham, Telegram ham bir xil matnni
    ishlatadi — ikki joyda ikki xil xabar bo'lib qolmaydi
- [x] Ogohlantirish/xabar dialogi (sabab + tavsiya + tuzatish tugmalari)
  → lib/widgets/shift_warning_dialog.dart
- [x] Yopishdan oldin tekshiruv (internet yo'q / ketmagan chek / rad etilgan chek /
  yuborilmagan yopish / POS aktivlashmagan)
  → lib/changes/providers/open_shift_provider.dart:44 (`onShiftCloseButtonPressed`)
  → `_confirmCloseWithWarnings` — bloklamaydi, lekin "Baribir yopish" tanlansa
    Telegramga to'liq kontekst yoziladi
- [x] Yopishdan keyingi holat 3 ga ajratildi: server tasdiqlamadi / serverga yetmagan
  yopish navbatda / hammasi joyida
  → lib/changes/providers/open_shift_provider.dart (`closeShift`)
- [x] `getCurrentHiveShift()!` null bo'lganda qizil ekran o'rniga tushunarli xabar
  → open_shift_provider.dart `closeShift` try/catch + null guard
- [x] Ochish xatolari sabab bo'yicha ajratildi (server ochiq / web ochgan / kassa
  ro'yxatda yo'q / POS aktivlashmagan / server javob bermadi)
  → shift_singleton_4.dart `openShift` — sikl `firstWhere` mantiqiga o'tkazildi,
    natijalar (true/false/null) o'zgarmadi, faqat sabab aniqlanadigan bo'ldi
  → Eski "02319-023-0123" va "111111" statusli loglar olib tashlandi
- [x] "Yopishni yuborish" tugmasi — serverga yetmagan yopishni qo'lda yuborish
  → open_shift_provider.dart `sendPendingCloseToServer`
  → Sabab: 2026-08-13 da deadlock'dan chiqishning **hech qanday** yo'li yo'q edi
- [x] Rad etilgan cheklar smena yopishda ogohlantirilmaydi (kassir tuzata olmaydi)
  → shift_diagnostics.dart `closeWarnings()`
- [x] **Tarmoq xatosi endi `rejected` deb belgilanmaydi**
  → lib/features/checks/features/checks_app_bar/bloc/usr_bloc.dart:103
  → Oldin: `statusCode != 201` bo'lsa (timeout -1, ulanish xatosi -2 ham) butun
    paket `rejected=true` bo'lardi va `_find10()` (faqat rejected=false oladi)
    ularni boshqa hech qachon ko'rmasdi — internet tiklansa ham o'zi ketmasdi.
  → Endi: faqat `statusCode >= 400` (server javob bergan xato) `rejected` qiladi.
    Tarmoq xatosida chek navbatda qoladi va keyingi triggerda o'zi yuboriladi.
  → 409 ataylab tegilmadi (avvalgidek `rejected`) — guruh so'rovida 409 kimga
    tegishli ekani noaniq, alohida hal qilinadi.
- [x] **`ShiftSyncQueue` — smena navbati bitta joyga yig'ildi**
  → lib/changes/services/shift/shift_sync_queue.dart (yangi)
  → Ilgari bir xil mantiq app.dart va usr_bloc.dart da nusxalangan edi, ikkalasida
    ham ikkita xato bor edi:
    (a) `_isBoxEmpty()` — ketmagan chek bo'lsa smena ham yuborilmasdi;
    (b) so'rov natijasi tekshirilmasdan navbat tozalanardi — server javob
        bermasa ham `closedDate=''` bo'lib, yopish BUTUNLAY yo'qolardi.
  → Endi navbat faqat server 200/201 qaytargandan keyin tozalanadi, aks holda
    saqlanib qoladi va Telegramga bir marta (dedupe) xabar ketadi.
- [x] `_isBoxEmpty()` gate'i olib tashlandi
  → app.dart:171 → `ShiftSyncQueue.flush(reason: 'network-success')`
  → `_isBoxEmpty()` metodi va keraksiz importlar o'chirildi
- [x] usr_bloc.dart dagi nusxa ham `ShiftSyncQueue.flush(...)` ga almashtirildi
- [x] **Startup trigger qo'shildi** (ro'yxatdagi 2-band)
  → wrapper.dart:107 `unawaited(ShiftSyncQueue.flush(reason: 'startup'))`
  → Sabab: `NetworkBloc` faqat internet holati O'ZGARGANDA emit qiladi. Ilova
    internet ulangan holda ochilsa hech qanday trigger yo'q edi — 13-avgustda
    16:25:55 dagi restartdan keyin aynan shu bo'lgan.
- [x] `flutter analyze lib` → 0 error

### (2026-08-17) Windows sinovida topilgan bug: "Smena yopildi" deb yolg'on xabar

Sinov: kassa oflayn → smena OCHILDI → 1 ta sotuv → yopish. Ogohlantirishlar
to'g'ri chiqdi ("Internet yo'q" + "Ketmagan cheklar"), "Baribir yopish" bosildi
→ **"Smena yopildi, lekin e'tibor bering / Server smenani yopmadi"** chiqdi,
"Tushunarli" bosilgach smena **hali ham ochiq** turgan edi.

Sabab zanjiri:
1. `ShiftSingleton4.closeShift` oflayn shoxi `closedCount == 0 && openedCount == 0`
   ni talab qiladi. Smena oflayn ochilgani uchun `openedCount == 1` edi → shart
   bajarilmadi → `shiftsOpened` `true` bo'lib qoldi, smena yopilmadi.
2. Lekin `closeShift` Hive yozuviga `isClosed=true` va `closedDate` ni shu
   shartdan **oldin** yozib bo'lgan edi → Hive'da "yopiq", POS'da "ochiq".
3. UI buni `serverCloseFailed` deb ko'rsatdi — holbuki serverga umuman murojaat
   qilinmagan (internet yo'q).
4. Dialog sarlavhasi `infoOnly` bo'lsa **har doim** "Smena yopildi, lekin
   e'tibor bering" edi — natijadan qat'i nazar.

- [x] Yopish **boshlanishidan oldin** bloklovchi tekshiruv
  → `ShiftSnapshot.openedCount` / `closedCount` / `canCloseOffline` qo'shildi
    (`ShiftSingleton4` dagi shartning aynan nusxasi — bitta joydan o'qilsin)
  → `ShiftDiagnostics.blockingCloseIssue()` — shift_diagnostics.dart
  → open_shift_provider.dart `_confirmCloseWithWarnings` 1-qadam: bloklovchi
    bo'lsa hech narsa yozilmaydi, dialog chiqadi, `false` qaytadi
  → Sabab: eng muhimi Hive'ga `isClosed=true` yozilib qolmasligi

- [x] 2 ta yangi sabab kodi (aniq sabab + nima qilish kerak)
  → `offlineCloseBlockedByPendingOpen` — "Smena yopilmadi — ochilishi serverga
    yetmagan" (aynan sinovdagi holat)
  → `offlineCloseBlockedByPendingClose` — "Smena yopilmadi — oldingi yopish
    navbatda"
  → Matn formati: `NIMA BO'LDI / SABAB / NIMA QILISH KERAK` + "sotuvlar va
    cheklar yo'qolmaydi" kafolati (kassir birinchi navbatda shundan qo'rqadi)

- [x] Dialog sarlavhasi natijaga bog'landi
  → `showShiftWarningDialog(succeeded: ...)` + `_headerText()`
  → shift_warning_dialog.dart
  → `infoOnly && !succeeded` → **"Smena yopilmadi"**; `succeeded` → "Smena
    yopildi, lekin e'tibor bering"

- [x] `serverCloseFailed` matni navbat holatiga qarab ikkiga bo'lindi
  → `closedCount == 1 && closedDate != ''` bo'lsagina "avtomatik qayta
    yuboriladi" deyiladi; aks holda "navbatga tushmadi — qo'lda yuboring"
  → Sabab: `ShiftSyncQueue` faqat `closedCount == 1` ni ko'radi. Ilgari har
    doim "qayta yuboriladi" deb va'da berilardi — kassir kutardi, hech narsa
    ketmasdi.

- [x] `noInternet` matnidagi noto'g'ri gap tuzatildi
  → "Internet tiklanmaguncha bu kassada yangi smena ochilmaydi" — **noto'g'ri**,
    oflayn ochish ishlaydi (`openedCount == 0` bo'lsa). To'g'ri gap: yopish
    serverga yetmaguncha keyingi smenani internetsiz YOPIB bo'lmaydi.

- [x] Savat/RuleCash faqat smena haqiqatan yopilganda tozalanadi
  → `closeShift` endi `Future<bool>` qaytaradi
  → open_shift_provider.dart `onShiftCloseButtonPressed`
  → Sabab: ilgari yopish bajarilmagan holatda ham savat tozalanardi — smena
    ochiq qolib, ma'lumot o'chib ketardi

- [x] Internet bor bo'lsa, yopishdan oldin navbat yuboriladi
  → `ShiftSyncQueue.flush(reason: 'before-close')` + snapshot qayta olinadi
  → Sabab: serverda ochilmagan smenani yopishga urinish server tomonidan rad
    etiladi. Endi avval ochish yetkaziladi, keyin yopish boshlanadi. Bu
    "oflayn ochilgan smena" holatidan internet kelganda o'z-o'zidan chiqaradi.

- [x] `_printReport` ichidagi ma'nosiz `try/catch` olib tashlandi (hech qachon
  throw qilmaydigan tayinlash edi, lekin `return` bilan `pendingCloseNotSynced`
  tekshiruvini o'tkazib yuborardi)

- [x] `flutter analyze lib` → 0 error

## Ildiz sabab (2026-08-17 tahlili — bularning HAMMASI bitta kasallik)

**Smena holati ikki joyda saqlanadi va ikkalasi bir-biriga mos kelmaydi:**

| Manba | Nima saqlaydi |
|---|---|
| Hive `ShiftModelHive` | `isClosed`, `isUploaded`, `openingTime`, `closingTime` — **haqiqiy holat** |
| Pref (4 ta qiymat) | `openedDate`, `openedCount`, `closedDate`, `closedCount` — **navbat holati** |

Ikkinchisi birinchisining qo'lda yuritiladigan nusxasi va **noto'g'ri paytda
yoziladi**:

```dart
// shift_singleton_4.dart closeShift()
closedDate = hozir;                   // ← natija MA'LUM BO'LMASDAN oldin
...
if (shart) { closedCount = 1; }       // ← faqat shart bajarilsa
```

Ya'ni "yopish navbatdami?" degan savolga javob beradigan yagona bayroq
(`closedCount`) muvaffaqiyatsizlik yo'llarida **yozilmaydi**, yonidagi
`closedDate` esa allaqachon yozilgan. **Yetim holat** shundan tug'iladi:
`closedDate` bor, `closedCount = 0` → `ShiftSyncQueue.hasPendingClose` `false`
qaytaradi → yopish so'rovi internet bo'lsa ham **hech qachon ketmaydi**.

Uchta alomat — bitta kasallik:

| Alomat | Sabab |
|---|---|
| "Smena yopildi" deyildi, yopilmadi | Hive `isClosed=true`, Pref `shiftsOpened=true` |
| Internet yondi, request ketmadi | `closedDate` bor, `closedCount=0` → navbat "bo'sh" |
| Oflayn 2-marta yopib bo'lmaydi | Hisoblagich `0/1` — bitta smena sig'adi, tarix emas |

E'tibor: `ShiftModelHive` da **`isUploaded` bayrog'i allaqachon bor** — to'g'ri
dizayn loyihada mavjud, lekin hech kim ishlatmaydi. Uning o'rniga Pref'da
parallel hisoblagichlar yuritilgan.

**Diagnostika bosqichi (relizga chiqqan) bu kasallikni davolamadi** — u faqat
kassirga rost gapirishni ta'minladi. Davolash 2-bosqichda.

---

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] **0. Windows'da 1.1.2+120 ni sinash** (quyidagi "Test" bo'limi)
      Bu qadamsiz keyingilariga o'tmaslik kerak — diagnostika xabarlari to'g'ri
      chiqayotganiga ishonch kerak.

### 1-qadam — arzon va xavfsiz (avval shu)

- [ ] **`ShiftSyncQueue.flush` qarorini log qilsin**
      Hozir `if (!hasPending) return;` — jimgina chiqadi, hech qayerda iz yo'q.
      2026-08-17 da aynan shu sababli "nega request ketmadi?" degan savolga
      taxmin qilib javob berishga to'g'ri keldi.
      → `shift_sync_queue.dart:48`
      → Yozilsin: `reason`, `closedDate/closedCount`, `openedDate/openedCount`,
        va qaror ("navbat bo'sh", "yuborildi: 200", "saqlandi: -1")

- [ ] **Startup self-heal — yetim `closedDate` ni tozalash/tiklash**
      Hozir foydalanuvchining kassasida shunday yetim holat **turibdi** va u
      `pendingCloseNotSynced` ogohlantirishini abadiy chiqaraveradi.
      Hakam — **Hive** (Pref emas):
      - Hive'dagi joriy smena `isClosed == true` → `closedCount = 1` qo'y
        (navbatga qaytar)
      - aks holda → `closedDate = ''` (yopish bo'lmagan, iz yolg'on)

- [ ] **Onlayn yopish muvaffaqiyatsiz bo'lganda lokal yopilsin + navbatga tushsin**
      → `shift_singleton_4.dart:256-263`
      → Hozir: server 200 qaytarmasa `closedDate` yoziladi-yu `closedCount` 0
        qoladi, `shiftsOpened` `true` qoladi → Hive'da yopiq, POS'da ochiq.
      → **Tavsiya:** oflayn shox bilan bir xil qilinsin — `shiftsOpened=false`,
        `closedCount=1`. Sabab: kassir yopdi, Z-hisobot chiqdi, Hive yopiq deydi.
        Server tasdig'i yopishning **sharti bo'lmasligi kerak**, chunki oflayn
        rejimda baribir shart emas.
      → ⚠️ Bu **foydalanuvchi qarorini talab qiladi** — `## Ochiq savollar` ga qarang.
      → Chastotasi yuqori (server 500 / timeout tez-tez bo'ladi), shuning uchun
        1-qadamda.

### 2-qadam — o'lchashdan keyin qaror qilinadi

- [ ] **Hive-asosli navbat (katta refaktor) — HOZIRCHA QILINMAYDI**
      `ShiftSyncQueue` Pref'ni emas, **smenalar ro'yxatini** o'qisin:
      ```
      Hive smenalarini vaqt bo'yicha tartibla
        ochilishi yuborilmagan  → POST open  (opened_at = openingTime)
        yopilgan-u yuborilmagan → POST close (closed_at = closingTime)
        200 kelsa → isUploaded = true
      ```
      Bitta o'zgarish bilan 4 ta muammo yopiladi: yetim holat yo'q, cheksiz
      oflayn sikl, tartib o'z-o'zidan to'g'ri, `openedCount == 0` sun'iy to'sig'i
      keraksiz bo'ladi.

      **Nega hozir emas:** eng ko'p uchraydigan holat (smena onlayn ochilgan,
      yopishda internet uzuq) **allaqachon ishlaydi**. Refaktor faqat kam
      uchraydigan holatlarni hal qiladi — to'lov yo'liga yaqin joyda katta
      o'zgarish, xavf/foyda nisbati yomon.

      **Qachon qilinadi — o'lchov bilan hal qilinadi.** Diagnostika endi har
      holatni kod bilan Telegramga yozadi. 2-3 hafta ishlatilgach sanaladi:
      - `offlineCloseBlockedByPendingOpen` **ko'p kelsa** → do'konlarda internet
        uzoq uziladi, refaktor kerak → qilinadi
      - **kelmasa yoki 1-2 marta kelsa** → refaktor kerak emas, yopiladi

      **O'lchash sanasi:** 2026-09-07 dan keyin Telegram kanalidan sanash.

### Alohida, kichikroq (istalgan vaqtda)

- [ ] Ochish POST'i muvaffaqiyatsiz bo'lganda `openedDate` tozalanmasin
      (`shift_singleton_4.dart:226-228` — POST natijasi kutilmasdan tozalanadi,
      ya'ni ochish ham yo'lda yo'qolishi mumkin)
- [ ] `openShift()` Hive smenasini serverdan javob olgandan keyin yaratsin
- [ ] `usr_bloc.dart:79` — `soldItemList` bo'sh cheklar navbatda mangu qoladi
      (`_find10()` ularni qaytaradi, `where` filtri chiqarib tashlaydi → sikl
      hech qachon "hammasi ketdi" holatiga yetmaydi → `receipts-uploaded`
      trigger'i ishlamaydi)
- [ ] 409 javobi guruh so'rovida qanday talqin qilinishi (hozir `rejected`)
- [ ] **Navbat tartibi kafolatlanmagan** — `flush` uchta trigger'dan chaqiriladi,
      faqat `receipts-uploaded` da cheklar smenadan oldin ketishi kafolatlangan.
      `startup` (`unawaited`, parallel) va `network-success` (u yerda `order_pos`
      umuman yuborilmaydi) da yopish cheklardan **oldin** yetib borishi mumkin.
      Backend'dan javob kerak — `## Ochiq savollar`.

## Qabul qilingan qarorlar
- **Rad etilgan (server qabul qilmagan) cheklar smena yopishda ogohlantirilmaydi.**
  Sabab: kassir ularni yopish paytida tuzata olmaydi va ular smenaning serverga
  yetishiga to'sqinlik qilmaydi — ogohlantirish shovqin bo'lardi. Ular Telegram
  hisobotida (`Rad etilgan cheklar: N`) va Sozlamalar → rad etilgan cheklar
  bo'limida ko'rinadi.
  → shift_diagnostics.dart `closeWarnings()`
  → BOG'LIQLIK: bu qaror `rejected` bayrog'i **haqiqatan** "server rad etdi"
    degani bo'lishini talab qiladi. Hozir `usr_bloc.dart:84` timeout/tarmoq
    xatosini ham `rejected=true` qilib qo'yadi — shu tuzatilmaguncha tarmoq
    tufayli ketmagan cheklar yopishda jim qoladi.
- Telegram xabari faqat o'zbekcha (texnik kanal), UI xabarlari uz/ru — `loc.ha` idiomasi
  orqali (ARB fayllarni qayta generatsiya qilmaslik uchun).
- Ogohlantirishlar **bloklamaydi** — kassir "Baribir yopish" deb davom eta oladi, lekin
  bu holat Telegramga to'liq kontekst bilan yoziladi.
  → ISTISNO (2026-08-17): `blockingCloseIssue()` qaytargan holatlar **bloklaydi**.
    Sabab: bu yerda "davom etish" degan variant yo'q — kod baribir smenani
    yopmaydi, faqat Hive'ni nomuvofiq holatga keltiradi. Kassirga tanlov berish
    yolg'on bo'lardi.
- **Dialog sarlavhasi amalning haqiqiy natijasini aytishi shart.** "Smena
  yopildi" deb yozib, aslida yopmaslik — eng qimmat xato turi: kassir ishonib
  ketadi va muammo keyinroq, tushuntirib bo'lmaydigan holatda chiqadi.

## Ochiq savollar

1. **[FOYDALANUVCHI QARORI KERAK — 1-qadam shunga bog'liq]**
   Onlayn yopishda server 200 qaytarmasa, smena **lokal yopilsinmi**?
   - **Ha** (tavsiya): `shiftsOpened=false` + `closedCount=1` → Hive bilan mos,
     navbatga tushadi, kassir ishini davom ettira oladi
   - **Yo'q** (hozirgi holat): POS "ochiq" qoladi, Hive "yopiq" — ziddiyat,
     kassir qayta urinishi kerak

2. **[BACKEND JAVOBI KERAK]**
   `POST shift_pos` (yopish) ketgandan keyin o'sha smenaga tegishli `order_pos`
   chek kelsa — server uni qabul qiladimi va smena hisobotiga qo'shadimi?
   - Qabul qilsa → navbat tartibi muammosi yo'q, hech narsa qilinmaydi
   - Rad etsa → `flush` ichida chegaralangan tartib kerak (avval cheklar, N
     urinishdan keyin baribir yopish — **cheksiz to'siq emas**)

3. **[O'LCHOVDAN KEYIN]**
   Hive-asosli navbat refaktori kerakmi? — 2026-09-07 dan keyin Telegram
   kanalidagi `offlineCloseBlockedByPendingOpen` sonига qarab hal qilinadi.

## Test / Verifikatsiya
- [ ] Internetni o'chirib smena yopish → ogohlantirish chiqishi
- [ ] Ketmagan chek bor holda yopish → "N ta chek ketmagan" xabari
- [ ] Serverda ochiq smena bilan ochishga urinish → sabab + "Yopishni yuborish" tugmasi
- [ ] Telegramga ketgan xabar o'qilishi
- [ ] **(2026-08-17 bug'i)** Oflayn: smena OCH → sotuv → yopishga urin
      → "Smena yopilmadi — ochilishi serverga yetmagan" chiqsin
      → "Tushunarli" bosilgach smena OCHIQ qolsin va savat tozalanmasin
      → Hive yozuvi `isClosed` bo'lib qolmasin (yopish umuman boshlanmaydi)
- [ ] Shundan keyin internetni ulab yopish → ochish avtomatik yuborilib
      (`before-close`), smena normal yopilsin
- [ ] Onlayn ochilgan smenani oflayn yopish → yopilsin + "yopilish navbatda"
      xabari, sarlavha "Smena yopildi, lekin e'tibor bering" bo'lsin
