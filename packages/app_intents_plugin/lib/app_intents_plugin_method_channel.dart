import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_intents_plugin_platform_interface.dart';

/// An implementation of [AppIntentsPluginPlatform] that uses method channels.
class MethodChannelAppIntentsPlugin extends AppIntentsPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('app_intents_plugin');

  OnIntentTriggeredCallback? _onIntentTriggered;

  MethodChannelAppIntentsPlugin() {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAppIntentTriggered') {
        final args = call.arguments as Map<dynamic, dynamic>? ?? {};
        if (_onIntentTriggered != null) {
          return await _onIntentTriggered!(args);
        }
        return "Intent processed by Dart default handler";
      }
      return null;
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
  Future<String?> simulateAppIntent(String title) async {
    final res = await methodChannel.invokeMethod<String>('simulateAppIntent', {'title': title});
    return res;
  }
}
