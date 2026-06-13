# Task: Printer sozlamasi o'zidan o'chib ketishini bartaraf qilish

**Boshlangan:** 2026-06-13
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Windows'da settings'dan sozlangan printer "bazi hollarda o'zidan o'zi o'chib ketyapti". Sababini topib, sozlama yo'qolmaydigan qilish.

## Muammoning ildizi (TO'LIQ tahlil — to'g'rilangan)
Printer `C:\ProgramData\InVanPos2\cache\printers\printers.hive` da saqlanadi (main.dart:203).

**MUHIM TUZATISH:** Avval "compaction printer faylni buzadi" deyilgan edi — bu NOTO'G'RI.
Hive default compaction sharti (hive-2.2.3/lib/src/box/default_compaction_strategy.dart):
`deletedEntries > 60 && deletedEntries/entries > 0.15`. Printer 1-2 marta sozlanib deyarli
o'chirilmaydi → deletedEntries≈0 → compaction HECH QACHON ishlamaydi. Compaction shifts
uchun to'g'ri edi (har sotuvda yoziladi → minglab o'chirish), printer uchun emas.

**Haqiqiy asosiy sabab — diskka yozish kechikishi (flush):**
1. Hive `box.add()` ni diskka DARROV yozmaydi. Kod yo'li box_impl.dart `_writeFrames` →
   storage_backend_vm.dart `writeFrames` da `flush()` CHAQIRILMAYDI. Ma'lumot OS buferida turadi.
2. Yagona ishonchli flush — `Hive.close()` (main.dart onWindowClose:39-48). LEKIN
   `windowManager.setPreventClose(true)` HECH QAYERDA chaqirilmagan → normal yopilishda ham
   `await hiveClose()` tugashidan oldin oyna yopilib ketishi mumkin (race).
3. Svet o'chsa / Task Manager'dan kill / crash bo'lsa onWindowClose UMUMAN ishlamaydi.
4. Natija: yangi sozlangan printer, OS background-flush qilishidan oldin (bir necha soniya)
   kompyuter to'satdan o'chsa — diskka yetib bormaydi → keyingi yoqishda yo'q. "Bazi hollarda"
   = flush ulgurganmi yo'qmi degan tasodif.

**Qo'shimcha sabablar:**
5. (O'rta) O'chirish atomik emas: printers_content_item.dart:64-73 `box.clear()` + `box.addAll()`.
   Orada uzilsa HAMMA printer yo'qoladi.
6. (Past, ataylab) Logout `clearAllBoxes()` (child_settings_content.dart:93 → hive_boxes.dart:15).
7. (Ehtimoliy) cache papkasini antivirus/tozalash dasturi tashqaridan o'chirishi.

**printers boxga yozish faqat 2 joyda** (boshqa joy yo'q — tekshirildi):
printer_select_dialog_provider.dart:47 (add), printers_content_item.dart:64 (delete).

## Scope
- Yangi: lib/features/printing/repository/printer_backup.dart (JSON atomik backup)
- O'zgaradi: printer_select_dialog_provider.dart (addPrinterToHive — backup yozish)
- O'zgaradi: printers_content_item.dart (removePrinterFromHive — atomik delete + backup)
- O'zgaradi: main.dart (hiveOpen oxirida _healPrintersIfNeeded)
- O'zgaradi: hive_boxes.dart (clearAllBoxes ga PrinterBackup.clear qo'shish)
- Scope'dan tashqari: shifts/boshqa box'lar (bu task faqat printer)

## Qabul qilingan qarorlar
- Backup Hive (prefs box) emas, **alohida JSON faylga atomik** yoziladi (.tmp → rename). Sabab: prefs box ham xuddi shu compaction buzilishiga uchraydi; JSON undan mustaqil va rename OS darajasida atomik.
- O'chirishda `clear()+addAll()` o'rniga `box.deleteAll(keys)` — atomik, qisman yo'qotish bo'lmaydi.
- **`box.flush()` qo'shiladi** har add/delete'dan keyin — Hive'ni darrov diskka yozdiradi, flush-race oynasini yopadi (asosiy sababga to'g'ridan-to'g'ri choradir).
- **Logout siyosati: printer HAM o'chsin (hozirgidek).** Foydalanuvchi tanladi (2026-06-13). Demak `clearAllBoxes()` ga `PrinterBackup.clear()` qo'shiladi — self-heal logoutni yo'qqa chiqarmasligi uchun.

## Bajarilgan
- [x] Muammo ildizi to'liq aniqlandi (asosiy: flush kechikishi, compaction EMAS)
- [x] Logout siyosati bo'yicha qaror olindi (printer o'chadi)
- [x] PrinterBackup yaratildi (JSON, .tmp→rename atomik, flush:true)
  → lib/features/printing/repository/printer_backup.dart
  → Windows: C:\ProgramData\InVanPos2\cache\printers\printers_backup.json; else: <appSupport>/posprinters/
- [x] addPrinterToHive — box.add() dan keyin box.flush() + PrinterBackup.save()
  → lib/changes/providers/printer_select_dialog_provider.dart:50-56
- [x] removePrinterFromHive — clear()+addAll() o'rniga box.deleteAll(keys) + flush + backup
  → lib/features/settings/features/printers/view/printers_content_item.dart:64-79
- [x] main.dart _healPrintersIfNeeded() — hiveOpen() dan keyin chaqiriladi (main.dart:75, ta'rif ~136)
  → box bo'sh + backup bor bo'lsa addAll+flush; box butun bo'lsa backupni yangilaydi
- [x] clearAllBoxes() ga PrinterBackup.clear() qo'shildi (logout backupni ham o'chiradi)
  → lib/features/hive_repository/hive_boxes.dart:30-34
- [x] flutter analyze — 5 fayl toza (faqat oldindan mavjud main.dart:106 empty_catch info)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] WINDOWS'da real test (quyidagi Test bo'limi bo'yicha) — foydalanuvchi bajaradi

## Ochiq savollar
- (yo'q — barchasi hal qilindi)

## Test / Verifikatsiya
- Windows: sozlangan printer → cache\printers\printers.hive ni o'chir/0KB qil → restart → printer qaytishi kerak (self-heal)
- O'chirish: 2 ta printer qo'sh, bittasini o'chir, qolgani saqlanishini tekshir
- Logout → printer ham backup ham tozalanishi kerak (qayta kirishda bo'sh)
