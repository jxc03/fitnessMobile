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
  // Selected filter category
  String _selectedCategory = 'All Exercise';
  
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
          'name': doc.id, // Using document ID as name as per your structure
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

  // Add this method to show the filter dialog
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
          label: Text('Sort: $_sortOption'),
          onDeleted: () {
            setState(() {
              _sortOption = 'Default';
            });
          },
          backgroundColor: Colors.blue.shade50,
        ),
      );
    }
    
    // Add muscle group chips
    for (final group in _selectedMuscleGroups) {
      chips.add(
        Chip(
          label: Text(group),
          onDeleted: () {
            setState(() {
              _selectedMuscleGroups.remove(group);
            });
          },
          backgroundColor: Colors.blue.shade100,
        ),
      );
    }
    
    // Add equipment chips
    for (final item in _selectedEquipment) {
      chips.add(
        Chip(
          label: Text(item),
          onDeleted: () {
            setState(() {
              _selectedEquipment.remove(item);
            });
          },
          backgroundColor: Colors.green.shade100,
        ),
      );
    }
    
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Active Filters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _sortOption = 'Default';
                  _selectedMuscleGroups = [];
                  _selectedEquipment = [];
                });
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _getFilteredExercises();
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with Search and Filter
              _buildHeaderSection(),
              
              const SizedBox(height: 16),
              
              // Category filter tabs
              _buildCategoryTabs(),
              
              const SizedBox(height: 16),
               // Active filters display

               if (_selectedMuscleGroups.isNotEmpty || _selectedEquipment.isNotEmpty || _sortOption != 'Default')
                _buildActiveFilters(),
                
              // Exercise list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : filteredExercises.isEmpty
                            ? _buildEmptyExerciseList()
                            : _buildExerciseList(filteredExercises),
              ),
            ],
          ),
        ),
      ),
      // Add FloatingActionButton for adding new exercises if needed
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add exercise screen or show dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Header section with Search field and Filter button
  Widget _buildHeaderSection() {
    return Row(
      children: [
        // Search field
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
              filled: true,
              fillColor: Colors.grey.shade300,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                // This will trigger rebuild with filtered exercises
              });
            },
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Filter button
        ElevatedButton(
          onPressed: () {
            _showFilterDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black,
            minimumSize: const Size(80, 45),
          ),
          child: const Text('Filter'),
        ),
      ],
    );
  }

  // Category filter tabs (All Exercise, Muscle, Equipment)
  Widget _buildCategoryTabs() {
    return Row(
      children: [
        _buildCategoryTab('All Exercise'),
        const SizedBox(width: 8),
        _buildCategoryTab('Muscle'),
        const SizedBox(width: 8),
        _buildCategoryTab('Equipment'),
      ],
    );
  }

  // Individual category tab
  Widget _buildCategoryTab(String category) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Text(
          category,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black,
          ),
        ),
      ),
    );
  }

  // Empty state for exercise list
  Widget _buildEmptyExerciseList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchExercises,
            child: const Text('Refresh'),
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
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: exercise['images'] != null && exercise['images'] != '' 
                ? Image.network(
                    exercise['images'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.fitness_center),
                      );
                    },
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.fitness_center),
                  ),
            title: Text(
              exercise['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Equipment: ${exercise['equipment']}'),
                
                // Display muscle groups if available
                if (exercise['muscleGroups'] != null && 
                    _isNotEmptyCollection(exercise['muscleGroups']))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildMuscleGroupsPreview(exercise['muscleGroups']),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to exercise details screen
              _navigateToExerciseDetails(exercise);
            },
          ),
        );
      },
    );
  }
  
  // Helper to check if a collection is not empty
  bool _isNotEmptyCollection(dynamic collection) {
    if (collection is List) return collection.isNotEmpty;
    if (collection is Map) return collection.isNotEmpty;
    if (collection is String) return collection.isNotEmpty;
    return false;
  }
  
  // Build a preview of muscle groups for the list item
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
      'Muscle groups: $preview',
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