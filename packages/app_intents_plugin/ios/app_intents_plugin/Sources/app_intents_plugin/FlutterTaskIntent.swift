import AppIntents
import Foundation
import Flutter

/// Thread-safe bridge connecting Apple App Intents (executing in cooperative async tasks),
/// to the FlutterMethodChannel, which must execute on the iOS main thread.
@available(iOS 16.0, *)
public class AppIntentsBridge: @unchecked Sendable {
  public static let shared = AppIntentsBridge()

  private var channel: FlutterMethodChannel?

  private init() {}

  public func setMethodChannel(_ channel: FlutterMethodChannel) {
    self.channel = channel
  }

  /// Invokes a Dart method over the FlutterMethodChannel on the main thread.
  ///
  /// When an App Intent triggers while the app is backgrounded or terminated,
  /// FlutterAppDelegate / LaunchEngine creates a headless Dart engine.
  @MainActor
  public func invokeOnMainActor(method: String, arguments: [String: Any]) async throws -> Any? {
    guard let channel = channel else {
      throw NSError(
        domain: "AppIntentsBridge",
        code: -1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "FlutterMethodChannel is not initialized. If the app was terminated, LaunchEngine is still starting the Dart isolate."
        ]
      )
    }
    return try await withCheckedThrowingContinuation { continuation in
      channel.invokeMethod(method, arguments: arguments) { result in
        if let error = result as? FlutterError {
          continuation.resume(
            throwing: NSError(
              domain: "FlutterError",
              code: -2,
              userInfo: [NSLocalizedDescriptionKey: error.message ?? "Unknown Flutter Error"]
            )
          )
        } else if (result as? NSObject) == FlutterMethodNotImplemented {
          continuation.resume(
            throwing: NSError(
              domain: "FlutterError",
              code: -3,
              userInfo: [NSLocalizedDescriptionKey: "Method not implemented in Dart"]
            )
          )
        } else {
          continuation.resume(returning: result)
        }
      }
    }
  }
}

/// A sample App Entity representing a task/item in the Flutter application.
@available(iOS 16.0, *)
public struct FlutterTaskEntity: AppEntity, Identifiable {
  public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Flutter Task"
  public static var defaultQuery = FlutterTaskQuery()

  public var id: String
  public var title: String

  public var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(title)")
  }

  public init(id: String, title: String) {
    self.id = id
    self.title = title
  }
}

/// A sample EntityQuery for finding and suggesting `FlutterTaskEntity` items.
@available(iOS 16.0, *)
public struct FlutterTaskQuery: EntityQuery {
  public init() {}

  public func entities(for identifiers: [FlutterTaskEntity.ID]) async throws -> [FlutterTaskEntity] {
    return identifiers.map { FlutterTaskEntity(id: $0, title: "Task \($0)") }
  }

  public func suggestedEntities() async throws -> [FlutterTaskEntity] {
    return [
      FlutterTaskEntity(id: "1", title: "Review Flutter iOS Embedder"),
      FlutterTaskEntity(id: "2", title: "Test Apple App Intents Plugin")
    ]
  }
}

/// A sample App Intent testing integration between Apple App Intents and Flutter Dart code.
///
/// Demonstrates how to register an App Intent, do parameter handling, and how `perform()` invokes
/// Dart code via `AppIntentsBridge`.
@available(iOS 16.0, *)
public struct AddFlutterTaskIntent: AppIntent {
  public static var title: LocalizedStringResource = "Add Flutter Task"
  public static var description = IntentDescription("Adds a task to the Flutter application via App Intents.")
  public static var openAppWhenRun: Bool = false

  @Parameter(title: "Task Title", default: "New Flutter Task")
  public var title: String

  public init() {}

  public init(title: String) {
    self.title = title
  }

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let res = try await AppIntentsBridge.shared.invokeOnMainActor(
      method: "onAppIntentTriggered",
      arguments: ["intent": "AddFlutterTask", "title": title]
    )
    let resultString = (res as? String) ?? "Task '\(title)' added via Flutter engine"
    return .result(value: resultString)
  }
}
