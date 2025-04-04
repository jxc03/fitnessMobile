import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
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
    _initializeFormValues();
  }
  
  void _initializeFormValues() {
    // Initialize form with user data
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
      print('Error uploading image: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    
                    // Profile image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (widget.userData['photoURL'] != null
                                    ? NetworkImage(widget.userData['photoURL'])
                                    : null),
                            child: (_imageFile == null && widget.userData['photoURL'] == null)
                                ? Text(
                                    _getInitials(widget.userData['displayName'] ?? ''),
                                    style: const TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.white,
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    
                    // Personal Information Section
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Height
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.height),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final height = double.tryParse(value);
                          if (height == null || height <= 0) {
                            return 'Please enter a valid height';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Weight
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monitor_weight),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid weight';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fitness Level
                    const Text(
                      'Fitness Level',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Wrap(
                      spacing: 8,
                      children: _fitnessLevels.map((level) {
                        return ChoiceChip(
                          label: Text(level.capitalize()),
                          selected: _selectedFitnessLevel == level,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFitnessLevel = level;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Fitness Goals
                    const Text(
                      'Fitness Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableFitnessGoals.map((goal) {
                        final isSelected = _selectedFitnessGoals.contains(goal);
                        return FilterChip(
                          label: Text(goal),
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
                          selectedColor: Colors.blue.shade100,
                          checkmarkColor: Colors.blue.shade800,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
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
                  ],
                ),
              ),
            ),
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

// Extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}