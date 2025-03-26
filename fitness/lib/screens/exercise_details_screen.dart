import 'package:flutter/material.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Map<dynamic, dynamic> exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    // Get the instructions
    final instructions = exercise['instructions'];
    
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
            _buildImageSection(exercise['images']),
            
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
              exercise['equipment']?.toString() ?? 'No equipment needed',
              style: const TextStyle(fontSize: 16),
            ),
            
            // Muscle Groups section
            if (exercise['muscleGroups'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader('Muscle Groups'),
                  const SizedBox(height: 8),
                  _buildMuscleGroups(exercise['muscleGroups']),
                ],
              ),
              
            // Tags section
            if (exercise['tags'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader('Tags'),
                  const SizedBox(height: 8),
                  _buildTags(exercise['tags']),
                ],
              ),
              
            // Video section (placeholder for future)
            if (exercise['videos'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionHeader('Videos'),
                  const SizedBox(height: 8),
                  _buildVideos(exercise['videos']),
                ],
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
            
            // Photos gallery (placeholder for future)
            if (exercise['photos'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionHeader('Photos'),
                  const SizedBox(height: 8),
                  _buildPhotoGallery(exercise['photos']),
                ],
              ),
              
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  // Building main image section
  Widget _buildImageSection(dynamic imageUrl) {
    if (imageUrl != null && imageUrl != '') {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder();
            },
          ),
        ),
      );
    } else {
      return _buildImagePlaceholder();
    }
  }
  
  // Building a placeholder for when no image is available
  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  // Building section for muscle groups
  Widget _buildMuscleGroups(dynamic muscleGroups) {
    if (muscleGroups == null) {
      return const Text('No muscle groups specified');
    }
    
    if (muscleGroups is String) {
      return Text(
        muscleGroups,
        style: const TextStyle(fontSize: 16),
      );
    } else if (muscleGroups is List) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: List.generate(
          muscleGroups.length,
          (index) => Chip(
            label: Text(muscleGroups[index].toString()),
            backgroundColor: Colors.blue.shade100,
          ),
        ),
      );
    } else if (muscleGroups is Map) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: muscleGroups.entries.map((e) {
          return Chip(
            label: Text(e.value.toString()),
            backgroundColor: Colors.blue.shade100,
          );
        }).toList(),
      );
    } else {
      return Text(
        muscleGroups.toString(),
        style: const TextStyle(fontSize: 16),
      );
    }
  }
  
  // Building section for tags
  Widget _buildTags(dynamic tags) {
    if (tags == null) {
      return const Text('No tags specified');
    }
    
    if (tags is String) {
      return Text(
        tags,
        style: const TextStyle(fontSize: 16),
      );
    } else if (tags is List) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: List.generate(
          tags.length,
          (index) => Chip(
            label: Text(tags[index].toString()),
            backgroundColor: Colors.green.shade100,
          ),
        ),
      );
    } else if (tags is Map) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: tags.entries.map((e) {
          return Chip(
            label: Text(e.value.toString()),
            backgroundColor: Colors.green.shade100,
          );
        }).toList(),
      );
    } else {
      return Text(
        tags.toString(),
        style: const TextStyle(fontSize: 16),
      );
    }
  }
  
  // Build videos section (placeholder for future videos)
  Widget _buildVideos(dynamic videos) {
    if (videos == null || (videos is List && videos.isEmpty) || (videos is String && videos.isEmpty)) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Videos will be available soon',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    // Here you would loop through your videos and build video players
    // For now, just a placeholder
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Videos will be available soon',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build photo gallery (placeholder for future)
  Widget _buildPhotoGallery(dynamic photos) {
    if (photos == null || (photos is List && photos.isEmpty) || (photos is String && photos.isEmpty)) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Photo gallery will be available soon',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    // Here you would loop through your photos and build a gallery
    // For now, just a placeholder
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Photo gallery will be available soon',
              style: TextStyle(color: Colors.grey),
            ),
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
      padding: const EdgeInsets.only(bottom: 12.0),
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