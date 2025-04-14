import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'welcome_screen.dart';
import 'package:fitness/main.dart';
import 'package:fitness/services/authentication_service.dart';

/// AuthWrapper determines which screen to show based on authentication state
/// Redirects to either the main app or welcome screen depending on login status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // Create instance of authentication service
    
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges, // Listen to authentication state stream
      builder: (context, snapshot) {
        // If the snapshot has user data, then they're already signed in
        if (snapshot.hasData) {
          return const MainNavigationScreen(); // Navigate to main app if user is authenticated
        }
        
        // Otherwise, they're not signed in
        return const WelcomeScreen();
      },
    );
  }
}