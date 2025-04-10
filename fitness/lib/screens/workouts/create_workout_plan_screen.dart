import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateWorkoutPlanScreen extends StatefulWidget {
  final String? planId; // If provided, to edit an existing plan

  const CreateWorkoutPlanScreen({super.key, this.planId});

  @override
  State<CreateWorkoutPlanScreen> createState() => _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isLoadingPlan = false;

  // Appc olour palette
  static const Color primaryColor = Color(0xFF2A6F97); // Deep blue - primary accent
  static const Color secondaryColor = Color(0xFF61A0AF); // Teal blue - secondary accent
  static const Color accentGreen = Color(0xFF4C956C); // Forest green - energy and growth
  static const Color accentTeal = Color(0xFF2F6D80); // Deep teal - calm and trust
  static const Color neutralDark = Color(0xFF3D5A6C); // Dark slate - professional text
  static const Color neutralLight = Color(0xFFF5F7FA); // Light gray - backgrounds
  static const Color neutralMid = Color(0xFFE1E7ED); // Mid gray - dividers, borders

  @override
  void initState() {
    super.initState();
    _isEditing = widget.planId != null;
    if (_isEditing) {
      _loadWorkoutPlan();
    }
  }

  Future<void> _loadWorkoutPlan() async {
    setState(() {
      _isLoadingPlan = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if the current user is the owner of this plan
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (data['userId'] != currentUserId) {
          // Not the owner, show error and go back
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
            Navigator.pop(context);
          }
          return;
        }

        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
        });
      } else {
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
          Navigator.pop(context);
        }
      }
    } catch (error) {
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
      setState(() {
        _isLoadingPlan = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralLight,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Workout Plan' : 'Create Workout Plan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingPlan
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout Plan Info Card
                    _buildSectionCard(
                      title: 'Workout Plan Information',
                      icon: Icons.fitness_center,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(
                              color: neutralDark,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Plan Name',
                              hintText: 'e.g., Full Body Workout, Upper/Lower Split',
                              labelStyle: TextStyle(
                                color: neutralDark.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: neutralDark.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                              filled: false,
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
                                borderSide: BorderSide(color: primaryColor, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red.shade700, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name for your workout plan';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Description field
                          TextFormField(
                            controller: _descriptionController,
                            style: TextStyle(
                              color: neutralDark,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              hintText: 'Describe your workout plan goals and structure',
                              labelStyle: TextStyle(
                                color: neutralDark.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: neutralDark.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                              filled: false,
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
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveWorkoutPlan,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(_isEditing ? 'Update Plan' : 'Create Plan'),
                      ),
                    ),
                    
                    // Help text below button
                    if (!_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'You can add exercises to your workout plan after creation.',
                          style: TextStyle(
                            color: neutralDark.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper method to build a section card
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neutralMid, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: neutralDark,
              ),
            ),
          ),
          
          // Divider
          Divider(color: neutralMid, height: 1),
          
          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkoutPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        // Update existing workout plan
        await FirebaseFirestore.instance
            .collection('WorkoutPlans')
            .doc(widget.planId)
            .update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser!.uid,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Workout plan updated successfully'),
              backgroundColor: accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        // Create new workout plan
        final docRef = await FirebaseFirestore.instance
            .collection('WorkoutPlans')
            .add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'exercises': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser!.uid,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Workout plan created successfully'),
              backgroundColor: accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout plan: $error'),
            backgroundColor: Colors.red.shade700,
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