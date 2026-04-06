class PrefKeys {
  const PrefKeys._();

  static const String deviceInfo = "device_info";
  static const String language = 'language_key';
  static const String theme = 'app_theme_pref_key';
  static const String doubleReceipt = 'double_receipt';

  static const String isAutoSyncActive = 'is_auto_sync_active';
  static const String autoSyncInterval = 'auto_sync_interval';
  static const String macAddress = 'current_comp_mac_address';
  static const String restaurantReceiptNo = 'restaReceiptNo';

  static const String token = 'current_token_for_headers';
  static const String activatedPosId = 'current_activated_pos_id';
  static const String acceptService = 'current_store_service';
  static const String serialNumber = 'serialNumber';

  static const String organization = 'current_organization';
  static const String currentShiftKey = 'curents_shift_key';
  static const String successToTelegram = "success_to_telegram";
  static const String locationSwitch = 'locationSwitch';

  static const String lat = "lat";
  static const String long = "long";

  static const String latLocal = "Localat";
  static const String longLocal = "Localong";

  static const String mesUnitId = "mesUnitId";
  static const String vatUnitId = "vatUnitId";

  static const String serviceAddress = 'service_address';
  static const String comName = 'comName';
  static const String withINCOM = 'with_incom';

  static const String posName = 'current_pos_name';
  static const String storeName = 'current_store_name';
  static const String transfer = "transfer_creat";
  static const String storeAddress = 'storeAddress';
  static const String storePhoneNum = 'storePhoneNum';
  static const String storeId = 'current_store_id';

  static const String cashierName = 'current_cashier_name';
  static const String employeeCanApplyDiscounOnItemPrice =
      'employee_can_apply_discoun_on_item_price';
  static const String employeeCanApplyDiscountOnTotalPrice =
      'employee_can_apply_discount_on_total_price';

  static const String userId = 'user_id';
  static const String cashierId = 'current_cashier_id';
  static const String authenticationBool = 'authentication_bool';
  static const String shiftsOpened = 'shift_opened';

  static const String shiftOpenedTime = "shift_opened_time";
  static const String receiptNo = 'receipt_number';
  static const String checkId = 'check_id';

  static const String taroziPrefix = 'prefix_for_tarozi';
  static const String homePageSwipeInt = 'home_page_swipe_int';
  static const String withOFD = 'with_ofd';
  static const String preCheck = 'pre_check';

  static const String thanks = "thanks";
  static const String greeting = "greeting";
  static const String orgID = "orgID";
  static const String organizationName = "organization_name";
  static const String organizationINN = "organization_inn";
  static const String lastSyncTime = "get_last-update";
  static const String lastSyncDate = "get_last-update_date";
  static const String lastSyncTimeChanged = "get_last-changet";
  static const String organizationModel = 'organization_model';
  static const String companyActive = 'company_active';
  static const String autoGenerate = 'auto_generate';
  static const String markCheckWithOfd = 'mark_check_with_ofd';

  static const String orgINITIALIZED = "org_INITIALIZED";
  static const String isDarkMode = "is_dark_mode";
  static const String isSendToTelegram = "is_send_tg";
  static const String isDevAlice = "is_dev_alice";
  static const String isRedDeleteActivated = "is_red_delete_activated";

  static const String appClosedTime = "app_closed_time";
  static const String isFirstTime = "is_first_time";

  ////////// DEBT CLICK ////////////////////////
  static const String debtClick = "debt_click";

  ////////// PAYMENT ENABLED ////////////////////////
  static const String cardEnabled = "card_enabled";
  static const String cashbackEnable = "cashbackEnable";

  static const String clickEnable = "clickEnable";
  static const String uzumEnable = "uzumEnable";
  static const String paymeEnable = "paymeEnable";

  static const String cashEnabled = "cash_enabled";
  static const String giftEnabled = "gift_enabled";
  static const String debtEnabled = "debt_enabled";
  static const String nfcEnabled = "ntf_enabled";

  ////////// PAYMENT ENABLED ////////////////////////
  static const String cardId = "card_Id";
  static const String cashbackId = "cashbackId";
  static const String cashId = "cash_Id";

  static const String clickId = "clickId";
  static const String uzumId = "uzumId";
  static const String paymeId = "paymeId";

  static const String giftId = "gift_Id";
  static const String debtId = "debt_Id";
  static const String nfcId = "ntf_Id";

  ////////// CLICK PASS  //////////////////////////
  static const String serviceId = 'service_id';
  static const String merchantId = 'merchant_id';
  static const String secretKeyOfClick = 'secret_key_click';
  static const String merchantUserId = 'merchant_user_id';

  ////////////////////////////////////////////////
  static const String paymeGoMerchantId = "payme_go_merchant_id";
  static const String paymeGoPassword = "payme_go_kassa_password";

  ////////////////////////////////////////////////
  static const String isHumoEnabled = 'is_humo_enabled';
  static const String doubleHumoReceipt = 'double_humo_receipt';

  ////////////////////////////////////////////////
  static const String isUzcardEnabled = 'is_uzcard_enabled';

  static const String isClickPassActivated = 'is_click_pass_activated';
  static const String isPaymegoActivated = 'is_payme_go_activated';
  static const String checkNo = "check_no";
  static const String selectedIntervalIndexOfAutoSync =
      "selected_interval_index_of_auto_sync";
  static const String virtualKeyboard = "virtual_keyboard";
  static const String printerRequired = "printer_required";

  ////////////////////////////////////////////////
  static const String companyResipt = "company_resipt";
  static const String companyNameDialog = "company_name_dialog";

  ////////////////
  static const String terminalID = "terminalID";
  static const String isSwitchTerminal = "isSwitchTerminal";

  static const String innLength = "innLength";

////////////
  static const String chequeId = "chequeId";
  static const String storeNameRD = "storeNameRD";
  static const String storeAddressRD = "storeAddressRD";
  static const String phoneNumberRD = "phoneNumberRD";
  static const String dateRD = "dateRD";
  static const String cashierRD = "cashierRD";
  static const String customerRD = "customerRD";
  static const String transactionRD = "transactionRD";

  //////////////
  static const String discountPercentageId = "discountPercentageId";
  static const String discountDefaultId = "discountDefaultId";
  static const String discountAmountId = "discountAmountId";

////////////
  static const String cashBeckCC = "cashBeckCC";
  static const String flatRate = "flatRate";

  static const String mxikCode = 'mxik_code';
  static const String packageCode = 'package_code';

  static const String openedDate = 'opened_date';
  static const String closedDate = 'closed_date';
  static const String openedCount = 'opened_count';
  static const String closedCount = 'closed_count';

  static const String version = 'version';
  static const String companyAppsFetched = 'companyAppsFetched';
  static const String sellProductsWithMarking = 'sellProductsWithMarking';
  static const String isCashDisableForAlcohol = 'isCashDisableForAlcohol';



}
