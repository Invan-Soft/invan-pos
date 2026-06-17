# Task: Kassa tanlashda smenasi ochiq kassani bloklash

**Boshlangan:** 2026-06-17
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Login/aktivatsiyada kassa tanlash ro'yxatida smenasi ochiq (server tomonda `status=open` yoki `opened_by_web`/`opened_by_pos`) kassalarni tanlab bo'lmasin. Hozir ochiq kassa tanlanadi → smena ochishda "Pos is open on the web" deydi va orqaga yo'l yo'q, user logout/login qilishga majbur. Yechim: bunday kassalar disabled + "Smena ochiq" yozuvi bilan ko'rsatilsin.

## Scope
- `lib/features/authentication/model/get_available_pos_response.dart` — `isShiftOpen` flag
- `lib/changes/services/get_available_pos_api.dart` — `getOpenShiftCashboxIds()` helper (GET api/v1/shift_statuses)
- `lib/features/authentication/bloc/ss_bloc/ss_bloc.dart` — ro'yxatga flag yozish
- `lib/features/authentication/bloc/auth_bloc/auth_bloc.dart` — single-store branch'da flag yozish
- `lib/features/authentication/bloc/bloc_activate_pos/apd_bloc_bloc.dart` — selectedPos guard
- `lib/features/authentication/view/activate_pos_card_bloc.dart` — length==1 auto-activate'ni ochiq kassa uchun bloklash
- `lib/features/authentication/bloc/bloc_activate_pos/components/initial_activate_pos_card_widget.dart` — disabled item + "Smena ochiq"
- Scope DAN TASHQARI: smena ochish logikasi (ShiftSingleton_4) — tegilmaydi

## Bajarilgan
- [x] Oqim tahlili: ro'yxat `GET api/v1/cashbox` (smena holati yo'q), smena holati `GET api/v1/shift_statuses`
- [x] `result` decoded JSON (List) ekani tasdiqlandi
- [x] Model: `isShiftOpen` flag qo'shildi
  → lib/features/authentication/model/get_available_pos_response.dart
- [x] Helper: `getOpenShiftCashboxIds()` (status=open/opened || opened_by_web/pos)
  → lib/changes/services/get_available_pos_api.dart
  → Sabab: xato/internet yo'q bo'lsa bo'sh set qaytaradi — bloklamaymiz (fail-open)
- [x] ss_bloc + auth_bloc: availablePosList qurilgach flag yoziladi
- [x] card_bloc: length==1 avto-aktivlashtirish ochiq kassa uchun bloklandi
  → lib/features/authentication/view/activate_pos_card_bloc.dart
- [x] apd_bloc: tanlash guard — ochiq kassa tanlansa tugma yoqilmaydi
- [x] UI: PopupMenuItem `enabled: !isOpen`, kulrang nom + qizil "Smena ochiq"/"Смена открыта"
- [x] flutter analyze: yangi error yo'q (faqat oldindan mavjud unused-import warninglar)
- [x] BUG FIX: shift_statuses 403 "invalid token" — kassa tanlash bosqichida PrefKeys.token hali bo'sh edi
  → shiftStatusInvan2({String? token}) + getOpenShiftCashboxIds({String? token}); ss_bloc/auth_bloc login token'ini uzatadi
  → Sabab: PrefKeys.token faqat aktivatsiyada (apd_bloc:240) yoki wrapper:78 da yoziladi, kassa tanlashda yo'q

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows/real qurilmada UI test: web'da smena ochiq kassa → login → disabled "Smena ochiq" ko'rinsin

## Qabul qilingan qarorlar
- UI: disabled + "Smena ochiq" yozuv (yashirish emas) — user nega tanlay olmasligini tushunsin
- Lokalizatsiya: yangi arb key qo'shmasdan `loc.ha == 'Ha' ? 'Smena ochiq' : 'Смена открыта'` pattern (loyihada mavjud usul)

## Ochiq savollar
- Barcha kassalar ochiq bo'lsa user shu ekranda qoladi (orqaga tugma bor) — yetarlimi?

## Test / Verifikatsiya
- Windows'da: web'da smena ochiq kassa → login → ro'yxatda disabled "Smena ochiq" ko'rinsin, tanlab bo'lmasin
