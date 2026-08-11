import Flutter
import UIKit

public class AppIntentsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "app_intents_plugin", binaryMessenger: registrar.messenger())
    let instance = AppIntentsPlugin()
    if #available(iOS 16.0, *) {
      AppIntentsBridge.shared.setMethodChannel(channel)
    }
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "simulateAppIntent":
      if #available(iOS 16.0, *) {
        Task {
          do {
            let args = call.arguments as? [String: Any] ?? [:]
            let title = args["title"] as? String ?? "Simulated Task"
            let intent = AddFlutterTaskIntent(title: title)
            let res = try await intent.perform()
            result("Simulated success: \(res)")
          } catch {
            result(FlutterError(code: "INTENT_ERROR", message: error.localizedDescription, details: nil))
          }
        }
      } else {
        result(FlutterError(code: "UNSUPPORTED_OS", message: "App Intents require iOS 16+", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
