import Foundation

/// A task mirrored from Dart into native storage.
public struct CachedTask: Codable, Sendable, Identifiable {
  public let id: String
  public let title: String
  public let subtitle: String?

  public init(id: String, title: String, subtitle: String? = nil) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
  }

  /// Decodes a task from the method channel representation.
  ///
  /// Returns `nil` if the required fields are missing or of the wrong type.
  init?(channelRepresentation map: [String: Any]) {
    guard let id = map["id"] as? String, let title = map["title"] as? String else { return nil }
    self.id = id
    self.title = title
    self.subtitle = map["subtitle"] as? String
  }
}

/// The tasks Dart has published, stored where Siri and Spotlight can reach them.
///
/// Siri and Spotlight query entities while the app may not be running. Serving those queries by
/// calling back into Dart would mean starting a Flutter engine per keystroke, so Dart instead
/// pushes its task list here whenever it changes and queries read from this cache.
///
/// - Note: This uses `UserDefaults.standard`, which is sufficient while App Intents run in the
///   app's own process. Moving the intents into an extension would require an App Group suite.
public enum TaskCache {
  private static let key = "app_intents_plugin.tasks"

  /// The cached tasks, or an empty array if nothing has been published yet.
  public static func load() -> [CachedTask] {
    guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
    return (try? JSONDecoder().decode([CachedTask].self, from: data)) ?? []
  }

  /// Replaces the cache wholesale.
  public static func save(_ tasks: [CachedTask]) {
    guard let data = try? JSONEncoder().encode(tasks) else { return }
    UserDefaults.standard.set(data, forKey: key)
  }
}
