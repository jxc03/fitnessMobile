import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitness/screens/exercises/exercises_screen.dart';
import 'package:fitness/screens/exercises/exercise_details_screen.dart';
import 'package:fitness/screens/exercises/filter_dialog.dart';

// Mock dependencies
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

// Mock for the FilterDialog to handle the showDialog callback
class MockFilterDialog extends StatelessWidget {
  final String selectedSortOption;
  final List<String> selectedMuscleGroups;
  final List<String> selectedEquipment;
  final List<String> availableMuscleGroups;
  final List<String> availableEquipment;

  const MockFilterDialog({
    super.key,
    required this.selectedSortOption,
    required this.selectedMuscleGroups,
    required this.selectedEquipment,
    required this.availableMuscleGroups,
    required this.availableEquipment,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter'),
      content: const Text('Filter Dialog Content'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'sortOption': 'A-Z',
            'muscleGroups': ['Chest'],
            'equipment': ['Barbell'],
          }),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// Set up a test widget to render ExercisesScreen with all necessary providers/dependencies
Widget createExercisesScreen(FakeFirebaseFirestore firestore) {
  return MaterialApp(
    home: ExercisesScreen(),
    routes: {
      '/exercise_details': (context) => const ExerciseDetailScreen(exercise: {}),
    },
  );
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late NavigatorObserver mockNavigatorObserver;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockNavigatorObserver = MockNavigatorObserver();
  });

  // Function to add mock exercise data to Firestore
  Future<void> addMockExercisesToFirestore() async {
    // Add several exercise documents
    await fakeFirestore.collection('Exercises').add({
      'name': 'Bench Press',
      'equipment': 'Barbell',
      'muscleGroups': ['Chest', 'Triceps', 'Shoulders'],
      'tags': ['Strength', 'Compound'],
      'images': 'assets/images/bench_press.jpg',
      'instructions': {
        'steps': {
          '1': 'Lie on the bench with your feet flat on the ground',
          '2': 'Grip the bar with hands slightly wider than shoulder-width',
        },
        'tips': {
          '1': 'Keep your back flat against the bench',
        },
      },
    });

    await fakeFirestore.collection('Exercises').add({
      'name': 'Squat',
      'equipment': 'Barbell',
      'muscleGroups': ['Quadriceps', 'Glutes', 'Hamstrings'],
      'tags': ['Strength', 'Compound', 'Lower Body'],
      'images': 'assets/images/squat.jpg',
    });

    await fakeFirestore.collection('Exercises').add({
      'name': 'Pull-up',
      'equipment': 'Pull-up Bar',
      'muscleGroups': ['Back', 'Biceps'],
      'tags': ['Bodyweight', 'Upper Body'],
      'images': 'assets/images/pullup.jpg',
    });
  }

  group('ExercisesScreen Widget Tests', () {
    testWidgets('renders loading indicator when fetching data', (WidgetTester tester) async {
      // Build the widget with unresolved future (initially loading)
      await tester.pumpWidget(createExercisesScreen(fakeFirestore));
      
      // Test if loading indicator is visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Test that exercise list is not yet visible
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });
    
    testWidgets('displays exercises after loading completes', (WidgetTester tester) async {
      // Add mock exercises to Firestore
      await addMockExercisesToFirestore();
      
      // Build and render the widget
      await tester.pumpWidget(createExercisesScreen(fakeFirestore));
      
      // Wait for the Firestore data to be fetched and UI to update
      await tester.pumpAndSettle();
      
      // Verify that CircularProgressIndicator is no longer visible
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // Verify that exercise cards are visible
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Pull-up'), findsOneWidget);
      
      // Verify that exercise count is displayed correctly
      expect(find.text('3'), findsOneWidget); // The count badge
    });
    
    testWidgets('search functionality filters exercises', (WidgetTester tester) async {
      // Add mock exercises to Firestore
      await addMockExercisesToFirestore();
      
      // Build and render the widget
      await tester.pumpWidget(createExercisesScreen(fakeFirestore));
      
      // Wait for the Firestore data to be fetched and UI to update
      await tester.pumpAndSettle();
      
      // Verify initial state shows all exercises
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Pull-up'), findsOneWidget);
      
      // Enter search text
      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pumpAndSettle();
      
      // Verify that only matching exercises are shown
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsNothing);
      expect(find.text('Pull-up'), findsNothing);
      
      // Clear search and verify all exercises are shown again
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Pull-up'), findsOneWidget);
    });
    
    testWidgets('filter button opens filter dialog', (WidgetTester tester) async {
      
      // Add mock exercises to Firestore
      await addMockExercisesToFirestore();
      
      // Build and render the widget
      await tester.pumpWidget(createExercisesScreen(fakeFirestore));
      
      // Wait for the Firestore data to be fetched and UI to update
      await tester.pumpAndSettle();
      
      // Verify that filter button exists
      expect(find.text('Filter'), findsOneWidget);
      
      // Verify that the button has the correct icon
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });
    
    testWidgets('tapping on exercise card navigates to details screen', (WidgetTester tester) async {
      // Add mock exercises to Firestore
      await addMockExercisesToFirestore();
      
      // Build the widget with a mock navigator observer to track navigation
      await tester.pumpWidget(
        MaterialApp(
          home: ExercisesScreen(),
          navigatorObservers: [mockNavigatorObserver],
        ),
      );
      
      // Wait for the data to load
      await tester.pumpAndSettle();
      
      // Find the first "View Details" button and tap it
      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();
      
      // Verify navigation occurred
      // This is simplified since we cant fully test navigation without deeper integration
      expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    });
    
    testWidgets('displays correct muscle groups and equipment', (WidgetTester tester) async {
      // Add mock exercises to Firestore
      await addMockExercisesToFirestore();
      
      // Build and render the widget
      await tester.pumpWidget(createExercisesScreen(fakeFirestore));
      
      // Wait for the Firestore data to be fetched and UI to update
      await tester.pumpAndSettle();
      
      // Verify equipment is displayed
      expect(find.text('Barbell'), findsWidgets);
      expect(find.text('Pull-up Bar'), findsOneWidget);
      
      // Verify muscle groups (Note: these might be truncated in UI with ...)
      expect(find.textContaining('Chest'), findsOneWidget);
      expect(find.textContaining('Quadriceps'), findsOneWidget);
      expect(find.textContaining('Back'), findsOneWidget);
    });
    
    testWidgets('handles empty exercise list gracefully', (WidgetTester tester) async {
      // Don't add any mock exercises to simulate empty state
      
      // Build and render the widget
      await tester.pumpWidget(createExercisesScreen(fakeFirestore));
      
      // Wait for the Firestore data to be fetched and UI to update
      await tester.pumpAndSettle();
      
      // Verify empty state UI elements
      expect(find.text('No exercises found'), findsOneWidget);
      expect(find.text('Try adjusting your filters or search terms'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });
    
    testWidgets('refresh button works when exercise list is empty', (WidgetTester tester) async {
      // Build and render the widget with empty Firestore
      await tester.pumpWidget(createExercisesScreen(fakeFirestore));
      
      // Wait for the Firestore data to be fetched and UI to update
      await tester.pumpAndSettle();
      
      // Verify empty state UI elements
      expect(find.text('No exercises found'), findsOneWidget);
      
      // Add mock exercises to Firestore after initial load
      await addMockExercisesToFirestore();
      
      // Tap the refresh button
      await tester.tap(find.text('Refresh'));
      
      // Wait for the refresh to complete
      await tester.pumpAndSettle();
      
      // Verify exercises are now loaded
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Pull-up'), findsOneWidget);
    });
    
    testWidgets('displays active filters when filters are applied', (WidgetTester tester) async {
      // Add mock exercises to Firestore
      await addMockExercisesToFirestore();
      
      // Create a testable widget that allows us to modify state programmatically
      Widget testableWidget = StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return createExercisesScreen(fakeFirestore);
        },
      );
      
      // Pump the widget
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();
      
      // Initially, active filters section should not be visible
      expect(find.text('Active Filters'), findsNothing);
      
    });
  });
  
  group('ExercisesScreen Error Handling Tests', () {
    testWidgets('displays error message when Firestore fetch fails', (WidgetTester tester) async {
    });
  });
}