# Task: Multi-klient orqali access-siz mahsulot o'chirish (kassir hiylasi) fix

**Boshlangan:** 2026-09-30
**Holat:** in-progress (relizda — 1.1.2+129, PRO, 2026-10-02, commit `a3a69a9`; do'kon sinovi kutilmoqda)
**Branch:** ayyubxon (DIQQAT: ish paytida working tree `fix/is-marking-false-sinxron`
branch'ida edi — commit'dan oldin qaysi branch'ga yozilishini foydalanuvchi hal qiladi)

## Maqsad
Kassirlar bo'sh klient tab'ini bosish orqali access kodisiz mahsulotni savatdan
"yo'qotish" yo'lini topishgan. Ildiz: `selectClient()` tanlangan bo'sh klientni
`_clearEmptyClients()` bilan ro'yxatdan o'chirib, `_currentClient`ni detached
qoldiradi; keyingi to'lovda `_paymentOnClients()` indeks bo'yicha boshqa
klientning savatini jimgina tozalaydi. Shu va unga yondosh teshiklarni yopish.

## Avvalgi implementatsiya
docs/sessions/archive/ da yo'q — bu zona `multi_client_test.dart` da
"xarakteristik test" sifatida muzlatilgan edi (Faza 0-3 da ataylab
ko'chirilmagan). Endi o'sha muzlatilgan xatti-harakat bug deb tasdiqlandi.

## Tasdiqlangan buglar (repro: test/multi_client_empty_select_bug_test.dart)
1. `selectClient(i)` — bo'sh klient tanlansa current detached, `_index` dangling
   → savat UI bo'sh ko'rinadi (mahsulot "yo'qoladi").
2. `_paymentOnClients()` — indeks bo'yicha tozalash: keyingi to'lovda 1-klient
   mahsuloti access-siz, deletedItems/Telegram izsiz o'chadi. 3+ klientda
   dangling `_index` → RangeError xavfi.
3. `cancelOrdering(access)` — mantiq teskari: `deleteS` ruxsati YO'Q xodim
   savatni dialogsiz tozalaydi, ruxsati BOR xodim dialog oladi.
   (git blame bilan tekshiriladi)
4. `Pref.getDeleteItem` defaulti `true` (default-open) — PIN login'dan oldin
   o'chirish ochiq.

## Scope
- lib/changes/providers/ordering_provider_4.dart — selectClient,
  _clearEmptyClients, _paymentOnClients, addClient (himoya), cancelOrdering
- lib/utils/helpers/prefs.dart — getDeleteItem default
- lib/features/home/home_page.dart — deleteTicketAccess stale o'qish (kerak bo'lsa)
- test/multi_client_empty_select_bug_test.dart — repro → regression testlarga aylantirish
- test/multi_client_test.dart — xarakteristik testlar yangi invariantga moslanadi
- Scope tashqarisida: per-qator o'chirish oqimi (deleteRow/PIN) — ishlayapti, tegilmaydi

## Bajarilgan
- [x] Bug tasdiqlandi — 3 ta repro test yozildi va o'tdi (buggy holatni isbotladi)
  → Sabab: gipotezani real provider oqimida isbotlash
- [x] selectClient: tanlangan klient _clearEmptyClients(keep:) bilan saqlanadi,
  _index = indexOf(_currentClient) qayta hisoblanadi
  → lib/changes/providers/ordering_provider_4.dart (selectClient, _clearEmptyClients)
  → Sabab: current hech qachon ro'yxatdan uzilmasligi (detached) kerak
- [x] _paymentOnClients: indeks o'rniga identity (_currentClient) bo'yicha tozalash;
  ro'yxat bo'shasa yangi klient, aks holda first + _index=0
  → lib/changes/providers/ordering_provider_4.dart (_paymentOnClients)
  → Sabab: to'lagan klient DOIM _currentClient; indeks siljishi boshqa klient
    savatini o'chirardi (asosiy o'g'irlik yo'li) yoki RangeError berardi
- [x] addClient: `if (list.isEmpty)` o'rniga `if (!list.contains(current))` —
  uzilgan current savati bilan ro'yxatga qaytadi
  → lib/changes/providers/ordering_provider_4.dart (addClient)
  → Sabab: himoya qatlami, mahsulot izsiz yo'qolmasligi uchun
- [x] cancelOrdering inversiya fix: deleteS YO'Q xodim endi false oladi
  (NoAccessDialog), deleteS BOR xodim to'liq tozalaydi
  → lib/changes/providers/ordering_provider_4.dart (cancelOrdering)
  → Sabab: git blame — mantiq fayl yaratilganidan beri teskari edi,
    ataylab qilingan degan dalil yo'q; ruxsatsiz xodim savatni dialogsiz
    tozalay olardi
- [x] getDeleteItem default true → false (default-deny)
  → lib/utils/helpers/prefs.dart:66
  → Sabab: PIN login'dan oldin o'chirish ochiq edi; yagona ishlatilish joyi
    'delete_ticket' (home_page)
- [x] home_page deleteTicketAccess maydon → getter (har bosishda o'qiladi)
  → lib/features/home/home_page.dart:79
  → Sabab: PIN bilan boshqa xodim kirsa qiymat eskirib qolardi
- [x] Repro testlar regression testlarga aylantirildi (4 ta)
  → test/multi_client_access_bypass_regression_test.dart
- [x] cart_basic_test: "savat baribir tozalanadi" xarakteristik testi to'g'ri
  holatga yangilandi + deleteS'li xodim testi qo'shildi
  → test/cart_basic_test.dart (cancelOrdering guruhi)
- [x] To'liq suite: 1382 test o'tdi; flutter analyze — 0 error
- [x] Katta miqyosli stress-test: 9000 tasodifiy operatsiya (30 seed × 300
  qadam, seed'langan — takrorlanuvchi) + 5 deterministik chekka holat.
  Har qadamda 4 invariant: (I1) current doim ro'yxatda va _index to'g'ri,
  (I2) begona bo'sh klient yo'q, (I3) clientNumber unikal, (I4) konservatsiya —
  hech bir savat ruxsatsiz o'zgarmaydi/yo'qolmaydi. Shadow-model bilan
  solishtiriladi.
  → test/multi_client_stress_test.dart
  → Sabab: fix har qanday operatsiya ketma-ketligida chidashini isbotlash
- [x] Mutation test: fix vaqtincha stash qilinganda fuzz eski bugni 3-qadamda
  ushladi ("current ro'yxatdan uzilgan"), uchchala batch yiqildi → test
  sezgirligi isbotlangan. Fix qaytarildi, yakuniy: 1390 test o'tdi.

## Keyingi qadamlar (prioritet bo'yicha)
- [x] 2026-10-01: commit (a3a69a9) va `ayyubxon`'ga birlashtirildi, GitLab + GitHub main'ga push; Odoo forkiga ham ko'chirildi
- [ ] Foydalanuvchi ko'rib chiqishi: commit qilish (branch tanlovi — ayyubxon
  yoki fix/multi-klient-access-bypass), keyin port-changelog bo'limi (7-qadam)
- [ ] Do'kon sinovi: kassir hiylasi stsenariysini qo'lda tekshirish
  (mahsulot → yangi klient → bo'sh klientni bosish → mahsulot joyida qolishi)

## Qabul qilingan qarorlar
- Bo'sh klient tab'da qoladi (tanlangan bo'lsa) — boshqa klientga o'tilganda
  avtomatik yo'qoladi. Sabab: mavjud UX saqlanadi, invariant tiklanadi
  (current doim ro'yxatda, _index doim to'g'ri).
- _paymentOnClients indeks emas, identity (`_currentClient`) bo'yicha tozalaydi.
  Sabab: to'lagan klient DOIM _currentClient; indeks siljishi/danglingda boshqa
  klient savati o'chib ketmasligi kafolatlanadi.

## Ochiq savollar
- (hal qilindi) cancelOrdering inversiyasi ataylabmi? — git blame: mantiq fayl
  yaratilganidan beri o'zgarmagan, ataylab dalili yo'q → fix kiritildi.
  E'tibor: endi deleteS'siz xodim Shift+Del bosganda NoAccessDialog chiqadi —
  do'kon sinovida shu oqim ham tekshirilsin.

## Test / Verifikatsiya
- `flutter test test/multi_client_access_bypass_regression_test.dart` — 4/4 o'tdi
- `flutter test` to'liq — 1382 test o'tdi (2026-09-30)
- `flutter analyze` (o'zgargan fayllar) — 0 error
- Do'kon sinovi kutilmoqda: (1) kassir hiylasi stsenariysi, (2) deleteS'siz
  xodim Shift+Del → dialog, deleteS'li xodim → tozalash
