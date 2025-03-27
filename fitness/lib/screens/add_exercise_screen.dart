import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExerciseScreen extends StatefulWidget {
  final String workoutPlanId;

  const AddExerciseScreen({
    super.key,
    required this.workoutPlanId,
  });

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _searchController = TextEditingController();
  final _selectedExercises = <String, Map<String, dynamic>>{};
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  String? _errorMessage;

  // Available muscle groups for filtering
  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Abs',
    'Glutes',
  ];
  String _selectedMuscleGroup = 'All';

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Exercises')
          .get();

      final List<Map<String, dynamic>> loadedExercises = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        loadedExercises.add({
          'id': doc.id,
          'name': data['name'] ?? doc.id,
          'equipment': data['equipment'] ?? '',
          'muscleGroups': data['muscleGroups'] ?? [],
        });
      }

      setState(() {
        _exercises = loadedExercises;
        _applyFilters();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load exercises: $error';
        _isLoading = false;
      });
      print('Error fetching exercises: $error');
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> result = [];

    result = _exercises.where((exercise) {
      // Filter by search query
      final nameMatch = exercise['name'].toString().toLowerCase().contains(query);
      final equipmentMatch = exercise['equipment'].toString().toLowerCase().contains(query);

      // Filter by muscle group
      bool muscleGroupMatch = true;
      if (_selectedMuscleGroup != 'All') {
        final muscleGroups = exercise['muscleGroups'];
        if (muscleGroups is List) {
          muscleGroupMatch = muscleGroups.any((group) =>
              group.toString().toLowerCase() == _selectedMuscleGroup.toLowerCase());
        } else {
          muscleGroupMatch = false;
        }
      }

      return (nameMatch || equipmentMatch) && muscleGroupMatch;
    }).toList();

    // Sort by name
    result.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

    setState(() {
      _filteredExercises = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercises'),
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search exercises',
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    _applyFilters();
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Muscle group filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _muscleGroups.map((muscleGroup) {
                      final isSelected = _selectedMuscleGroup == muscleGroup;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(muscleGroup),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMuscleGroup = muscleGroup;
                              _applyFilters();
                            });
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Colors.blue.shade100,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Selected exercises count
          if (_selectedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${_selectedExercises.length} exercise${_selectedExercises.length != 1 ? 's' : ''} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedExercises.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Exercise list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _filteredExercises.isEmpty
                        ? _buildEmptyState()
                        : _buildExerciseList(),
          ),

          // Add selected exercises button
          if (_selectedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addSelectedExercisesToWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Selected Exercises'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search or filters',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index];
        final exerciseId = exercise['id'];
        final isSelected = _selectedExercises.containsKey(exerciseId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            title: Text(
              exercise['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Equipment: ${exercise['equipment']}'),
                if (exercise['muscleGroups'] is List && exercise['muscleGroups'].isNotEmpty)
                  Text('Muscle Groups: ${(exercise['muscleGroups'] as List).join(', ')}'),
              ],
            ),
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  // Add to selected
                  _selectedExercises[exerciseId] = {
                    'exerciseId': exerciseId,
                    'exerciseName': exercise['name'],
                    'sets': 3,
                    'reps': '10-12',
                    'rest': 60,
                    'notes': '',
                    'order': _selectedExercises.length,
                  };
                } else {
                  // Remove from selected
                  _selectedExercises.remove(exerciseId);
                }
              });
            },
            secondary: isSelected
                ? IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showExerciseSettingsDialog(exerciseId, exercise['name']),
                    tooltip: 'Exercise Settings',
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      },
    );
  }

  void _showExerciseSettingsDialog(String exerciseId, String exerciseName) {
    final formKey = GlobalKey<FormState>();
    final exercise = _selectedExercises[exerciseId]!;
    
    int sets = exercise['sets'] ?? 3;
    String reps = exercise['reps'] ?? '10-12';
    int rest = exercise['rest'] ?? 60;
    String notes = exercise['notes'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exerciseName),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                
                setState(() {
                  _selectedExercises[exerciseId] = {
                    'exerciseId': exerciseId,
                    'exerciseName': exerciseName,
                    'sets': sets,
                    'reps': reps,
                    'rest': rest,
                    'notes': notes,
                    'order': exercise['order'],
                  };
                });
                
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSelectedExercisesToWorkout() async {
    if (_selectedExercises.isEmpty) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // First, get current workout plan
      final docSnapshot = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.workoutPlanId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Workout plan not found');
      }

      // Get current exercises
      final data = docSnapshot.data() as Map<String, dynamic>;
      final currentExercises = List.from(data['exercises'] ?? []);

      // Add selected exercises to the list
      final newExercises = _selectedExercises.values.toList();
      
      // Set the order for new exercises (after existing ones)
      for (int i = 0; i < newExercises.length; i++) {
        newExercises[i]['order'] = currentExercises.length + i;
      }
      
      currentExercises.addAll(newExercises);

      // Update workout plan
      await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.workoutPlanId)
          .update({
        'exercises': currentExercises,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Navigate back with success
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        Navigator.of(context).pop(true); // Return to workout plan details with success
      }
    } catch (error) {
      // Remove loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding exercises: $error')),
        );
      }
    }
  }
}