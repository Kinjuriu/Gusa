import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/services/ai/ai_simplifier_config.dart';
import 'package:gusa/services/ai/http_message_simplifier.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const configuredWithKey = AiSimplifierConfig(
    baseUrl: 'https://example.test/v1',
    apiKey: 'test-key',
    model: 'test-model',
    timeout: Duration(milliseconds: 200),
  );

  test('no API key configured -> falls back to rule-based without any HTTP call',
      () async {
    final client = MockClient((request) async {
      fail('HTTP client should not be called when no API key is configured');
    });
    final simplifier = HttpMessageSimplifier(
      client: client,
      config: const AiSimplifierConfig(apiKey: ''),
    );

    final result = await simplifier.simplify('Would you like to attend?');

    expect(result, isNotEmpty);
    expect(result, endsWith('?'));
  });

  test('HTTP failure falls back to rule-based and does not throw', () async {
    final client = MockClient((request) async {
      throw http.ClientException('connection refused');
    });
    final simplifier = HttpMessageSimplifier(
      client: client,
      config: configuredWithKey,
    );

    final result = await simplifier.simplify('Would you like to attend?');

    expect(result, isNotEmpty);
    expect(result, endsWith('?'));
  });

  test('timeout falls back to rule-based and does not throw', () async {
    final client = MockClient((request) async {
      await Future<void>.delayed(const Duration(seconds: 5));
      return http.Response('{}', 200);
    });
    final simplifier = HttpMessageSimplifier(
      client: client,
      config: configuredWithKey,
    );

    final result =
        await simplifier.simplify('Would you like to attend the event?');

    expect(result, isNotEmpty);
    expect(result, endsWith('?'));
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('non-200 response falls back to rule-based', () async {
    final client = MockClient((request) async {
      return http.Response('server error', 500);
    });
    final simplifier = HttpMessageSimplifier(
      client: client,
      config: configuredWithKey,
    );

    final result = await simplifier.simplify('Call me back later please');

    expect(result, isNotEmpty);
  });

  test('malformed JSON body falls back to rule-based without throwing',
      () async {
    final client = MockClient((request) async {
      return http.Response('not json at all {{{', 200);
    });
    final simplifier = HttpMessageSimplifier(
      client: client,
      config: configuredWithKey,
    );

    final result = await simplifier.simplify('Call me back later please');

    expect(result, isNotEmpty);
  });

  test('unexpected JSON shape falls back to rule-based without throwing',
      () async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'unexpected': 'shape'}), 200);
    });
    final simplifier = HttpMessageSimplifier(
      client: client,
      config: configuredWithKey,
    );

    final result = await simplifier.simplify('Call me back later please');

    expect(result, isNotEmpty);
  });

  test('empty input returns empty output without calling the network',
      () async {
    final client = MockClient((request) async {
      fail('HTTP client should not be called for empty input');
    });
    final simplifier = HttpMessageSimplifier(
      client: client,
      config: configuredWithKey,
    );

    final result = await simplifier.simplify('   ');

    expect(result, isEmpty);
  });

  test('a valid 200 response returns the AI-provided content', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(),
          'https://example.test/v1/chat/completions');
      expect(request.headers['Authorization'], 'Bearer test-key');

      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': 'EVENT TOMORROW.\nATTEND?'}
            }
          ]
        }),
        200,
      );
    });
    final simplifier = HttpMessageSimplifier(
      client: client,
      config: configuredWithKey,
    );

    final result = await simplifier
        .simplify('Would you like to attend the event tomorrow?');

    expect(result, 'EVENT TOMORROW.\nATTEND?');
  });
}
