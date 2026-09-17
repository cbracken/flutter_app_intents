import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_intent_task.dart';
import 'app_intents_plugin_platform_interface.dart';

/// An implementation of [AppIntentsPluginPlatform] that uses method channels.
class MethodChannelAppIntentsPlugin extends AppIntentsPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('app_intents_plugin');

  OnIntentTriggeredCallback? _onIntentTriggered;
  OnOpenTaskCallback? _onOpenTask;

  MethodChannelAppIntentsPlugin() {
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAppIntentTriggered':
          final args = call.arguments as Map<dynamic, dynamic>? ?? {};
          final handler = _onIntentTriggered;
          if (handler != null) {
            return await handler(args);
          }
          return 'Intent processed by Dart default handler';
        case 'onOpenTask':
          final args = call.arguments as Map<dynamic, dynamic>? ?? {};
          final id = args['id'] as String?;
          if (id == null) {
            throw PlatformException(
              code: 'INVALID_ARGUMENTS',
              message: 'onOpenTask requires an "id" argument',
            );
          }
          await _onOpenTask?.call(id);
          return null;
        default:
          // Surfaces as FlutterMethodNotImplemented on the native side, rather
          // than a null reply that Swift would read as success.
          throw MissingPluginException(
            '${call.method} is not implemented by app_intents_plugin',
          );
      }
    });
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  void setIntentHandler(OnIntentTriggeredCallback handler) {
    _onIntentTriggered = handler;
  }

  @override
  void setOpenTaskHandler(OnOpenTaskCallback handler) {
    _onOpenTask = handler;
  }

  @override
  Future<String?> simulateAppIntent(String title) async {
    final res = await methodChannel.invokeMethod<String>('simulateAppIntent', {'title': title});
    return res;
  }

  @override
  Future<void> syncTasks(List<AppIntentTask> tasks) async {
    await methodChannel.invokeMethod<void>('syncTasks', {
      'tasks': tasks.map((task) => task.toMap()).toList(),
    });
  }
}
