# Task: Ketmagan cheklarni startup'da avto-yuborish + UI eskirishi bug'i

**Boshlangan:** 2026-07-03
**Holat:** in-progress (kod tayyor, Windows test kutilmoqda)
**Branch:** ayyubxon

## Maqsad
Internet bo'lmagan holatda lokalda saqlanib qolgan ("ketmagan") cheklar
ilova qayta ochilganda orqa fonda avtomatik serverga yuborilsin. Qo'shimcha:
chek orqa fonda ketgach cheklar ro'yxatidagi "ketmagan" (`!`) belgisi
avtomatik yo'qolsin (UI eskirishi bug'i).

## Scope
- `lib/app/wrapper/wrapper.dart` — startup avto-flush trigger
- `lib/features/checks/features/checks_list/*` — UI jonli yangilanishi
- Scope'dan tashqari: rad etilgan (`rejected=true`) cheklarni avto-qayta urinish
  (qasddan qoldirildi — ular odatda yana o'sha xatoni beradi)

## Muhim kontekst (kod bo'yicha)

### Ketmagan cheklar mexanizmi
- Cheklar ObjectBox'da `ReceiptModel4`, ikki bayroq: `uploaded`, `rejected`.
- "Jo'natilmagan" = `uploaded == false`. Ikki toifa:
  - `rejected=false` — internet yo'q edi / urinilmagan. Yuboradi: `UsrBloc._send`
    (10 tadan guruhlab, `receiptCreateGroup`). usr_bloc.dart:43
  - `rejected=true` — server 201'dan boshqa status qaytargan (validatsiya/backend
    xatosi). Yuboradi: `UsrBloc._sendSpecial` (bittalab, refresh tugmasi). usr_bloc.dart:159
- `rejected=true` FAQAT usr_bloc.dart:89 da (statusCode != 201) o'rnatiladi.
  Yangi chek doim `rejected=false` yaratiladi (ordering_provider_4.dart:2965, 3209).
- `UsrBloc` global (app.dart:156), butun ilova davomida tirik.

### Avto-yuborish triggerlari (oldindan mavjud edi)
- Wrapper ObjectBox listener (wrapper.dart:59) — savat o'zgarganda (yangi sotuv) → UsrSendEvent
- Wrapper network listener (wrapper.dart:68) — internet ulanganda → UsrSendEvent
- **Bo'shliq:** ilova qayta ochilganda internet allaqachon ulangan bo'lsa —
  hech qanday trigger yo'q edi. ObjectBox `.watch()` (triggerImmediately=false)
  startup'da emit qilmaydi; network listener faqat status o'zgarsa ishlaydi.

### Yuborish rejimi: GURUH, bittalab EMAS (muhim aniqlik)
- `_send` (asosiy avto-yuborish) `_find10()` bilan 10 tagacha chekni oladi va
  HAMMASINI bitta POST'ga solib yuboradi: `{"order": [chek1, chek2, ...]}`.
  Ya'ni 6 sotuv = Alice'da 1 ta `POST /api/v1/order_pos` (order array ichida 6 ta).
  10 tadan ko'p bo'lsa loop bilan keyingi 10 tani yana bitta request'da yuboradi.
- Chek raqami body'da `external_id` (masalan "DH74"). order UUID = `id`.
  qty = `items[].value`, to'lov = `pays.pays[]`.
- Guruh kamchiligi: guruhdagi BITTA chek xato bo'lsa server butun guruhga
  201'dan boshqa status qaytaradi → o'sha 10 tasi ham `rejected=true` bo'ladi.
- Bittalab faqat `_sendSpecial` (refresh tugmasi / rad etilgan) da:
  `receiptCreateGroup([receiptList[i]])` loop ichida.

### rejected=true cheklar qayta yuborilishi (aniqlik)
- Avto-yuboruvchilar (`_send`: yangi sotuv, reconnect, startup flush) rejected'ga
  TEGMAYDI (`_find10` filtri `rejected=false`).
- rejected'ni faqat `_sendSpecial` yuboradi. Triggerlari:
  1. Cheklar sahifasidagi refresh tugmasi (checks_app_bar.dart:131) — qo'lda, ishonchli
  2. Sozlamalar → "Rad etilgan cheklar" dialogi (rejected_receipts.dart:192) — qo'lda
  3. Ilova qayta ochilganda `if (isFirstTime)` (wrapper.dart:127) — ISHONCHSIZ:
     app.dart:75 `_checkFirstTime` bir vaqtda isFirstTime=false qiladi (race);
     crash/majburiy yopilishda onWindowClose ishlamaydi → isFirstTime=false qoladi.
- Qaror: rejected retry ataylab qo'lda qoldirildi (foydalanuvchi A variantni tanladi).

### UI eskirishi bug'i sababi
- Cheklar ro'yxati UI'si `CheckFBloc.checksList`'dan chizadi.
- Bu maydon FAQAT `CheckFDateChangedEvent` (Wrapper listeneridan) orqali yangilanadi.
- Wrapper splash bo'lib startup'dan keyin dispose bo'ladi → listener ishonchsiz.
- Shu sabab orqa fonda `uploaded=false→true` bo'lsa, ro'yxat ishonchli
  yangilanmay `(!)` qolib ketardi.

## Bajarilgan
- [x] Startup avto-flush qo'shildi (faqat `rejected=false`, faqat startup, timer'siz)
  → lib/app/wrapper/wrapper.dart:90 (`_flushUnsentReceiptsOnStartup()` chaqiruvi)
  → lib/app/wrapper/wrapper.dart (metod: `uploaded=false && rejected=false` sanaydi,
     >0 bo'lsa `UsrSendEvent("Wrapper Startup", pending)`)
  → Sabab: internet tekshiruvi UsrBloc._send ichida (real ping), internet yo'q bo'lsa
     xavfsiz to'xtaydi; internet kelsa network listener qayta uradi.
- [x] UI jonli yangilanishi — cheklar sahifasi ObjectBox'ni bevosita kuzatadi
  → check_f_event.dart: `CheckFRefreshEvent(data, isSearching)` qo'shildi
  → check_f_bloc.dart: `_refresh` handler — ro'yxatni yangilaydi, tanlangan chekni
     SAQLAYDI (selected=0 ga tashlamaydi), qidiruv faol bo'lsa tegmaydi
  → checks_list.dart: `watch(triggerImmediately: true)` subscription initState'da,
     dispose'da cancel. Kirishda + har o'zgarishda ro'yxatni yangilaydi.
  → Sabab: Wrapper'ning ishonchsiz listeneriga bog'lanmaslik uchun sahifa
     lifecycle'iga bog'langan mustaqil watch.
- [x] Alice tekshiruvi — qo'shimcha kod SHART EMAS. receiptCreateGroup →
     ApiProvider.postResponse/putResponse → alice.onHttpResponse (api_provider.dart:103,193,238).
     Barcha avto-yuborishlar bir xil yo'ldan o'tadi, allaqachon Alice'da ko'rinadi.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da test: internet o'chiq → sotuv → ilova yop → internet yoq → qayta och
      → cheklar startup'da o'zi ketishi kerak (Cheklar sahifasiga kirmasdan ham).
- [ ] Test: cheklar sahifasida turganda orqa fon yuborilsa `(!)` o'zi yo'qolishi.
- [ ] Test: qidiruv faol bo'lganda orqa fon yangilanishi qidiruvni buzmasligi.
- [ ] Test tasdiqlansa → Holat: done, archive'ga ko'chirish.

## Qabul qilingan qarorlar
- Faqat startup tekshirish (periodik Timer YO'Q) — foydalanuvchi tanladi. Sabab:
  mavjud network/objectbox listenerlar reconnect va yangi sotuvni allaqachon qoplaydi.
- Faqat `rejected=false` avto-yuboriladi — foydalanuvchi tanladi (A variant). Sabab:
  `rejected=true` cheklar qayta yuborishda odatda yana o'sha xatoni beradi.
- UI refresh Wrapper'dan EMAS, cheklar sahifasining o'z watch'idan — ishonchlilik uchun.

## Ochiq savollar
- Yo'q.

## Test / Verifikatsiya
- `flutter analyze` o'zgargan fayllarda: yangi xato yo'q (faqat oldindan mavjud
  info/warning: BuildContext async, deprecated dialogBackgroundColor, unused `o`).
- Real Windows test kutilmoqda (yuqoridagi qadamlar).
