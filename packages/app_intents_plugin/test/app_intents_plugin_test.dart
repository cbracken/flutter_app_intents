import 'package:flutter_test/flutter_test.dart';
import 'package:app_intents_plugin/app_intents_plugin.dart';
import 'package:app_intents_plugin/app_intents_plugin_platform_interface.dart';
import 'package:app_intents_plugin/app_intents_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppIntentsPluginPlatform
    with MockPlatformInterfaceMixin
    implements AppIntentsPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final initialPlatform = AppIntentsPluginPlatform.instance;

  test('$MethodChannelAppIntentsPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppIntentsPlugin>());
  });

  test('getPlatformVersion', () async {
    AppIntentsPlugin appIntentsPlugin = AppIntentsPlugin();
    MockAppIntentsPluginPlatform fakePlatform = MockAppIntentsPluginPlatform();
    AppIntentsPluginPlatform.instance = fakePlatform;

    expect(await appIntentsPlugin.getPlatformVersion(), '42');
  });
}
