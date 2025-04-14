import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/screens/exercises/exercise_details_screen.dart';

void main() {
  // Mock exercise 
  final mockExercise = {
    'name': 'Bench Press',
    'equipment': 'Barbell, Bench',
    'muscleGroups': ['Chest', 'Triceps', 'Shoulders'],
    'tags': ['Strength', 'Compound'],
    'images': 'assets/images/bench_press.jpg',
    'instructions': {
      'steps': {
        '1': 'Lie on the bench with your feet flat on the ground',
        '2': 'Grip the bar with hands slightly wider than shoulder-width',
        '3': 'Unrack the bar and lower it to your chest',
        '4': 'Push the bar back up to the starting position'
      },
      'tips': {
        '1': 'Keep your back flat against the bench',
        '2': 'Maintain a controlled motion throughout'
      },
      'commonMistakes': {
        '1': 'Bouncing the bar off your chest',
        '2': 'Arching your back excessively'
      },
      'precautions': {
        '1': 'Use a spotter for heavy lifts',
        '2': 'Keep your wrists straight during the movement'
      }
    }
  };

  group('ExerciseDetailScreen Widget Tests', () {
    testWidgets('renders correctly with all components', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );

      // Verify the app bar shows the exercise name
      expect(find.text('Bench Press'), findsOneWidget);
      
      // Verify action buttons are present
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
      
      // Verify tabs are present
      expect(find.text('How to'), findsOneWidget);
      expect(find.text('Tips'), findsOneWidget);
      expect(find.text('Mistakes'), findsOneWidget);
      expect(find.text('Precautions'), findsOneWidget);
      
      // Verify info cards are present
      expect(find.text('Equipment'), findsOneWidget);
      expect(find.text('Muscle Groups'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
    });
    
    testWidgets('displays correct equipment information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );
      
      expect(find.text('Barbell, Bench'), findsOneWidget);
    });
    
    testWidgets('displays correct muscle groups as chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );
      
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Triceps'), findsOneWidget);
      expect(find.text('Shoulders'), findsOneWidget);
    });
    
    testWidgets('displays correct tags as chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );
      
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Compound'), findsOneWidget);
    });
    
    testWidgets('tab navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );
      
      // First tab should be active by default
      expect(find.text('Lie on the bench with your feet flat on the ground'), findsOneWidget);
      
      // Tap on the Tips tab
      await tester.tap(find.text('Tips'));
      await tester.pumpAndSettle();
      
      // Verify Tips content is visible
      expect(find.text('Keep your back flat against the bench'), findsOneWidget);
      
      // Tap on the Mistakes tab
      await tester.tap(find.text('Mistakes'));
      await tester.pumpAndSettle();
      
      // Verify Mistakes content is visible
      expect(find.text('Bouncing the bar off your chest'), findsOneWidget);
      
      // Tap on the Precautions tab
      await tester.tap(find.text('Precautions'));
      await tester.pumpAndSettle();
      
      // Verify Precautions content is visible
      expect(find.text('Use a spotter for heavy lifts'), findsOneWidget);
    });
    
    testWidgets('handles missing data gracefully', (WidgetTester tester) async {
      // Create a minimal exercise with missing fields
      final minimalExercise = {
        'name': 'Minimal Exercise',
      };
      
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: minimalExercise),
        ),
      );
      
      // Verify it doesnt crash and shows the exercise name
      expect(find.text('Minimal Exercise'), findsOneWidget);
      
      // Check for "No information available" messages
      await tester.tap(find.text('How to'));
      await tester.pumpAndSettle();
      expect(find.text('No information available'), findsWidgets);
    });
    
    testWidgets('image placeholder appears when no image is provided', (WidgetTester tester) async {
      // Exercise without an image
      final noImageExercise = Map<String, dynamic>.from(mockExercise);
      noImageExercise.remove('images');
      
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: noImageExercise),
        ),
      );
      
      // Verify placeholder text appears
      expect(find.text('No image available'), findsOneWidget);
    });
    
    testWidgets('handles different data structures for muscle groups', (WidgetTester tester) async {
      // Test with a string instead of a list
      final stringMuscleExercise = Map<String, dynamic>.from(mockExercise);
      stringMuscleExercise['muscleGroups'] = 'Core';
      
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: stringMuscleExercise),
        ),
      );
      
      expect(find.text('Core'), findsOneWidget);
      
      // Test with a map structure
      final mapMuscleExercise = Map<String, dynamic>.from(mockExercise);
      mapMuscleExercise['muscleGroups'] = {'primary': 'Quadriceps', 'secondary': 'Glutes'};
      
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mapMuscleExercise),
        ),
      );
      
      expect(find.text('Quadriceps'), findsOneWidget);
      expect(find.text('Glutes'), findsOneWidget);
    });

    testWidgets('action buttons are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );
      
      // Test that favorite button is tappable
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      
      // Test that share button is tappable
      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();
      
    });
  });
  
  group('ExerciseDetailScreen Additional Features Tests', () {
    testWidgets('videos section shows placeholder when no videos available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );
      
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Videos will be available soon'), findsOneWidget);
      expect(find.text('Notify Me'), findsOneWidget);
    });
    
    testWidgets('notify me button is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );
      
      await tester.tap(find.text('Notify Me'));
      await tester.pump();
      
    });

    testWidgets('exercise details show up in the first tab by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exercise: mockExercise),
        ),
      );
      
      // Check that steps are visible in the first tab
      for (int i = 1; i <= 4; i++) {
        expect(find.byWidgetPredicate(
          (Widget widget) => widget is Text && widget.data == '$i',
        ), findsOneWidget);
      }
      
      expect(find.text('Lie on the bench with your feet flat on the ground'), findsOneWidget);
      expect(find.text('Grip the bar with hands slightly wider than shoulder-width'), findsOneWidget);
    });
  });
}