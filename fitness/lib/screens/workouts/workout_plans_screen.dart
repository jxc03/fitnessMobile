import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_plan_details_screen.dart';
import 'create_workout_plan_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

/// A screen that displays all workout plans created by the current user
/// This widget fetches workout plans from Firestore and allows users to:
/// View a list of their workout plans
/// Create new workout plans
/// Edit existing workout plans
/// Delete workout plans
/// View detailed information about each plan
class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  bool _isLoading = true; // Loading state indicator
  List<Map<String, dynamic>> _workoutPlans = [];// List of workout plans from Firestore
  String? _errorMessage; // Error message if fetch operation fails

  // App colour palette
  static const Color primaryColor = Color(0xFF2A6F97); // Deep blue 
  static const Color secondaryColor = Color(0xFF61A0AF); // Teal blue 
  static const Color accentGreen = Color(0xFF4C956C); // Forest green 
  static const Color accentTeal = Color(0xFF2F6D80); // Deep teal 
  static const Color neutralDark = Color(0xFF3D5A6C); // Dark slate 
  static const Color neutralLight = Color(0xFFF5F7FA); // Light gray 
  static const Color neutralMid = Color(0xFFE1E7ED); // Mid gray 

  @override
  void initState() {
    super.initState();
    _fetchWorkoutPlans(); // Fetch workout plans when the screen initialises
  }

  /// Fetches workout plans from Firestore for the current user
  /// Queries the 'WorkoutPlans' collection, filtering for plans
  /// created by the current authenticated user and orders them by creation date
  Future<void> _fetchWorkoutPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the current user ID for filtering workout plans
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      // Query Firestore for this user's workout plans, sorted by creation date
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedPlans = [];

      // Process each document in the query results
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

      // Update the state with the fetched workout plans
      setState(() {
        _workoutPlans = loadedPlans;
        _isLoading = false;
      });
    } catch (error) {
      // Handle any errors that occur during fetch
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
      body: _buildBody(), // Main content area with conditional rendering
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

  /// Builds the main body content based on the current state
  /// This method conditionally renders:
  /// A loading indicator when data is being fetched
  /// An error message if the fetch operation failed
  /// An empty state UI if no workout plans exist
  /// A list of workout plan cards if plans are available
  Widget _buildBody() {
    if (_isLoading) {
      // Show loading indicator while fetching data
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      // Show error message if fetch operation failed
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }

    if (_workoutPlans.isEmpty) {
      // Show empty state if no workout plans exist
      return _buildEmptyState();
    }

    // Show list of workout plans
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workoutPlans.length,
      itemBuilder: (context, index) {
        final plan = _workoutPlans[index];
        return _buildWorkoutPlanCard(plan);
      },
    );
  }

  /// Builds the empty state UI when no workout plans exist
  /// Displays a placeholder with instructions and a button to create the first workout plan
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fitness icon
          Icon(
            Icons.fitness_center,
            size: 80,
            color: neutralDark.withValues(alpha: 0.3), // 30% opacity
          ),
          const SizedBox(height: 16),
          // Empty state title
          Text(
            'No Workout Plans Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          // Empty state description
          Text(
            'Create your first workout plan to get started!',
            style: TextStyle(
              color: neutralDark.withValues(alpha: 0.7), // 70% opacity
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          // Create workout plan button
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

  /// Builds a card widget for displaying a workout plan
  /// Each card shows:
  /// The plan name and description
  /// Number of exercises in the plan
  /// Options to edit or delete the plan
  /// A button to view plan details
  Widget _buildWorkoutPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: neutralMid, width: 1),
      ),
      child: InkWell( // Make the entire card tappable
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
                  // Plan name with overflow handling
                  Expanded(
                    child: Text(
                      plan['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: neutralDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // "..." if text is too long
                    ),
                  ),
                  // Popup menu for edit/delete options
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
                      color: neutralDark.withValues(alpha: 0.7), // 70% opacity
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: neutralMid, width: 1),
                    ),
                    color: Colors.white,
                    elevation: 1,
                    itemBuilder: (context) => [
                      // Edit option
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
                      // Delete option
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
              // Plan description - only shown if available
              if (plan['description'] != null && plan['description'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    plan['description'],
                    style: TextStyle(
                      color: neutralDark.withValues(alpha: 0.7), // 70% opacity
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // "..." if text is too long
                  ),
                ),
              const SizedBox(height: 16),
              // Bottom section with exercise count and action button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise count indicator with proper pluralisation
                      _buildInfoBox(
                        icon: Icons.fitness_center, 
                        text: '${plan['exerciseCount']} exercise${plan['exerciseCount'] != 1 ? 's' : ''}',
                        color: secondaryColor,
                      ),
                      const SizedBox(height: 12),
                      // View details button
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

  /// Builds a styled information box with icon and text
  /// Used for displaying metadata about the workout plan like the number of exercises
  Widget _buildInfoBox({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), // 12% opacity background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3), // 30% opacity border
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color.withValues(alpha: 0.9), // 90% opacity icon
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color.withValues(alpha: 0.9), // 90% opacity text
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigates to the workout plan detail screen for a specific plan
  /// When returning from the detail screen, refreshes the list of workout plans to ensure data consistency
  void _navigateToWorkoutPlanDetail(String planId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPlanDetailScreen(planId: planId),
      ),
    ).then((_) => _fetchWorkoutPlans()); // Refresh plans after returning
  }

  /// Navigates to the screen for creating a new workout plan
  /// When returning from the creation screen, refreshes the list of workout plans to include the newly created plan.
  void _navigateToCreateWorkoutPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutPlanScreen(),
      ),
    ).then((_) => _fetchWorkoutPlans()); // Refresh plans after returning
  }

  /// Navigates to the screen for editing an existing workout plan.
  /// Uses the same CreateWorkoutPlanScreen but passes the planId parameter to indicate edit mode. Refreshes the list after returning.
  void _navigateToEditWorkoutPlan(String planId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutPlanScreen(planId: planId),
      ),
    ).then((_) => _fetchWorkoutPlans()); // Refresh plans after returning
  }

  /// Shows a confirmation dialog before deleting a workout plan.
  /// Displays the plan name and warns that the action cannot be undone.
  /// Provides options to cancel or confirm the deletion.
  Future<void> _confirmDeleteWorkoutPlan(String planId, String planName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
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
                  style: TextStyle(color: neutralDark.withValues(alpha: 0.7)), // 70% opacity
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // Cancel button
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Delete button
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

  /// Deletes a workout plan from Firestore
  /// Attempts to delete the document with the specified planId,
  /// then refreshes the workout plans list and shows a success or error message as appropriate
  Future<void> _deleteWorkoutPlan(String planId) async {
    try {
      // Delete the document from Firestore
      await FirebaseFirestore.instance.collection('WorkoutPlans').doc(planId).delete();
      _fetchWorkoutPlans(); // Refresh the list
      
      // Show success message if the widget is still mounted
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
      // Show error message if deletion fails and the widget is still mounted
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