import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

/// A screen that displays the user's workout history.
/// This widget fetches and displays all past workout sessions from Firestore,
/// allowing users to:
/// View a chronological list of completed workouts
/// See progress details and ratings for each session
/// View detailed information about each workout session
/// Refresh the history to show the latest data
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  bool _isLoading = true;                           // Loading state indicator
  List<Map<String, dynamic>> _workoutSessions = []; // Workout session data from Firestore
  String? _errorMessage;                            // Error message if fetch operation fails

  @override
  void initState() {
    super.initState();
    _fetchWorkoutHistory(); // Fetch workout history when the screen initialises
  }
  
  /// Fetches the user's workout history from Firestore.
  /// This method retrieves all workout sessions for the current user
  /// ordered by timestamp (most recent first), and processes the data
  /// for display in the UI
  Future<void> _fetchWorkoutHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Try to fetch workout history from Firestore
    try {
      // Get current user ID from Firebase Authentication
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Query Firestore for all workout sessions belonging to the current user
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutSessions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true) // Most recent sessions first
          .get();

      // Initialize an empty list to store the workout sessions
      final List<Map<String, dynamic>> sessions = [];

      // Loop through each document in the snapshot
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Process and add session data to the list
        sessions.add({
          'id': doc.id,
          'workoutPlanName': data['workoutPlanName'] ?? 'Unknown Workout',
          'date': data['timestamp'] != null 
            ? (data['timestamp'] as Timestamp).toDate() 
            : DateTime.now(),
          'exercisesCount': (data['exercises'] as List?)?.length ?? 0,
          'completedCount': _countCompletedExercises(data['exercises'] as List?),
          'overallRating': data['overallRating'] ?? 0,
          'notes': data['notes'] ?? '',
        });
      }

      // Update state with fetched data
      setState(() {
        _workoutSessions = sessions;
        _isLoading = false;
      });
    } catch (error) {
      // Handle errors during fetch operation
      setState(() {
        _errorMessage = 'Failed to load workout history: $error';
        _isLoading = false;
      });
      log('Error fetching workout history: $error');
    }
  }

  /// Counts the number of completed exercises in a workout session
  /// Takes a list of exercises from a workout session and returns
  /// the count of exercises that have a 'completed' flag set to true
  int _countCompletedExercises(List? exercises) {
    if (exercises == null) return 0;
    
    int count = 0;
    for (var exercise in exercises) {
      if (exercise['completed'] == true) {
        count++;
      }
    }
    
    return count;
  }

  @override
  Widget build(BuildContext context) {
    // Access theme properties for consistent styling
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        elevation: 0,
        actions: [
          // Refresh button to reload workout history
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWorkoutHistory,
            tooltip: 'Refresh history',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Error icon
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      // Error title
                      Text(
                        'Error Loading History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Error message
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Retry button
                      ElevatedButton.icon(
                        onPressed: _fetchWorkoutHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildWorkoutHistoryList(), // The main content when data is loaded successfully
    );
  }

  /// Builds the workout history list or empty state UI
  /// If workout sessions exist, displays them as a scrollable list
  /// If no sessions exist, shows an empty state with a prompt to complete workouts
  Widget _buildWorkoutHistoryList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Show empty state if no workout sessions exist
    if (_workoutSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1), // 10% opacity
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 64,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Empty state title
            Text(
              'No workout history yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            // Empty state message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Complete a workout to see it here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Action button to start a workout
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to workout plans
                Navigator.of(context).pushNamed('/workout-plans');
              },
              icon: const Icon(Icons.add),
              label: const Text('Start a Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build list of workout sessions
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workoutSessions.length,
      itemBuilder: (context, index) {
        final session = _workoutSessions[index];
        final date = session['date'] as DateTime;
        final dateFormat = DateFormat('E, MMM d, yyyy'); // Format: Mon, Jan 1, 2023
        final timeFormat = DateFormat('h:mm a');         // Format: 3:30 PM
        
        // Calculate progress percentage for the completion indicator
        final progressPercent = session['exercisesCount'] > 0 
            ? (session['completedCount'] / session['exercisesCount'] * 100).toInt() 
            : 0;
        
        // Individual workout session card
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2), // 20% opacity
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showWorkoutSessionDetails(session), // Show details on tap
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date indicator with month and day
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1), // 10% opacity
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              date.day.toString(), // Day of month
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date), // Month abbreviation
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Workout details section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Workout plan name
                            Text(
                              session['workoutPlanName'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Date and time
                            Text(
                              '${dateFormat.format(date)} at ${timeFormat.format(date)}',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Rating stars
                            _buildRatingStars(session['overallRating']),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress indicator for exercise completion
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Exercise completion text
                          Text(
                            'Completed ${session['completedCount']}/${session['exercisesCount']} exercises',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          // Percentage indicator
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getProgressColor(progressPercent / 100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar with color based on completion percentage
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: _getProgressColor(progressPercent / 100),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  
                  // Notes section (if available)
                  if (session['notes'] != null && session['notes'].isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2), // 20% opacity
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${session['notes']}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurface.withValues(alpha: 0.8), // 80% opacity
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis, // Truncate with "..." if text is too long
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a row of star icons to display a rating.
  /// Takes an integer rating (0-5) and returns a row of filled or 
  /// outlined stars representing the rating.
  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border, // Filled or outlined star
          size: 18,
          color: index < rating ? Colors.amber : Colors.grey.shade400, // Yellow for filled, grey for outlined
        );
      }),
    );
  }

  /// Determines the color for the progress bar based on completion percentage.
  /// 
  /// Returns:
  /// - Red for < 30% completion
  /// - Orange for 30-70% completion
  /// - Green for > 70% completion
  Color _getProgressColor(double progress) {
    final theme = Theme.of(context);
    if (progress < 0.3) return Colors.red.shade400; // Below 30% - red
    if (progress < 0.7) return Colors.orange.shade400; // Below 70% - orange
    return theme.colorScheme.tertiary; // Above 70% - green
  }

  /// Shows a detailed view of a workout session
  /// Fetches the full workout session data from Firestore and
  /// displays it in a dialog with exercise-by-exercise details
  void _showWorkoutSessionDetails(Map<String, dynamic> session) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Show loading spinner while fetching data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Fetch the complete workout session document from Firestore
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('WorkoutSessions')
          .doc(session['id'])
          .get();

      if (!mounted) return;
      
      // Dismiss loading dialog
      Navigator.of(context).pop();

      // Check if the document exists
      if (!doc.exists) {
        throw Exception('Workout session not found');
      }

      // Extract full document data
      final data = doc.data() as Map<String, dynamic>;
      final exercises = data['exercises'] as List? ?? [];

      // Show dialog with session details if the widget is still mounted
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildSessionDetailsDialog(session, exercises),
        );
      }
    } catch (error) {
      if (mounted) {
        // Dismiss loading dialog
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workout details: $error'),
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

  /// Builds the dialog for displaying detailed workout session information.
  /// Workout name and date
  /// Overall rating for the session
  /// Session notes (if present)
  /// List of exercises with set-by-set details
  Widget _buildSessionDetailsDialog(Map<String, dynamic> session, List exercises) {
    final date = session['date'] as DateTime;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy'); 
    final timeFormat = DateFormat('h:mm a');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.fitness_center,
            color: theme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              session['workoutPlanName'],
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
      ),
      contentPadding: const EdgeInsets.only(top: 20, left: 24, right: 24),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and time section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1), // 10% opacity
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${dateFormat.format(date)} at ${timeFormat.format(date)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Rating display
              Row(
                children: [
                  Text(
                    'Overall Rating: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  _buildRatingStars(session['overallRating']),
                ],
              ),
              
              // Notes section (if available)
              if (session['notes'] != null && session['notes'].isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2), // 20% opacity
                    ),
                  ),
                  child: Text(
                    session['notes'],
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface.withValues(alpha: 0.8), // 80% opacity
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Exercises section header
              _buildSectionHeader('Exercises'),
              
              const SizedBox(height: 12),
              
              // List of exercises with their details
              ...exercises.map((exercise) => _buildExerciseDetail(exercise)),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        // Close button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a section header with text and divider
  /// Creates a visual separation between different sectionsin the workout details dialog
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
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), // 30% opacity
            thickness: 1,
          ),
        ),
      ],
    );
  }

  /// Builds a detailed view of an exercise from a workout session
  /// Exercise name and completion status
  /// For completed exercises: details for each set including
  ///  reps, weight, and difficulty rating
  Widget _buildExerciseDetail(Map<String, dynamic> exercise) {
    final bool completed = exercise['completed'] ?? false;
    final String name = exercise['exerciseName'] ?? 'Unknown Exercise';
    final sets = exercise['sets'] as List? ?? [];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2), // 20% opacity
          width: 1,
        ),
      ),
      // Background color based on completion status
      color: completed ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status indicator (check or close icon)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: completed ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed ? Icons.check : Icons.close,
                    color: completed ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                // Exercise name
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            // Set details (only shown for completed exercises)
            if (completed && sets.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Column(
                children: List.generate(sets.length, (index) {
                  final set = sets[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Set number
                        Text(
                          'Set ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Repetitions
                        Text('${set['actualReps'] ?? 0} reps'),
                        const SizedBox(width: 4),
                        // Weight (if applicable)
                        if ((set['actualWeight'] ?? 0) > 0)
                          Text('@${set['actualWeight']}${set['weightUnit'] ?? 'kg'}'),
                        const Spacer(),
                        // Difficulty rating
                        _buildSmallRatingStars(set['rating'] ?? 0),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a smaller version of rating stars for set difficulty
  Widget _buildSmallRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border, // Filled or outlined star
          size: 12, // Smaller size for set ratings
          color: index < rating ? Colors.amber : Colors.grey.shade300, // Yellow for filled, grey for outlined
        );
      }),
    );
  }
}