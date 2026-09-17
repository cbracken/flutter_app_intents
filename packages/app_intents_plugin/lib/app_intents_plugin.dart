import 'app_intent_task.dart';
import 'app_intents_plugin_platform_interface.dart';

export 'app_intent_task.dart';
export 'app_intents_plugin_platform_interface.dart'
    show OnIntentTriggeredCallback, OnOpenTaskCallback;

class AppIntentsPlugin {
  /// Ensures the Dart side is listening for App Intent invocations.
  ///
  /// Call this early in `main()`, before any intent can be delivered.
  ///
  /// [AppIntentsPluginPlatform.instance] is lazily constructed, and it is that
  /// construction which registers the method channel handler. Until something
  /// touches it, an intent arriving at a cold-started engine is answered with
  /// `FlutterMethodNotImplemented`, which the native side reports as a failure.
  static void ensureInitialized() {
    AppIntentsPluginPlatform.instance;
  }

  Future<String?> getPlatformVersion() {
    return AppIntentsPluginPlatform.instance.getPlatformVersion();
  }

  void setIntentHandler(OnIntentTriggeredCallback handler) {
    AppIntentsPluginPlatform.instance.setIntentHandler(handler);
  }

  /// Registers the callback invoked when a task is opened from Spotlight,
  /// Siri or Shortcuts.
  void setOpenTaskHandler(OnOpenTaskCallback handler) {
    AppIntentsPluginPlatform.instance.setOpenTaskHandler(handler);
  }

  Future<String?> simulateAppIntent(String title) {
    return AppIntentsPluginPlatform.instance.simulateAppIntent(title);
  }

  /// Mirrors [tasks] into the native cache and refreshes the Spotlight index.
  ///
  /// Siri and Spotlight query tasks while the app may not be running, so they
  /// read this cache rather than calling back into Dart. Call this whenever the
  /// task list changes; it replaces the cache wholesale.
  Future<void> syncTasks(List<AppIntentTask> tasks) {
    return AppIntentsPluginPlatform.instance.syncTasks(tasks);
  }
}
