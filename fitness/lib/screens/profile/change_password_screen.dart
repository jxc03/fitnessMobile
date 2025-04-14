import 'package:flutter/material.dart'; // Import Flutter material design package
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase authentication package
import 'package:fitness/services/authentication_service.dart'; // Import local authentication service

/// Screen for users to change their account password
/// Validates current password and ensures new password meets requirements
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final _currentPasswordController = TextEditingController(); // Controller for current password input
  final _newPasswordController = TextEditingController(); // Controller for new password input
  final _confirmPasswordController = TextEditingController(); // Controller for password confirmation
  
  bool _isLoading = false; // Flag for loading state during password change
  bool _isCurrentPasswordVisible = false; // Toggle for current password visibility
  bool _isNewPasswordVisible = false; // Toggle for new password visibility
  bool _isConfirmPasswordVisible = false; // Toggle for confirm password visibility
  String? _errorMessage; // Error message to display if password change fails
  
  final AuthService _authService = AuthService(); // Instance of authentication service

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handles the password change process with validation and error handling
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form validation fails
    }
    
    setState(() {
      _isLoading = true; // Show loading indicator
      _errorMessage = null; // Clear any previous errors
    });
    
    try {
      // Attempt to change password using authentication service
      await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully'),
            backgroundColor: Theme.of(context).primaryColor, // Use theme primary colour
            behavior: SnackBarBehavior.floating, // Float above content
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            margin: const EdgeInsets.all(16), // Margin around snackbar
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String message;
      
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect.';
          break;
        case 'weak-password':
          message = 'The new password is too weak.';
          break;
        case 'requires-recent-login':
          message = 'Please sign in again before changing your password.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      
      setState(() {
        _errorMessage = message; // Set error message based on error code
      });
    } catch (e) {
      // Handle general errors
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access theme properties for consistent styling
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        elevation: 0, // No shadow for flat design
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with lock icon and title
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.8), // Gradient effect
                  ],
                ),
              ),
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              child: Column(
                children: [
                  // Lock icon in white circle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4), // Bottom shadow
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: theme.primaryColor, // Primary colour lock icon
                    ),
                  ),
                  
                  const SizedBox(height: 16), // Spacing
                  
                  // Page title
                  const Text(
                    'Change Your Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text on coloured background
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8), // Spacing
                  
                  // Subtitle/instruction
                  const Text(
                    'Keep your account secure with a strong password',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70, // Semi-transparent white text
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Form content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey, // Form key for validation
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error message display
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50, // Light red background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200), // Red border
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700, // Red error icon
                            ),
                            const SizedBox(width: 12), // Spacing
                            Expanded(
                              child: Text(
                                _errorMessage!, // Display error message
                                style: TextStyle(
                                  color: Colors.red.shade700, // Red error text
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Current password section
                    _buildSectionHeader(context, 'Current Password'),
                    const SizedBox(height: 8), // Spacing
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: !_isCurrentPasswordVisible, // Hide password by default
                      decoration: InputDecoration(
                        hintText: 'Enter your current password',
                        prefixIcon: Icon(
                          Icons.lock, // Lock icon
                          color: theme.primaryColor, // Primary colour
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isCurrentPasswordVisible 
                                ? Icons.visibility_off // Hide password icon
                                : Icons.visibility, // Show password icon
                            color: colorScheme.onSurface.withValues(alpha: 0.6), // Faded icon
                          ),
                          onPressed: () {
                            setState(() {
                              _isCurrentPasswordVisible = !_isCurrentPasswordVisible; // Toggle password visibility
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                          borderSide: BorderSide(
                            color: colorScheme.outline, // Border colour from theme
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2, // Thicker border when focused
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16, // Comfortable internal padding
                        ),
                      ),
                      validator: (value) {
                        // Validate current password is not empty
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null; // No error
                      },
                    ),
                    
                    const SizedBox(height: 24), // Section spacing
                    
                    // New password section
                    _buildSectionHeader(context, 'New Password'),
                    const SizedBox(height: 8), // Spacing
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_isNewPasswordVisible, // Hide password by default
                      decoration: InputDecoration(
                        hintText: 'Enter your new password',
                        prefixIcon: Icon(
                          Icons.lock_outline, // Lock outline icon
                          color: colorScheme.secondary, // Secondary colour
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isNewPasswordVisible 
                                ? Icons.visibility_off // Hide password icon
                                : Icons.visibility, // Show password icon
                            color: colorScheme.onSurface.withValues(alpha: 0.6), // Faded icon
                          ),
                          onPressed: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible; // Toggle password visibility
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2, // Thicker border when focused
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16, // Comfortable internal padding
                        ),
                      ),
                      validator: (value) {
                        // Validate new password meets requirements
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null; // No error
                      },
                    ),
                    
                    const SizedBox(height: 20), // Spacing
                    
                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible, // Hide password by default
                      decoration: InputDecoration(
                        hintText: 'Confirm your new password',
                        prefixIcon: Icon(
                          Icons.lock_outline, // Lock outline icon
                          color: colorScheme.secondary, // Secondary colour
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible 
                                ? Icons.visibility_off // Hide password icon
                                : Icons.visibility, // Show password icon
                            color: colorScheme.onSurface.withValues(alpha: 0.6), // Faded icon
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible; // Toggle password visibility
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2, // Thicker border when focused
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16, // Comfortable internal padding
                        ),
                      ),
                      validator: (value) {
                        // Validate confirmation matches new password
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null; // No error
                      },
                    ),
                    
                    const SizedBox(height: 40), // Section spacing
                    
                    // Password requirements information box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.05), // Light primary colour background
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2), // Light primary colour border
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password Requirements:', // Info box title
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary, // Primary colour text
                            ),
                          ),
                          const SizedBox(height: 8), // Spacing
                          // Password requirement list items
                          _buildRequirementItem('At least 6 characters'),
                          _buildRequirementItem('Include a mix of letters, numbers, and symbols for better security'),
                          _buildRequirementItem('Avoid using personal information'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32), // Bottom spacing
                    
                    // Change password button
                    SizedBox(
                      height: 52, // Taller button for better touch target
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword, // Disable when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor, // Primary colour button
                          foregroundColor: Colors.white, // White text
                          elevation: 0, // No shadow for flat design
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12), // Vertical padding
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white, // White loading spinner
                                  strokeWidth: 2, // Thinner spinner
                                ),
                              )
                            : const Text(
                                'Change Password', // Button text
                                style: TextStyle(
                                  fontSize: 16, // Larger font
                                  fontWeight: FontWeight.bold, // Bold text
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds a section header with title and divider
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title, // Section title
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface, // Theme text colour
          ),
        ),
        const SizedBox(width: 8), // Spacing
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), // Faded divider
            thickness: 1, // Thin line
          ),
        ),
      ],
    );
  }
  
  /// Builds a password requirement list item with check icon
  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // Bottom spacing between items
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline, // Checkmark icon
            size: 16, // Small icon
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7), // Faded primary colour
          ),
          const SizedBox(width: 8), // Spacing
          Expanded(
            child: Text(
              text, // Requirement text
              style: TextStyle(
                fontSize: 14, // Smaller text
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), // Faded text
              ),
            ),
          ),
        ],
      ),
    );
  }
}