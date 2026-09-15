import AppIntents
import Foundation

/// A sample App Entity representing a task/item in the Flutter application.
@available(iOS 16.0, *)
public struct FlutterTaskEntity: AppEntity, Identifiable {
  public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Flutter Task"
  public static let defaultQuery = FlutterTaskQuery()

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
    identifiers.map { FlutterTaskEntity(id: $0, title: "Task \($0)") }
  }

  public func suggestedEntities() async throws -> [FlutterTaskEntity] {
    [
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
