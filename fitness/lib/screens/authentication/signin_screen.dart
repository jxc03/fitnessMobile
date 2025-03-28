// Importing packages
import 'package:flutter/material.dart'; // Flutter framework
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication package
import '../../services/authentication_service.dart'; // Authentication service
import '../authentication/forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState(); 
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final _emailController = TextEditingController(); // Email controller
  final _passwordController = TextEditingController(); // Password controller

  bool _isLoading = false; // Loading state, set to false initially
  bool _isPasswordVisible = false; // Password visuability state, set to false initially
  String? _errorMessage; // Error message state, set to null initially

  final AuthService _authService = AuthService(); // Initialise authentication service instance

  // Dispose of controllers to free up resources
  @override
  void dispose() {
    _emailController.dispose(); // Dispose of email controller
    _passwordController.dispose(); // Dispose of password controller
    super.dispose(); // Call super dispose, ensures cleanup 
  }

  // Function to handle signin
  Future <void> _signIn() async {
    // Check if form is valid 
    if (!_formKey.currentState!.validate()) { // If form is not valid
      return; // Stop execution and return
    }
  // Update UI state to show a loading indicator and reset error messages
  setState(() {
    _isLoading = true; // Set loading state to true, shows loading indicator
    _errorMessage = null; // Clear any error message
  });

  // Try to sign in with email and password
  try {
    // Attempt to sign in with provided email and password 
    await _authService.signInWithEmailAndPassword(_emailController.text, _passwordController.text); // Call sign-in method from authentication service

    // Ensure the widget is still mounted before navigating
    if (mounted) { // Check if the widget is still mounted
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false); // Navigate to home screen on successful sign-in
      }
    // Error handling
    } on FirebaseAuthException catch (err) { // Catch Firebase authentication errors
      String message; // Message variable to store error message

      // Handle Firebase authentication errors
      switch(err.code) { // Check the error code
        case 'user-not-found': // If user not found
          message = 'No user found for that email.'; // User not found error message
          break;
        case 'wrong-password': // If wrong password
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email': // If invalid email
          message = 'The email address is not valid.'; 
          break;
        case 'user-disabled': // If user is disabled
          message = 'This user has been disabled.'; 
          break;
        default: // If unknown error
          message = 'An unknown error occurred.'; // Default error message
      }
      setState(() {
        _errorMessage = message; // Set error message state
      });

    } catch (err) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.'; // Set generic error message
      });
      
    } finally { // Finally block to reset loading state
      // Ensure the widget is still mounted before updating the state
      if (mounted) { // Check if the widget is still mounted
        setState(() { // Update UI state
          _isLoading = false; // Set loading state to false
        });
      }
    }
  }

  // Build frontend UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
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
                // Logo or icon
                const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Colors.blue,
                ),
                
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
                    hintText: 'Enter your password',
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
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Forgot password button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign in button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
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
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign up option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      child: const Text('Sign Up'),
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




