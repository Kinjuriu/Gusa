import 'package:installed_apps/installed_apps.dart';

import 'app_launcher.dart';
import 'launcher_app.dart';

/// Real Android implementation of [AppLauncher], backed by the
/// `installed_apps` plugin.
///
/// Requires the `android.permission.QUERY_ALL_PACKAGES` manifest permission
/// (or an equivalent `<queries>` block) to see apps other than Gusa's own
/// package on Android 11+ — see the manifest note in the delivery report.
class AndroidAppLauncher implements AppLauncher {
  const AndroidAppLauncher();

  @override
  Future<List<LauncherApp>> getInstalledApps() async {
    final apps = await InstalledApps.getInstalledApps(true, false);
    return apps
        .map((app) =>
            LauncherApp(name: app.name, packageName: app.packageName))
        .toList();
  }

  @override
  Future<bool> launchApp(String packageName) async {
    final started = await InstalledApps.startApp(packageName);
    return started ?? false;
  }
}
