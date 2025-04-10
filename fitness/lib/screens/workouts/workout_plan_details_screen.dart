import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../exercises/exercise_details_screen.dart';
import 'add_exercise_screen.dart';
import '../tracking/workout_tracking_screen.dart';
import '../tracking/workout_history_screen.dart';
import '../tracking/workout_progress_screen.dart';
import 'dart:developer'; // For using the log method
import 'dart:ui' show lerpDouble; // To drag exercises

class WorkoutPlanDetailScreen extends StatefulWidget {
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
    _fetchWorkoutPlanDetails();
  }

  Future<void> _fetchWorkoutPlanDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'Workout plan not found';
          _isLoading = false;
        });
        return;
      }

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
          if (!_isLoading && _workoutPlan != null) ... [
            // Analytics button
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
      body: _buildBody(),
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

    if (_workoutPlan == null) {
      return Center(
        child: Text(
          'Workout plan not found',
          style: TextStyle(color: neutralDark),
        ),
      );
    }

    final exercises = _workoutPlan!['exercises'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workout Plan Info Section
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_workoutPlan!['description'] != null && _workoutPlan!['description'].isNotEmpty)
                Text(
                  _workoutPlan!['description'],
                  style: TextStyle(
                    fontSize: 16,
                    color: neutralDark.withValues(alpha: 0.8),
                  ),
                ),
              const SizedBox(height: 8),
              _buildInfoBox(
                icon: Icons.fitness_center, 
                text: '${exercises.length} exercise${exercises.length != 1 ? 's' : ''}',
                color: secondaryColor,
              ),
            ],
          ),
        ),

        // Exercises Section
        Expanded(
          child: exercises.isEmpty
              ? _buildEmptyExercisesState()
              : _buildExercisesList(exercises),
        ),
      ],
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

  Widget _buildEmptyExercisesState() {
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
            'No Exercises Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add exercises to your workout plan',
            style: TextStyle(
              color: neutralDark.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
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
        buildDefaultDragHandles: false, // Disables the default drag handles
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = exercises.removeAt(oldIndex);
            exercises.insert(newIndex, item);

            // Update the order field for each exercise
            for (int i = 0; i < exercises.length; i++) {
              exercises[i]['order'] = i;
            }

            // Save the updated order to Firestore
            _updateExercisesOrder(exercises);
          });
        },
        // Custom drag feedback to make the dragging experience cleaner
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Material(
                elevation: 4.0 * animation.value,
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                child: child,
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          // Make the entire card draggable
          return ReorderableDragStartListener(
            key: ValueKey(exercise['exerciseId'] ?? index),
            index: index,
            child: _buildExerciseCard(exercise, index),
          );
        },
      ),
    );
  }
  

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
            // Exercise number indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [secondaryColor, primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Exercise details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['exerciseName'] ?? 'Unknown Exercise',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: neutralDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Exercise parameters
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _buildExerciseDetail('Sets', '${exercise['sets'] ?? 3}'),
                      _buildExerciseDetail('Reps', exercise['reps'] ?? '10-12'),
                      _buildExerciseDetail('Rest', '${exercise['rest'] ?? 60}s'),
                    
                      // Show weight if its greater than 0
                      if ((exercise['weight'] ?? 0) > 0)
                        _buildExerciseDetail(
                          'Weight', 
                          '${exercise['weight']}${exercise['weightUnit'] ?? 'kg'}'
                        ),
                    ],
                  ),
                  
                  // Notes, if any
                  if (exercise['notes'] != null && exercise['notes'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Note: ${exercise['notes']}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: neutralDark.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons column
            Column(
              children: [
                // Info button
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: neutralDark.withValues(alpha: 0.7),
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
                    color: neutralDark.withValues(alpha: 0.7),
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
            : neutralDark.withValues(alpha: 0.7),
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }

  Widget _buildExerciseDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: neutralDark.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
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

  void _navigateToExerciseDetails(String exerciseId) async {
    try {
      // Fetch the full exercise data
      final doc = await FirebaseFirestore.instance
          .collection('Exercises')
          .doc(exerciseId)
          .get();
      
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

  void _navigateToAddExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(workoutPlanId: widget.planId),
      ),
    );
    
    if (result == true) {
      _fetchWorkoutPlanDetails();
    }
  }

  void _editExercise(Map<String, dynamic> exercise, int index) {
    // Show dialog to edit exercise details
    showDialog(
      context: context,
      builder: (context) => _buildEditExerciseDialog(exercise, index),
    );
  }

  Widget _buildEditExerciseDialog(Map<String, dynamic> exercise, int index) {
    final formKey = GlobalKey<FormState>();
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
              // Exercise name display
              Text(
                exercise['exerciseName'] ?? 'Unknown Exercise',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: neutralDark,
                ),
              ),
              const SizedBox(height: 16),
              
              // Sets
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
              
              // Reps
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
              
              // Rest
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
              
              // Weight and unit
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

                  // Weight unit selector
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

              // Notes
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
                maxLines: 3,
                onSaved: (value) {
                  notes = value ?? '';
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: primaryColor),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              formKey.currentState!.save();
              Navigator.of(context).pop();
              
              // Update the exercise
              final updatedExercise = Map<String, dynamic>.from(exercise);
              updatedExercise['sets'] = sets;
              updatedExercise['reps'] = reps;
              updatedExercise['rest'] = rest;
              updatedExercise['weight'] = weight;
              updatedExercise['weightUnit'] = weightUnit;
              updatedExercise['notes'] = notes;
              
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

  Future<void> _updateExercise(Map<String, dynamic> updatedExercise, int index) async {
    try {
      final exercises = List.from(_workoutPlan!['exercises'] as List);
      exercises[index] = updatedExercise;
      
      await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .update({
        'exercises': exercises,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _workoutPlan!['exercises'] = exercises;
      });
      
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

  Future<void> _updateExercisesOrder(List exercises) async {
    try {
      await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .update({
        'exercises': exercises,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
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

  
Future<void> _confirmRemoveExercise(Map<String, dynamic> exercise, int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
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

  Future<void> _removeExercise(int index) async {
    try {
      final exercises = List.from(_workoutPlan!['exercises'] as List);
      exercises.removeAt(index);
      
      await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .update({
        'exercises': exercises,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _workoutPlan!['exercises'] = exercises;
      });
      
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

  void _startWorkout() async {
    if (_workoutPlan == null) return;
    final exercises = _workoutPlan!['exercises'] as List;
    
    if (exercises.isEmpty) {
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
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutTrackingScreen(
          workoutPlanId: widget.planId,
          workoutPlan: _workoutPlan!,
        ),
      ),
    );
  
    if (result == true) {
      _fetchWorkoutPlanDetails(); // Refresh workout plan details after workout completion
    }
  }
}