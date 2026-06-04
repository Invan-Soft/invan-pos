/// Internet/tarmoq xatolarini foydalanuvchi tushunadigan xabarga aylantiradi.
/// Kassirlar uchun "SocketException", "ClientException" kabi raw exception
/// matnlari o'rniga "Internet sekin ishlayapti" kabi xabar chiqaradi.
class NetworkErrorHelper {
  static bool isNetworkError(Object error) {
    final s = error.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('clientexception') ||
        s.contains('handshakeexception') ||
        s.contains('timeoutexception') ||
        s.contains('httpexception') ||
        s.contains('connection closed') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('connection timed out') ||
        s.contains('connection aborted') ||
        s.contains('connection failed') ||
        s.contains('network is unreachable') ||
        s.contains('no address associated') ||
        s.contains('failed host lookup') ||
        s.contains('software caused connection abort') ||
        s.contains('os error') ||
        s.contains('errno =') ||
        s.contains('таймаут') ||
        s.contains('семафор') ||
        s.contains('сети') ||
        s.contains('соединени') ||
        s.contains('подключени');
  }

  /// Internet xato bo'lsa kassirlar uchun tushunarli xabar qaytaradi,
  /// aks holda raw error matnini qaytaradi (texnik debug uchun).
  /// [isUz] - true bo'lsa lotin, false bo'lsa kirill (rus)
  static String friendlyMessage(Object error, {required bool isUz}) {
    if (isNetworkError(error)) {
      return isUz
          ? "Internet sekin ishlayapti yoki ulanish yo'q. Iltimos, qayta urinib ko'ring."
          : "Интернет работает медленно или нет подключения. Пожалуйста, попробуйте ещё раз.";
    }
    return error.toString();
  }
}
