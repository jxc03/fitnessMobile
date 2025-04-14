import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_details_screen.dart';
import 'filter_dialog.dart';

/// Displays all exercises with filtering and search capabilities. 
/// Fetches exercise data from Firestore and allows users to:
/// Search for exercises using a search bar
/// Filter exercises by muscle groups and equipment
/// Sort exercises alphabetically
/// View detailed information for each exercise
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  // Colour palette for the applications theme
  static const Color primaryColor = Color(0xFF2A6F97); // Deep blue
  static const Color secondaryColor = Color(0xFF61A0AF); // Teal blue
  static const Color accentGreen = Color(0xFF4C956C); // Forest green 
  static const Color accentTeal = Color(0xFF2F6D80); // Deep teal 
  static const Color neutralDark = Color(0xFF3D5A6C); // Dark slate 
  static const Color neutralLight = Color(0xFFF5F7FA); // Light gray 
  static const Color neutralMid = Color(0xFFE1E7ED); // Mid gray

  // The currently selected category for filtering exercises
  final String _selectedCategory = 'All Exercise';
  
  // Filter and sort state variables
  String _sortOption = 'Default'; // Current sort method
  List<String> _selectedMuscleGroups = []; // Currently selected muscle groups for filtering
  List<String> _selectedEquipment = []; // Currently selected equipment items for filtering
  List<String> _availableMuscleGroups = []; // All available muscle groups from the database
  List<String> _availableEquipment = []; // All available equipment from the database

  // Controller for the search input field
  final TextEditingController _searchController = TextEditingController();
  
  // Data state variables
  List<Map<String, dynamic>> _exercises = []; // List of all exercises fetched from Firestore
  bool _isLoading = true; // Loading state indicator
  String? _errorMessage; // Error message if fetch operation fails
  
  @override
  void initState() {
    super.initState();
    _fetchExercises(); // Fetch exercises as soon as the widget initialises
  }
  
  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches exercise data from Firestore and populates the state variables
  /// Extracts unique muscle groups and equipment types from the fetched data to use in filter options
  Future<void> _fetchExercises() async {
    // Set loading state to show progress indicator
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Query all documents in the Exercises collection
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Exercises')
        .get();
      
      // Temporary storage for processed data
      final List<Map<String, dynamic>> loadedExercises = [];
      final Set<String> muscleGroups = {};
      final Set<String> equipment = {};
      
      // Process each document in the snapshot
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<dynamic, dynamic>;
        final Map<String, dynamic> exerciseData = {
          'id': doc.id,
          'name': data['name'] ?? doc.id, // Fallback to document ID if name is missing
          'equipment': data['equipment'] ?? '',
          'instructions': data['instructions'] ?? {},
          'images': data['images'] ?? '',
          'tags': data['tags'] ?? [],
          'videos': data['videos'] ?? [],
          'muscleGroups': data['muscleGroups'] ?? [],
        };

        // Extract unique equipment types for filtering options
        if (exerciseData['equipment'].toString().isNotEmpty) {
          equipment.add(exerciseData['equipment'].toString());
        }
        
        // Extract unique muscle groups for filtering options
        // Handle both List and Map data structures for compatibility
        if (exerciseData['muscleGroups'] is List) {
          for (var group in exerciseData['muscleGroups']) {
            muscleGroups.add(group.toString());
          }
        } else if (exerciseData['muscleGroups'] is Map) {
          for (var group in (exerciseData['muscleGroups'] as Map).values) {
            muscleGroups.add(group.toString());
          }
        }

        loadedExercises.add(exerciseData);
      }
      
      // Update the state with the fetched and processed data
      setState(() {
        _exercises = loadedExercises;
        _availableMuscleGroups = muscleGroups.toList()..sort(); 
        _availableEquipment = equipment.toList()..sort();       
        _isLoading = false;
      });

    } catch (error) {
      // Handle any errors that occur during fetch
      setState(() {
        _errorMessage = 'Failed to load exercises: $error';
        _isLoading = false;
      });
      print('Error fetching exercises: $error');
    }
  }

  /// Filters and sorts the exercise list based on search query and selected filters
  /// Returns a filtered list of exercises matching the current search and filter criteria
  List<Map<String, dynamic>> _getFilteredExercises() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> result = [];
    
    //Filter by search query (across name, equipment, and muscle groups)
    result = _exercises.where((exercise) {
      // Match exercise name
      final nameMatch = exercise['name'].toString().toLowerCase().contains(query);
      // Match equipment
      final equipmentMatch = exercise['equipment'].toString().toLowerCase().contains(query);
      
      // Match any muscle groups, handles different data structures
      bool muscleGroupMatch = false;
      if (exercise['muscleGroups'] != null) {
        if (exercise['muscleGroups'] is List) {
          muscleGroupMatch = exercise['muscleGroups'].any((group) => 
            group.toString().toLowerCase().contains(query));
        } else if (exercise['muscleGroups'] is String) {
          muscleGroupMatch = exercise['muscleGroups'].toString().toLowerCase().contains(query);
        } else if (exercise['muscleGroups'] is Map) {
          muscleGroupMatch = exercise['muscleGroups'].values.any((group) => 
            group.toString().toLowerCase().contains(query));
        }
      }
      
      // Return true if any field matches the search query
      return nameMatch || equipmentMatch || muscleGroupMatch;
    }).toList();
    
    // Filter by selected category
    if (_selectedCategory != 'All Exercise') {
      result = result.where((exercise) {
        if (_selectedCategory == 'Equipment') {
          return exercise['equipment'].toString().isNotEmpty;
        } else if (_selectedCategory == 'Muscle') {
          return _isNotEmptyCollection(exercise['muscleGroups']);
        }
        return true;
      }).toList();
    }
    
    //Apply muscle group filters
    if (_selectedMuscleGroups.isNotEmpty) {
      result = result.where((exercise) {
        if (exercise['muscleGroups'] is List) {
          return exercise['muscleGroups'].any((group) => 
            _selectedMuscleGroups.contains(group.toString()));
        } else if (exercise['muscleGroups'] is Map) {
          return exercise['muscleGroups'].values.any((group) => 
            _selectedMuscleGroups.contains(group.toString()));
        }
        return false;
      }).toList();
    }
    
    //Apply equipment filters
    if (_selectedEquipment.isNotEmpty) {
      result = result.where((exercise) {
        return _selectedEquipment.contains(exercise['equipment'].toString());
      }).toList();
    }
    
    // Apply sorting (A-Z or Z-A)
    if (_sortOption == 'A-Z') {
      result.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    } else if (_sortOption == 'Z-A') {
      result.sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
    }
    
    return result;
  }

  /// Shows a dialog for selecting filters and sort options
  /// This method opens a FilterDialog widget that allows the user to:
  /// Select a sort order (A-Z, Z-A, Default)
  /// Select muscle groups to filter by
  /// Select equipment types to filter by
  void _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FilterDialog(
        selectedSortOption: _sortOption,
        selectedMuscleGroups: _selectedMuscleGroups,
        selectedEquipment: _selectedEquipment,
        availableMuscleGroups: _availableMuscleGroups,
        availableEquipment: _availableEquipment,
      ),
    );
    
    // Update the state with the selected filter options if the user confirmed
    if (result != null) {
      setState(() {
        _sortOption = result['sortOption'];
        _selectedMuscleGroups = result['muscleGroups'];
        _selectedEquipment = result['equipment'];
      });
    }
  }

  /// UI widget displaying the currently active filters as chips.
  /// Each chip has a delete icon that allows users to remove individual filters
  /// A "Clear All" button is also provided to reset all filters at once
  Widget _buildActiveFilters() {
    List<Widget> chips = [];
    
    // Add sort option chip if not the default
    if (_sortOption != 'Default') {
      chips.add(
        Chip(
          label: Text(
            'Sort: $_sortOption',
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          onDeleted: () {
            setState(() {
              _sortOption = 'Default';
            });
          },
          deleteIconColor: primaryColor,
          backgroundColor: primaryColor.withAlpha((0.1 * 255).toInt()), // 10% opacity
          side: BorderSide(color: primaryColor.withAlpha((0.3 * 255).toInt())), // 30% opacity
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    
    // Add a chip for each selected muscle group
    for (final group in _selectedMuscleGroups) {
      chips.add(
        Chip(
          label: Text(
            group,
            style: const TextStyle(
              color: accentGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          onDeleted: () {
            setState(() {
              _selectedMuscleGroups.remove(group);
            });
          },
          deleteIconColor: accentGreen,
          backgroundColor: accentGreen.withValues(alpha: 0.1), // 10% opacity
          side: BorderSide(color: accentGreen.withValues(alpha: 0.3)), // 30% opacity
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    
    // Add a chip for each selected equipment item
    for (final item in _selectedEquipment) {
      chips.add(
        Chip(
          label: Text(
            item,
            style: const TextStyle(
              color: secondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          onDeleted: () {
            setState(() {
              _selectedEquipment.remove(item);
            });
          },
          deleteIconColor: secondaryColor,
          backgroundColor: secondaryColor.withAlpha((0.1 * 255).toInt()), // 10% opacity
          side: BorderSide(color: secondaryColor.withAlpha((0.3 * 255).toInt())), // 30% opacity
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    
    // Dont show the filter section if there are no active filters
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Container to display active filters with a title and clear button
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: neutralLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neutralMid, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: neutralDark,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _sortOption = 'Default';
                    _selectedMuscleGroups = [];
                    _selectedEquipment = [];
                  });
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the filtered exercise list based on current search and filters
    final filteredExercises = _getFilteredExercises();
    
    return Scaffold(
      backgroundColor: neutralLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar and filter button
              _buildHeaderSection(),
              
              const SizedBox(height: 20),
              
              // Title section with exercise count indicator
              Row(
                children: [
                  Text(
                    'Exercises',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: neutralDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge showing the number of exercises matching the current filters
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredExercises.length}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Display active filters only if there are any selected
              if (_selectedMuscleGroups.isNotEmpty || _selectedEquipment.isNotEmpty || _sortOption != 'Default') ...[
                _buildActiveFilters(),
                const SizedBox(height: 16),
              ],
                
              // Main content area - shows either a loading indicator,  error message,
              // empty state or the list of exercises depending on the current state
              Expanded(
                child: _isLoading
                    ? const Center(
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
                        : filteredExercises.isEmpty
                            ? _buildEmptyExerciseList()
                            : _buildExerciseList(filteredExercises),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the search and filter header section.
  /// This widget includes:
  /// A search text field with a search icon
  /// A vertical divider
  /// A filter button that opens the filter dialog
  Widget _buildHeaderSection() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()), // 5% opacity
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search field that updates the UI as the user types
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: neutralDark.withAlpha((0.5 * 255).toInt())), // 50% opacity
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                prefixIcon: Icon(Icons.search, color: primaryColor),
              ),
              style: TextStyle(
                color: neutralDark,
                fontSize: 16,
              ),
              onChanged: (value) {
                // Refresh the filtered list whenever the search text changes
                setState(() {});
              },
            ),
          ),
          
          // Visual separator between search field and filter button
          Container(
            height: 30,
            width: 1,
            color: neutralMid,
          ),
          
          // Filter button that opens the filter dialog when tapped
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showFilterDialog,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 52,
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the empty state widget shown when no exercises match the current filters
  /// This provides visual feedback and a refresh button
  Widget _buildEmptyExerciseList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Exercise icon with reduced opacity
          Icon(
            Icons.fitness_center,
            size: 64,
            color: neutralDark.withAlpha((0.3 * 255).toInt()), // 30% opacity
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              color: neutralDark.withAlpha((0.7 * 255).toInt()), // 70% opacity
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          // Refresh button to fetch exercises again
          ElevatedButton.icon(
            onPressed: _fetchExercises,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of exercise cards displaying exercise information.
  /// Each card includes:
  /// An exercise image (or placeholder if no image is available)
  /// The exercise name
  /// quipment information
  /// Muscle groups targeted
  /// Optional tags
  /// A button to view more details
  Widget _buildExerciseList(List<Map<String, dynamic>> exercises) {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: neutralMid, width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _navigateToExerciseDetails(exercise);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise image or placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: exercise['images'] != null && exercise['images'].toString().isNotEmpty
                      ? _buildExerciseImage(exercise['images'], exercise['name'])
                      : Container(
                          width: 120,
                          height: 140,
                          color: neutralMid,
                          child: Icon(
                            Icons.fitness_center,
                            color: neutralDark.withAlpha((0.7 * 255).toInt()), // 70% opacity
                            size: 40,
                          ),
                        ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Exercise details section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise name
                        Text(
                          exercise['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: neutralDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Equipment information in a styled box
                        _buildLabelBox(
                          icon: Icons.fitness_center,
                          text: exercise['equipment']?.toString() ?? 'No equipment',
                          color: secondaryColor,
                        ),
                        const SizedBox(height: 6),
                        
                        // Display muscle groups if available
                        if (exercise['muscleGroups'] != null && 
                            _isNotEmptyCollection(exercise['muscleGroups']))
                          _buildLabelBox(
                            icon: Icons.accessibility_new,
                            text: _getMuscleGroupText(exercise['muscleGroups']),
                            color: accentGreen,
                          ),
                          
                        // Add space between muscle groups and tags if both exist
                        if ((exercise['muscleGroups'] != null && 
                            _isNotEmptyCollection(exercise['muscleGroups'])) &&
                            (exercise['tags'] != null && exercise['tags'] is List && 
                            (exercise['tags'] as List).isNotEmpty))
                          const SizedBox(height: 6),
                          
                        // Display tags if available
                        if (exercise['tags'] != null && exercise['tags'] is List && 
                            (exercise['tags'] as List).isNotEmpty)
                          _buildLabelBox(
                            icon: Icons.tag,
                            text: (exercise['tags'] as List).join(', '),
                            color: accentTeal,
                          ),
                        
                        const SizedBox(height: 12),
                        
                        // Button to view detailed information about the exercise
                        ElevatedButton(
                          onPressed: () {
                            _navigateToExerciseDetails(exercise);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
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
  
  /// Styled information box with an icon and text
  /// This is used to display equipment, muscle groups and tags
  Widget _buildLabelBox({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), // 12% opacity background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withAlpha((0.7 * 255).toInt()), // 70% opacity border
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color.withAlpha((0.9 * 255).toInt()), // 90% opacity icon
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withAlpha((0.9 * 255).toInt()), // 90% opacity text
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // "..." if text is too long
            ),
          ),
        ],
      ),
    );
  }
  
  /// Creates a preview string of muscle groups for display in the exercise card
  /// Handles different data structures (List, Map, String) and limits the display
  /// to the first 2 groups to avoid crowding the UI
  String _getMuscleGroupText(dynamic muscleGroups) {
    if (muscleGroups is List) {
      if (muscleGroups.isEmpty) return 'None';
      final displayed = muscleGroups.take(2).join(', '); // Take first 2 groups
      if (muscleGroups.length > 2) return '$displayed...'; // Add ellipsis if more exist
      return displayed;
    } else if (muscleGroups is Map) {
      if (muscleGroups.isEmpty) return 'None';
      final values = muscleGroups.values.toList();
      final displayed = values.take(2).join(', '); // Take first 2 groups
      if (values.length > 2) return '$displayed...'; // Add ellipsis if more exist
      return displayed;
    } else if (muscleGroups is String) {
      return muscleGroups;
    }
    return 'None';
  }
  
  /// Image widget for an exercise, handling both network and asset images
  /// Includes error handling to display a placeholder if the image fails to load
  Widget _buildExerciseImage(dynamic imagePath, String exerciseName) {
    // Determine if the image is a local asset or a network URL
    final bool isLocalAsset = imagePath != null && 
                              !imagePath.toString().startsWith('http') && 
                              !imagePath.toString().startsWith('https');

    return Container(
      width: 120,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: neutralMid, width: 1),
      ),
      clipBehavior: Clip.antiAlias, // Clip the image to the rounded corners
      child: isLocalAsset
        ? Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              return Container(
                color: neutralMid,
                child: Icon(
                  Icons.fitness_center,
                  color: neutralDark.withAlpha((0.7 * 255).toInt()), // 70% opacity
                  size: 40,
                ),
              );
            },
          )
        : Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Display a placeholder if the network image fails to load
              return Container(
                color: neutralMid,
                child: Icon(
                  Icons.fitness_center,
                  color: neutralDark.withAlpha((0.7 * 255).toInt()), // 70% opacity
                  size: 40,
                ),
              );
            },
          ),
    );
  }

  /// Checks if a collection (List, Map, or String) is not empty
  /// This helper method unifies the emptiness check across different data types
  bool _isNotEmptyCollection(dynamic collection) {
    if (collection is List) return collection.isNotEmpty;
    if (collection is Map) return collection.isNotEmpty;
    if (collection is String) return collection.isNotEmpty;
    return false;
  }
  
  /// Text widget displaying a preview of muscle groups for an exercise
  /// Formats the muscle groups as a comma-separated list, limiting to the first
  /// 2 groups and adding an ellipsis if there are more
  Widget _buildMuscleGroupsPreview(dynamic muscleGroups) {
    String preview = '';
    
    // Format the muscle groups differently based on their data structure
    if (muscleGroups is List) {
      if (muscleGroups.isEmpty) return const SizedBox.shrink();
      preview = muscleGroups.take(2).join(', '); // Take first 2 groups
      if (muscleGroups.length > 2) preview += '...'; // Add ellipsis if more exist
    } else if (muscleGroups is Map) {
      if (muscleGroups.isEmpty) return const SizedBox.shrink();
      final values = muscleGroups.values.toList();
      preview = values.take(2).join(', '); // Take first 2 groups
      if (values.length > 2) preview += '...'; // Add ellipsis if more exist
    } else if (muscleGroups is String) {
      preview = muscleGroups;
    }
    
    return Text(
      preview,
      style: TextStyle(
        color: neutralDark.withAlpha((0.8 * 255).toInt()), // 80% opacity
        fontSize: 14,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis, //"..." if text is too long
    );
  }
  
  /// Navigates to the exercise detail screen when an exercise is selected
  /// This method pushes the ExerciseDetailScreen onto the navigation stack,
  /// passing the selected exercise data to the new screen.
  void _navigateToExerciseDetails(Map<String, dynamic> exercise) {
     Navigator.push(
       context, 
       MaterialPageRoute(
         builder: (context) => ExerciseDetailScreen(exercise: exercise),
       ),
     );
  }
}