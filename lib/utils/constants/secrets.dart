/// Build-time secrets injected via `--dart-define` flags.
///
/// On CI these come from GitHub Actions repository secrets.
/// For local development pass them with:
///   flutter run --dart-define=TELEGRAM_BOT_TOKEN=xxx --dart-define=...
/// or configure them in .vscode/launch.json (not committed).
class Secrets {
  static const String telegramBotToken = String.fromEnvironment(
    'TELEGRAM_BOT_TOKEN',
    defaultValue: '',
  );

  static const String telegramChannelId = String.fromEnvironment(
    'TELEGRAM_CHANNEL_ID',
    defaultValue: '',
  );

  static const String fiscalApiToken = String.fromEnvironment(
    'FISCAL_API_TOKEN',
    defaultValue: '',
  );
}
