import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../exercises/exercise_details_screen.dart';
import 'add_exercise_screen.dart';
import '../tracking/workout_tracking_screen.dart';
import '../tracking/workout_history_screen.dart';
import '../tracking/workout_progress_screen.dart';
import 'dart:developer'; // For using the log method for debugging
import 'dart:ui' show lerpDouble; // For gradient calculations when dragging exercises

/// Displays detailed information about a specific workout plan
/// This widget fetches the workout plan data from Firestore and allows users to:
/// View all exercises in the workout plan
/// Add new exercises to the plan
/// Edit exercise parameters (sets, reps, rest time, weight)
/// Reorder exercises by dragging them
/// Remove exercises from the plan
/// Start a workout session based on this plan
/// View workout history and progress analytics
class WorkoutPlanDetailScreen extends StatefulWidget {
  /// The Firestore document ID of the workout plan to display
  final String planId;

  const WorkoutPlanDetailScreen({
    super.key,
    required this.planId,
  });

  @override
  State<WorkoutPlanDetailScreen> createState() => _WorkoutPlanDetailScreenState();
}

class _WorkoutPlanDetailScreenState extends State<WorkoutPlanDetailScreen> {
  bool _isLoading = true;                     
  Map<String, dynamic>? _workoutPlan;         
  String? _errorMessage;                      

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
    _fetchWorkoutPlanDetails(); // Fetch workout plan data when the screen initialises
  }

  /// Fetches the workout plan details from Firestore
  /// Retrieves the complete workout plan document based on the planId
  /// provided to the widget and updates the state accordingly
  Future<void> _fetchWorkoutPlanDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Query the specific workout plan document from Firestore
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .get();

      // Handle case where document doesn't exist
      if (!doc.exists) {
        setState(() {
          _errorMessage = 'Workout plan not found';
          _isLoading = false;
        });
        return;
      }

      // Process the document data and update state
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _workoutPlan = {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Workout',
          'description': data['description'] ?? '',
          'exercises': data['exercises'] ?? [],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
        _isLoading = false;
      });
    } catch (error) {
      // Handle any errors during fetch operation
      setState(() {
        _errorMessage = 'Failed to load workout plan details: $error';
        _isLoading = false;
      });
      log('Error fetching workout plan details: $error', name: 'WorkoutPlanDetailScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralLight,
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Workout Plan' : _workoutPlan?['name'] ?? 'Workout Plan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Only show action buttons when data is loaded
          if (!_isLoading && _workoutPlan != null) ... [
            // Analytics/insights button with bottom sheet options
            IconButton(
              icon: const Icon(Icons.insights),
              tooltip: 'View Analytics',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Workout history option
                          ListTile(
                            leading: Icon(Icons.history, color: primaryColor),
                            title: const Text('Workout History'),
                            subtitle: const Text('View your past workouts'),
                            onTap: () {
                              Navigator.pop(context); // Close the bottom sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WorkoutHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(color: neutralMid),
                          // Progress analytics option
                          ListTile(
                            leading: Icon(Icons.show_chart, color: primaryColor),
                            title: const Text('Progress Analytics'),
                            subtitle: const Text('Track your exercise improvements'),
                            onTap: () {
                              Navigator.pop(context); // Close the bottom sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WorkoutProgressScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            // Start workout button
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Start Workout',
              onPressed: () => _startWorkout(),
            ),
          ]
        ],
      ),
      body: _buildBody(), // Main content area with conditional rendering
      // Only show FAB when workout plan is loaded
      floatingActionButton: !_isLoading && _workoutPlan != null 
        ? FloatingActionButton.extended(
            onPressed: () => _navigateToAddExercise(),
            backgroundColor: primaryColor,
            elevation: 2,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Exercise',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ) 
        : null,
    );
  }

  /// Builds the main body content based on the current state
  /// This method conditionally renders:
  /// A loading indicator when data is being fetched
  /// An error message if the fetch operation failed
  /// A "not found" message if the workout plan doesn't exist
  /// The complete workout plan details with exercises if data is available
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

    if (_workoutPlan == null) {
      // Show message if workout plan not found
      return Center(
        child: Text(
          'Workout plan not found',
          style: TextStyle(color: neutralDark),
        ),
      );
    }

    // Extract the exercises list from the workout plan
    final exercises = _workoutPlan!['exercises'] as List;

    // Build the complete workout plan details UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workout Plan Info Section with description and exercise count
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show description if available
              if (_workoutPlan!['description'] != null && _workoutPlan!['description'].isNotEmpty)
                Text(
                  _workoutPlan!['description'],
                  style: TextStyle(
                    fontSize: 16,
                    color: neutralDark.withValues(alpha: 0.8), // 80% opacity
                  ),
                ),
              const SizedBox(height: 8),
              // Exercise count indicator with proper pluralisation
              _buildInfoBox(
                icon: Icons.fitness_center, 
                text: '${exercises.length} exercise${exercises.length != 1 ? 's' : ''}',
                color: secondaryColor,
              ),
            ],
          ),
        ),

        // Exercises List Section - takes remaining screen space
        Expanded(
          child: exercises.isEmpty
              ? _buildEmptyExercisesState() // Empty state if no exercises
              : _buildExercisesList(exercises), // List of exercises if available
        ),
      ],
    );
  }

  /// Builds a styled information box with icon and text
  /// Used to display metadata about the workout plan like the number of exercises.
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

  /// Builds the empty state UI when no exercises exist in the plan
  /// Displays a placeholder with instructions and a button to add the first exercise to the workout plan.
  Widget _buildEmptyExercisesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Exercise icon
          Icon(
            Icons.fitness_center,
            size: 80,
            color: neutralDark.withValues(alpha: 0.3), // 30% opacity
          ),
          const SizedBox(height: 16),
          // Empty state title
          Text(
            'No Exercises Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          // Empty state description
          Text(
            'Add exercises to your workout plan',
            style: TextStyle(
              color: neutralDark.withValues(alpha: 0.7), // 70% opacity
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          // Add exercise button
          ElevatedButton.icon(
            onPressed: () => _navigateToAddExercise(),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a reorderable list of exercises in the workout plan
  /// This widget supports drag-and-drop reordering of exercises with custom styling for the drag feedback.
  Widget _buildExercisesList(List exercises) {
    return Theme(
      // Override the default selection color/behavior when dragging
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exercises.length,
        buildDefaultDragHandles: false, // Disables the default drag handles for custom behavior
        onReorder: (oldIndex, newIndex) {
          // Handle the reordering of exercises
          setState(() {
            // Adjust the newIndex to account for the item removal
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            // Remove the item from the old position and insert at the new position
            final item = exercises.removeAt(oldIndex);
            exercises.insert(newIndex, item);

            // Update the order field for each exercise to maintain correct order
            for (int i = 0; i < exercises.length; i++) {
              exercises[i]['order'] = i;
            }

            // Save the updated order to Firestore
            _updateExercisesOrder(exercises);
          });
        },
        // Custom drag feedback animation for a better user experience
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Material(
                elevation: 4.0 * animation.value, // Gradually increase elevation during drag
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                shadowColor: Colors.black.withValues(alpha: 0.1), // 10% opacity shadow
                child: child,
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          // Make the entire card draggable using ReorderableDragStartListener
          return ReorderableDragStartListener(
            key: ValueKey(exercise['exerciseId'] ?? index), // Unique key for each exercise
            index: index,
            child: _buildExerciseCard(exercise, index),
          );
        },
      ),
    );
  }
  
  /// Builds a card for displaying a single exercise in the workout plan
  /// Each card shows:
  /// Exercise name
  /// Training parameters (sets, reps, rest time, weight)
  /// Optional notes
  /// Buttons for viewing details, editing, and deleting
  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: neutralMid, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise number indicator with gradient background
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [secondaryColor, primaryColor], // Gradient from secondary to primary
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2), // 20% opacity shadow
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}', // 1 - based numbering for display
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Exercise details (name, sets, reps, etc.)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name
                  Text(
                    exercise['exerciseName'] ?? 'Unknown Exercise',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: neutralDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Exercise parameters (sets, reps, rest, weight) in a wrap layout
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _buildExerciseDetail('Sets', '${exercise['sets'] ?? 3}'),
                      _buildExerciseDetail('Reps', exercise['reps'] ?? '10-12'),
                      _buildExerciseDetail('Rest', '${exercise['rest'] ?? 60}s'),
                    
                      // Show weight only if it's greater than 0
                      if ((exercise['weight'] ?? 0) > 0)
                        _buildExerciseDetail(
                          'Weight', 
                          '${exercise['weight']}${exercise['weightUnit'] ?? 'kg'}'
                        ),
                    ],
                  ),
                  
                  // Optional notes for the exercise
                  if (exercise['notes'] != null && exercise['notes'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Note: ${exercise['notes']}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: neutralDark.withValues(alpha: 0.7), // 70% opacity
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons column (view details, edit, delete)
            Column(
              children: [
                // Info/details button
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: neutralDark.withValues(alpha: 0.7), // 70% opacity
                  ),
                  onPressed: () => _navigateToExerciseDetails(exercise['exerciseId']),
                  tooltip: 'View Exercise Details',
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
                
                // Edit button
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: neutralDark.withValues(alpha: 0.7), // 70% opacity
                  ),
                  onPressed: () => _editExercise(exercise, index),
                  tooltip: 'Edit Exercise',
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
                
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                  onPressed: () => _confirmRemoveExercise(exercise, index),
                  tooltip: 'Remove Exercise',
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a reusable action button with icon and tooltip
  /// Note: This method is not currently used in the widget but
  /// provides a template for consistent action buttons.
  Widget _buildActionButton({
    required IconData icon, 
    required VoidCallback onPressed, 
    required String tooltip,
    bool isDestructive = false,
  }) {
    return IconButton(
      icon: Icon(
        icon, 
        size: 20,
        color: isDestructive 
            ? Colors.red.shade700 
            : neutralDark.withValues(alpha: 0.7), // 70% opacity for non-destructive actions
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }

  /// Builds a labeled detail for exercise parameters
  /// This widget displays a parameter label and its value,
  /// used for showing sets, reps, rest time, and weight.
  Widget _buildExerciseDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parameter label (e.g., "Sets", "Reps")
        Text(
          label,
          style: TextStyle(
            color: neutralDark.withValues(alpha: 0.6), // 60% opacity
            fontSize: 12,
          ),
        ),
        // Parameter value (e.g., "3", "10-12")
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: neutralDark,
          ),
        ),
      ],
    );
  }

  /// Navigates to the exercise details screen for a specific exercise
  /// Fetches the full exercise data from Firestore before navigation,
  /// as the workout plan only contains a subset of exercise properties
  void _navigateToExerciseDetails(String exerciseId) async {
    try {
      // Fetch the complete exercise data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('Exercises')
          .doc(exerciseId)
          .get();
      
      // Handle case where exercise document doesn't exist
      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Exercise not found'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }
      
      // Process exercise data and navigate to details screen
      final exerciseData = doc.data() as Map<String, dynamic>;
      exerciseData['id'] = doc.id;
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: exerciseData),
          ),
        );
      }
    } catch (error) {
      // Handle errors during fetch operation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exercise details: $error'),
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

  /// Navigates to the add exercise screen for this workout plan
  /// After returning from the screen, refreshes the workout plan details
  /// if an exercise was added (result == true)
  void _navigateToAddExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(workoutPlanId: widget.planId),
      ),
    );
    
    // Refresh the workout plan details if an exercise was added
    if (result == true) {
      _fetchWorkoutPlanDetails();
    }
  }

  /// Opens a dialog to edit the parameters of an exercise
  /// Shows a form with fields for sets, reps, rest time, weight,
  /// weight unit and notes
  void _editExercise(Map<String, dynamic> exercise, int index) {
    // Show dialog with form to edit exercise parameters
    showDialog(
      context: context,
      builder: (context) => _buildEditExerciseDialog(exercise, index),
    );
  }

  /// Builds the dialog for editing exercise parameters
  /// Creates a form with validators and default values based on the current exercise parameters.
  Widget _buildEditExerciseDialog(Map<String, dynamic> exercise, int index) {
    final formKey = GlobalKey<FormState>();
    // Initialize form values with current exercise parameters
    int sets = exercise['sets'] ?? 3;
    String reps = exercise['reps'] ?? '10-12';
    int rest = exercise['rest'] ?? 60;
    double weight = exercise['weight'] ?? 0.0;
    String weightUnit = exercise['weightUnit'] ?? 'kg';
    String notes = exercise['notes'] ?? '';

    return AlertDialog(
      title: Text(
        'Edit Exercise',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: neutralDark,
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: neutralMid, width: 1),
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exercise name (non-editable)
              Text(
                exercise['exerciseName'] ?? 'Unknown Exercise',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: neutralDark,
                ),
              ),
              const SizedBox(height: 16),
              
              // Sets input field
              TextFormField(
                initialValue: sets.toString(),
                decoration: InputDecoration(
                  labelText: 'Sets',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of sets';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  sets = int.parse(value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Reps input field (can be a range like "8-12")
              TextFormField(
                initialValue: reps,
                decoration: InputDecoration(
                  labelText: 'Reps (e.g., "10" or "8-12")',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reps';
                  }
                  return null;
                },
                onSaved: (value) {
                  reps = value!;
                },
              ),
              const SizedBox(height: 16),
              
              // Rest time input field (in seconds)
              TextFormField(
                initialValue: rest.toString(),
                decoration: InputDecoration(
                  labelText: 'Rest (seconds)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rest time';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  rest = int.parse(value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Weight and unit input fields (side by side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight input field
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: weight.toString(),
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null; // Weight can be empty
                        }
                        if (double.tryParse(value) == null || double.parse(value) < 0) {
                          return 'Enter a valid weight';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        weight = value != null && value.isNotEmpty ? double.parse(value) : 0.0;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Weight unit selector (kg/lb)
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      value: weightUnit,
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'lb', child: Text('lb')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          weightUnit = value;
                        }
                      },
                      onSaved: (value) {
                        weightUnit = value ?? 'kg';
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes input field (multi-line, optional)
              TextFormField(
                initialValue: notes,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                maxLines: 3, // Allow multiple lines for notes
                onSaved: (value) {
                  notes = value ?? '';
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: primaryColor),
          ),
        ),
        // Save button
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              formKey.currentState!.save();
              Navigator.of(context).pop();
              
              // Create updated exercise with new parameters
              final updatedExercise = Map<String, dynamic>.from(exercise);
              updatedExercise['sets'] = sets;
              updatedExercise['reps'] = reps;
              updatedExercise['rest'] = rest;
              updatedExercise['weight'] = weight;
              updatedExercise['weightUnit'] = weightUnit;
              updatedExercise['notes'] = notes;
              
              // Update the exercise in Firestore
              _updateExercise(updatedExercise, index);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Updates an exercise in the workout plan
  /// Saves the updated exercise parameters to Firestore and updates the local state to reflect the changes.
  Future<void> _updateExercise(Map<String, dynamic> updatedExercise, int index) async {
    try {
      // Create a copy of the exercises list
      final exercises = List.from(_workoutPlan!['exercises'] as List);
      // Replace the exercise at the specified index
      exercises[index] = updatedExercise;
      
      // Update the Firestore document
      await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .update({
        'exercises': exercises,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update the local state
      setState(() {
        _workoutPlan!['exercises'] = exercises;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Exercise updated successfully'),
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
      // Show error message if update fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating exercise: $error'),
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

  /// Updates the order of exercises in the workout plan
  /// Saves the reordered exercises list to Firestore after  a drag-and-drop operation.
  Future<void> _updateExercisesOrder(List exercises) async {
    try {
      // Update the Firestore document with the new exercise order
      await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .update({
        'exercises': exercises,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Show error message if update fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating exercise order: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      // Revert to the previous state if there's an error
      _fetchWorkoutPlanDetails();
    }
  }

  
  /// Shows a confirmation dialog before removing an exercise from the plan
  /// Displays the exercise name and provides options to cancel or confirm the removal.
  Future<void> _confirmRemoveExercise(Map<String, dynamic> exercise, int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Remove Exercise',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: neutralDark,
            ),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: neutralMid, width: 1),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to remove "${exercise['exerciseName']}" from this workout plan?',
                  style: TextStyle(color: neutralDark),
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
            // Remove button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                _removeExercise(index);
              },
            ),
          ],
        );
      },
    );
  }

  /// Removes an exercise from the workout plan
  /// Deletes the exercise at the specified index from the Firestore document
  /// and updates the local state to reflect the change.
  Future<void> _removeExercise(int index) async {
    try {
      // Create a copy of the exercises list
      final exercises = List.from(_workoutPlan!['exercises'] as List);
      // Remove the exercise at the specified index
      exercises.removeAt(index);
      
      // Update the Firestore document
      await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .update({
        'exercises': exercises,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update the local state
      setState(() {
        _workoutPlan!['exercises'] = exercises;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Exercise removed successfully'),
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
      // Show error message if removal fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing exercise: $error'),
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

  /// Starts a workout session based on this workout plan
  /// Navigates to the workout tracking screen if the plan has exercises,
  /// otherwise shows an error message.
  void _startWorkout() async {
    if (_workoutPlan == null) return;
    final exercises = _workoutPlan!['exercises'] as List;
    
    // Check if the workout plan has exercises
    if (exercises.isEmpty) {
      // Show error message if no exercises in plan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add exercises to your workout plan before starting'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    
    // Navigate to the workout tracking screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutTrackingScreen(
          workoutPlanId: widget.planId,
          workoutPlan: _workoutPlan!,
        ),
      ),
    );
  
    // Refresh the workout plan details if workout was completed
    if (result == true) {
      _fetchWorkoutPlanDetails();
    }
  }
}