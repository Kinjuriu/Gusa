import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_simplifier_config.dart';
import 'message_simplifier.dart';
import 'rule_based_simplifier.dart';

/// Calls an OpenAI-compatible `/chat/completions` endpoint to simplify
/// [spokenText] into short, tactile-friendly text.
///
/// Always falls back to [RuleBasedSimplifier] — never throws, never hangs —
/// when:
/// - no API key is configured ([AiSimplifierConfig.hasApiKey] is false),
/// - the request times out ([AiSimplifierConfig.timeout], ~4s by default),
/// - the request fails (network error, non-200 status), or
/// - the response body is not in the expected shape.
///
/// This guarantees a demo running with no network/API key still produces
/// usable output instead of hanging or throwing.
class HttpMessageSimplifier implements MessageSimplifier {
  HttpMessageSimplifier({
    http.Client? client,
    AiSimplifierConfig config = const AiSimplifierConfig(),
    MessageSimplifier? fallback,
  })  : _client = client ?? http.Client(),
        _config = config,
        _fallback = fallback ?? const RuleBasedSimplifier();

  final http.Client _client;
  final AiSimplifierConfig _config;
  final MessageSimplifier _fallback;

  static const String _systemPrompt =
      'You convert spoken sentences into extremely short, tactile-friendly '
      'text for a blind/deafblind user who reads it via Braille vibration. '
      'Reply with ONLY the simplified text, nothing else: at most 2 short '
      'lines separated by a newline, plain concrete words, uppercase, no '
      'markdown.';

  @override
  Future<String> simplify(String spokenText) async {
    if (spokenText.trim().isEmpty) return '';
    if (!_config.hasApiKey) {
      return _fallback.simplify(spokenText);
    }

    try {
      final uri = Uri.parse('${_config.baseUrl}/chat/completions');
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_config.apiKey}',
            },
            body: jsonEncode({
              'model': _config.model,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': spokenText},
              ],
              'max_tokens': 60,
              'temperature': 0.2,
            }),
          )
          .timeout(_config.timeout);

      if (response.statusCode != 200) {
        return _fallback.simplify(spokenText);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _fallback.simplify(spokenText);
      }

      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        return _fallback.simplify(spokenText);
      }

      final firstChoice = choices.first;
      if (firstChoice is! Map<String, dynamic>) {
        return _fallback.simplify(spokenText);
      }

      final message = firstChoice['message'];
      final content =
          message is Map<String, dynamic> ? message['content'] : null;

      if (content is! String || content.trim().isEmpty) {
        return _fallback.simplify(spokenText);
      }

      return content.trim();
    } on TimeoutException {
      return _fallback.simplify(spokenText);
    } catch (_) {
      // Any network/parse failure falls back rather than propagating —
      // a demo must never hang or crash on a bad connection.
      return _fallback.simplify(spokenText);
    }
  }
}
