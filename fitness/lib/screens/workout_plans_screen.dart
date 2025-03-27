import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_plan_details_screen.dart';
import 'create_workout_plan_screen.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _workoutPlans = [];
  String? _errorMessage;

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
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
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
      print('Error fetching workout plans: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plans'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateWorkoutPlan(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Workout Plans Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first workout plan to get started!',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateWorkoutPlan(),
            icon: const Icon(Icons.add),
            label: const Text('Create Workout Plan'),
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

  Widget _buildWorkoutPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToWorkoutPlanDetail(plan['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
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
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${plan['exerciseCount']} exercise${plan['exerciseCount'] != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ],
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
          title: const Text('Delete Workout Plan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "$planName"?'),
                const SizedBox(height: 8),
                const Text('This action cannot be undone.'),
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
                'Delete',
                style: TextStyle(color: Colors.red),
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
          const SnackBar(content: Text('Workout plan deleted successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting workout plan: $error')),
        );
      }
    }
  }
}