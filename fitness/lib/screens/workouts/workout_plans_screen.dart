import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_plan_details_screen.dart';
import 'create_workout_plan_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _workoutPlans = [];
  String? _errorMessage;

  // App colour palette 
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
    _fetchWorkoutPlans();
  }

  Future<void> _fetchWorkoutPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the current user ID
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedPlans = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        loadedPlans.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Workout',
          'description': data['description'] ?? '',
          'exerciseCount': (data['exercises'] as List?)?.length ?? 0,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'userId': data['userId'],
        });
      }

      setState(() {
        _workoutPlans = loadedPlans;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load workout plans: $error';
        _isLoading = false;
      });
      log('Error fetching workout plans: $error', name: 'WorkoutPlansScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralLight,
      appBar: AppBar(
        title: const Text(
          'Workout Plans',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateWorkoutPlan(),
        backgroundColor: primaryColor,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Workout Plan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }

    if (_workoutPlans.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workoutPlans.length,
      itemBuilder: (context, index) {
        final plan = _workoutPlans[index];
        return _buildWorkoutPlanCard(plan);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: neutralDark.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Workout Plans Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first workout plan to get started!',
            style: TextStyle(
              color: neutralDark.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateWorkoutPlan(),
            icon: const Icon(Icons.add),
            label: const Text('Create Workout Plan'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildWorkoutPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: neutralMid, width: 1),
      ),
      child: InkWell( // If the user clicks on the card
        onTap: () => _navigateToWorkoutPlanDetail(plan['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header with title and menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: neutralDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEditWorkoutPlan(plan['id']);
                      } else if (value == 'delete') {
                        _confirmDeleteWorkoutPlan(plan['id'], plan['name']);
                      }
                    },
                    icon: Icon(
                      Icons.more_vert,
                      color: neutralDark.withValues(alpha: 0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: neutralMid, width: 1),
                    ),
                    color: Colors.white,
                    elevation: 1,
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(color: neutralDark),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (plan['description'] != null && plan['description'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    plan['description'],
                    style: TextStyle(
                      color: neutralDark.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoBox(
                        icon: Icons.fitness_center, 
                        text: '${plan['exerciseCount']} exercise${plan['exerciseCount'] != 1 ? 's' : ''}',
                        color: secondaryColor,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _navigateToWorkoutPlanDetail(plan['id']),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailsButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null, // This is handled by the InkWell on the entire card
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'View Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _navigateToWorkoutPlanDetail(String planId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPlanDetailScreen(planId: planId),
      ),
    ).then((_) => _fetchWorkoutPlans()); // Refresh after returning
  }

  void _navigateToCreateWorkoutPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutPlanScreen(),
      ),
    ).then((_) => _fetchWorkoutPlans()); // Refresh after returning
  }

  void _navigateToEditWorkoutPlan(String planId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutPlanScreen(planId: planId),
      ),
    ).then((_) => _fetchWorkoutPlans()); // Refresh after returning
  }

  Future<void> _confirmDeleteWorkoutPlan(String planId, String planName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Workout Plan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: neutralDark,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: neutralMid, width: 1),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete "$planName"?',
                  style: TextStyle(color: neutralDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: neutralDark.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red.shade700),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteWorkoutPlan(planId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteWorkoutPlan(String planId) async {
    try {
      await FirebaseFirestore.instance.collection('WorkoutPlans').doc(planId).delete();
      _fetchWorkoutPlans(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout plan deleted successfully'),
            backgroundColor: accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting workout plan: $error'),
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