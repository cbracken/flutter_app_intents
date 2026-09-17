import CoreSpotlight
import Foundation
import os

/// Publishes tasks to the Spotlight index.
///
/// Indexing requires iOS 18 (`IndexedEntity` and `CSSearchableIndex.indexAppEntities`), so on
/// earlier versions this is a no-op and tasks remain reachable only through Siri and Shortcuts.
public enum SpotlightIndexer {
  private static let log = Logger(subsystem: "app_intents_plugin", category: "Spotlight")

  /// Replaces the indexed tasks with [tasks].
  ///
  /// This reindexes wholesale rather than diffing. That is fine at prototype scale, but with a
  /// large task list you would want to index only what changed.
  public static func reindex(_ tasks: [CachedTask]) async {
    guard #available(iOS 18.0, *) else {
      log.debug("Spotlight indexing of App Entities requires iOS 18; skipping.")
      return
    }
    let index = CSSearchableIndex.default()
    do {
      try await index.deleteAppEntities(ofType: FlutterTaskEntity.self)
      guard !tasks.isEmpty else { return }
      try await index.indexAppEntities(tasks.map(FlutterTaskEntity.init))
      log.debug("Indexed \(tasks.count) task(s) for Spotlight.")
    } catch {
      // Indexing is best effort: a failure must not fail the originating intent.
      log.error("Failed to index tasks: \(error.localizedDescription)")
    }
  }
}
