# Shorebird: patch chiqarish qoidalari (InVan 2)

**Yangilangan:** 2026-10-02
**Kim uchun:** patch chiqaradigan dasturchi va qo'llab-quvvatlash.

Shorebird o'rnatilgandan keyin Dart kodidagi o'zgarishlar kassalarga yangi
`.exe` siz — **patch** bilan yetadi. Yangi reliz faqat native o'zgarishlarda
kerak. Bu hujjat — nima patch bilan o'tadi, patch qanday chiqariladi va
qanday qaytariladi.

## 1. Hozirgi holat

| | |
|---|---|
| Ishlab chiqarish relizi | `1.1.2+128`, **Windows**, Flutter 3.41.3 |
| Kassalar o'qiydigan kanal | faqat `stable` |
| Oxirgi stable patch | **#5** — `main` `919e601` (toza kod + PatchUpdater), 2026-09-30 17:16 |
| Patch'lar qanday chiqadi | GitHub Actions → **Shorebird Patch Windows** (`.github/workflows/patch.yml`) |
| Mac sinov relizi | `1.1.2+9128`, **macOS** — faqat sinov uchun, kassalarga ta'siri yo'q |

> 2026-09-30 da #1, #3, #4 — rangli SINOV patch'lari ishlab chiqarish
> relizining `stable` kanaliga chiqqan. O'sha kuni ~5 soat ichida patch
> tekshirgan kassalar rangli ekranni ko'rgan bo'lishi mumkin. #5 bilan
> hammasi toza holatga qaytgan. **Bundan keyin sinov patch'lari ishlab
> chiqarish relizining stable kanaliga chiqarilmaydi** (3-bo'lim).

## 2. Patch bilan nima o'tadi, nima yangi reliz talab qiladi

| O'zgarish | Patch | Yangi reliz |
|---|---|---|
| Dart kodi (`lib/`), tarjimalar (`.arb` → Dart) | ✅ | |
| `pubspec`: sof Dart paket qo'shish/yangilash | ✅ | |
| `pubspec`: native kodi bor plagin (yangi yoki versiya) | | ✅ |
| `windows/`, `macos/`, `android/`, `ios/` papkalari | | ✅ |
| `assets/` (rasm, shrift, `incom/`) | ❌ patch'ga **kirmaydi** | ✅ |
| Flutter versiyasi, `shorebird.yaml` | | ✅ |
| **ObjectBox sxemasi** (`objectbox-model.json`) | ❌ **HECH QACHON** | ✅ — va shu versiyadan pastga qaytish yopiladi |
| Pref/Hive ma'lumot formati | ⚠️ faqat orqaga mos bo'lsa | |
| `--dart-define` qiymatlari | `release.yml` va `patch.yml` da **bir xil** bo'lishi shart | |

Izohlar:
- **Ikonkalar:** release build ikonka shriftidan faqat ishlatilgan
  ikonkalarni qoldiradi. Patch'da yangi `Icons.xxx` qo'shilsa shrift
  o'zgaradi — Shorebird "asset changes" deb to'xtaydi (Mac'da shunday
  bo'ldi). Windows CI'da (#5) bu kuzatilmadi, lekin yangi ikonka qo'shilsa
  CI logini tekshiring; ogohlantirish bo'lsa — mavjud ikonkani ishlating.
- **ObjectBox:** sxema o'zgargan patch qaytarilsa (rollback) eski kod
  yangi bazani ochmaydi → kassa ochilmaydi. Sxema faqat to'liq reliz bilan.
- **Ma'lumot formati:** patch yangi formatda yozgan ma'lumotni qaytarilgan
  kod tushunmaydi (masalan smena navbatining yangi ro'yxati). Yangi format
  eski kalitlarni ham o'qiydigan qilib yozilsin.

## 3. Patch chiqarish tartibi

1. Kod GitHub `main` ga tushadi (`ayyubxon` → `main`).
2. GitHub → Actions → **Shorebird Patch Windows** → *Run workflow*:
   - `release_version`: **aniq** (masalan `1.1.2+128`). Standart qiymat
     yo'q: `latest` Shorebird'da "eng oxirgi yangilangan reliz" — u Mac sinov
     relizi bo'lib qolishi mumkin.
   - `track`: **`staging`** (tavsiya) yoki shoshilinch holatda `stable`.
3. **Sinov (staging):** test Windows kompyuterda
   `shorebird preview --platform=windows --release-version=1.1.2+128 --track=staging`
   → sotuv, smena, vozvrat, sinxron asosiy oqimlari.
4. **Kassalarga:** `shorebird patches promote --release-version=1.1.2+128 --patch-number=N`
   (yoki console.shorebird.dev → patch → Promote).
5. **Kuzatish:** Telegram hisoboti (PatchReporter — alohida task) va
   Shorebird console.

## 4. Kassada yangilanish qanday ishlaydi (`PatchUpdater`)

- **Ochilishda:** yangi patch bo'lsa yuklab, dastur o'zi qayta yonadi —
  kassir **bir marta** ochadi. Shu tekshiruv paytida oyna ko'rinmaydi.
  O'lchov (Mac, patch 5, 2026-10-02):

  | Holat | Oyna chiqquncha tekshiruv |
  |---|---|
  | Yangi patch bor | ~2 s yuklash → o'zi qayta yonadi (+3.2 s da yangi patch'da) |
  | Yangi patch yo'q (oddiy kun) | ~0.7 s |
  | Internet yo'q | ~0.3 s |
  | Wi-Fi bor, internet "osilgan" (javob yo'q) | ~3 s (har tekshiruv 3 s bilan cheklangan) |

  Sekin internetda patch 8 s ichida yuklanib ulgurmasa — dastur
  odatdagidek ochiladi, yuklash fonda davom etadi: keyin "Yangilanish
  tayyor" tugmasi chiqadi yoki keyingi ochilishda qo'llanadi.
- **Ish vaqtida:** har 10 daqiqada va internet/server qaytganda tekshiradi;
  patch tayyor bo'lsa yuqorida yashil **"Yangilanish tayyor"** tugmasi —
  faqat 6 ta savatning hammasi bo'sh bo'lganda.
- Tugma bosilmasa ham — keyingi ochilishda baribir qo'llanadi.
- Qayta yongandan keyin **"✓ Dastur yangilandi"** xabari.
- Har qadam log'da: `[PATCH] ...` (`request_logs_of_invan_pos.txt`).

> ⚠️ Ishlab chiqarishdagi #5 da ochilishdagi mantiq ESKI (Shorebird'ning
> avtomatik yuklovchisi bilan poyga — dastur o'zi qayta yonmaydi). Tuzatish
> keyingi patch bilan yetadi; o'sha patch'ning o'zi hali eski mantiq bilan
> qo'llanadi (tugma yoki ikkinchi ochilish), keyingilari — bir ochilishda.

## 5. Xato patch'ni qaytarish (rollback)

- **Console:** console.shorebird.dev → InVan POS 2 → `1.1.2+128` → Patches →
  patch → **Rollback**.
- **Terminal:**
  ```bash
  shorebird patches list --release-version=1.1.2+128
  shorebird patches rollback --release-version=1.1.2+128 --patch-number=N
  shorebird patches rollforward --release-version=1.1.2+128 --patch-number=N   # qayta yoqish
  ```
- Kassa keyingi tekshiruvda avvalgi patch'ga (birinchi patch bo'lsa —
  asl relizga) qaytadi: ochilishda bir martada yoki ish vaqtida tugma bilan.
  **Internet kerak.** Mac'da sinab ko'rilgan (2026-10-02, 6-bo'lim).

## 6. Sinov (Mac)

Ishlab chiqarish relizini sinov uchun ishlatmang. Mac sinov relizi bor:

```bash
# Faqat sinov paytida (commit qilinmaydi!) — macos/Runner/Release.entitlements:
#   app-sandbox=false, network.client=true, cs.allow-unsigned-executable-memory=true
shorebird patch macos --release-version=1.1.2+9128 --track=stable [--allow-asset-diffs]
shorebird preview --platform=macos --release-version=1.1.2+9128 --track=stable
```

Tuzoqlar:
- **Odoo forki** Mac'da ham `com.example.invan2` bundle id'ni ishlatadi →
  umumiy ma'lumotlar papkasi. Odoo ilovasi ochilsa ObjectBox sxemasi 61 ga
  ko'tariladi va InVan 2 (50) ochilmaydi. Sinov paytida Odoo ilovasini
  ochmang (Odoo bundle id'sini ajratish tavsiya etiladi).
- Lokal `shorebird patch` ba'zan **"Unauthorized"** (uzoq build'dan keyin
  sessiya) — qayta yuborish yetadi. CI API kalit bilan ishlaydi.
- `build/macos/.../Release/invan2.app` — patch build chiqindisi; uni
  ochmang (Shorebird relizi emas). Haqiqiy reliz `shorebird preview`
  keshida.
- Ishchi papkada boshqa (tugallanmagan) ish bo'lsa patch'ga u ham kiradi
  yoki build buziladi. Patch'ni alohida `git worktree` da (oxirgi commit +
  kerakli fayllar) build qiling.
- **PatchReporter** sinov build'idan ham Telegram kanaliga "build olindi"
  yuboradi (ochilgandan ~20 s keyin). Kanalga sinov xabari ketmasin desangiz
  — dasturni 20 s dan oldin yoping.
- Ochilish vaqtini o'lchash: binary'ni terminaldan to'g'ridan-to'g'ri
  ishga tushiring (`.../invan2.app/Contents/MacOS/invan2`), `[PATCH]`
  qatorlari stdout'ga chiqadi. Internetsiz holat:
  `HTTPS_PROXY=http://127.0.0.1:9` (ulanish rad etiladi); "osilgan"
  internet: `HTTPS_PROXY=http://10.255.255.1:9` (javob yo'q). Proxy faqat
  Shorebird'ga ta'sir qiladi — dasturning o'z API so'rovlari odatdagidek.

## 7. Xavflar va cheklovlar

- **Shorebird rejasi: free, overage 0.** Oylik patch o'rnatishlar limiti
  bor (console'da ko'ring). Kassalar soni × oyiga patch'lar soni limitdan
  oshsa — patch'lar yetkazilmay qoladi. Patch chastotasi oshganda pullik
  reja kerak bo'ladi.
- **Oflayn kassa** patch'ni internet qaytgunicha olmaydi.
- **Bir nechta patch o'tkazib yuborilsa** — kassa faqat oxirgisini oladi.
- **Patch faqat bitta relizga tushadi.** Kassalar turli relizlarda bo'lsa
  (masalan bir qismi hali `+128`, qolgani `+129`), muhim tuzatish har bir
  reliz uchun alohida patch qilinadi (`patch.yml` ni har `release_version`
  bilan ishga tushiring).
- **Windows'da qayta yonish sinalmagan.** Windows runner'da "bitta nusxa"
  tekshiruvi bor (`windows/runner/win32_window.cpp` `CheckOneInstance`):
  ikkinchi nusxa ochilmasdan jim yopiladi. Patch'dan keyin dastur o'zini
  qayta ishga tushirganda yangi jarayon eski jarayon to'liq yopilmasidan
  OLDIN shu tekshiruvga yetsa — yangi jarayon yopiladi va kassir dasturni
  qayta ochishi kerak bo'ladi (ma'lumot yo'qolmaydi). Mac'da bu tekshiruv
  yo'q — Mac sinovlari buni qamramaydi. Windows'da staging patch bilan
  sinash shart.
- Xato patch'ni Shorebird o'zi aniqlamaydi (Dart xatolari "muvaffaqiyatli
  ishga tushish" hisoblanadi) — kuzatish va rollback qo'lda.
