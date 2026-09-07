# Arxiv indeksi

Yakunlangan task'larning ro'yxati. Foydalanuvchi tabiiy tilda izlaganda Claude shu jadvalni o'qiydi va mos task'ni topadi.

**Qator qo'shish formati:**
```
| YYYY-MM-DD | <task qisqa nomi> | <kalit so'zlar/mavzu> | [link](<fayl>.md) |
```

| Yakunlangan | Task | Mavzu / kalit so'zlar | Fayl |
|-------------|------|------------------------|------|
| 2026-05-20 | Diskont (chegirma) tizimi | chegirma, diskont, BuyXGetY, BuyXGetX, FreeGift, sovg'a, foiz chegirma, kategoriya chegirmasi, mijoz guruhi diskonti, chek diskonti, isRepeatable, DiscountSingleton, DiscountHelpers, DiscountWsService, savatdagi diskont, box mahsulot diskonti, markirovka diskonti, UUID UUID UUID-konstanta diskont turlari | [link](2026-05-20-discount-system.md) |
| 2026-07-29 | Smena Chegirmalar qatori 0/juda katta | smena yopish chegirma 0, Z-otchёt Скидки noto'g'ri, Savdolar juda katta summa, blok BuyXGetY 1+1 chegirma boxValue marta ko'p, getCurrentHiveShift discountAmount, realPrice-price formula, item.discount ledger consolidateSoldItems value yoyilishi, 864000 900000 blok, OPD Chegirma %, chegirma fiskal OFD mos, naqd pul kassada ko'p otchot kam tekshiruv, chegirma naqdga tegmaydi | [link](2026-07-28-shift-discount-row-zero-fix.md) |
| 2026-09-07 | Fiskal sotuvni tezlashtirish | pressPaymentButtonOnlyOFD sekin, OFD sotuv kutish vaqti uzun, 'Sotuv tugadi' kech chiqadi, chek yopilishi sekin, profiling, YAKUNLANMAGAN (8 qadamdan 2 tasi) | [link](2026-05-20-fiscal-sale-optimization.md) |
| 2026-09-07 | Paynet Pass to'lov integratsiyasi | Paynet Pass yangi to'lov turi, QR/OTP skaner, status polling, fiskal chek, PaynetBloc, test URL ishlaydi, PROD URL YOQILMAGAN | [link](2026-05-20-paynet-payment-integration.md) |
| 2026-09-07 | Markirovkali product_type fix | markirovka product_type bo'sh, product_package bo'sh, marking_names to'la, MXIK prefix 02009 yo'q, isMarking fallback | [link](2026-05-21-marking-product-type-fix.md) |
| 2026-09-07 | Skaner home ekranda ishlamasligi | barcode listener fokus yo'qotadi, skaner vaqti-vaqti bilan ishlamaydi, macOS, BlBloc | [link](2026-05-22-barcode-listener-mac-fix.md) |
| 2026-09-07 | Free Gift sovg'a yagona product bo'lganda | Free Gift savatda faqat sovg'a producti bo'lsa qo'llanmasligi, buyAmount shart, sovg'a qiymati ayrilgandan keyin | [link](2026-06-03-free-gift-same-product-fix.md) |
| 2026-09-07 | Diskontli qisman refund narxi | order-level diskont, qisman qaytarish, qolgan mahsulot asl narxga qaytib ketishi | [link](2026-06-04-discount-partial-refund-fix.md) |
| 2026-09-07 | Free Gift refundda narx taqsimoti | sovg'a mahsulot 0 so'm o'rniga proporsional narx, order-level diskont refund | [link](2026-06-04-free-gift-refund-fix.md) |
| 2026-09-07 | Internet xatosi tushunarli xabari | SocketException raw matn kassirga chiqishi, ClientException, 'Превышен таймаут семафора', NetworkErrorHelper | [link](2026-06-04-network-error-friendly-message.md) |
| 2026-09-07 | shifts.hive buzilishi va bo'sh Z-otchot | svet o'chishi, compaction, shifts.hive 0KB, Z/X-otchot bo'sh, smenani yopib bo'lmaydi, self-heal | [link](2026-06-06-shift-hive-corruption-fix.md) |
| 2026-09-07 | OFD manzil avto-yangilash | ofd1..ofd4.yt.uz eskirdi, s0..s2.ofd.uz:3447, FiscalDriveAPI config, OfdConfigMigrator, soliq domen o'zgarishi | [link](2026-06-11-ofd-address-auto-migration.md) |
| 2026-09-07 | Diskont dialogi mijoz tanlanganda | mijoz QR scan, person-icon qidiruv, diskont dialogi keyingi productgacha chiqmasligi, recheckDiscountsAfterClientChanged | [link](2026-06-13-discount-dialog-on-client-select.md) |
| 2026-09-07 | Printer sozlamasi o'chib ketishi | printer sozlamasi o'zidan o'chadi, Hive flush kechikishi, JSON backup, self-heal, Windows | [link](2026-06-13-printer-setting-disappears-fix.md) |
| 2026-09-07 | Mijoz o'chirilganda diskont bekor | customer group diskont, mijozni tepadan o'chirish, sovg'a narxi qaytishi, isForAllClients | [link](2026-06-13-revert-discount-on-client-remove.md) |
| 2026-09-07 | OFD 10.2.1 — o'chirilgan item | red-delete isDeleted item fiskal chekka ketishi, items jami to'lovga teng emas, раздел 10.2.1 | [link](2026-06-15-ofd-deleted-item-equation-1021.md) |
| 2026-09-07 | OFD bo'sh items xatosi | items:[] bo'sh chek, 'Передан недействительный параметр в JSON', double trigger, paymentsMap tozalash | [link](2026-06-16-ofd-empty-items-double-trigger.md) |
| 2026-09-07 | Ochiq smenali kassani bloklash | kassa tanlash ro'yxati, 'Pos is open on the web', smena ochiq kassa disabled, aktivatsiya | [link](2026-06-17-block-open-shift-cashbox-on-select.md) |
| 2026-09-07 | Promo diskont qaytarishda yoyilishi | kampaniya diskonti refundda hamma productga proporsional tarqalishi, single_order_discount maydoni | [link](2026-06-18-return-promo-discount-spread-fix.md) |
| 2026-09-07 | BonusPoint (keshbek) discount turi | BonusPoint yangi discount turi, keshbek berish, lokalga saqlash, YAKUNLANMAGAN (qo'llash mantig'i yo'q) | [link](2026-06-19-bonuspoint-discount.md) |
| 2026-09-07 | Markirovka savatda 1 qator | markirovkali mahsulot har dona alohida qator, UI guruhlash, qty, data modeli o'zgarmaydi | [link](2026-06-19-marking-group-single-row.md) |
| 2026-09-07 | OFD 10.2.1 elektron to'lov yaxlitlash | tarozi item yarim so'm 59435.5, 100% click/payme/cashback to'lov, itemlar jami mos emas, _enforce1021Balance | [link](2026-06-24-ofd-1021-electronic-payment-rounding.md) |
| 2026-09-07 | request_logs 24 soat + activity | request_logs_of_invan_pos.txt rolling 24 soat rotatsiya, har UI harakati log, request body response | [link](2026-07-02-request-logs-24h-activity.md) |
| 2026-09-07 | Ketmagan cheklar avto-yuborish | internetsiz saqlangan cheklar, startup avto-flush, cheklar ro'yxatida (!) belgisi yangilanmasligi | [link](2026-07-03-unsent-receipts-auto-upload.md) |
| 2026-09-07 | Kassir xizmat vaqti tracking | started_time savatga birinchi mahsulot, closed_time chek yopilishi, kassir tezligi, YAKUNLANMAGAN (API endpoint yo'q) | [link](2026-07-04-cashier-service-time-tracking.md) |
| 2026-09-07 | Barcode exact-match | skanerda noto'g'ri mahsulot topilishi, Pringles o'rniga Shakar, LIKE qidiruv, SKU-barcode chalkashishi | [link](2026-07-08-barcode-exact-match.md) |
| 2026-09-07 | Diskont avto-sinxron (10 daqiqa) | WebSocket type 15/16/17 yo'qolsa diskont yetmasligi, company_discounts_for_pos, diff-merge, DiscountAutoSyncService | [link](2026-07-09-discount-auto-sync.md) |
| 2026-09-07 | Blok (box) tier narxi | blok skan qilinganda doim 1-tier narx, blok ichidagi dona soni tier'ga tushishi, savatdagi umumiy son | [link](2026-07-10-box-tier-price-fix.md) |
| 2026-09-07 | Blok/dona narx tahriri sinxron | OPD da blok narxi o'zgartirilsa dona qatorlari ham o'zgarishi, teskarisi ham, bir dona-narx | [link](2026-07-16-box-price-edit-sync.md) |
| 2026-09-07 | Blok vozvrat — UI blok, data dona | cheklarda 'N blok', faqat butun blok qaytarish, refund API dona hisobida, blok qoldig'i | [link](2026-07-16-box-return-block.md) |
| 2026-09-07 | O'chirilgan itemlar order_pos ga | deleted_items massivi, deleted_by kassir id, deleted_time, savatdan o'chirilgan mahsulot serverga | [link](2026-07-16-deleted-items-orderpos.md) |
| 2026-09-07 | Blok savatda 1 qator | blok saleType==2 har biri alohida qator, UI guruhlash, blokdagi dona sonini ko'rsatish | [link](2026-07-20-box-single-row-ui-grouping.md) |
| 2026-09-07 | Perechisleniya INN dual-search | Didox Перечисления INN qidiruv, clients_by_pos + supplier API parallel so'rov | [link](2026-07-28-perechisleniya-inn-dual-search.md) |
| 2026-09-07 | Markirovka (01) qavs strip fix | GS1 (01)(21)(93) qavs tozalash regexi AI raqamini ham o'chirishi, KM 04 dan boshlanishi, crypto kesish | [link](2026-07-30-marking-paren-strip-fix.md) |
| 2026-09-07 | OFD o'chiq — markirovka/cashsale gating | markCheckWithOfd o'chiq, naqd to'lov cheklovi, avto markirovka aniqlash, sozlamalar qulflanishi, 1.1.2+118 | [link](2026-08-07-ofd-off-marking-cashsale-gating.md) |
| 2026-09-07 | Cashback balansdan ortiq to'lash | Bonus karta bir necha marta bosilishi, balans 78000 dan 131000 to'lanishi, kumulyativ tekshiruv, 1.1.2+119 | [link](2026-08-12-cashback-overspend-fix.md) |
| 2026-09-07 | Ko'p kassa narx sinxron gap'i | oflayn kassa narx o'zgarishini olmasligi, notification catch-up oynasi, SyncCursor, CatchUpSync, 1.1.2+118 | [link](2026-08-12-multi-kassa-price-sync-gap.md) |
| 2026-09-07 | Smena diagnostikasi va ogohlantirishlar | 'Pos is open on the web', 'Невозможно закрыть смену', ketmagan cheklar, Telegram xabari, ShiftDiagnostics, 1.1.2+120 | [link](2026-08-13-shift-diagnostics-warnings.md) |
| 2026-09-07 | Qarzdorsiz DEBT sotuvi | mijozsiz qarzga sotuv, qarzdor o'chirilishi, supplierga qarz, DEBT qatori, 1.1.2+121 | [link](2026-08-17-debt-without-client-fix.md) |
| 2026-09-07 | BuyXGetY stale tekin product | A o'chirilgach B tekinligicha qolishi, savatda boshqa product bo'lsa, _clearStale, red-delete qty, 1.1.2+122 | [link](2026-08-21-buyxgety-stale-free-product-fix.md) |
| 2026-09-07 | Narx 5 kassadan 2 tasiga yetmasligi | connectivity_plus NCSI gate, Windows internet yo'q deydi API ishlaydi, katalog yangilanmagan ogohlantirishi, 1.1.2+122 | [link](2026-08-21-price-sync-missing-on-some-kassas.md) |
