import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Database for storing workout data
import 'package:firebase_auth/firebase_auth.dart'; // Authentication for user identification

/// WorkoutTrackingScreen allows users to track their workout progress in real-time
/// This screen guides users through a workout session, tracking sets, reps, weights,
/// and perceived difficulty. It provides rest timers and analysis of performance.
class WorkoutTrackingScreen extends StatefulWidget {
  // Required properties passed from workout plan selection
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
  // Loading state management - used to show loading indicators
  bool _isLoading = false; 

  // Exercise navigation properties
  int _currentExerciseIndex = 0; // Index of the exercise currently being performed
  List<Map<String, dynamic>> _exercises = []; // List of all exercises in this workout
  
  // Data tracking maps
  final Map<int, List<bool>> _completedSets = {}; // Tracks completion status for each set
  final Map<int, List<Map<String, dynamic>>> _setPerformances = {}; // Tracks performance data for each set
  
  // Rest timer properties 
  int _restTimeRemaining = 0; // Remaining time (seconds) in current rest period
  bool _isResting = false; // Whether the user is currently resting or not, initially false

  @override
  void initState() {
    super.initState();
    _initialiseWorkout(); // Setup workout data when screen first loads
  }

  /// Initialise the workout session with exercise data from the selected workout plan
  /// Extracts exercises from the workout plan
  /// Creates tracking structures for sets and performance data
  /// Sets up defaults for weight and repetitions
  void _initialiseWorkout() {
    setState(() {
      _isLoading = true;
    });

    // Get the exercises from the workout plan and convert to properly typed list
    final exercises = widget.workoutPlan['exercises'] as List; 
    _exercises = List<Map<String, dynamic>>.from(exercises); 

    // Loop through each exercise and initialize tracking data
    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i]; 
      final sets = exercise['sets'] as int? ?? 3; // Default to 3 sets if not specified
      
      // Create list to track completed sets (initially all false)
      _completedSets[i] = List.filled(sets, false);

      // Create list to track performance data for each set with initial values
      _setPerformances[i] = List.generate(sets, (_) => {
        'actualReps': 0,
        'actualWeight': exercise['weight'] ?? 0.0,
        'weightUnit': exercise['weightUnit'] ?? 'kg',
        'rating': 0, // 0 = not rated, 1-5 = difficulty rating
      });
    }

    // Ready to display the workout
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access theme properties for consistent styling
    final theme = Theme.of(context);
    
    // Prevent accidental back gestures/buttons with confirmation dialog
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final result = await _onWillPop();
          if (result) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workoutPlan['name'] ?? 'Workout Session'),
          elevation: 0,
          actions: [
            // "Finish" button to complete the workout early
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
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              )
            : _buildWorkoutTracker(),
      ),
    );
  }

  /// Show a confirmation dialog when user tries to exit the workout
  /// Returns true if user confirms exit, false otherwise
  Future<bool> _onWillPop() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Workout?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: const Text('Are you sure you want to exit this workout? Your progress will not be saved.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Build the main workout tracking interface
  /// Returns different UIs based on the current state:
  /// Empty state if no exercises
  /// Rest timer if user is between sets
  /// Exercise tracking UI otherwise
  Widget _buildWorkoutTracker() {
    // Access theme properties
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Handle no exercises in workout plan
    if (_exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 64,
                color: theme.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No exercises in this workout plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Workouts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show rest timer if user is in rest period
    if (_isResting) {
      return _buildRestTimer();
    }

    // Get current exercise data
    final currentExercise = _exercises[_currentExerciseIndex];
    final sets = currentExercise['sets'] as int? ?? 3;
    final reps = currentExercise['reps'] as String? ?? '10-12';
    final weight = currentExercise['weight'] ?? 0.0;
    final weightUnit = currentExercise['weightUnit'] ?? 'kg';

    // Main workout tracking UI
    return Column(
      children: [
        // Progress indicator section
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Exercise ${_currentExerciseIndex + 1}/${_exercises.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_calculateCompletedExercises()} completed',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar showing current position in workout
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentExerciseIndex + 1) / _exercises.length,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                  color: theme.primaryColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        
        // Exercise information card
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          size: 24,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentExercise['exerciseName'] ?? 'Exercise',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Target: $sets sets of $reps reps',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            if (weight > 0)
                              Text(
                                'Weight: $weight$weightUnit',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Exercise notes section (if available)
                  if (currentExercise['notes'] != null && currentExercise['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${currentExercise['notes']}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Sets tracking section (scrollable list)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: sets,
            itemBuilder: (context, setIndex) {
              final isCompleted = _completedSets[_currentExerciseIndex]![setIndex];
              final performance = _setPerformances[_currentExerciseIndex]![setIndex];
              
              // Individual set card
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                color: isCompleted ? colorScheme.tertiary.withValues(alpha: 0.05) : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Set number indicator
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCompleted 
                                  ? colorScheme.tertiary.withValues(alpha: 0.1)
                                  : colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${setIndex + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? colorScheme.tertiary : colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Set ${setIndex + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          // Completed indicator or Complete button
                          if (isCompleted)
                            Row(
                              children: [
                                const Text('Completed'),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle,
                                  color: colorScheme.tertiary,
                                ),
                              ],
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _markSetCompleted(setIndex),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: const Text('Complete Set'),
                            ),
                        ],
                      ),
                      // Performance data for completed sets
                      if (isCompleted) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPerformanceItem(
                                  'Reps', 
                                  performance['actualReps'].toString(),
                                  Icons.repeat
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: colorScheme.outline.withValues(alpha: 0.2),
                              ),
                              Expanded(
                                child: _buildPerformanceItem(
                                  'Weight', 
                                  '${performance['actualWeight']}${performance['weightUnit']}',
                                  Icons.fitness_center
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: colorScheme.outline.withValues(alpha: 0.2),
                              ),
                              Expanded(
                                child: _buildRatingIndicator(performance['rating']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Navigation buttons for moving between exercises
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous exercise button (if not on first exercise)
              if (_currentExerciseIndex > 0)
                ElevatedButton.icon(
                  onPressed: _previousExercise,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              // Next exercise button (if not on last exercise)
              if (_currentExerciseIndex < _exercises.length - 1)
                ElevatedButton.icon(
                  onPressed: _nextExercise,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              // Finish workout button (if on last exercise)
              if (_currentExerciseIndex == _exercises.length - 1)
                ElevatedButton.icon(
                  onPressed: _showWorkoutSummary,
                  icon: const Icon(Icons.check),
                  label: const Text('Finish Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.tertiary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a performance metric item 
  /// Used for displaying reps, weight, etc. in a consistent format
  Widget _buildPerformanceItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Build the difficulty rating indicator with stars
  Widget _buildRatingIndicator(int rating) {
    return Column(
      children: [
        Text(
          'Difficulty',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              size: 16,
              color: index < rating ? Colors.amber : Colors.grey.shade300,
            );
          }),
        ),
      ],
    );
  }
  
  /// Build the rest timer UI displayed between sets
  Widget _buildRestTimer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'REST TIME',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_restTimeRemaining',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Take a break',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _skipRest,
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip Rest'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mark a set as completed and open dialog to record performance
  void _markSetCompleted(int setIndex) {
    final currentExercise = _exercises[_currentExerciseIndex];
    
    // Show dialog to log performance
    showDialog(
      context: context,
      builder: (context) => _buildSetCompletionDialog(currentExercise, setIndex),
    );
  }

  /// Build the dialog for logging set performance (reps, weight, difficulty)
  Widget _buildSetCompletionDialog(Map<String, dynamic> exercise, int setIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final targetReps = exercise['reps'] as String? ?? '10-12';
    final initialWeight = exercise['weight'] ?? 0.0;
    final initialWeightUnit = exercise['weightUnit'] ?? 'kg';
    
    // Performance tracking variables that will be updated by user input
    int actualReps = 0;
    double actualWeight = initialWeight;
    String weightUnit = initialWeightUnit;
    int rating = 0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.fitness_center,
            color: theme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Set ${setIndex + 1} Completed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target information banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Target: $targetReps reps',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Actual reps input
            Text(
              'How many reps did you complete?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Actual Reps',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.repeat,
                  color: theme.primaryColor,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                actualReps = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 20),
            
            // Weight input section
            Text(
              'What weight did you use?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight value input field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: TextEditingController(text: initialWeight.toString()),
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.fitness_center,
                        color: theme.primaryColor,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                      ),
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
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                      ),
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
            const SizedBox(height: 20),
            
            // Difficulty rating
            Text(
              'How difficult was this set?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: index < rating ? Colors.amber : Colors.grey.shade300,
                                  size: 32,
                                ),
                                onPressed: () {
                                  setState(() {
                                    rating = index + 1;
                                  });
                                },
                              ),
                              // Display number with short description
                              Container(
                                width: 60,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: index < rating ? Colors.amber : Colors.grey.shade400,
                                        fontWeight: index < rating ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      _getShortRatingDescription(index + 1),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: index < rating ? Colors.amber.shade700 : Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Display full description for selected rating
                      if (rating > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _getRatingDescription(rating),
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton.icon(
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
          icon: const Icon(Icons.save),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// Get a short description for each rating (used in tooltips)
  String _getShortRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Very easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Moderate';
      case 4:
        return 'Difficult';
      case 5:
        return 'Very difficult';
      default:
        return '';
    }
  }

  /// Get descriptive text for difficulty rating
  String _getRatingDescription(int rating) {
    switch (rating) {
      case 0:
        return 'Select difficulty level';
      case 1:
        return 'Very easy - Could do many more reps';
      case 2:
        return 'Easy - Could do a few more reps';
      case 3:
        return 'Moderate - Challenging but manageable';
      case 4:
        return 'Difficult - Almost reached failure';
      case 5:
        return 'Very difficult - Reached muscle failure';
      default:
        return '';
    }
  }

  /// Check if all sets for an exercise are completed
  bool _isSetCompleted(int exerciseIndex) {
    return _completedSets[exerciseIndex]!.every((isCompleted) => isCompleted);
  }

  /// Analyze performance and provide feedback on exercise difficulty
  /// Calculates the average difficulty rating across all sets
  /// 2Generates appropriate feedback based on difficulty level
  /// Shows a dialog with recommendations for future workouts
  void _analysePerformance(int exerciseIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final exercise = _exercises[exerciseIndex];
    final sets = exercise['sets'] as int? ?? 3;
    final performances = _setPerformances[exerciseIndex]!;
    
    // Calculate average rating across all sets
    double totalRating = 0;
    for (var performance in performances) {
      totalRating += performance['rating'] as int? ?? 0;
    }
    final avgRating = totalRating / sets;
    
    // Determine feedback based on difficulty level
    String message;
    Color messageColor;
    IconData messageIcon;
    
    if (avgRating < 1.5) {
      // Too easy - suggest increasing weight
      message = 'This was too easy! Consider increasing weight by 5-10%.';
      messageColor = colorScheme.tertiary;
      messageIcon = Icons.arrow_upward;
    } else if (avgRating < 3.5) {
      // Good challenge level - maintain current weight
      message = 'Great job! This was a good challenge level.';
      messageColor = theme.primaryColor;
      messageIcon = Icons.check_circle;
    } else {
      // Too difficult - suggest reducing weight
      message = 'This was quite difficult. Consider reducing weight by 5-10% or doing fewer reps.';
      messageColor = Colors.orange;
      messageIcon = Icons.arrow_downward;
    }
    
    // Show a feedback popup with the analysis
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.fitness_center,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Exercise Complete',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              exercise['exerciseName'] ?? 'Exercise',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: messageColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    messageIcon,
                    color: messageColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: messageColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
            child: Text(
              'OK',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Start the rest timer between sets
  /// Sets up a countdown timer that updates every second
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

  /// Skip the rest period and continue workout
  void _skipRest() {
    setState(() {
      _isResting = false;
    });
  }

  /// Navigate to previous exercise
  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  /// Navigate to next exercise
  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    }
  }

  /// Calculate how many exercises have all sets completed
  int _calculateCompletedExercises() {
    int completedCount = 0;
    for (int i = 0; i < _exercises.length; i++) {
      if (_isSetCompleted(i)) {
        completedCount++;
      }
    }
    return completedCount;
  }

  /// Show workout summary dialog and prepare for saving
  void _showWorkoutSummary() {
    // Prepare workout data for saving
    final workoutData = _prepareWorkoutData();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Show workout summary dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.fitness_center,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Workout Summary',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.workoutPlan['name'] ?? 'Workout Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Completed: ${_calculateCompletedExercises()}/${_exercises.length} exercises',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Section header with divider
              _buildSectionHeader('Overall Rating'),
              
              const SizedBox(height: 12),
              
              Center(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starValue = index + 1;
                            return Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    index < (workoutData['overallRating'] ?? 0) 
                                        ? Icons.star 
                                        : Icons.star_border,
                                    color: index < (workoutData['overallRating'] ?? 0) 
                                        ? Colors.amber 
                                        : Colors.grey.shade300,
                                    size: 36,
                                  ),
                                  onPressed: () {
                                    workoutData['overallRating'] = starValue;
                                    setState(() {});
                                  },
                                ),
                                // Display number with short description
                                Container(
                                  width: 65, // Set a fixed width for alignment
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$starValue',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: index < (workoutData['overallRating'] ?? 0) 
                                              ? Colors.amber 
                                              : Colors.grey.shade400,
                                          fontWeight: index < (workoutData['overallRating'] ?? 0) 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        _getShortRatingDescription(starValue),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: index < (workoutData['overallRating'] ?? 0) 
                                              ? Colors.amber.shade700 
                                              : Colors.grey.shade500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        // Display full description for selected rating
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: (workoutData['overallRating'] ?? 0) > 0 
                                ? Colors.amber.withValues(alpha: 0.1) 
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (workoutData['overallRating'] ?? 0) > 0 
                                  ? Colors.amber.withValues(alpha: 0.3) 
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getRatingDescription(workoutData['overallRating'] ?? 0),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: (workoutData['overallRating'] ?? 0) > 0 
                                  ? Colors.amber.shade800 
                                  : Colors.grey.shade700,
                              fontWeight: (workoutData['overallRating'] ?? 0) > 0 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Section header with divider
              _buildSectionHeader('Notes'),
              
              const SizedBox(height: 12),
              
              TextField(
                decoration: InputDecoration(
                  hintText: 'Add notes about this workout (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.primaryColor,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.note,
                    color: theme.primaryColor,
                  ),
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
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _saveWorkoutData(workoutData);
            },
            icon: const Icon(Icons.check),
            label: const Text('Save & Finish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.tertiary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Create a section header with text and divider
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
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

  /// Build a star rating widget for the overall workout
  /// This method has been replaced with inline implementation in _showWorkoutSummary
  /// for better state management and display of rating descriptions
  Widget _buildSessionRating(Function(int) onRatingChanged, int currentRating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return Column(
          children: [
            IconButton(
              icon: Icon(
                index < currentRating ? Icons.star : Icons.star_border,
                color: index < currentRating ? Colors.amber : Colors.grey.shade300,
                size: 36,
              ),
              onPressed: () {
                onRatingChanged(starValue);
              },
              tooltip: '$starValue - ${_getShortRatingDescription(starValue)}',
            ),
            Text(
              '$starValue',
              style: TextStyle(
                fontSize: 12,
                color: index < currentRating ? Colors.amber : Colors.grey.shade400,
                fontWeight: index < currentRating ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Prepare all workout data for saving to Firestore
  /// Collects information about exercises, sets, reps, weights, and ratings
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

  /// Save workout data to Firestore and show completion dialog
  Future<void> _saveWorkoutData(Map<String, dynamic> workoutData) async {
    final theme = Theme.of(context);
    
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
          SnackBar(
            content: Text('Error saving workout: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Generate exercise-specific recommendations based on performance 
  /// Analyses difficulty ratings to suggest weight adjustments for future workouts
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

  /// Show the final workout completion dialog with recommendations
  /// This dialog:
  /// Congratulates the user on completing the workout
  /// Displays performance-based recommendations
  /// Allows the user to apply recommendations for future workouts
  void _showCompletionDialog(Map<String, dynamic> recommendations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Keep track of which recommendations the user accepts
    final Map<String, dynamic> acceptedRecommendations = {};
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_score,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Workout Completed',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Great job! Your workout has been saved.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Section header with divider
                _buildSectionHeader('Recommendations'),
                
                const SizedBox(height: 12),
                
                ...recommendations.entries.map((entry) {
                  final isAccepted = acceptedRecommendations.containsKey(entry.key);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isAccepted
                            ? colorScheme.tertiary.withValues(alpha: 0.5)
                            : colorScheme.outline.withValues(alpha: 0.2),
                        width: isAccepted ? 1.5 : 1,
                      ),
                    ),
                    color: isAccepted ? colorScheme.tertiary.withValues(alpha: 0.05) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(entry.value),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    if (isAccepted) {
                                      acceptedRecommendations.remove(entry.key);
                                    } else {
                                      // Store recommendation details
                                      acceptedRecommendations[entry.key] = entry.value;
                                    }
                                  });
                                },
                                icon: Icon(
                                  isAccepted ? Icons.check_circle : Icons.add_circle_outline,
                                  size: 18,
                                  color: isAccepted ? colorScheme.tertiary : theme.primaryColor,
                                ),
                                label: Text(
                                  isAccepted ? 'Accepted' : 'Apply Next Time',
                                  style: TextStyle(
                                    color: isAccepted ? colorScheme.tertiary : theme.primaryColor,
                                    fontWeight: isAccepted ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: isAccepted 
                                      ? colorScheme.tertiary.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: isAccepted
                                        ? BorderSide(color: colorScheme.tertiary.withValues(alpha: 0.3))
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                if (acceptedRecommendations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all( 
                        color: theme.primaryColor.withAlpha(51), 
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Accepted recommendations will be applied to your workout plan.',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Return to workout plan screen
              },
              child: Text(
                'Skip',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Save accepted recommendations if there are any
                if (acceptedRecommendations.isNotEmpty) {
                  await _saveRecommendationsToFirestore(acceptedRecommendations);
                }
                
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true); // Return to workout plan screen
                }
              },
              icon: Icon(
                acceptedRecommendations.isNotEmpty ? Icons.save : Icons.arrow_back,
                size: 18,
              ),
              label: Text(
                acceptedRecommendations.isNotEmpty ? 'Save & Return' : 'Back to Plan'
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Save accepted recommendations to Firestore
  /// Updates exercise data in the workout plan with new weights/reps
  /// based on user-accepted recommendations
  Future<void> _saveRecommendationsToFirestore(Map<String, dynamic> acceptedRecommendations) async {
    try {
      // Reference to the workout plan document
      final workoutPlanRef = FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.workoutPlanId);
      
      // Get current workout plan data
      final workoutPlanDoc = await workoutPlanRef.get();
      if (!workoutPlanDoc.exists) {
        throw Exception('Workout plan not found');
      }
      
      final workoutPlanData = workoutPlanDoc.data() as Map<String, dynamic>;
      final exercises = workoutPlanData['exercises'] as List;
      final List<Map<String, dynamic>> updatedExercises = [];
      
      // Update each exercise based on recommendations
      for (final exercise in exercises) {
        final Map<String, dynamic> updatedExercise = Map.from(exercise);
        final exerciseName = exercise['exerciseName'] as String;
        
        // If this exercise has an accepted recommendation
        if (acceptedRecommendations.containsKey(exerciseName)) {
          final recommendation = acceptedRecommendations[exerciseName] as String;
          
          // Extract recommended weight from the recommendation string
          if (recommendation.contains('Increase weight to') || 
              recommendation.contains('Decrease weight to')) {
            
            // Parse the new weight from the recommendation
            // Format example: "Increase weight to 15.5kg"
            final RegExp weightRegex = RegExp(r'to\s+(\d+\.?\d*)([a-zA-Z]+)');
            final match = weightRegex.firstMatch(recommendation);
            
            if (match != null) {
              final newWeight = double.parse(match.group(1)!);
              final unit = match.group(2)!;
              
              // Update the exercise weight
              updatedExercise['weight'] = newWeight;
              updatedExercise['weightUnit'] = unit;
            }
          }
        }
        
        updatedExercises.add(updatedExercise);
      }
      
      // Update the workout plan with the modified exercises
      await workoutPlanRef.update({
        'exercises': updatedExercises,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout plan updated with your recommendations'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating workout plan: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}