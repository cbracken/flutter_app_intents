import 'package:flutter_test/flutter_test.dart';
import 'package:app_intents_plugin/app_intents_plugin.dart';
import 'package:app_intents_plugin/app_intents_plugin_platform_interface.dart';
import 'package:app_intents_plugin/app_intents_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppIntentsPluginPlatform
    with MockPlatformInterfaceMixin
    implements AppIntentsPluginPlatform {
  /// The handler most recently passed to [setIntentHandler], if any.
  OnIntentTriggeredCallback? handler;

  /// Titles received by [simulateAppIntent], in call order.
  final List<String> simulatedTitles = [];

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  void setIntentHandler(OnIntentTriggeredCallback handler) {
    this.handler = handler;
  }

  @override
  Future<String?> simulateAppIntent(String title) {
    simulatedTitles.add(title);
    return Future.value('Simulated: $title');
  }
}

void main() {
  // Required before touching AppIntentsPluginPlatform.instance: constructing the
  // default MethodChannelAppIntentsPlugin registers a method call handler, which
  // needs an initialized binary messenger.
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = AppIntentsPluginPlatform.instance;

  test('$MethodChannelAppIntentsPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppIntentsPlugin>());
  });

  group('delegates to the platform implementation', () {
    late AppIntentsPlugin appIntentsPlugin;
    late MockAppIntentsPluginPlatform fakePlatform;

    setUp(() {
      appIntentsPlugin = AppIntentsPlugin();
      fakePlatform = MockAppIntentsPluginPlatform();
      AppIntentsPluginPlatform.instance = fakePlatform;
    });

    tearDown(() {
      AppIntentsPluginPlatform.instance = initialPlatform;
    });

    test('getPlatformVersion', () async {
      expect(await appIntentsPlugin.getPlatformVersion(), '42');
    });

    test('setIntentHandler', () async {
      Map<dynamic, dynamic>? received;
      appIntentsPlugin.setIntentHandler((arguments) async {
        received = arguments;
        return 'handled';
      });

      expect(fakePlatform.handler, isNotNull);
      expect(await fakePlatform.handler!({'title': 'Buy milk'}), 'handled');
      expect(received, {'title': 'Buy milk'});
    });

    test('simulateAppIntent', () async {
      final result = await appIntentsPlugin.simulateAppIntent('Demo Task');

      expect(fakePlatform.simulatedTitles, ['Demo Task']);
      expect(result, 'Simulated: Demo Task');
    });
  });
}
