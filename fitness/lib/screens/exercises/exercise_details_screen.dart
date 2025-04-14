import 'package:flutter/material.dart';

/// A screen that displays detailed information about a specific exercise.
class ExerciseDetailScreen extends StatelessWidget {
  /// The exercise data containing all details to be displayed.
  /// This map contains various properties including name, equipment, instructions,
  /// images, videos, muscle groups and tags.
  final Map<dynamic, dynamic> exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  // Define the colour palette for the entire screen
  // These colours were chosen to represent health and wellness themes
  static const Color primaryColor = Color(0xFF2A6F97); // Deep blue 
  static const Color secondaryColor = Color(0xFF61A0AF); // Teal blue 
  static const Color accentGreen = Color(0xFF4C956C); // Forest green
  static const Color accentTeal = Color(0xFF2F6D80); // Deep teal
  static const Color neutralDark = Color(0xFF3D5A6C); // Dark slate
  static const Color neutralLight = Color(0xFFF5F7FA); // Light gray
  static const Color neutralMid = Color(0xFFE1E7ED); // Mid gray

  /// Builds the main widget structure for the exercise detail screen
  /// This includes:
  /// App bar with exercise name and action buttons
  /// Hero image of the exercise
  /// Information cards (equipment, muscle groups, tags)
  /// Tab bar for different content sections
  /// Tab views for instructions, tips, mistakes, and precautions
  @override
  Widget build(BuildContext context) {
    // Extract instructions data from the exercise for use in tabs
    final instructions = exercise['instructions'];
    
    return Scaffold(
      // App bar with exercise name and action buttons
      appBar: AppBar(
        title: Text(
          exercise['name'] ?? 'Exercise Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Favourite button (functionality to be implemented)
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Favourite functionality to be implemented
            },
          ),
          // Share button (functionality to be implemented)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality to be implemented
            },
          ),
        ],
      ),
      backgroundColor: neutralLight,
      // Use DefaultTabController for the tabbed interface
      body: DefaultTabController(
        length: 4, // Four tabs: How to, Tips, Mistakes, Precautions
        child: NestedScrollView(
          // Header section that stays at the top
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Non-scrollable top section with image and info cards
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise image or placeholder
                    _buildImageSection(exercise['images']),
                    
                    // Information section with equipment, muscle groups, and tags
                    _buildInfoSection(context),
                  ],
                ),
              ),
              // Sticky tab bar that remains visible when scrolling
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: primaryColor,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'How to'),
                      Tab(text: 'Tips'),
                      Tab(text: 'Mistakes'),
                      Tab(text: 'Precautions'),
                    ],
                  ),
                ),
                pinned: true, // Keep the tab bar visible when scrolling
              ),
            ];
          },
          // Tab content area that scrolls beneath the header
          body: TabBarView(
            children: [
              // Tab content for each section with consistent padding
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildListSection(instructions != null ? instructions['steps'] : null),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildListSection(instructions != null ? instructions['tips'] : null),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildListSection(instructions != null ? instructions['commonMistakes'] : null),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildListSection(instructions != null ? instructions['precautions'] : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Information section containing equipment, muscle groups, and tags
  /// This section displays multiple information cards
  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipment information card
          _buildInfoCard(
            context,
            title: 'Equipment',
            icon: Icons.fitness_center,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                exercise['equipment']?.toString() ?? 'No equipment needed',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            iconColor: accentTeal,
          ),
          
          const SizedBox(height: 16),
          
          // Muscle Groups card - only shown if data exists
          if (exercise['muscleGroups'] != null)
            _buildInfoCard(
              context,
              title: 'Muscle Groups',
              icon: Icons.accessibility_new,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildMuscleGroups(exercise['muscleGroups']),
              ),
              iconColor: primaryColor,
            ),
          
          const SizedBox(height: 16),
          
          // Tags card - only shown if data exists
          if (exercise['tags'] != null)
            _buildInfoCard(
              context,
              title: 'Tags',
              icon: Icons.tag,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildTags(exercise['tags']),
              ),
              iconColor: primaryColor,
            ),
          
          const SizedBox(height: 16),
          
          // Videos section - only shown if data exists
          if (exercise['videos'] != null) 
            _buildVideosCard(context),
            
          // Photos Gallery - only shown if data exists
          if (exercise['photos'] != null) 
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildInfoCard(
                context,
                title: 'Photo Gallery',
                icon: Icons.photo_library,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildPhotoGallery(exercise['photos']),
                ),
                iconColor: secondaryColor,
              ),
            ),
        ],
      ),
    );
  }
  
  /// Reusable information card with consistent styling.
  /// This card template is used for displaying various types of information
  /// with a title, icon, and custom content widget.
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1), // 10% opacity shadow
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with icon and title
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: neutralDark,
                  ),
                ),
              ],
            ),
            // Card content (custom widget passed as parameter)
            child,
          ],
        ),
      ),
    );
  }
  
  /// Card to display video content or a placeholder
  /// Currently shows a placeholder with "coming soon" message and
  /// notification button, as video functionality is not yet implemented
  Widget _buildVideosCard(BuildContext context) {
    return _buildInfoCard(
      context,
      title: 'Videos',
      icon: Icons.play_circle_filled,
      iconColor: primaryColor,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: neutralLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play button with subtle animation effect via shadow
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.8), // 80% opacity
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3), // 30% opacity shadow
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Videos will be available soon',
                style: TextStyle(
                  color: neutralDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              // Notification button with rounded corners and accent colour
              ElevatedButton(
                onPressed: () {
                  // Notification functionality to be implemented
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Notify Me'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Image section at the top of the screen
  /// Displays either:
  /// The exercise image with a gradient overlay and text
  /// A placeholder if no image is available
  /// The image can be either from a network URL or a local asset.
  Widget _buildImageSection(dynamic imageUrl) {
    // Check if a valid image URL is provided
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      // Determine if the image is a local asset or a network URL
      final bool isLocalAsset = !imageUrl.toString().startsWith('http') &&
                                !imageUrl.toString().startsWith('https'); 
      return SizedBox(
        height: 250,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with gradient overlay
            ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, neutralDark.withValues(alpha: 0.7)], // Gradient from transparent to dark
                  stops: const [0.7, 1.0], // Start darkening at 70% of the height
                ).createShader(rect);
              },
              blendMode: BlendMode.darken,
              child: isLocalAsset
                ? Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return _buildImagePlaceholder();
                    },
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  ),
            ),
            
            // Exercise name overlay at the bottom of the image
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                exercise['name'] ?? 'Exercise Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0), // Subtle text shadow 
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // If no image is available, show a placeholder
      return _buildImagePlaceholder();
    }
  }
  
  /// Builds a placeholder widget for when no exercise image is available
  /// Displays a fitness icon and "No image available" text message
  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      color: neutralMid,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 60, color: neutralDark.withValues(alpha: 0.7)), // 70% opacity
          const SizedBox(height: 16),
          const Text(
            'No image available',
            style: TextStyle(
              color: neutralDark,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Muscle groups display with dynamic formatting
  /// Handles different data structures (String, List, Map) and
  /// renders the muscle groups as styled chips.
  Widget _buildMuscleGroups(dynamic muscleGroups) {
    if (muscleGroups == null) {
      return const Text('No muscle groups specified');
    }
    
    // Handle String data type (single muscle group)
    if (muscleGroups is String) {
      // Display a single muscle group as a chip
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: [
          _buildStyledChip(
            muscleGroups,
            accentGreen,
            Icons.accessibility_new,
          ),
        ],
      );
    } 
    // Handle List data type (multiple muscle groups as a list)
    else if (muscleGroups is List) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: List.generate(
          muscleGroups.length,
          (index) => _buildStyledChip(
            muscleGroups[index].toString(),
            accentGreen,
            Icons.accessibility_new,
          ),
        ),
      );
    } 
    // Handle Map data type (key value pairs of muscle groups)
    else if (muscleGroups is Map) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: muscleGroups.entries.map((e) {
          return _buildStyledChip(
            e.value.toString(),
            accentGreen,
            Icons.accessibility_new,
          );
        }).toList(),
      );
    } 
    // Fallback for any other data type
    else {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: [
          _buildStyledChip(
            muscleGroups.toString(),
            accentGreen,
            Icons.accessibility_new,
          ),
        ],
      );
    }
  }
  
  
  /// Builds the tags display with appropriate formatting
  /// Handles different data structures (String, List, Map) and
  /// renders the tags as styled chips.
  Widget _buildTags(dynamic tags) {
    if (tags == null) {
      return const Text('No tags specified');
    }
    
    // Handle String data type (single tag)
    if (tags is String) {
      return Text(
        tags,
        style: const TextStyle(fontSize: 16),
      );
    } 
    // Handle List data type (multiple tags as a list)
    else if (tags is List) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: List.generate(
          tags.length,
          (index) => _buildStyledChip(
            tags[index].toString(),
            accentGreen,
            Icons.tag,
          ),
        ),
      );
    } 
    // Handle Map data type (key value pairs of tags)
    else if (tags is Map) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: tags.entries.map((e) {
          return _buildStyledChip(
            e.value.toString(),
            accentGreen,
            Icons.tag,
          );
        }).toList(),
      );
    } 
    // Fallback for any other data type
    else {
      return Text(
        tags.toString(),
        style: const TextStyle(fontSize: 16),
      );
    }
  }
  
  /// Builds a styled chip widget with consistent appearance.
  /// Used for displaying muscle groups, tags, and other categorization elements
  /// with a visually appealing and consistent style.
  Widget _buildStyledChip(String label, Color color, IconData icon) {
    // Calculate derived colours for background and text/icon
    final Color backgroundColor = color.withValues(alpha: 0.12); // 12% opacity background
    final Color textAndIconColor = color.withValues(alpha: 0.9); // 90% opacity text/icon
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50), // Fully rounded corners
        border: Border.all(
          color: color.withValues(alpha: 0.3), // 30% opacity border
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Wrap content tightly
        children: [
          Icon(
            icon,
            size: 16,
            color: textAndIconColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds a horizontal scrollable photo gallery
  /// If photos are available, displays them as scrollable thumbnails
  /// Otherwise, shows a placeholder message
  Widget _buildPhotoGallery(dynamic photos) {
    // Check if photos data is missing or empty
    if (photos == null || (photos is List && photos.isEmpty) || (photos is String && photos.isEmpty)) {
      // Display a placeholder for missing photos
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: neutralLight,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 40, color: neutralDark.withValues(alpha: 0.4)), // 40% opacity
            const SizedBox(height: 12),
            const Text(
              'Photo gallery will be available soon',
              style: TextStyle(color: neutralDark, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Convert the photos data to a list format for consistent handling
    List<String> photoList = [];
    if (photos is String) {
      photoList = [photos]; // Single photo as a string
    } else if (photos is List) {
      photoList = List<String>.from(photos); // Multiple photos as a list
    }

    // Build horizontal scrollable list of photo thumbnails
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photoList.length,
        itemBuilder: (context, index) {
          final photo = photoList[index];
          final bool isLocalAsset = !photo.startsWith('http') && !photo.startsWith('https');
          
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                // Open full screen image viewer when thumbnail is tapped
                _showFullScreenImage(context, photo, index, photoList);
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2), // 20% opacity shadow
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: isLocalAsset
                    ? Image.asset(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Show broken image icon if asset image fails to load
                          return Container(
                            color: neutralLight,
                            child: Icon(Icons.broken_image, color: neutralDark.withValues(alpha: 0.5)),
                          );
                        },
                      )
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Show broken image icon if network image fails to load
                          return Container(
                            color: neutralLight,
                            child: Icon(Icons.broken_image, color: neutralDark.withValues(alpha: 0.5)),
                          );
                        },
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Opens a full-screen image viewer for the selected photo
  /// Displays the selected image with zooming capabilities and a
  /// thumbnail strip at the bottom for navigating between images
  /// Note: This method is marked as "not working" in the original code
  /// and needs further debugging.
  void _showFullScreenImage(BuildContext context, String imageUrl, int initialIndex, List<String> allImages) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              '${initialIndex + 1}/${allImages.length}', // Show position in gallery
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Stack(
            children: [
              // Main image viewer with paging and zoom capabilities
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  final String currentImage = allImages[index];
                  final bool isLocalAsset = !currentImage.startsWith('http') && !currentImage.startsWith('https');
                
                  return Center(
                    child: InteractiveViewer(
                      panEnabled: true, // Allow panning when zoomed
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.5, // Allow zooming out to 50%
                      maxScale: 3, // Allow zooming in to 300%
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
                              // Show loading progress indicator for network images
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Show error message if image fails to load
                              return const Center(
                                child: Text('Error loading image', style: TextStyle(color: Colors.white)),
                              );
                            },
                          ),
                    ),
                  );
                },
              ),
              
              // Bottom thumbnail strip for quick navigation between images
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allImages.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final String thumbImage = allImages[index];
                      final bool isSelected = index == initialIndex;
                      final bool isLocalAsset = !thumbImage.startsWith('http') && !thumbImage.startsWith('https');
                      
                      return GestureDetector(
                        onTap: () {
                          // Navigate to the selected image
                          // Note: This code likely needs fixing as noted in the original comment
                          PageController(initialPage: index).animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                              ? Border.all(color: Colors.white, width: 2) // Highlight selected thumbnail
                              : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: isLocalAsset
                              ? Image.asset(
                                  thumbImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.broken_image, color: Colors.white),
                                    );
                                  },
                                )
                              : Image.network(
                                  thumbImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.broken_image, color: Colors.white),
                                    );
                                  },
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Builds a section for displaying instructions, tips, mistakes, or precautions
  /// Handles different data structures and displays items in a styled list format
  /// with numbered indicators
  Widget _buildListSection(dynamic items) {
    // Display a placeholder if no data is available
    if (items == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: neutralDark.withValues(alpha: 0.5)), // 50% opacity
            const SizedBox(height: 16),
            Text(
              'No information available',
              style: TextStyle(
                fontSize: 16,
                color: neutralDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Create an empty list to hold the list items
    List<Widget> listItems = [];

    // Handle Map data structure (commonly used for instructions)
    if (items is Map) {
      if (items.isEmpty) {
        return Center(
          child: Text(
            'No information available',
            style: TextStyle(color: neutralDark),
          ),
        );
      }

      // Sort the keys numerically to ensure correct ordering
      final sortedKeys = items.keys.toList()..sort((a, b) {
        final aInt = a is String ? int.tryParse(a) ?? 0 : a;
        final bInt = b is String ? int.tryParse(b) ?? 0 : b;
        return aInt.compareTo(bInt);
      });

      // Create a list item for each entry in the map
      for (var key in sortedKeys) {
        final value = items[key];
        final index = key is String ? int.tryParse(key) ?? 0 : key;
        
        listItems.add(
          _buildListItem(index, value.toString()),
        );
      }
    }
    // Handle List data structure (alternative format for instructions)
    else if (items is List) {
      if (items.isEmpty) {
        return Center(
          child: Text(
            'No information available',
            style: TextStyle(color: neutralDark),
          ),
        );
      }
      
      // Create a list item for each entry in the list
      for (int i = 0; i < items.length; i++) {
        final value = items[i];
        listItems.add(
          _buildListItem(i, value.toString()),
        );
      }
    }
    // Handle unexpected data types with an error message
    else {
      return Text('Unexpected data format: ${items.runtimeType}');
    }
    
    // Return a ListView containing all the generated list items
    return ListView(
      padding: EdgeInsets.zero,
      children: listItems,
    );
  }
  
  /// Builds a single styled list item for instructions, tips, etc
  /// Creates a visually appealing card with a numbered indicator and
  /// the instruction text.

  Widget _buildListItem(int index, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neutralMid, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05), // 5% opacity shadow
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numbered circle with gradient background and subtle shadow
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [secondaryColor, primaryColor], // Gradient from secondary to primary
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2), // 20% opacity shadow
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}', // 1-based numbering for user-friendly display
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Instruction text with enhanced readability
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5, // Line height for better readability
                color: neutralDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for the tab bar in the sliver app bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  
  _SliverAppBarDelegate(this.tabBar);
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE1E7ED), // neutralMid
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }
  
  @override
  double get maxExtent => tabBar.preferredSize.height;
  
  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}