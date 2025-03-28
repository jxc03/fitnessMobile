import 'package:flutter/material.dart';

// Imports for firebase 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import screens
import 'screens/exercises_screen.dart';
import 'screens/exercise_details_screen.dart';
import 'screens/workout_plans_screen.dart';
import 'screens/profile_screen.dart';

// Import authenitcation service
import 'services/authentication_service.dart';

// Import authentication screens
import 'screens/authentication/welcome_screen.dart';
import 'screens/authentication/signin_screen.dart';
import 'screens/authentication/signup_screen.dart';
import 'screens/authentication/forgot_password_screen.dart';
import 'screens/authentication/auth_wrapper.dart';

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
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/profile': (context) => const ProfileScreen(),
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // If the snapshot has user data, then they're already signed in
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        
        // Otherwise, they're not signed in
        return const WelcomeScreen();
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
    const ProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
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
    final authService = AuthService();
    final user = authService.currentUser;

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
            const SizedBox(height: 8),
            
            // Display user name if available
            if (user != null && user.displayName != null)
              Text(
                'Hello, ${user.displayName}!',
                style: const TextStyle(fontSize: 18),
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
            const SizedBox(height: 24),
            // Profile button
            ElevatedButton.icon(
              onPressed: () {
                // Switch to Profile tab
                (context.findAncestorStateOfType<_MainNavigationScreenState>())
                    ?.setState(() {
                  (context.findAncestorStateOfType<_MainNavigationScreenState>())
                      ?._currentIndex = 3;
                });
              },
              icon: const Icon(Icons.person),
              label: const Text('View Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}