import 'package:flutter/material.dart';
import 'package:app_intents_plugin/app_intents_plugin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apple App Intents Prototype',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppIntentsDemoPage(),
    );
  }
}

class AppIntentsDemoPage extends StatefulWidget {
  const AppIntentsDemoPage({super.key});

  @override
  State<AppIntentsDemoPage> createState() => _AppIntentsDemoPageState();
}

class _AppIntentsDemoPageState extends State<AppIntentsDemoPage> {
  final AppIntentsPlugin _appIntentsPlugin = AppIntentsPlugin();
  final List<String> _tasks = [];
  String _statusMessage = 'Waiting for App Intent triggers...';
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initPlugin();
  }

  Future<void> _initPlugin() async {
    try {
      final version = await _appIntentsPlugin.getPlatformVersion();
      setState(() {
        _platformVersion = version ?? 'Unknown';
      });
    } catch (e) {
      setState(() {
        _platformVersion = 'Failed to get version: $e';
      });
    }

    // Register handler for App Intents invoked by iOS / Siri / Shortcuts / Core AI
    _appIntentsPlugin.setIntentHandler((arguments) async {
      final title = arguments['title'] as String? ?? 'Untitled Task';
      setState(() {
        _tasks.add(title);
        _statusMessage = 'Last Intent Triggered: AddFlutterTask ("$title")';
      });
      return 'Successfully added task "$title" to Flutter state';
    });
  }

  Future<void> _simulateIntent() async {
    final taskNumber = _tasks.length + 1;
    final res = await _appIntentsPlugin.simulateAppIntent(
      'Demo Task #$taskNumber',
    );
    setState(() {
      _statusMessage = 'Simulation Result: $res';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Intents & App Entities Prototype'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform: $_platformVersion',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $_statusMessage',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Text(
              'Tasks Added via App Intents:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet. Tap the simulation button below or trigger via Shortcuts / Siri.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(_tasks[index]),
                            subtitle: Text(
                              'Added via AddFlutterTaskIntent (#${index + 1})',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateIntent,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Simulate App Intent'),
      ),
    );
  }
}
