import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'welcome_screen.dart';
import 'package:fitness/main.dart';
import 'package:fitness/services/authentication_service.dart';

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