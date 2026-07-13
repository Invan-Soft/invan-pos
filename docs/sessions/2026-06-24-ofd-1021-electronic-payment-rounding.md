# Task: OFD §10.2.1 — yarim-so'mli tarozi item + 100% elektron to'lov yaxlitlanishi

**Boshlangan:** 2026-06-24
**Holat:** in-progress
**Branch:** ayyubxon

## Avvalgi implementatsiya
docs/sessions/2026-06-15-ofd-deleted-item-equation-1021.md (red-delete deleted item §10.2.1)
↑ U yerda boshqa §10.2.1 sababi (o'chirilgan item to'lovga kirmasligi) hal qilingan edi.
Bu YANGI, mustaqil sabab — yaxlitlash, to'lov turi bilan bog'liq.

## Maqsad
Chek W58626 (Tiin Optom, Kassa 5, 726 926 so'm, 33 item) OFD §10.2.1 xatosi bilan
yiqildi. Sabab: tarozi mahsuloti narxi aniq **yarim so'mga** tushganda (Keshyu Gajak
0.29 × 204950 = **59435.5**) kod ikki xil yaxlitlaydi → OFD itemlar jami ≠ mijoz to'lagan
summa → 100% elektron to'lovda (cashback+click, naqd 0) balans buziladi.

## Sabab (isbotlangan — foydalanuvchi datasidan)
- W58626 to'lovi: CASHBACK 926 + CLICK 726 000 = **726 926** (naqd 0, karta 0).
- Server/to'lov Keshyu'ni **59 435** deb hisoblagan → jami 726 926.
- OFD `_countPrice` `roundToNearest` (yarimni yuqoriga) → Keshyu **59 436** → OFD jami 726 927.
- FARQ = 1 so'm (100 tiyin). §10.2.1: `Σ(Price−Disc) == Cash + Card + ΣOther`.
- 100% "other" (cashback+click) bo'lganda OFD aniq tiyin-tenglikni talab qiladi → buziladi.

### Eksperimentlar (qaysi gipotezalar rad etildi)
- Keshyu 0.29 + Sushki 0.334, **naqd** → o'tdi  ⇒ yolg'iz tarozi-yaxlitlash sabab EMAS.
- 1 ta item, 100% click, VAT=0 → o'tdi  ⇒ VAT nollanishi (other=price) sabab EMAS.
- 3×10000, 20000 naqd + 10000 click (100 tiyin balans farqi) → o'tdi  ⇒ naqd borligi farqni yutadi.
- W58626: yarim-so'mli kg item + 100% cashback+click → §10.2.1.
- Xulosa: **ikkala shart birga kerak** — yarim-so'mli tarozi item VA 100% elektron to'lov.

## Kod zanjiri (manba)
- `saleOnOFD` → lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart:212
- `_countPrice` (roundToNearest×100) → :350
- `_countOtherOFD` (per-item taqsimot, roundToNearest) → :397
- `_countVat` = (price−other)×nds/(100+nds) → :357
- `getOfdTotalPrice` (Σ roundToNearest) — taqsimot maxraji → items_singleton.dart:59
- Diagnostika (BALANS_FARQI) — base_service.dart `_build1021Diag` (commit 001a7e4)

## Bajarilgan
- [x] `saleOnOFD` — itemlar avval `List<SalingItemModel>` sifatida quriladi (toJson keyin)
  → receipt_singleton_4.dart:286 (`ofdItems`)
  → Sabab: yuborishdan oldin §10.2.1 balansini tekshirish/tuzatish uchun.
- [x] `_enforce1021Balance` qo'shildi — yuborishdan oldin §10.2.1 majburlanadi
  → receipt_singleton_4.dart:351 (yangi metod), :322 da chaqiriladi (faqat sotuvda)
  → Σ(Price−Disc) − (Cash+Card+ΣOther) qoldig'i hisoblanadi. Eng katta narxli
    item PRICE'i qoldiqcha to'g'rilanadi → Σ Price = mijoz to'lagan summa (OFD = to'lov,
    ortiqcha emas). Other Price'dan oshsa — zaxira: qoldiq Other'ga. VAT qayta hisob.
  → Qoldiq 0 ⇒ NO-OP. Farq 1 yoki bir necha so'm bo'lsa ham ishlaydi (qoldiq qancha
    bo'lsa shuncha to'g'rilanadi).
  → Qaror: foydalanuvchi OFD jami to'langan summaga teng bo'lishini xohladi
    (727 da balanslash emas, 726 = to'lov). Shuning uchun Other emas, Price to'g'rilanadi.
- [x] XAVFSIZLIK CHEGARASI: qoldiq faqat ≤ 500 so'm bo'lsa to'g'rilanadi. Bundan katta
    farq = boshqa bug → tegmaydi, xato ko'rinib qoladi (50k→70k kabi buzilishni oldini oladi).
  → receipt_singleton_4.dart: `const maxRoundingTiyin = 500 * 100` (50000 tiyin)
  → Sabab: float yaxlitlash manbasini qidirmasdan, OFD tekshiradigan invariantni
    to'g'ridan-to'g'ri kafolatlaymiz; no-op bo'lgani uchun balansli (ishlayotgan)
    sotuvlarga umuman ta'sir qilmaydi → regress xavfi yo'q.
- [x] flutter analyze: yangi xato/warning yo'q (3 ta — hammasi avvaldan mavjud:
  dead_null_aware :235, avoid_print :269, unused itemsLen :280).

- [~] Telegram log o'zgarishlari (ikkala/uchala body alohida xabar + order_pos stash)
  → BEKOR QILINDI (foydalanuvchi so'rovi bilan asliga qaytarildi):
    `git checkout base_service.dart` + receipt_singleton_4.dart'dan currentSaleOrderPosBody
    stash bloki olib tashlandi. base_service asl holatda (bitta requestSend + diag).
  → Eslatma: order_pos `{order:[...]}` body ApiProvider'dan (sync) keladi; muvaffaqiyatsiz
    fiskal sotuv serverga bormagani uchun u body ko'rinmaydi (mening o'zgarishim sababi emas).

- [x] BUGFIX: `_enforce1021Balance` har sotuvda crash berardi
  ("type 'double' is not a subtype of type 'List<DiscountModel>?'").
  Sabab: `SalingItemModel.discount` getter List<DiscountModel>? deb tiplangan, lekin
  unga double saqlanadi → getter o'qishda cast-crash. Fix: getter o'rniga
  `it.toJson()['discount']` (xom double). receipt_singleton_4.dart:~395.

## 2026-07-10: Real chekda takrorlandi — _enforce1021Balance YETARLI EMAS

Chek Y24996 (Tiin Optom, Kassa 6, v1.1.2+109, 34 item, CLICK 980 000 + CASHBACK 626
= 980 626, naqd/karta = 0) yana §10.2.1 bilan yiqildi. Bodydan isbotlangan tahlil:

- Aybdor item: **Pechenye Заман Kunjut Kg, 0.29 × 77 950 = 22 605.5** (yarim so'm!)
  → OFD `price` = 2 260 600 (22 606, yuqoriga), `other` = 2 260 500 (22 605, pastga).
  Per-item P−D−O = **+100 tiyin**. Qolgan barcha ko'ringan itemlarda P−D−O = 0
  (Qurt 0.21×69 950=14 689.5 ikkala tomonda ham 14 690 bo'lib mos tushgan).
- `_enforce1021Balance` ISHLAGAN (v109 da bor, residual=+100 ≤ 500 so'm), LEKIN:
  qoldiqni eng katta narxli itemga (Huggies 161 450) yuklaydi. 100% elektron
  to'lovda HAR item uchun other == price−disc, shuning uchun:
  - afzal branch sharti `price − residual >= other` (16 144 900 >= 16 145 000) → FALSE;
  - fallback `other += residual` → Huggies other = 16 145 100 > price = 16 145 000
    → endi **per-item Other > Price** → modul baribir "ошибочные параметры" beradi.
  Global tenglama 0 ga keladi, lekin buzilish boshqa itemga ko'chadi, xolos.
- XULOSA: strategiya noto'g'ri — qoldiqni IXTIYORIY (eng qimmat) itemga emas,
  muvozanatni buzgan itemlarning O'ZIga qo'llash kerak: δᵢ = Pᵢ−Dᵢ−Oᵢ > 0 bo'lgan
  itemlarning price'ini δᵢ ga kamaytirish (Заман 22 606→22 605) → ham global,
  ham per-item tenglik saqlanadi.
- Eslatma: diag'dagi "VAT=0 lekin kut~..." qatorlar FALSE POSITIVE — diag formulasi
  (P−D)×12/112 Other'ni hisobga olmaydi; 100% elektronda to'g'ri VAT = (P−D−O)×… = 0.
  Bu qatorlarni sabab deb o'qimaslik kerak.

## 2026-07-10 (kechqurun): IKKINCHI chek — tashxis 100% ISBOTLANDI, FIX YOZILDI

Banan cheki (5 item, 100% click, 22:51, Kassa "Holida", v109). Bu safar diag TO'LIQ
ko'rindi va nazariyani so'zma-so'z tasdiqladi:
- `BALANS_FARQI=0 (OK)` — global tenglama joyida (eski enforce "tuzatgan"),
- LEKIN #4 Roshen Milk Bubble: **other=2 790 100 > price=2 790 000** — eski
  enforce'ning fallback izi! Banan (0.65×19 990=12 993.5 yarim so'm, price
  12 994 / other 12 993) +1 so'mini eng katta itemga (Roshen) ko'chirgan →
  per-item buzilish → modul rad etgan. Per-item tekshiruv mavjudligi endi FAKT.

### Bajarilgan (fix)
- [x] `_enforce1021Balance` TO'LIQ qayta yozildi
  → receipt_singleton_4.dart (saleOnOFD :322 chaqiruvi o'zgarmagan)
  → 1-bosqich: per-item clamp (Other ≤ Price−Discount, VAT qayta hisob);
    2-bosqich: residual>0 → δ=P−D−O>0 itemlarning narxi δ dan oshirmay
    kamaytiriladi (eng katta δ dan boshlab); residual<0 → Other kamaytiriladi.
    Guard (≤500 so'm) va NO-OP xatti-harakati saqlangan. Matematik kafolat:
    residual = Σδ − (naqd+karta) ≤ Σδ — musbat qoldiq doim yopiladi.
- [x] Diag tuzatildi (base_service.dart `_build1021Diag`):
  → YANGI asosiy signal: `OTHER+DISC>PRICE` per-item tekshiruvi;
  → expVat endi (price−other)×vatP/(100+vatP) — app formulasiga mos, 100%
    elektronda VAT=0 endi false-positive bermaydi.
- [x] QO'SHIMCHA MUSTAHKAMLASH (100% kafolat uchun):
  → 0-bosqich normallashtirish: price/other/discount butun tiyinga yaxlitlanadi.
    Sabab: FiscalReceiptModel.fromRequest hamma summani `.toInt()` bilan KESADI
    (fiscal_receipt_model.dart:73-76) — float changli discount kesilganda 1 tiyin
    siljib, modul tenglamasi biz balanslagandan boshqacha chiqishi mumkin edi.
    Endi modul AYNAN biz balanslagan butun sonlarni ko'radi.
  → enforce endi REFUND uchun ham ishlaydi (`!isRefund` sharti olib tashlandi):
    refund ham xuddi shu `_countPrice` yaxlitlashidan o'tadi (hammasi naqd,
    other=0 — algoritm bunda eng katta itemni to'g'rilaydi, xavfsiz).
  → Yagona bo'g'iz nuqta tasdiqlandi: saleOnOFD faqat LocalService.sell():72 dan
    chaqiriladi; INCOM va INCOM-siz yo'llar ikkalasi ham shu body'ni ishlatadi.
- [x] Simulyatsiya (funksiya kodi manbadan verbatim, scratchpad): 9 test —
  Y24996 (34 item, real raqamlar), Banan cheki (5 item), no-op, manfiy residual,
  per-item buzuq holat, +300 multi-item, >500 so'm guard, refund +100,
  float-changli discount → HAMMASI O'TDI. Har testda 3 invariant: global raw,
  MODUL KO'ZI (.toInt() dan keyingi butun tenglama) va per-item. Y24996: faqat
  Заман 22 606→22 605, Huggies tegilmadi. Banan: faqat Banan 12 994→12 993.
- [x] flutter analyze: yangi xato/warning yo'q (3 tasi avvaldan mavjud).

## Keyingi qadamlar
- [ ] Yangi build/release (fix kassalarga yetib borishi uchun) — v109 hali eski kod bilan ishlayapti.
- [ ] Windows/do'kon test: yarim-so'mli tarozi item (masalan 0.65 kg × 19 990) +
  100% click/cashback → muvaffaqiyatli sotuv, diag'da OTHER+DISC>PRICE chiqmasligi.
- [ ] Regress: oddiy naqd / aralash sotuvlar avvalgidek ishlashini tekshirish (no-op kutiladi).

## Qabul qilingan qarorlar
- Fix joyi: `saleOnOFD` ichida itemlar qurilgach, yuborishdan oldin bitta rekonsilyatsiya.
  Sabab: yaxlitlashning aniq float-manbasini qidirib o'tirmasdan, OFD tekshiradigan
  invariantni (§10.2.1 balans) to'g'ridan-to'g'ri kafolatlaymiz. No-op bo'lgani uchun
  ishlayotgan (balansli) sotuvlarga xavf yo'q.

## Ochiq savollar
- Statik tahlilda ba'zan balans 0 chiqadi-yu, real chek yiqiladi — float subtilligi.
  Shuning uchun yakuniy tasdiq diagnostikali build logidan (BALANS_FARQI) olinadi.

## Test / Verifikatsiya
- flutter analyze: yangi xato yo'qligini tekshirish.
- Windows: Keshyu 0.29 kg + 100% click/cashback → §10.2.1 chiqmasligi kerak.
