import 'package:flutter_test/flutter_test.dart';
import 'package:gusa/services/launcher/fake_app_launcher.dart';
import 'package:gusa/services/launcher/launcher_app.dart';

void main() {
  const whatsApp = LauncherApp(name: 'WhatsApp', packageName: 'com.whatsapp');

  test('getInstalledApps returns the configured fixture apps', () async {
    final launcher = FakeAppLauncher(apps: const [whatsApp]);

    final apps = await launcher.getInstalledApps();

    expect(apps, [whatsApp]);
  });

  test('launchApp records the call and reports success for a known package',
      () async {
    final launcher = FakeAppLauncher(apps: const [whatsApp]);

    final launched = await launcher.launchApp('com.whatsapp');

    expect(launched, isTrue);
    expect(launcher.launchedPackages, ['com.whatsapp']);
  });

  test('launchApp reports failure for an unknown package', () async {
    final launcher = FakeAppLauncher(apps: const [whatsApp]);

    final launched = await launcher.launchApp('com.unknown.app');

    expect(launched, isFalse);
  });
}
