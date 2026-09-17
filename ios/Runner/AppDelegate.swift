import AppIntents
import Flutter
import UIKit
import app_intents_plugin

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

/// Opts the app in to the App Intents defined in the `app_intents_plugin` package.
///
/// App Intents metadata is extracted per module, so intents living in a Swift package are not
/// discovered by the system unless the app target lists that package here.
@available(iOS 17.0, *)
struct AppIntentsPrototypePackage: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] {
    [AppIntentsPluginPackage.self]
  }
}

/// Exposes the plugin's intents to Siri without the user having to build a shortcut first.
///
/// This must live in the app target. An `AppShortcutsProvider` declared inside the plugin package
/// is extracted into that package's metadata bundle but never reaches the app's App Shortcuts
/// registry, so the phrases would silently never register.
@available(iOS 16.0, *)
struct FlutterTaskShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddFlutterTaskIntent(),
      phrases: ["Add a task to \(.applicationName)"],
      shortTitle: "Add Task",
      systemImageName: "plus.circle"
    )
    AppShortcut(
      intent: OpenFlutterTaskIntent(),
      phrases: ["Open a task in \(.applicationName)"],
      shortTitle: "Open Task",
      systemImageName: "checklist"
    )
  }
}
