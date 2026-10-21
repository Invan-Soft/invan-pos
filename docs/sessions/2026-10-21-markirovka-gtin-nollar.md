# Task: KM to'g'ridan skanerlanganda GTIN boshidagi nollar sababli mahsulot topilmasdi

**Boshlangan:** 2026-10-21
**Holat:** done (kod + testlar + port bo'limi; `ayyubxon` ga merge, Shorebird patch va do'kon sinovi — foydalanuvchida)
**Yakunlangan:** 2026-10-21
**Branch:** fix/markirovka-gtin-nollar (worktree: `../pos-invan-2-markgtin`, `ayyubxon` b1fd08d dan)

## Maqsad
Do'kondan (real ma'lumot): "Ichimlik Fanta 355ml" (SKU 25619) KM i kassada to'g'ridan skanerlansa
mahsulot topilmasdi. Avval oddiy shtrix-kod, keyin markirovka dialogida KM skanerlansa ishlardi.
KM to'g'ridan skanerlanganda ham mahsulot topilsin; oddiy shtrix-kod va SKU qidiruvi bayt-ba-bayt o'zgarmasin.

Adminkadagi shtrix-kodlar: `049000014242`, `0049000014242`, `049000067729`, `0049000067729`,
`049000033939`, `0049000033939`, `049000014273`, `0049000014273`.
KM: `01` + GTIN-14 `00049000033939` + `21` + seriya(13) + GS + `93` + kripto(4), masalan
`0100049000033939217MG7fVVkzf5Y?` `<GS>` `93abcd`.

## Sabab (tasdiqlandi — b1fd08d da qayta hosil qilindi)
- `lib/changes/domain/barcode/scanned_product_lookup.dart` `find()` (b1fd08d: 75-85): `^01(\d{14})` → `00049000033939`
  → `replaceFirst(^0+)` → `49000033939` (11 xona) → `ItemsSingleton.getProductByBarcode`
  (`lib/features/get_products/singletons/items_singleton.dart:283-306`) AYNAN `b == trimmed` solishtiradi.
  Katalogda `049000033939` (UPC-12) / `0049000033939` (EAN-13) — mos emas → `null`.
- Keyin aynan teng qidiruv (butun KM satri) ham, narxi 0 qidiruvi (`triedPatterns` aynan teng) ham topmaydi → "Mahsulot topilmadi".
- Dialog yo'li ishlaydi: `MarkValidator.matchesProduct` (`lib/changes/domain/marking/mark_validator.dart:105-107`)
  ikkala tomondan boshidagi nollarni olib tashlaydi.
- Tasnif/muddat to'siq emas: GS (0x1D) Dart `\s` ga kirmaydi → `product`; `parseExpiry` → null (21 dan oldin 17/15 yo'q).
- Xuddi shu sinf: `findBoxProduct` (EAN13 / nolsiz / GTIN14 variantlari, UPC-12 yo'q), `(01)` shoxi, `findZeroPriceProduct`.

## Scope
- `lib/changes/domain/marking/gs1.dart` — `Gs1.isSameGtin` (sof funksiya)
- `lib/changes/domain/barcode/scanned_product_lookup.dart` — uch yo'lga GS1 tengligi fallback, `ScannedProductMatch.gtins`
- `lib/changes/providers/ordering_provider_4.dart` — bitta qator: `findZeroPriceProduct(..., gtins: match.gtins)`
- Testlar: `test/gs1_test.dart`, `test/scanned_product_lookup_test.dart`, `test/barcode_classifier_test.dart`, `test/km_direct_scan_e2e_test.dart` (YANGI)
- Scope dan tashqari: `ItemsSingleton.getProductByBarcode` (oddiy skan/SKU), `MarkValidator`, qo'lda qidiruv
  (search dialog / typeahead), `api_provider.dart`, Arcus/terminal.

## Bajarilgan
- [x] `Gs1.isSameGtin(barcode, gtinKey)` — GS1 GTIN tengligi
  → lib/changes/domain/marking/gs1.dart:30-62
  → Sabab: GTIN-8/12/13/14 chapdan nol bilan 14 xonagacha to'ldirilganda teng bo'lsa — bitta tovar. Katalog kodi
    faqat 8..14 xonali SOF RAQAM bo'lsa qatnashadi; `endsWith` arzon filtr birinchi (regex faqat nomzodlarda).
- [x] `find()`: aynan teng qidiruvlar (GTIN nolsiz → butun satr) hech narsa topmasa — `gtins` bo'yicha `_productByGtin`
  → lib/changes/domain/barcode/scanned_product_lookup.dart:88-89, 97, 111, 136-153, 70-72
  → Sabab: oxirgi qadam bo'lgani uchun avval topilgan har bir skan aynan avvalgidek qoladi; `item.mark` qoidasi
    GTIN shoxlaridagidek (faqat markirovkali mahsulotga).
- [x] `findBoxProduct`: uch aynan variantdan keyin `_boxProductByGtin` (UPC-12 blok kodi)
  → lib/changes/domain/barcode/scanned_product_lookup.dart:53-64
- [x] `findZeroPriceProduct(triedPatterns, {gtins})`: aynan teng → topilmasa GS1 tengligi (katalog kodi `trim` bilan — shu yo'ldagi aynan solishtirish kabi)
  → lib/changes/domain/barcode/scanned_product_lookup.dart:156-177
  → lib/changes/providers/ordering_provider_4.dart:2998-2999
- [x] Testlar: +12 `gs1_test`, +81 `scanned_product_lookup_test`, +4 `barcode_classifier_test`, +12 `km_direct_scan_e2e_test` (YANGI) — jami +109
  → e2e fayl b1fd08d da: 8 ta bug testi yiqiladi, 4 ta "o'zgarmagan" testi o'tadi — ya'ni testlar haqiqatan bugni ushlaydi.

- [x] Commit `38e40f3` (kod + testlar); `docs/port-changelog.md` 17-task bo'limi, jadval va xronologiya (alohida docs commit)
  → Sabab: CLAUDE.md "PORT HUJJATI" qoidasi; "Odoo forkiga: kerak" — skaner/markirovka qidiruvi mantig'i.

- [x] `fix/markirovka-gtin-nollar` va `fix/vozvrat-ofd-xato` (18-task) → `ayyubxon` merge (`9122c02`, `075932e`); merge qilingan kodda to'liq to'plam 2147 o'tdi
- [x] Qo'shimcha (foydalanuvchi so'rovi): ba'zi skanerlar KM boshiga `-` qo'yadi (`-0100049…`) — topilmasdi. `Gs1.stripScannerPrefix`: faqat orqasidan `01`+GTIN14 / `(01)`+GTIN14 kelsa boshidagi `-` va AIM `]d2`/`]C1`/`]Q3` olinadi; `-` rejimida (haqiqiy GS yo'q bo'lsa) `-93` / `-8005` → GS. Commit `0bb3faa` (branch `fix/markirovka-skaner-minus`)
  → lib/changes/domain/marking/gs1.dart (`stripScannerPrefix`), lib/changes/domain/barcode/barcode_classifier.dart (`sanitize`), lib/changes/domain/marking/mark_cleaner.dart (`scanTime` boshi)
  → Sabab: `-` ilovadan emas — `MyBarcodeListener` `keyEvent.character` ni oladi, `fixKeyboardLayout` faqat kirill harflarini almashtiradi; skaner FNC1 ni `-` qilib uzatadi. Ichki GS ham `-` bo'lishi mumkin — aks holda KM `…Y?-` bilan soliqqa ketardi.
  → Testlar +24 (fix'siz 12 tasi yiqiladi); to'liq to'plam 2171 o'tdi, 7 skip. Port: 17-task §9.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Shorebird patch (`1.1.2+130` ga, `stable`; faqat Dart o'zgarishi, ObjectBox/pubspec yo'q)
- [ ] Do'kondagi `-` qo'yadigan skanerning to'liq xom satrini (fiskal so'rov logidagi `Label`) ko'rib tasdiqlash: ichki GS ham `-` bo'lib keladimi
- [ ] Do'konda: Fanta KM ini to'g'ridan skanerlash → marka qatori; shu KM qayta → "oldin qo'shilgan"
- [ ] `docs/markirovka-tizimi.md` (asosiy worktree'da, commit qilinmagan) §7.3 va §21 ga shu o'zgarishni qo'shish — 17-task port bo'limidagi matn bilan

## Qabul qilingan qarorlar
- GS1 tengligi har yo'lda OXIRGI qadam (blok: 3 aynan variantdan keyin; dona: GTIN nolsiz + butun satr aynan qidiruvidan keyin;
  narxi 0: aynan `triedPatterns` dan keyin) — avval ishlagan skan o'zgarmasligi uchun (masalan eski "Yaratish" bilan butun KM
  shtrix-kod qilib saqlangan mahsulot o'sha KM bilan avvalgidek topiladi).
- Pastki chegara 8 xona: eng qisqa GTIN (GTIN-8). `<= 5` — bu tizimda SKU, 6-7 — ichki kodlar; ularni nol bilan to'ldirish
  fragment moslik bo'lardi ("0206" ≠ "206" qoidasi). Yuqori chegara 14 — eng uzun GTIN.
- Indikator raqami (GTIN-14 boshidagi 1..9) saqlanadi: `14780000000001` ≠ `4780000000001` (GS1: karton ≠ dona).
- `_productByGtin` faqat oddiy shtrix-kodlarga qaraydi (blok kodi `findBoxProduct` da) — `MarkValidator` ham faqat oddiy
  shtrix-kodlarga qaraydi; GS1 qoidasi validator qoidasidan torroq (uzunlik cheklovi bor), shuning uchun skaner topgan
  mahsulot KM tekshiruvidan doim o'tadi (testda mixlangan).
- `MarkValidator` o'zgartirilmadi — dialog yo'li prod'da ishlayapti; unga uzunlik cheklovi qo'shilsa mavjud qabul qilingan
  KM lar rad etilishi mumkin edi (`0004780000000017` testi).
- `ItemsSingleton` ga tegilmadi — oddiy skan/SKU bayt-ba-bayt o'zgarmaydi; asosiy worktree'dagi commit qilinmagan
  `items_singleton.dart` o'zgarishlari bilan to'qnashuv ham yo'q.
- Narxi 0 yo'li uchun `ScannedProductMatch.gtins` (aniq maydon) — `triedPatterns.skip(1)` ga yashirin tayanish o'rniga.

## Ochiq savollar
- Blok kodi va boshqa mahsulotning dona shtrix-kodi GS1 bo'yicha bir xil GTIN bo'lsa (katalog xatosi) — blok yo'li birinchi
  (avvalgi tartib). Amalda uchramasligi kerak.
- Narxi 0 dublikat (aynan nolsiz kod) va narxi bor dublikat (GS1 teng kod) bir vaqtda bo'lsa — endi narxi bor mahsulot topiladi
  (avval narxi 0 dialogi). Katalog xatosi holati.
- Mavjud, tuzatilmagan: GTIN kaliti `<= 5` xona bo'lsa 1-qadam SKU qidiruviga tushadi (real KM da bo'lmaydi); `(01)`+13 xonali
  qavsli kodda lookup va `MarkValidator.extractGtin` turlicha GTIN oladi; `21` dan keyin kelgan `17` muddat o'qilmaydi; `item.mark`
  katalog obyektiga yoziladi (§21-p).

## Test / Verifikatsiya
- b1fd08d (baza): to'liq to'plam **2035 o'tdi, 7 skip**.
- Shu branch (`38e40f3`): to'liq to'plam **2144 o'tdi, 7 skip** (+109). Yiqilgan test yo'q.
- `test/km_direct_scan_e2e_test.dart` b1fd08d da: 8 ta bug testi yiqiladi, 4 ta "o'zgarmagan" testi o'tadi.
- `flutter analyze` (o'zgargan lib fayllar): 28 ta oldindan bor info, yangi ogohlantirish yo'q (baza bilan solishtirildi).
- 30 000 mahsulotli katalog: blok + KM qidiruvi 11 ms (test rejimi).
