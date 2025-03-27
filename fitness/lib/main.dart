import 'package:flutter/material.dart';

// Imports for firebase 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import screens
import 'screens/exercises_screen.dart';
import 'screens/exercise_details_screen.dart';
import 'screens/workout_plans_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
      routes: {
        '/exercises': (context) => const ExercisesScreen(),
        '/workout-plans': (context) => const WorkoutPlansScreen(),
      },
      // Use onGenerateRoute for routes with parameters
      onGenerateRoute: (settings) {
        if (settings.name == '/exercise-detail') {
          final exercise = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: exercise),
          );
        }
        return null;
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  // List of screens for bottom navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const ExercisesScreen(),
    const WorkoutPlansScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            label: 'Workouts',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to your Fitness Journey!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Switch to Exercises tab
                    (context.findAncestorStateOfType<_MainNavigationScreenState>())
                        ?.setState(() {
                      (context.findAncestorStateOfType<_MainNavigationScreenState>())
                          ?._currentIndex = 1;
                    });
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Exercises'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Switch to Workouts tab
                    (context.findAncestorStateOfType<_MainNavigationScreenState>())
                        ?.setState(() {
                      (context.findAncestorStateOfType<_MainNavigationScreenState>())
                          ?._currentIndex = 2;
                    });
                  },
                  icon: const Icon(Icons.format_list_bulleted),
                  label: const Text('Workout Plans'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}