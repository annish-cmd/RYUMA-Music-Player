import 'package:flutter/material.dart';
import 'services/theme_service.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RYUMA Music Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<String> testResults = [];

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _runTests() async {
    // Test our duration filtering logic
    setState(() {
      testResults.add('Testing duration filtering logic...');
    });

    // Simulate different duration scenarios
    final testDurations = [
      {'title': 'Very short sound', 'duration': 5000}, // 5 seconds
      {'title': 'Short song', 'duration': 25000}, // 25 seconds  
      {'title': 'Normal song', 'duration': 180000}, // 3 minutes
      {'title': 'Long song', 'duration': 3600000}, // 1 hour
      {'title': 'Very long audio', 'duration': 7200000}, // 2 hours
      {'title': 'Null duration', 'duration': null},
      {'title': 'Negative duration', 'duration': -1000},
    ];

    for (var test in testDurations) {
      final title = test['title'] as String;
      final duration = test['duration'] as int?;
      
      bool shouldExclude = _shouldExcludeTrack(title, duration);
      
      setState(() {
        testResults.add('$title (${duration ?? 'null'} ms): ${shouldExclude ? 'EXCLUDED' : 'INCLUDED'}');
      });
    }

    setState(() {
      testResults.add('Test completed!');
    });
  }

  // This replicates the core filtering logic from MusicService
  bool _shouldExcludeTrack(String title, int? duration) {
    // Check for null duration
    if (duration == null) {
      // Don't exclude tracks with null duration in our improved version
      return false;
    }

    // Minimum duration check (10 seconds instead of 30)
    const int minDurationMs = 10000;
    if (duration < minDurationMs) {
      return true;
    }

    // Check for negative duration
    if (duration < 0) {
      return true;
    }

    // Maximum reasonable duration: 24 hours
    const int maxDurationMs = 24 * 60 * 60 * 1000;
    if (duration > maxDurationMs) {
      // Don't exclude very long tracks, just log warning
      return false;
    }

    // Check if title is empty or too generic
    if (title.trim().isEmpty || 
        title.trim().toLowerCase() == 'unknown' ||
        title.trim().toLowerCase() == '<unknown>') {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RYUMA Music - Duration Filter Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Duration Filtering Test Results:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: testResults.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        testResults[index],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runTests,
              child: const Text('Run Test Again'),
            ),
          ],
        ),
      ),
    );
  }
}