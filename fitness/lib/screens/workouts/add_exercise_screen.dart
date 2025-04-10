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

  // App colour palette
  static const Color primaryColor = Color(0xFF2A6F97); // Deep blue - primary accent
  static const Color secondaryColor = Color(0xFF61A0AF); // Teal blue - secondary accent
  static const Color accentGreen = Color(0xFF4C956C); // Forest green - energy and growth
  static const Color accentTeal = Color(0xFF2F6D80); // Deep teal - calm and trust
  static const Color neutralDark = Color(0xFF3D5A6C); // Dark slate - professional text
  static const Color neutralLight = Color(0xFFF5F7FA); // Light gray - backgrounds
  static const Color neutralMid = Color(0xFFE1E7ED); // Mid gray - dividers, borders

  // Available muscle groups for filtering
  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Core',
    'Glutes',
    'Hamstrings',
    'Quads',
    'Upper Body',
    'Lower Body',
  ];
  String _selectedMuscleGroup = 'All';

  Set<String> _alreadyAddedExercises = {}; // To track already added exercises

  @override
  void initState() {
    super.initState();
    _fetchExistingExercises().then((_) => _fetchExercises());
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
        final String exerciseId = doc.id;
        
        // Check if the exercise is already added to the workout plan
        if (_alreadyAddedExercises.contains(exerciseId)) {
          continue;
        }

        loadedExercises.add({
          'id': doc.id,
          'name': data['name'] ?? doc.id,
          'equipment': data['equipment'] ?? '',
          'muscleGroups': data['muscleGroups'] ?? [],
          'tags': data['tags'] ?? [],
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

  // Fetch existing exercises from the workout plan
  Future<void> _fetchExistingExercises() async { 
    try {
      // Get the 
      final docSnapshot = await FirebaseFirestore.instance
      .collection('WorkoutPlans')
      .doc(widget.workoutPlanId)
      .get();
      
      // Check if the document exists
      if (!docSnapshot.exists) {
        return;
      }
      
      // Get the data from the document
      final data = docSnapshot.data() as Map<String, dynamic>;
      // Get the current exercises from the document
      final currentExercises = List.from(data['exercises'] ?? []);
      
      // Extract exercise IDs from current exercises
      _alreadyAddedExercises = currentExercises
      .map<String>((exercise) => exercise['exerciseId'] as String)
      .toSet();
    } catch (error) {
      print('Error fetching existing exercises: $error');
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
        bool inMuscleGroups = false;
        if (muscleGroups is List) {
          inMuscleGroups = muscleGroups.any((group) => 
          group.toString().toLowerCase() == _selectedMuscleGroup.toLowerCase());
        }

        // Filter Upper Body and Lower Body, also check the tags array
        bool inTags = false;
        if (_selectedMuscleGroup == 'Upper Body' || _selectedMuscleGroup == 'Lower Body') {
          final tags = exercise['tags'];
          if (tags is List) {
            inTags = tags.any((tag) => 
            tag.toString().toLowerCase() == _selectedMuscleGroup.toLowerCase());
          }
        }
        
        // Match if found in either muscle groups or tags (for Upper/Lower Body)
        muscleGroupMatch = inMuscleGroups || 
        ((_selectedMuscleGroup == 'Upper Body' || _selectedMuscleGroup == 'Lower Body') && inTags);
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
      backgroundColor: neutralLight,
      appBar: AppBar(
        title: const Text(
          'Add Exercises',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: TextStyle(color: neutralDark.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: neutralLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neutralMid, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neutralMid, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  style: TextStyle(
                    color: neutralDark,
                    fontSize: 16,
                  ),
                  onChanged: (value) {
                    _applyFilters();
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Muscle group filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _muscleGroups.map((muscleGroup) {
                      final isSelected = _selectedMuscleGroup == muscleGroup;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            muscleGroup,
                            style: TextStyle(
                              color: isSelected ? accentGreen : neutralDark,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMuscleGroup = muscleGroup;
                              _applyFilters();
                            });
                          },
                          backgroundColor: neutralLight,
                          selectedColor: accentGreen.withValues(alpha: 0.12),
                          checkmarkColor: accentGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: BorderSide(
                              color: isSelected ? accentGreen.withValues(alpha: 0.3) : neutralMid,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: neutralMid, width: 1),
                  bottom: BorderSide(color: neutralMid, width: 1),
                ),
              ),
              child: Row(
                children: [
                  _buildInfoBox(
                    icon: Icons.fitness_center,
                    text: '${_selectedExercises.length} exercise${_selectedExercises.length != 1 ? 's' : ''} selected',
                    color: primaryColor,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedExercises.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Exercise list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      )
                    : _filteredExercises.isEmpty
                        ? _buildEmptyState()
                        : _buildExerciseList(),
          ),

          // Selected exercises button
          if (_selectedExercises.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: neutralMid, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addSelectedExercisesToWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Add Selected Exercises'),
                ),
              ),
            ),
        ],
      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: neutralDark.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search or filters',
            style: TextStyle(
              color: neutralDark.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index];
        final exerciseId = exercise['id'];
        final isSelected = _selectedExercises.containsKey(exerciseId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: neutralMid, width: 1),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                checkColor: WidgetStateProperty.all(Colors.white),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return primaryColor;
                  }
                  return Colors.transparent; // Transparent when not selected
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  width: 1.5,
                  color: isSelected ? primaryColor : neutralMid,
                ),
                splashRadius: 0,
              ),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: CheckboxListTile(
              title: Text(
                exercise['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: neutralDark,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  if (exercise['equipment'] != null && exercise['equipment'].toString().isNotEmpty)
                    _buildExerciseInfoTag(
                      label: 'Equipment', 
                      value: exercise['equipment'].toString(),
                      color: secondaryColor,
                    ),
                  const SizedBox(height: 6),
                  if (exercise['muscleGroups'] is List && exercise['muscleGroups'].isNotEmpty)
                    _buildExerciseInfoTag(
                      label: 'Muscle Groups', 
                      value: (exercise['muscleGroups'] as List).join(', '),
                      color: accentGreen,
                    ),
                  const SizedBox(height: 6),
                  if (exercise['tags'] is List && exercise['tags'].isNotEmpty)
                    _buildExerciseInfoTag(
                      label: 'Tags', 
                      value: (exercise['tags'] as List).join(', '),
                      color: accentTeal,
                    ),
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
                      'weight': 0.0,
                      'weightUnit': 'kg',
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
                      icon: Icon(
                        Icons.settings,
                        color: primaryColor,
                        size: 24,
                      ),
                      onPressed: () => _showExerciseSettingsDialog(exerciseId, exercise['name']),
                      tooltip: 'Exercise Settings',
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isThreeLine: true,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              // Control the checkbox appearance
              activeColor: primaryColor,
              dense: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseInfoTag({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: neutralDark.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  void _showExerciseSettingsDialog(String exerciseId, String exerciseName) {
    final formKey = GlobalKey<FormState>();
    final exercise = _selectedExercises[exerciseId]!;
    
    int sets = exercise['sets'] ?? 3;
    String reps = exercise['reps'] ?? '10-12';
    int rest = exercise['rest'] ?? 60;
    double weight = exercise['weight'] ?? 0.0;
    String weightUnit = exercise['weightUnit'] ?? 'kg';
    String notes = exercise['notes'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          exerciseName,
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
                TextFormField(
                  initialValue: sets.toString(),
                  decoration: InputDecoration(
                    labelText: 'Sets',
                    labelStyle: TextStyle(color: neutralDark.withValues(alpha: 0.7)),
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
                TextFormField(
                  initialValue: reps,
                  decoration: InputDecoration(
                    labelText: 'Reps (e.g., "10" or "8-12")',
                    labelStyle: TextStyle(color: neutralDark.withValues(alpha: 0.7)),
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
                TextFormField(
                  initialValue: rest.toString(),
                  decoration: InputDecoration(
                    labelText: 'Rest (seconds)',
                    labelStyle: TextStyle(color: neutralDark.withValues(alpha: 0.7)),
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
                // Weight input
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: weight.toString(),
                        decoration: InputDecoration(
                          labelText: 'Weight',
                          labelStyle: TextStyle(color: neutralDark.withValues(alpha: 0.7)),
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
                    // Weight unit selector
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: TextStyle(color: neutralDark.withValues(alpha: 0.7)),
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
                // Notes input
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: notes,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    labelStyle: TextStyle(color: neutralDark.withValues(alpha: 0.7)),
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
                
                setState(() {
                  _selectedExercises[exerciseId] = {
                    'exerciseId': exerciseId,
                    'exerciseName': exerciseName,
                    'sets': sets,
                    'reps': reps,
                    'rest': rest,
                    'weight': weight,
                    'weightUnit': weightUnit,
                    'notes': notes,
                    'order': exercise['order'],
                  };
                });
                
                Navigator.of(context).pop();
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
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
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
          SnackBar(
            content: Text('Error adding exercises: $error'),
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