import 'launcher_app.dart';

/// Enumerates installed apps and launches them by package name.
///
/// Real work happens in [AndroidAppLauncher] (a thin plugin wrapper).
/// Tests use [FakeAppLauncher] so no device/plugin channel is required.
abstract class AppLauncher {
  /// Returns the list of installed, launchable apps on the device.
  Future<List<LauncherApp>> getInstalledApps();

  /// Launches the app with the given [packageName].
  ///
  /// Returns `true` if the launch was requested successfully, `false`
  /// otherwise. Never throws for an ordinary "could not launch" failure.
  Future<bool> launchApp(String packageName);
}
