# Task: Perechisleniya (Didox) INN qidiruvida client + supplier ikkalasiga request

**Boshlangan:** 2026-07-28
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad

"Перечисления" ekranidagi Didox INN qidiruv (SEARCH tugmasi) faqat `clients_by_pos`
API'siga so'rov yuborardi. Endi shu INN bo'yicha supplier (postavshik) qidiruv
API'siga ham parallel so'rov yuboriladi — ikkalasidan qaysinisi natija (ma'lumot)
qaytarsa, o'shani ishlatamiz (mijoz yoki supplier sifatida).

## Scope

- `lib/changes/dialogs/client_search/client_search_with_inn_dialog.dart` (TransferWithInnDialog — bu "Перечисления"/Didox oynasi)
- `lib/changes/bloc/client_search/client_search_bloc.dart` / `client_search_event.dart` / `client_search_state.dart`
- `lib/changes/dialogs/client_search/components/search_button_of_client_search_dialog.dart.dart`
- `lib/changes/dialogs/client_search/components/search_field_of_client_search_dialog.dart`
- `lib/changes/providers/ordering_provider_4.dart` (supplier setter)
- Scope tashqarisida: asosiy (kartochka bo'yicha) client qidiruv oqimi —
  `client_search_dialog_with_bloc.dart` — `alsoCheckSupplier` default `false`
  bo'lgani uchun bu yerda xatti-harakat o'zgarmadi.

## Bajarilgan

- [x] `ClientSearchEvent`ga `alsoCheckSupplier` (default false) flag qo'shildi
  → lib/changes/bloc/client_search/client_search_event.dart
  → Sabab: mavjud client-search oqimlarini (asosiy checkout, create-client va h.k.) buzmaslik uchun opt-in flag.
- [x] `ClientSearchSupplierFoundState` qo'shildi (SupplierModel bilan)
  → lib/changes/bloc/client_search/client_search_state.dart
- [x] `ClientBloc._clientSearch`da `alsoCheckSupplier=true` bo'lsa, `ClientApi.clientByCardIdd` va `SupplierApi.searchSuppliers` bir vaqtda (`Future.wait`) chaqiriladi; client topilsa — ClientFoundState, topilmasa lekin supplier topilsa — ClientSearchSupplierFoundState, ikkalasi ham topilmasa — ClientNotFoundState, ikkalasi ham xato bo'lsa — ClientErrorState
  → lib/changes/bloc/client_search/client_search_bloc.dart:50-90
- [x] `SearchButtonOfClientDialog` va `SearchFieldOfClientSearchDialog`ga `alsoCheckSupplier` prop qo'shildi va barcha `ClientSearchEvent(...)` chaqiruvlariga thread qilindi
  → lib/changes/dialogs/client_search/components/search_button_of_client_search_dialog.dart.dart
  → lib/changes/dialogs/client_search/components/search_field_of_client_search_dialog.dart
- [x] `TransferWithInnDialog`da ikkala widget'ga `alsoCheckSupplier: true` berildi; listener/builder'da `ClientSearchSupplierFoundState` ushlanadi (companyController matni supplier nomi bilan to'ldiriladi, `OrderingProvider4.setSelectedSupplierFromInnSearch()` chaqiriladi); client va supplier holatlari bir-birini tozalaydi (mutual exclusivity); "Ok" tugmasi validatsiyasi client YOKI supplier tanlangan bo'lishini qabul qiladigan qilib yangilandi
  → lib/changes/dialogs/client_search/client_search_with_inn_dialog.dart
- [x] `OrderingProvider4.setSelectedSupplierFromInnSearch(SupplierModel?)` metodi qo'shildi (`_selectedSupplier`ni o'rnatadi/tozalaydi)
  → lib/changes/providers/ordering_provider_4.dart (onSupplierSearchButtonPressed yonida)
- [x] `flutter analyze` — yangi xato yo'q (faqat loyihada oldindan mavjud bo'lgan info/warning'lar)

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] Windows'da real test: Perechisleniya oynasida haqiqiy mijoz INN'i bilan qidirib, client topilishini tekshirish (eski xatti-harakat saqlanganini tasdiqlash)
- [ ] Windows'da real test: faqat supplier bazasida mavjud INN bilan qidirib, "Название компании" maydoniga supplier nomi to'g'ri tushishini va "Ok" bosilganda supplier sifatida saqlanishini tekshirish
- [ ] Ikkalasida ham topilmagan INN bilan qidirib, "mijoz topilmadi" holati to'g'ri ishlashini tekshirish
- [ ] Chek/order yozilganda supplier orqali tanlangan "Perechisleniya" to'g'ri saqlanayotganini (masalan supplierId order body'siga tushayotganini) tekshirish — bu qism o'zgartirilmadi, lekin oqim endi ikkita manbadan kelishi mumkin

## Qabul qilingan qarorlar

- `ClientBloc` global (butun ilova bo'ylab bitta instance, app.dart'da yaratiladi) bo'lgani uchun ikkala-API qidiruvni **opt-in flag** orqali qildik, default xatti-harakatni o'zgartirmadik — asosiy client-qidiruv (checkout, create-client, va h.k.) faqat avvalgidek `clients_by_pos`ga so'rov yuboradi.
- Ustuvorlik: agar ikkala API ham natija qaytarsa, **client ustuvor** (chunki bu asl `ClientBloc` mo'ljallangan asosiy oqim, supplier — qo'shimcha fallback).

## Ochiq savollar

- Agar bitta INN bo'yicha ham client, ham supplier mavjud bo'lsa (real hayotda kamdan-kam), hozir client ustuvor tanlanadi — foydalanuvchi buni tasdiqlashi kerakmi yoki hozirgi ustuvorlik yetarlimi? Windows testi paytida aniqlash kerak.

## Test / Verifikatsiya

- `flutter analyze` orqali statik tekshiruv qilindi (xato yo'q).
- Real Windows POS'da INN qidiruv oqimi hali test qilinmagan (yuqoridagi "Keyingi qadamlar"ga qarang).
