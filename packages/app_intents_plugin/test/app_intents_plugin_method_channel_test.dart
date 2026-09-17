import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_intents_plugin/app_intent_task.dart';
import 'package:app_intents_plugin/app_intents_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('app_intents_plugin');
  const StandardMethodCodec codec = StandardMethodCodec();

  late MethodChannelAppIntentsPlugin platform;

  /// Delivers [call] to the plugin the way the native side would, and returns
  /// the raw reply so tests can inspect the envelope.
  Future<ByteData?> sendFromNative(MethodCall call) {
    return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          codec.encodeMethodCall(call),
          null,
        );
  }

  setUp(() {
    // A fresh instance per test, so the intent handler registered by one test
    // does not leak into the next.
    platform = MethodChannelAppIntentsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('simulateAppIntent', () async {
    expect(await platform.simulateAppIntent('Demo Task'), '42');
  });

  test('syncTasks encodes tasks for the native cache', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          return null;
        });

    await platform.syncTasks(const [
      AppIntentTask(id: 'task-1', title: 'Buy milk'),
      AppIntentTask(id: 'task-2', title: 'Walk dog', subtitle: 'Before noon'),
    ]);

    // The Swift decoder reads these exact keys, so the shape is part of the
    // contract, not an implementation detail.
    expect(calls.single.method, 'syncTasks');
    expect(calls.single.arguments, {
      'tasks': [
        {'id': 'task-1', 'title': 'Buy milk', 'subtitle': null},
        {'id': 'task-2', 'title': 'Walk dog', 'subtitle': 'Before noon'},
      ],
    });
  });

  group('incoming onAppIntentTriggered', () {
    test('routes to the registered handler', () async {
      Map<dynamic, dynamic>? received;
      platform.setIntentHandler((arguments) async {
        received = arguments;
        return 'handled by test';
      });

      final reply = await sendFromNative(
        const MethodCall('onAppIntentTriggered', {'title': 'Buy milk'}),
      );

      expect(received, {'title': 'Buy milk'});
      expect(codec.decodeEnvelope(reply!), 'handled by test');
    });

    test('falls back to the default handler when none is registered', () async {
      final reply = await sendFromNative(
        const MethodCall('onAppIntentTriggered', {'title': 'Buy milk'}),
      );

      expect(codec.decodeEnvelope(reply!), 'Intent processed by Dart default handler');
    });

    test('tolerates missing arguments', () async {
      Map<dynamic, dynamic>? received;
      platform.setIntentHandler((arguments) async {
        received = arguments;
        return 'ok';
      });

      await sendFromNative(const MethodCall('onAppIntentTriggered'));

      expect(received, isEmpty);
    });
  });

  test('an unknown method reports not-implemented', () async {
    final reply = await sendFromNative(const MethodCall('noSuchMethod'));

    // A null reply is how MissingPluginException reaches the native side as
    // FlutterMethodNotImplemented, which AppIntentsBridge turns into
    // AppIntentsBridgeError.methodNotImplemented.
    expect(reply, isNull);
  });
}
