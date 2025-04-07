import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Database for storing workout data
import 'package:firebase_auth/firebase_auth.dart'; // Authentication for user identification

class WorkoutTrackingScreen extends StatefulWidget {
  final String workoutPlanId;
  final Map<String, dynamic> workoutPlan;

  const WorkoutTrackingScreen({
    super.key,
    required this.workoutPlanId,
    required this.workoutPlan,
  });

  @override
  State<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends State<WorkoutTrackingScreen> {
  // Loading state management
  bool _isLoading = false; 

  // Exercise naviagation
  // Index of the exercise currently being performed
  // List of all exercises in this workout
  int _currentExerciseIndex = 0;
  List<Map<String, dynamic>> _exercises = [];
  
  // Track completed sets and performance data
  final Map<int, List<bool>> _completedSets = {};
  final Map<int, List<Map<String, dynamic>>> _setPerformances = {};
  
  // Timer for rest periods
  // Remaining time (seconds) current rest period
  // Wether the user is currently resting or not, initially set to false 
  int _restTimeRemaining = 0;
  bool _isResting = false; 

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  void _initializeWorkout() {
    setState(() {
      _isLoading = true;
    });

    // Get the exercises from the workout plan
    // Converts the exercises to a list of maps
    final exercises = widget.workoutPlan['exercises'] as List; 
    _exercises = List<Map<String, dynamic>>.from(exercises); 

    // Loop through each exercise and initialise completed sets and performance data
    // Set i to 0 and increment it by 1 until it reaches the length of the exercises list
    for (int i = 0; i < _exercises.length; i++) {
      // Get the current exercise from the list of exercises 
      // Get the number of sets for the current exercise, default to 3 if not specified
      final exercise = _exercises[i]; 
      final sets = exercise['sets'] as int? ?? 3;
      
      // Create list to track each completed sets for this exercise, starts as false (not completed)
      _completedSets[i] = List.filled(sets, false);

      // Create list to track performance data for each set
      _setPerformances[i] = List.generate(sets, (_) => {
        'actualReps': 0,
        'actualWeight': exercise['weight'] ?? 0.0,
        'weightUnit': exercise['weightUnit'] ?? 'kg',
        'rating': 0, // 0 = not rated, 1-5 = difficulty rating
      });
    }

    // Update state to reflect that the workout has been initialised
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workoutPlan['name'] ?? 'Workout Session'),
          actions: [
            TextButton.icon(
              onPressed: _showWorkoutSummary,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Finish'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildWorkoutTracker(),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workout?'),
        content: const Text('Are you sure you want to exit this workout? Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
        ],
      ),
    ) ??
    false;
  }

  Widget _buildWorkoutTracker() {
    if (_exercises.isEmpty) {
      return const Center(child: Text('No exercises in this workout plan'));
    }

    if (_isResting) {
      return _buildRestTimer();
    }

    
    final currentExercise = _exercises[_currentExerciseIndex];
    final sets = currentExercise['sets'] as int? ?? 3;
    final reps = currentExercise['reps'] as String? ?? '10-12';
    final weight = currentExercise['weight'] ?? 0.0;
    final weightUnit = currentExercise['weightUnit'] ?? 'kg';

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Exercise ${_currentExerciseIndex + 1}/${_exercises.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Total: ${_calculateCompletedExercises()} completed',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        
        // Exercise information
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentExercise['exerciseName'] ?? 'Exercise',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Target: $sets sets of $reps reps'),
                  if (weight > 0)
                    Text('Weight: $weight$weightUnit'),
                  if (currentExercise['notes'] != null && currentExercise['notes'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${currentExercise['notes']}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Sets tracking
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets,
            itemBuilder: (context, setIndex) {
              final isCompleted = _completedSets[_currentExerciseIndex]![setIndex];
              final performance = _setPerformances[_currentExerciseIndex]![setIndex];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Set ${setIndex + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (isCompleted)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                          else
                            OutlinedButton(
                              onPressed: () => _markSetCompleted(setIndex),
                              child: const Text('Complete Set'),
                            ),
                        ],
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPerformanceItem(
                                'Reps', 
                                performance['actualReps'].toString()
                              ),
                            ),
                            Expanded(
                              child: _buildPerformanceItem(
                                'Weight', 
                                '${performance['actualWeight']}${performance['weightUnit']}'
                              ),
                            ),
                            Expanded(
                              child: _buildRatingIndicator(performance['rating']),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentExerciseIndex > 0)
                ElevatedButton.icon(
                  onPressed: _previousExercise,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (_currentExerciseIndex < _exercises.length - 1)
                ElevatedButton.icon(
                  onPressed: _nextExercise,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_currentExerciseIndex == _exercises.length - 1)
                ElevatedButton.icon(
                  onPressed: _showWorkoutSummary,
                  icon: const Icon(Icons.check),
                  label: const Text('Finish Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingIndicator(int rating) {
    return Column(
      children: [
        Text(
          'Difficulty',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              Icons.star,
              size: 16,
              color: index < rating ? Colors.amber : Colors.grey.shade300,
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildRestTimer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'REST TIME',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$_restTimeRemaining',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _skipRest,
            child: const Text('Skip Rest'),
          ),
        ],
      ),
    );
  }

  void _markSetCompleted(int setIndex) {
    final currentExercise = _exercises[_currentExerciseIndex];
    
    // Show dialog to log performance
    showDialog(
      context: context,
      builder: (context) => _buildSetCompletionDialog(currentExercise, setIndex),
    );
  }

  Widget _buildSetCompletionDialog(Map<String, dynamic> exercise, int setIndex) {
    final targetReps = exercise['reps'] as String? ?? '10-12';
    final initialWeight = exercise['weight'] ?? 0.0;
    final initialWeightUnit = exercise['weightUnit'] ?? 'kg';
    
    int actualReps = 0;
    double actualWeight = initialWeight;
    String weightUnit = initialWeightUnit;
    int rating = 0;

    return AlertDialog(
      title: Text('Set ${setIndex + 1} Completed'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Target: $targetReps reps'),
            const SizedBox(height: 16),
            
            // Actual reps input
            TextField(
              decoration: const InputDecoration(
                labelText: 'Actual Reps',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                actualReps = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            
            // Weight input
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight input field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: TextEditingController(text: initialWeight.toString()),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      actualWeight = double.tryParse(value) ?? initialWeight;
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
                    value: initialWeightUnit,
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'lb', child: Text('lb')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        weightUnit = value;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Difficulty rating
            const Text(
              'How difficult was this set?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < rating ? Colors.amber : Colors.grey.shade300,
                  ),
                  onPressed: () {
                    rating = index + 1;
                    (context as Element).markNeedsBuild();
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            
            // Save the performance data
            setState(() {
              _completedSets[_currentExerciseIndex]![setIndex] = true;
              _setPerformances[_currentExerciseIndex]![setIndex] = {
                'actualReps': actualReps,
                'actualWeight': actualWeight,
                'weightUnit': weightUnit,
                'rating': rating,
              };
            });
            
            // Start rest timer if configured
            final restTime = exercise['rest'] as int? ?? 60;
            if (restTime > 0) {
              _startRestTimer(restTime);
            }
            
            // Check if all sets are completed
            if (_isSetCompleted(_currentExerciseIndex)) {
              // Analyse performance and suggest adjustments
              _analysePerformance(_currentExerciseIndex);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  bool _isSetCompleted(int exerciseIndex) {
    return _completedSets[exerciseIndex]!.every((isCompleted) => isCompleted);
  }

  void _analysePerformance(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final sets = exercise['sets'] as int? ?? 3;
    final performances = _setPerformances[exerciseIndex]!;
    
    // Calculate average rating
    double totalRating = 0;
    for (var performance in performances) {
      totalRating += performance['rating'] as int? ?? 0;
    }
    final avgRating = totalRating / sets;
    
    // Display recommendations based on difficulty
    String message;
    Color messageColor;
    
    if (avgRating < 1.5) {
      message = 'This was too easy! Consider increasing weight by 5-10%.';
      messageColor = Colors.green;
    } else if (avgRating < 3.5) {
      message = 'Great job! This was a good challenge level.';
      messageColor = Colors.blue;
    } else {
      message = 'This was quite difficult. Consider reducing weight by 5-10% or doing fewer reps.';
      messageColor = Colors.orange;
    }
    
    // Show a feedback popup
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exercise Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              exercise['exerciseName'] ?? 'Exercise',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: messageColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Automatically move to next exercise if not the last one
              if (_currentExerciseIndex < _exercises.length - 1) {
                _nextExercise();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

   void _startRestTimer(int seconds) {
    setState(() {
      _isResting = true;
      _restTimeRemaining = seconds;
    });
    
    // Create a timer to update the countdown
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if we're still in resting state
      if (!mounted || !_isResting) {
        return false;
      }
      
      setState(() {
        _restTimeRemaining--;
      });
      
      // Continue timer if time remaining
      if (_restTimeRemaining <= 0) {
        setState(() {
          _isResting = false;
        });
        return false;
      }
      
      return true;
    });
  }

  void _skipRest() {
    setState(() {
      _isResting = false;
    });
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    }
  }

  int _calculateCompletedExercises() {
    int completedCount = 0;
    for (int i = 0; i < _exercises.length; i++) {
      if (_isSetCompleted(i)) {
        completedCount++;
      }
    }
    return completedCount;
  }

  void _showWorkoutSummary() {
    // Prepare workout data for saving
    final workoutData = _prepareWorkoutData();
    
    // Show workout summary dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.workoutPlan['name'] ?? 'Workout Session',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completed: ${_calculateCompletedExercises()}/${_exercises.length} exercises',
              ),
              const SizedBox(height: 16),
              const Text(
                'How was your workout overall?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSessionRating(
                (rating) {
                  workoutData['overallRating'] = rating;
                  (context as Element).markNeedsBuild();
                },
                workoutData['overallRating'] ?? 0,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  workoutData['notes'] = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveWorkoutData(workoutData);
            },
            child: const Text('Save & Finish'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRating(Function(int) onRatingChanged, int currentRating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            Icons.star,
            color: index < currentRating ? Colors.amber : Colors.grey.shade300,
            size: 32,
          ),
          onPressed: () {
            onRatingChanged(index + 1);
          },
        );
      }),
    );
  }

  Map<String, dynamic> _prepareWorkoutData() {
    // Collect all exercise data
    final exerciseData = <Map<String, dynamic>>[];
    
    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      final performances = _setPerformances[i]!;
      final isCompleted = _isSetCompleted(i);
      
      exerciseData.add({
        'exerciseId': exercise['exerciseId'],
        'exerciseName': exercise['exerciseName'],
        'sets': performances,
        'completed': isCompleted,
      });
    }
    
    // Create workout session data
    return {
      'workoutPlanId': widget.workoutPlanId,
      'workoutPlanName': widget.workoutPlan['name'],
      'date': DateTime.now(),
      'exercises': exerciseData,
      'overallRating': 0,
      'notes': '',
      'userId': FirebaseAuth.instance.currentUser?.uid,
    };
  }

  Future<void> _saveWorkoutData(Map<String, dynamic> workoutData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save the workout session to Firestore
      await FirebaseFirestore.instance
          .collection('WorkoutSessions')
          .add({
        ...workoutData,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Generate workout recommendations based on performance
      final recommendations = _generateRecommendations(workoutData);
      
      // Show success message with recommendations
      if (mounted) {
        _showCompletionDialog(recommendations);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout: $error')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _generateRecommendations(Map<String, dynamic> workoutData) {
    // Analyse workout performance to generate recommendations
    final recommendations = <String, dynamic>{};
    final exercises = workoutData['exercises'] as List;
    
    for (final exerciseData in exercises) {
      if (exerciseData['completed'] == true) {
        final sets = exerciseData['sets'] as List;
        double avgRating = 0;
        
        for (final set in sets) {
          avgRating += set['rating'] as int? ?? 0;
        }
        
        if (sets.isNotEmpty) {
          avgRating /= sets.length;
          
          // Generate recommendation based on average rating
          String recommendation;
          
          if (avgRating < 1.5) {
            // Too easy
            final weight = sets.first['actualWeight'] as double? ?? 0;
            final unit = sets.first['weightUnit'] as String? ?? 'kg';
            final newWeight = (weight * 1.1).toStringAsFixed(1); // 10% increase
            recommendation = 'Increase weight to $newWeight$unit';
          } else if (avgRating > 3.5) {
            // Too difficult
            final weight = sets.first['actualWeight'] as double? ?? 0;
            final unit = sets.first['weightUnit'] as String? ?? 'kg';
            final newWeight = (weight * 0.9).toStringAsFixed(1); // 10% decrease
            recommendation = 'Decrease weight to $newWeight$unit';
          } else {
            // Just right
            recommendation = 'Maintain current weight and reps';
          }
          
          recommendations[exerciseData['exerciseName']] = recommendation;
        }
      }
    }
    
    return recommendations;
  }

  void _showCompletionDialog(Map<String, dynamic> recommendations) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Workout Completed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Great job! Your workout has been saved.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recommendations for next time:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...recommendations.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, size: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(entry.value),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true); // Return to workout plan screen
            },
            child: const Text('Back to Plan'),
          ),
        ],
      ),
    );
  }
}