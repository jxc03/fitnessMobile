import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_details_screen.dart';
import 'add_exercise_screen.dart';
import 'workout_tracking_screen.dart';
import 'workout_history_screen.dart';
import 'workout_progress_screen.dart';

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
      print('Error fetching workout plan details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Workout Plan' : _workoutPlan?['name'] ?? 'Workout Plan'),
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
                            leading: const Icon(Icons.history),
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
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.show_chart),
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
      floatingActionButton: !_isLoading && _workoutPlan != null ? FloatingActionButton(
        onPressed: () => _navigateToAddExercise(),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_workoutPlan == null) {
      return const Center(child: Text('Workout plan not found'));
    }

    final exercises = _workoutPlan!['exercises'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workout Plan Info Section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_workoutPlan!['description'] != null && _workoutPlan!['description'].isNotEmpty)
                Text(
                  _workoutPlan!['description'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '${exercises.length} exercise${exercises.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // Exercises Section
        Expanded(
          child: exercises.isEmpty
              ? _buildEmptyExercisesState()
              : _buildExercisesList(exercises),
        ),
      ],
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Exercises Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add exercises to your workout plan',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddExercise(),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(List exercises) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
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
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise, index);
      },
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    return Card(
      key: ValueKey(exercise['exerciseId'] ?? index),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise number indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildExerciseDetail('Sets', '${exercise['sets'] ?? 3}'),
                      _buildExerciseDetail('Reps', exercise['reps'] ?? '10-12'),
                      _buildExerciseDetail('Rest', '${exercise['rest'] ?? 60}s'),
                    
                      // Show weight if it's greater than 0
                      if ((exercise['weight'] ?? 0) > 0)
                        _buildExerciseDetail(
                          'Weight', 
                          '${exercise['weight']}${exercise['weightUnit'] ?? 'kg'}'
                        ),
                    ],
                  ),
                  if (exercise['notes'] != null && exercise['notes'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Note: ${exercise['notes']}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _navigateToExerciseDetails(exercise['exerciseId']),
                  tooltip: 'View Exercise Details',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editExercise(exercise, index),
                  tooltip: 'Edit Exercise',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _confirmRemoveExercise(exercise, index),
                  tooltip: 'Remove Exercise',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
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
            const SnackBar(content: Text('Exercise not found')),
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
          SnackBar(content: Text('Error loading exercise details: $error')),
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
      title: const Text('Edit Exercise'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exercise name display
              Text(
                exercise['exerciseName'] ?? 'Unknown Exercise',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              // Sets
              TextFormField(
                initialValue: sets.toString(),
                decoration: const InputDecoration(
                  labelText: 'Sets',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Reps (e.g., "10" or "8-12")',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Rest (seconds)',
                  border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
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
          child: const Text('Cancel'),
        ),
        TextButton(
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
          const SnackBar(content: Text('Exercise updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating exercise: $error')),
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
          SnackBar(content: Text('Error updating exercise order: $error')),
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
          title: const Text('Remove Exercise'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to remove "${exercise['exerciseName']}" from this workout plan?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
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
          const SnackBar(content: Text('Exercise removed successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing exercise: $error')),
        );
      }
    }
  }

  void _startWorkout() async {
    if (_workoutPlan == null) return;
    final exercises = _workoutPlan!['exercises'] as List;
    
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add exercises to your workout plan before starting'),
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