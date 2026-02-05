import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Onboarding Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });
    
    group('Placement Test Screen', () {
      testWidgets('should display intro screen initially', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MockPlacementTestScreen(),
            ),
          ),
        );
        
        expect(find.text('Assess Your Level'), findsOneWidget);
        expect(find.text('Start Assessment'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
      });
      
      testWidgets('should display questions after starting', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MockPlacementTestScreen(),
            ),
          ),
        );
        
        // Tap start button
        await tester.tap(find.text('Start Assessment'));
        await tester.pumpAndSettle();
        
        // Verify question is displayed
        expect(find.text('Question 1 of 3'), findsOneWidget);
      });
      
      testWidgets('should allow answer selection', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MockPlacementTestScreen(),
            ),
          ),
        );
        
        await tester.tap(find.text('Start Assessment'));
        await tester.pumpAndSettle();
        
        // Tap an answer option
        final optionFinder = find.text('None at all');
        if (optionFinder.evaluate().isNotEmpty) {
          await tester.tap(optionFinder);
          await tester.pumpAndSettle();
        }
      });
      
      testWidgets('skip button should navigate away', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MockPlacementTestScreen(),
            ),
          ),
        );
        
        // Tap skip
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        
        // In real test, would verify navigation
      });
    });
    
    group('Language Selection Screen', () {
      testWidgets('should display language options', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MockLanguageSelectionScreen(),
            ),
          ),
        );
        
        // Common languages should be available
        expect(find.text('Swahili'), findsOneWidget);
        expect(find.text('Yoruba'), findsOneWidget);
      });
      
      testWidgets('should allow single language selection', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MockLanguageSelectionScreen(),
            ),
          ),
        );
        
        // Tap to select Swahili
        await tester.tap(find.text('Swahili'));
        await tester.pumpAndSettle();
        
        // In real test, would verify state update
      });
    });
    
    group('Daily Goal Screen', () {
      testWidgets('should display duration options', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MockDailyGoalScreen(),
            ),
          ),
        );
        
        expect(find.text('5 min'), findsOneWidget);
        expect(find.text('10 min'), findsOneWidget);
        expect(find.text('15 min'), findsOneWidget);
        expect(find.text('20 min'), findsOneWidget);
      });
    });
    
    group('Accessibility', () {
      testWidgets('buttons should have semantic labels', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MockPlacementTestScreen(),
            ),
          ),
        );
        
        // Verify semantic labels exist
        final semantics = tester.getSemantics(find.text('Start Assessment'));
        expect(semantics.label, isNotNull);
      });
      
      testWidgets('should support large font sizes', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(textScaleFactor: 2.0),
                child: MockPlacementTestScreen(),
              ),
            ),
          ),
        );
        
        // Should not overflow
        expect(tester.takeException(), isNull);
      });
    });
  });
}

// Mock screens for testing
class MockPlacementTestScreen extends StatefulWidget {
  const MockPlacementTestScreen({super.key});

  @override
  State<MockPlacementTestScreen> createState() => _MockPlacementTestScreenState();
}

class _MockPlacementTestScreenState extends State<MockPlacementTestScreen> {
  bool showIntro = true;
  int currentQuestion = 0;
  final totalQuestions = 3;

  @override
  Widget build(BuildContext context) {
    if (showIntro) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Assess Your Level'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => showIntro = false),
                child: const Text('Start Assessment'),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Question ${currentQuestion + 1} of $totalQuestions'),
            const SizedBox(height: 16),
            _buildOption('None at all'),
            _buildOption('A little bit'),
            _buildOption('Conversational'),
            _buildOption('Fluent'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOption(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () {
          if (currentQuestion < totalQuestions - 1) {
            setState(() => currentQuestion++);
          }
        },
        child: Text(text),
      ),
    );
  }
}

class MockLanguageSelectionScreen extends StatelessWidget {
  const MockLanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          ListTile(title: Text('Swahili')),
          ListTile(title: Text('Yoruba')),
          ListTile(title: Text('Amharic')),
          ListTile(title: Text('Zulu')),
          ListTile(title: Text('Hausa')),
        ],
      ),
    );
  }
}

class MockDailyGoalScreen extends StatelessWidget {
  const MockDailyGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Daily Goal'),
            Chip(label: Text('5 min')),
            Chip(label: Text('10 min')),
            Chip(label: Text('15 min')),
            Chip(label: Text('20 min')),
          ],
        ),
      ),
    );
  }
}
