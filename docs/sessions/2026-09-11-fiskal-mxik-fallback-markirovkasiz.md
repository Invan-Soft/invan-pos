# Task: Markirovka MXIK'li, lekin KM siz qator — fiskalga statik MXIK bilan yuborish

**Boshlangan:** 2026-09-11
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Adminkada mahsulot markirovkali deb belgilanMAGAN (`is_marking=false` — birinchi
mezon), lekin unga markirovka talab qiladigan MXIK (02202..., 02203... va h.k.) xato
kiritilgan. Mahsulotda markirovka kodi (seriya raqami) yo'q. Bunday qator fiskal
modulga asl MXIK bilan ketsa soliq chekni rad etadi. Yechim: FAQAT fiskal body'da
`classCode` (SPIC) → statik MXIK (`01905012001000000`), `barcode` → bo'sh. Qolgan
hamma narsa (backend `order_pos`: `product_mxik`, `product_barcode`; savat;
`product_type`) avvalgidek — foydalanuvchi 2026-09-11 da tasdiqladi.

Qo'shimcha (2026-09-11, ikkinchi aniqlashtirish): bunday mahsulotga savatda
**markirovka dialogi ham chiqmasin** — `is_marking=false` bo'lsa MXIK ro'yxatda
bo'lsa ham oddiy mahsulot kabi qo'shiladi.

## Avvalgi implementatsiya
docs/sessions/archive/2026-05-21-marking-product-type-fix.md (Yakunlangan 2026-09-07)
↑ U yerda "isMarking=false va 'Avto markirovkani aniqlash' ON → MXIK orqali
aniqlanadi" qoidasi qabul qilingan edi. Sabab: adminka bayroqni unutgan
markirovkali tovarlarni MXIK orqali ushlash. Endi `is_marking=false` birinchi
mezon: MXIK tekshirilmaydi (dialog yo'q, oddiy qator). `is_marking=null`
(bayroq kelmagan) uchun eski qoida saqlanadi.

## Scope
- `lib/changes/domain/marking/mxik_rules.dart` — `isMxikAutoDetectCandidate`
  (yangi), `isProductMarkable` qoidasi (is_marking=false → markirovkali emas)
- `lib/changes/providers/ordering_provider_4.dart` — `addProduct` va skaner yo'li
  shu markaziy predikatni ishlatadi (`_isMxikMarking` wrapper olib tashlandi)
- `lib/changes/domain/marking/fiscal_mxik_fallback.dart` — YANGI, sof qoida
- `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart`
  — `saleOnOFD` item quruvchida qoida qo'llanadi (sotuv va vozvrat)
- `test/fiscal_mxik_fallback_test.dart` — YANGI
- Testlar: mxik_rules, sold_item_builder, marked_row_builder, invoice_row_builder,
  box_row_builder, marking_flag_ofd_gating — `is_marking=false` holatlari
- Scope dan tashqari: `MxikRules.isMxikMarking` ro'yxatining o'zi, backend
  `order_pos` JSON tuzilmasi, `get_items_service` dagi Soliq bo'yicha
  `isMarking=true` sinxroni (`switchMarking`)

## Bajarilgan
- [x] Port hujjati (InVan 1 ga ko'chirish uchun): docs/fiskal-mxik-fallback-port.md
- [x] Sof qoida yozildi: `FiscalMxikFallback.needsFallback` / `resolve`
  → lib/changes/domain/marking/fiscal_mxik_fallback.dart
  → Sabab: Pref o'qimaydigan sof funksiya — to'g'ridan-to'g'ri testlanadi;
    "markirovka ro'yxati" uchun mavjud `MxikRules.isMxikMarking` ishlatiladi
    (02009, 02201, 02202, 02203–02208, 024) — alohida ro'yxat ochilmadi
- [x] `saleOnOFD` da `classCode`/`barcode` qoida orqali olinadi, almashtirilganda
  `LogHelper.write(warn)` yoziladi
  → receipt_singleton_4.dart `saleOnOFD` (ofdItems map)
  → Sabab: sotuv (`pressPaymentButtonOnlyOFD`), vozvrat (`return_bloc`) va
    qayta yuborish (`preofd_bloc`) hammasi `LocalService.sell` → `saleOnOFD`
    orqali o'tadi — bitta joy yetarli, vozvrat sotuv bilan mos keladi
- [x] Foydalanuvchi aniqlashtirdi: `is_marking` birinchi mezon → shartga
  `isMarkingProduct == false` qo'shildi; bayroq chek qatorida yo'q, shuning uchun
  `saleOnOFD` da `ItemsSingleton.getProductById` orqali katalogdan o'qiladi
  → fiscal_mxik_fallback.dart `needsFallback`, receipt_singleton_4.dart `saleOnOFD`
  → Sabab: `is_marking=true` mahsulot haqiqatan markirovkali — KM siz qolsa ham
    (invoice qatori) uni statik MXIK bilan "oddiy tovar" qilib o'tkazmaymiz
- [x] Testlar: sof qoida (15) + `saleOnOFD` integratsiya (9)
  → test/fiscal_mxik_fallback_test.dart
- [x] Ikkinchi aniqlashtirish: `is_marking=false` → markirovka dialogi CHIQMAYDI
  → mxik_rules.dart `isMxikAutoDetectCandidate` + `isProductMarkable` (2-qoida)
  → ordering_provider_4.dart `addProduct` (`isMarkingByMxik`) va `onBarcodeScanned`
    skaner yo'li — ikkalasi markaziy predikatga o'tdi, `_isMxikMarking` o'chirildi
  → Sabab: qoida 3 joyda takrorlanmasin (2026-05-21 dagi "4 ta mustaqil ro'yxat"
    xatosi qaytmasin). `is_marking=null` (bayroq kelmagan) eski xatti-harakatda —
    "Avto markirovkani aniqlash" shu holat uchun ishlayveradi
- [x] Testlar yangilandi: 6 faylga `is_marking=false` holatlari; `marked_row_builder_test`
  helper default'i `false` → `null` (niyat "MXIK avto-aniqlash" edi)
- [x] Chetki holatlar tekshiruvi (foydalanuvchi so'rovi: "men inobatga olmagan case'lar")
  → test/fiscal_mxik_fallback_scenarios_test.dart (20 test) + marking_flag_ofd_gating_test
    (alkogol widget testi)
  → Topilgan va tuzatilgan: `saleOnOFD` katalog qidiruvi (a) faqat fallback umuman
    mumkin bo'lganda chaqiriladi — `FiscalMxikFallback.mayNeedFallback` (20k katalog,
    60 qator: bir necha o'n ms), (b) try/catch — katalogda `id=null` mahsulot bo'lsa
    to'lov yo'li yiqilmaydi (`_isMarkingInCatalog`)
  → Hujjatlashtirilgan (o'zgartirilmagan) xatti-harakatlar: pastda "Ochiq savollar"

- [x] Soxta fiskal modul (Node, 127.0.0.1:3448, FiscalDriveAPI formati) bilan Mac'da haqiqiy
  sotuv + vozvrat o'tkazildi: ListFiscalDrives → GetInfo → SendSaleReceipt → order_pos;
  vozvratda RefundInfo sotuv javobidagi pasport bilan keldi, §10.2.1 balans to'g'ri
  → test/fiscal_wire_format_test.dart (modulga ketadigan aynan JSON, 9 test)
  → Kuzatuv: vozvratda `PackageCode=""` ketadi (server package_code bermaydi) — eski holat
- [x] Reliz: kommitlar 347813b (feat) + f0eefff (release), tag v1.1.2+125, GitLab + GitHub push
  → Sabab: foydalanuvchi "prodda chiqaraver" dedi (2026-09-11)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] GitHub Actions build → .exe ni PRO backend'ga yuklash → `GET api.7i.uz/file` tekshiruvi
- [ ] Do'kon sinovi (Windows, OFD yoqiq, "Avto markirovkani aniqlash" YOQIQ):
      adminkada `is_marking=false` va MXIK `02202...` bo'lgan mahsulot skanerlanadi →
      markirovka dialogi CHIQMAYDI, oddiy qator → to'lov → Alice'da fiskal so'rovda
      `SPIC=019...`, `Barcode=""`, `Label=""` → soliq qabul qiladi; `order_pos` da
      `product_mxik=02202...`
- [ ] Haqiqiy markirovkali (`is_marking=true`) suv — dialog chiqadi, KM bilan
      sotiladi, `SPIC` asl (regressiya yo'q)
- [ ] O'sha chekni vozvrat qilish — fiskal so'rovda ham `SPIC=019...`
- [ ] Haqiqiy markirovkali suv (KM skanerlangan) — `SPIC` asl MXIK, `Label` to'la
      (regressiya yo'q)

## Qabul qilingan qarorlar
- Shart (uchalasi birga): `is_marking == false` && `MxikRules.isMxikMarking(mxik)`
  && `mark` bo'sh. Sabab: foydalanuvchi — `is_marking` birinchi mezon, "false +
  markirovkali MXIK" holatida almashtirish. `mark` bo'shligi qo'shimcha himoya:
  "Avto markirovkani aniqlash" yoqiq bo'lsa `is_marking=false` bo'lgan, lekin
  haqiqatan markirovkali tovar (adminka bayroqni unutgan) MXIK orqali ushlanib KM
  skanerlanadi — bunda asl MXIK ketishi shart, aks holda KM statik SPIC bilan ketadi
- `is_marking` katalogdan (`ItemsSingleton.products`) o'qiladi, chek qatorida
  saqlanmaydi. Sabab: `ReceiptModelSoldItem4` ObjectBox entity — yangi maydon
  build_runner/model migratsiyasini talab qiladi, scope'dan katta. Mahsulot katalogda
  topilmasa (o'chirilgan, eski chek vozvrati) `false` deb olinadi
- Faqat fiskal body — chek qatori (`ReceiptModelSoldItem4.mxik`) MUTATSIYA
  QILINMAYDI. Sabab: backend `product_mxik` asl bo'lib qolishi kerak (adminka
  xatosi ko'rinib tursin), vozvrat/ObjectBox ma'lumotlari o'zgarmasin
- Statik MXIK `Pref mxikCode` dan (main.dart har ishga tushishda `01905012001000000`
  yozadi); Pref bo'sh bo'lsa almashtirish qilinmaydi. Sabab: bo'sh SPIC har doim
  rad etiladi — asl MXIK ketgani xavfsizroq
- Alkogol/sigareta MXIK ham qamrab olinadi (bir xil ro'yxat). Sabab: foydalanuvchi
  "avto markirovka tekshiruvi" ni nazarda tutdi, u ro'yxat alkogolni ham o'z ichiga oladi

## Ochiq savollar
- ~~"Serial number false" = `is_marking=false`~~ — 2026-09-11 tasdiqlandi, shartga kiritildi
- Alkogol MXIK (02203–02208, 024) + `is_marking=false`: markirovka dialogi chiqmaydi va
  fiskalga statik MXIK ketadi, LEKIN naqd to'lov cheklovi (`CashRestrictionRules
  .cashHiddenByMarking`) va alkogol ogohlantirishi hamon MXIK bo'yicha ishlaydi —
  kassir faqat karta bilan sota oladi. Bu eski qoida, tegilmadi. Foydalanuvchi qaror
  qilsin: MXIK xato bo'lsa naqd cheklovi ham olib tashlansinmi?
- Vozvrat mosligi: sotuvda `is_marking=false` (statik MXIK ketgan), keyin adminka
  bayroqni `true` qilsa vozvrat ASL MXIK bilan ketadi (katalog joriy holatidan
  o'qiladi). Fiskal modul vozvrat itemlarini asl sotuv bilan solishtirmaydi deb
  taxmin qilinadi — do'kon sinovida tekshirish kerak
- `is_marking=null` + "Avto markirovkani aniqlash" O'CHIQ: savatda oddiy qator, fiskalga
  statik MXIK (null ≠ true). Avval asl MXIK + bo'sh Label ketib soliq rad etardi —
  endi o'tadi. Niyat shu deb olindi
- `is_marking=true` + KM yo'q (masalan invoice qatori): fallback aralashmaydi — asl
  MXIK, bo'sh Label (eski xatti-harakat, soliq rad etishi mumkin)
- Backend `is_marking` ni har doim yuboradimi? Agar ha bo'lsa `null` holati amalda
  bo'lmaydi va "Avto markirovkani aniqlash" sozlamasi savatda deyarli ishlamaydi
  (faqat `true` bayroq dialog ochadi). Foydalanuvchi bilan tekshirish kerak
- `switchMarking` (Soliq ro'yxati bo'yicha `isMarking=true` sinxroni,
  get_items_service.dart) yoqiq do'konda MXIK xato mahsulot lokal `true` bo'lib
  qoladi — dialog yana chiqadi. Bu sozlama default o'chiq; kerak bo'lsa alohida task
- `is_marking=false` + KM SKANERLANGAN qatorda asl MXIK ketadi (almashtirilmaydi) —
  bu himoya foydalanuvchi bilan alohida kelishilmagan; agar bunday qator ham 019 bilan
  ketishi kerak bo'lsa `needsFallback` dan `!hasMark(mark)` olib tashlanadi

## Test / Verifikatsiya
- `flutter test test/fiscal_mxik_fallback_test.dart` — 24/24
- `flutter test test/fiscal_wire_format_test.dart` — 9/9 (modul wire-format)
- `flutter test test/fiscal_mxik_fallback_scenarios_test.dart` — 20/20 (blok, invoice,
  DataMatrix skan, is_marking=null, katalog bo'sh/buzilgan/o'zgargan, vozvrat, alkogol,
  20k katalog tezligi)
- `flutter test` markirovka testlari (mxik_rules, sold/marked/invoice/box row builder,
  marking_flag_ofd_gating) — yangi `is_marking=false` holatlari bilan o'tdi
- `flutter test` (to'liq to'plam, 2026-09-11) — 1115/1115 o'tdi
- `flutter analyze` (o'zgargan 3 fayl) — yangi xato/ogohlantirish yo'q (3 ta eski
  ogohlantirish `receipt_singleton_4.dart` da, tegilmagan qatorlarda)
- Do'kon sinovi — KUTILMOQDA (yuqoridagi "Keyingi qadamlar")
