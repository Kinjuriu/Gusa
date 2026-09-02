/// Configuration for [HttpMessageSimplifier].
///
/// Values default to build-time environment variables (via
/// `--dart-define`) so no key is ever hardcoded or committed:
///
/// ```text
/// flutter run \
///   --dart-define=GUSA_AI_BASE_URL=https://your-proxy.example.com/v1 \
///   --dart-define=GUSA_AI_API_KEY=...
/// ```
///
/// Per SPEC.md §20/§22, production builds should point [baseUrl] at the
/// serverless proxy, never directly at OpenAI with a permanent key baked
/// into the APK. An empty [apiKey] (the default with no `--dart-define`)
/// means "no key configured" and [HttpMessageSimplifier] falls back to
/// [RuleBasedSimplifier] without attempting a network call.
class AiSimplifierConfig {
  const AiSimplifierConfig({
    this.baseUrl = const String.fromEnvironment(
      'GUSA_AI_BASE_URL',
      defaultValue: 'https://api.openai.com/v1',
    ),
    this.apiKey = const String.fromEnvironment('GUSA_AI_API_KEY'),
    this.model = const String.fromEnvironment(
      'GUSA_AI_MODEL',
      defaultValue: 'gpt-4o-mini',
    ),
    this.timeout = const Duration(seconds: 4),
  });

  /// Base URL of an OpenAI-compatible chat completions API (no trailing
  /// slash), e.g. `https://api.openai.com/v1` or a serverless proxy URL.
  final String baseUrl;

  /// API key sent as `Authorization: Bearer <apiKey>`. Empty means "not
  /// configured".
  final String apiKey;

  /// Chat model name.
  final String model;

  /// Max time to wait for a response before falling back to
  /// [RuleBasedSimplifier]. Kept short so a demo never hangs.
  final Duration timeout;

  bool get hasApiKey => apiKey.trim().isNotEmpty;
}
