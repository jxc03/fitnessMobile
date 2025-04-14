import 'package:flutter/material.dart'; // Import Flutter's material design package
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for database operations
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for user authentication

/// Screen for creating or editing workout plans
/// Allows users to input plan name and description and save to Firestore
class CreateWorkoutPlanScreen extends StatefulWidget {
  final String? planId; // Plan ID for editing existing plans, null for new plans

  const CreateWorkoutPlanScreen({super.key, this.planId});

  @override
  State<CreateWorkoutPlanScreen> createState() => _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for validating the form
  final _nameController = TextEditingController(); // Controller for plan name input
  final _descriptionController = TextEditingController(); // Controller for plan description input

  bool _isLoading = false; // To track if save operation is in progress
  bool _isEditing = false; // To determine if editing or creating
  bool _isLoadingPlan = false; // To track if plan data is being loaded

  // Application colour palette
  static const Color primaryColor = Color(0xFF2A6F97); 
  static const Color secondaryColor = Color(0xFF61A0AF); 
  static const Color accentGreen = Color(0xFF4C956C); 
  static const Color accentTeal = Color(0xFF2F6D80); 
  static const Color neutralDark = Color(0xFF3D5A6C); 
  static const Color neutralLight = Color(0xFFF5F7FA); 
  static const Color neutralMid = Color(0xFFE1E7ED); 

  @override
  void initState() {
    super.initState();
    _isEditing = widget.planId != null; // Set editing mode if planId is provided
    if (_isEditing) {
      _loadWorkoutPlan(); // Load existing plan data if in editing mode
    }
  }

  /// Loads an existing workout plan from Firestore for editing
  /// Verifies user permissions and populates form fields
  Future<void> _loadWorkoutPlan() async {
    setState(() {
      _isLoadingPlan = true; // Show loading indicator
    });

    try {
      // Fetch the workout plan document from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Security check: verify current user owns this plan
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (data['userId'] != currentUserId) {
          // Not the owner, show error and navigate back
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('You do not have permission to edit this workout plan'),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            Navigator.pop(context); // Return to previous screen
          }
          return;
        }

        // Populate form fields with existing data
        setState(() {
          _nameController.text = data['name'] ?? ''; // Set plan name
          _descriptionController.text = data['description'] ?? ''; // Set plan description
        });
      } else {
        // Plan not found, show error and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Workout plan not found'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context); // Return to previous screen
        }
      }
    } catch (error) {
      // Handle any errors during data loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workout plan: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      // Hide loading indicator when operation completes
      setState(() {
        _isLoadingPlan = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up controllers when widget is removed
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralLight, // Light background for screen
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Workout Plan' : 'Create Workout Plan', // Dynamic title based on mode
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor, // Blue app bar
        foregroundColor: Colors.white, // White text and icons
        elevation: 0, // No shadow for flat design
      ),
      body: _isLoadingPlan
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor), // Blue loading indicator
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0), // Padding around all content
              child: Form(
                key: _formKey, // Form key for validation
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout Plan Info Card - contains form fields
                    _buildSectionCard(
                      title: 'Workout Plan Information',
                      icon: Icons.fitness_center,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8), // Spacing above first field
                          
                          // Plan name field with validation
                          TextFormField(
                            controller: _nameController, // Controller for name input
                            style: TextStyle(
                              color: neutralDark,
                              fontWeight: FontWeight.w500, // Medium weight text
                            ),
                            decoration: InputDecoration(
                              labelText: 'Plan Name', // Field label
                              hintText: 'e.g., Full Body Workout, Upper/Lower Split', // Example text
                              labelStyle: TextStyle(
                                color: neutralDark.withValues(alpha: 0.7), // Slightly faded label
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: neutralDark.withValues(alpha: 0.5), // More faded hint
                                fontSize: 14, // Smaller hint text
                              ),
                              filled: false, // No background fill
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12), // Rounded corners
                                borderSide: BorderSide(color: neutralMid, width: 1), // Border colour
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: neutralMid, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 1.5), // Thicker blue border when focused
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red.shade700, width: 1), // Red border for errors
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red.shade700, width: 1.5), // Thicker red border for focused errors
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Internal padding
                            ),
                            validator: (value) {
                              // Validation logic for required field
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name for your workout plan';
                              }
                              return null; // No error
                            },
                          ),
                          const SizedBox(height: 20), // Spacing between fields
                          
                          // Description field (optional, no validation)
                          TextFormField(
                            controller: _descriptionController, // Controller for description input
                            style: TextStyle(
                              color: neutralDark,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Description (optional)', // Field label
                              hintText: 'Describe your workout plan goals and structure', // Helper text
                              labelStyle: TextStyle(
                                color: neutralDark.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: neutralDark.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                              filled: false, // No background fill
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: neutralMid, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: neutralMid, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2), // Thicker blue border when focused
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            maxLines: 5, // Allow multiple lines for description
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24), // Spacing before button
                    
                    // Submit button - full width
                    SizedBox(
                      width: double.infinity, // Full width button
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveWorkoutPlan, // Disable when loading
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, // White text
                          backgroundColor: primaryColor, // Blue background
                          padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
                          elevation: 0, // No shadow for flat design
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16, // Larger text
                            fontWeight: FontWeight.bold, // Bold text
                          ),
                          disabledBackgroundColor: primaryColor.withValues(alpha: 0.5), // Faded when disabled
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // White spinner
                                  strokeWidth: 2.5, // Thinner spinner line
                                ),
                              )
                            : Text(_isEditing ? 'Update Plan' : 'Create Plan'), // Dynamic button text
                      ),
                    ),
                    
                    // Help text below button - only shown for new plans
                    if (!_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'You can add exercises to your workout plan after creation.',
                          style: TextStyle(
                            color: neutralDark.withValues(alpha: 0.6), // Faded text
                            fontSize: 14, // Smaller text
                          ),
                          textAlign: TextAlign.center, // Centered text
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Builds a card for a form section with consistent styling
  /// Used to group related form elements with a title
  Widget _buildSectionCard({
    required String title, // Section title
    required IconData icon, // Section icon
    required Widget content, // Section content
  }) {
    return Container(
      width: double.infinity, // Full width container
      margin: const EdgeInsets.only(bottom: 8), // Margin below card
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12), // Rounded corners
        border: Border.all(color: neutralMid, width: 1), // Light grey border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header with title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title, // Section title
              style: TextStyle(
                fontSize: 18, // Larger text for section headings
                fontWeight: FontWeight.bold, // Bold section headings
                color: neutralDark, // Dark text for contrast
              ),
            ),
          ),
          
          // Divider between header and content
          Divider(color: neutralMid, height: 1), // Thin divider
          
          // Card content area
          Padding(
            padding: const EdgeInsets.all(16), // Padding around content
            child: content, // Section content widgets
          ),
        ],
      ),
    );
  }

  /// Saves the workout plan to Firestore
  /// Creates new plan or updates existing one based on editing mode
  Future<void> _saveWorkoutPlan() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    setState(() {
      _isLoading = true; // Show loading state
    });

    try {
      if (_isEditing) {
        // Update existing workout plan in Firestore
        await FirebaseFirestore.instance
            .collection('WorkoutPlans')
            .doc(widget.planId)
            .update({
          'name': _nameController.text, // Update plan name
          'description': _descriptionController.text, // Update description
          'updatedAt': FieldValue.serverTimestamp(), // Record update time
          'userId': FirebaseAuth.instance.currentUser!.uid, // User ID for ownership
        });

        // Show success message and return to previous screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Workout plan updated successfully'),
              backgroundColor: accentGreen, // Green success colour
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context, true); // Return success result
        }
      } else {
        // Create new workout plan in Firestore
        final docRef = await FirebaseFirestore.instance
            .collection('WorkoutPlans')
            .add({
          'name': _nameController.text, // Plan name
          'description': _descriptionController.text, // Plan description
          'exercises': [], // Empty exercises array for new plan
          'createdAt': FieldValue.serverTimestamp(), // Creation timestamp
          'updatedAt': FieldValue.serverTimestamp(), // Update timestamp (same as creation)
          'userId': FirebaseAuth.instance.currentUser!.uid, // User ID for ownership
        });

        // Show success message and return to previous screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Workout plan created successfully'),
              backgroundColor: accentGreen, // Green success colour
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context, true); // Return success result
        }
      }
    } catch (error) {
      // Reset loading state and show error message
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout plan: $error'),
            backgroundColor: Colors.red.shade700, // Red error colour
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}