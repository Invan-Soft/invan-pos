class ReturnFiscalMessage {
  static Map sendError(dynamic message, {bool mxikError = false}) => {
        "error": true,
        "message": message,
        "mxik_error": mxikError,
      };

  static Map sendSuccess() => {
        "error": false,
        "message": "SUCCESS",
      };
}
