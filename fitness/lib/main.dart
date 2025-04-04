import 'package:flutter/material.dart';

// Imports for firebase 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import screens
import 'screens/exercises/exercises_screen.dart';
import 'screens/exercises/exercise_details_screen.dart';
import 'screens/workouts/workout_plans_screen.dart';
import 'screens/profile/profile_screen.dart';

// Import authenitcation service
import 'services/authentication_service.dart';

// Import authentication screens
import 'screens/authentication/welcome_screen.dart';
import 'screens/authentication/signin_screen.dart';
import 'screens/authentication/signup_screen.dart';
import 'screens/authentication/forgot_password_screen.dart';
import 'screens/authentication/auth_wrapper.dart';

// Import workout tracking screens
import 'screens/workout_history_screen.dart';
import 'screens/workout_progress_screen.dart';

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
        '/workout-history': (context) => const WorkoutHistoryScreen(),
        '/workout-progress': (context) => const WorkoutProgressScreen(),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Center(
                child: Column(
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
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick access section
              const Text(
                'Quick Access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Quick access cards for primary features
              Row(
                children: [
                  // Exercises card
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.fitness_center,
                      title: 'Exercises',
                      color: Colors.blue.shade100,
                      onTap: () {
                        (context.findAncestorStateOfType<_MainNavigationScreenState>())
                            ?.setState(() {
                          (context.findAncestorStateOfType<_MainNavigationScreenState>())
                              ?._currentIndex = 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Workout Plans card
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.format_list_bulleted,
                      title: 'Workout Plans',
                      color: Colors.green.shade100,
                      onTap: () {
                        (context.findAncestorStateOfType<_MainNavigationScreenState>())
                            ?.setState(() {
                          (context.findAncestorStateOfType<_MainNavigationScreenState>())
                              ?._currentIndex = 2;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Workout Tracking section
              const Text(
                'Workout Tracking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Workout history and progress cards
              Row(
                children: [
                  // Workout History card
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.history,
                      title: 'Workout History',
                      color: Colors.orange.shade100,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkoutHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Progress Analytics card
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.show_chart,
                      title: 'Progress Analytics',
                      color: Colors.purple.shade100,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkoutProgressScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Profile section
              _buildFeatureCard(
                context,
                icon: Icons.person,
                title: 'My Profile',
                color: Colors.grey.shade100,
                isFullWidth: true,
                onTap: () {
                  (context.findAncestorStateOfType<_MainNavigationScreenState>())
                      ?.setState(() {
                    (context.findAncestorStateOfType<_MainNavigationScreenState>())
                        ?._currentIndex = 3;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
    }
  )
  {
  return Card(
    elevation: 2,
    color: color,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: isFullWidth 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isFullWidth) ...[
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ],
        ),
      ),
    ),
  );
  }
}