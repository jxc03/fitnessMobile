import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _workoutSessions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWorkoutHistory();
  }
  
  Future<void> _fetchWorkoutHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Try to fetch workout history from Firestore
    // Error handling is done in the catch block
    try {
      // Get current user ID from Firebase Authentication
      // Check if the user is authenticated, if not then throw an error
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Query Firestore for all workout sessions belonging to the current user
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutSessions')
          .where('userId', isEqualTo: userId) // Filter by user ID to get only the current user's sessions
          .orderBy('timestamp', descending: true) // Order by timestamp to get the most recent sessions first
          .get();

      // Initalise an empty list to store the workout sessions
      final List<Map<String, dynamic>> sessions = [];

      // Loop through each document in the snapshot
      for (var doc in snapshot.docs) {
        
        final data = doc.data() as Map<String, dynamic>;
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

      setState(() {
        _workoutSessions = sessions;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load workout history: $error';
        _isLoading = false;
      });
      print('Error fetching workout history: $error');
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildWorkoutHistoryList(),
    );
  }

  Widget _buildWorkoutHistoryList() {
    if (_workoutSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No workout history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a workout to see it here',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workoutSessions.length,
      itemBuilder: (context, index) {
        final session = _workoutSessions[index];
        final date = session['date'] as DateTime;
        final dateFormat = DateFormat('E, MMM d, yyyy');
        final timeFormat = DateFormat('h:mm a');
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _showWorkoutSessionDetails(session),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session['workoutPlanName'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dateFormat.format(date)} at ${timeFormat.format(date)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildRatingStars(session['overallRating']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(
                        'Completed', 
                        '${session['completedCount']}/${session['exercisesCount']}',
                      ),
                      _buildProgressIndicator(
                        session['completedCount'], 
                        session['exercisesCount'],
                      ),
                    ],
                  ),
                  if (session['notes'] != null && session['notes'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Notes: ${session['notes']}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 18,
          color: index < rating ? Colors.amber : Colors.grey.shade300,
        );
      }),
    );
  }

  Widget _buildProgressIndicator(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;
    
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: _getProgressColor(progress),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  void _showWorkoutSessionDetails(Map<String, dynamic> session) async {
    try {
      // Fetch full session details
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('WorkoutSessions')
          .doc(session['id'])
          .get();

      if (!doc.exists) {
        throw Exception('Workout session not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final exercises = data['exercises'] as List? ?? [];

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildSessionDetailsDialog(session, exercises),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workout details: $error')),
        );
      }
    }
  }

  Widget _buildSessionDetailsDialog(Map<String, dynamic> session, List exercises) {
    final date = session['date'] as DateTime;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return AlertDialog(
      title: Text(session['workoutPlanName']),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateFormat.format(date)} at ${timeFormat.format(date)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Overall Rating: '),
                  _buildRatingStars(session['overallRating']),
                ],
              ),
              if (session['notes'] != null && session['notes'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${session['notes']}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Exercises',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...exercises.map((exercise) => _buildExerciseDetail(exercise)).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildExerciseDetail(Map<String, dynamic> exercise) {
    final bool completed = exercise['completed'] ?? false;
    final String name = exercise['exerciseName'] ?? 'Unknown Exercise';
    final sets = exercise['sets'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completed ? Icons.check_circle : Icons.cancel,
                  color: completed ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (completed && sets.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Column(
                children: List.generate(sets.length, (index) {
                  final set = sets[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          'Set ${index + 1}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${set['actualReps'] ?? 0} reps'),
                        const SizedBox(width: 4),
                        if ((set['actualWeight'] ?? 0) > 0)
                          Text('@${set['actualWeight']}${set['weightUnit'] ?? 'kg'}'),
                        const Spacer(),
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

  Widget _buildSmallRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 12,
          color: index < rating ? Colors.amber : Colors.grey.shade300,
        );
      }),
    );
  }
}