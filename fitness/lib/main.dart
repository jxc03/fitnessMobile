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
import 'screens/tracking/workout_history_screen.dart';
import 'screens/tracking/workout_progress_screen.dart';
import 'screens/tracking/tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MainApp());
}

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // Colour palette for the whole app
  static const Color primaryColor = Color(0xFF2A6F97); 
  static const Color secondaryColor = Color(0xFF61A0AF); 
  static const Color accentGreen = Color(0xFF4C956C); 
  static const Color accentTeal = Color(0xFF2F6D80); 
  static const Color neutralDark = Color(0xFF3D5A6C); 
  static const Color neutralLight = Color(0xFFF5F7FA); 
  static const Color neutralMid = Color(0xFFE1E7ED); 
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use Material 3
        useMaterial3: true,
        
        // Primary color and generate colour scheme from it
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          tertiary: AppColors.accentGreen,
          surface: AppColors.neutralLight,
        ),
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white, // Explicitly set title text color to white
          ),
        ),
        
        // Text theme
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralDark,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralDark,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.neutralDark,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: AppColors.neutralDark,
          ),
        ),
        
        // Card theme
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.neutralMid, width: 1),
          ),
        ),
        
        // BottomNavigationBar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: Color(0x993D5A6C), // neutralDark with 60% opacity
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
        ),
        
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
        '/tracking': (context) => const TrackingScreen(),
      },
      // onGenerateRoute for routes with parameters
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
        // If the snapshot has user data, then theyre already signed in
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        
        // Otherwise, theyre not signed in
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
  
  // To change tabs that can be called from child widgets
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  // List of screens for bottom navigation
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    // Initialise screens with the navigation callback
    _screens = [
      HomeScreen(onNavigate: changeTab),
      const ExercisesScreen(),
      const WorkoutPlansScreen(),
      const TrackingScreen(),
      const ProfileScreen(),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: AppColors.neutralMid,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Exercises',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_bulleted_outlined),
              activeIcon: Icon(Icons.format_list_bulleted),
              label: 'Workouts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  // Callback function for navigation
  final Function(int)? onNavigate;
  
  const HomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    
    // Accessing theme colors and text styles
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Fitness App'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Welcome to your Fitness Journey!',
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Display user name if available
                  if (user != null && user.displayName != null)
                    Text(
                      'Hello, ${user.displayName}!',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.neutralDark.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),

            // Main content with padding
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick access section
                  Text(
                    'Quick Access',
                    style: textTheme.titleMedium,
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
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          iconColor: AppColors.primaryColor,
                          onTap: () => onNavigate?.call(1),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Workout Plans card
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          icon: Icons.format_list_bulleted,
                          title: 'Workout Plans',
                          color: AppColors.accentGreen.withValues(alpha: 0.1),
                          iconColor: AppColors.accentGreen,
                          onTap: () => onNavigate?.call(2),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Workout Tracking section
                  Text(
                    'Workout Tracking',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tracking Card
                  _buildFeatureCard(
                    context,
                    icon: Icons.show_chart,
                    title: 'Track Your Progress',
                    color: AppColors.secondaryColor.withValues(alpha: 0.1),
                    iconColor: AppColors.secondaryColor,
                    isFullWidth: true,
                    onTap: () => onNavigate?.call(3),
                  ),
                  const SizedBox(height: 32),
                  
                  // Profile section
                  Text(
                    'Your Account',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFeatureCard(
                    context,
                    icon: Icons.person,
                    title: 'My Profile',
                    color: AppColors.accentTeal.withValues(alpha: 0.1),
                    iconColor: AppColors.accentTeal,
                    isFullWidth: true,
                    onTap: () => onNavigate?.call(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    bool isFullWidth = false,
    }
  ) {
    return Card(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (isFullWidth) ...[
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.neutralDark.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}