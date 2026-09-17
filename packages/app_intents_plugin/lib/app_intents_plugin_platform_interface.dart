import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'app_intent_task.dart';
import 'app_intents_plugin_method_channel.dart';

typedef OnIntentTriggeredCallback = Future<String> Function(Map<dynamic, dynamic> arguments);

/// Invoked when the user opens a task from Spotlight, Siri or Shortcuts.
typedef OnOpenTaskCallback = Future<void> Function(String id);

abstract class AppIntentsPluginPlatform extends PlatformInterface {
  /// Constructs a AppIntentsPluginPlatform.
  AppIntentsPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppIntentsPluginPlatform _instance = MethodChannelAppIntentsPlugin();

  /// The default instance of [AppIntentsPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelAppIntentsPlugin].
  static AppIntentsPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppIntentsPluginPlatform] when
  /// they register themselves.
  static set instance(AppIntentsPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  void setIntentHandler(OnIntentTriggeredCallback handler) {
    throw UnimplementedError('setIntentHandler() has not been implemented.');
  }

  void setOpenTaskHandler(OnOpenTaskCallback handler) {
    throw UnimplementedError('setOpenTaskHandler() has not been implemented.');
  }

  Future<String?> simulateAppIntent(String title) {
    throw UnimplementedError('simulateAppIntent() has not been implemented.');
  }

  Future<void> syncTasks(List<AppIntentTask> tasks) {
    throw UnimplementedError('syncTasks() has not been implemented.');
  }
}
