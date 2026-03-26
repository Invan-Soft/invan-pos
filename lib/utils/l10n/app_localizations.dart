import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('uz')
  ];

  /// Наименование || Nomi
  ///
  /// In ru, this message translates to:
  /// **'Наименование'**
  String get nomi;

  /// Кол-во || Miqdor
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get miqdor;

  /// Цена || Narxi
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get narxi;

  /// Итого || Jami
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get jami;

  /// Чек || Chek
  ///
  /// In ru, this message translates to:
  /// **'Чек'**
  String get chek;

  /// К оплате || To'lash
  ///
  /// In ru, this message translates to:
  /// **'К оплате'**
  String get tolash;

  /// Скидки || Chegirmalar
  ///
  /// In ru, this message translates to:
  /// **'Скидки'**
  String get chegirmalar;

  /// Все || Barchasi
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get barchasi;

  /// Возврат || Qaytarish
  ///
  /// In ru, this message translates to:
  /// **'Возврат'**
  String get qaytarish;

  /// Продажи || Savdo
  ///
  /// In ru, this message translates to:
  /// **'Продажи'**
  String get savdo;

  /// Чеки || Cheklar
  ///
  /// In ru, this message translates to:
  /// **'Чеки'**
  String get cheklar;

  /// Кассовые смены || Kassa hisoboti
  ///
  /// In ru, this message translates to:
  /// **'Кассовые смены'**
  String get kassaHisoboti;

  /// Настройки || Sozlamalar
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get sozlamalar;

  /// Обратная связь || Izoh jo'natish
  ///
  /// In ru, this message translates to:
  /// **'Обратная связь'**
  String get izohJonatish;

  /// Выход || Chiqish
  ///
  /// In ru, this message translates to:
  /// **'Выход'**
  String get chiqish;

  /// Доходы || Kirim
  ///
  /// In ru, this message translates to:
  /// **'Доходы'**
  String get kirim;

  /// Разница || Farq
  ///
  /// In ru, this message translates to:
  /// **'Разница'**
  String get farq;

  /// Поиск по штрихкоду... || Shtrix-kod orqali qidirish...
  ///
  /// In ru, this message translates to:
  /// **'Поиск по штрихкоду...'**
  String get shtrixKodOrqaliQidirish;

  /// Поиск по артикулу... || Artikul bo'yicha qidirish...
  ///
  /// In ru, this message translates to:
  /// **'Поиск по артикулу...'**
  String get artikulBoyichaQidirish;

  /// Поиск по имени товара... || Mahsulot nomi bo'yicha qidirish...
  ///
  /// In ru, this message translates to:
  /// **'Поиск по имени...'**
  String get mahsulotNomiBoyichaQidirish;

  /// Введите название... || Nomini kiriting
  ///
  /// In ru, this message translates to:
  /// **'Введите название...'**
  String get nominiKiriting;

  /// Клиент || Mijoz
  ///
  /// In ru, this message translates to:
  /// **'Клиент'**
  String get mijoz;

  /// Поиск || Qidirish
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get qidirish;

  /// Товары || Tovarlar
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get tovarlar;

  /// Категории || Kategoriyalar
  ///
  /// In ru, this message translates to:
  /// **'Категории'**
  String get kategoriyalar;

  /// Добавить элемент || Element qo'shish
  ///
  /// In ru, this message translates to:
  /// **'Добавить элемент'**
  String get elementQoshish;

  /// Количество || Soni
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get soni;

  /// Скидка || Chegirma
  ///
  /// In ru, this message translates to:
  /// **'Скидка'**
  String get chegirma;

  /// Бонус || Bonus
  ///
  /// In ru, this message translates to:
  /// **'Бонус'**
  String get bonus;

  /// Комментарий || Izoh
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get izoh;

  /// Введите комментарий || Izohni kiriting
  ///
  /// In ru, this message translates to:
  /// **'Введите комментарий'**
  String get izohniKiriting;

  /// Удалить || O'chirish
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get ochirish;

  /// Сохранить || Saqlash
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get saqlash;

  /// Поиск клиента по имени и номеру || Klientni ismi va nomeri bo'yicha qidirish
  ///
  /// In ru, this message translates to:
  /// **'Поиск клиента по ID'**
  String get klientniIsmiBoyichaQidirish;

  /// Добавить клиента || Mijoz qo'shish
  ///
  /// In ru, this message translates to:
  /// **'Добавить клиента'**
  String get mijozQoshish;

  /// Наличными || Naqd pulda
  ///
  /// In ru, this message translates to:
  /// **'Наличными'**
  String get naqdPulda;

  /// Пластик || Plastik
  ///
  /// In ru, this message translates to:
  /// **'Пластик'**
  String get plastik;

  /// Подарок || Sovg'a
  ///
  /// In ru, this message translates to:
  /// **'Подарок'**
  String get sovga;

  /// Долг || Qarz
  ///
  /// In ru, this message translates to:
  /// **'Долг'**
  String get qarz;

  /// Сдача || Sdacha
  ///
  /// In ru, this message translates to:
  /// **'Сдача'**
  String get sdacha;

  /// Оплатить || To'lash
  ///
  /// In ru, this message translates to:
  /// **'Оплатить'**
  String get tolash_oplatit;

  /// Кассир || Kassir
  ///
  /// In ru, this message translates to:
  /// **'Кассир'**
  String get kassir;

  /// ПОС || POS
  ///
  /// In ru, this message translates to:
  /// **'ПОС'**
  String get pos;

  /// Чек Но || Chek No
  ///
  /// In ru, this message translates to:
  /// **'Чек Но'**
  String get chekNo;

  /// Имя || Ism
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get ism;

  /// Фамилия || Familiya
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get familiya;

  /// Примечание || Eslatma
  ///
  /// In ru, this message translates to:
  /// **'Примечание'**
  String get eslatma;

  /// Создать и добавить в чек || Yaratish va chekka qo'shish
  ///
  /// In ru, this message translates to:
  /// **'Создать и добавить в чек'**
  String get yaratishVaChekkaQoshish;

  /// Введите номер чек || Chek raqamini kiriting
  ///
  /// In ru, this message translates to:
  /// **'Введите номер чек'**
  String get chekRaqaminiKiriting;

  /// Возврат || To'lovni qaytarish
  ///
  /// In ru, this message translates to:
  /// **'Возврат'**
  String get tolovniQaytarish;

  /// Общая сумма || To'langan jami
  ///
  /// In ru, this message translates to:
  /// **'Общая сумма'**
  String get tolanganJami;

  /// Дата создания || Yaratilgan sanasi
  ///
  /// In ru, this message translates to:
  /// **'Дата создания'**
  String get yaratilganSanasi;

  /// Нажмите на товар для возврата || Qaytish uchun tovarni bosing
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на товар для возврата'**
  String get qaytishUchunTovarniBosing;

  /// Налоги || Soliqlar
  ///
  /// In ru, this message translates to:
  /// **'Налоги'**
  String get soliqlar;

  /// Нажмите на товар для отмены возврата || Qaytarishni bekor qilish uchun tovarni bosing
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на товар для отмены возврата'**
  String get qaytarishniBekorQilishUchunTovarniBosing;

  /// Чек возврата || Qaytish cheki
  ///
  /// In ru, this message translates to:
  /// **'Чек возврата'**
  String get qaytishCheki;

  /// Смена || Smena
  ///
  /// In ru, this message translates to:
  /// **'Смена'**
  String get smena;

  /// Управление наличными || Naqd pulni boshqarish
  ///
  /// In ru, this message translates to:
  /// **'Управление наличными'**
  String get naqdPulniBoshqarish;

  /// Закрыт смену || Smenani yopish
  ///
  /// In ru, this message translates to:
  /// **'Закрыт смену'**
  String get smenaniYopish;

  /// Открыт || Tomonidan ochilgan
  ///
  /// In ru, this message translates to:
  /// **'Открыт'**
  String get tomonidanOchilgan;

  /// Наличные в кассе || Kassada naqd pul
  ///
  /// In ru, this message translates to:
  /// **'Наличные в кассе'**
  String get kassadaNaqdPul;

  /// Наличные на начало смены || Smena boshida naqd pul
  ///
  /// In ru, this message translates to:
  /// **'Наличные на начало смены'**
  String get smenaBoshidaNaqdPul;

  /// Оплаты наличными || Naqd to'lovlar
  ///
  /// In ru, this message translates to:
  /// **'Оплаты наличными'**
  String get naqdTolovlar;

  /// Возврат наличными || Naqd pulda qaytimlar
  ///
  /// In ru, this message translates to:
  /// **'Возврат наличными'**
  String get naqdPuldaQaytimlar;

  /// Внесения || Kirimlar
  ///
  /// In ru, this message translates to:
  /// **'Внесения'**
  String get kirimlar;

  /// Изъятия || Chiqimlar
  ///
  /// In ru, this message translates to:
  /// **'Изъятия'**
  String get chiqimlar;

  /// Инкассация || Inkassatsiya
  ///
  /// In ru, this message translates to:
  /// **'Инкассация'**
  String get inkassatsiya;

  /// Ожидаемая сумма наличных || Kutilayotgan pul miqdori
  ///
  /// In ru, this message translates to:
  /// **'Ожидаемая сумма наличных'**
  String get kutilayotganPulMiqdori;

  /// Сумма наличных ||  Pul miqdori
  ///
  /// In ru, this message translates to:
  /// **'Сумма наличных'**
  String get pulMiqdori;

  /// Итог продаж || Jami sotuvlar
  ///
  /// In ru, this message translates to:
  /// **'Итог продаж'**
  String get jamiSotuvlar;

  /// Продажи || Savdolar
  ///
  /// In ru, this message translates to:
  /// **'Продажи'**
  String get savdolar;

  /// Изъять || Chiqim
  ///
  /// In ru, this message translates to:
  /// **'Изъять'**
  String get chiqim;

  /// Сумма || Summa
  ///
  /// In ru, this message translates to:
  /// **'Сумма'**
  String get summa;

  /// Внести || Kirim
  ///
  /// In ru, this message translates to:
  /// **'Внести'**
  String get kirim_vnesti;

  /// Распечатать отчет || Hisobotni chop etish
  ///
  /// In ru, this message translates to:
  /// **'Распечатать отчет'**
  String get hisobotniChopEtish;

  /// Открыть смену || Smenani ochish
  ///
  /// In ru, this message translates to:
  /// **'Открыть смену'**
  String get smenaniOchish;

  /// Сумма наличных в начале смены || Boshlang'ich miqdor
  ///
  /// In ru, this message translates to:
  /// **'Сумма наличных в начале смены'**
  String get boshlangichMiqdor;

  /// Смена закрыта. || Smena yopilgan.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта.'**
  String get smenaYopilgan;

  /// Откройте смену, чтобы начать работу. || Ishni boshlash uchun smenani oching.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену, чтобы начать работу.'**
  String get ishniBoshlashUchunSmenaniOching;

  /// Принтеры || Printerlar
  ///
  /// In ru, this message translates to:
  /// **'Принтеры'**
  String get printerlar;

  /// Размер бумаги || Qog'oz o'lchami
  ///
  /// In ru, this message translates to:
  /// **'Размер бумаги'**
  String get qogozOlchami;

  /// Добавить принтер || Printer qo'shish
  ///
  /// In ru, this message translates to:
  /// **'Добавить принтер'**
  String get printerQoshish;

  /// Язык || Til
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get til;

  /// Префикс весов || Tarozi uchun prefix
  ///
  /// In ru, this message translates to:
  /// **'Префикс весов'**
  String get taroziUchunPrefix;

  /// Порт весов || Tarozi porti
  ///
  /// In ru, this message translates to:
  /// **'Порт весов'**
  String get taroziPorti;

  /// Настройки шрифта || Shrift sozlamalari
  ///
  /// In ru, this message translates to:
  /// **'Настройки шрифта'**
  String get shriftSozlamalari;

  /// Ночной режим || Tungi rejim
  ///
  /// In ru, this message translates to:
  /// **'Ночной режим'**
  String get tungiRejim;

  /// Выход из системы || Tizimdan chiqish
  ///
  /// In ru, this message translates to:
  /// **'Выход из системы'**
  String get tizimdanChiqish;

  /// Выберите язык || Tilni tanlang
  ///
  /// In ru, this message translates to:
  /// **'Выберите язык'**
  String get tilniTanlang;

  /// O'zbek || O'zbek
  ///
  /// In ru, this message translates to:
  /// **'O\'zbek'**
  String get ozbek;

  /// Русский || Русский
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russkiy;

  /// Введите префикс штрих-кода для весов || Tarozi uchun shtrix kod prefixini kiriting
  ///
  /// In ru, this message translates to:
  /// **'Введите префикс штрих-кода для весов'**
  String get taroziUchunShtrixKodPrefixiniKiriting;

  /// Выберите последовательный порт весов || Tarozi portini tanlang
  ///
  /// In ru, this message translates to:
  /// **'Выберите последовательный порт весов'**
  String get taroziPortiniTanlang;

  /// Размер шрифта || Shrift o'lchamini o'zgartiring
  ///
  /// In ru, this message translates to:
  /// **'Размер шрифта'**
  String get shriftOlchaminiOzgartiring;

  /// Перед выходом из системы: || Tizimdan chiqishdan oldin:
  ///
  /// In ru, this message translates to:
  /// **'Перед выходом из системы:'**
  String get tizimdanChiqishdanOldin;

  /// Закрытие открытой смены || Ochiq smenani yopish
  ///
  /// In ru, this message translates to:
  /// **'Закрытие открытой смены'**
  String get ochiqSmenaniYopish;

  /// Отмена || Bekor qilish
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// Текст сообщения... || Matnni kiriting
  ///
  /// In ru, this message translates to:
  /// **'Текст сообщения...'**
  String get matnniKiriting;

  /// Отправить || Jo'natish
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get jonatish;

  /// Телефонный номер || Telefon nomer
  ///
  /// In ru, this message translates to:
  /// **'Телефонный номер'**
  String get telefonNomer;

  /// Войти в систему || Tizimga kirish
  ///
  /// In ru, this message translates to:
  /// **'Войти в систему'**
  String get tizimgaKirish;

  /// Код СМС || SMS kod
  ///
  /// In ru, this message translates to:
  /// **'Код СМС'**
  String get smsKod;

  /// Подтверждать || Tasdiqlash
  ///
  /// In ru, this message translates to:
  /// **'Подтверждать'**
  String get tasdiqlash;

  ///  || O'z filialingizni tanlang
  ///
  /// In ru, this message translates to:
  /// **'Выберите свою заведение'**
  String get ozFilialingizniTanlang;

  /// Следующий || Keyingisi
  ///
  /// In ru, this message translates to:
  /// **'Следующий'**
  String get keyingisi;

  /// Выберите POS-устройство || POS qurilmasini tanlang
  ///
  /// In ru, this message translates to:
  /// **'Выберите POS-устройство'**
  String get posQurilmasiniTanlang;

  /// Вы хотите выйти? || Tizimdan chiqmoqchimisiz?
  ///
  /// In ru, this message translates to:
  /// **'Вы хотите выйти?'**
  String get tizimdanChiqmoqchimisiz;

  /// Да || Ha
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get ha;

  /// Нет || Yo'q
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get yoq;

  /// Выйти из приложения || Ilovadan chiqish
  ///
  /// In ru, this message translates to:
  /// **'Выйти из приложения'**
  String get ilovadanChiqish;

  /// Вариант || Variant
  ///
  /// In ru, this message translates to:
  /// **'Вариант'**
  String get variant;

  ///  || Mijoz tanlanmagan
  ///
  /// In ru, this message translates to:
  /// **'Клиент не выбран'**
  String get mijoz_tanlanmagan;

  /// Обновить || Yangilash
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get yangilash;

  /// Кешбек оплата || Keshbek to'lov
  ///
  /// In ru, this message translates to:
  /// **'Кешбек оплата'**
  String get keshbek_tolov;

  /// No description provided for @kassa_tanlang.
  ///
  /// In ru, this message translates to:
  /// **'Выберите кассу'**
  String get kassa_tanlang;

  /// No description provided for @tel_raqam.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get tel_raqam;

  /// No description provided for @kirish.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get kirish;

  /// No description provided for @parol.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get parol;

  /// No description provided for @filial_tanlang.
  ///
  /// In ru, this message translates to:
  /// **'Выберите филиал'**
  String get filial_tanlang;

  /// No description provided for @min.
  ///
  /// In ru, this message translates to:
  /// **'мин'**
  String get min;

  /// No description provided for @sek.
  ///
  /// In ru, this message translates to:
  /// **'сек'**
  String get sek;

  /// No description provided for @soat.
  ///
  /// In ru, this message translates to:
  /// **'часы'**
  String get soat;

  /// No description provided for @sotuv.
  ///
  /// In ru, this message translates to:
  /// **'Продажа'**
  String get sotuv;

  /// No description provided for @parol_keriting.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get parol_keriting;

  /// No description provided for @shtrix_code.
  ///
  /// In ru, this message translates to:
  /// **'Штрих Код'**
  String get shtrix_code;

  /// No description provided for @xodim.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник'**
  String get xodim;

  /// No description provided for @sync.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация'**
  String get sync;

  /// No description provided for @tolov_turi.
  ///
  /// In ru, this message translates to:
  /// **'Вид оплаты'**
  String get tolov_turi;

  /// No description provided for @tolandi.
  ///
  /// In ru, this message translates to:
  /// **'Оплачен'**
  String get tolandi;

  /// No description provided for @qoldiq.
  ///
  /// In ru, this message translates to:
  /// **'Остаток'**
  String get qoldiq;

  /// No description provided for @terminal.
  ///
  /// In ru, this message translates to:
  /// **'Терминал'**
  String get terminal;

  /// No description provided for @bonus_karta.
  ///
  /// In ru, this message translates to:
  /// **'Бонус карта'**
  String get bonus_karta;

  /// No description provided for @yakunlash.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть чек'**
  String get yakunlash;

  /// No description provided for @naqd.
  ///
  /// In ru, this message translates to:
  /// **'Наличный'**
  String get naqd;

  /// No description provided for @x_otchetga_access_yoq.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет разрешения на X-отчет!!!'**
  String get x_otchetga_access_yoq;

  /// No description provided for @z_otchetga_access_yoq.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет разрешения на Z-отчет!!!'**
  String get z_otchetga_access_yoq;

  /// No description provided for @hisoblash.
  ///
  /// In ru, this message translates to:
  /// **'Расчет'**
  String get hisoblash;

  /// No description provided for @hujjatni_yopish.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть документ'**
  String get hujjatni_yopish;

  /// No description provided for @qoldi.
  ///
  /// In ru, this message translates to:
  /// **'Осталось'**
  String get qoldi;

  /// No description provided for @karta.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get karta;

  /// No description provided for @qaytim.
  ///
  /// In ru, this message translates to:
  /// **'Сдача'**
  String get qaytim;

  /// No description provided for @narxni_ozgartirish.
  ///
  /// In ru, this message translates to:
  /// **'Изменить цену'**
  String get narxni_ozgartirish;

  /// No description provided for @tolov.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get tolov;

  /// No description provided for @bu_belgi_bilan_mahsulot_mavjud_emas.
  ///
  /// In ru, this message translates to:
  /// **'Нет продукта с этим штрих-кодом'**
  String get bu_belgi_bilan_mahsulot_mavjud_emas;

  /// No description provided for @click_pass.
  ///
  /// In ru, this message translates to:
  /// **'Click Pass'**
  String get click_pass;

  /// No description provided for @id.
  ///
  /// In ru, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @balans.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get balans;

  /// No description provided for @notogri_raqam.
  ///
  /// In ru, this message translates to:
  /// **'Неправильный номер'**
  String get notogri_raqam;

  /// No description provided for @client_cartasida_yetarli_emas.
  ///
  /// In ru, this message translates to:
  /// **'На карте клиента недостаточно денег!!!'**
  String get client_cartasida_yetarli_emas;

  /// No description provided for @clint_tanlanmagan.
  ///
  /// In ru, this message translates to:
  /// **'Выбранный клиент не существует'**
  String get clint_tanlanmagan;

  /// No description provided for @pinkodni_kiriting.
  ///
  /// In ru, this message translates to:
  /// **'Введите свой пин-код!'**
  String get pinkodni_kiriting;

  /// No description provided for @activligi.
  ///
  /// In ru, this message translates to:
  /// **'активность'**
  String get activligi;

  /// No description provided for @internet_yoq.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к интернету'**
  String get internet_yoq;

  /// No description provided for @xaridornig_ismini_kiriting.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя клиента'**
  String get xaridornig_ismini_kiriting;

  /// No description provided for @sharif.
  ///
  /// In ru, this message translates to:
  /// **'Отчество'**
  String get sharif;

  /// No description provided for @xaridorning_sharifini_kiriting.
  ///
  /// In ru, this message translates to:
  /// **'Введите отчество клиента'**
  String get xaridorning_sharifini_kiriting;

  /// No description provided for @xaridorning_telefon_raqamini_kiriting.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона клиента'**
  String get xaridorning_telefon_raqamini_kiriting;

  /// No description provided for @erkak.
  ///
  /// In ru, this message translates to:
  /// **'Мужской'**
  String get erkak;

  /// No description provided for @ayol.
  ///
  /// In ru, this message translates to:
  /// **'Женщина'**
  String get ayol;

  /// No description provided for @qiymat_kiriting.
  ///
  /// In ru, this message translates to:
  /// **'Введите значение'**
  String get qiymat_kiriting;

  /// No description provided for @narh_qoyilmagan.
  ///
  /// In ru, this message translates to:
  /// **'Цена выбранного товара еще не определена!!!'**
  String get narh_qoyilmagan;

  /// No description provided for @som.
  ///
  /// In ru, this message translates to:
  /// **'сум'**
  String get som;

  /// No description provided for @mijozga_qaytimini_bering_va_tekshiring.
  ///
  /// In ru, this message translates to:
  /// **'Передайте клиенту сдачу и чек'**
  String get mijozga_qaytimini_bering_va_tekshiring;

  /// No description provided for @xisobot.
  ///
  /// In ru, this message translates to:
  /// **'отчет'**
  String get xisobot;

  /// No description provided for @komunikator_ishlamaypti.
  ///
  /// In ru, this message translates to:
  /// **'Коммуникатор не работает !!!'**
  String get komunikator_ishlamaypti;

  /// No description provided for @mavjud_pos_qurilmalar.
  ///
  /// In ru, this message translates to:
  /// **'Доступные pos-устройства'**
  String get mavjud_pos_qurilmalar;

  /// No description provided for @chop_etish_ruhsati_yoq.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет разрешения на печать'**
  String get chop_etish_ruhsati_yoq;

  /// No description provided for @tolov_amalga_oshmadi.
  ///
  /// In ru, this message translates to:
  /// **'Платеж не прошел'**
  String get tolov_amalga_oshmadi;

  /// No description provided for @dark_mode.
  ///
  /// In ru, this message translates to:
  /// **'Темный режим'**
  String get dark_mode;

  /// No description provided for @send_telegram.
  ///
  /// In ru, this message translates to:
  /// **'Отправлять ошибки в телеграм'**
  String get send_telegram;

  /// No description provided for @mjoz_topilmadi.
  ///
  /// In ru, this message translates to:
  /// **'Клиент не найден'**
  String get mjoz_topilmadi;

  /// No description provided for @auto_yangilanish.
  ///
  /// In ru, this message translates to:
  /// **'Автоматическое обновление'**
  String get auto_yangilanish;

  /// No description provided for @oraliq_vaqtni_kiriting.
  ///
  /// In ru, this message translates to:
  /// **'Введите интервал'**
  String get oraliq_vaqtni_kiriting;

  /// No description provided for @daqiqa.
  ///
  /// In ru, this message translates to:
  /// **'минута'**
  String get daqiqa;

  /// No description provided for @tarnsaksiya_yaratildi.
  ///
  /// In ru, this message translates to:
  /// **' успешно\n создана транзакция!!!\n'**
  String get tarnsaksiya_yaratildi;

  /// No description provided for @kartani_oqiting.
  ///
  /// In ru, this message translates to:
  /// **'Прочитай карту !!!'**
  String get kartani_oqiting;

  /// No description provided for @tolov_amalga_oshirildi.
  ///
  /// In ru, this message translates to:
  /// **'Платеж произведен'**
  String get tolov_amalga_oshirildi;

  /// No description provided for @kod_notogri_yoki_internet_yoq.
  ///
  /// In ru, this message translates to:
  /// **'Вы ввели неверный СМС-код, или проблемы с интернетом'**
  String get kod_notogri_yoki_internet_yoq;

  /// No description provided for @xodim_uchun_tashkilot_biriktirilmagan.
  ///
  /// In ru, this message translates to:
  /// **'К данному сотруднику не привязана организация'**
  String get xodim_uchun_tashkilot_biriktirilmagan;

  /// No description provided for @yaroqsiz_id_kiritdingiz.
  ///
  /// In ru, this message translates to:
  /// **'Вы ввели неверный ID'**
  String get yaroqsiz_id_kiritdingiz;

  /// No description provided for @kodni_scanerlash.
  ///
  /// In ru, this message translates to:
  /// **'Сканирование кода'**
  String get kodni_scanerlash;

  /// No description provided for @tovar.
  ///
  /// In ru, this message translates to:
  /// **'Товар'**
  String get tovar;

  /// No description provided for @sana.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get sana;

  /// No description provided for @qoshish.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get qoshish;

  /// No description provided for @scanerni_codga_qarating_va_scanerlang.
  ///
  /// In ru, this message translates to:
  /// **'Наведите сканер на код и отсканируйте'**
  String get scanerni_codga_qarating_va_scanerlang;

  /// No description provided for @ijobiy_loglarni_jonatish.
  ///
  /// In ru, this message translates to:
  /// **'Отправить положительные логы'**
  String get ijobiy_loglarni_jonatish;

  /// No description provided for @sync_warning.
  ///
  /// In ru, this message translates to:
  /// **'Приложение обновит данные о товарах, сотрудниках и клиентах. Это может занять немного времени. Вы хотите обновить?'**
  String get sync_warning;

  /// No description provided for @yopish.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get yopish;

  /// No description provided for @kun.
  ///
  /// In ru, this message translates to:
  /// **'день'**
  String get kun;

  /// No description provided for @intervalni_tanlang.
  ///
  /// In ru, this message translates to:
  /// **'Выберите интервал'**
  String get intervalni_tanlang;

  /// No description provided for @kuting.
  ///
  /// In ru, this message translates to:
  /// **'Подождите'**
  String get kuting;

  /// No description provided for @turi.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get turi;

  /// No description provided for @ulgurji.
  ///
  /// In ru, this message translates to:
  /// **'ОПТОВЫЙ'**
  String get ulgurji;

  /// No description provided for @tolov_turi_activlashtirilmagan.
  ///
  /// In ru, this message translates to:
  /// **' оплаты не активирован'**
  String get tolov_turi_activlashtirilmagan;

  /// No description provided for @summa_minimal_summadan_kam.
  ///
  /// In ru, this message translates to:
  /// **'Сумма меньше минимальной суммы'**
  String get summa_minimal_summadan_kam;

  /// No description provided for @yuklanishlar_muvaffaqiyatli_yakunlandi.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка завершена успешно'**
  String get yuklanishlar_muvaffaqiyatli_yakunlandi;

  /// No description provided for @qayta_yuklash.
  ///
  /// In ru, this message translates to:
  /// **'Перезагрузить'**
  String get qayta_yuklash;

  /// No description provided for @pos_qurilma_mavjud_emas.
  ///
  /// In ru, this message translates to:
  /// **'Не активировано для этого компьютера\nPOS-устройство недоступно.\nЧерез бэк-офис создайте новое устройство.\nЗатем повторите попытку!'**
  String get pos_qurilma_mavjud_emas;

  /// No description provided for @qayta_urinish.
  ///
  /// In ru, this message translates to:
  /// **'Повторить попытку'**
  String get qayta_urinish;

  /// No description provided for @pos_qurilma_aktivlashtirilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Активация POS-устройства...'**
  String get pos_qurilma_aktivlashtirilmoqda;

  /// No description provided for @pos_qurilma_activlashtirish_yakunlanmadi.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось активировать Pos-устройство'**
  String get pos_qurilma_activlashtirish_yakunlanmadi;

  /// No description provided for @employee_yuklanmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка сотрудника...'**
  String get employee_yuklanmoqda;

  /// No description provided for @employee_yuklash_yakunlanmadi.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сотрудника'**
  String get employee_yuklash_yakunlanmadi;

  /// No description provided for @kategoriyalar_yuklanmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка категорий...'**
  String get kategoriyalar_yuklanmoqda;

  /// No description provided for @kategoriyalar_yuklash_yakunlanmadi.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить категории'**
  String get kategoriyalar_yuklash_yakunlanmadi;

  /// No description provided for @service_yuklanmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка сервиса...'**
  String get service_yuklanmoqda;

  /// No description provided for @service_yuklash_yakunlanmadi.
  ///
  /// In ru, this message translates to:
  /// **'Сбой загрузки службы'**
  String get service_yuklash_yakunlanmadi;

  /// No description provided for @productlar_olib_kelinmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Получение продуктов...'**
  String get productlar_olib_kelinmoqda;

  /// No description provided for @productlar_olib_kelish_yakunlanmadi.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось импортировать товары'**
  String get productlar_olib_kelish_yakunlanmadi;

  /// No description provided for @discountlar_olib_kelinmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Скидки принимаются...'**
  String get discountlar_olib_kelinmoqda;

  /// No description provided for @discountlar_olib_kelish_yakunlanmadi.
  ///
  /// In ru, this message translates to:
  /// **'Вычеты завершены.'**
  String get discountlar_olib_kelish_yakunlanmadi;

  /// No description provided for @internet_tekshirilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Проверка интернета...'**
  String get internet_tekshirilmoqda;

  /// No description provided for @malumotlar_tekshirilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Проверка данных...'**
  String get malumotlar_tekshirilmoqda;

  /// No description provided for @tasdiqlash_kodi_jonatilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Отправка кода подтверждения...'**
  String get tasdiqlash_kodi_jonatilmoqda;

  /// No description provided for @raqam_jonatishda_hatolik.
  ///
  /// In ru, this message translates to:
  /// **'ОШИБКА ОТПРАВКИ НОМЕРА:'**
  String get raqam_jonatishda_hatolik;

  /// No description provided for @mavjud_qurilmalar_yuklanmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка доступной информации об устройстве...'**
  String get mavjud_qurilmalar_yuklanmoqda;

  /// No description provided for @yangilangan_tovarlar_mavjud_emas.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных обновленных элементов'**
  String get yangilangan_tovarlar_mavjud_emas;

  /// No description provided for @ta_tovar_yangilandi.
  ///
  /// In ru, this message translates to:
  /// **'товары были обновлены'**
  String get ta_tovar_yangilandi;

  /// No description provided for @yangilanish_amalga_oshirilmadi.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить'**
  String get yangilanish_amalga_oshirilmadi;

  /// No description provided for @tolov_amalga_oshirilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Оплата производится...'**
  String get tolov_amalga_oshirilmoqda;

  /// No description provided for @bekor_qilish.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get bekor_qilish;

  /// No description provided for @qaytarish_amalga_oshirilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Возвращение...'**
  String get qaytarish_amalga_oshirilmoqda;

  /// No description provided for @qaytarish_muvaffaqiyatli_yakunlandi.
  ///
  /// In ru, this message translates to:
  /// **'Возврат успешно завершен'**
  String get qaytarish_muvaffaqiyatli_yakunlandi;

  /// No description provided for @qaytarish_amalga_oshirilmadi.
  ///
  /// In ru, this message translates to:
  /// **'Возврата не было'**
  String get qaytarish_amalga_oshirilmadi;

  /// No description provided for @check_qidirilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Ищу чек...'**
  String get check_qidirilmoqda;

  /// No description provided for @belgiga_tegishli_check_topilmadi.
  ///
  /// In ru, this message translates to:
  /// **'Не найдено чеков, соответствующих символу'**
  String get belgiga_tegishli_check_topilmadi;

  /// No description provided for @hali_checklar_mavjud_emas.
  ///
  /// In ru, this message translates to:
  /// **'Чеки пока недоступны'**
  String get hali_checklar_mavjud_emas;

  /// No description provided for @notogri_pin_kiritdingiz.
  ///
  /// In ru, this message translates to:
  /// **'Вы ввели неправильный пин-код!'**
  String get notogri_pin_kiritdingiz;

  /// No description provided for @klient_qidirilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Ищем клиента...'**
  String get klient_qidirilmoqda;

  /// No description provided for @tizimdan_chiqish_imkonsiz.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выйти, обратитесь к администратору'**
  String get tizimdan_chiqish_imkonsiz;

  /// No description provided for @jonatilmagan_cheklar_mavjud_emas.
  ///
  /// In ru, this message translates to:
  /// **'Не отправленные чеки нет!'**
  String get jonatilmagan_cheklar_mavjud_emas;

  /// No description provided for @jonatish_allaqachon_ishlamoqda.
  ///
  /// In ru, this message translates to:
  /// **'Отправка уже выполняется...'**
  String get jonatish_allaqachon_ishlamoqda;

  /// No description provided for @jonatish_tugatildi.
  ///
  /// In ru, this message translates to:
  /// **'Отправка завершена!'**
  String get jonatish_tugatildi;

  /// No description provided for @jonatish_jaroyonda.
  ///
  /// In ru, this message translates to:
  /// **'Идет отправка...'**
  String get jonatish_jaroyonda;

  /// No description provided for @mijoz_qoshish_muvaffaqiyatli_amalga_oshirildi.
  ///
  /// In ru, this message translates to:
  /// **'Добавление клиента прошло успешно!'**
  String get mijoz_qoshish_muvaffaqiyatli_amalga_oshirildi;

  /// No description provided for @mijoz_qoshilmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Добавление клиента...'**
  String get mijoz_qoshilmoqda;

  /// No description provided for @mijoz_qoshish_oxshamadi.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить клиента!'**
  String get mijoz_qoshish_oxshamadi;

  /// No description provided for @organization_olib_kelinmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Привлечение организации...'**
  String get organization_olib_kelinmoqda;

  /// No description provided for @organization_olib_kelish_yakunlanmadi.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить данные об организации.'**
  String get organization_olib_kelish_yakunlanmadi;

  /// No description provided for @kutish_vaqti.
  ///
  /// In ru, this message translates to:
  /// **'Время ожидания:'**
  String get kutish_vaqti;

  /// No description provided for @quiyidagi_mahsulotlarda_mxik_xatoliklar_mavjud.
  ///
  /// In ru, this message translates to:
  /// **'Эти продукты содержат несколько мxик ошибок'**
  String get quiyidagi_mahsulotlarda_mxik_xatoliklar_mavjud;

  /// No description provided for @dastur_haqida.
  ///
  /// In ru, this message translates to:
  /// **'О программе'**
  String get dastur_haqida;

  /// No description provided for @qarzga_sotishga_client_tanlangan_boloshi_lozim.
  ///
  /// In ru, this message translates to:
  /// **'Для продажи в кредит необходимо выбрать клиента'**
  String get qarzga_sotishga_client_tanlangan_boloshi_lozim;

  /// No description provided for @chegirmali_narx.
  ///
  /// In ru, this message translates to:
  /// **'Цена со скидкой'**
  String get chegirmali_narx;

  /// No description provided for @mijoz_hisobida_mablag_yetarli_emas.
  ///
  /// In ru, this message translates to:
  /// **'На счету клиента недостаточно средств'**
  String get mijoz_hisobida_mablag_yetarli_emas;

  /// No description provided for @bosh_sahifaga_otish.
  ///
  /// In ru, this message translates to:
  /// **'Перейти на домашнюю страницу'**
  String get bosh_sahifaga_otish;

  /// No description provided for @yuklab_olish.
  ///
  /// In ru, this message translates to:
  /// **'Скачать'**
  String get yuklab_olish;

  /// No description provided for @yuklanish_yakunlandi.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка завершена'**
  String get yuklanish_yakunlandi;

  /// No description provided for @yaratish.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get yaratish;

  /// No description provided for @haqiqatan_ham_barcha_jurnallarni_ochirib_tashlamoqchimisiz.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить все журналы?'**
  String get haqiqatan_ham_barcha_jurnallarni_ochirib_tashlamoqchimisiz;

  /// No description provided for @hammasini_tozalash.
  ///
  /// In ru, this message translates to:
  /// **'Очистить все'**
  String get hammasini_tozalash;

  /// No description provided for @yuklanmoqda.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка'**
  String get yuklanmoqda;

  /// No description provided for @perecisleniya.
  ///
  /// In ru, this message translates to:
  /// **'Перечисления'**
  String get perecisleniya;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
