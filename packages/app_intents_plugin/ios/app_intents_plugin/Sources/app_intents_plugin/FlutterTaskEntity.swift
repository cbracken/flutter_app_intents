import AppIntents
import CoreSpotlight
import Foundation

/// A task in the Flutter application, exposed to Siri, Shortcuts and Spotlight.
///
/// Backed by ``TaskCache`` rather than by a live call into Dart, so it resolves even when the app
/// is not running.
@available(iOS 16.0, *)
public struct FlutterTaskEntity: AppEntity, Identifiable {
  public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Flutter Task"
  public static let defaultQuery = FlutterTaskQuery()

  public var id: String
  public var title: String
  public var subtitle: String?

  public var displayRepresentation: DisplayRepresentation {
    if let subtitle {
      DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    } else {
      DisplayRepresentation(title: "\(title)")
    }
  }

  public init(id: String, title: String, subtitle: String? = nil) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
  }

  public init(_ task: CachedTask) {
    self.init(id: task.id, title: task.title, subtitle: task.subtitle)
  }
}

/// Describes how a task appears in Spotlight.
///
/// Conformance is gated because `IndexedEntity` requires iOS 18. On earlier versions tasks are
/// still resolvable by Siri and Shortcuts through ``FlutterTaskQuery``; they simply are not
/// indexed for Spotlight search.
@available(iOS 18.0, *)
extension FlutterTaskEntity: IndexedEntity {
  public var attributeSet: CSSearchableItemAttributeSet {
    let attributes = defaultAttributeSet
    attributes.title = title
    attributes.contentDescription = subtitle
    // Lets Spotlight match individual words, not just a leading prefix of the title.
    attributes.keywords = title.split(separator: " ").map(String.init)
    return attributes
  }
}

/// Resolves `FlutterTaskEntity` values for Siri, Shortcuts and Spotlight.
///
/// Conforms to `EntityStringQuery` so free-text lookups ("open Buy milk") work; a plain
/// `EntityQuery` only supports lookup by identifier and a list of suggestions.
@available(iOS 16.0, *)
public struct FlutterTaskQuery: EntityStringQuery {
  public init() {}

  public func entities(for identifiers: [FlutterTaskEntity.ID]) async throws -> [FlutterTaskEntity] {
    let wanted = Set(identifiers)
    return TaskCache.load()
      .filter { wanted.contains($0.id) }
      .map(FlutterTaskEntity.init)
  }

  public func entities(matching string: String) async throws -> [FlutterTaskEntity] {
    TaskCache.load()
      .filter { $0.title.localizedCaseInsensitiveContains(string) }
      .map(FlutterTaskEntity.init)
  }

  public func suggestedEntities() async throws -> [FlutterTaskEntity] {
    TaskCache.load().map(FlutterTaskEntity.init)
  }
}
