import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:developer';
import 'package:fitness/services/authentication_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  // Profile details
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedFitnessLevel = 'beginner';
  List<String> _selectedFitnessGoals = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  File? _imageFile;
  
  final AuthService _authService = AuthService();
  
  final List<String> _fitnessLevels = [
    'beginner',
    'intermediate',
    'advanced',
  ];
  
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
    _initialiseFormValues();
  }
  
  void _initialiseFormValues() {
    // Initialise form with user data
    _nameController.text = widget.userData['displayName'] ?? '';
    
    final profile = widget.userData['profile'] as Map<String, dynamic>?;
    if (profile != null) {
      _heightController.text = profile['height']?.toString() ?? '';
      _weightController.text = profile['weight']?.toString() ?? '';
      _selectedFitnessLevel = profile['fitnessLevel'] ?? 'beginner';
      
      if (profile['fitnessGoals'] is List) {
        _selectedFitnessGoals = (profile['fitnessGoals'] as List)
            .map((goal) => goal.toString())
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  
  Future<String?> _uploadImage() async {
    if (_imageFile == null) {
      return null;
    }
    
    try {
      final user = _authService.currentUser;
      if (user == null) return null;
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${user.uid}.jpg');
      
      await storageRef.putFile(_imageFile!);
      
      return await storageRef.getDownloadURL();
    } catch (e) {
      log('Error uploading image: $e', name: 'EditProfileScreen');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Upload image if selected
      String? photoURL;
      if (_imageFile != null) {
        photoURL = await _uploadImage();
      }
      
      // Parse height and weight
      double? height;
      double? weight;
      
      if (_heightController.text.isNotEmpty) {
        height = double.tryParse(_heightController.text);
      }
      
      if (_weightController.text.isNotEmpty) {
        weight = double.tryParse(_weightController.text);
      }
      
      // Update profile
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
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access theme properties
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.8),
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
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (widget.userData['photoURL'] != null
                                          ? NetworkImage(widget.userData['photoURL'])
                                          : null),
                                  child: (_imageFile == null && widget.userData['photoURL'] == null)
                                      ? Text(
                                          _getInitials(widget.userData['displayName'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 50,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.camera_alt, size: 20),
                                    color: Colors.white,
                                    onPressed: _pickImage,
                                    tooltip: 'Change photo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Caption text
                        const Text(
                          'Tap to change profile picture',
                          style: TextStyle(
                            color: Colors.white70,
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
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                          if (_errorMessage != null)
                            const SizedBox(height: 20),
                          
                          // Name section
                          _buildSectionHeader('Personal Details'),
                          
                          const SizedBox(height: 16),
                          
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: theme.primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Body Measurements section
                          _buildSectionHeader('Body Measurements'),
                          
                          const SizedBox(height: 16),
                          
                          // Height & Weight in a row
                          Row(
                            children: [
                              // Height field
                              Expanded(
                                child: TextFormField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Height',
                                    hintText: 'cm',
                                    prefixIcon: Icon(
                                      Icons.height,
                                      color: theme.primaryColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final height = double.tryParse(value);
                                      if (height == null || height <= 0) {
                                        return 'Invalid height';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Weight field
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Weight',
                                    hintText: 'kg',
                                    prefixIcon: Icon(
                                      Icons.monitor_weight_outlined,
                                      color: colorScheme.tertiary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final weight = double.tryParse(value);
                                      if (weight == null || weight <= 0) {
                                        return 'Invalid weight';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Fitness Details section
                          _buildSectionHeader('Fitness Details'),
                          
                          const SizedBox(height: 16),
                          
                          // Fitness Level section
                          Text(
                            'Fitness Level',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Fitness Level Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: _fitnessLevels.map((level) {
                              final isSelected = _selectedFitnessLevel == level;
                              return FilterChip(
                                label: Text(
                                  level.capitalize(),
                                  style: TextStyle(
                                    color: isSelected 
                                        ? theme.primaryColor 
                                        : colorScheme.onSurface,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedFitnessLevel = level;
                                    });
                                  }
                                },
                                backgroundColor: theme.cardColor,
                                selectedColor: theme.primaryColor.withValues(alpha: 0.12),
                                checkmarkColor: theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  side: BorderSide(
                                    color: isSelected 
                                        ? theme.primaryColor 
                                        : colorScheme.outline.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Fitness Goals section
                          Text(
                            'Fitness Goals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Fitness Goals Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: _availableFitnessGoals.map((goal) {
                              final isSelected = _selectedFitnessGoals.contains(goal);
                              return FilterChip(
                                label: Text(
                                  goal,
                                  style: TextStyle(
                                    color: isSelected 
                                        ? theme.primaryColor 
                                        : colorScheme.onSurface,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedFitnessGoals.add(goal);
                                    } else {
                                      _selectedFitnessGoals.remove(goal);
                                    }
                                  });
                                },
                                backgroundColor: theme.cardColor,
                                selectedColor: theme.primaryColor.withValues(alpha: 0.12),
                                checkmarkColor: theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  side: BorderSide(
                                    color: isSelected 
                                        ? theme.primaryColor 
                                        : colorScheme.outline.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
  
  String _getInitials(String fullName) {
    List<String> names = fullName.split(' ');
    String initials = '';
    
    for (var name in names) {
      if (name.isNotEmpty) {
        initials += name[0];
      }
    }
    
    return initials.toUpperCase();
  }
}

// Extension for capitalising string - taken 
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}