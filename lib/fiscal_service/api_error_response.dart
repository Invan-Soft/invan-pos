// ignore_for_file: constant_identifier_names

class ApiErrorResponses {
  const ApiErrorResponses._();
  static const String invalidResponse = 'Неверный ответ';
  static const String unAuth = 'Неавторизованный';
  static const String noInternet = 'No Internet Connection';
  static const String invalidFormat = 'Неверный формат';
  static const String unknownError = 'Неизвестная ошибка';
  static const String httpError = 'HTTP ERROR';
  static const String fiscalModuleIstConnected =
      'Фискальный модуль не подключен';

  // Fiscal Drive API errors
  static const String netwokError =
      'При регистрации чека возврата и при проверки информации об отозванном чеке (RefundInfo) возникла ошибка подключения к серверу ОФД. Повторите попытку.';
  static const String notValidRefund =
      'При регистрации чека возврата была передана информация об отозванном чеке (RefundInfo) с недействительным ФП';
  static const String illegalArgument =
      'Передан недействительный параметр в JSON.';
  static const String cannotConnectCard =
      'Не удалось подключится к ФМ, ФМ не подключен или не найден по указанному заводскому номеру.';
  static const String tryLater =
      'Другие ошибки. Подробности ошибки смотрите в лог файле сервиса FiscalDriveAPI.';
  static const String cannotSelectApplet =
      'Не удалось выбрать апплет в ФМ. Возможно в ФМ не был прошит апплетом или ФМ поврежден.';
  static const String cannotEncodeReceipt =
      'В переданном чеке есть ошибочные параметры, возможно не соблюдаются условия уравнения приведенные в разделе 10.2.1.';
  static const String cannotReadEncryptedRecaipt =
      'Не удалось декодировать ответ от ФМ, повторите попытку. Возможно ФМ поврежден.';
  static const String cannotSaveReceiptInStorage =
      'Ошибка при сохранении файла чека в БД, возможно файл БД поврежден.';
  static const String noRefundinfoPassed =
      'При регистрации чека возврата не была передана информация об отозванном чеке (RefundInfo)';
  static const String fiscalDriveFailure =
      'Сбой при вызове команды ФМ, повторите попытку.';
  static const String fiscalDriceLocked =
      'Сервер ОФД заблокировал принятия чеков от ФМ, обратитесь в ОФД. После разблокировки ФМ в ОФД, подождитеопределенное время (10 минут), затем перезапустите сервисFiscalDriveAPI для продолжения работы.';
  static const String cannotReadEncyptedZReport =
      'Не удалось декодировать ответ от ФМ, повторите попытку. Возможно ФМ поврежден.';
  static const String unsupportedAppletVersion =
      'Сервис FiscalDriveAPI не поддерживает версию апплета в ФМ, следует подключить новый ФМ с новым апплетом.';
  static const String badRefundInfoPassed =
      'При регистрации чека возврата была передана информация об отозванном чеке (RefundInfo) с неправильными значениями';
}
