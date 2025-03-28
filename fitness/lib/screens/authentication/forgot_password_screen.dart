// Importing packages 
import 'package:flutter/material.dart'; // Flutter package for UI components
import 'package:firebase_auth/firebase_auth.dart'; // Firebase package for authentication
import 'package:fitness/services/authentication_service.dart'; // Authentication service for handling user authentication

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // Assigning form key for validation
  final _emailController = TextEditingController(); // Controller for email input
  
  bool _isLoading = false; // Loading state for the sign-up process, set to false initially
  bool _emailSent = false; // State to check if the email has been sent for password reset
  String? _errorMessage; // Error message for displaying any sign-up errors
  
  final AuthService _authService = AuthService(); // Initialise authentication service instance

  // Dispose method to clean up the controllers
  @override
  void dispose() {
    _emailController.dispose(); // Dispose of the email controller
    super.dispose(); // Call super dispose, ensures cleanup
  }

  // Function to handle password reset
  Future<void> _resetPassword() async {
    // Check if form is valid before proceeding
    if (!_formKey.currentState!.validate()) { // Validate the form
      return; // If the form is not valid, return
    }
    // Update UI state to show a loading indicator and reset error messages
    setState(() { // Set state to update UI
      _isLoading = true; // Set loading state to true, shows loading indicator
      _errorMessage = null; // Clear any error message
    });
    
    // Try to send password reset email using the authentication service
    try { // Try block to catch any exceptions
      // Attempt to send password reset email
      await _authService.sendPasswordResetEmail(_emailController.text.trim()); // Call the sendPasswordResetEmail method from the authentication service 
      
      // If the email is sent successfully, update the UI state
      if (mounted) { // Check if the widget is still mounted
        setState(() { // Set state to update UI
          _emailSent = true; // Set email sent state to true, indicates email has been sent
          _isLoading = false; // Set loading state to false, hides loading indicator
        });
      }
    // Error handling
    } on FirebaseAuthException catch (err) { // Catch Firebase authentication exceptions
      String message; // Variable to hold the error message
      
      // Handle Firebase authentication errors
      switch (err.code) { // Switch case to handle different error codes
        case 'invalid-email': // If the email is invalid
          message = 'The email address is not valid.';
          break;
        case 'user-not-found': // If the user is not found
          message = 'No user found with this email.';
          break;
        default: // For any other error
          message = 'An error occurred. Please try again.';
      }
      // Update UI state with the error message
      setState(() { 
        _errorMessage = message; // Set the error message to be displayed
        _isLoading = false; // Set loading state to false, hides loading indicator
      });
    
    } catch (err) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  // 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _emailSent
              ? _buildSuccessScreen()
              : _buildResetPasswordForm(),
        ),
      ),
    );
  }
  
  // 
  Widget _buildResetPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: Colors.blue,
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Forgot Your Password?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Enter your email and we\'ll send you a link to reset your password',
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
          
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
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
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Back to sign in
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'We\'ve sent a password reset link to:\n${_emailController.text}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        // Back to sign in
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextButton(
          onPressed: _resetPassword,
          child: const Text('Didn\'t receive the email? Send again'),
        ),
      ],
    );
  }
}