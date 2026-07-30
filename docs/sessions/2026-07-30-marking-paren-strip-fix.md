# Task: Markirovka qavs tozalashda 01 AI o'chib ketishi (KM buzilishi)

**Boshlangan:** 2026-07-30
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Skanerdan `(01)04780069000505(21)serial(93)crypto` ko'rinishida kelgan GS1 markirovka
kodini tozalashda eski regex `\(\d{2}\)` qavs bilan birga `01`/`21`/`93` **raqamini ham**
o'chirib yuborardi. Natijada KM `04...` (GTIN) dan boshlanib, buzuq formatda saqlanardi va
sotuv/soliq/OFD ga shu buzuq holda ketardi. Tuzatildi: faqat qavs olinadi, raqam saqlanadi;
`93` va undan keyingi kripto qism esa hech qayerga yuborilmaydi.

## Muammoning kelib chiqishi (dalil)
Bir sotuvda 60 ta markirovka bo'lib, 2 tasi `01...` dan, 58 tasi `04...` dan boshlangan
edi. Tahlil: 60 ta yozuv, lekin faqat **58 ta noyob** kod — 2 tasi ikki xil formatda
takrorlangan (idx 0/33 va 1/35 bir xil serial). Foydalanuvchi skrindan ko'rsatdi:
skaner `(01)...(21)...(93)...` beradi, kod esa `(01)` ni butunlay o'chirib tashlayapti.

Sinov: `"(01)04780069000505(21)7%G'2dE6p)QWf(93)DrFn"`
- Eski `\(\d{2,3}\)` → `047800690005057%G'2dE6p)QWfDrFn` (01 YO'Q, buzuq)
- Yangi → `0104780069000505217%G'2dE6p)QWf` (01 joyida, 93+crypto yo'q)

## Scope
- `lib/changes/providers/ordering_provider_4.dart` — `_markirovka` (skan vaqti), `cleanMarkForFiscal` (to'lov vaqti)
- `lib/changes/services/local_selling_service.dart` — `cleanMarkForFiscal` (nusxa; hozir hech qayerdan chaqirilmaydi, izchillik uchun tuzatildi)
- Scope dan tashqari: receipt_singleton_4 (faqat `\n` bilan birlashtiradi, transform yo'q)

## Oqim (tasdiqlangan)
1. Skan → `marking()` dialog `onSubmitted` → `_markirovka(v)` (line ~1478/1488)
2. `_markingCheck` → `item.mark = v` + soliq validatsiya `kmIds:[v]` (line ~1753)
3. To'lov → `cleanMarkForFiscal(item.mark)` har item uchun (line 3339 / 3631)
4. `ReceiptSingleton4` bir mahsulot marklarini `\n` bilan birlashtiradi (receipt_singleton_4.dart:202)
5. `toJson` → `marking_names = mark.split('\n')` (receipt_model_4.dart:489) → backend + OFD

## Bajarilgan
- [x] Muammo tasdiqlandi: `\(\d{2}\)` regexi (01) ni raqami bilan o'chiradi
  → ordering_provider_4.dart:1518 (eski), local_selling_service.dart / :3493 (eski)
  → Sabab: qavs olinishi kerak edi, lekin ichidagi AI raqami (01/21/93) ham ketardi
- [x] `_markirovka` tuzatildi — ordering_provider_4.dart:1516 atrofida
  → (93)/`<GS>93` kripto tail kesiladi, keyin `(NN)`→`NN` (raqam saqlanadi)
  → Sabab: 93 skan vaqtida kesilsa, soliq validatsiyasiga ham ketmaydi ("soliqqa hech narsa")
- [x] `cleanMarkForFiscal` (ordering_provider_4.dart:3488) va (local_selling_service.dart:52) tuzatildi
  → replaceAllMapped `\((\d{2,3})\)` → group(1); (93)/GS kesish; eski `(?=93)` fallback qoldi
  → Sabab: foydalanuvchi "93-kesish qolsin, olib tashlamagin" dedi
- [x] Pipeline simulyatsiya: bracketed 1/2/3, GS-separator, already-01 — hammasi `01...21...serial`, 93 yo'q
- [x] **Xavfli `(?=93)` fallback OLIB TASHLANDI** (ikkala cleanMarkForFiscal)
  → ordering_provider_4.dart:3496, local_selling_service.dart:52
  → Sabab: serial ichida tasodifiy "93" bo'lsa (masalan "93QWERTYuiop1") fallback
    serialni kesib yuborardi (test bilan isbotlandi: "...2193QW..." -> "...21").
    _markirovka allaqachon kriptoni ANIQ marker ((93)/<GS>) bilan kesadi — fallback keraksiz.
- [x] **DUAL-logika `_markirovka`ga qo'shildi** (foydalanuvchi talabi) — ordering_provider_4.dart:1513
  → MARKER bor ((93)/<GS>93): aniq kesish, serialdagi 93 SAQLANADI
  → MARKER yo'q (yalang'och): ESKI logika `(01\d{14}21.*?)(?=93)` — birinchi 93 gacha,
    serialda 93 bo'lsa ham kesiladi (markersiz kodda chegarani aniqlashning yo'li yo'q)
  → Qaror faqat `_markirovka`da: marker ko'rinadigan yagona joy (skan vaqti). `cleanMarkForFiscal`
    marker olib tashlangan qiymat oladi, "marker edimi?"ni bilolmaydi → unga fallback QO'YILMAYDI
    (aks holda marker+serial-93 holatini buzardi)
- [x] Repoda doimiy regressiya-test: test/marking_paren_strip_test.dart (17 test, hammasi o'tdi)
  → Haqiqiy `cleanMarkForFiscal` + `_markirovka` dual-logika spec (marker/markersiz)
- [x] `flutter analyze` — 0 error; dual_test.dart 9/0; `flutter test` suite — o'tdi (boilerplate widget_test avvaldan yiqiladi)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] **Windows'da jonli test**: yangi markirovkali mahsulot skan qilib, chek/order_pos'da
      KM `01...21...` dan boshlanishini va 93/crypto YO'Qligini tekshirish
- [ ] **Soliq ONKM validatsiyasi test** (eng muhim risk): `kmIds:[v]` endi crypto'siz ketadi.
      Agar validatsiya crypto talab qilsa, faqat validatsiya chaqiruvi uchun to'liq kodni saqlash kerak bo'lishi mumkin.
      (Eslatma: `Pref 'validation_onkm'` false bo'lsa validatsiya o'tkazib yuboriladi — line ~1697)
- [ ] OFD fiskal chek KM ni to'g'ri qabul qilishini tasdiqlash

## Qabul qilingan qarorlar
- `93` va keyingi kripto qism **skan vaqtida** (`_markirovka`) kesiladi — shunda
  soliq/sotuv/OFD hech qayerga bormaydi. Sabab: foydalanuvchi talabi.
- **DUAL-logika (foydalanuvchi talabi):**
  - MARKER bor (`(93)`/`<GS>93`) → aniq marker bo'yicha kesish; serialdagi tasodifiy
    `93` SAQLANADI (u yalang'och, marker "kiyimi" yo'q).
  - MARKER yo'q (yalang'och kod) → ESKI logika `(01\d{14}21.*?)(?=93)`: birinchi `93`
    gacha. Serialda `93` bo'lsa ham kesiladi — markersiz kodda chegarani boshqacha
    aniqlab bo'lmaydi (foydalanuvchi buni ataylab qabul qildi).
- Dual-logika **faqat `_markirovka`da** — chunki marker faqat skan vaqti ko'rinadi.
  `cleanMarkForFiscal` marker olib tashlangan qiymat oladi → unga `(?=93)` fallback
  qo'yilMAYDI (aks holda marker+serial-93 holatini buzardi). U faqat marker-cut + tozalash.
- Eski buzuq `04...` forma (AIsiz) idempotent tiklanmaydi — faqat eski yozuvlar;
  yangi skanlar doim to'g'ri keladi.

## Ochiq savollar
- Soliq ONKM validatsiyasi crypto'siz KM ni qabul qiladimi? — Windows testda aniqlanadi
  (agar buzilsa: faqat validatsiya chaqiruvi uchun to'liq kodni saqlash — oson yechim)
- Agar markirovkada `(91)`/`(92)` kripto qismlari `(93)` dan oldin kelsa, ular hozir
  KI ichida qolib ketadi (skrindagi kodlarda yo'q; kelib chiqsa alohida ko'riladi)

## Test / Verifikatsiya
- **Repo regressiya-test**: test/marking_paren_strip_test.dart — 11 test, HAMMASI O'TDI
  (bracketed, GS, serial-ichida-93, idempotent, join/split invariantlari)
- Standalone: scratchpad/full_test.dart — 119 assert, 0 yiqilish
- flutter analyze: 0 error
- flutter test (butun suite): 53 o'tdi (1 boilerplate widget_test yiqiladi — avvaldan, aloqasiz)
- Real qurilma testi (Windows): KUTILMOQDA — ayniqsa ONKM validatsiya
