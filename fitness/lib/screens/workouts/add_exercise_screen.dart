import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen for adding exercises to a workout plan
/// Allows browsing, searching, filtering and selecting exercises
class AddExerciseScreen extends StatefulWidget {
  final String workoutPlanId; // ID of the workout plan to add exercises to

  const AddExerciseScreen({
    super.key,
    required this.workoutPlanId, // Required parameter for the target workout plan
  });

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _searchController = TextEditingController(); // Controller for the search input field
  final _selectedExercises = <String, Map<String, dynamic>>{}; // Map of selected exercises with their settings
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  String? _errorMessage; // Error message to display if loading fails

  // App colour palette
  static const Color primaryColor = Color(0xFF2A6F97); 
  static const Color secondaryColor = Color(0xFF61A0AF); 
  static const Color accentGreen = Color(0xFF4C956C); 
  static const Color accentTeal = Color(0xFF2F6D80);
  static const Color neutralDark = Color(0xFF3D5A6C); 
  static const Color neutralLight = Color(0xFFF5F7FA); 
  static const Color neutralMid = Color(0xFFE1E7ED); 

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

  /// Fetches all available exercises from Firestore
  /// Filters out exercises already added to the workout plan
  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Query firestore for exercises
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Exercises')
          .get();

      final List<Map<String, dynamic>> loadedExercises = [];
      
      // Go through each exerrcise doc
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String exerciseId = doc.id;
        
        // Check if the exercise is already added to the workout plan
        if (_alreadyAddedExercises.contains(exerciseId)) {
          continue; // Skip if already added
        }

        // Add exercise to the loaded list with essential properties
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

  /// Fetches exercises already added to the workout plan
  /// Creates a set of exercise IDs to filter out from available exercises
  Future<void> _fetchExistingExercises() async { 
    try {
      // Get the workout plan document
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

  /// Applies search and muscle group filters to the exercises list
  /// Updates the filtered exercises displayed in the UI
  void _applyFilters() {
    final query = _searchController.text.toLowerCase(); // Convert search query to lowercase
    List<Map<String, dynamic>> result = [];

    // Filter exercises based on search query and muscle group
    result = _exercises.where((exercise) {
      // Filter by search query in name or equipment
      final nameMatch = exercise['name'].toString().toLowerCase().contains(query);
      final equipmentMatch = exercise['equipment'].toString().toLowerCase().contains(query);

      // Filter by selected muscle group
      bool muscleGroupMatch = true;
      if (_selectedMuscleGroup != 'All') { // Skip filter if 'All' is selected
        final muscleGroups = exercise['muscleGroups'];
        bool inMuscleGroups = false;
        if (muscleGroups is List) {
          // Check if exercise targets the selected muscle group
          inMuscleGroups = muscleGroups.any((group) => 
          group.toString().toLowerCase() == _selectedMuscleGroup.toLowerCase());
        }

        // Special handling for Upper Body and Lower Body categories
        bool inTags = false;
        if (_selectedMuscleGroup == 'Upper Body' || _selectedMuscleGroup == 'Lower Body') {
          final tags = exercise['tags'];
          if (tags is List) {
            // Check if exercise has the upper/lower body tag
            inTags = tags.any((tag) => 
            tag.toString().toLowerCase() == _selectedMuscleGroup.toLowerCase());
          }
        }
        
        // Exercise matches if found in either muscle groups or tags
        muscleGroupMatch = inMuscleGroups || 
        ((_selectedMuscleGroup == 'Upper Body' || _selectedMuscleGroup == 'Lower Body') && inTags);
      }

      // Include exercise if it matches both search query and muscle group filter
      return (nameMatch || equipmentMatch) && muscleGroupMatch;
    }).toList();

    // Sort filtered exercises alphabetically by name
    result.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

    setState(() {
      _filteredExercises = result; // Update filtered exercises list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralLight, // Light background for the screen
      appBar: AppBar(
        title: const Text(
          'Add Exercises',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor, // Primary blue app bar
        foregroundColor: Colors.white, // White text and icons in app bar
        elevation: 0, // No shadow for flat design
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search input field
                TextField(
                  controller: _searchController, // Controller for search text
                  decoration: InputDecoration(
                    hintText: 'Search exercises...', // Placeholder text
                    hintStyle: TextStyle(color: neutralDark.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: neutralLight, // Light background for input
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
                      borderSide: BorderSide(color: primaryColor, width: 1.5), // Blue border when focused
                    ),
                    prefixIcon: Icon(Icons.search, color: primaryColor), // Search icon
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  style: TextStyle(
                    color: neutralDark,
                    fontSize: 16,
                  ),
                  onChanged: (value) {
                    _applyFilters(); // Apply filters when search text changes
                  },
                ),
                
                const SizedBox(height: 16), // Spacing between search and muscle group filters
                
                // Horizontal scrollable muscle group filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Allow horizontal scrolling
                  child: Row(
                    children: _muscleGroups.map((muscleGroup) {
                      final isSelected = _selectedMuscleGroup == muscleGroup; // Check if this group is selected
                      return Padding(
                        padding: const EdgeInsets.only(right: 8), // Space between chips
                        child: FilterChip(
                          label: Text(
                            muscleGroup, // Muscle group name
                            style: TextStyle(
                              color: isSelected ? accentGreen : neutralDark, // Green if selected
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, // Bold if selected
                            ),
                          ),
                          selected: isSelected, // Set selected state
                          onSelected: (selected) {
                            setState(() {
                              _selectedMuscleGroup = muscleGroup; // Update selected muscle group
                              _applyFilters(); // Apply filters with new selection
                            });
                          },
                          backgroundColor: neutralLight, // Light background for unselected chips
                          selectedColor: accentGreen.withValues(alpha: 0.12), // Transparent green for selected chips
                          checkmarkColor: accentGreen, // Green checkmark
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50), // Fully rounded corners
                            side: BorderSide(
                              color: isSelected ? accentGreen.withValues(alpha: 0.3) : neutralMid, // Green border if selected
                              width: 1, // Thin border
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding inside chip
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Selected exercises counter and clear button
          if (_selectedExercises.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: neutralMid, width: 1), // Top border
                  bottom: BorderSide(color: neutralMid, width: 1), // Bottom border
                ),
              ),
              child: Row(
                children: [
                  // Info box showing selected exercise count
                  _buildInfoBox(
                    icon: Icons.fitness_center,
                    text: '${_selectedExercises.length} exercise${_selectedExercises.length != 1 ? 's' : ''} selected',
                    color: primaryColor,
                  ),
                  const Spacer(), // Push clear button to right side
                  // Clear all selected exercises button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedExercises.clear(); // Clear all selections
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor, // Blue text
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontWeight: FontWeight.w600), // Semi-bold text
                    ),
                  ),
                ],
              ),
            ),

          // Main content area - exercise list or loading indicators
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor), // Blue loading spinner
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!, // Show error message if loading failed
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      )
                    : _filteredExercises.isEmpty
                        ? _buildEmptyState() // Show empty state when no exercises match filters
                        : _buildExerciseList(), // Show exercise list
          ),

          // Bottom action button for adding selected exercises
          if (_selectedExercises.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: neutralMid, width: 1), // Top border
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), // Subtle shadow
                    offset: const Offset(0, -2), // Shadow above the container
                    blurRadius: 4, // Soft shadow
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity, // Full width button
                child: ElevatedButton(
                  onPressed: _addSelectedExercisesToWorkout, // Save selected exercises to workout
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, // Blue button
                    foregroundColor: Colors.white, // White text
                    padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
                    elevation: 0, // No shadow for flat design
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16, // Larger text
                      fontWeight: FontWeight.bold, // Bold text
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

  /// Builds an info box with icon and text
  /// Used to display the number of selected exercises
  Widget _buildInfoBox({
    required IconData icon, // Icon to display
    required String text, // Text to display
    required Color color, // Colour theme for the box
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Padding inside box
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), // Transparent background matching the colour
        borderRadius: BorderRadius.circular(6), // Slightly rounded corners
        border: Border.all(
          color: color.withValues(alpha: 0.3), // Transparent border matching the colour
          width: 1, // Thin border
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Shrink to fit content
        children: [
          Icon(
            icon, // Display provided icon
            size: 16, // Smaller icon
            color: color.withValues(alpha: 0.9), // Slightly transparent colour
          ),
          const SizedBox(width: 6), // Space between icon and text
          Text(
            text, // Display provided text
            style: TextStyle(
              color: color.withValues(alpha: 0.9), // Slightly transparent colour
              fontWeight: FontWeight.w500, // Medium weight text
              fontSize: 13, // Smaller text
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an empty state view when no exercises match the filters
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off, // "No results" icon
            size: 80, // Large icon
            color: neutralDark.withValues(alpha: 0.3), // Faded colour
          ),
          const SizedBox(height: 16), // Space after icon
          Text(
            'No exercises found', // Primary message
            style: TextStyle(
              fontSize: 20, // Larger text
              fontWeight: FontWeight.bold, // Bold text
              color: neutralDark, // Dark text colour
            ),
          ),
          const SizedBox(height: 8), // Space between messages
          Text(
            'Try changing your search or filters', // Helpful suggestion
            style: TextStyle(
              color: neutralDark.withValues(alpha: 0.7), // Slightly faded text
              fontSize: 16, // Normal text size
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the exercise list with selectable items and details
  Widget _buildExerciseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16), // Padding around the list
      itemCount: _filteredExercises.length, // Number of exercises to display
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index]; // Current exercise data
        final exerciseId = exercise['id']; // Exercise ID
        final isSelected = _selectedExercises.containsKey(exerciseId); // Check if exercise is selected
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12), // Space between cards
          elevation: 0, // No shadow for flat design
          color: Colors.white, // White background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
            side: BorderSide(color: neutralMid, width: 1), // Light grey border
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              // Custom checkbox theme for consistent appearance
              checkboxTheme: CheckboxThemeData(
                checkColor: WidgetStateProperty.all(Colors.white), // White checkmark
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return primaryColor; // Blue background when selected
                  }
                  return Colors.transparent; // Transparent when not selected
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // Slightly rounded checkbox
                ),
                side: BorderSide(
                  width: 1.5, // Thicker border
                  color: isSelected ? primaryColor : neutralMid, // Blue when selected, grey when not
                ),
                splashRadius: 0, // No splash effect
              ),
              splashColor: Colors.transparent, // No splash effect
              highlightColor: Colors.transparent, // No highlight effect
            ),
            child: CheckboxListTile(
              title: Text(
                exercise['name'], // Exercise name
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Bold title
                  fontSize: 16, // Larger text
                  color: neutralDark, // Dark text
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6), // Space after title
                  // Equipment tag - if available
                  if (exercise['equipment'] != null && exercise['equipment'].toString().isNotEmpty)
                    _buildExerciseInfoTag(
                      label: 'Equipment', 
                      value: exercise['equipment'].toString(),
                      color: secondaryColor, // Teal colour for equipment
                    ),
                  const SizedBox(height: 6), // Space between tags
                  // Muscle groups tag - if available
                  if (exercise['muscleGroups'] is List && exercise['muscleGroups'].isNotEmpty)
                    _buildExerciseInfoTag(
                      label: 'Muscle Groups', 
                      value: (exercise['muscleGroups'] as List).join(', '), // Join list with commas
                      color: accentGreen, // Green colour for muscle groups
                    ),
                  const SizedBox(height: 6), // Space between tags
                  // Tags - if available
                  if (exercise['tags'] is List && exercise['tags'].isNotEmpty)
                    _buildExerciseInfoTag(
                      label: 'Tags', 
                      value: (exercise['tags'] as List).join(', '), // Join list with commas
                      color: accentTeal, // Teal colour for tags
                    ),
                ],
              ),
              value: isSelected, // Checkbox state
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    // Add exercise to selected map with default settings
                    _selectedExercises[exerciseId] = {
                      'exerciseId': exerciseId, // Exercise ID for database
                      'exerciseName': exercise['name'], // Exercise name for display
                      'sets': 3, // Default 3 sets
                      'reps': '10-12', // Default rep range
                      'rest': 60, // Default rest time in seconds
                      'weight': 0.0, // Default weight (none)
                      'weightUnit': 'kg', // Default weight unit
                      'notes': '', // Empty notes
                      'order': _selectedExercises.length, // Order in workout plan
                    };
                  } else {
                    // Remove from selected exercises
                    _selectedExercises.remove(exerciseId);
                  }
                });
              },
              secondary: isSelected
                  ? IconButton(
                      icon: Icon(
                        Icons.settings, // Settings icon
                        color: primaryColor, // Blue icon
                        size: 24, // Normal icon size
                      ),
                      onPressed: () => _showExerciseSettingsDialog(exerciseId, exercise['name']), // Show settings dialog
                      tooltip: 'Exercise Settings', // Tooltip text
                      splashColor: Colors.transparent, // No splash effect
                      highlightColor: Colors.transparent, // No highlight effect
                    )
                  : null, // No icon when not selected
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding inside tile
              isThreeLine: true, // Allow for multiple lines in subtitle
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Slightly rounded checkbox
              ),
              // Checkbox styling
              activeColor: primaryColor, // Blue checkbox when active
              dense: false, // Normal density for better readability
            ),
          ),
        );
      },
    );
  }

  /// Builds an information tag for exercise details
  /// Used to display equipment, muscle groups, and tags
  Widget _buildExerciseInfoTag({
    required String label, // Label text (Equipment, Muscle Groups, Tags)
    required String value, // Value to display
    required Color color, // Colour for the value text
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ', // Label with colon
          style: TextStyle(
            color: neutralDark.withValues(alpha: 0.7), // Slightly faded text
            fontSize: 14, // Smaller text
          ),
        ),
        Expanded(
          child: Text(
            value, // Display the value
            style: TextStyle(
              color: color, // Coloured text based on the type
              fontWeight: FontWeight.w500, // Medium weight text
              fontSize: 14, // Smaller text
            ),
            overflow: TextOverflow.ellipsis, // '...' if too long
            maxLines: 1, // Single line
          ),
        ),
      ],
    );
  }

  /// Shows a dialog to configure exercise settings
  /// Allows customisation of sets, reps, rest time, weight and notes
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