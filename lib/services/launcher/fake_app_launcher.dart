import 'app_launcher.dart';
import 'launcher_app.dart';

/// In-memory [AppLauncher] for tests. No plugin channel, no device.
class FakeAppLauncher implements AppLauncher {
  FakeAppLauncher({List<LauncherApp> apps = const []})
      : _apps = List<LauncherApp>.from(apps);

  final List<LauncherApp> _apps;

  /// Package names passed to [launchApp], in call order.
  final List<String> launchedPackages = [];

  /// When set, [launchApp] returns this instead of "package exists".
  bool? launchResultOverride;

  @override
  Future<List<LauncherApp>> getInstalledApps() async => List.of(_apps);

  @override
  Future<bool> launchApp(String packageName) async {
    launchedPackages.add(packageName);
    if (launchResultOverride != null) return launchResultOverride!;
    return _apps.any((app) => app.packageName == packageName);
  }
}
