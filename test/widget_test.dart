// Widget tests for the App Intents prototype app.
//
// These exercise the Dart side of the App Intents bridge by swapping in a fake
// platform implementation, so no engine or native plugin is required.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_intents_plugin/app_intents_plugin_platform_interface.dart';
import 'package:app_intents_prototype/main.dart';

/// A fake platform implementation that records calls and exposes the intent
/// handler the app registers, so tests can trigger it the way the native side
/// would.
///
/// This extends [AppIntentsPluginPlatform] rather than implementing it so that
/// the superclass constructor supplies the platform interface token.
class FakeAppIntentsPluginPlatform extends AppIntentsPluginPlatform {
  /// The handler most recently passed to [setIntentHandler], if any.
  OnIntentTriggeredCallback? handler;

  /// Titles received by [simulateAppIntent], in call order.
  final List<String> simulatedTitles = [];

  /// The value [simulateAppIntent] returns.
  String simulateResult = 'Simulated OK';

  @override
  Future<String?> getPlatformVersion() async => 'iOS 42';

  @override
  void setIntentHandler(OnIntentTriggeredCallback handler) {
    this.handler = handler;
  }

  @override
  Future<String?> simulateAppIntent(String title) async {
    simulatedTitles.add(title);
    return simulateResult;
  }
}

void main() {
  late FakeAppIntentsPluginPlatform fakePlatform;

  setUp(() {
    fakePlatform = FakeAppIntentsPluginPlatform();
    AppIntentsPluginPlatform.instance = fakePlatform;
  });

  testWidgets('shows the platform version and an empty task list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Platform: iOS 42'), findsOneWidget);
    expect(find.textContaining('No tasks yet'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('tapping the button simulates an App Intent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(fakePlatform.simulatedTitles, ['Demo Task #1']);
    expect(find.text('Status: Simulation Result: Simulated OK'), findsOneWidget);
  });

  testWidgets('a triggered App Intent adds a task to the list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Drive the registered handler the way the native App Intent would.
    final result = await fakePlatform.handler!({'title': 'Buy milk'});
    await tester.pumpAndSettle();

    expect(result, 'Successfully added task "Buy milk" to Flutter state');
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Added via AddFlutterTaskIntent (#1)'), findsOneWidget);
    expect(
      find.text('Status: Last Intent Triggered: AddFlutterTask ("Buy milk")'),
      findsOneWidget,
    );
    expect(find.textContaining('No tasks yet'), findsNothing);
  });

  testWidgets('a task with no title falls back to a placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await fakePlatform.handler!(<dynamic, dynamic>{});
    await tester.pumpAndSettle();

    expect(find.text('Untitled Task'), findsOneWidget);
  });
}
