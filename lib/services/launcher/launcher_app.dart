/// A minimal, plugin-free representation of an installed, launchable app.
///
/// Kept deliberately small (name + package) so that [AppResolver] can stay
/// pure Dart with no Flutter/plugin dependency and be fully unit-tested.
class LauncherApp {
  const LauncherApp({required this.name, required this.packageName});

  /// Human-readable app name as shown to the user, e.g. "WhatsApp".
  final String name;

  /// Android package name, e.g. "com.whatsapp".
  final String packageName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LauncherApp &&
          other.packageName == packageName &&
          other.name == name);

  @override
  int get hashCode => Object.hash(name, packageName);

  @override
  String toString() => 'LauncherApp(name: $name, packageName: $packageName)';
}
