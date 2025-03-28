import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/services/authentication_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final _nameController = TextEditingController(); // Controller for name
  final _emailController = TextEditingController(); // Controller for email 
  final _passwordController = TextEditingController(); // Controller for password 
  final _confirmPasswordController = TextEditingController(); // Controller for confirm password

  bool _isLoading = false; // Loading state for the sign-up process, set to false initially
  bool _isPasswordVisible = false; // Password visuability state, set to false initially
  bool _isConfirmPasswordVisible = false; // Confirm password visibility state, set to false initially
  String? _errorMessage; // Error message for displaying any sign-up errors

  final AuthService _authService = AuthService(); // Initialise authentication service instance

  // Dispose method to clean up the controllers
  @override
  void dispose() {
    _nameController.dispose(); // Dispose of the name controller
    _emailController.dispose(); // Dispose of the email controller
    _passwordController.dispose(); // Dispose of the password controller
    _confirmPasswordController.dispose(); // Dispose of the confirm password controller
    super.dispose(); // Call super dispose, ensures cleanup
  }

  // Function to handle sign up 
  Future<void> _signUp() async {
    // Check if form is valid 
    if (!_formKey.currentState!.validate()) { // If form is not valid
      return; // Stop execution and return
    }
    // Update UI state to show a loading indicator and reset error messages
    setState(() {
      _isLoading = true; // Set loading state to true, shows loading indicator
      _errorMessage = null; // Clear any error message
    });
    
    // Try to sign up with email and password
    try {
      // Get trimmed input values
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final displayName = _nameController.text.trim();
    
      print('Attempting to register: $email with name: $displayName');

      // Attempt to register the user with email and password
      await _authService.registerWithEmailAndPassword( // Call sign-up method from authentication service
        _emailController.text.trim(), // Trimmed email input
        _passwordController.text, // Password input
        _nameController.text.trim(), // Trimmed name input
      );
      
      // Ensure the widget is still mounted before navigating, go to main app on success
      if (mounted) { // Check if the widget is still mounted
        print('Registration successful, navigating to home');
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false); // Navigate to home screen
      }
    // Error handling
    } on FirebaseAuthException catch (err) { // Catch Firebase authentication errors
      print('Firebase Auth Exception: ${err.code} - ${err.message}');
      String message; // Variable to store error message
      
      // Handle Firebase authentication errors
      switch (err.code) { // Check the error code
        case 'email-already-in-use':
          message = 'This email is already in use by another account.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        default:
          message = 'An error occurred: ${err.message}';
      }
      setState(() {
        _errorMessage = message; // Set error message state
      });

    } catch (e) {
      print('General Exception: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e'; // Set generic error message
      });

    } finally { // Finally block to reset loading state
      // Ensure the widget is still mounted before updating state
      if (mounted) { // Check if the widget is still mounted
        setState(() { // Update UI state
          _isLoading = false; // Set loading state to false, hides loading indicator
        });
      }
    }
  }

  // Build method to create the UI of the sign-up screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text(
                  'Join Fitness App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Create an account to start your fitness journey',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                if (_errorMessage != null)
                  const SizedBox(height: 16),
                
                // Name input
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password input
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm password input
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Sign up button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign in option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signin');
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}