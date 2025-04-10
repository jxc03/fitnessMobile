import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_details_screen.dart';
import 'filter_dialog.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  // Colour palette
  static const Color primaryColor = Color(0xFF2A6F97); // Deep blue - primary accent
  static const Color secondaryColor = Color(0xFF61A0AF); // Teal blue - secondary accent
  static const Color accentGreen = Color(0xFF4C956C); // Forest green - energy and growth
  static const Color accentTeal = Color(0xFF2F6D80); // Deep teal - calm and trust
  static const Color neutralDark = Color(0xFF3D5A6C); // Dark slate - professional text
  static const Color neutralLight = Color(0xFFF5F7FA); // Light gray - backgrounds
  static const Color neutralMid = Color(0xFFE1E7ED); // Mid gray - dividers, borders

  // Selected filter category
  final String _selectedCategory = 'All Exercise';
  
  // Filter options
  String _sortOption = 'Default';
  List<String> _selectedMuscleGroups = [];
  List<String> _selectedEquipment = [];
  List<String> _availableMuscleGroups = [];
  List<String> _availableEquipment = [];

  // Search controller
  final TextEditingController _searchController = TextEditingController();
  
  // Exercises list that will be populated from Firestore
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  String? _errorMessage;
  
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

  // Fetch exercises from Firestore
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
      final Set<String> muscleGroups = {};
      final Set<String> equipment = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<dynamic, dynamic>;
        final Map<String, dynamic> exerciseData = {
          'id': doc.id,
          'name': data['name'] ?? doc.id, // Using document ID as name
          'equipment': data['equipment'] ?? '',
          'instructions': data['instructions'] ?? {},
          'images': data['images'] ?? '',
          'tags': data['tags'] ?? [],
          'videos': data['videos'] ?? [],
          'muscleGroups': data['muscleGroups'] ?? [],
        };

        // Extract unique muscle groups and equipment
        if (exerciseData['equipment'].toString().isNotEmpty) {
          equipment.add(exerciseData['equipment'].toString());
        }
        
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
      
      setState(() {
        _exercises = loadedExercises;
        _availableMuscleGroups = muscleGroups.toList()..sort();
        _availableEquipment = equipment.toList()..sort();
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

  // Filter exercises based on category and search query
  List<Map<String, dynamic>> _getFilteredExercises() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> result = [];
    
    // First filter by search query
    result = _exercises.where((exercise) {
      // Basic search on exercise name
      final nameMatch = exercise['name'].toString().toLowerCase().contains(query);
      
      // Search in equipment
      final equipmentMatch = exercise['equipment'].toString().toLowerCase().contains(query);
      
      // Search in muscle groups
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
      
      // Combined search match across all fields
      return nameMatch || equipmentMatch || muscleGroupMatch;
    }).toList();
    
    // Then filter by category
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
    
    // Then filter by selected muscle groups
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
    
    // Then filter by selected equipment
    if (_selectedEquipment.isNotEmpty) {
      result = result.where((exercise) {
        return _selectedEquipment.contains(exercise['equipment'].toString());
      }).toList();
    }
    
    // Finally, sort the results
    if (_sortOption == 'A-Z') {
      result.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    } else if (_sortOption == 'Z-A') {
      result.sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
    }
    
    return result;
  }

  // Method to show the filter dialog
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
    
    if (result != null) {
      setState(() {
        _sortOption = result['sortOption'];
        _selectedMuscleGroups = result['muscleGroups'];
        _selectedEquipment = result['equipment'];
      });
    }
  }

  // Add this method to display active filters
  Widget _buildActiveFilters() {
    List<Widget> chips = [];
    
    // Add sort option chip
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
          backgroundColor: primaryColor.withAlpha((0.1 * 255).toInt()),
          side: BorderSide(color: primaryColor.withAlpha((0.3 * 255).toInt())),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    
    // Add muscle group chips
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
          backgroundColor: accentGreen.withValues(alpha: 0.1),
          side: BorderSide(color: accentGreen.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    
    // Add equipment chips
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
          backgroundColor: secondaryColor.withAlpha((0.1 * 255).toInt()),
          side: BorderSide(color: secondaryColor.withAlpha((0.3 * 255).toInt())),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
    final filteredExercises = _getFilteredExercises();
    
    return Scaffold(
      backgroundColor: neutralLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with Search and Filter
              _buildHeaderSection(),
              
              const SizedBox(height: 20),
              
              // Section title with count
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
              
              // Active filters display
              if (_selectedMuscleGroups.isNotEmpty || _selectedEquipment.isNotEmpty || _sortOption != 'Default') ...[
                _buildActiveFilters(),
                const SizedBox(height: 16),
              ],
                
              // Exercise list
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

  // Header section with Search field and Filter button 
  Widget _buildHeaderSection() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: neutralDark.withAlpha((0.5 * 255).toInt())),
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
                setState(() {});
              },
            ),
          ),
          
          // Vertical divider
          Container(
            height: 30,
            width: 1,
            color: neutralMid,
          ),
          
          // Filter button
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

  // Empty state for exercise list
  Widget _buildEmptyExerciseList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: neutralDark.withAlpha((0.3 * 255).toInt()),
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
              color: neutralDark.withAlpha((0.7 * 255).toInt()),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
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

  // Exercise list populated with data from Firebase
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
                  // Exercise image 
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
                            color: neutralDark.withAlpha((0.7 * 255).toInt()),
                            size: 40,
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
                          exercise['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: neutralDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Equipment
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
                          
                        // Add space if both muscle groups and tags exist
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
                        
                        // View details button
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
  
  // Build styled label box for information
  Widget _buildLabelBox({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withAlpha((0.7 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color.withAlpha((0.9 * 255).toInt()),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withAlpha((0.9 * 255).toInt()),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to get muscle group text for preview
  String _getMuscleGroupText(dynamic muscleGroups) {
    if (muscleGroups is List) {
      if (muscleGroups.isEmpty) return 'None';
      final displayed = muscleGroups.take(2).join(', ');
      if (muscleGroups.length > 2) return '$displayed...';
      return displayed;
    } else if (muscleGroups is Map) {
      if (muscleGroups.isEmpty) return 'None';
      final values = muscleGroups.values.toList();
      final displayed = values.take(2).join(', ');
      if (values.length > 2) return '$displayed...';
      return displayed;
    } else if (muscleGroups is String) {
      return muscleGroups;
    }
    return 'None';
  }
  
  // Helper to the _ExercisesScreenState class to build exercise image
  Widget _buildExerciseImage(dynamic imagePath, String exerciseName) {
    // Check if the image is a local asset path or a network URL
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
      clipBehavior: Clip.antiAlias,
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
                  color: neutralDark.withAlpha((0.7 * 255).toInt()),
                  size: 40,
                ),
              );
            },
          )
        : Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: neutralMid,
                child: Icon(
                  Icons.fitness_center,
                  color: neutralDark.withAlpha((0.7 * 255).toInt()),
                  size: 40,
                ),
              );
            },
          ),
    );
  }

  // Helper to check if a collection is not empty
  bool _isNotEmptyCollection(dynamic collection) {
    if (collection is List) return collection.isNotEmpty;
    if (collection is Map) return collection.isNotEmpty;
    if (collection is String) return collection.isNotEmpty;
    return false;
  }
  
  // Build preview of muscle groups for the list item
  Widget _buildMuscleGroupsPreview(dynamic muscleGroups) {
    String preview = '';
    
    if (muscleGroups is List) {
      if (muscleGroups.isEmpty) return const SizedBox.shrink();
      preview = muscleGroups.take(2).join(', ');
      if (muscleGroups.length > 2) preview += '...';
    } else if (muscleGroups is Map) {
      if (muscleGroups.isEmpty) return const SizedBox.shrink();
      final values = muscleGroups.values.toList();
      preview = values.take(2).join(', ');
      if (values.length > 2) preview += '...';
    } else if (muscleGroups is String) {
      preview = muscleGroups;
    }
    
    return Text(
      preview,
      style: TextStyle(
        color: neutralDark.withAlpha((0.8 * 255).toInt()),
        fontSize: 14,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  // Navigate to exercise details screen
  void _navigateToExerciseDetails(Map<String, dynamic> exercise) {
     Navigator.push(
       context, 
       MaterialPageRoute(
         builder: (context) => ExerciseDetailScreen(exercise: exercise),
       ),
     );
  }
}