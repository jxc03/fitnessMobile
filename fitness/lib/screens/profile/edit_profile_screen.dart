import 'package:flutter/material.dart'; // Import Flutter material design package
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase authentication package
import 'package:image_picker/image_picker.dart'; // Import image picker for selecting profile photos
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase storage for image uploads
import 'dart:io'; // Import IO for file handling
import 'dart:developer'; // Import developer tools for logging
import 'package:fitness/services/authentication_service.dart'; // Import local authentication service

/// Screen for users to edit their profile information
/// Allows editing name, measurements, fitness level, goals and profile picture
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // Current user data to initialise form fields

  const EditProfileScreen({
    super.key,
    required this.userData, // Require user data for editing
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final _nameController = TextEditingController(); // Controller for name input
  
  // Profile details controllers and state
  final _heightController = TextEditingController(); // Controller for height input
  final _weightController = TextEditingController(); // Controller for weight input
  String _selectedFitnessLevel = 'beginner'; // Default fitness level
  List<String> _selectedFitnessGoals = []; // Selected fitness goals
  
  bool _isLoading = false; // Loading state flag
  String? _errorMessage; // Error message if something goes wrong
  File? _imageFile; // Selected image file for profile picture
  
  final AuthService _authService = AuthService(); // Instance of authentication service
  
  // Available fitness level options
  final List<String> _fitnessLevels = [
    'beginner',
    'intermediate',
    'advanced',
  ];
  
  // Available fitness goals options
  final List<String> _availableFitnessGoals = [
    'Lose Weight',
    'Build Muscle',
    'Improve Strength',
    'Improve Endurance',
    'Improve Flexibility',
    'Maintain Fitness',
    'Rehabilitation',
    'Sports Performance',
  ];

  @override
  void initState() {
    super.initState();
    _initialiseFormValues(); // Set initial form values from user data
  }
  
  /// Sets initial form values using the provided user data
  void _initialiseFormValues() {
    // Initialise form with user data
    _nameController.text = widget.userData['displayName'] ?? '';
    
    // Extract profile data if available
    final profile = widget.userData['profile'] as Map<String, dynamic>?;
    if (profile != null) {
      _heightController.text = profile['height']?.toString() ?? '';
      _weightController.text = profile['weight']?.toString() ?? '';
      _selectedFitnessLevel = profile['fitnessLevel'] ?? 'beginner';
      
      // Extract fitness goals list if available
      if (profile['fitnessGoals'] is List) {
        _selectedFitnessGoals = (profile['fitnessGoals'] as List)
            .map((goal) => goal.toString())
            .toList();
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  /// Opens the image picker to select a profile photo from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Set selected image file
      });
    }
  }
  
  /// Uploads the selected image to Firebase Storage
  /// Returns the download URL for the uploaded image
  Future<String?> _uploadImage() async {
    if (_imageFile == null) {
      return null; // No image to upload
    }
    
    try {
      final user = _authService.currentUser;
      if (user == null) return null; // Exit if no authenticated user
      
      // Create a storage reference with the user's ID
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${user.uid}.jpg');
      
      // Upload the image file
      await storageRef.putFile(_imageFile!);
      
      // Return the download URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      log('Error uploading image: $e', name: 'EditProfileScreen'); // Log error
      return null; // Return null on error
    }
  }

  /// Saves user profile changes to Firebase
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form validation failed
    }
    
    setState(() {
      _isLoading = true; // Show loading indicator
      _errorMessage = null; // Clear any previous errors
    });
    
    try {
      // Upload image if selected
      String? photoURL;
      if (_imageFile != null) {
        photoURL = await _uploadImage();
      }
      
      // Parse height and weight from text to double
      double? height;
      double? weight;
      
      if (_heightController.text.isNotEmpty) {
        height = double.tryParse(_heightController.text);
      }
      
      if (_weightController.text.isNotEmpty) {
        weight = double.tryParse(_weightController.text);
      }
      
      // Update user profile with all data
      await _authService.updateUserProfile(
        displayName: _nameController.text.trim(),
        photoURL: photoURL,
        profileData: {
          'height': height,
          'weight': weight,
          'fitnessLevel': _selectedFitnessLevel,
          'fitnessGoals': _selectedFitnessGoals,
        },
      );
      
      if (mounted) {
        Navigator.pop(context, true); // Return to previous screen with success result
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e'; // Set error message
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access theme properties for consistent styling
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0, // No shadow for flat design
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor), // Use theme colour
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header section with profile image
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
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      children: [
                        // Profile image with edit button
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Profile image container
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3, // White border around image
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2), // Subtle shadow
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60, // Large profile image
                                  backgroundColor: Colors.white,
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!) // Show selected image
                                      : (widget.userData['photoURL'] != null
                                          ? NetworkImage(widget.userData['photoURL']) // Show existing image
                                          : null),
                                  child: (_imageFile == null && widget.userData['photoURL'] == null)
                                      ? Text(
                                          _getInitials(widget.userData['displayName'] ?? ''), // Show initials if no image
                                          style: TextStyle(
                                            fontSize: 50,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              // Camera icon button for changing image
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary, // Secondary colour for button
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2, // White border
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2), // Subtle shadow
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.camera_alt, size: 20),
                                    color: Colors.white,
                                    onPressed: _pickImage, // Open image picker
                                    tooltip: 'Change photo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8), // Spacing
                        
                        // Helper text for changing profile image
                        const Text(
                          'Tap to change profile picture',
                          style: TextStyle(
                            color: Colors.white70, // Semi-transparent white text
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey, // Form key for validation
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error message box if error occurs
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50, // Light red background
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200, // Red border
                                  width: 1,
                                ),
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
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                          if (_errorMessage != null)
                            const SizedBox(height: 20), // Spacing after error
                          
                          // Personal details section
                          _buildSectionHeader('Personal Details'),
                          
                          const SizedBox(height: 16), // Spacing
                          
                          // Name input field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: theme.primaryColor, // Use theme primary colour
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
                                vertical: 16, // Comfortable padding
                              ),
                            ),
                            validator: (value) {
                              // Name field validation
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null; // No error
                            },
                          ),
                          
                          const SizedBox(height: 24), // Section spacing
                          
                          // Body measurements section
                          _buildSectionHeader('Body Measurements'),
                          
                          const SizedBox(height: 16), // Spacing
                          
                          // Height & Weight in a row for better layout
                          Row(
                            children: [
                              // Height input field
                              Expanded(
                                child: TextFormField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number, // Numeric keyboard
                                  decoration: InputDecoration(
                                    labelText: 'Height',
                                    hintText: 'cm', // Centimetres hint
                                    prefixIcon: Icon(
                                      Icons.height,
                                      color: theme.primaryColor, // Primary colour icon
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), // Rounded corners
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16, // Comfortable padding
                                    ),
                                  ),
                                  validator: (value) {
                                    // Height validation (optional field)
                                    if (value != null && value.isNotEmpty) {
                                      final height = double.tryParse(value);
                                      if (height == null || height <= 0) {
                                        return 'Invalid height';
                                      }
                                    }
                                    return null; // No error
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 16), // Spacing between fields
                              
                              // Weight input field
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number, // Numeric keyboard
                                  decoration: InputDecoration(
                                    labelText: 'Weight',
                                    hintText: 'kg', // Kilograms hint
                                    prefixIcon: Icon(
                                      Icons.monitor_weight_outlined,
                                      color: colorScheme.tertiary, // Tertiary colour icon
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), // Rounded corners
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16, // Comfortable padding
                                    ),
                                  ),
                                  validator: (value) {
                                    // Weight validation (optional field)
                                    if (value != null && value.isNotEmpty) {
                                      final weight = double.tryParse(value);
                                      if (weight == null || weight <= 0) {
                                        return 'Invalid weight';
                                      }
                                    }
                                    return null; // No error
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24), // Section spacing
                          
                          // Fitness details section
                          _buildSectionHeader('Fitness Details'),
                          
                          const SizedBox(height: 16), // Spacing
                          
                          // Fitness level section header
                          Text(
                            'Fitness Level',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface, // Theme text colour
                            ),
                          ),
                          
                          const SizedBox(height: 12), // Spacing
                          
                          // Fitness level selection with chips
                          Wrap(
                            spacing: 8, // Horizontal gap between chips
                            runSpacing: 10, // Vertical gap between rows
                            children: _fitnessLevels.map((level) {
                              final isSelected = _selectedFitnessLevel == level; // Check if selected
                              return FilterChip(
                                label: Text(
                                  level.capitalize(), // Capitalise first letter
                                  style: TextStyle(
                                    color: isSelected 
                                        ? theme.primaryColor // Primary colour for selected
                                        : colorScheme.onSurface, // Default text colour
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal, // Bold if selected
                                  ),
                                ),
                                selected: isSelected, // Set selected state
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedFitnessLevel = level; // Update selected level
                                    });
                                  }
                                },
                                backgroundColor: theme.cardColor, // Card colour for chip
                                selectedColor: theme.primaryColor.withValues(alpha: 0.12), // Light primary colour when selected
                                checkmarkColor: theme.primaryColor, // Primary colour checkmark
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50), // Fully rounded corners
                                  side: BorderSide(
                                    color: isSelected 
                                        ? theme.primaryColor // Primary colour border when selected
                                        : colorScheme.outline.withValues(alpha: 0.5), // Faded border when not selected
                                    width: 1, // Thin border
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4), // Chip padding
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 24), // Section spacing
                          
                          // Fitness goals section header
                          Text(
                            'Fitness Goals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface, // Theme text colour
                            ),
                          ),
                          
                          const SizedBox(height: 12), // Spacing
                          
                          // Fitness goals multi-selection with chips
                          Wrap(
                            spacing: 8, // Horizontal gap between chips
                            runSpacing: 10, // Vertical gap between rows
                            children: _availableFitnessGoals.map((goal) {
                              final isSelected = _selectedFitnessGoals.contains(goal); // Check if selected
                              return FilterChip(
                                label: Text(
                                  goal, // Goal name
                                  style: TextStyle(
                                    color: isSelected 
                                        ? theme.primaryColor // Primary colour for selected
                                        : colorScheme.onSurface, // Default text colour
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal, // Bold if selected
                                  ),
                                ),
                                selected: isSelected, // Set selected state
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedFitnessGoals.add(goal); // Add goal to selected list
                                    } else {
                                      _selectedFitnessGoals.remove(goal); // Remove goal from selected list
                                    }
                                  });
                                },
                                backgroundColor: theme.cardColor, // Card colour for chip
                                selectedColor: theme.primaryColor.withValues(alpha: 0.12), // Light primary colour when selected
                                checkmarkColor: theme.primaryColor, // Primary colour checkmark
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50), // Fully rounded corners
                                  side: BorderSide(
                                    color: isSelected 
                                        ? theme.primaryColor // Primary colour border when selected
                                        : colorScheme.outline.withValues(alpha: 0.5), // Faded border when not selected
                                    width: 1, // Thin border
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4), // Chip padding
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 32), // Bottom spacing
                          
                          // Save button - full width
                          SizedBox(
                            width: double.infinity, // Full width button
                            height: 52, // Taller button for better touch target
                            child: ElevatedButton(
                              onPressed: _saveProfile, // Save profile function
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor, // Primary colour button
                                foregroundColor: Colors.white, // White text
                                elevation: 0, // No shadow for flat design
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // Rounded corners
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16, // Larger text
                                  fontWeight: FontWeight.bold, // Bold text
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32), // Bottom padding
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
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title, // Section title
          style: TextStyle(
            fontSize: 18,
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
  
  /// Extracts initials from a full name for avatar placeholder
  String _getInitials(String fullName) {
    List<String> names = fullName.split(' '); // Split name by spaces
    String initials = '';
    
    // Get first letter of each name part
    for (var name in names) {
      if (name.isNotEmpty) {
        initials += name[0]; // Add first letter
      }
    }
    
    return initials.toUpperCase(); // Return uppercase initials
  }
}

// Extension for capitalising string
extension StringExtension on String {
  /// Capitalises the first letter of a string
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}