import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/services/launcher/app_resolver.dart';
import 'package:gusa/services/launcher/launcher_app.dart';

void main() {
  const resolver = AppResolver();

  const whatsApp = LauncherApp(name: 'WhatsApp', packageName: 'com.whatsapp');
  const whatsAppBusiness = LauncherApp(
    name: 'WhatsApp Business',
    packageName: 'com.whatsapp.w4b',
  );
  const camera =
      LauncherApp(name: 'Camera', packageName: 'com.android.camera');
  const camScanner =
      LauncherApp(name: 'CamScanner', packageName: 'com.intsig.camscanner');
  const gmail =
      LauncherApp(name: 'Gmail', packageName: 'com.google.android.gm');

  group('exact match', () {
    final apps = [whatsApp, camera, gmail];

    test('single exact match requires no confirmation', () {
      final result = resolver.resolve('WhatsApp', apps);

      expect(result.matches, hasLength(1));
      expect(result.bestMatch!.app, whatsApp);
      expect(result.bestMatch!.confidence, AppMatchConfidence.exact);
      expect(result.bestMatch!.score, 1.0);
      expect(result.requiresConfirmation, isFalse);
    });

    test('command-word prefixes are stripped before matching', () {
      final result = resolver.resolve('open whatsapp', apps);

      expect(result.matches, hasLength(1));
      expect(result.bestMatch!.app, whatsApp);
      expect(result.bestMatch!.confidence, AppMatchConfidence.exact);
      expect(result.requiresConfirmation, isFalse);
    });
  });

  group('case-insensitive match', () {
    final apps = [whatsApp, camera, gmail];

    test('all-caps phrase still matches exactly', () {
      final result = resolver.resolve('WHATSAPP', apps);

      expect(result.matches, hasLength(1));
      expect(result.bestMatch!.app, whatsApp);
      expect(result.bestMatch!.confidence, AppMatchConfidence.exact);
      expect(result.requiresConfirmation, isFalse);
    });

    test('lowercase phrase still matches exactly', () {
      final result = resolver.resolve('whatsapp', apps);

      expect(result.matches, hasLength(1));
      expect(result.bestMatch!.app, whatsApp);
      expect(result.bestMatch!.confidence, AppMatchConfidence.exact);
      expect(result.requiresConfirmation, isFalse);
    });
  });

  group('partial / prefix match', () {
    final apps = [whatsApp, camera, gmail];

    test('short prefix resolves to the one app it can mean, but is not exact', () {
      final result = resolver.resolve('whats', apps);

      expect(result.matches, hasLength(1));
      expect(result.bestMatch!.app, whatsApp);
      expect(result.bestMatch!.confidence, AppMatchConfidence.high);
      expect(result.bestMatch!.score, lessThan(1.0));
      // Not an exact match -> a blind/deafblind user must confirm before we
      // launch the wrong app.
      expect(result.requiresConfirmation, isTrue);
    });
  });

  group('ambiguous match returns multiple candidates', () {
    test('a name that prefixes two installed apps returns both, ranked', () {
      final apps = [whatsApp, whatsAppBusiness, camera];
      final result = resolver.resolve('whatsapp', apps);

      expect(result.matches, hasLength(2));
      expect(result.matches.map((m) => m.app), [whatsApp, whatsAppBusiness]);
      expect(result.requiresConfirmation, isTrue);
    });

    test('two similarly-prefixed apps are both returned and best-ranked first', () {
      final apps = [camera, camScanner, gmail];
      final result = resolver.resolve('cam', apps);

      expect(result.matches, hasLength(2));
      expect(result.requiresConfirmation, isTrue);
      // Camera ("cam" is a larger fraction of "camera") should outrank
      // CamScanner.
      expect(result.matches.first.app, camera);
      expect(
        result.matches.first.score,
        greaterThanOrEqualTo(result.matches.last.score),
      );
    });
  });

  group('no match', () {
    final apps = [whatsApp, camera, gmail];

    test('a phrase matching nothing returns an empty, non-confirmable result', () {
      final result = resolver.resolve('nonexistentapp123', apps);

      expect(result.matches, isEmpty);
      expect(result.hasMatch, isFalse);
      expect(result.bestMatch, isNull);
      expect(result.requiresConfirmation, isFalse);
    });

    test('empty phrase returns no matches', () {
      final result = resolver.resolve('', apps);
      expect(result.matches, isEmpty);
    });

    test('empty app list returns no matches', () {
      final result = resolver.resolve('WhatsApp', const []);
      expect(result.matches, isEmpty);
    });
  });
}
