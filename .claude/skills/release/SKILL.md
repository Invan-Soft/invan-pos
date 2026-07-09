---
name: release
description: InVan POS yangi versiyasini chiqarish — pubspec bump, dual push (gitlab+github), v* tag, GitHub Actions buildni kuzatish, .exe ni backend /upload/build ga yuklash. Foydalanuvchi "release qil", "yangi versiya chiqar" desa yoki /release buyrug'ini yozsa ishlatiladi.
argument-hint: "[X.Y.Z+BUILD] [changelog matni]"
---

# InVan POS Release Pipeline

Yangi POS versiyasini chiqarish jarayoni. Argument: `/release 1.1.3+108 Changelog matni` — ikkalasi ham ixtiyoriy.

## 0. Tayyorgarlik tekshiruvi

- `git status` toza bo'lishi kerak. Commit qilinmagan o'zgarishlar bo'lsa, foydalanuvchidan so'ra: commit qilamizmi yoki releasega kirmasinmi.
- Joriy branch `ayyubxon` bo'lishi kerak.
- Joriy versiyani o'qi: `grep '^version:' pubspec.yaml`

## 1. Versiya aniqlash

- Argument berilgan bo'lsa: format `X.Y.Z+BUILD` ekanini va BUILD joriy builddан katta ekanini tekshir.
- Argument berilmagan bo'lsa: build raqamini +1 oshirishni taklif qil (masalan `1.1.2+107` → `1.1.2+108`) va foydalanuvchidan tasdiq ol.
- MUHIM: build raqami do'konlarda o'rnatilgan versiyalardan katta bo'lishi shart, aks holda ilova yangilanishni ko'rmaydi.

## 2. Changelog

- Argumentda changelog berilmagan bo'lsa, oxirgi tagdan beri commitlardan o'zbek tilida qisqa (1-3 jumla, foydalanuvchiga tushunarli tilda, texnik jargon minimal) changelog draft qil va foydalanuvchiga ko'rsatib tasdiqlat.
- Oxirgi tag: `git describe --tags --abbrev=0`
- Commitlar: `git log <oxirgi-tag>..HEAD --oneline`

## 3. Pubspec bump + commit + dual push

1. `pubspec.yaml` da `version:` qatorini yangi versiyaga o'zgartir.
2. Commit: `release: X.Y.Z+BUILD`
3. Dual push (har doim ikkalasiga):
   - `git -c http.sslVerify=false push gitlab ayyubxon`
   - `git push origin ayyubxon:main` (github)

## 4. Tag + build trigger

```bash
git tag vX.Y.Z+BUILD
git push origin vX.Y.Z+BUILD
```

Bu `.github/workflows/release.yml` ("Release Windows Build") ni ishga tushiradi:
Flutter build windows → Inno Setup (`installer.iss`) → `installers/{version}.exe` → GitHub Release.

**Buildni kuzatish:** `gh run list --workflow=release.yml --limit=1` bilan run ID ol, so'ng `gh run watch <ID>` (run_in_background bilan). Build odatda 10-20 daqiqa.

**Build yiqilsa:** loglarni `gh run view <ID> --log-failed` bilan o'qi, sababini tushuntir. Tagni qayta ishga tushirish kerak bo'lsa: `git push origin :refs/tags/vX.Y.Z+BUILD` (o'chir) → tuzatish commit → tag qayta yarat → push.

**Ma'lum gotcha:** workflow `windows-2022` da ishlashi shart (yangi `windows-latest` VS18/MSVC14.51 `<experimental/coroutine>` ni hard-error qiladi; `windows/CMakeLists.txt` da `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` bor).

## 5. Backendga yuklash (MAJBURIY qo'lda qadam)

⚠️ GitHub Release ilovaga AVTOMATIK bormaydi. Ilovaning "Yangilanish" tugmasi `GET {baseUrl}file` dan o'qiydi, shuning uchun `.exe` ni backendga yuklash shart.

1. Foydalanuvchidan so'ra: **dev** (`https://dev.api.7i.uz/`) yoki **pro** (`https://api.7i.uz/`) ga yuklaymizmi? (Ikkalasiga ham bo'lishi mumkin.)
2. Release'dan .exe ni scratchpad papkaga yukla:
   ```bash
   gh release download vX.Y.Z+BUILD --pattern '*.exe' --dir <scratchpad>
   ```
3. Yukla (fayl katta, timeout 300s):
   ```bash
   curl -s -m 300 -w "\n--- HTTP: %{http_code}, vaqt: %{time_total}s ---\n" \
     -X POST "{baseUrl}upload/build" \
     -F "version=X.Y.Z+BUILD" \
     -F "changelog=<changelog>" \
     -F "file=@<exe-fayl>"
   ```

## 6. Verifikatsiya

1. `curl -s -m 20 {baseUrl}file` — javobda yangi `version` va `change_log` ko'rinishi kerak (`name`/`version`/`change_log` maydonlari).
2. CDN tekshiruvi: `curl -sI -m 20 "https://cdn.7i.uz/file/pos_X.Y.Z+BUILD.exe"` (dev uchun `dev.cdn.7i.uz`) — HTTP 200.
3. Yuklab olingan .exe faylni scratchpaddan o'chir.

## 7. Yakuniy hisobot

Foydalanuvchiga jadval ko'rinishida ber: versiya, tag, GitHub Release link, qaysi backend(lar)ga yuklandi, changelog matni, va eslatma: "Do'konlardagi ilova drawer'dagi Yangilanish tugmasi orqali yangi versiyani ko'radi".
