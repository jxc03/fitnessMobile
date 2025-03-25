import 'package:flutter/material.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Map<dynamic, dynamic> exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    // Get the instructions map which contains steps, tips, etc.
    final Map<dynamic, dynamic>? instructions = exercise['instructions'] as Map<dynamic, dynamic>?;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise['name'] ?? 'Exercise Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise image if available
            if (exercise['images'] != '')
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    exercise['images'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
              ),
              
            const SizedBox(height: 24),
            
            // Equipment section
            const Text(
              'Equipment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise['equipment'] ?? 'No equipment needed',
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 24),
            
            // Steps section 
            _buildSectionHeader('Steps'),
            const SizedBox(height: 8),
            _buildListSection(instructions != null ? instructions['steps'] : null),
            
            const SizedBox(height: 16),
            
            // Tips section 
            _buildSectionHeader('Tips'),
            const SizedBox(height: 8),
            _buildListSection(instructions != null ? instructions['tips'] : null),
            
            const SizedBox(height: 16),
            
            // Common Mistakes section 
            _buildSectionHeader('Common Mistakes'),
            const SizedBox(height: 8),
            _buildListSection(instructions != null ? instructions['commonMistakes'] : null),
            
            const SizedBox(height: 16),
            
            // Precautions section 
            _buildSectionHeader('Precautions'),
            const SizedBox(height: 8),
            _buildListSection(instructions != null ? instructions['precautions'] : null),
            
            // Muscle Groups (if available)
            if (exercise['muscleGroups'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader('Muscle Groups'),
                  const SizedBox(height: 8),
                  Text(
                    exercise['muscleGroups']?.toString() ?? 'Not specified',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  // Build a section with either map or list data
  Widget _buildListSection(dynamic items) {
    if (items == null) {
      return const Text('No information available');
    }
    
    List<Widget> listItems = [];
    
    // Handle items as Map
    if (items is Map) {
      if (items.isEmpty) {
        return const Text('No information available');
      }
      
      // Sort the keys numerically (0, 1, 2, etc.)
      final sortedKeys = items.keys.toList()
        ..sort((a, b) {
          // Handle both string and int keys
          final aInt = a is String ? int.tryParse(a) ?? 0 : a;
          final bInt = b is String ? int.tryParse(b) ?? 0 : b;
          return aInt.compareTo(bInt);
        });
        
      for (var key in sortedKeys) {
        final value = items[key];
        final index = key is String ? int.tryParse(key) ?? 0 : key;
        
        listItems.add(
          _buildListItem(index, value.toString()),
        );
      }
    }
    // Handle items as List
    else if (items is List) {
      if (items.isEmpty) {
        return const Text('No information available');
      }
      
      for (int i = 0; i < items.length; i++) {
        final value = items[i];
        listItems.add(
          _buildListItem(i, value.toString()),
        );
      }
    }
    // Not a recognized collection type
    else {
      return Text('Unexpected data format: ${items.runtimeType}');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: listItems,
    );
  }

  // Helper method to build a single list item
  Widget _buildListItem(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}