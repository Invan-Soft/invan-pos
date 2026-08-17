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
- [x] (2026-07-31) CHIDAMLILIK fix: dual-search javob parse'i himoyalandi
  → `_firstDataItem(HttpResult)` helper: {data:[...]} yoki top-level [...] shakllarini
    xavfsiz o'qiydi, kutilmagan shakl/bo'sh/Map-bo'lmagan → null (exception tashlamaydi)
  → butun parse bloki try/catch ichida — parse xatosida ClientErrorState emit qilinadi
  → Sabab: oldin `result['data'] as List` himoyasiz edi — API kutilmagan shakl qaytarsa
    (yoki List<String>.from parse xatosi) bloc handler throw qilib, UI SpinKit'da abadiy
    qotib qolardi. Endi har qanday holatda ham UI holatga o'tadi.
  → client_search_bloc.dart:_firstDataItem + _clientSearch dual-search bloki
  → dart analyze toza
- [x] (2026-07-31) Supplier DELETE tugmasi qo'shildi (Didox oynasida)
  → Oldin faqat client uchun DELETE bor edi; supplier xato tanlansa kassir tozalay
    olmasdi (sotuv xato supplier bilan ketardi). Endi DELETE tugmasi supplier
    tanlangan bo'lsa ham chiqadi.
  → Supplier delete: setSelectedSupplierFromInnSearch(null) + AppNavigation.pop()
    (client delete'dek — tozalab dialogni yopadi). Foydalanuvchi 2026-07-31 da
    client'dek yopilishini so'radi.
  → Shart: (widget.client != null || getSelectedSupplier != null). Dialog isDidox'ni
    watch qilgani uchun supplier o'zgarganda qayta quriladi → tugma reaktiv chiqadi.
  → client_search_with_inn_dialog.dart (DELETE tugmasi Row'i)
  → dart analyze toza

- [x] (2026-08-17) Supplier tanlangach dialog qayta ochilganda "Название компании" bo'sh qolardi — tuzatildi
  → `ClientInitialState` blokida faqat `widget.client` tekshirilardi; endi client
    yo'q bo'lsa `orderingProvider4.getSelectedSupplier` dan nom prefill qilinadi
    (`supplierCompanyName`, bo'sh bo'lsa `name`)
  → client_search_with_inn_dialog.dart:221-236 (ClientInitialState builder bloki)
  → Sabab: supplier provider'da saqlanadi, lekin `companyController` har ochilishda
    yangi/bo'sh yaratiladi va faqat qidiruv paytidagi
    `ClientSearchSupplierFoundState` uni to'ldirardi. Natijada DELETE tugmasi
    ko'rinib turardi (supplier bor), nomi esa yo'q edi.
  → Yon ta'sir ham tuzaldi: bo'sh maydon holatida "Ok" bosilsa
    `Pref.setString(PrefKeys.companyNameDialog, "")` ketib, chekdagi kompaniya nomi
    o'chib qolardi (print_sold_api.dart:89, printing_methods.dart:442 shu Pref'ni o'qiydi)
  → `flutter analyze` — yangi xato/warning yo'q (faqat oldindan mavjud deprecation info'lar)

- [x] (2026-08-17) Supplier endi HAR SAVAT (slot) uchun alohida — ko'p-mijoz rejimida bir-biriga ta'sir qilmaydi
  → `SixClientModel4` ga `selectedSupplier` maydoni qo'shildi (`selectedClient` yonida)
  → six_client_model.dart:14-24
  → `OrderingProvider4._selectedSupplier` maydon emas, endi
    `_currentClient.selectedSupplier` ustidan getter/setter
  → ordering_provider_4.dart:~3583 (`SupplierModel? get _selectedSupplier`)
  → Sabab: 1-mijozda Didox orqali supplier tanlansa, 2-mijozga o'tib cashback
    kartasi/mijoz tanlamoqchi bo'lganda `onClientSearchButtonPressed` guard'i
    (ordering_provider_4.dart:3523) global `_selectedSupplier` ni ko'rib
    "Allaqachon supplier tanlangan" deb bloklardi. "Mijoz YOKI supplier" qoidasi
    BITTA sotuv doirasida bo'lishi kerak, savatlar orasida emas.
  → `_paymentOnClients()` faqat sotilgan slotning supplierini tozalaydi;
    `clearSixClient4List()` barcha slotlarda tozalaydi
  → Tashqi iste'molchilar (`payment_page.dart:156`, `keyboard_of_payment_page.dart:242`,
    `left.dart:357`, `client_search_with_inn_dialog.dart`) `getSelectedSupplier`
    getter'idan o'qigani uchun o'z-o'zidan joriy slotga bog'landi
  → `ReceiptBuilder` ga uzatiladigan `_sixClientModel4` — to'lov sahifasiga
    kirishda aynan `getCurrentClient` obyekti (ordering_provider_4.dart:2845),
    demak chek ham o'z slotining supplieri bilan yig'iladi
  → `flutter analyze` — yangi xato yo'q

- [x] (2026-08-17) Kompaniya nomi + chek nusxalari soni ham savatga bog'landi
  → `SixClientModel4.receiptCompanyName` / `receiptCopies` qo'shildi
  → `OrderingProvider4._syncReceiptCompanyPrefsFromCurrentClient()` — savat
    almashganda (`selectClient`, `addClient`, `_paymentOnClients` oxiri,
    `clearSixClient4List`) global Pref'ni joriy savatnikiga moslaydi
    (qiymat yo'q bo'lsa `removeWithKey`)
  → `OrderingProvider4.setReceiptCompanyInfo({companyName, copies})` — dialog
    "Ok"da shu chaqiriladi, oldingi to'g'ridan-to'g'ri `Pref.setString/setInt`
    o'rniga (client_search_with_inn_dialog.dart, "Ok" handleri)
  → Nusxa soni dialog qayta ochilganda savatdan tiklanadi (`initState`da
    `a = getCurrentClient.receiptCopies ?? 1`, `StreamBuilder.initialData: a`)
  → Sabab: chop etish bu qiymatlarni GLOBAL Pref'dan o'qiydi
    (print_sold_api.dart:89, printing_methods.dart:442) va ularni faqat chop
    etilgandan keyin o'chiradi. Shuning uchun 1-mijoz uchun kiritilgan
    kompaniya nomi 2-mijoz birinchi sotilsa uning chekiga bosilardi.
  → Ketma-ketlik tekshirildi: chek `ReceiptSingleton4.toOBJECTBOX` ichida
    chop etiladi va u `_paymentOnClients()` dan OLDIN chaqiriladi
    (ordering_provider_4.dart:2958 → 2978) — demak Pref'ni tozalash chop
    etishga ulgurmay qolmaydi.
  → Eslatma: `lib/features/payment/right/dilogs/enamuration.dart` hamon Pref'ga
    to'g'ridan-to'g'ri yozadi, lekin u hech qayerdan chaqirilmaydi (o'lik kod) —
    shuning uchun tegilmadi.
  → `flutter analyze` — yangi xato yo'q

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] Windows'da real test: Perechisleniya oynasida haqiqiy mijoz INN'i bilan qidirib, client topilishini tekshirish (eski xatti-harakat saqlanganini tasdiqlash)
- [ ] Windows'da real test: faqat supplier bazasida mavjud INN bilan qidirib, "Название компании" maydoniga supplier nomi to'g'ri tushishini va "Ok" bosilganda supplier sifatida saqlanishini tekshirish
- [ ] Ikkalasida ham topilmagan INN bilan qidirib, "mijoz topilmadi" holati to'g'ri ishlashini tekshirish
- [ ] Windows'da tekshirish: supplier tanlab "Ok" → dialogni qayta ochish → "Название компании"da supplier nomi turibdimi (2026-08-17 fix)
- [ ] Windows'da ko'p-mijoz testi: 1-mijozga supplier tanlash → 2-mijozga o'tib mahsulot qo'shish → to'lovda cashback kartasi urish "Allaqachon supplier tanlangan" bermasligi kerak; 1-mijozga qaytganda supplier joyida turishi kerak
- [ ] Windows'da chek testi: 1-mijozga "Перечисления"da kompaniya nomi kiritib, 2-mijozni BIRINCHI sotish → 2-mijoz chekida kompaniya nomi CHIQMASLIGI kerak; keyin 1-mijozni sotganda esa chiqishi kerak (nusxa soni ham shunday)
- [ ] Chek/order yozilganda supplier orqali tanlangan "Perechisleniya" to'g'ri saqlanayotganini (masalan supplierId order body'siga tushayotganini) tekshirish — bu qism o'zgartirilmadi, lekin oqim endi ikkita manbadan kelishi mumkin

## Qabul qilingan qarorlar

- `ClientBloc` global (butun ilova bo'ylab bitta instance, app.dart'da yaratiladi) bo'lgani uchun ikkala-API qidiruvni **opt-in flag** orqali qildik, default xatti-harakatni o'zgartirmadik — asosiy client-qidiruv (checkout, create-client, va h.k.) faqat avvalgidek `clients_by_pos`ga so'rov yuboradi.
- Ustuvorlik: agar ikkala API ham natija qaytarsa, **client ustuvor** (chunki bu asl `ClientBloc` mo'ljallangan asosiy oqim, supplier — qo'shimcha fallback).

## Ochiq savollar

- Agar bitta INN bo'yicha ham client, ham supplier mavjud bo'lsa (real hayotda kamdan-kam), hozir client ustuvor tanlanadi — foydalanuvchi buni tasdiqlashi kerakmi yoki hozirgi ustuvorlik yetarlimi? Windows testi paytida aniqlash kerak.

## Test / Verifikatsiya

- `flutter analyze` orqali statik tekshiruv qilindi (xato yo'q).
- Real Windows POS'da INN qidiruv oqimi hali test qilinmagan (yuqoridagi "Keyingi qadamlar"ga qarang).
