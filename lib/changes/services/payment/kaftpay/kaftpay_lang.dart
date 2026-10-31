// Kaftpay xabarlari tili. Kassa tili (o'zbek / rus) Kaftpay oynalari va
// sozlama sahifasi ochilganda o'rnatiladi; skaner, to'lov oqimi va xato
// matnlari shunga qarab chiqadi. Rus tilida server xatolari Kaftpay'ning
// o'z ruscha `reason` matni bilan (`Accept-Language: ru`).

class KaftpayLang {
  const KaftpayLang._();

  /// true — o'zbekcha (sukut), false — ruscha.
  static bool uz = true;

  static String t(String uzText, String ruText) => uz ? uzText : ruText;

  /// `Accept-Language` (server `reason` tili).
  static String get serverLanguage => uz ? 'uz' : 'ru';
}
