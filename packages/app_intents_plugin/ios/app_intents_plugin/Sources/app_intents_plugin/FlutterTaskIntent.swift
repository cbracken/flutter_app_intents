import AppIntents
import Foundation

/// A sample App Intent testing integration between Apple App Intents and Flutter Dart code.
///
/// Demonstrates how to register an App Intent, do parameter handling, and how `perform()` invokes
/// Dart code via `AppIntentsBridge`.
@available(iOS 16.0, *)
public struct AddFlutterTaskIntent: AppIntent {
  public static let title: LocalizedStringResource = "Add Flutter Task"
  public static let description = IntentDescription("Adds a task to the Flutter application via App Intents.")
  public static let openAppWhenRun: Bool = false

  @Parameter(title: "Task Title", default: "New Flutter Task")
  public var title: String

  public init() {}

  public init(title: String) {
    self.title = title
  }

  // Deliberately not `@MainActor`: `AppIntentsBridge` is main-actor isolated and hops on its own,
  // so the intent doesn't occupy the main thread while Dart is working.
  public func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let reply: String? = try await AppIntentsBridge.shared.invokeMethod(
      "onAppIntentTriggered",
      arguments: ["intent": "AddFlutterTask", "title": title]
    )
    return .result(value: reply ?? "Task '\(title)' added via Flutter engine")
  }
}

/// Opens a task in the Flutter application.
///
/// Conforming to `OpenIntent` is what gives Spotlight results and Siri something to do when the
/// user taps a task: the system foregrounds the app, then `perform()` tells Dart which task to
/// show. `openAppWhenRun` is supplied by `OpenIntent` and is always `true`.
@available(iOS 16.0, *)
public struct OpenFlutterTaskIntent: OpenIntent {
  public static let title: LocalizedStringResource = "Open Flutter Task"
  public static let description = IntentDescription("Opens a task in the Flutter application.")

  @Parameter(title: "Task")
  public var target: FlutterTaskEntity

  public init() {}

  public init(target: FlutterTaskEntity) {
    self.target = target
  }

  public func perform() async throws -> some IntentResult {
    let _: String? = try await AppIntentsBridge.shared.invokeMethod(
      "onOpenTask",
      arguments: ["id": target.id]
    )
    return .result()
  }
}

/// Makes the intents in this package discoverable by the system.
///
/// App Intents metadata is extracted per module, so intents defined in a Swift package are
/// invisible unless the app target opts in. The app declares its own `AppIntentsPackage` listing
/// this type in `includedPackages`. Requires iOS 17.
///
/// - Note: Intents and entities propagate to the app this way, but an `AppShortcutsProvider` does
///   not: one declared here lands in this package's metadata bundle and never reaches the app's
///   App Shortcuts registry. Siri phrases must therefore be declared in the app target.
@available(iOS 17.0, *)
public struct AppIntentsPluginPackage: AppIntentsPackage {
  public init() {}
}
