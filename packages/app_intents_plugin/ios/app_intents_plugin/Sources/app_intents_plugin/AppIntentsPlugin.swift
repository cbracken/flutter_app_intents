import Flutter
import UIKit

public final class AppIntentsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "app_intents_plugin", binaryMessenger: registrar.messenger())
    let instance = AppIntentsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    // Publishing is required for `detachFromEngine(for:)` to be delivered.
    registrar.publish(instance)
    if #available(iOS 16.0, *) {
      // Plugin registration always occurs on the platform (main) thread.
      MainActor.assumeIsolated { AppIntentsBridge.shared.setMethodChannel(channel) }
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    if #available(iOS 16.0, *) {
      // Clear the channel so intents fail fast rather than invoking a dead engine.
      MainActor.assumeIsolated { AppIntentsBridge.shared.setMethodChannel(nil) }
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "simulateAppIntent":
      guard #available(iOS 16.0, *) else {
        result(FlutterError(code: "UNSUPPORTED_OS", message: "App Intents require iOS 16+", details: nil))
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      let title = args["title"] as? String ?? "Simulated Task"
      Task { @MainActor in
        do {
          let outcome = try await AddFlutterTaskIntent(title: title).perform()
          result(outcome.value ?? "Simulated success")
        } catch {
          result(FlutterError(code: "INTENT_ERROR", message: error.localizedDescription, details: nil))
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
