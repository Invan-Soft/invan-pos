# Task: Catch error'larni internet xatosi bo'lsa kassirga tushunarli xabarga aylantirish

**Boshlangan:** 2026-06-04
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Kassirlarga "ClientException with SocketException: Превышен таймаут семафора (OS Error)" kabi raw exception matnlari ko'rsatilmasin. Internet bilan bog'liq error bo'lsa, "Internet sekin ishlayapti yoki ulanish yo'q. Iltimos, qayta urinib ko'ring." kabi tushunarli xabar chiqsin.

## Scope
- Network error detektor helper yaratish
- Markirovkali mahsulot ONKM validatsiyasi (skrinshotdagi aniq misol)
- Loyiha bo'ylab `e.toString()` foydalanuvchi ko'radigan joylar

Scope tashqari: log/debug joylarda `e.toString()` saqlanishi kerak.

## Bajarilgan
- [x] `NetworkErrorHelper` yaratildi
  → lib/utils/helpers/network_error_helper.dart
  → Sabab: bir joyda markazlashtirilgan detektor — kelajakda yangi network error pattern'ini bir joyga qo'shsa bo'ladi. Kirill (rus) + lotin (uz) til qo'llab-quvvatlash.
  → Logikasi: `isNetworkError(e)` orqali SocketException/ClientException/HandshakeException/TimeoutException + OS Error/семафор/таймаут kalit so'zlarini tekshiradi. `friendlyMessage(e, isUz)` — agar network bo'lsa user-friendly, bo'lmasa raw `e.toString()` qaytaradi (texnik debug uchun).

- [x] helpers.dart barrel'ga eksport qo'shildi
  → lib/utils/helpers/helpers.dart
  → Sabab: `package:invan2/utils/utils.dart` orqali avtomatik tarqaladi, har joyda alohida import shart emas.

- [x] _markingCheck catch bloki tuzatildi (markirovka ONKM validation — skrinshotdagi joy)
  → lib/changes/providers/ordering_provider_4.dart:1806
  → Sabab: kassir validation paytida network down bo'lsa raw SocketException ko'rmasin.

- [x] typeUzcard catchError tuzatildi
  → lib/changes/providers/ordering_provider_4.dart:3709
  → Sabab: Arcus2 terminal Shell call'i — internet bog'liq emas, lekin xavf yo'q (helper non-network errorni o'z holicha qaytaradi).

- [x] typeHumo catchError tuzatildi
  → lib/changes/providers/ordering_provider_4.dart:3829
  → Sabab: yuqoridagi bilan bir xil.

- [x] wrapper.dart showErrorDialog tuzatildi
  → lib/app/wrapper/wrapper.dart:111
  → Sabab: full update items chaqirig'i async, network down bo'lsa SocketException ko'rsatardi.

- [x] marking_sync_dialog.dart tuzatildi
  → lib/features/settings/view/components/marking_sync_dialog.dart:48
  → Sabab: Soliqdan markirovka sinxronlash — bevosita internet talab qiladi.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Foydalanuvchi haqiqiy kassada UI test qilsin (markirovkali mahsulotni internet o'chirgan holatda qo'shib ko'rish)
- [ ] Boshqa loyiha bo'ylab `e.toString()` foydalanuvchi-yo'naltirilgan joylar (snackbar/dialog) qolmaganini auditdan o'tkazish. Hozirgi qamrov: yuqoridagi 5 ta joy. Boshqalari log/debug uchun bo'lib qoldi.

## Qabul qilingan qarorlar
- **`NetworkErrorHelper.friendlyMessage` non-network error uchun raw `e.toString()` qaytaradi** — sabab: agar kelajakda yangi error chiqsa, developer debug qila olishi kerak. Foydalanuvchi-yo'naltirilgan joyda har doim ham generic "Xatolik" yaxshi emas, ba'zida server xabari (masalan `messageLat`/`messageRu`) ko'rsatish maqsadga muvofiq.
- **Kirill (rus) detektsiyasi** kalit so'zlar bilan: "таймаут", "семафор", "соединение", "сети", "подключение" — chunki Windows OS Error xabari mahalliylashgan rus tilida keladi.

## Ochiq savollar
- Yo'q

## Test / Verifikatsiya
- `flutter analyze` — yangi xato yo'q, faqat oldindan mavjud info/warning'lar.
- UI test kutilmoqda: kassada internetni o'chirib markirovkali mahsulotni qo'shish.
