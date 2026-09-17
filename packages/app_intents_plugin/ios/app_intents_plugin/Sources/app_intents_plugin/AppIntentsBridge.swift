import Flutter
import Foundation

/// Errors thrown while bridging App Intents to Dart.
@available(iOS 16.0, *)
public enum AppIntentsBridgeError: Error, LocalizedError, CustomLocalizedStringResourceConvertible {
  /// No channel is registered. If the app was terminated, the Dart isolate may still be starting.
  case channelUnavailable

  /// Dart has no handler registered for this method.
  case methodNotImplemented(String)

  /// Dart replied with a `FlutterError`.
  ///
  /// The `FlutterError` is decomposed into its `code` and `message` rather than stored directly,
  /// so that this error remains `Sendable`.
  case dart(code: String, message: String?)

  /// Dart accepted the call but never replied.
  case replyTimedOut(String)

  public var errorDescription: String? {
    switch self {
    case .channelUnavailable:
      "The Flutter method channel is not available yet. If the app was terminated, the Dart isolate may still be starting."
    case .methodNotImplemented(let method):
      "Dart does not implement '\(method)'."
    case .dart(let code, let message):
      message ?? "Dart error: \(code)"
    case .replyTimedOut(let method):
      "Dart did not reply to '\(method)' in time."
    }
  }

  /// App Intents surfaces this text to Siri and Shortcuts when `perform()` throws.
  public var localizedStringResource: LocalizedStringResource {
    "\(errorDescription ?? "Unknown error")"
  }
}

/// Bridges Apple App Intents, which execute in cooperative async tasks, to the
/// `FlutterMethodChannel`, which must be used from the iOS main thread.
///
/// The channel may only be touched from the platform (main) thread, so the whole type is
/// `@MainActor`-isolated. That isolation is what makes `channel` race-free.
///
/// - Important: This assumes a single Flutter engine. The bridge holds one channel, so in a
///   multi-engine app the most recently registered engine wins and intents are routed to that
///   engine's isolate. Keying the bridge by engine would be required to support more than one.
@available(iOS 16.0, *)
@MainActor
public final class AppIntentsBridge {
  public static let shared = AppIntentsBridge()

  private var channel: FlutterMethodChannel?

  private init() {}

  /// Registers the channel used to reach Dart, or clears it (`nil`) on engine teardown.
  public func setMethodChannel(_ channel: FlutterMethodChannel?) {
    self.channel = channel
  }

  /// Invokes a Dart method over the `FlutterMethodChannel` and returns its reply.
  ///
  /// When an App Intent triggers while the app is backgrounded or terminated,
  /// FlutterAppDelegate / LaunchEngine creates a headless Dart engine. That engine may still be
  /// starting when the intent runs, so this waits up to `startupTimeout` for the channel to be
  /// registered before giving up.
  ///
  /// Dart is then given `replyTimeout` to respond. Without that bound, a Dart handler that never
  /// completes would suspend the calling intent indefinitely.
  ///
  /// - Returns: The reply, or `nil` if Dart replied with `null` or with a value that is not a `T`.
  /// - Throws: ``AppIntentsBridgeError`` if the channel never becomes available, the method is
  ///   unimplemented in Dart, Dart replied with an error, or Dart did not reply in time.
  public func invokeMethod<T: Sendable>(
    _ method: String,
    arguments: [String: any Sendable] = [:],
    startupTimeout: Duration = .seconds(5),
    replyTimeout: Duration = .seconds(30)
  ) async throws -> T? {
    let channel = try await channel(waitingUpTo: startupTimeout)
    return try await withCheckedThrowingContinuation { continuation in
      // The reply and the timeout race; whichever lands first wins.
      let once = SingleResume<T?>(continuation)
      let deadline = Task { @MainActor in
        try? await Task.sleep(for: replyTimeout)
        guard !Task.isCancelled else { return }
        once.resume(throwing: AppIntentsBridgeError.replyTimedOut(method))
      }
      channel.invokeMethod(method, arguments: arguments) { reply in
        // Channels created without a task queue deliver replies on the platform (main) thread.
        MainActor.assumeIsolated {
          deadline.cancel()
          switch reply {
          case let error as FlutterError:
            once.resume(
              throwing: AppIntentsBridgeError.dart(code: error.code, message: error.message))
          case let object as NSObject where object === FlutterMethodNotImplemented:
            once.resume(throwing: AppIntentsBridgeError.methodNotImplemented(method))
          default:
            once.resume(returning: reply as? T)
          }
        }
      }
    }
  }

  /// Returns the channel, waiting up to `timeout` for plugin registration to complete.
  private func channel(waitingUpTo timeout: Duration) async throws -> FlutterMethodChannel {
    let deadline = ContinuousClock.now + timeout
    while channel == nil, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    guard let channel else { throw AppIntentsBridgeError.channelUnavailable }
    return channel
  }
}

/// Resumes a continuation exactly once, ignoring any later attempts.
///
/// Resuming a continuation twice is undefined behaviour, so racing a reply against a timeout
/// needs a guard. Main-actor isolation is what makes the check-and-clear atomic.
@available(iOS 16.0, *)
@MainActor
private final class SingleResume<T> {
  private var continuation: CheckedContinuation<T, any Error>?

  init(_ continuation: CheckedContinuation<T, any Error>) {
    self.continuation = continuation
  }

  func resume(returning value: T) {
    continuation?.resume(returning: value)
    continuation = nil
  }

  func resume(throwing error: any Error) {
    continuation?.resume(throwing: error)
    continuation = nil
  }
}
