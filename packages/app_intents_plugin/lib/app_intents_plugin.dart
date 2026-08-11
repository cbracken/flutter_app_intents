import 'app_intents_plugin_platform_interface.dart';

export 'app_intents_plugin_platform_interface.dart' show OnIntentTriggeredCallback;

class AppIntentsPlugin {
  Future<String?> getPlatformVersion() {
    return AppIntentsPluginPlatform.instance.getPlatformVersion();
  }

  void setIntentHandler(OnIntentTriggeredCallback handler) {
    AppIntentsPluginPlatform.instance.setIntentHandler(handler);
  }

  Future<String?> simulateAppIntent(String title) {
    return AppIntentsPluginPlatform.instance.simulateAppIntent(title);
  }
}
