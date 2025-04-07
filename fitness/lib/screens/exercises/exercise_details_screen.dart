import 'package:flutter/material.dart'; 

/// This screen displays the details of a specific exercise.
/// It presents information such as the exercise name, equipment needed, images,
/// muscle groups, instructions, tips, and more in a scrollable format.

class ExerciseDetailScreen extends StatelessWidget {
  final Map<dynamic, dynamic> exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  /// Build the main widget for the exercise detail screen
  /// Responsible for displaying the exercise details
  @override
  Widget build(BuildContext context) {
    // Get the instructions from the exercise data
    // Its a nested map that contains the steps, tips, common mistakes, and precautions
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
  
  /// Build an image section to display the exercise image
  /// If no image is available, a placeholder is shown
  Widget _buildImageSection(dynamic imageUrl) {
    // Check if imageUrl is not null and is a string 
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      // Check if the image is a local asset or a network image
      final bool isLocalAsset = !imageUrl.toString().startsWith('http') &&
                                !imageUrl.toString().startsWith('https'); 
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: isLocalAsset
            ? Image.asset(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                // If the asset fails to load, show a placeholder
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return _buildImagePlaceholder();
                },
              )
            : Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                // If the network image fails to load, show a placeholder
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
  
  /// Build a placeholder for when no image is available or fails to load
  /// This widget displays a grey box with an icon and text indicating no image is available
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
  
  /// Build the muscle groups section
  /// This widget handles the display of muscleGroups information
  Widget _buildMuscleGroups(dynamic muscleGroups) {
    // Check if muscleGroups is empty
    // If so, return a message
    if (muscleGroups == null) {
      return const Text('No muscle groups specified');
    }
    
    // If muscleGroups is a string, display it directly
    // If muscleGroups is a list, display each item as a chip
    // If muscleGroups is a map, display each entry as a chip
    // If muscleGroups is of an unexpected type, display its string representation
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
  
  /// Build section for tags
  /// This widget handles the display of tags information
  Widget _buildTags(dynamic tags) {
    // Check if tags is empty
    // If so, return a message
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
  
  /// Build videos section (placeholder for future videos)
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
    
    // TODO: Implement video functionality 
    // Currently, it just shows a placeholder
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
  
  /// Build photo gallery (placeholder for future)
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

    // TODO: Implement photo gallery functionality
    // Currently, it just shows a placeholder

    // Convert to a list if it's a single string
    List<String> photoList = [];
    if (photos is String) {
      photoList = [photos];
    } else if (photos is List) {
      photoList = List<String>.from(photos);
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photoList.length,
        itemBuilder: (context, index) {
          final photo = photoList[index];
          final bool isLocalAsset = !photo.startsWith('http') && !photo.startsWith('https');
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                // Open full screen image view
                _showFullScreenImage(context, photo, index, photoList);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: isLocalAsset
                ? Image.asset(
                  photo,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return _buildImagePlaceholder();
                  },
                )
                : Image.network(
                  photo,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Method to show full screen image
  void _showFullScreenImage(BuildContext context, String imageUrl, int initialIndex, List<String> allImages) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              final String currentImage = allImages[index];
              final bool isLocalAsset = !currentImage.startsWith('http') && !currentImage.startsWith('https');
            
              return Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 3,
                  child: isLocalAsset
                  ? Image.asset(
                      currentImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Error loading image', style: TextStyle(color: Colors.white)),
                        );
                      },
                    )
                  : Image.network(
                    currentImage,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Error loading image', style: TextStyle(color: Colors.white)),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  /// Build section header with a title
  /// This widget is used to display the title of each section in the exercise detail screen
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  /// Build section for displaying the list of instructions
  /// This widget handles the display of steps, tips, common mistakes, and precautions
  Widget _buildListSection(dynamic items) {
    // Check if items is empty, if so then return a message
    if (items == null) {
      return const Text('No information available');
    }

    // Initialise an empty list to hold the list items
    List<Widget> listItems = [];

    // Check if items is a Map 
    // If its empty, return a message
    if (items is Map) {
      if (items.isEmpty) {
        return const Text('No information available');
      }

      // If not empty, sort the keys numerically (0, 1, 2 etc)
      final sortedKeys = items.keys.toList()..sort((a, b) {
        // Handle both string and int keys
        // Convert string keys to int if possible, if it fails then use 0
        final aInt = a is String ? int.tryParse(a) ?? 0 : a;
        final bInt = b is String ? int.tryParse(b) ?? 0 : b;
        return aInt.compareTo(bInt);
      });

      // Loop through each key in sortedKeys
      for (var key in sortedKeys) {
        // Store the key
        // Convert the key to int index if its a string
        final value = items[key];
        final index = key is String ? int.tryParse(key) ?? 0 : key;
        
        // Build the list widgit then add it to the list
        listItems.add(
          _buildListItem(index, value.toString()),
        );
      }
    }

    // Handle List data structure
    // If the items is a List
    else if (items is List) {
      // Check if its empty, if so return message
      if (items.isEmpty) {
        return const Text('No information available');
      }
      
      // Loop through each item in the list
      for (int i = 0; i < items.length; i++) {
        // Get the item at the current index
        // Then add the index and string representation of the value
        final value = items[i];
        listItems.add(
          _buildListItem(i, value.toString()),
        );
      }
    }

    // Handle unexpected data types
    else {
      return Text('Unexpected data format: ${items.runtimeType}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: listItems,
    );
  }
  
  // Helper method to build a single list item
  // This widget is used to display each step, tip, common mistake, or precaution
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