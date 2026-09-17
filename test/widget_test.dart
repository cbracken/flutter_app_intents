// Widget tests for the App Intents prototype app.
//
// These exercise the Dart side of the App Intents bridge by swapping in a fake
// platform implementation, so no engine or native plugin is required.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_intents_plugin/app_intent_task.dart';
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

  /// The handler most recently passed to [setOpenTaskHandler], if any.
  OnOpenTaskCallback? openTaskHandler;

  /// Titles received by [simulateAppIntent], in call order.
  final List<String> simulatedTitles = [];

  /// The value [simulateAppIntent] returns.
  String simulateResult = 'Simulated OK';

  /// The most recent task list passed to [syncTasks].
  List<AppIntentTask>? syncedTasks;

  @override
  Future<String?> getPlatformVersion() async => 'iOS 42';

  @override
  void setIntentHandler(OnIntentTriggeredCallback handler) {
    this.handler = handler;
  }

  @override
  void setOpenTaskHandler(OnOpenTaskCallback handler) {
    openTaskHandler = handler;
  }

  @override
  Future<String?> simulateAppIntent(String title) async {
    simulatedTitles.add(title);
    return simulateResult;
  }

  @override
  Future<void> syncTasks(List<AppIntentTask> tasks) async {
    syncedTasks = tasks;
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
    expect(find.text('Added via AddFlutterTaskIntent'), findsOneWidget);
    expect(
      find.text('Status: Last Intent Triggered: AddFlutterTask ("Buy milk")'),
      findsOneWidget,
    );
    expect(find.textContaining('No tasks yet'), findsNothing);
  });

  testWidgets('added tasks are synced to the native cache', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Synced on startup, before any task exists.
    expect(fakePlatform.syncedTasks, isEmpty);

    await fakePlatform.handler!({'title': 'Buy milk'});
    await tester.pumpAndSettle();

    // Spotlight and Siri read this cache, so the task must reach it with a
    // stable id.
    expect(fakePlatform.syncedTasks, hasLength(1));
    final synced = fakePlatform.syncedTasks!.single;
    expect(synced.title, 'Buy milk');
    expect(synced.id, isNotEmpty);
  });

  testWidgets('opening a task from Spotlight highlights it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await fakePlatform.handler!({'title': 'Buy milk'});
    await tester.pumpAndSettle();
    final id = fakePlatform.syncedTasks!.single.id;

    // Drive the handler the way OpenFlutterTaskIntent would.
    await fakePlatform.openTaskHandler!(id);
    await tester.pumpAndSettle();

    expect(
      find.text('Status: Opened "Buy milk" from Spotlight / Siri'),
      findsOneWidget,
    );
  });

  testWidgets('opening an unknown task is reported, not crashed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await fakePlatform.openTaskHandler!('task-does-not-exist');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Asked to open unknown task'),
      findsOneWidget,
    );
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
