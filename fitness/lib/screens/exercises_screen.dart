import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_details_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  // Selected filter category
  String _selectedCategory = 'All Exercise';
  
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
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<dynamic, dynamic>;
        final Map<String, dynamic> exerciseData = {
          'id': doc.id,
          'name': doc.id, // Using document ID as name as per your structure
          'equipment': data['equipment'] ?? '',
          'instructions': data['instructions'] ?? {},
          'images': data['images'] ?? '',
        };
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
    
    return _exercises.where((exercise) {
      // Basic search on exercise name
      final nameMatch = exercise['name'].toString().toLowerCase().contains(query);
      
      // Filter by category if not "All Exercise"
      bool categoryMatch = true;
      if (_selectedCategory == 'Equipment') {
        categoryMatch = exercise['equipment'].toString().isNotEmpty;
      }
      // Add more category filters if needed
      
      return nameMatch && categoryMatch;
    }).toList();
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
            // Will implement filter dialog/screen later
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
            leading: exercise['images'] != '' 
                ? Image.network(exercise['images'])
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
            subtitle: Text('Equipment: ${exercise['equipment']}'),
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